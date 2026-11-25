import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emtrack/routes/app_pages.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/tyre_model.dart';
import '../services/tyre_service.dart';
import '../services/offline_hive_service.dart';
import '../utils/network_helper.dart';
import '../utils/mesurment_helper_class.dart';
import '../utils/tyre_unit_history.dart';
import '../utils/pending_inspection_guard.dart';
import '../views/tyre_view.dart';
import '../inspection/vehicle_inspe_controller.dart';
import '../inspection_approval/search.dart' show SearchApi;
import 'package:shared_preferences/shared_preferences.dart';

class SearchInstallTireController extends GetxController {
  final TyreService service = TyreService();

  final RxBool isLoading = false.obs;
  final RxBool isOffline = false.obs;

  final RxList<TyreModel> allTyres = <TyreModel>[].obs;
  final RxList<TyreModel> visibleTyres = <TyreModel>[].obs;

  final RxString searchText = ''.obs;

  StreamSubscription? _connectivitySub;

  @override
  void onInit() {
    super.onInit();
    fetchInventoryTyres();

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online && isOffline.value) {
        fetchInventoryTyres();
      }
    });

    // Refresh the inventory list once a pending tyre operation (e.g. an
    // offline install) actually finishes syncing, so a tyre that just
    // got installed correctly disappears from this "available" list
    // instead of waiting for the user to manually reopen the screen.
    OfflineHiveService.registerPostSyncTyreListener(_onTyreSynced);
  }

  void _onTyreSynced() {
    fetchInventoryTyres();
  }

  static const String _kPendingApprovalTireIdsKey = 'pending_approval_tire_ids';

  /// Wo tyres jo ya to queue me install ke liye pade hain, ya server par
  /// install ho chuke hain lekin approver ka approve/reject baaki hai.
  /// Server abhi bhi inhe inventory (disposition 8) bata sakta hai, isliye
  /// inhe available list se hataana zaroori hai.
  Future<Set<int>> _pendingInstallTireIds(int accId, {required bool online}) async {
    final ids = <int>{...OfflineHiveService.getAllPendingInstallTireIds()};
    final prefs = await SharedPreferences.getInstance();

    if (online) {
      try {
        final entries = await SearchApi()
            .fetchPendingInspections(accId)
            .timeout(const Duration(seconds: 10));
        final serverIds = <int>{};
        for (final p in entries) {
          final s = p.status?.statusId;
          if (!(s == null || s == 1)) continue; // sirf Pending
          if (p.tire?.tireId != null) serverIds.add(p.tire!.tireId!);
          for (final t in p.tiresList) {
            if (t.tireId != null) serverIds.add(t.tireId!);
          }
        }
        serverIds.remove(0);
        await prefs.setStringList(
          _kPendingApprovalTireIdsKey,
          serverIds.map((e) => e.toString()).toList(),
        );
        ids.addAll(serverIds);
        return ids;
      } catch (_) {
        // fail-open: last known list use karo
      }
    }

    final cachedIds = prefs.getStringList(_kPendingApprovalTireIdsKey) ?? const [];
    ids.addAll(cachedIds.map(int.tryParse).whereType<int>());
    return ids;
  }

  TyreModel _hiveToTyreModel(dynamic h) {
    final String? distSrc = TyreUnitHistory.getDistanceUnit(h.tireId) ??
        (h.serialNumber != null ? TyreUnitHistory.getDistanceUnit(h.serialNumber) : null);

    final double? savedTo = TyreUnitHistory.getRawOutside(h.tireId) ??
        (h.serialNumber != null ? TyreUnitHistory.getRawOutside(h.serialNumber) : null);
    final double? savedTm = TyreUnitHistory.getRawMiddle(h.tireId) ??
        (h.serialNumber != null ? TyreUnitHistory.getRawMiddle(h.serialNumber) : null);
    final double? savedTi = TyreUnitHistory.getRawInside(h.tireId) ??
        (h.serialNumber != null ? TyreUnitHistory.getRawInside(h.serialNumber) : null);
    final double? savedMiles = TyreUnitHistory.getRawMiles(h.tireId) ??
        (h.serialNumber != null ? TyreUnitHistory.getRawMiles(h.serialNumber) : null);

    final double hOutside = (h.outsideTread is num)
        ? (h.outsideTread as num).toDouble()
        : (double.tryParse('${h.outsideTread ?? ''}') ?? 0.0);
    final double hMiddle = (h.middleTread is num)
        ? (h.middleTread as num).toDouble()
        : (h.currentTreadDepth is num)
            ? (h.currentTreadDepth as num).toDouble()
            : (double.tryParse('${h.middleTread ?? h.currentTreadDepth ?? ''}') ?? 0.0);
    final double hInside = (h.insideTread is num)
        ? (h.insideTread as num).toDouble()
        : (double.tryParse('${h.insideTread ?? ''}') ?? 0.0);
    final double hMiles = (h.currentMiles is num)
        ? (h.currentMiles as num).toDouble()
        : (double.tryParse('${h.currentMiles ?? ''}') ?? 0.0);

    final double rawOutside = (hOutside > 0)
        ? hOutside
        : (savedTo != null && savedTo > 0 ? savedTo : 0.0);
    final double rawMiddle = (hMiddle > 0)
        ? hMiddle
        : (savedTm != null && savedTm > 0 ? savedTm : 0.0);
    final double rawInside = (hInside > 0)
        ? hInside
        : (savedTi != null && savedTi > 0 ? savedTi : 0.0);
    final double rawMiles = (savedMiles != null && savedMiles > 0)
        ? savedMiles
        : ((hMiles > 0)
            ? (MeasurementHelper.isImperial ? hMiles : MeasurementHelper.toDisplayDistance(hMiles, sourceUnit: distSrc))
            : 0.0);

    final double bestSingle = rawMiddle > 0
        ? rawMiddle
        : (rawOutside > 0 ? rawOutside : rawInside);

    final double resolvedOutside = rawOutside > 0 ? rawOutside : bestSingle;
    final double resolvedInside = rawInside > 0 ? rawInside : bestSingle;
    final double resolvedMiddle = rawMiddle > 0 ? rawMiddle : bestSingle;

    final double resolvedCtd = resolvedMiddle > 0
        ? resolvedMiddle
        : (resolvedOutside + resolvedInside) / 2;

    return TyreModel(
      tireId: h.tireId,
      tireSerialNo: h.serialNumber,
      brandNo: h.brandNo,
      sizeName: h.tireSizeName,
      typeName: h.tireTypeName ?? h.typeName,
      tireStatusName: (h.tireStatusName != null && h.tireStatusName!.isNotEmpty)
          ? h.tireStatusName
          : (h.dispositionName != null && h.dispositionName!.isNotEmpty)
          ? h.dispositionName
          : 'Inventory',
      vehicleId: h.vehicleId,
      vehicleNumber: null,
      wheelPosition: h.wheelPosition,
      dispositionId: h.dispositionId,
      dispositionName: h.dispositionName,
      dispositionGroupId: h.dispositionGroupId,
      manufacturerName: h.manufacturerName,
      currentTreadDepth: resolvedCtd,
      outsideTread: resolvedOutside,
      middleTread: resolvedMiddle,
      insideTread: resolvedInside,
      currentPressure: h.currentPressure,
      percentageWorn: (((h.originalTread ?? 0) > 0 && resolvedCtd > 0)
          ? (resolvedCtd >= h.originalTread!
              ? 0.0
              : (((1 - (resolvedCtd - ((h.originalTread! > (h.removeAt ?? 0)) ? (h.removeAt ?? 0.0) : 0.0)) /
                      (((h.originalTread! - (h.removeAt ?? 0)) > 0)
                          ? (h.originalTread! - (h.removeAt ?? 0))
                          : h.originalTread!)) * 100).clamp(0.0, 100.0)))
          : ((h.percentageWorn != null && h.percentageWorn! >= 0) ? h.percentageWorn : 0.0)),
      originalTread: h.originalTread,
      currentHours: h.currentHours,
      currentMiles: rawMiles,
      inspectionDate: null,
    );
  }

  Future<void> fetchInventoryTyres() async {
    isLoading.value = true;
    try {
      final parentAccountId = await SecureStorage.getParentAccountId();
      if (parentAccountId == null || parentAccountId.isEmpty) {
        Get.snackbar("Error", "Parent account not selected");
        return;
      }
      final int accId = int.parse(parentAccountId);
      final online = await NetworkHelper.hasInternet();

      List<TyreModel> inventoryTyres;

      if (online) {
        isOffline.value = false;
        final tyres = await service.getTyresByAccount(accId);

        await OfflineHiveService.saveTyres(
          tyres
              .map(
                (t) => {
              'tireId': t.tireId ?? 0,
              'parentAccountId': accId,
              'locationId': 0,
              'serialNumber': t.tireSerialNo,
              'manufacturerName': t.manufacturerName,
              'tireSizeName': t.sizeName,
              'tireTypeName': t.typeName,
              'dispositionId': t.dispositionId,
              'dispositionName': t.dispositionName,
              'dispositionGroupId': t.dispositionGroupId,
              'vehicleId': t.vehicleId,
              'wheelPosition': t.wheelPosition,
              'typeName': t.typeName,
              'outsideTread': t.outsideTread,
              'middleTread': t.middleTread,
              'insideTread': t.insideTread,
              'currentPressure': t.currentPressure,
              'currentTreadDepth': t.currentTreadDepth,
              'brandNo': t.brandNo,
              'tireStatusName': t.tireStatusName,
              'percentageWorn': t.percentageWorn,
              'originalTread': t.originalTread,
              'currentHours': t.currentHours,
              'currentMiles': t.currentMiles,
            },
          )
              .toList(),
        );

        inventoryTyres = tyres.where((t) {
          final dispId = t.dispositionId ?? 0;
          final dispName = (t.dispositionName ?? '').toLowerCase().trim();
          if (dispId == 7 || dispName == 'installed') return false;
          if (t.vehicleId != null && t.vehicleId! > 0) return false;
          if (dispId != 8) return false;
          return true;
        }).toList();

        final hiveTyresAll = OfflineHiveService.getAllTyres(
          parentAccountId: accId,
        );
        final hiveMap = {for (final h in hiveTyresAll) h.tireId: h};
        inventoryTyres = inventoryTyres.where((t) {
          if (t.tireId == null) return true;
          final h = hiveMap[t.tireId];
          if (h == null) return true;

          final hDispId = h.dispositionId ?? 0;
          final hVehId = h.vehicleId;
          if (hVehId != null && hVehId > 0 && hDispId == 7) {
            return false;
          }
          if (hDispId != 0 && hDispId != 8 && hDispId != 7) {
            return false;
          }
          return true;
        }).toList();

        final cached = OfflineHiveService.getAllTyres(parentAccountId: accId);
        final pendingTyres = cached.where((h) {
          if (h.isPendingSync != true) return false;
          final dispId = h.dispositionId ?? 0;
          final dispName = (h.dispositionName ?? '').toLowerCase().trim();
          if (dispId == 7 || dispName == 'installed') return false;
          if (h.vehicleId != null && h.vehicleId! > 0) return false;
          if (dispId != 8 && dispId != 0) return false;
          return true;
        }).toList();

        if (pendingTyres.isNotEmpty) {
          final pendingConverted = pendingTyres.map(_hiveToTyreModel).toList();
          final existingIds = inventoryTyres.map((t) => t.tireId).toSet();
          final newPending = pendingConverted
              .where((t) => !existingIds.contains(t.tireId))
              .toList();
          inventoryTyres = [...inventoryTyres, ...newPending];
        }
      } else {
        isOffline.value = true;

        final cached = OfflineHiveService.getInventoryTyres(
          parentAccountId: accId,
        );
        inventoryTyres = cached.map(_hiveToTyreModel).toList();
      }

      final activeMountedTireIds = <int>{};
      final activeMountedSerialNos = <String>{};

      if (Get.isRegistered<VehicleInspeController>()) {
        final vic = Get.find<VehicleInspeController>();
        for (final t in vic.tires) {
          if (t.tireId != null && t.tireId! > 0) {
            activeMountedTireIds.add(t.tireId!);
          }
          final s = (t.tireSerialNo ?? '').trim().toUpperCase();
          if (s.isNotEmpty) {
            activeMountedSerialNos.add(s);
          }
        }
      }

      try {
        final rawVehId = (Get.arguments is Map) ? Get.arguments['vehicleId'] : null;
        if (rawVehId != null) {
          final cachedJson = OfflineHiveService.getInspectionCache(rawVehId.toString());
          if (cachedJson != null) {
            final parsed = jsonDecode(cachedJson) as Map<String, dynamic>;
            final installed = parsed['model']?['installedTires'] as List<dynamic>?;
            if (installed != null) {
              for (final item in installed) {
                if (item is Map) {
                  final tId = item['tireId'];
                  if (tId is int && tId > 0) activeMountedTireIds.add(tId);
                  final s = (item['tireSerialNo']?.toString() ?? '').trim().toUpperCase();
                  if (s.isNotEmpty) activeMountedSerialNos.add(s);
                }
              }
            }
          }
        }
      } catch (_) {}

      if (activeMountedTireIds.isNotEmpty || activeMountedSerialNos.isNotEmpty) {
        inventoryTyres = inventoryTyres.where((t) {
          if (t.tireId != null && activeMountedTireIds.contains(t.tireId)) {
            return false;
          }
          final s = (t.tireSerialNo ?? '').trim().toUpperCase();
          if (s.isNotEmpty && activeMountedSerialNos.contains(s)) {
            return false;
          }
          return true;
        }).toList();
      }

      final pendingIds = await _pendingInstallTireIds(accId, online: online);
      if (pendingIds.isNotEmpty) {
        inventoryTyres = inventoryTyres
            .where((t) => t.tireId == null || !pendingIds.contains(t.tireId))
            .toList();
      }

      allTyres.assignAll(inventoryTyres);
      visibleTyres.assignAll(inventoryTyres);

      if (searchText.value.isNotEmpty) {
        onSearch(searchText.value);
      }
    } catch (e) {
      await _loadFromHiveFallback();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadFromHiveFallback() async {
    try {
      final parentAccountId = await SecureStorage.getParentAccountId();
      if (parentAccountId == null) return;
      final int accId = int.parse(parentAccountId);

      final cached = OfflineHiveService.getInventoryTyres(
        parentAccountId: accId,
      );
      if (cached.isNotEmpty) {
        var converted = cached.map(_hiveToTyreModel).toList();

        final activeMountedTireIds = <int>{};
        final activeMountedSerialNos = <String>{};

        if (Get.isRegistered<VehicleInspeController>()) {
          final vic = Get.find<VehicleInspeController>();
          for (final t in vic.tires) {
            if (t.tireId != null && t.tireId! > 0) {
              activeMountedTireIds.add(t.tireId!);
            }
            final s = (t.tireSerialNo ?? '').trim().toUpperCase();
            if (s.isNotEmpty) {
              activeMountedSerialNos.add(s);
            }
          }
        }

        try {
          final rawVehId = (Get.arguments is Map) ? Get.arguments['vehicleId'] : null;
          if (rawVehId != null) {
            final cachedJson = OfflineHiveService.getInspectionCache(rawVehId.toString());
            if (cachedJson != null) {
              final parsed = jsonDecode(cachedJson) as Map<String, dynamic>;
              final installed = parsed['model']?['installedTires'] as List<dynamic>?;
              if (installed != null) {
                for (final item in installed) {
                  if (item is Map) {
                    final tId = item['tireId'];
                    if (tId is int && tId > 0) activeMountedTireIds.add(tId);
                    final s = (item['tireSerialNo']?.toString() ?? '').trim().toUpperCase();
                    if (s.isNotEmpty) activeMountedSerialNos.add(s);
                  }
                }
              }
            }
          }
        } catch (_) {}

        final fbPending = await _pendingInstallTireIds(accId, online: false);
        activeMountedTireIds.addAll(fbPending);

        if (activeMountedTireIds.isNotEmpty || activeMountedSerialNos.isNotEmpty) {
          converted = converted.where((t) {
            if (t.tireId != null && activeMountedTireIds.contains(t.tireId)) {
              return false;
            }
            final s = (t.tireSerialNo ?? '').trim().toUpperCase();
            if (s.isNotEmpty && activeMountedSerialNos.contains(s)) {
              return false;
            }
            return true;
          }).toList();
        }

        allTyres.assignAll(converted);
        visibleTyres.assignAll(converted);
        isOffline.value = true;
      } else {
        Get.snackbar(
          "Error",
          "Failed to load inventory. Check your connection.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (_) {}
  }

  void onSearch(String value) {
    searchText.value = value;
    if (value.trim().isEmpty) {
      visibleTyres.assignAll(allTyres);
      return;
    }
    final query = value.toLowerCase().trim();
    visibleTyres.assignAll(
      allTyres.where((t) {
        return (t.tireSerialNo ?? '').toLowerCase().contains(query) ||
            (t.sizeName ?? '').toLowerCase().contains(query) ||
            (t.vehicleNumber ?? '').toLowerCase().contains(query) ||
            (t.manufacturerName ?? '').toLowerCase().contains(query) ||
            (t.brandNo ?? '').toLowerCase().contains(query);
      }).toList(),
    );
  }

  void openBottomSheet(TyreModel tyre) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Center(child: Text('View')),
              onTap: () {
                Get.back();
                Get.to(() => TyreView(), arguments: tyre.tireId);
              },
            ),
            ListTile(
              title: const Center(child: Text('Edit')),
              onTap: () async {
                Get.back();
                final allowed = await PendingInspectionGuard.canProceedForTire(
                  tireId: tyre.tireId,
                  tireSerialNo: tyre.tireSerialNo,
                  action: PendingBlockedAction.editTyre,
                );
                if (!allowed) return;
                Get.toNamed(AppPages.EDIT_TIRE_SCREEN, arguments: tyre.tireId);
              },
            ),
            ListTile(
              title: const Center(child: Text('Clone')),
              onTap: () async {
                Get.back();
                final allowed = await PendingInspectionGuard.canProceedForTire(
                  tireId: tyre.tireId,
                  tireSerialNo: tyre.tireSerialNo,
                  action: PendingBlockedAction.cloneTyre,
                );
                if (!allowed) return;
                Get.toNamed(
                  AppPages.CREATE_TYRE,
                  arguments: {
                    'tireId': tyre.tireId,
                    'cloneModel': tyre,
                    'ratingName': tyre.ratingName,
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void onClose() {
    _connectivitySub?.cancel();
    OfflineHiveService.unregisterPostSyncTyreListener(_onTyreSynced);
    super.onClose();
  }
}
