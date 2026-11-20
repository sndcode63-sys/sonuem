import 'package:emtrack/models/grand_parent_account_model/assign_grand_parent_model.dart';
import 'package:emtrack/models/grand_parent_account_model/grand_parent_account_model.dart';
import 'package:emtrack/routes/app_pages.dart';
import 'package:emtrack/services/api_constants.dart';
import 'package:emtrack/services/api_service.dart';
import 'package:emtrack/services/grand_parent_account_service/grand_parent_account_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller.dart';

class GrandparentAccountController extends GetxController {
  final service = GrandparentAccountService();

  // Stepper
  RxInt currentStep = 0.obs;
  final int totalSteps = 2;

  final isloading = false.obs;

  final selectedParentName = ''.obs;
  final selectedGrandparentName = ''.obs;

  final accountTypeController = TextEditingController();
  final RxString accountType = ''.obs;

  @override
  void onClose() {
    accountTypeController.dispose();
    super.onClose();
  }

  // Validation
  final createFormKey = GlobalKey<FormState>();

  final RxBool isWorkflowEnabled = false.obs;

  RxString grandparentName = ''.obs;
  RxInt selectedParentId = 0.obs;
  RxInt selectedGrandparentId = 0.obs;

  RxList<Map<String, dynamic>> parentAccounts = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> grandparentAccounts = <Map<String, dynamic>>[].obs;

  void next() {
    if (currentStep.value < totalSteps - 1) {
      currentStep.value++;
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchParentAccounts();
    fetchGrandParentAccounts();
  }

  void previous() {
    if (currentStep.value > 0) {
      currentStep.value--;
      grandparentName.value = '';
    }
  }

  // Submit Step-1: Create Grandparent
  Future<void> createGrandparent() async {
    isloading.value = true;
    final userName = await SecureStorage.getUserName();

    final isWfEnabled = isWorkflowEnabled.value;

    debugPrint("🚀 [CONTROLLER] Creating Grandparent with workflow enabled: $isWfEnabled");

    final model = GrandparentAccountModel(
      createdBy: userName.toString(),
      createdDate: DateTime.now().toIso8601String(),
      grandParentAccountName: grandparentName.value,
      isActive: true,
      ownedBy: accountType.value,
      updatedBy: userName.toString(),
      updatedDate: DateTime.now().toIso8601String(),
      isApprovalWorkflowEnabled: isWfEnabled, // ✅ Pass toggle state for this account
    );

    try {
      final isCreated = await service.createGrandparent(model);
      if (isCreated) {
        Get.snackbar(
          "Success",
          "Grandparent Account Created Successfully!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await Future.delayed(const Duration(seconds: 1));
        Get.offAllNamed(AppPages.HOME);
      } else {
        Get.snackbar(
          "Failed",
          "Could not create account. Please check your network.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.wifi_off, color: Colors.white),
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      debugPrint("❌ [CONTROLLER] Error creating grandparent: $e");
      Get.snackbar(
        "Error",
        "Failed to create grandparent account. Please check your network.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.wifi_off, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    } finally {
      isloading.value = false;
    }
  }

  // Submit Step-2: Assign / Update Grandparent
  Future<void> assignGrandparent() async {
    if (isloading.value) return;
    if (selectedParentId.value == 0 || selectedGrandparentId.value == 0) {
      Get.snackbar(
        "Required",
        "Please select both Parent and Grandparent accounts",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return;
    }

    isloading.value = true;

    final isWfEnabled = isWorkflowEnabled.value;

    debugPrint("🚀 [CONTROLLER] Assigning Grandparent ID: ${selectedGrandparentId.value} with workflow enabled: $isWfEnabled");

    final model = AssignGrandparentModel(
      userId: selectedParentId.value,
      parentAccountId: selectedParentId.value,
      grandparentAccountId: selectedGrandparentId.value,
      isApprovalWorkflowEnabled: isWfEnabled, // ✅ Pass toggle state for this account
    );

    try {
      final success = await service.assignGrandparent(model);

      if (success) {
        // ✅ Remember which Parent + Grandparent account were just assigned
        // so the User Management list can show them (in green) against
        // every EMTUSER row. Kept in the shared InspectionEligibilityController
        // for immediate app-wide reactivity, and mirrored to SecureStorage so
        // it survives an app restart.
        InspectionEligibilityController.instance.setAssignedAccounts(
          parentName: selectedParentName.value,
          grandparentName: selectedGrandparentName.value,
          parentId: selectedParentId.value,
          grandparentId: selectedGrandparentId.value,
        );
        await SecureStorage.saveAssignedParentAccountName(selectedParentName.value);
        await SecureStorage.saveAssignedGrandparentAccountName(selectedGrandparentName.value);
        await SecureStorage.saveAssignedParentAccountId(selectedParentId.value);
        await SecureStorage.saveAssignedGrandparentAccountId(selectedGrandparentId.value);

        // ✅ Explicitly update ONLY this GrandParentAccount record's approval workflow status
        await service.updateApprovalWorkflow(
          grandParentAccountId: selectedGrandparentId.value,
          isApprovalWorkflowEnabled: isWfEnabled,
        );

        Get.snackbar(
          "Success",
          "Grandparent assigned successfully!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        await Future.delayed(const Duration(seconds: 1));
        Get.offAllNamed(AppPages.HOME);
      } else {
        Get.snackbar(
          "Failed",
          "Could not assign account. Please check your network.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.wifi_off, color: Colors.white),
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      debugPrint("❌ [CONTROLLER] Error assigning grandparent: $e");
      Get.snackbar(
        "Error",
        "Failed to assign grandparent. Please check your network.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.wifi_off, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    } finally {
      isloading.value = false;
    }
  }

  Future<void> fetchParentAccounts() async {
    try {
      debugPrint("📡 [CONTROLLER] Fetching Parent Accounts...");
      final response = await ApiService.getApi(
        endpoint: ApiConstants.getParentAccountList,
      );

      if (response['model'] != null && response['model'].length > 0) {
        final List data = response['model'];
        parentAccounts.value = data.map<Map<String, dynamic>>((item) {
          return {"id": item["parentAccountId"], "name": item["accountName"]};
        }).toList();
        debugPrint("✅ [CONTROLLER] Loaded ${parentAccounts.length} parent accounts.");
      } else {
        Get.snackbar(
          "Error",
          "Failed to load parent accounts. Please check your network.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.wifi_off, color: Colors.white),
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      debugPrint("❌ [CONTROLLER] Error fetching parent accounts: $e");
      Get.snackbar(
        "Error",
        "Failed to fetch parent accounts. Please check your network.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.wifi_off, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> fetchGrandParentAccounts() async {
    try {
      debugPrint("📡 [CONTROLLER] Fetching Grandparent Accounts...");
      final response = await ApiService.getApi(
        endpoint: ApiConstants.getGrandparentAccountList,
      );

      if (response['model'] != null && response['model'].length > 0) {
        final List data = response['model'];
        grandparentAccounts.value = data.map<Map<String, dynamic>>((item) {
          return {
            "id": item["grandParentAccountId"],
            "name": item["grandParentAccountName"],
            "isApprovalWorkflowEnabled": item["isApprovalWorkflowEnabled"] == true,
          };
        }).toList();
        debugPrint("✅ [CONTROLLER] Loaded ${grandparentAccounts.length} grandparent accounts.");
      } else {
        Get.snackbar(
          "Error",
          "Failed to load grandparent accounts. Please check your network.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.wifi_off, color: Colors.white),
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      debugPrint("❌ [CONTROLLER] Error fetching grandparent accounts: $e");
      Get.snackbar(
        "Error",
        "Failed to fetch grandparent accounts. Please check your network.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.wifi_off, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    }
  }
}