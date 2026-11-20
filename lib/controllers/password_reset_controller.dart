import 'package:emtrack/routes/app_pages.dart';
import 'package:emtrack/services/api_constants.dart';
import 'package:emtrack/services/api_service.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class ResetPasswordController extends GetxController {
  var currentStep = 0.obs;
  final RxBool isLoading = false.obs;

  final formKey1 = GlobalKey<FormState>();
  final formKey2 = GlobalKey<FormState>();

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final tokenController = TextEditingController();
  final newPasswordController = TextEditingController();

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    tokenController.dispose();
    newPasswordController.dispose();
    super.onClose();
  }

  void goToStep2() => currentStep.value = 1;
  void goBack() => currentStep.value = 0;

  Future<void> sendtokenPassword() async {
    if (isLoading.value) return;
    if (!formKey1.currentState!.validate()) return;

    try {
      isLoading.value = true;
      final response = await ApiService.postApi(
        endpoint: ApiConstants.sendPasswordToken,
        body: {'username': usernameController.text.trim()},
      );

      if (response == null) {
        _showError(
          "Network error. Please check your connection.",
          isNetwork: true,
        );
        return;
      }

      _handleResponse(
        response: response,
        onSuccess: () async {
          await Future.delayed(const Duration(milliseconds: 500));
          goToStep2();
        },
      );
    } catch (e) {
      _showError(
        "Network error. Please check your connection.",
        isNetwork: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword() async {
    if (isLoading.value) return;
    if (!formKey2.currentState!.validate()) return;

    try {
      isLoading.value = true;
      final response = await ApiService.postApi(
        endpoint: ApiConstants.resetPassword,
        body: {
          'username': usernameController.text.trim(),
          'token': tokenController.text.trim(),
          'newPassword': newPasswordController.text.trim(),
        },
      );

      if (response == null) {
        _showError(
          "Network error. Please check your connection.",
          isNetwork: true,
        );
        return;
      }

      _handleResponse(
        response: response,
        onSuccess: () async {
          await Future.delayed(const Duration(milliseconds: 500));
          Get.offAllNamed(AppPages.LOGIN);
        },
      );
    } catch (e) {
      _showError(
        "Network error. Please check your connection.",
        isNetwork: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _handleResponse({
    required Map<String, dynamic> response,
    required Future<void> Function() onSuccess,
  }) {
    final isSuccess = response['isSuccess'];
    final message = response['message']?.toString().trim() ?? '';
    final errorMessage = response['errorMessage']?.toString().trim() ?? '';

    if (isSuccess != null) {
      if (isSuccess == true) {
        _showSuccess(message.isNotEmpty ? message : "Operation successful.");
        onSuccess();
      } else {
        _showError(
          errorMessage.isNotEmpty
              ? errorMessage
              : message.isNotEmpty
              ? message
              : "Something went wrong.",
        );
      }
      return;
    }

    final msgLower = message.toLowerCase();
    final isErrorMsg =
        msgLower.contains('failed') ||
        msgLower.contains('error') ||
        msgLower.contains('invalid') ||
        msgLower.contains('not found') ||
        msgLower.contains('incorrect') ||
        msgLower.contains('expired') ||
        msgLower.contains('wrong');

    if (message.isNotEmpty && isErrorMsg) {
      _showError(message);
      return;
    }

    if (errorMessage.isNotEmpty) {
      _showError(errorMessage);
      return;
    }

    if (message.isNotEmpty) {
      _showSuccess(message);
      onSuccess();
      return;
    }

    _showError("Invalid Inputs. Please verify and try again.");
  }

  void _showSuccess(String message) {
    Get.snackbar(
      "Success",
      "If the user exists, a password reset code has been sent to the registered email address.",
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  void _showError(String message, {bool isNetwork = false}) {
    Get.snackbar(
      isNetwork ? "Network Error" : "Error",
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
      duration: const Duration(seconds: 4),
      icon: isNetwork
          ? const Icon(Icons.wifi_off, color: Colors.white)
          : const Icon(Icons.error_outline, color: Colors.white),
    );
  }
}
