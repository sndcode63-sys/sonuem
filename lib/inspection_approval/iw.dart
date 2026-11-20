import 'package:emtrack/inspection/vehicle_inspe_model.dart';
import 'package:emtrack/inspection_approval/search.dart';
import 'package:emtrack/inspection_approval/tyre.dart';
import 'package:emtrack/inspection_approval/vehicle.dart';
import 'package:emtrack/search_tyre_vehicle/tire_item_model.dart';
import 'package:emtrack/search_tyre_vehicle/vehicle_item_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../l10n/app_localizations.dart';
import '../utils/approval_localizations.dart';

class IWSearchScreen extends StatelessWidget {
  final int initialTab;
  const IWSearchScreen({super.key, this.initialTab = 0});

  static void _navigateToVehicle(VehicleItem v, IWSearchController c) {
    final int? pendingId = v.pendingInspectionId ?? c.getPendingInspectionIdForVehicle(v.vehicleId);
    Get.to(
      () => IWVehicleInspectionScreen(
        vehicleId: v.vehicleId?.toString() ?? '',
        vehicleIdInt: v.vehicleId ?? 0,
        vehicleNumber: v.vehicleNumber ?? '',
        oldTires: <InstalledTire>[].obs,
        newTires: <InstalledTire>[].obs,
        axleConfig: '22',
        pendingInspectionId: pendingId,
      ),
    );
  }

  static void _navigateToTyre(TireItem t, IWSearchController c) {
    String? foundDate;
    String? foundImages = t.imagesLocation;
    for (final p in c.pendingInspections) {
      final matchTire = (p.tire?.tireId != null && p.tire?.tireId == t.tireId)
          ? p.tire
          : (p.tiresList.any((pt) =>
              (pt.tireId != null && pt.tireId == t.tireId) ||
              (t.tireSerialNo.isNotEmpty && pt.tireSerialNo?.trim().toUpperCase() == t.tireSerialNo.trim().toUpperCase()))
              ? p.tiresList.firstWhere((pt) =>
                  (pt.tireId != null && pt.tireId == t.tireId) ||
                  (t.tireSerialNo.isNotEmpty && pt.tireSerialNo?.trim().toUpperCase() == t.tireSerialNo.trim().toUpperCase()))
              : null);
      if (matchTire != null) {
        foundDate = matchTire.inspectionDate ?? p.status?.createdDate;
        if (foundImages == null || foundImages.isEmpty) {
          foundImages = matchTire.imagesLocation?.toString();
        }
        break;
      }
    }
    foundDate ??= t.inspectionDate;

    Get.to(
      () => IWTyreInspectionScreen(
        serialNo: t.tireSerialNo,
        tireId: t.tireId,
        vehicleNumber: t.vehicleNumber,
        inspectionDate: foundDate,
        wearConditionId: t.wearConditionId,
        casingConditionId: t.casingConditionId,
        comments: t.comments,
        outsideTread: t.outsideTread,
        middleTread: t.middleTread,
        insideTread: t.insideTread,
        currentPressure: t.currentPressure,
        wheelPosition: t.wheelPosition,
        pendingInspectionId: t.pendingInspectionId,
        imagesLocation: foundImages,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = ApprovalLocalizations.of(context);
    final t = AppLocalizations.of(context);
    final IWSearchController c = Get.put(
      IWSearchController(initialTab: initialTab),
      tag: 'iw_search',
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(a.inspectionVehicleTire),
        leading: const BackButton(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── MAIN SEARCH BAR ──
          Padding(
            padding: const EdgeInsets.all(12),
            child: GestureDetector(
              onTap: () => _openSearchDialog(context, c),
              child: AbsorbPointer(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: a.searchInspectionVehicleTire,
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
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),

          // ── RECENT LISTS ──
          Expanded(
            child: Obx(
                  () => SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Inspection Vehicles ──
                    Text(
                      a.inspectionVehicles,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    c.recentVehicles.isEmpty
                        ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        a.noVehicleSelected,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                        : Column(
                      children: c.recentVehicles
                          .map(
                            (v) => _recentTile(
                          a: a,
                          title:
                          v.vehicleNumber ??
                              v.vehicleId.toString(),
                          subtitle:
                          '${v.manufacturer ?? ''} | ${v.typeName ?? ''}'
                              .trim(),
                          status: c.getStatus(v),
                          onTap: () => _navigateToVehicle(v, c),
                          onRemove: () => c.removeRecentVehicle(v),
                        ),

                      )
                          .toList(),
                    ),

                    const SizedBox(height: 16),

                    // ── Inspection Tires ──
                    Text(
                      a.inspectionTires,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    c.recentTyres.isEmpty
                        ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        a.noTyreSelected,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                        : Column(
                      children: c.recentTyres
                          .map(
                            (tItem) {
                          final bool isRemoved = (tItem.action?.trim().toLowerCase() == 'remove') ||
                              (tItem.dispositionName.trim().toLowerCase() == 'removed');
                          final bool hasBrand = tItem.brandNo != null &&
                              tItem.brandNo!.trim().isNotEmpty &&
                              tItem.brandNo!.trim().toLowerCase() != 'null';
                          final String baseTitle = tItem.tireSerialNo.isNotEmpty
                              ? tItem.tireSerialNo
                              : tItem.tireId.toString();
                          return _recentTile(
                            a: a,
                            title: hasBrand ? '$baseTitle / ${tItem.brandNo}' : baseTitle,
                            subtitle: isRemoved
                                ? (tItem.wheelPosition.isNotEmpty ? a.removedFromPosition(tItem.wheelPosition) : a.removedFromVehicle)
                                : (tItem.wheelPosition.isNotEmpty ? a.position(tItem.wheelPosition) : null),
                            overrideLabel: isRemoved ? a.pendingRemoval : null,
                            overrideColor: isRemoved ? Colors.deepOrange : null,
                            status: isRemoved ? null : c.getStatus(tItem),
                            onTap: () => _navigateToTyre(tItem, c),
                            onRemove: () => c.removeRecentTyre(tItem),
                          );
                        },
                      )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SEARCH DIALOG ──
  void _openSearchDialog(BuildContext context, IWSearchController c) {
    c.clearSearch();
    final a = ApprovalLocalizations.of(context);
    Get.dialog(
      Scaffold(
        appBar: AppBar(
          title: Text(a.searchInspectionVehicleDialog),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: Get.back,
          ),
        ),
        body: Obx(
              () => Column(
            children: [
              // ── Search bar ──
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  autofocus: true,
                  onChanged: c.onSearch,
                  decoration: InputDecoration(
                    hintText: a.searchInspectionVehicleTire,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),

              // ── TABS ──
              Row(children: [_tab(c, a.vehiclesTab, 0), _tab(c, a.tiresTab, 1)]),

              // ── LIST ──
              Expanded(
                child: c.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : c.visibleList.isEmpty
                    ? Center(child: Text(a.noItemsFound))
                    : ListView.builder(
                  itemCount: c.visibleList.length,
                  itemBuilder: (_, i) {
                    final item = c.visibleList[i];
                    final isVehicle = c.selectedTab.value == 0;

                    String title = '';
                    String subtitle = '';
                    Color color;
                    String label;
                    if (isVehicle) {
                      final v = item as VehicleItem;
                      title = v.vehicleNumber ?? 'ID: ${v.vehicleId}';
                      subtitle =
                          '${v.manufacturer ?? ''} | ${v.typeName ?? ''}'
                              .trim();
                      final status = c.getStatus(item);
                      color = _statusColor(status);
                      label = _statusLabel(status, a);
                    } else {
                      final t = item as TireItem;
                      final bool hasBrand = t.brandNo != null &&
                          t.brandNo!.trim().isNotEmpty &&
                          t.brandNo!.trim().toLowerCase() != 'null';
                      final String baseTitle = t.tireSerialNo.isNotEmpty ? t.tireSerialNo : 'ID: ${t.tireId}';
                      title = hasBrand ? '$baseTitle / ${t.brandNo}' : baseTitle;
                      final bool isRemoved = (t.action?.trim().toLowerCase() == 'remove') ||
                          (t.dispositionName.trim().toLowerCase() == 'removed');
                      if (isRemoved) {
                        subtitle = t.wheelPosition.isNotEmpty
                            ? a.removedFromPosition(t.wheelPosition)
                            : a.removedFromVehicle;
                        color = Colors.deepOrange;
                        label = a.pendingRemoval;
                      } else {
                        subtitle = t.wheelPosition.isNotEmpty
                            ? a.position(t.wheelPosition)
                            : '';
                        final status = c.getStatus(item);
                        color = _statusColor(status);
                        label = _statusLabel(status, a);
                      }
                    }

                    return InkWell(
                      onTap: () {
                        c.selectItem(item);
                        Get.back();
                        if (isVehicle) {
                          _navigateToVehicle(item as VehicleItem, c);
                        } else {
                          _navigateToTyre(item as TireItem, c);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: Text(title),
                          subtitle: subtitle.isNotEmpty
                              ? Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          )
                              : null,
                          trailing: Text(
                            label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  static Widget _tab(IWSearchController c, String title, int index) {
    return Expanded(
      child: Obx(
            () => GestureDetector(
          onTap: () => c.switchTab(index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
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

  static Color _statusColor(IWInspectionStatus s) {
    switch (s) {
      case IWInspectionStatus.approved:
        return Colors.green;
      case IWInspectionStatus.rejected:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  static String _statusLabel(IWInspectionStatus s, ApprovalLocalizations a) {
    switch (s) {
      case IWInspectionStatus.approved:
        return a.approved;
      case IWInspectionStatus.rejected:
        return a.rejected;
      default:
        return a.pending;
    }
  }

  static Widget _recentTile({
    required ApprovalLocalizations a,
    required String title,
    String? subtitle,
    IWInspectionStatus? status,
    String? overrideLabel,
    Color? overrideColor,
    VoidCallback? onTap,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(title),
        subtitle: (subtitle != null && subtitle.isNotEmpty)
            ? Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (overrideLabel != null)
              Text(
                overrideLabel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: overrideColor ?? Colors.deepOrange,
                ),
              )
            else if (status != null)
              Text(
                _statusLabel(status, a),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _statusColor(status),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}