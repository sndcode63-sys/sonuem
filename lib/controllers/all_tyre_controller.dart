import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emtrack/inspection/vehicle_inspe_view.dart';
import 'package:emtrack/routes/app_pages.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/tyre_model.dart';
import '../services/role_service.dart';
import '../services/tyre_service.dart';
import '../services/tyre_view_service.dart';
import '../services/offline_hive_service.dart';
import '../utils/network_helper.dart';
import '../utils/pending_inspection_guard.dart';
import '../views/tyre_view.dart';

class AllTyreController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final TyreService service = TyreService();

  AppLocalizations get l10n => AppLocalizations.of(Get.context!);

  TabController? tabController;

  final RxBool isLoading = false.obs;
  final RxBool isOffline = false.obs;

  final RxList<TyreModel> allTyres = <TyreModel>[].obs;
  final RxList<TyreModel> tabFilteredTyres = <TyreModel>[].obs;
  final RxList<TyreModel> visibleTyres = <TyreModel>[].obs;
  final RxString searchText = ''.obs;

  StreamSubscription? _connectivitySub;

  List<String> get tabs => [
    l10n.all,
    l10n.install,
    l10n.inventory,
    l10n.onHold,
    l10n.scrap,
    l10n.repair,
    l10n.retread,
  ];

  String get currentTab => tabs[tabController?.index ?? 0];

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: tabs.length, vsync: this);
    fetchData();
    OfflineHiveService.registerPostSyncTyreListener(_onTyreSynced);

    tabController!.addListener(() {
      if (!tabController!.indexIsChanging) {
        searchText.value = '';
        _applyTabFilter();
      }
    });

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online && isOffline.value) {
        fetchData();
      }
    });
  }

  Future<void> fetchData({bool showSnackbarOnError = false}) async {
    isLoading.value = true;
    try {
      final String? parentAccountId = await SecureStorage.getParentAccountId();
      if (parentAccountId == null || parentAccountId.isEmpty || parentAccountId == '0') {
        isLoading.value = false;
        if (showSnackbarOnError) {
          Get.snackbar("Error", "Parent account not selected");
        }
        return;
      }
      final int accId = int.parse(parentAccountId);
      final selectedLocationIds = SecureStorage.getSelectedLocationIds()
          .map((e) => int.tryParse(e))
          .whereType<int>()
          .where((id) => id > 0)
          .toSet();
      bool matchesLocation(TyreModel t) {
        if (selectedLocationIds.isEmpty) return true;
        final locId = t.locationId;
        if (locId == null || locId == 0) return true;
        return selectedLocationIds.contains(locId);
      }

      final online = await NetworkHelper.hasInternet();

      if (online) {
        isOffline.value = false;
        final tyres = await service.getTyresByAccount(accId);
        final filteredTyres = tyres.where(matchesLocation).toList();

        await OfflineHiveService.saveTyres(
          tyres
              .map(
                (t) => {
              'tireId': t.tireId ?? 0,
              'parentAccountId': accId,
              'locationId': t.locationId ?? 0,
              'serialNumber': t.tireSerialNo,
              'manufacturerName': t.manufacturerName,
              'manufacturerId': t.manufacturerId,
              'tireSizeName': t.sizeName,
              'tireSizeId': t.sizeId,
              'tireTypeName': t.typeName,
              'tireTypeId': t.typeId,
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
              'currentTreadDepth': t.currentTreadDepth != null
                  ? double.parse(t.currentTreadDepth!.toStringAsFixed(2))
                  : (t.middleTread != null && t.middleTread! > 0
                  ? double.parse(
                (((t.outsideTread ?? 0) +
                    t.middleTread! +
                    (t.insideTread ?? 0)) /
                    3)
                    .toStringAsFixed(2),
              )
                  : (((t.outsideTread ?? 0) + (t.insideTread ?? 0)) >
                  0
                  ? double.parse(
                (((t.outsideTread ?? 0) +
                    (t.insideTread ?? 0)) /
                    2)
                    .toStringAsFixed(2),
              )
                  : 0.0)),
              'brandNo': t.brandNo,
              'tireStatusName': t.tireStatusName,
              'evaluationNo': t.evaluationNo,
              'lotNo': t.lotNo,
              'poNo': t.poNo,
              'mileageType': t.mileageType,
              'currentHours': t.currentHours,
              'currentMiles': t.currentMiles,
              'originalTread': t.originalTread,
              'purchasedTread': t.purchasedTread,
              'removeAt': t.removeAt,
              'starRatingId': t.starRatingId,
              'indCodeId': null,
              'compoundId': t.compoundId,
              'loadRatingId': t.loadRatingId,
              'speedRatingId': t.speedRatingId,
              'fillTypeId': t.fillTypeId,
              'purchaseCost': t.purchaseCost,
              'casingValue': t.casingValue,
              'fillCost': t.fillCost,
              'repairCost': t.repairCost,
              'retreadCost': t.retreadCost,
              'warrantyAdjustment': null,
              'costAdjustment': t.costAdjustment,
              'soldAmount': null,
              'netCost': t.netCost,
            },
          )
              .toList(),
        );

        final patchedTyres = filteredTyres.map((t) {
          final tId = t.tireId ?? 0;
          if (tId > 0 && OfflineHiveService.isTireRecentlyRemoved(tId)) {
            final hiveTyre = OfflineHiveService.getTyreById(tId);
            if (hiveTyre != null) {
              return t.copyWith(
                dispositionId: hiveTyre.dispositionId,
                dispositionName: hiveTyre.dispositionName,
                clearVehicle: true,
              );
            } else {
              return t.copyWith(clearVehicle: true);
            }
          }
          return t;
        }).toList();

        final cachedPending = OfflineHiveService.getAllTyres(parentAccountId: accId)
            .where((t) => t.isPendingSync == true)
            .toList();
        final pendingModels = _hiveToTyreModels(cachedPending).where(matchesLocation).toList();
        final combined = [...pendingModels, ...patchedTyres];
        allTyres.assignAll(combined);

        for (final t in tyres) {
          if (t.tireId != null && t.tireId! > 0) {
            OfflineHiveService.clearTireDetailCache(t.tireId!);
          }
        }

        _preCacheAllTyres(tyres);
      } else {
        isOffline.value = true;
        final cached = OfflineHiveService.getAllTyres(parentAccountId: accId);

        final converted = _hiveToTyreModels(cached).where(matchesLocation).toList();
        allTyres.assignAll(converted);
      }

      _applyTabFilter();
    } catch (e) {
      await _loadFromHiveFallback();
    } finally {
      isLoading.value = false;
    }
  }

  String? _lookupVehicleNumber(int? vehicleId) {
    if (vehicleId == null || vehicleId == 0) return null;
    final vehicle = OfflineHiveService.getVehicleById(vehicleId);
    return vehicle?.vehicleNumber;
  }

  List<TyreModel> _hiveToTyreModels(List cached) {
    return cached.map((h) {
      final String? dispositionName =
      (h.dispositionName != null && h.dispositionName!.isNotEmpty)
          ? h.dispositionName
          : null;

      final String? statusName =
      (h.tireStatusName != null && h.tireStatusName!.isNotEmpty)
          ? h.tireStatusName
          : dispositionName;

      final String? vehicleNumber = _lookupVehicleNumber(h.vehicleId);

      return TyreModel(
        tireId: h.tireId,
        tireSerialNo: h.serialNumber,
        brandNo: h.brandNo,
        sizeName: h.tireSizeName,
        sizeId: h.tireSizeId,
        typeName: h.tireTypeName ?? h.typeName,
        typeId: h.tireTypeId,
        tireStatusName: statusName,
        vehicleId: h.vehicleId,
        vehicleNumber: vehicleNumber,
        wheelPosition: h.wheelPosition,
        dispositionId: h.dispositionId,
        dispositionName: dispositionName,
        dispositionGroupId: h.dispositionGroupId,
        manufacturerName: h.manufacturerName,
        manufacturerId: h.manufacturerId,
        currentTreadDepth: h.currentTreadDepth != null
            ? double.parse(h.currentTreadDepth!.toStringAsFixed(2))
            : (h.middleTread != null && h.middleTread! > 0
            ? double.parse(
          (((h.outsideTread ?? 0) +
              h.middleTread! +
              (h.insideTread ?? 0)) /
              3)
              .toStringAsFixed(2),
        )
            : (((h.outsideTread ?? 0) + (h.insideTread ?? 0)) > 0
            ? double.parse(
          (((h.outsideTread ?? 0) + (h.insideTread ?? 0)) / 2)
              .toStringAsFixed(2),
        )
            : null)),
        outsideTread: h.outsideTread,
        middleTread: h.middleTread,
        insideTread: h.insideTread,
        currentPressure: h.currentPressure,
        inspectionDate: null,
        evaluationNo: h.evaluationNo,
        lotNo: h.lotNo,
        poNo: h.poNo,
        mileageType: h.mileageType,
        currentHours: h.currentHours,
        currentMiles: h.currentMiles,
        originalTread: h.originalTread,
        purchasedTread: h.purchasedTread,
        removeAt: h.removeAt,
        starRatingId: h.starRatingId,
        compoundId: h.compoundId,
        loadRatingId: h.loadRatingId,
        speedRatingId: h.speedRatingId,
        fillTypeId: h.fillTypeId,
        purchaseCost: h.purchaseCost,
        casingValue: h.casingValue,
        fillCost: h.fillCost,
        repairCost: h.repairCost,
        retreadCost: h.retreadCost,
        costAdjustment: h.costAdjustment,
        netCost: h.netCost,
      );
    }).toList();
  }

  Future<void> _loadFromHiveFallback() async {
    try {
      final String? parentAccountId = await SecureStorage.getParentAccountId();
      if (parentAccountId == null) return;
      final int accId = int.parse(parentAccountId);
      final cached = OfflineHiveService.getAllTyres(parentAccountId: accId);
      if (cached.isNotEmpty) {
        final selectedLocationIds = SecureStorage.getSelectedLocationIds()
            .map((e) => int.tryParse(e))
            .whereType<int>()
            .where((id) => id > 0)
            .toSet();
        final models = _hiveToTyreModels(cached).where((t) {
          if (selectedLocationIds.isEmpty) return true;
          final locId = t.locationId;
          if (locId == null || locId == 0) return true;
          return selectedLocationIds.contains(locId);
        }).toList();

        allTyres.assignAll(models);
        _applyTabFilter();
        isOffline.value = true;
      } else {
        Get.snackbar(
          "Error",
          "Failed to load tyres. Please check your network.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.wifi_off, color: Colors.white),
          duration: const Duration(seconds: 4),
        );
      }
    } catch (_) {}
  }

  bool _isInstalled(TyreModel t) {
    if (t.tireId != null && t.tireId! > 0 && OfflineHiveService.isTireRecentlyRemoved(t.tireId!)) {
      return false;
    }

    final dispId = t.dispositionId ?? 0;
    final dispName = (t.dispositionName ?? '').toLowerCase().trim();

    // Agar tyre ka status explicitly Scrap, Inventory, Repair, Retread ya On Hold hai toh Installed nahi ho sakta
    if (dispId == 1 || dispId == 2 || dispId == 3 || dispId == 4 || dispId == 8 ||
        dispName.contains('scrap') || dispName.contains('inventory') ||
        dispName.contains('repair') || dispName.contains('retread') || dispName.contains('hold')) {
      return false;
    }

    if (dispName == 'installed' || dispId == 7) return true;

    final hasVehicle = (t.vehicleId != null && t.vehicleId! > 0);
    final pos = t.wheelPosition?.trim() ?? '';
    final hasPosition = pos.isNotEmpty && pos.toLowerCase() != 'n/a';
    return hasVehicle || hasPosition;
  }

  bool _isInstalledOffline(TyreModel t) {
    if (t.tireId != null && t.tireId! > 0 && OfflineHiveService.isTireRecentlyRemoved(t.tireId!)) {
      return false;
    }
    if (_isInstalled(t)) return true;
    if (t.vehicleId != null && t.vehicleId! < 0) {
      final dispId = t.dispositionId ?? 0;
      final dispName = (t.dispositionName ?? '').toLowerCase().trim();
      if (dispId == 1 || dispId == 2 || dispId == 3 || dispId == 4 || dispId == 8 ||
          dispName.contains('scrap') || dispName.contains('inventory') ||
          dispName.contains('repair') || dispName.contains('retread') || dispName.contains('hold')) {
        return false;
      }
      return true;
    }
    return false;
  }

  String _getEffectiveStatus(TyreModel t) {
    if (t.dispositionId != null && t.dispositionId! > 0) {
      switch (t.dispositionId) {
        case 1:
          return 'scrap';
        case 2:
          return 'repair';
        case 3:
          return 'retread';
        case 4:
          return 'on hold';
        case 7:
          return 'installed';
        case 8:
          return 'inventory';
      }
    }

    final rawName = (t.dispositionName ?? '').toLowerCase().trim();
    final dispName = rawName
        .replaceAll(RegExp(r'[\-_]'), ' ')
        .replaceAllMapped(RegExp(r'onhold'), (_) => 'on hold');
    if (dispName.isNotEmpty) {
      if (dispName.contains('scrap')) return 'scrap';
      if (dispName.contains('repair')) return 'repair';
      if (dispName.contains('retread')) return 'retread';
      if (dispName.contains('hold')) return 'on hold';
      if (dispName.contains('mount') || dispName.contains('install')) return 'installed';
      if (dispName.contains('inventory')) return 'inventory';
      return dispName;
    }

    return '';
  }

  void _applyTabFilter() {
    final int index = tabController?.index ?? 0;
    List<TyreModel> filtered;

    if (index == 0) {
      // All
      filtered = List<TyreModel>.from(allTyres);
    } else if (index == 1) {
      filtered = allTyres.where((t) => _isInstalledOffline(t)).toList();
    } else if (index == 2) {
      const otherStatuses = [
        'installed',
        'on hold',
        'onhold',
        'scrap',
        'repair',
        'retread',
      ];
      const nonInventoryIds = [1, 2, 3, 4, 7];
      filtered = allTyres.where((t) {
        if (_isInstalledOffline(t)) return false;
        final dispId = t.dispositionId ?? 0;
        if (nonInventoryIds.contains(dispId)) return false;
        final status = _getEffectiveStatus(t);
        final normalizedStatus = status.toLowerCase().replaceAll(
          RegExp(r'[\s\-_]'),
          '',
        );
        if (otherStatuses
            .map((s) => s.replaceAll(' ', ''))
            .contains(normalizedStatus)) {
          return false;
        }
        return true;
      }).toList();
    } else if (index == 3) {
      filtered = allTyres.where((t) {
        final status = _getEffectiveStatus(t);
        return status == 'on hold' || t.dispositionId == 4;
      }).toList();
    } else if (index == 4) {
      filtered = allTyres.where((t) {
        final status = _getEffectiveStatus(t);
        return status == 'scrap' || t.dispositionId == 1;
      }).toList();
    } else if (index == 5) {
      filtered = allTyres.where((t) {
        final status = _getEffectiveStatus(t);
        return status == 'repair' || t.dispositionId == 2;
      }).toList();
    } else if (index == 6) {
      filtered = allTyres.where((t) {
        final status = _getEffectiveStatus(t);
        return status == 'retread' || t.dispositionId == 3;
      }).toList();
    } else {
      filtered = List<TyreModel>.from(allTyres);
    }

    tabFilteredTyres.assignAll(filtered);
    if (searchText.value.trim().isEmpty) {
      visibleTyres.assignAll(filtered);
    } else {
      _applySearch(searchText.value);
    }
  }

  Future<void> _preCacheAllTyres(List<TyreModel> tyres) async {
    final tyreViewService = TyreViewService();

    for (final t in tyres) {
      if (t.tireId == null || t.tireId! <= 0) continue;
      try {
        if (!OfflineHiveService.hasTireDetailCache(t.tireId!)) {
          await tyreViewService.fetchTyreDetailsById(t.tireId!);
        }
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (_) {}
    }
  }

  void onSearch(String value) {
    searchText.value = value;
    _applySearch(value);
  }

  void _applySearch(String value) {
    if (value.trim().isEmpty) {
      visibleTyres.assignAll(tabFilteredTyres);
      return;
    }
    final query = value.toLowerCase().trim();
    visibleTyres.assignAll(
      tabFilteredTyres.where((t) {
        return (t.tireSerialNo ?? '').toLowerCase().contains(query) ||
            (t.sizeName ?? '').toLowerCase().contains(query) ||
            (t.vehicleNumber ?? '').toLowerCase().contains(query) ||
            (t.manufacturerName ?? '').toLowerCase().contains(query) ||
            (t.brandNo ?? '').toLowerCase().contains(query);
      }).toList(),
    );
  }

  @override
  Future<void> refresh() async {
    searchText.value = '';
    await fetchData(showSnackbarOnError: true);
  }

  void reapplyFilters() {
    _applyTabFilter();
  }

  void openBottomSheet(TyreModel tyre) {
    final bool installed = _isInstalledOffline(tyre);
    final bool _ = (tyre.tireId ?? 0) < 0;

    final String role = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>().userRole.value
        : '';

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (installed && RoleService.canInspectVehicle(role)) ...[
                ListTile(
                  title: const Center(
                    child: Text('Inspect', style: TextStyle(color: Colors.red)),
                  ),
                  onTap: () {
                    Get.back();
                    Get.to(() => VehicleInspeView(), arguments: tyre.vehicleId);
                  },
                ),
              ],
              if (RoleService.canViewTire(role))
                ListTile(
                  title: Center(
                    child: Text(
                      l10n.view,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  onTap: () {
                    Get.back();
                    Get.to(() => TyreView(), arguments: tyre.tireId);
                  },
                ),
              if (RoleService.canEditTire(role))
                ListTile(
                  title: Center(
                    child: Text(
                      l10n.edit,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  onTap: () async {
                    Get.back();
                    final allowed = await PendingInspectionGuard.canProceedForTire(
                      tireId: tyre.tireId,
                      tireSerialNo: tyre.tireSerialNo,
                      action: PendingBlockedAction.editTyre,
                    );
                    if (!allowed) return;
                    Get.toNamed(
                      AppPages.EDIT_TIRE_SCREEN,
                      arguments: tyre.tireId,
                    );
                  },
                ),
              if (RoleService.canCloneTire(role))
                ListTile(
                  title: Center(
                    child: Text(
                      l10n.clone,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
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
      ),
      isScrollControlled: false,
    );
  }

  void _onTyreSynced() {
    fetchData();
  }

  @override
  void onClose() {
    OfflineHiveService.unregisterPostSyncTyreListener(_onTyreSynced);
    _connectivitySub?.cancel();
    tabController?.dispose();
    super.onClose();
  }
}