import 'package:emtrack/color/app_color.dart';
import 'package:emtrack/controllers/change_account_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../l10n/app_localizations.dart';

class ChangeAccountView extends StatelessWidget {
  ChangeAccountView({super.key});

  final ctrl = Get.put(ChangeAccountController());

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          t.changeLocationAccount,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ctrl.isOffline.value)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.wifi_off,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Offline — showing cached data',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                t.selectedParentAccountLocation,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _roundCheckbox(t.own, ctrl.ownSelected),
                  const SizedBox(width: 50),
                  _roundCheckbox(t.shared, ctrl.sharedSelected),
                ],
              ),
              const SizedBox(height: 20),
              Text(t.parentAccount),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _openParentAccountDialog(t),
                child: _fakeDropdown(
                  ctrl.selectedAccount.value?.accountName ??
                      "${t.selectPrefix}${t.parentAccount}",
                ),
              ),
              const SizedBox(height: 16),
              Text(t.location),
              const SizedBox(height: 6),
              InkWell(
                onTap: ctrl.selectedAccount.value == null
                    ? null
                    : () => _openLocationDialog(t),
                child: _fakeDropdown(_locationDropdownText(ctrl, t)),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonDanger,
                    disabledBackgroundColor: AppColors.buttonDanger.withAlpha(180),
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: ctrl.isLoading.value ? null : ctrl.submit,
                  child: ctrl.isLoading.value
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          t.select,
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: Get.back,
                  child: Text(
                    t.cancel,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _locationDropdownText(ChangeAccountController ctrl, AppLocalizations t) {
    final selected = ctrl.selectedLocations;
    if (selected.isEmpty) return "${t.selectPrefix}${t.location}";
    if (ctrl.isAllLocationsSelected) return "All Locations (${selected.length})";
    if (selected.length == 1) return selected.first.locationName;
    return "${selected.first.locationName} +${selected.length - 1} more";
  }

  Widget _fakeDropdown(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  Widget _roundCheckbox(String label, RxBool value) {
    return Obx(
          () => InkWell(
        onTap: () => value.value = !value.value,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: value.value,
              shape: const CircleBorder(),
              activeColor: Colors.red,
              onChanged: (v) => value.value = v!,
            ),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _openParentAccountDialog(AppLocalizations t) {
    ctrl.accountSearchQuery.value = ""; // Reset search
    Get.dialog(
      Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: Text(
            "${t.selectPrefix}${t.parentAccount}",
            style: const TextStyle(color: Colors.white),
          ), // ✅ Localized
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: Get.back,
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                cursorColor: Colors.red,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: t.searchAccount,
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                ),
                onChanged: (v) => ctrl.accountSearchQuery.value = v,
              ),
            ),
            Expanded(
              child: Obx(() {
                // Live filter based on accountSearchQuery
                final list = ctrl.accounts
                    .where(
                      (e) => e.accountName.toLowerCase().contains(
                    ctrl.accountSearchQuery.value.toLowerCase(),
                  ),
                )
                    .toList();

                if (list.isEmpty) return Center(child: Text(t.noAccountsFound));

                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) => ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text(list[i].accountName), const Divider()],
                    ),
                    onTap: () {
                      ctrl.onAccountChanged(list[i]);
                      Get.back();
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _openLocationDialog(AppLocalizations t) {
    ctrl.locationSearchQuery.value = "";
    Get.dialog(
      Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: Text(
            "${t.selectPrefix}${t.location}",
            style: const TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: Get.back,
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                cursorColor: Colors.red,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: t.searchLocation,
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                ),
                onChanged: (v) => ctrl.locationSearchQuery.value = v,
              ),
            ),
            Obx(
                  () => CheckboxListTile(
                value: ctrl.isAllLocationsSelected,
                activeColor: Colors.red,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Select All',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onChanged: (_) => ctrl.toggleSelectAllLocations(),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Obx(() {
                final list = ctrl.locations
                    .where(
                      (e) => e.locationName.toLowerCase().contains(
                    ctrl.locationSearchQuery.value.toLowerCase(),
                  ),
                )
                    .toList();

                if (list.isEmpty) {
                  return Center(child: Text(t.noLocationsFound));
                }

                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) => Obx(
                        () => CheckboxListTile(
                      value: ctrl.isLocationSelected(list[i]),
                      activeColor: Colors.red,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(list[i].locationName),
                      onChanged: (_) => ctrl.toggleLocation(list[i]),
                    ),
                  ),
                );
              }),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: Obx(
                        () => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonDanger,
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: ctrl.selectedLocations.isEmpty
                          ? null
                          : Get.back,
                      child: Text(
                        ctrl.selectedLocations.isEmpty
                            ? t.select
                            : "${t.select} (${ctrl.selectedLocations.length})",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }
}