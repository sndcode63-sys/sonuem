import 'package:emtrack/color/app_color.dart';
import 'package:emtrack/controllers/grand_parent_account_controller/grand_parent_account_controller.dart';
import 'package:emtrack/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../l10n/app_localizations.dart';

class GrandparentAccountView extends StatelessWidget {
  final c = Get.put(GrandparentAccountController());

  GrandparentAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Get.back();
            } else {
              Get.offAllNamed('/home');
            }
          },
        ),
        title: Text(
          t.grandparentAccountInformation,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Obx(
              () => Stack(
            children: [
              Column(
                children: [
                  _stepHeader(t),
                  Expanded(child: _stepBody(t)),
                ],
              ),
              if (c.isloading.value)
                Container(
                  color: Colors.black.withAlpha(128),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// STEP HEADER
  Widget _stepHeader(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Step 0: Create Account
          GestureDetector(
            onTap: () => c.currentStep.value = 0,
            child: _stepCircle(0, t.createAccount),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Icon(
              Icons.chevron_right,
              color: c.currentStep.value >= 1 ? Colors.green : Colors.grey,
              size: 32,
            ),
          ),

          // Step 1: Assign Account
          GestureDetector(
            onTap: () => c.currentStep.value = 1,
            child: _stepCircle(1, t.assignAccount),
          ),
        ],
      ),
    );
  }

  Widget _stepCircle(int step, String title) {
    final isCompleted = step < c.currentStep.value;
    final isCurrent = step == c.currentStep.value;

    Color color = isCompleted
        ? Colors.green
        : (isCurrent ? Colors.yellow.shade700 : Colors.grey);

    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color,
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white)
              : Text("${step + 1}", style: const TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? Colors.black : Colors.grey,
          ),
        ),
      ],
    );
  }

  /// BODY SWITCHER
  Widget _stepBody(AppLocalizations t) {
    return c.currentStep.value == 0 ? _createAccountUI(t) : _assignAccountUI(t);
  }

  /// STEP-1 UI: CREATE ACCOUNT
  Widget _createAccountUI(AppLocalizations t) {
    return Form(
      key: c.createFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              t.createAccount,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: c.accountTypeController,
              cursorColor: Colors.red,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: t.accountTypeLabel,
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 2.0),
                ),
                floatingLabelStyle: const TextStyle(color: Colors.red),
                errorBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? "${t.accountTypeLabel} is required"
                  : null,
              onChanged: (v) => c.accountType.value = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              cursorColor: Colors.red,
              decoration: InputDecoration(
                labelText: t.grandparentNameLabel,
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 2.0),
                ),
                floatingLabelStyle: const TextStyle(color: Colors.red),
                errorBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? "${t.grandparentNameLabel} is required"
                  : null,
              onChanged: (v) => c.grandparentName.value = v,
            ),

            // ── Enable Workflow Toggle ──
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _workflowToggle(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.toNamed(AppPages.HOME),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(t.cancel,
                        style: const TextStyle(color: Colors.red)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Obx(
                    () => ElevatedButton(
                      onPressed: c.isloading.value
                          ? null
                          : () {
                              if (c.createFormKey.currentState!.validate()) {
                                c.createGrandparent();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.red,
                        disabledBackgroundColor: Colors.red.withAlpha(180),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: c.isloading.value
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(t.save,
                              style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// STEP-2 UI: ASSIGN ACCOUNT
  Widget _assignAccountUI(AppLocalizations t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            t.assignAccount,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // ── Parent Account ──
          _searchableDropdown(
            label: t.selectParentAccount,
            selectedValue: c.selectedParentId,
            displayText: c.selectedParentName,
            items: c.parentAccounts,
            onSelect: (id) => c.selectedParentId.value = id,
            t: t,
          ),

          const SizedBox(height: 12),

          // ── Grandparent Account ──
          _searchableDropdown(
            label: t.selectGrandparentAccount,
            selectedValue: c.selectedGrandparentId,
            displayText: c.selectedGrandparentName,
            items: c.grandparentAccounts,
            onSelect: (id) {
              c.selectedGrandparentId.value = id;
              final match = c.grandparentAccounts.firstWhereOrNull((item) => item['id'] == id);
              if (match != null && match['isApprovalWorkflowEnabled'] != null) {
                c.isWorkflowEnabled.value = match['isApprovalWorkflowEnabled'] == true;
              }
            },
            t: t,
          ),

          // ── Enable Workflow Toggle ──
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _workflowToggle(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: c.previous,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(t.cancel,
                      style: const TextStyle(color: Colors.red)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Obx(
                  () => ElevatedButton(
                    onPressed: c.isloading.value ? null : c.assignGrandparent,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.red,
                      disabledBackgroundColor: Colors.red.withAlpha(180),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: c.isloading.value
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(t.assignBtn,
                            style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _workflowToggle() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: Colors.red,
          title: const Text(
            "Enable Workflow",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            "Enable approval workflow for this account and all its EMT users",
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          value: c.isWorkflowEnabled.value,
          onChanged: (val) {
            debugPrint("🟢 [UI] Enable Workflow Toggle changed to: $val");
            c.isWorkflowEnabled.value = val;
          },
        ),
      ),
    );
  }

  Widget _searchableDropdown({
    required String label,
    required RxInt selectedValue,
    required RxString displayText,
    required List<Map<String, dynamic>> items,
    required Function(int) onSelect,
    required AppLocalizations t,
  }) {
    return Obx(() {
      final hasValue = selectedValue.value != 0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _openFullScreenDialog(
              label: label,
              items: items,
              currentId: selectedValue.value,
              onSelect: (id, name) {
                selectedValue.value = id;
                displayText.value = name;
              },
              t: t,
            ),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasValue
                          ? displayText.value
                          : "${t.selectPrefix} $label",
                      style: TextStyle(
                        fontSize: 14,
                        color: hasValue ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.red),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  void _openFullScreenDialog({
    required String label,
    required List<Map<String, dynamic>> items,
    required int currentId,
    required Function(int id, String name) onSelect,
    required AppLocalizations t,
  }) {
    final RxList<Map<String, dynamic>> filtered =
        <Map<String, dynamic>>[].obs;
    final TextEditingController searchCtrl = TextEditingController();
    final RxInt tempId = currentId.obs;

    filtered.assignAll(items);

    Get.dialog(
      Scaffold(
        appBar: AppBar(
          title: Text("${t.selectPrefix} $label",
              style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false,
        ),
        body: Column(
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
                  filtered.value = items
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
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, index) {
                    final item = filtered[index];
                    final displayText = "${item['id']} : ${item['name']}";
                    return Obx(() {
                      final isSelected = item['id'] == tempId.value;
                      return ListTile(
                        title: Text(
                          displayText,
                          style: TextStyle(
                            color: isSelected ? Colors.red : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: Colors.red)
                            : null,
                        onTap: () => tempId.value = item['id'] as int,
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
                          padding:
                          const EdgeInsets.symmetric(vertical: 16)),
                      child: Text(t.cancel,
                          style:
                          const TextStyle(color: Colors.red, fontSize: 16)),
                    ),
                  ),
                  Container(
                      width: 1, height: 50, color: Colors.grey.shade300),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        if (tempId.value != 0) {
                          final selected = items.firstWhere(
                                  (e) => e['id'] == tempId.value,
                              orElse: () => {});
                          if (selected.isNotEmpty) {
                            onSelect(
                              selected['id'] as int,
                              "${selected['id']} : ${selected['name']}",
                            );
                          }
                          Get.back();
                        }
                      },
                      style: TextButton.styleFrom(
                          padding:
                          const EdgeInsets.symmetric(vertical: 16)),
                      child: Text(t.okBtn,
                          style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }
}