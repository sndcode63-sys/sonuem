import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emtrack/controllers/inspect_tyre_controller.dart';
import 'package:emtrack/inspection/vehicle_inspe_controller.dart';
import 'package:emtrack/inspection/vehicle_inspe_view.dart';
import 'package:emtrack/views/inspect_tyre_view.dart';
import 'package:emtrack/inspection/vehicle_inspe_model.dart';
import 'package:emtrack/search_tyre_vehicle/vehicle_item_model.dart';
import 'package:emtrack/search_tyre_vehicle/tire_item_model.dart';
import 'package:emtrack/search_tyre_vehicle/search_api_service.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:get/get.dart';

class SearchVehicleTyreController extends GetxController {
  final SearchApi api = SearchApi();

  static Future<bool> _isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  RxInt selectedTab = 0.obs;
  RxString searchText = ''.obs;

  RxList<VehicleItem> vehicles = <VehicleItem>[].obs;
  RxList<TireItem> tyres = <TireItem>[].obs;
  RxList<VehicleItem> recentVehicles = <VehicleItem>[].obs;
  RxList<TireItem> recentTyres = <TireItem>[].obs;
  RxList<dynamic> visibleList = <dynamic>[].obs;

  RxBool isLoading = false.obs;
  bool _isNavigating = false;

  @override
  void onInit() {
    super.onInit();
    loadData();
    loadRecentFromStorage();
  }

  bool _isInstalled({
    required String? dispositionName,
    required int? dispositionId,
    required int? vehicleId,
    required String? wheelPosition,
  }) {
    final dispName = (dispositionName ?? '').toLowerCase().trim();
    if (dispName == 'installed') return true;

    final dispId = dispositionId ?? 0;
    if (dispId == 7) return true;

    final hasVehicle = (vehicleId != null && vehicleId > 0);
    final pos = wheelPosition?.trim() ?? '';
    final hasPosition = pos.isNotEmpty && pos.toLowerCase() != 'n/a';
    return hasVehicle || hasPosition;
  }

  bool _isInstalledOffline({
    required String? dispositionName,
    required int? dispositionId,
    required int? vehicleId,
    required String? wheelPosition,
  }) {
    if (_isInstalled(
      dispositionName: dispositionName,
      dispositionId: dispositionId,
      vehicleId: vehicleId,
      wheelPosition: wheelPosition,
    )) {
      return true;
    }
    if (vehicleId != null && vehicleId < 0) return true;
    return false;
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      final String? accountIdStr = await SecureStorage.getParentAccountId();
      if (accountIdStr == null || accountIdStr.isEmpty) return;

      final int? accountId = int.tryParse(accountIdStr);
      if (accountId == null) return;

      final online = await _isOnline();

      if (online) {
        try {
          vehicles.value = await api.fetchVehicles(accountId);

          final remoteTyres = await api.fetchTyres(accountId);

          final hiveTyres = OfflineHiveService.getAllTyres(parentAccountId: accountId);
          final hiveMap = {for (final h in hiveTyres) h.tireId: h};

          tyres.value = remoteTyres.where((t) {

            final hive = hiveMap[t.tireId];
            if (hive != null) {
              final hiveVehicleId = hive.vehicleId;
              final hiveDispId = hive.dispositionId ?? 0;

              if ((hiveVehicleId == null || hiveVehicleId == 0) && hiveDispId != 7) {
                return false;
              }

              return _isInstalledOffline(
                dispositionName: hiveDispId == 7 ? 'installed' : (hive.dispositionName ?? t.dispositionName),
                dispositionId: hiveDispId,
                vehicleId: hiveVehicleId ?? t.vehicleId,
                wheelPosition: hive.wheelPosition ?? t.wheelPosition,
              );
            }

            return _isInstalledOffline(
              dispositionName: t.dispositionName,
              dispositionId: null,
              vehicleId: t.vehicleId,
              wheelPosition: t.wheelPosition,
            );
          }).toList();

        } catch (e) {
          _loadFromHive(accountId);
        }
      } else {
        _loadFromHive(accountId);
      }

      updateVisibleList();
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  void _loadFromHive(int accountId) {
    final hiveVehicles = OfflineHiveService.getVehicles(
      parentAccountId: accountId,
    );
    vehicles.value = hiveVehicles
        .map(
          (h) => VehicleItem(
        vehicleId: h.vehicleId,
        vehicleNumber: h.vehicleNumber,
        parentAccountId: accountId,
        manufacturer: h.manufacturerName,
        typeName: h.typeName,
        modelName: h.modelName,
        tireSize: null,
        mileageType: null,
        currentHours: null,
        currentMiles: null,
      ),
    )
        .toList();

    final hiveTyres = OfflineHiveService.getAllTyres(
      parentAccountId: accountId,
    );

    final installedHiveTyres = hiveTyres.where(
          (h) => _isInstalledOffline(
        dispositionName: h.dispositionId == 7 ? 'installed' : h.dispositionName,
        dispositionId: h.dispositionId,
        vehicleId: h.vehicleId,
        wheelPosition: h.wheelPosition,
      ),
    );

    tyres.value = installedHiveTyres
        .map(
          (h) => TireItem(
        tireId: h.tireId,
        tireSerialNo: h.serialNumber ?? '',
        brandNo: h.brandNo,
        manufacturerName: h.manufacturerName ?? '',
        sizeName: h.tireSizeName ?? '',
        typeName: h.tireTypeName ?? h.typeName ?? '',
        currentHours: h.currentHours ?? 0.0,
        currentMiles: h.currentMiles ?? 0.0,
        currentTreadDepth: h.currentTreadDepth ?? 0.0,
        percentageWorn: 0.0,
        wheelPosition: h.wheelPosition ?? '',
        dispositionName: h.dispositionName ?? '',
        vehicleNumber: '',
        vehicleId: h.vehicleId,
        outsideTread: h.outsideTread,
        middleTread: h.middleTread,
        insideTread: h.insideTread,
        currentPressure: h.currentPressure,
        wearConditionId: h.wearConditionId,
        casingConditionId: h.casingConditionId,
        comments: h.comments,
      ),
    )
        .toList();

  }

  Future<void> loadRecentFromStorage() async {
    try {
      final savedVehiclesStr = await SecureStorage.getVehicle();
      if (savedVehiclesStr != null && savedVehiclesStr.isNotEmpty) {
        final List decoded = jsonDecode(savedVehiclesStr);
        recentVehicles.value = decoded
            .map((e) => VehicleItem.fromJson(e))
            .toList();
      }

      final savedTyresStr = await SecureStorage.getTyre();
      if (savedTyresStr != null && savedTyresStr.isNotEmpty) {
        final List decoded = jsonDecode(savedTyresStr);

        final List<TireItem> totalRecent = decoded
            .map((e) => TireItem.fromJson(e))
            .toList();

        recentTyres.value = totalRecent.where((t) {
          if (t.vehicleId == null || t.vehicleId == 0) return false;

          if (t.tireId != 0) {
            final hive = OfflineHiveService.getTyreById(t.tireId);
            if (hive != null) {
              final hiveVehicleId = hive.vehicleId;
              final hiveDispId = hive.dispositionId ?? 0;
              if ((hiveVehicleId == null || hiveVehicleId == 0) && hiveDispId != 7) {
                return false;
              }
            }
          }

          return true;
        }).toList();

        if (recentTyres.length != totalRecent.length) {
          await _saveRecentTyres();
        }
      }
    } catch (_) {
    }
  }

  Future<void> _saveRecentVehicles() async {
    final list = recentVehicles.map((e) => e.toJson()).toList();
    await SecureStorage.saveVehicle(jsonEncode(list));
  }

  Future<void> _saveRecentTyres() async {
    final list = recentTyres.map((e) => e.toJson()).toList();
    await SecureStorage.saveTyre(jsonEncode(list));
  }

  void switchTab(int index) {
    selectedTab.value = index;
    searchText.value = '';
    updateVisibleList();
  }

  void onSearch(String value) {
    searchText.value = value;
    updateVisibleList();
  }

  void updateVisibleList() {
    final query = searchText.value.toLowerCase().trim();

    if (selectedTab.value == 0) {
      if (query.isEmpty) {
        visibleList.value = List.from(vehicles);
      } else {
        visibleList.value = vehicles.where((v) {
          return (v.vehicleNumber ?? '').toLowerCase().contains(query) ||
              (v.manufacturer ?? '').toLowerCase().contains(query) ||
              (v.typeName ?? '').toLowerCase().contains(query) ||
              (v.modelName ?? '').toLowerCase().contains(query);
        }).toList();
      }
    } else {
      if (query.isEmpty) {
        visibleList.value = List.from(tyres);
      } else {
        visibleList.value = tyres.where((t) {
          final sMatch = (t.tireSerialNo).toLowerCase().contains(query);
          final bMatch = (t.brandNo ?? '').toLowerCase().contains(query);
          return sMatch || bMatch;
        }).toList();
      }
    }

  }

  Future<void> selectItem(dynamic item) async {
    if (item is VehicleItem || (selectedTab.value == 0 && item is! TireItem)) {
      final vehicle = item as VehicleItem;

      if (!recentVehicles.any((e) => e.vehicleId == vehicle.vehicleId)) {
        recentVehicles.add(vehicle);
        _saveRecentVehicles();
      }

      if (!_isNavigating) {
        _isNavigating = true;
        Get.back();

        if (Get.isRegistered<VehicleInspeController>()) {
          Get.delete<VehicleInspeController>(force: true);
        }

        Get.to(
              () => VehicleInspeView(),
          arguments: vehicle.vehicleId,
        )?.then((_) => _isNavigating = false);
      }
    } else {
      final tyre = item as TireItem;

      if (!_isNavigating) {
        _isNavigating = true;

        final freshHiveT = (tyre.tireId != 0)
            ? OfflineHiveService.getTyreById(tyre.tireId)
            : null;

        int resolvedVehicleId =
        (freshHiveT?.vehicleId != null && freshHiveT!.vehicleId! != 0)
            ? freshHiveT.vehicleId!
            : (tyre.vehicleId != null && tyre.vehicleId! != 0)
            ? tyre.vehicleId!
            : 0;

        String resolvedVehicleNumber = tyre.vehicleNumber;

        if (resolvedVehicleNumber.isEmpty && resolvedVehicleId != 0) {
          try {
            final cached = OfflineHiveService.getInspectionCache(
              resolvedVehicleId.toString(),
            );
            if (cached != null) {
              final jsonMap = jsonDecode(cached) as Map<String, dynamic>;
              final model = jsonMap['model'] as Map<String, dynamic>?;
              resolvedVehicleNumber =
                  model?['vehicleNumber']?.toString() ?? '';
            }
          } catch (_) {
          }
        }

        InstalledTire passingData;
        if (freshHiveT != null) {
          passingData = InstalledTire(
            tireId: freshHiveT.tireId,
            tireSerialNo: freshHiveT.serialNumber ?? tyre.tireSerialNo,
            wheelPosition: freshHiveT.wheelPosition ?? tyre.wheelPosition,
            currentHours: freshHiveT.currentHours ?? tyre.currentHours,
            currentMiles: freshHiveT.currentMiles ?? tyre.currentMiles,
            currentTreadDepth:
            freshHiveT.currentTreadDepth ?? tyre.currentTreadDepth,
            percentageWorn: tyre.percentageWorn,
            vehicleId: resolvedVehicleId,
            vehicleNumber: resolvedVehicleNumber,
            brandNo: tyre.brandNo,
            inspectionDate: tyre.inspectionDate,
            outsideTread: freshHiveT.outsideTread ?? tyre.outsideTread ?? 0.0,
            middleTread: freshHiveT.middleTread ?? tyre.middleTread ?? 0.0,
            insideTread: freshHiveT.insideTread ?? tyre.insideTread ?? 0.0,
            currentPressure:
            freshHiveT.currentPressure ?? tyre.currentPressure ?? 0.0,
            originalTread:
            freshHiveT.originalTread ?? tyre.originalTread ?? 0.0,
            removeAt: freshHiveT.removeAt ?? tyre.removeAt ?? 0.0,
            wearConditionId:
            freshHiveT.wearConditionId ?? tyre.wearConditionId,
            casingConditionId:
            freshHiveT.casingConditionId ?? tyre.casingConditionId,
            comments: freshHiveT.comments ?? tyre.comments,
            isFromSearch: true,
          );
        } else {
          passingData = InstalledTire(
            tireId: tyre.tireId,
            tireSerialNo: tyre.tireSerialNo,
            wheelPosition: tyre.wheelPosition,
            currentHours: tyre.currentHours,
            currentMiles: tyre.currentMiles,
            currentTreadDepth: tyre.currentTreadDepth,
            percentageWorn: tyre.percentageWorn,
            vehicleId: resolvedVehicleId,
            vehicleNumber: resolvedVehicleNumber,
            brandNo: tyre.brandNo,
            inspectionDate: tyre.inspectionDate,
            outsideTread: tyre.outsideTread ?? 0.0,
            middleTread: tyre.middleTread ?? 0.0,
            insideTread: tyre.insideTread ?? 0.0,
            currentPressure: tyre.currentPressure ?? 0.0,
            originalTread: tyre.originalTread ?? 0.0,
            removeAt: tyre.removeAt ?? 0.0,
            wearConditionId: tyre.wearConditionId,
            casingConditionId: tyre.casingConditionId,
            comments: tyre.comments,
            isFromSearch: true,
          );
        }

        final tireToSave = freshHiveT != null
            ? TireItem(
          tireId: freshHiveT.tireId,
          tireSerialNo: freshHiveT.serialNumber ?? tyre.tireSerialNo,
          brandNo: freshHiveT.brandNo ?? tyre.brandNo,
          manufacturerName: tyre.manufacturerName,
          sizeName: tyre.sizeName,
          typeName: tyre.typeName,
          currentHours: freshHiveT.currentHours ?? tyre.currentHours,
          currentMiles: freshHiveT.currentMiles ?? tyre.currentMiles,
          currentTreadDepth:
          freshHiveT.currentTreadDepth ?? tyre.currentTreadDepth,
          percentageWorn: tyre.percentageWorn,
          wheelPosition: freshHiveT.wheelPosition ?? tyre.wheelPosition,
          dispositionName: tyre.dispositionName,
          vehicleNumber: resolvedVehicleNumber,
          vehicleId: resolvedVehicleId,
          outsideTread: freshHiveT.outsideTread ?? tyre.outsideTread,
          middleTread: freshHiveT.middleTread ?? tyre.middleTread,
          insideTread: freshHiveT.insideTread ?? tyre.insideTread,
          currentPressure:
          freshHiveT.currentPressure ?? tyre.currentPressure,
          originalTread: freshHiveT.originalTread ?? tyre.originalTread,
          removeAt: freshHiveT.removeAt ?? tyre.removeAt,
          wearConditionId:
          freshHiveT.wearConditionId ?? tyre.wearConditionId,
          casingConditionId:
          freshHiveT.casingConditionId ?? tyre.casingConditionId,
          comments: freshHiveT.comments ?? tyre.comments,
          inspectionDate: tyre.inspectionDate,
        )
            : tyre;

        if (!recentTyres.any((e) => e.tireId == tyre.tireId)) {
          recentTyres.add(tireToSave);
          _saveRecentTyres();
        }
        if (Get.isRegistered<InspectTyreController>()) {
          Get.delete<InspectTyreController>(force: true);
        }

        Get.back();
        Get.to(() => InspectTyreView(tire: passingData), arguments: passingData)?.then((_) {
          _isNavigating = false;
          loadData();
        });
      }
    }
  }

  void removeRecentVehicle(VehicleItem item) {
    recentVehicles.removeWhere((e) => e.vehicleId == item.vehicleId);
    _saveRecentVehicles();
  }

  void removeRecentTyre(TireItem item) {
    recentTyres.removeWhere((e) => e.tireId == item.tireId);
    _saveRecentTyres();
  }

  void clearSearch() {
    searchText.value = '';
    updateVisibleList();
  }
}