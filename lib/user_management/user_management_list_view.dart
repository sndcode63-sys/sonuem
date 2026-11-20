import 'package:emtrack/routes/app_pages.dart';
import 'package:emtrack/user_management/user_management_list_controller.dart';
import 'package:emtrack/utils/app_dialog.dart';
import 'package:emtrack/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/controller.dart';
import '../l10n/app_localizations.dart';
import 'user_list_model.dart';

class UserManagementListView extends StatelessWidget {
  final c = Get.put(UserManagementListController());

  UserManagementListView({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.userManagement),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Get.key.currentState?.canPop() ?? false) {
              Get.back();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Get.offAllNamed(AppPages.HOME);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: w,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Get.toNamed(AppPages.USER_MANAGEMENT_VIEW)?.then((_) {
                      c.fetchUsers();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "+ ${t.createUser.toUpperCase()}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),

            /// 🔍 SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: c.search,
                cursorColor: Colors.red,
                decoration: InputDecoration(
                  hintText: t.searchUser,
                  prefixIcon: const Icon(Icons.search),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2.0),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            /// 🟠 OFFLINE PENDING-SYNC BANNER
            /// Jab tak koi "create user" abhi Hive queue me pending hai
            /// (device offline tha jab banaya gaya), yahan count aur ek
            /// "Sync Now" button dikhta hai.
            Obx(() {
              final pending = c.pendingSyncUsersCount.value;
              if (pending == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_off_rounded,
                          size: 18, color: Colors.orange.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$pending user${pending > 1 ? 's' : ''} pending sync',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                      Obx(() => c.syncingUsers.value
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.orange),
                      )
                          : TextButton(
                        onPressed: c.syncPendingUsers,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Sync Now',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),

            /// 📋 USER LIST
            Expanded(
              child: Obx(() {
                if (c.loading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  );
                }

                if (c.filteredUsers.isEmpty) {
                  return Center(
                    child: Text(
                      t.noDataAvailable,
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: Colors.red,
                  onRefresh: c.fetchUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: c.filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = c.filteredUsers[index];
                      return _userCard(context, user, t);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _userCard(
      BuildContext context, UserlListModel user, AppLocalizations t) {
    final bool hasGrandparent =
        user.grandParentAccountId != null && user.grandParentAccountId! > 0;
    final eligibilityController = InspectionEligibilityController.instance;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: user.isPendingSync
            ? BorderSide(color: Colors.orange.shade300, width: 1.2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── "Pending Sync" chip: offline-created user, backend par
            // abhi tak record nahi bana. ──
            if (user.isPendingSync)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sync_rounded,
                          size: 13, color: Colors.orange.shade800),
                      const SizedBox(width: 5),
                      Text(
                        'Pending Sync',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // ── Assigned Parent / Grandparent Account (green text) ──
            Obx(() {
              final parentName =
                  eligibilityController.assignedParentAccountName.value;
              final grandparentName =
                  eligibilityController.assignedGrandparentAccountName.value;
              if (parentName.isEmpty && grandparentName.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (parentName.isNotEmpty)
                      Text(
                        "Parent Account: $parentName",
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (grandparentName.isNotEmpty)
                      Text(
                        "Grandparent Account: $grandparentName",
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              );
            }),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// LEFT — user data
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Name ──
                      if (user.firstName != null && user.firstName!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            "${user.firstName ?? ''} ${user.middleName ?? ''} ${user.lastName ?? ''}"
                                .trim(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),

                      // ── Role ──
                      if (user.userRole != null &&
                          user.userRole.toString().isNotEmpty)
                        Text(user.userRole.toString(),
                            style: const TextStyle(fontSize: 12)),

                      // ── Email ──
                      if (user.emailAddress != null &&
                          user.emailAddress!.isNotEmpty)
                        Text(user.emailAddress!,
                            style: const TextStyle(fontSize: 12)),

                      // ── Country Code ──
                      if (user.countryCode != null &&
                          user.countryCode!.isNotEmpty)
                        Text(user.countryCode!,
                            style: const TextStyle(fontSize: 12)),

                      // ── Updated Date ──
                      if (user.updatedDate != null)
                        Text(user.updatedDate.toString(),
                            style: const TextStyle(fontSize: 12)),

                      // ── Phone ──
                      if (user.phoneNumber != null &&
                          user.phoneNumber!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "${t.phone}: ${user.phoneNumber}",
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icons row — offline pending-sync rows ke liye
                    // hide kiye hain kyunki inka koi real userId/account
                    // abhi backend par exist nahi karta (sync hone tak).
                    if (!user.isPendingSync)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!hasGrandparent)
                            IconButton(
                              tooltip: "Assign Grandparent Account",
                              icon: const Icon(Icons.person_add,
                                  color: Colors.red),
                              onPressed: () => _showAssignGrandparentDialog(
                                  context, user, t),
                            ),

                          /// 🗑 delete
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => AppDialog.showConfirmDialog(
                              title: t.deleteUser,
                              message: t.deleteUserConfirm,
                              onOk: () {
                                Get.find<UserManagementListController>()
                                    .deleteUser(user);
                              },
                            ),
                          ),
                        ],
                      ),

                    if (hasGrandparent && !user.isPendingSync)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade300),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "GP ID: ${user.grandParentAccountId}",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // ── Approval for Inspection Checkbox ─────
            // Jis user ke account ka workflow enable hai (kisi bhi type ka user),
            // uske card par Approval for Inspection ka checkbox dikhega.
            Obx(() {
              if (user.isPendingSync) {
                return const SizedBox.shrink();
              }
              if (!c.isWorkflowEnabledForUser(user)) {
                return const SizedBox.shrink();
              }
              final approved = (user.isApprover == true) ||
                  eligibilityController.isApproved(user.userId);
              final isUpdating =
                  c.approverStatusUpdating.contains(user.userId ?? '');

              return Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: isUpdating
                      ? const Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.red),
                    ),
                  )
                      : InkWell(
                          onTap: () {
                            c.setApproverStatus(user, !approved);
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: approved,
                                  activeColor: Colors.green.shade700,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  onChanged: (val) {
                                    c.setApproverStatus(user, val ?? false);
                                  },
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  approved
                                      ? "Approved for Inspection"
                                      : "Approve for Inspection",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: approved
                                        ? Colors.green.shade800
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Grandparent assign dialog — searchable list
  void _showAssignGrandparentDialog(
      BuildContext context, UserlListModel user, AppLocalizations t) {
    final RxList<Map<String, dynamic>> filtered = <Map<String, dynamic>>[].obs;
    final RxInt selectedId = 0.obs;
    final RxString selectedName = ''.obs;
    final TextEditingController searchCtrl = TextEditingController();

    filtered.assignAll(c.grandparentAccounts);

    Get.dialog(
      Scaffold(
        appBar: AppBar(
          title: const Text(
            "Assign Grandparent Account",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false,
        ),
        body: Obx(() {
          if (c.grandparentLoading.value) {
            return const AppLoadingIndicator();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: searchCtrl,
                  cursorColor: Colors.red,
                  decoration: InputDecoration(
                    hintText: "${t.searchHint}...",
                    prefixIcon: const Icon(Icons.search, color: Colors.red),
                    enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2)),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (q) {
                    filtered.value = c.grandparentAccounts
                        .where((e) => "${e['id']} : ${e['name']}"
                        .toLowerCase()
                        .contains(q.toLowerCase()))
                        .toList();
                  },
                ),
              ),

              Expanded(
                child: Obx(() {
                  if (filtered.isEmpty) {
                    return Center(child: Text(t.noDataAvailable));
                  }
                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final item = filtered[index];
                      final display = "${item['id']} : ${item['name']}";
                      final workflowOn = item['isApprovalWorkflowEnabled'] == true;
                      return Obx(() {
                        final isSelected = selectedId.value == item['id'];
                        return ListTile(
                          title: Text(
                            display,
                            style: TextStyle(
                              color: isSelected ? Colors.red : Colors.black,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          // Reflects the current isApprovalWorkflowEnabled
                          // state for this grandparent account (from GetAll),
                          // so it's visible right after an update.
                          subtitle: Text(
                            workflowOn
                                ? "Workflow: Enabled"
                                : "Workflow: Disabled",
                            style: TextStyle(
                              fontSize: 11,
                              color: workflowOn ? Colors.green : Colors.grey,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: Colors.red)
                              : null,
                          onTap: () {
                            selectedId.value = item['id'] as int;
                            selectedName.value = item['name'] as String;
                          },
                        );
                      });
                    },
                  );
                }),
              ),

              Container(
                decoration: BoxDecoration(
                    border:
                    Border(top: BorderSide(color: Colors.grey.shade300))),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: Text(t.cancel,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 16)),
                      ),
                    ),
                    Container(
                        width: 1, height: 50, color: Colors.grey.shade300),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          if (selectedId.value == 0) {
                            Get.snackbar(
                              "Required",
                              "Please select a Grandparent Account",
                              backgroundColor: Colors.orange,
                              colorText: Colors.white,
                            );
                            return;
                          }
                          Get.back();
                          c.assignGrandparentToUser(user, selectedId.value);
                        },
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: Text(
                          t.okBtn,
                          style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
      barrierDismissible: false,
    );
  }
}