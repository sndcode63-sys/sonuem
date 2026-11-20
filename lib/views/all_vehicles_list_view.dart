import 'package:emtrack/color/app_color.dart';
import 'package:emtrack/controllers/all_vehicles_controller.dart';
import 'package:emtrack/widgets/app_widgets.dart';
import 'package:emtrack/controllers/auth_controller.dart';
import 'package:emtrack/inspection/vehicle_inspe_view.dart';
import 'package:emtrack/services/role_service.dart';
import 'package:emtrack/views/create_vehicle_view.dart';
import 'package:emtrack/views/vehicle_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/local_helper.dart';
import '../l10n/app_localizations.dart';
import 'Edit_vehicle.dart';

class AllVehicleListView extends StatelessWidget {
  AllVehicleListView({super.key});

  final controller = Get.put(AllVehicleController());
  final AuthController _auth = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.allVehicles),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 🔍 SEARCH BAR
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: controller.searchController,
                onChanged: (value) => controller.onSearch(value),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Obx(() {
                    final isApplied = controller.isFilterApplied.value;
                    return SizedBox(
                      width: 60,
                      height: 60,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.filter_alt,
                              color: isApplied
                                  ? Colors.red.withAlpha(64)
                                  : Colors.red,
                            ),
                            onPressed: () => _openFilterBottomSheet(context, t),
                          ),
                          if (isApplied)
                            Positioned(
                              bottom: 19,
                              right: 18,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 9,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                ),
              ),
            ),
            // 📋 LIST
            Expanded(
              child: Obx(() {
                // behtar shimmer skeleton loader jab tak vehicle data
                // server se aa nahi jaata
                if (controller.isLoading.value) {
                  return const AppListSkeleton();
                }

                // ✅ FIX: pehle agar list truly khali hoti (na filter laga
                // hua, na offline — sirf 0 vehicles), toh yaha seedha
                // blank ListView (0 items) render ho jaata tha — matlab
                // ek "white screen". Ab har khali case me proper message
                // dikhega.
                if (controller.filteredList.isEmpty) {
                  if (controller.isOffline.value) {
                    return AppEmptyState.offline(message: t.noDataAvailable);
                  }
                  return AppEmptyState.noResults(message: t.noDataAvailable);
                }

                return RefreshIndicator(
                  onRefresh: () async => controller.refreshVehicles(),
                  child: ListView.builder(
                    itemCount: controller.filteredList.length,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final vehicle = controller.filteredList[index];
                      return _vehicleCard(vehicle, t, context);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Obx(() {
        final role = _auth.userRole.value;
        if (!RoleService.canCreateVehicle(role)) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => Get.to(() => CreateVehicleView()),
          child: Container(
            margin: const EdgeInsets.only(right: 4, bottom: 4),
            child: Image.asset('assets/images/CreateVehicle.png', width: 150),
          ),
        );
      }),
    );
  }

  Widget _buildVehicleImage() {
    return Image.asset(
      'assets/images/IMG_Default.png',
      height: 70,
      width: 70,
      fit: BoxFit.contain,
    );
  }

  String _getTireCount(dynamic vehicle) {
    if (vehicle.tireCount != null && vehicle.tireCount > 0) {
      return vehicle.tireCount.toString();
    }
    final count = calculateTireCount(vehicle.axleConfig);
    if (count > 0) return count.toString();
    return '0';
  }

  Widget _vehicleCard(dynamic vehicle, AppLocalizations t, BuildContext context) {
    return GestureDetector(
      onTap: () => _openActionBottomSheet(vehicle, t),
      child: Card(
        color: Colors.red.shade50.withAlpha(204),
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.red, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#${vehicle.vehicleNumber ?? ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 20,
                          ),
                        ),
                        // if (vehicle.isPendingSync) ...[
                        //   const SizedBox(width: 8),
                        //   AppStatusBadge.pendingSync(label: t.pendingSync),
                        // ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        children: [
                          TextSpan(text: "${t.make}: "),
                          TextSpan(
                            text: vehicle.manufacturerName ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        children: [
                          TextSpan(text: "${t.model}: "),
                          TextSpan(
                            text: vehicle.modelName ?? '',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        children: [
                          TextSpan(text: "${t.axleLabel}: "),
                          TextSpan(
                            text:
                            '${formatAxleConfig(vehicle.axleConfig)} ${t.axleLabel} ${_getTireCount(vehicle)} ${LocaleHelper.tyreName(context)}',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Image.network(
                    Uri.encodeFull(vehicle.assetNumber ?? ""),
                    height: 60,
                    width: 80,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildVehicleImage(),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        height: 60,
                        width: 80,
                        child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vehicle.typeName ?? "",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String formatAxleConfig(String? value) {
    if (value == null || value.isEmpty) return '';
    if (RegExp(r'^\d+$').hasMatch(value.trim())) {
      return value.trim().length.toString();
    }
    String result = value.replaceAll(RegExp(r'\s*\(.*?\)'), '');
    result = result.replaceAll('Axles', 'Axle');
    return result.trim();
  }

  int calculateTireCount(String? axleConfig) {
    if (axleConfig == null || axleConfig.isEmpty) return 0;
    final RegExp regex = RegExp(r'(\d+)\s*Tires?');
    final match = regex.firstMatch(axleConfig);
    if (match != null) return int.tryParse(match.group(1) ?? '0') ?? 0;
    final axleMatch = RegExp(r'(\d+)\s*Axle').firstMatch(axleConfig);
    if (axleMatch != null) {
      final axleCount = int.tryParse(axleMatch.group(1) ?? '0') ?? 0;
      return axleCount * 2;
    }
    return 0;
  }

  // ── Action bottom sheet ───────────────────────────────────────────────────
  void _openActionBottomSheet(dynamic vehicle, AppLocalizations t) {
    final String role = _auth.userRole.value;
    Get.bottomSheet(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (RoleService.canInspectVehicle(role)) ...[
              ListTile(
                title: Center(
                  child: InkWell(
                    onTap: () {
                      Get.back();
                      Get.to(() => VehicleInspeView(),
                          arguments: vehicle.vehicleId);
                    },
                    child: Text(t.inspect,
                        style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ),
              const Divider(),
            ],
            if (RoleService.canViewVehicle(role)) ...[
              ListTile(
                title: Center(
                  child: InkWell(
                    onTap: () {
                      Get.back();
                      Get.to(() => VehicleView(), arguments: vehicle.vehicleId);
                    },
                    child: Text(t.view,
                        style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ),
              const Divider(),
            ],
            if (RoleService.canEditVehicle(role))
              ListTile(
                onTap: () {
                  Get.back();
                  Get.to(() => UpdateVehicleView(),
                      arguments: vehicle.vehicleId);
                },
                title: Center(
                  child: Text(t.editBtn,
                      style: const TextStyle(color: Colors.red)),
                ),
              ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  // ── Filter bottom sheet ───────────────────────────────────────────────────
  void _openFilterBottomSheet(BuildContext context, AppLocalizations t) {
    Get.bottomSheet(
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    t.filters,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  SizedBox(),
                ],
              ),
              const SizedBox(height: 12),

              // ── Vehicle Type ─────────────────────────────────────────────
              _buildFilterLabel("${t.vehicleType}:"),
              Obx(() {
                final selected = controller.selectedType.value;
                return _searchableFilterField(
                  hint: t.vehicleType,
                  selectedValue: selected,
                  onTap: () => _openFilterDialog(
                    context: context,
                    title: t.vehicleType,
                    items: controller.typeList,
                    selectedValue: controller.selectedType,
                    t: t,
                  ),
                );
              }),

              const SizedBox(height: 12),

              _buildFilterLabel("${t.make}:"),
              Obx(() {
                final selected = controller.selectedMake.value;
                return _searchableFilterField(
                  hint: t.make,
                  selectedValue: selected,
                  onTap: () => _openFilterDialog(
                    context: context,
                    title: t.make,
                    items: controller.makeList,
                    selectedValue: controller.selectedMake,
                    t: t,
                  ),
                );
              }),

              const SizedBox(height: 12),

              _buildFilterLabel("${t.model}:"),
              Obx(() {
                final selected = controller.selectedModel.value;
                return _searchableFilterField(
                  hint: t.model,
                  selectedValue: selected,
                  onTap: () => _openFilterDialog(
                    context: context,
                    title: t.model,
                    items: controller.modelList,
                    selectedValue: controller.selectedModel,
                    t: t,
                  ),
                );
              }),

              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  controller.applyFilter();
                  Get.back();
                },
                child: Text(
                  t.applyFilters,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),

              Obx(() {
                if (!controller.isFilterApplied.value) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                    onPressed: () {
                      controller.clearFilter();
                      Get.back();
                    },
                    child: const Text(
                      "Reset Filters",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),

              Center(
                child: InkWell(
                  onTap: () => Get.back(),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      t.cancel,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  Widget _searchableFilterField({
    required String hint,
    required String selectedValue,
    required VoidCallback onTap,
  }) {
    final bool hasValue = selectedValue.isNotEmpty;
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        onTap();
      },
      child: AbsorbPointer(
        child: TextFormField(
          readOnly: true,
          key: ValueKey(selectedValue),
          initialValue: hasValue ? selectedValue : null,
          decoration: InputDecoration(
            hintText: hint,
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2)),
            disabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey)),
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.red),
          ),
          style: TextStyle(
            color: hasValue ? Colors.black87 : Colors.grey.shade600,
            fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _openFilterDialog({
    required BuildContext context,
    required String title,
    required RxList<String> items,
    required RxString selectedValue,
    required AppLocalizations t,
  }) {
    final List<String> snapshot = List<String>.from(items);
    final RxList<String> filteredList = RxList<String>.from(snapshot);
    final TextEditingController searchCtrl = TextEditingController();
    final RxString tempSelected = selectedValue.value.obs;

    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (dialogContext) => Scaffold(
        appBar: AppBar(
          title: Text(title, style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Search field
              AppSearchBar(
                controller: searchCtrl,
                hintText: 'Search...',
                onChanged: (v) {
                  final query = v.toLowerCase();
                  filteredList.value = query.isEmpty
                      ? List<String>.from(snapshot)
                      : snapshot
                      .where((e) => e.toLowerCase().contains(query))
                      .toList();
                },
              ),

              // List
              Expanded(
                child: Obx(() {
                  if (snapshot.isEmpty) {
                    return Center(child: Text(t.noDataAvailable));
                  }
                  if (filteredList.isEmpty) {
                    return Center(child: Text(t.noDataAvailable));
                  }
                  return ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (_, index) {
                      final item = filteredList[index];
                      return Obx(() {
                        final isSelected = tempSelected.value == item;
                        return ListTile(
                          tileColor: isSelected
                              ? Colors.red.withAlpha(20)
                              : Colors.transparent,
                          title: Text(
                            item,
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
                          onTap: () => tempSelected.value = item,
                        );
                      });
                    },
                  );
                }),
              ),

              // Cancel / OK row
              Container(
                decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(color: Colors.grey.shade300))),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: TextButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 16)),
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
                          selectedValue.value = tempSelected.value;
                          Navigator.of(dialogContext).pop();
                        },
                        style: TextButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 16)),
                        child: Text(t.okBtn,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            )),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }
}