import 'package:emtrack/models/grand_parent_account_model/assign_grand_parent_model.dart';
import 'package:emtrack/models/grand_parent_account_model/grand_parent_account_model.dart';
import 'package:emtrack/services/api_constants.dart';
import 'package:emtrack/services/api_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GrandparentAccountService {
  Future<bool> createGrandparent(GrandparentAccountModel model) async {
    try {
      final body = model.toJson();
      debugPrint("🌐 [API SERVICE] POST: ${ApiConstants.createGrandParentAccount}");
      debugPrint("📦 [API SERVICE] Request Body: $body");

      final response = await ApiService.postApi(
        endpoint: ApiConstants.createGrandParentAccount,
        body: body,
      );

      debugPrint("📥 [API SERVICE] Response: $response");

      if (response['httpStatusCode'] == 200) {
        debugPrint("✅ [API SERVICE] Grandparent created successfully!");
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ [API SERVICE] Exception in createGrandparent: $e");
      Get.snackbar("Error", "Failed to create grandparent: $e");
      return false;
    }
  }

  Future<bool> assignGrandparent(AssignGrandparentModel model) async {
    try {
      final body = model.toJson();
      debugPrint("🌐 [API SERVICE] POST/UPDATE: ${ApiConstants.updateGrandParentAccount}");
      debugPrint("📦 [API SERVICE] Request Body (Assign/Update): $body");

      final response = await ApiService.postApi(
        endpoint: ApiConstants.updateGrandParentAccount,
        body: body,
      );

      debugPrint("📥 [API SERVICE] Response: $response");

      if (response['httpStatusCode'] == 200) {
        debugPrint("✅ [API SERVICE] Grandparent assigned/updated successfully!");
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ [API SERVICE] Exception in assignGrandparent: $e");
      return false;
    }
  }

  /// User Management list ke "Assign Grandparent Account" (person_add icon)
  /// action ke liye dedicated call — is API se hi assign hoga:
  ///
  ///   PUT /api/UserProfile/AssignGrandParentAccount
  ///   body: { "username": "<string>", "grandParentAccountId": <long> }
  ///
  /// NOTE: Yeh purane `assignGrandparent()` (ParentAccount/UpdateGrandParentAccount)
  /// se ALAG hai — us wala Grand Parent Account creation-flow screen ke liye
  /// hai, ise touch nahi kiya. Yeh sirf User Management list ke assign icon
  /// ke liye hai.
  Future<bool> assignGrandParentAccountToUser({
    required String username,
    required int grandParentAccountId,
  }) async {
    final body = {
      "username": username,
      "grandParentAccountId": grandParentAccountId,
    };

    try {
      debugPrint(
        "🌐 [API SERVICE] PUT: ${ApiConstants.assignGrandParentAccountToUser}",
      );
      debugPrint("📦 [API SERVICE] Request Body: $body");

      final response = await ApiService.putApi(
        endpoint: ApiConstants.assignGrandParentAccountToUser,
        body: body,
      );

      debugPrint("📥 [API SERVICE] Response: $response");

      // Kuch "Update"-style endpoints 200 par empty body ya sirf message
      // wapas dete hain — httpStatusCode field ka strictly wait nahi karna,
      // sirf explicit error indicator par fail treat karo.
      if (response is Map) {
        final errorMessage = response["errorMessage"] ?? response["error"];
        final hasErrorMessage =
            errorMessage != null && errorMessage.toString().trim().isNotEmpty;
        if (hasErrorMessage) {
          debugPrint(
            "❌ [API SERVICE] AssignGrandParentAccount failed: $errorMessage",
          );
          return false;
        }
      }

      debugPrint("✅ [API SERVICE] Grandparent assigned to user successfully!");
      return true;
    } catch (e) {
      debugPrint(
        "❌ [API SERVICE] Exception in assignGrandParentAccountToUser: $e",
      );
      return false;
    }
  }

  /// Enables/disables the "Eligible for Inspection" approval workflow on a
  /// GrandParentAccount by hitting:
  ///
  ///   PUT /api/GrandParentAccount/Update
  ///   body: {
  ///     grandParentAccountId, grandParentAccountName, ownedBy, createdBy,
  ///     createdDate, updatedBy, updatedDate, isActive,
  ///     isApprovalWorkflowEnabled
  ///   }
  ///
  /// This is a full-object PUT, so we first fetch the current record via
  /// FindById to avoid wiping out fields we're not trying to change (name,
  /// ownedBy, createdBy/createdDate, isActive), then send it back with only
  /// `isApprovalWorkflowEnabled` (and updatedBy/updatedDate) changed.
  Future<bool> updateApprovalWorkflow({
    required int grandParentAccountId,
    required bool isApprovalWorkflowEnabled,
  }) async {
    try {
      debugPrint(
        "🌐 [API SERVICE] GET: ${ApiConstants.findGrandParentAccountById(grandParentAccountId)}",
      );
      final current = await ApiService.getApi(
        endpoint: ApiConstants.findGrandParentAccountById(grandParentAccountId),
      );

      // Some endpoints wrap the record in "model", some return it raw.
      Map<String, dynamic> record = {};
      if (current is Map) {
        final m = current["model"];
        if (m is Map<String, dynamic>) {
          record = m;
        } else if (m is List && m.isNotEmpty && m.first is Map) {
          record = Map<String, dynamic>.from(m.first as Map);
        } else {
          record = Map<String, dynamic>.from(current);
        }
      }

      final userName = await SecureStorage.getUserName();

      final body = {
        "grandParentAccountId": grandParentAccountId,
        "grandParentAccountName": record["grandParentAccountName"] ?? "",
        "ownedBy": record["ownedBy"] ?? "",
        "createdBy": record["createdBy"] ?? "",
        "createdDate": record["createdDate"],
        "updatedBy": userName?.toString() ?? record["updatedBy"] ?? "",
        "updatedDate": DateTime.now().toIso8601String(),
        "isActive": record["isActive"] ?? true,
        "isApprovalWorkflowEnabled": isApprovalWorkflowEnabled,
      };

      debugPrint(
        "🌐 [API SERVICE] PUT: ${ApiConstants.updateGrandParentAccountWorkflow}",
      );
      debugPrint("📦 [API SERVICE] Request Body (Workflow Update): $body");

      final response = await ApiService.putApi(
        endpoint: ApiConstants.updateGrandParentAccountWorkflow,
        body: body,
      );

      debugPrint("📥 [API SERVICE] Response: $response");

      if (response is Map) {
        final errorMessage = response["errorMessage"] ?? response["error"];
        final hasErrorMessage =
            errorMessage != null && errorMessage.toString().trim().isNotEmpty;
        if (hasErrorMessage) {
          debugPrint(
            "❌ [API SERVICE] updateApprovalWorkflow failed: $errorMessage",
          );
          return false;
        }
      }

      debugPrint("✅ [API SERVICE] Approval workflow updated successfully!");
      return true;
    } catch (e) {
      debugPrint("❌ [API SERVICE] Exception in updateApprovalWorkflow: $e");
      return false;
    }
  }
}