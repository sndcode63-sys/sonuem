import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emtrack/controllers/controller.dart';
import 'package:emtrack/services/api_constants.dart';
import 'package:emtrack/services/api_service.dart';
import 'package:emtrack/services/grand_parent_account_service/grand_parent_account_service.dart';
import 'package:emtrack/services/network_sync_servives.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/user_management/user_list_model.dart';
import 'package:emtrack/user_management/user_management_list_service.dart';
import 'package:emtrack/utils/app_dialog.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserManagementListController extends GetxController {
  final _service = UserManagementListService();
  final _grandparentService = GrandparentAccountService();

  RxList<UserlListModel> users         = <UserlListModel>[].obs;
  RxList<UserlListModel> filteredUsers = <UserlListModel>[].obs;
  RxBool loading = false.obs;

  /// Kitne "create user" offline-pending hain (Hive queue me, abhi tak
  /// server par sync nahi hue). User Management list screen ke upar
  /// "X user(s) pending sync" chip/banner isi se driven hota hai.
  RxInt pendingSyncUsersCount = 0.obs;
  RxBool syncingUsers = false.obs;

  RxSet<String> approverStatusUpdating = <String>{}.obs;

  RxList<Map<String, dynamic>> grandparentAccounts = <Map<String, dynamic>>[].obs;
  RxBool grandparentLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
    fetchGrandparentAccounts();
    _restoreAssignedAccounts();
  }

  /// Re-hydrates the "last assigned Parent + Grandparent account" (shown in
  /// green above EMTUSER rows) from SecureStorage, in case the app was
  /// restarted after the Grandparent Assign screen set it in-memory.
  Future<void> _restoreAssignedAccounts() async {
    final eligibilityController = InspectionEligibilityController.instance;
    if (eligibilityController.assignedParentAccountName.value.isNotEmpty ||
        eligibilityController.assignedGrandparentAccountName.value.isNotEmpty) {
      return; // already set in-memory this session
    }
    final parentName = await SecureStorage.getAssignedParentAccountName();
    final grandparentName = await SecureStorage.getAssignedGrandparentAccountName();
    final parentId = await SecureStorage.getAssignedParentAccountId();
    final grandparentId = await SecureStorage.getAssignedGrandparentAccountId();
    if (parentName != null && parentName.isNotEmpty) {
      eligibilityController.assignedParentAccountName.value = parentName;
    }
    if (grandparentName != null && grandparentName.isNotEmpty) {
      eligibilityController.assignedGrandparentAccountName.value = grandparentName;
    }
    if (parentId != null) {
      eligibilityController.assignedParentAccountId.value = parentId;
    }
    if (grandparentId != null) {
      eligibilityController.assignedGrandparentAccountId.value = grandparentId;
    }
  }

  Future<void> fetchUsers() async {
    try {
      loading.value = true;
      final data = await _service.getUsers();
      users.assignAll(data);
      filteredUsers.assignAll(data);
      _mergeOfflinePendingUsers();

      // ── Seed the shared eligibility controller's approvedUserIds set
      // from the server truth (isApprover flag from GetAllUsers), so the
      // checkbox/"Approved for Inspection" chip reflects real backend
      // state instead of only in-memory taps from this session.
      final eligibilityController = InspectionEligibilityController.instance;
      final approvedIds = data
          .where((u) => u.isApprover == true)
          .map((u) => u.userId)
          .whereType<String>()
          .toSet();
      eligibilityController.approvedUserIds.assignAll(approvedIds);
      debugPrint(
        '✅ [UserManagementListController] Seeded ${approvedIds.length} '
            'approver(s) from GetAllUsers response: $approvedIds',
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to load users. Please check your network.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.wifi_off, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    } finally {
      loading.value = false;
    }
  }

  /// Server list ke UPAR, abhi-tak-un-synced offline "createUser"
  /// operations ko placeholder row ke roop me dikhata hai (orange
  /// "Pending Sync" chip ke saath). Jaise hi woh op sync ho jata hai
  /// aur `fetchUsers()` dubara chalta hai, yeh placeholder khud hat
  /// jata hai (kyunki tab woh asli server list me aa jayega).
  void _mergeOfflinePendingUsers() {
    final pendingOps = OfflineHiveService.getPendingOperationsByType('createUser');
    pendingSyncUsersCount.value = pendingOps.length;
    if (pendingOps.isEmpty) return;

    final pendingModels = pendingOps
        .map((op) => UserlListModel.fromPendingPayload(
        Map<String, dynamic>.from(op.payload)))
        .toList();

    users.insertAll(0, pendingModels);
    filteredUsers.insertAll(0, pendingModels);
  }

  /// Manual "Sync Now" button (User Management list ke upar) — offline
  /// pending users (aur baaki saara pending queue) ko turant sync karne
  /// ki koshish karta hai, phir list refresh kar deta hai.
  Future<void> syncPendingUsers() async {
    if (pendingSyncUsersCount.value == 0 || syncingUsers.value) return;

    final results = await Connectivity().checkConnectivity();
    final online = results.any((r) => r != ConnectivityResult.none);
    if (!online) {
      Get.snackbar(
        'No Internet',
        'Please connect to the internet to sync pending users.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    syncingUsers.value = true;
    try {
      await ManualSyncService.syncNow();
    } finally {
      syncingUsers.value = false;
      await fetchUsers();
    }
  }

  Future<void> fetchGrandparentAccounts() async {
    try {
      grandparentLoading.value = true;
      final response = await ApiService.getApi(
        endpoint: ApiConstants.getGrandparentAccountList,
      );
      if (response['model'] != null && response['model'].length > 0) {
        final List data = response['model'];
        grandparentAccounts.value = data.map<Map<String, dynamic>>((item) {
          return {
            "id": item["grandParentAccountId"],
            "name": item["grandParentAccountName"],
            "isApprovalWorkflowEnabled": item["isApprovalWorkflowEnabled"] ?? false,
            "isActive": item["isActive"] ?? true,
          };
        }).toList();
        debugPrint(
          "✅ [fetchGrandparentAccounts] Refreshed ${grandparentAccounts.length} "
              "grandparent account(s) from GetAll.",
        );
      }
    } catch (_) {
    } finally {
      grandparentLoading.value = false;
    }
  }

  /// Checks whether approval workflow is enabled for this user's Grandparent Account.
  /// If enabled (or if user is already an approver), the "Approve for Inspection"
  /// checkbox is displayed on their card.
  bool isWorkflowEnabledForUser(UserlListModel user) {
    if (user.isApprover == true) return true;
    final gpId = user.grandParentAccountId;
    if (gpId == null || gpId <= 0) return false;
    final match = grandparentAccounts.firstWhereOrNull((g) => g['id'] == gpId);
    if (match != null) {
      return match['isApprovalWorkflowEnabled'] == true;
    }
    return false;
  }

  void search(String value) {
    if (value.trim().isEmpty) {
      filteredUsers.assignAll(users);
      return;
    }
    final query = value.toLowerCase();
    filteredUsers.assignAll(
      users.where((u) {
        final first  = (u.firstName ?? '').toLowerCase();
        final last   = (u.lastName  ?? '').toLowerCase();
        final userId = (u.userId    ?? '').toLowerCase();
        return first.contains(query) ||
            last.contains(query)  ||
            userId.contains(query);
      }),
    );
  }

  Future<void> deleteUser(UserlListModel user) async {
    try {
      final username = user.userId;
      if (username == null || username.isEmpty) {
        Get.snackbar(
          "Error",
          "Invalid user ID. Please check your network.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.wifi_off, color: Colors.white),
          duration: const Duration(seconds: 4),
        );
        return;
      }

      await _service.deleteUser(username);

      users.remove(user);
      filteredUsers.remove(user);

      Get.snackbar(
        "Deleted",
        "User deleted successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint("Delete error: $e");
      Get.snackbar(
        "Error",
        "Failed to delete user. Please check your network.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.wifi_off, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    }
  }


  /// Called when the "Approve for Inspection" checkbox is tapped in the
  /// User Management list for an EMTUSER.
  /// When checking ON: validates that the user already has a Grandparent
  /// Account assigned, then sets isApprover = true on the backend.
  /// When unchecking: sets isApprover = false on the backend.
  Future<void> setApproverStatus(UserlListModel user, bool isApprover) async {
    final userId = user.userId;
    if (userId == null || userId.isEmpty) return;

    // ── Validation: User must have a Grandparent Account ID before being approved ──
    final displayName = user.firstName ?? user.userId ?? 'User';
    final hasGrandparent =
        user.grandParentAccountId != null && user.grandParentAccountId! > 0;
    if (isApprover && !hasGrandparent) {
      Get.snackbar(
        "Grandparent Account Required",
        "Please assign a Grandparent Account to $displayName first before approving for inspection.",
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
      return;
    }

    if (approverStatusUpdating.contains(userId)) return;

    final eligibilityController = InspectionEligibilityController.instance;
    approverStatusUpdating.add(userId);

    try {
      final success = await _service.updateApproverStatus(user, isApprover);

      if (!success) {
        Get.snackbar(
          "Failed",
          "Could not update approver status. Please check your network.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.wifi_off, color: Colors.white),
          duration: const Duration(seconds: 4),
        );
        return;
      }

      eligibilityController.toggleApproval(userId, isApprover);

      // Keep the local list rows in sync too
      final idx = users.indexWhere((u) => u.userId == userId);
      if (idx != -1) users[idx] = users[idx].copyWith(isApprover: isApprover);
      final fidx = filteredUsers.indexWhere((u) => u.userId == userId);
      if (fidx != -1) {
        filteredUsers[fidx] =
            filteredUsers[fidx].copyWith(isApprover: isApprover);
      }

      Get.snackbar(
        "Success",
        isApprover
            ? "$displayName approved for inspection successfully!"
            : "Approval removed for $displayName.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint("Error updating approver status for $userId: $e");
      Get.snackbar(
        "Error",
        "Failed to update approver status. Please check your network.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.wifi_off, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    } finally {
      approverStatusUpdating.remove(userId);
    }
  }

  RxSet<String> workflowStatusUpdating = <String>{}.obs;

  /// Shared by both the "Approve for Inspection" (when checking ON) and
  /// "Enable Workflow" checkboxes:
  ///
  ///  1. PUT /api/UserProfile/AssignGrandParentAccount
  ///     -> assigns the Grandparent Account (selected on the Grandparent
  ///        Assign screen) to THIS user. Only called when the user has no
  ///        Grandparent yet, or a reassign was confirmed.
  ///  2. PUT /api/GrandParentAccount/Update
  ///     -> sets isApprovalWorkflowEnabled = [enableWorkflow] on the
  ///        relevant Grandparent Account (new one if (re)assigned, OLD one
  ///        if the user already had one and declined to change it).
  ///
  /// Behaviour when the user already has a Parent/Grandparent assigned (the
  /// person_add "Assign Grandparent Account" icon on their card is already
  /// hidden) AND a *different* Parent/Grandparent is selected on the
  /// Grandparent Assign screen:
  ///   - A confirmation dialog is shown — "Update Assignment?"
  ///   - "Yes"  -> reassigns to the NEW Parent/Grandparent, workflow flag
  ///               is set on the NEW account.
  ///   - "No"   -> keeps the user's OLD Parent/Grandparent as-is (no
  ///               reassign call at all), but the workflow flag is still
  ///               applied to that OLD account so Approve/Enable Workflow
  ///               completes successfully using the existing assignment.
  ///
  /// If the user already has a Grandparent and nothing new (or the same
  /// one) is selected on the Assign screen, no dialog is shown — the
  /// workflow flag is simply applied to the existing account.
  ///
  /// Both requests + responses are printed with debugPrint so they can be
  /// cross-checked in Postman using the same endpoint/body.
  ///
  /// Returns true if a Grandparent account (new OR existing) ended up with
  /// the workflow flag successfully applied; false only when there's no
  /// Grandparent to work with at all, or an API call fails.
  Future<bool> _assignParentGrandparentToUser(
      UserlListModel user, {
        required bool enableWorkflow,
      }) async {
    final userId = user.userId;
    if (userId == null || userId.isEmpty) return false;

    final eligibilityController = InspectionEligibilityController.instance;
    final newGrandparentId = eligibilityController.assignedGrandparentAccountId.value;
    final oldGrandparentId = user.grandParentAccountId;
    final hasGrandparent = oldGrandparentId != null && oldGrandparentId > 0;

    // Nothing assigned to this user yet AND nothing selected on the Assign
    // screen either — there's no Grandparent account to work with.
    if (!hasGrandparent && newGrandparentId == 0) {
      Get.snackbar(
        "Required",
        "Please assign a Parent + Grandparent account from the "
            "Grandparent Assign screen first.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    final wantsReassign = newGrandparentId != 0 && newGrandparentId != oldGrandparentId;

    // Already assigned to a DIFFERENT Grandparent than the one currently
    // selected on the Assign screen -> confirm before overwriting it.
    if (hasGrandparent && wantsReassign) {
      final confirmed = await _confirmReassignDialog();
      if (!confirmed) {
        // Keep the OLD Parent/Grandparent assignment — no reassign call —
        // but still apply the workflow flag to that existing account so
        // Approve/Enable Workflow still goes through using the old data.
        debugPrint(
          "🚫 [assign] userId=$userId declined reassign — keeping existing "
              "grandParentAccountId=$oldGrandparentId, applying "
              "isApprovalWorkflowEnabled=$enableWorkflow to it",
        );
        debugPrint(
          "🌐 [assign] PUT /api/GrandParentAccount/Update "
              "grandParentAccountId=$oldGrandparentId, isApprovalWorkflowEnabled=$enableWorkflow",
        );
        final workflowSuccess = await _grandparentService.updateApprovalWorkflow(
          grandParentAccountId: oldGrandparentId!,
          isApprovalWorkflowEnabled: enableWorkflow,
        );
        debugPrint("📥 [assign] Workflow-on-old-account result: $workflowSuccess");

        if (!workflowSuccess) {
          Get.snackbar(
            "Failed",
            "Could not update workflow on the existing Grandparent account.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
            icon: const Icon(Icons.wifi_off, color: Colors.white),
            duration: const Duration(seconds: 4),
          );
          return false;
        }

        Get.snackbar(
          "Kept Existing",
          "Existing Parent & Grandparent account assignment was kept, "
              "workflow updated.",
          backgroundColor: Colors.blueGrey,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return true;
      }
      // "Yes" -> fall through and assign the NEW Grandparent below.
    }

    // Target account: the NEW one if we're (re)assigning, otherwise the
    // user's existing one (nothing changed, just apply workflow to it).
    final targetGrandparentId = wantsReassign ? newGrandparentId : (oldGrandparentId ?? newGrandparentId);

    // Only actually call the assign API when setting the Grandparent for
    // the first time, or genuinely changing it.
    if (!hasGrandparent || wantsReassign) {
      debugPrint(
        "🌐 [assign] Step 1: PUT /api/UserProfile/AssignGrandParentAccount "
            "username=$userId, grandParentAccountId=$targetGrandparentId",
      );
      final assignSuccess = await _grandparentService.assignGrandParentAccountToUser(
        username: userId,
        grandParentAccountId: targetGrandparentId,
      );
      debugPrint("📥 [assign] Step 1 result: $assignSuccess");

      if (!assignSuccess) {
        Get.snackbar(
          "Failed",
          "Could not assign Parent/Grandparent account. Please check your network.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.wifi_off, color: Colors.white),
          duration: const Duration(seconds: 4),
        );
        return false;
      }
    }

    debugPrint(
      "🌐 [assign] Step 2: PUT /api/GrandParentAccount/Update "
          "grandParentAccountId=$targetGrandparentId, isApprovalWorkflowEnabled=$enableWorkflow",
    );
    final workflowSuccess = await _grandparentService.updateApprovalWorkflow(
      grandParentAccountId: targetGrandparentId,
      isApprovalWorkflowEnabled: enableWorkflow,
    );
    debugPrint("📥 [assign] Step 2 result: $workflowSuccess");

    if (!workflowSuccess) {
      Get.snackbar(
        "Failed",
        "Could not update workflow flag. Please check your network.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.wifi_off, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
      return false;
    }

    // Keep local rows in sync so `hasGrandparent` flips true immediately and
    // the person_add "Assign Grandparent Account" icon hides without a
    // refetch.
    final idx = users.indexWhere((u) => u.userId == userId);
    if (idx != -1) users[idx] = users[idx].copyWith(grandParentAccountId: targetGrandparentId);
    final fidx = filteredUsers.indexWhere((u) => u.userId == userId);
    if (fidx != -1) {
      filteredUsers[fidx] = filteredUsers[fidx].copyWith(grandParentAccountId: targetGrandparentId);
    }

    return true;
  }

  /// "Yes" -> true (reassign/update), "No" -> false (keep old assignment).
  Future<bool> _confirmReassignDialog() {
    final completer = Completer<bool>();
    AppDialog.showConfirmDialog(
      title: "Update Assignment?",
      message: "This user is already assigned to a Parent & Grandparent "
          "account.\nDo you want to update/reassign it?",
      okText: "Yes",
      cancelText: "No",
      onOk: () => completer.complete(true),
      onCancel: () => completer.complete(false),
    );
    return completer.future;
  }

  /// Called when the "Enable Workflow" checkbox is tapped in the User
  /// Management list for an EMTUSER. Assigns the Grandparent Account
  /// (confirming reassignment if one is already set) and sets the workflow
  /// flag — see `_assignParentGrandparentToUser` for the API calls made.
  Future<void> setWorkflowStatus(UserlListModel user, bool isWorkflowEnabled) async {
    final userId = user.userId;
    if (userId == null || userId.isEmpty) return;

    workflowStatusUpdating.add(userId);
    try {
      final assigned = await _assignParentGrandparentToUser(
        user,
        enableWorkflow: isWorkflowEnabled,
      );
      if (!assigned) return; // snackbar already shown by the helper

      InspectionEligibilityController.instance.toggleWorkflow(userId, isWorkflowEnabled);

      Get.snackbar(
        "Success",
        isWorkflowEnabled
            ? "Workflow enabled & grandparent account assigned"
            : "Workflow disabled for user",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint("❌ [Enable Workflow] Exception for userId=$userId: $e");
      Get.snackbar(
        "Error",
        "Failed to update workflow. Please check your network.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.wifi_off, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    } finally {
      workflowStatusUpdating.remove(userId);
    }
  }

  Future<void> assignGrandparentToUser(UserlListModel user, int grandparentId) async {
    try {
      final username = user.userId;
      debugPrint("🚀 [assignGrandparentToUser] Started for username: $username, Grandparent ID: $grandparentId");

      if (username == null || username.isEmpty) {
        debugPrint("⚠️ [assignGrandparentToUser] Invalid/empty username, aborting.");
        Get.snackbar(
          "Error",
          "Invalid user. Please check your network.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.wifi_off, color: Colors.white),
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // ✅ Assign ka call ab dedicated API se hi hota hai:
      //    PUT /api/UserProfile/AssignGrandParentAccount
      //    body: { "username": ..., "grandParentAccountId": ... }
      final success = await _grandparentService.assignGrandParentAccountToUser(
        username: username,
        grandParentAccountId: grandparentId,
      );
      debugPrint("📡 [assignGrandparentToUser] API Result Success: $success");

      if (success) {
        final idx = users.indexWhere((u) => u.userId == user.userId);
        if (idx != -1) {
          users[idx] = users[idx].copyWith(grandParentAccountId: grandparentId);
          debugPrint("✅ [assignGrandparentToUser] Updated main users list at index $idx");
        }

        final fidx = filteredUsers.indexWhere((u) => u.userId == user.userId);
        if (fidx != -1) {
          filteredUsers[fidx] = filteredUsers[fidx].copyWith(grandParentAccountId: grandparentId);
          debugPrint("✅ [assignGrandparentToUser] Updated filtered users list at index $fidx");
        }

        // Refresh grandparent accounts so updated assignments reflect immediately
        await fetchGrandparentAccounts();

        Get.snackbar(
          "Success",
          "Grandparent account assigned successfully!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        debugPrint("⚠️ [assignGrandparentToUser] API returned failure (success = false)");
        Get.snackbar(
          "Failed",
          "Could not assign account. Please check your network.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.wifi_off, color: Colors.white),
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e, stackTrace) {
      debugPrint("❌ [assignGrandparentToUser] Exception caught: $e");
      debugPrint("📍 [assignGrandparentToUser] StackTrace: $stackTrace");
      Get.snackbar(
        "Error",
        "Failed to assign grandparent. Please check your network.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.wifi_off, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    }
  }}