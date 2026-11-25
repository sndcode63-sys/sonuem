import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emtrack/inspection/vehicle_inspe_service.dart';
import 'package:emtrack/services/all_vehicles_services.dart';
import 'package:emtrack/services/tyre_view_service.dart';
import 'package:emtrack/services/update_vehicle_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/all_vehicle_account_model.dart';
import '../services/offline_hive_service.dart';
import '../utils/network_helper.dart';

class AllVehicleController extends GetxController {
  final AllVehicleService _service = AllVehicleService();

  final RxList<AccountVehicleModel> vehicleList = <AccountVehicleModel>[].obs;
  final RxList<AccountVehicleModel> filteredList = <AccountVehicleModel>[].obs;
  final TextEditingController searchController = TextEditingController();
  AppLocalizations get l10n => AppLocalizations.of(Get.context!);

  // Bool Controller
  final RxBool isFilterApplied = false.obs;
  final RxBool isLoading = true.obs;
  final RxBool isOffline = false.obs;

  // Text Editor controller
  final RxString selectedType = ''.obs;
  final RxString selectedMake = ''.obs;
  final RxString selectedModel = ''.obs;
  final RxString searchText = ''.obs;

// List
  final RxList<String> typeList = <String>[].obs;
  final RxList<String> makeList = <String>[].obs;
  final RxList<String> modelList = <String>[].obs;

  StreamSubscription? _connectivitySub;

// onInt
  @override
  void onInit() {
    super.onInit();
    loadVehicles();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online && isOffline.value) {
        loadVehicles();
      }
    });
  }

  // refresh flitter list
  void _refreshFilterLists() {
    typeList.assignAll(
      vehicleList
          .map((e) => e.typeName ?? '')
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList()
        ..sort(),
    );
    makeList.assignAll(
      vehicleList
          .map((e) => e.manufacturerName ?? '')
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList()
        ..sort(),
    );
    modelList.assignAll(
      vehicleList
          .map((e) => e.modelName ?? '')
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList()
        ..sort(),
    );
  }

  List<AccountVehicleModel> _convertHiveList(List<dynamic> cached) {
    return cached
        .map(
          (h) => AccountVehicleModel(
        vehicleId: h.vehicleId,
        vehicleNumber: h.vehicleNumber,
        typeName: h.typeName,
        modelName: h.modelName,
        axleConfig: h.axleConfig,
        manufacturerName: h.manufacturerName,
        tireCount: h.tireCount,
        locationId: h.locationId,
        assetNumber: null,
        currentHours: null,
        currentMiles: null,
        lastRead: null,
        isPendingSync: h.isPendingSync,
      ),
    )
        .toList();
  }

  Future<void> loadVehicles({bool showSnackbarOnError = false}) async {
    searchController.clear();
    searchText.value = '';

    try {
      final String? storedParentId = await SecureStorage.getParentAccountId();
      if (storedParentId == null || storedParentId.isEmpty || storedParentId == '0') {
        isLoading.value = false;
        if (showSnackbarOnError) {
          Get.snackbar('Error', 'Parent Account not selected');
        }
        return;
      }
      final int? parentId = int.tryParse(storedParentId);
      if (parentId == null) {
        isLoading.value = false;
        if (showSnackbarOnError) {
          Get.snackbar('Error', 'Invalid Parent Account ID');
        }
        return;
      }

      // ✅ Multi-location: pehle sirf ek locationId se filter hota tha,
      // ab Change Account screen se jitni bhi locations select ki gayi
      // hain unn sabka vehicle list mein data dikhega. Koi selection
      // saved na ho (purana session) to sab locations dikhengi (jaisa
      // pehle "0"/empty case mein hota tha).
      final selectedLocationIds = SecureStorage.getSelectedLocationIds()
          .map((e) => int.tryParse(e))
          .whereType<int>()
          .where((id) => id > 0)
          .toSet();
      final bool hasLocationFilter = selectedLocationIds.isNotEmpty;

      // ✅ STEP 1 — CACHE-FIRST: agar Hive me pehle se data hai (previous
      // visit se), usse TURANT dikhado — koi spinner/loader ka wait
      // nahi. Isse click karte hi list dikhti hai, network response
      // aane tak rukna nahi padta.
      final cachedNow = OfflineHiveService.getVehicles(
        parentAccountId: parentId,
      );
      if (cachedNow.isNotEmpty) {
        final convertedNow = _convertHiveList(cachedNow);
        final filteredCachedNow = hasLocationFilter
            ? convertedNow
            .where((v) => selectedLocationIds.contains(v.locationId))
            .toList()
            : convertedNow;

        vehicleList.assignAll(filteredCachedNow);
        _refreshFilterLists();
        filteredList.assignAll(filteredCachedNow);
        isLoading.value = false; // data already on screen, no loader needed
      }

      // ✅ STEP 2 — BACKGROUND REFRESH: network se fresh data silently
      // fetch hota hai. Agar cache already dikha diya tha (upar), yaha
      // isLoading ko dobara true NAHI karte — warna list flicker karke
      // wapas loader dikha degi. Sirf jab bilkul pehli baar khul rahi ho
      // (koi cache nahi) tabhi loader dikhega.
      final online = await NetworkHelper.hasInternet();

      if (online) {
        isOffline.value = false;
        final data = await _service.getVehiclesByAccount(
          parentAccountId: parentId,
        );

        await OfflineHiveService.saveVehicles(
          data.map((v) => v.toJson()..['parentAccountId'] = parentId).toList(),
        );

        final allVehiclesFromHive = OfflineHiveService.getVehicles(parentAccountId: parentId);
        final converted = _convertHiveList(allVehiclesFromHive);
        final filtered = hasLocationFilter
            ? converted.where((v) => selectedLocationIds.contains(v.locationId)).toList()
            : converted;

        vehicleList.assignAll(filtered);
        _refreshFilterLists();

        _preCacheAllVehicles(data);
      } else {
        isOffline.value = true;
        if (cachedNow.isEmpty) {
          // koi cache bhi nahi tha aur offline bhi hai -> khaali hi rahega
          vehicleList.assignAll([]);
        }
      }

      if (searchText.value.isNotEmpty) {
        onSearch(searchText.value);
      } else if (isFilterApplied.value) {
        applyFilter();
      } else {
        filteredList.assignAll(vehicleList);
      }
    } catch (e) {
      await _loadFromHiveFallback();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadFromHiveFallback() async {
    try {
      final String? storedParentId = await SecureStorage.getParentAccountId();
      if (storedParentId == null) return;
      final int? parentId = int.tryParse(storedParentId);
      if (parentId == null) return;

      final cached = OfflineHiveService.getVehicles(parentAccountId: parentId);
      if (cached.isNotEmpty) {
        final selectedLocationIds = SecureStorage.getSelectedLocationIds()
            .map((e) => int.tryParse(e))
            .whereType<int>()
            .where((id) => id > 0)
            .toSet();

        final converted = cached
            .map(
              (h) => AccountVehicleModel(
            vehicleId: h.vehicleId,
            vehicleNumber: h.vehicleNumber,
            typeName: h.typeName,
            modelName: h.modelName,
            axleConfig: h.axleConfig,
            manufacturerName: h.manufacturerName,
            tireCount: h.tireCount,
            locationId: h.locationId,
            assetNumber: null,
            currentHours: null,
            currentMiles: null,
            lastRead: null,
            isPendingSync: h.isPendingSync,
          ),
        )
            .where((v) => (v.vehicleId ?? 0) > 0)
            .where(
              (v) =>
          selectedLocationIds.isEmpty ||
              selectedLocationIds.contains(v.locationId),
        )
            .toList();
        vehicleList.assignAll(converted);
        filteredList.assignAll(converted);
        _refreshFilterLists();
        isOffline.value = true;
      } else {
        Get.snackbar(
          'Error',
          'Failed to load vehicles. Check your connection.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (_) {}
  }

  Future<void> refreshVehicles() async => await loadVehicles(showSnackbarOnError: true);

  Future<void> _preCacheAllVehicles(List<AccountVehicleModel> vehicles) async {
    final inspeService = VehicleInspeService();
    final vehicleService = UpdateVehicleService();
    final tyreViewService = TyreViewService();
    final prefs = await SharedPreferences.getInstance();

    for (final v in vehicles) {
      if (v.vehicleId == null) continue;
      try {
        final protectedKey = 'cache_protected_${v.vehicleId}';
        final protectedAt = prefs.getInt(protectedKey);
        if (protectedAt != null) {
          final diff = DateTime.now().millisecondsSinceEpoch - protectedAt;
          if (diff < 300000) {
            await Future.delayed(const Duration(milliseconds: 300));
            continue;
          } else {
            await prefs.remove(protectedKey);
          }
        }

        if (!OfflineHiveService.hasInspectionCache(v.vehicleId.toString())) {
          await inspeService.getInspectionRecord(v.vehicleId.toString());
        }
        if (!OfflineHiveService.hasVehicleDetailCache(v.vehicleId!)) {
          await vehicleService.getVehicleById(v.vehicleId!);
        }
        final vehicleTyres = OfflineHiveService.getTyresByVehicle(v.vehicleId!);
        for (final t in vehicleTyres) {
          if (t.tireId <= 0) continue;
          if (!OfflineHiveService.hasTireDetailCache(t.tireId)) {
            await tyreViewService.fetchTyreDetailsById(t.tireId);
            await Future.delayed(const Duration(milliseconds: 200));
          }
        }
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {}
    }
  }

  void onSearch(String value) {
    searchText.value = value.toLowerCase();
    isFilterApplied.value = value.isNotEmpty;
    filteredList.assignAll(
      vehicleList.where((v) {
        return v.vehicleId.toString().contains(searchText.value) ||
            (v.vehicleNumber ?? '').toLowerCase().contains(searchText.value) ||
            (v.manufacturerName ?? '').toLowerCase().contains(
              searchText.value,
            ) ||
            (v.modelName ?? '').toLowerCase().contains(searchText.value) ||
            (v.axleConfig ?? '').toLowerCase().contains(searchText.value) ||
            (v.typeName ?? '').toLowerCase().contains(searchText.value);
      }).toList(),
    );
  }

  void applyFilter() {
    isFilterApplied.value = true;
    filteredList.assignAll(
      vehicleList.where((v) {
        final typeMatch =
            selectedType.value.isEmpty ||
                (v.typeName ?? '') == selectedType.value;
        final makeMatch =
            selectedMake.value.isEmpty ||
                (v.manufacturerName ?? '') == selectedMake.value;
        final modelMatch =
            selectedModel.value.isEmpty ||
                (v.modelName ?? '') == selectedModel.value;
        return typeMatch && makeMatch && modelMatch;
      }).toList(),
    );
  }

  void clearFilter() {
    selectedType.value = '';
    selectedMake.value = '';
    selectedModel.value = '';
    isFilterApplied.value = false;
    filteredList.assignAll(vehicleList);
  }

  @override
  void onClose() {
    _connectivitySub?.cancel();
    super.onClose();
  }
}