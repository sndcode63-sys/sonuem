import 'package:emtrack/inspection/vehicle_inspe_controller.dart';
import 'package:emtrack/inspection/vehicle_inspe_model.dart';
import 'package:emtrack/routes/app_pages.dart';
import 'package:emtrack/search_tyre_vehicle/search_vehicle_tyre_controller.dart';
import 'package:emtrack/search_tyre_vehicle/tire_item_model.dart';
import 'package:emtrack/search_tyre_vehicle/vehicle_item_model.dart';
import 'package:emtrack/views/create_vehicle_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../l10n/app_localizations.dart';
import '../utils/local_helper.dart';
import '../utils/reusable_dialog.dart';

class SearchVehicleTyreView extends StatelessWidget {
  const SearchVehicleTyreView({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final SearchVehicleTyreController controller = Get.put(
      SearchVehicleTyreController(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${t.searchPrefix} ${t.vehicles} / ${LocaleHelper.tyreName(context)}',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── MAIN SEARCH BAR ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: () => _openSearchDialog(context, controller, t),
                  child: AbsorbPointer(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText:
                        '${t.searchPrefix} ${t.vehicles} / ${LocaleHelper.tyreName(context)}',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  t.recentSearch,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),

              // ─── RECENT LIST ───────────────────────────────────────────────
              Obx(
                    () => Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── RECENT VEHICLES ───
                      Text(
                        t.vehicles,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      controller.recentVehicles.isEmpty
                          ? Text(
                        t.noRecentVehicleFound,
                        style: const TextStyle(color: Colors.grey),
                      )
                          : Column(
                        children: controller.recentVehicles
                            .map<Widget>(
                              (VehicleItem e) => _recentTile(
                            t: t,
                            title:
                            e.vehicleNumber ??
                                e.vehicleId.toString(),
                            onTap: () => controller.selectItem(e),
                            onRemove: () =>
                                controller.removeRecentVehicle(e),
                          ),
                        )
                            .toList(),
                      ),

                      const SizedBox(height: 16),

                      // ─── RECENT TYRES ───
                      Text(
                        ' ${LocaleHelper.tyreName(context)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      controller.recentTyres.isEmpty
                          ? Text(
                        t.noRecentTyreFound,
                        style: const TextStyle(color: Colors.grey),
                      )
                          : Column(
                        children: controller.recentTyres
                            .map<Widget>(
                              (TireItem e) => _recentTile(
                            t: t,
                            title: (e.brandNo != null &&
                                    e.brandNo!.trim().isNotEmpty &&
                                    e.brandNo!.trim().toLowerCase() != 'null')
                                ? '${e.tireSerialNo} / ${e.brandNo}'
                                : e.tireSerialNo,
                            onTap: () => controller.selectItem(e),
                            onRemove: () =>
                                controller.removeRecentTyre(e),
                          ),
                        )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── SEARCH DIALOG ────────────────────────────────────────────────────────
  void _openSearchDialog(
      BuildContext context,
      SearchVehicleTyreController c,
      AppLocalizations t,
      ) {
    c.clearSearch();
    c.switchTab(0);

    showDialog(
      context: context,
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: Text(
            '${t.searchPrefix} ${t.vehicles} / ${LocaleHelper.tyreName(context)}',
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          ),
        ),
        body: Obx(() {
          final hasResults = c.visibleList.isNotEmpty;
          final isSearching = c.searchText.value.isNotEmpty;
          final isVehicleTab = c.selectedTab.value == 0;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  autofocus: true,
                  onChanged: c.onSearch,
                  decoration: InputDecoration(
                    hintText: '${t.typeToSearch}...',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  _tab(c, t.vehicles.toUpperCase(), 0),
                  _tab(
                    c,
                    ' ${LocaleHelper.tyreName(context).toUpperCase()}',
                    1,
                  ),
                ],
              ),
              if (c.isLoading.value)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Colors.red),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (!hasResults && isSearching)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isVehicleTab
                                      ? "${t.noVehiclesFoundFor} '${c.searchText.value}'"
                                      : "${t.noTyresFoundFor} '${c.searchText.value}'",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!hasResults && !isSearching)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              '${t.typeToSearch}...',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        if (hasResults)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: c.visibleList.length,
                            itemBuilder: (_, i) {
                              final item = c.visibleList[i];
                              final isVehicle = c.selectedTab.value == 0;

                              String title = '';
                              String subtitle = '';

                              if (isVehicle) {
                                final v = item as VehicleItem;
                                title = v.vehicleNumber ?? 'ID: ${v.vehicleId}';
                                subtitle =
                                '${v.manufacturer ?? ''} | ${v.typeName ?? ''} | ${v.modelName ?? ''}';
                              } else {
                                final tireItem = item as TireItem;
                                final hasBrand = tireItem.brandNo != null &&
                                    tireItem.brandNo!.trim().isNotEmpty &&
                                    tireItem.brandNo!.trim().toLowerCase() != 'null';
                                title = hasBrand
                                    ? '${tireItem.tireSerialNo} / ${tireItem.brandNo}'
                                    : tireItem.tireSerialNo;
                                subtitle = tireItem.wheelPosition ?? '';
                              }

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: subtitle.isNotEmpty
                                      ? Text(
                                    subtitle,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  )
                                      : null,
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Colors.red,
                                  ),
                                  onTap: () => c.selectItem(item),
                                ),
                              );
                            },
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: Text(
                                isVehicleTab
                                    ? t.createNewVehicle
                                    : t.createNewTyre,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                Get.back();
                                if (isVehicleTab) {
                                  Get.to(() => CreateVehicleView());
                                } else {
                                  Get.toNamed(AppPages.CREATE_TYRE);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  static Widget _tab(SearchVehicleTyreController c, String title, int index) {
    return Expanded(
      child: Obx(
            () => GestureDetector(
          onTap: () => c.switchTab(index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: c.selectedTab.value == index
                      ? Colors.red
                      : Colors.grey.shade300,
                  width: 3,
                ),
              ),
            ),
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.selectedTab.value == index
                      ? Colors.red
                      : Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _recentTile({
    required AppLocalizations t,
    required String title,
    required VoidCallback onRemove,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(title, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            onPressed: () {
              DialogHelper.showConfirm(
                title: t.confirmRemoveTitle,
                message: t.confirmRemoveMessage,
                confirmText: t.yes.toUpperCase(),
                cancelText: t.no.toUpperCase(),
                onConfirm: onRemove,
              );
            },
          ),
        ],
      ),
    );
  }
}