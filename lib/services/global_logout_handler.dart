import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:emtrack/views/login_view.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:emtrack/services/auth_service.dart';

class GlobalLogoutHandler extends GetxService {
  bool _isRedirecting = false;
  bool _isRetrying = false;


  Future<void> forceLogout() async {
    if (_isRedirecting) return;
    if (_isRetrying) return;

    _isRetrying = true;
    try {
      final username = await SecureStorage.getUserName();
      final password = await SecureStorage.getPassword();

      if (username != null &&
          username.isNotEmpty &&
          password != null &&
          password.isNotEmpty) {
        final result = await AuthService.login(username, password)
            .timeout(const Duration(seconds: 15));

        if (result != null) {
          return;
        }
      }
    } catch (_) {

    } finally {
      _isRetrying = false;
    }

    if (_isRedirecting) return;
    _isRedirecting = true;
    Get.offAll(() => LoginView());
  }
}