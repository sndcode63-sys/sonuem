import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';

/// Shared, app-wide controller that holds the "Eligible for Inspection"
/// enable/disable toggle state, plus the set of userIds that have been
/// approved for inspection via the checkbox in User Management.
///
/// NOTE (UI-only phase): No API calls are wired up here yet. All state is
/// kept in-memory. Hook the TODOs below to the real endpoints later.
class InspectionEligibilityController extends GetxController {
  /// Returns the single shared instance app-wide (creates it on first use).
  static InspectionEligibilityController get instance {
    if (Get.isRegistered<InspectionEligibilityController>()) {
      return Get.find<InspectionEligibilityController>();
    }
    return Get.put(InspectionEligibilityController(), permanent: true);
  }

  /// Master enable/disable toggle. When true -> checkboxes show up against
  /// every user in User Management list. When false -> checkboxes are hidden.
  final RxBool isEligibleForInspection = false.obs;

  /// userIds that have been checked (approved for inspection).
  final RxSet<String> approvedUserIds = <String>{}.obs;

  /// userIds for whom the "Enable Workflow" checkbox has been checked in
  /// User Management. This is separate from `approvedUserIds` above:
  /// approval decides who can approve an inspection, this decides whether
  /// the approval workflow itself is switched on for that particular user.
  final RxSet<String> workflowEnabledUserIds = <String>{}.obs;

  /// Parent + Grandparent account (with IDs) that was most recently assigned
  /// from the Grandparent Assign screen ("Assign Account" step). Once set
  /// (and while `isEligibleForInspection` is true), the names are shown in
  /// green text above every EMTUSER row in the User Management list, and
  /// the IDs are used by the "Enable Workflow" checkbox to actually call
  /// the assign/workflow APIs for that user.
  final RxString assignedParentAccountName = ''.obs;
  final RxString assignedGrandparentAccountName = ''.obs;
  final RxInt assignedParentAccountId = 0.obs;
  final RxInt assignedGrandparentAccountId = 0.obs;

  /// Called from the toggle switch (in the assign-account screen and its
  /// dialog).
  void setEligibility(bool value) {
    isEligibleForInspection.value = value;

    // When the feature gets disabled, clear out any selections so a stale
    // approval doesn't silently linger if it's re-enabled later.
    if (!value) {
      approvedUserIds.clear();
      workflowEnabledUserIds.clear();
    }

    // TODO(API): persist this enable/disable flag to backend once API is ready.
  }

  /// Called right after a successful "Assign" on the Grandparent Assign
  /// screen — remembers which Parent + Grandparent account (name + id) were
  /// just assigned so the User Management list can display them and use
  /// their IDs for the per-user "Enable Workflow" API calls.
  void setAssignedAccounts({
    required String parentName,
    required String grandparentName,
    required int parentId,
    required int grandparentId,
  }) {
    assignedParentAccountName.value = parentName;
    assignedGrandparentAccountName.value = grandparentName;
    assignedParentAccountId.value = parentId;
    assignedGrandparentAccountId.value = grandparentId;
    debugPrint(
      '🏷️ [InspectionEligibilityController] setAssignedAccounts('
      'parent=$parentName#$parentId, grandparent=$grandparentName#$grandparentId)',
    );
  }

  bool isWorkflowEnabled(String? userId) {
    if (userId == null) return false;
    return workflowEnabledUserIds.contains(userId);
  }

  /// Called when a user's "Enable Workflow" checkbox is tapped in User
  /// Management.
  void toggleWorkflow(String? userId, bool value) {
    if (userId == null) return;
    if (value) {
      workflowEnabledUserIds.add(userId);
    } else {
      workflowEnabledUserIds.remove(userId);
    }
    debugPrint(
      '🔁 [InspectionEligibilityController] toggleWorkflow(userId=$userId, '
      'value=$value) -> workflowEnabledUserIds=$workflowEnabledUserIds',
    );
  }

  bool isApproved(String? userId) {
    if (userId == null) return false;
    return approvedUserIds.contains(userId);
  }

  /// Called when a user's row checkbox is tapped in User Management.
  void toggleApproval(String? userId, bool value) {
    if (userId == null) return;
    if (value) {
      approvedUserIds.add(userId);
    } else {
      approvedUserIds.remove(userId);
    }
    debugPrint(
      '🔁 [InspectionEligibilityController] toggleApproval(userId=$userId, '
      'value=$value) -> approvedUserIds=$approvedUserIds',
    );

    // Actual persistence to backend now happens in
    // UserManagementListController.setApproverStatus(), which calls this
    // for the optimistic UI update and then hits
    // POST /api/UserProfile/CreateUserProfile with isApprover.
  }
}