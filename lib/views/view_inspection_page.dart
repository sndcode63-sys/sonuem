import '../utils/local_helper.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../color/app_color.dart';
import '../controllers/home_controller.dart';
import '../controllers/inspection_controller.dart';
import '../inspection/vehicle_inspe_view.dart';
import '../l10n/app_localizations.dart';
import '../models/inspection_hive_models.dart';
import '../services/offline_hive_service.dart';

class ViewInspectionPage extends StatelessWidget {
  const ViewInspectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (!Get.isRegistered<InspectionController>()) {
      Get.lazyPut(() => InspectionController());
    }
    final ctrl = Get.find<InspectionController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back, color: Colors.white),
          onPressed: () {
            _refreshHomeCount();
            Get.back();
          },
        ),
        title: Text(
          t.viewInspection,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Obx(
                  () => _SegmentTabs(
                t: t,
                selectedIndex: ctrl.tabController.index,
                unsyncedCount: ctrl.unsyncedCount,
                syncedCount: ctrl.syncedCount,
                onTabChanged: (idx) {
                  ctrl.tabController.animateTo(idx);
                  (context as Element).markNeedsBuild();
                },
              ),
            ),
          ),
        ),
      ),
      body: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) {
            _refreshHomeCount();
          }
        },
        child: AnimatedBuilder(
          animation: ctrl.tabController,
          builder: (_, _) => ctrl.tabController.index == 0
              ? _UnsyncedTab(ctrl: ctrl, t: t)
              : _SyncedTab(ctrl: ctrl, t: t),
        ),
      ),
    );
  }

  void _refreshHomeCount() {
    try {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().refreshCounts();
      }
    } catch (_) {}
  }
}

class _SegmentTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final AppLocalizations t;
  final int unsyncedCount;
  final int syncedCount;

  const _SegmentTabs({
    required this.selectedIndex,
    required this.onTabChanged,
    required this.t,
    this.unsyncedCount = 0,
    this.syncedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          _TabItem(
            label: t.unsynced,
            isSelected: selectedIndex == 0,
            isLeft: true,
            count: unsyncedCount,
            onTap: () => onTabChanged(0),
          ),
          _TabItem(
            label: t.synced,
            isSelected: selectedIndex == 1,
            isLeft: false,
            count: syncedCount,
            onTap: () => onTabChanged(1),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isLeft;
  final VoidCallback onTap;
  final int count;

  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.isLeft,
    required this.onTap,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.only(
              topLeft: isLeft ? const Radius.circular(4) : Radius.zero,
              bottomLeft: isLeft ? const Radius.circular(4) : Radius.zero,
              topRight: !isLeft ? const Radius.circular(4) : Radius.zero,
              bottomRight: !isLeft ? const Radius.circular(4) : Radius.zero,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.primary : Colors.white,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Map<String, List<InspectionHiveModel>> _groupByUser(
    List<InspectionHiveModel> list,
    ) {
  final result = <String, List<InspectionHiveModel>>{};
  for (final item in list) {
    final key = item.requestorName.isNotEmpty
        ? item.requestorName
        : (item.accountName.isNotEmpty ? item.accountName : '--');
    result.putIfAbsent(key, () => []).add(item);
  }
  return result;
}

String _getHomeLocationText() {
  try {
    if (!Get.isRegistered<HomeController>()) return '';
    final hc = Get.find<HomeController>();
    final account = hc.homeData.value?.parentAccount.isNotEmpty == true
        ? hc.homeData.value!.parentAccount
        : hc.selectedParentAccountName.value;
    final location = hc.homeData.value?.location.isNotEmpty == true
        ? hc.homeData.value!.location
        : hc.selectedLocationName.value;
    final a = account.isNotEmpty ? account : '--';
    final l = location.isNotEmpty ? location : '--';
    return '$a - $l';
  } catch (_) {
    return '';
  }
}

class _UnsyncedTab extends StatelessWidget {
  final InspectionController ctrl;
  final AppLocalizations t;

  const _UnsyncedTab({required this.ctrl, required this.t});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (ctrl.unsyncedList.isEmpty) return _NoDataState(t: t);

      final grouped = _groupByUser(ctrl.unsyncedList);

      return Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: ctrl.loadData,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: grouped.keys.length,
                itemBuilder: (_, i) {
                  final key = grouped.keys.elementAt(i);
                  final items = grouped[key]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _UserGroupHeader(
                        username: key,
                        locationName: _getHomeLocationText(),
                        showSyncAll: true,
                        ctrl: ctrl,
                        t: t,
                        onSyncAll: () async {
                          await ctrl.syncAll();
                          _refreshHome();
                        },
                      ),
                      ...items.map(
                            (item) => _InspectionCard(
                          item: item,
                          isUnsynced: true,
                          ctrl: ctrl,
                          t: t,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  void _refreshHome() {
    try {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().refreshCounts();
      }
    } catch (_) {}
  }
}

class _SyncedTab extends StatelessWidget {
  final InspectionController ctrl;
  final AppLocalizations t;

  const _SyncedTab({required this.ctrl, required this.t});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (ctrl.syncedList.isEmpty) return _NoDataState(t: t);

      final grouped = _groupByUser(ctrl.syncedList);

      return RefreshIndicator(
        onRefresh: ctrl.loadData,
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: grouped.keys.length,
          itemBuilder: (_, i) {
            final key = grouped.keys.elementAt(i);
            final items = grouped[key]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UserGroupHeader(
                  username: key,
                  locationName: _getHomeLocationText(),
                  showSyncAll: false,
                  ctrl: ctrl,
                  t: t,
                ),
                ...items.map(
                      (item) => _InspectionCard(
                    item: item,
                    isUnsynced: false,
                    ctrl: ctrl,
                    t: t,
                  ),
                ),
                const SizedBox(height: 6),
              ],
            );
          },
        ),
      );
    });
  }
}

class _UserGroupHeader extends StatelessWidget {
  final String username;
  final String locationName;
  final bool showSyncAll;
  final InspectionController ctrl;
  final AppLocalizations t;
  final VoidCallback? onSyncAll;

  const _UserGroupHeader({
    required this.username,
    required this.locationName,
    required this.showSyncAll,
    required this.ctrl,
    required this.t,
    this.onSyncAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.black,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        locationName.isNotEmpty ? locationName : '--',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          height: 1.3,
                        ),
                        softWrap: true,
                        maxLines: 3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (showSyncAll) ...[
            const SizedBox(width: 10),
            Obx(
                  () => GestureDetector(
                onTap: !ctrl.isSyncingAll.value ? onSyncAll : null,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ctrl.isSyncingAll.value
                          ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(
                        Icons.sync,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        t.syncAll,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InspectionCard extends StatelessWidget {
  final InspectionHiveModel item;
  final bool isUnsynced;
  final InspectionController ctrl;
  final AppLocalizations t;

  const _InspectionCard({
    required this.item,
    required this.isUnsynced,
    required this.ctrl,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: BoxDecoration(
        color: Colors.red.shade50.withAlpha(204),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    "ID: : ${item.vehicleNumber}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _fmtDateTime(item.inspectionDate),
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                ),
              ],
            ),

            if (item.vehicleId.isNotEmpty && item.vehicleId != '0') ...[
              const SizedBox(height: 2),
            ],

            const SizedBox(height: 6),

            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
                children: [
                  const TextSpan(text: 'Inspected '),
                  TextSpan(
                    text: '${item.inspectedTyreCount}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  if (item.totalTyreCount > 0) ...[
                    const TextSpan(text: ' of '),
                    TextSpan(
                      text: '${item.totalTyreCount}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                  TextSpan(
                    text: ' Tire${item.inspectedTyreCount == 1 ? '' : 's'}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isUnsynced) ...[
                  Obx(() {
                    final syncing = ctrl.syncingIds.contains(item.id);
                    final canSync = !syncing;
                    return _CardBtn(
                      isBtnEnabled: true,
                      icon: syncing
                          ? const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                          : const Icon(
                        Icons.sync,
                        size: 16,
                        color: Colors.black,
                      ),
                      label: syncing ? t.syncing : t.sync,
                      onTap: canSync
                          ? () async {
                        await ctrl.syncSingle(item);
                        _refreshHome();
                      }
                          : null,
                    );
                  }),
                  const SizedBox(width: 8),
                  Obx(
                        () => _CardBtn(
                      isBtnEnabled: true,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Colors.black,
                      ),
                      label: t.delete,
                      onTap: ctrl.isLoading.value
                          ? null
                          : () => _confirmDelete(context, item, t),
                    ),
                  ),
                ],
                if (!isUnsynced)
                  _CardBtn(
                    isBtnEnabled: true,
                    icon: const Icon(
                      Icons.article_outlined,
                      size: 16,
                      color: Colors.black,
                    ),
                    label: t.view,
                    onTap: () => _openVehicleInspection(item),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openVehicleInspection(InspectionHiveModel item) async {
    final rawId = int.tryParse(item.vehicleId) ?? 0;

    if (rawId < 0) {
      final prefs = await SharedPreferences.getInstance();

      final realId = prefs.getInt('vehicle_real_id_${item.vehicleId}');
      if (realId != null && realId > 0) {
        Get.to(() => const VehicleInspeView(), arguments: realId);
        return;
      }

      final targetVehicleNo = item.vehicleNumber.trim().toLowerCase();
      final allPositiveIds =
      OfflineHiveService.getAllCachedPositiveVehicleIds();
      for (final posId in allPositiveIds) {
        final cached = OfflineHiveService.getInspectionCache(posId.toString());
        if (cached == null) continue;
        try {
          final decoded = jsonDecode(cached) as Map<String, dynamic>;
          final model = decoded['model'] as Map<String, dynamic>?;
          final vNum =
              model?['vehicleNumber']?.toString().trim().toLowerCase() ?? '';
          if (vNum == targetVehicleNo && vNum.isNotEmpty) {
            await prefs.setInt('vehicle_real_id_${item.vehicleId}', posId);
            Get.to(() => const VehicleInspeView(), arguments: posId);
            return;
          }
        } catch (_) {}
      }
    }

    Get.to(
          () => const VehicleInspeView(),
      arguments: rawId != 0 ? rawId : item.vehicleId,
    );
  }

  void _refreshHome() {
    try {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().refreshCounts();
      }
    } catch (_) {}
  }

  static String _fmtDateTime(String? raw) => LocaleHelper.formatDateTime(raw);

  void _confirmDelete(
      BuildContext context,
      InspectionHiveModel item,
      AppLocalizations t,
      ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.confirmDeleteTitle),
        content: Text('${t.confirmDeleteMessage} ${item.vehicleNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel, style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ctrl.deleteInspection(item);
              _refreshHome();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _CardBtn extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onTap;
  final bool isBtnEnabled;

  const _CardBtn({
    required this.icon,
    required this.label,
    this.onTap,
    this.isBtnEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null || isBtnEnabled;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: enabled ? Colors.black : Colors.grey.shade400,
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: enabled ? Colors.black : Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoDataState extends StatelessWidget {
  final AppLocalizations t;

  const _NoDataState({required this.t});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/NoDataimage.png',

            width: MediaQuery.of(context).size.width * 0.5,
            height: 160,
            errorBuilder: (_, _, _) => Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.noDataAvailable,
            style: const TextStyle(fontSize: 24, color: Color(0xFF0D54B5)),
          ),
        ],
      ),
    );
  }
}
