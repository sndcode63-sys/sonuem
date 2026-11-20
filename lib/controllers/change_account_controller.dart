import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emtrack/controllers/home_controller.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:emtrack/utils/hive_prefe.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/change_account_model.dart';
import '../services/change_account_service.dart';

class ChangeAccountController extends GetxController {
  final service = ChangeAccountService();

  RxBool ownSelected = false.obs;
  RxBool sharedSelected = false.obs;
  RxBool isLoading = false.obs;
  RxBool isOffline = false.obs;

  RxString accountSearchQuery = ''.obs;
  RxString locationSearchQuery = ''.obs;

  RxnString accountType = RxnString();
  Rx<ParentAccountModel?> selectedAccount = Rx<ParentAccountModel?>(null);

  // ✅ Multi-select: ab ek se zyada locations select ho sakte hain.
  RxList<LocationModel> selectedLocations = <LocationModel>[].obs;

  RxList<ParentAccountModel> accounts = <ParentAccountModel>[].obs;
  RxList<LocationModel> locations = <LocationModel>[].obs;

  bool get isAllLocationsSelected =>
      locations.isNotEmpty && selectedLocations.length == locations.length;

  bool isLocationSelected(LocationModel loc) =>
      selectedLocations.any((e) => e.locationId == loc.locationId);

  void toggleLocation(LocationModel loc) {
    if (isLocationSelected(loc)) {
      selectedLocations.removeWhere((e) => e.locationId == loc.locationId);
    } else {
      selectedLocations.add(loc);
    }
  }

  void toggleSelectAllLocations() {
    if (isAllLocationsSelected) {
      selectedLocations.clear();
    } else {
      selectedLocations.value = List<LocationModel>.from(locations);
    }
  }



  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await _checkConnectivity();
    await _restoreRadio();
    await loadParentAccounts();
    await _restoreParentAndLocation();
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    isOffline.value = results.every((r) => r == ConnectivityResult.none);
    if (isOffline.value) {}
  }

  Future<void> _restoreRadio() async {
    final own = await SecureStorage.getBool('own_selected');
    final shared = await SecureStorage.getBool('shared_selected');
    ownSelected.value = own ?? false;
    sharedSelected.value = shared ?? false;
  }

  Future<void> loadParentAccounts() async {
    try {
      isLoading.value = true;
      accounts.value = await service.fetchParentAccounts();

      if (accounts.isEmpty && isOffline.value) {}
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _restoreParentAndLocation() async {
    final savedParentId = await SecureStorage.getParentAccountId();
    if (savedParentId != null &&
        savedParentId.isNotEmpty &&
        accounts.isNotEmpty) {
      final parent = accounts.firstWhereOrNull(
            (e) => e.parentAccountId.toString() == savedParentId,
      );
      if (parent != null) {
        selectedAccount.value = parent;
        await loadLocations(parent.parentAccountId);
      }
    }

    // ✅ Multi-select restore: purane saved location IDs (comma-joined)
    // se match karke locations list mein se sahi items select kar do.
    final savedLocationIds = SecureStorage.getSelectedLocationIds();
    if (savedLocationIds.isNotEmpty && locations.isNotEmpty) {
      selectedLocations.value = locations
          .where((e) => savedLocationIds.contains(e.locationId.toString()))
          .toList();
    }
  }

  Future<void> loadLocations(int parentAccountId) async {
    locations.clear();
    selectedLocations.clear();
    locations.value = await service.fetchLocations(parentAccountId);
  }

  void onAccountChanged(ParentAccountModel? account) async {
    selectedAccount.value = account;
    if (account != null) {
      selectedLocations.clear();
      locations.clear();
      await loadLocations(account.parentAccountId);
    }
  }

  Future<void> submit() async {
    if (isLoading.value) return;
    if (selectedAccount.value == null || selectedLocations.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select account and at least one location',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    try {
      final newAccountId = selectedAccount.value!.parentAccountId.toString();
      final newAccountName = selectedAccount.value!.accountName;

      // ✅ "Primary" location = pehla selected location. CRUD flows
      // (create/edit tyre, vehicle inspection, etc. — poore app mein
      // 20+ files) ab bhi ek hi active location par depend karte hain,
      // isliye unke liye yehi primary location save hoga. Baaki saare
      // selected locations sirf Home dashboard ke combined view ke liye
      // alag se save honge (neeche saveSelectedLocations).
      final primaryLocation = selectedLocations.first;
      final newLocationId = primaryLocation.locationId.toString();
      final newLocationName = primaryLocation.locationName;

      final allLocationIds =
      selectedLocations.map((e) => e.locationId.toString()).toList();
      final allLocationNames =
      selectedLocations.map((e) => e.locationName).toList();

      String newCurrency = primaryLocation.currency ?? '';
      if (newCurrency.isEmpty && !isOffline.value) {
        // Offline mein currency fetch skip karo
        final fetched = await service.fetchLocationCurrency(
          primaryLocation.locationId,
        );
        newCurrency = fetched ?? '';
      }

      // ✅ noOfTreadDepthReadings update karo naye (primary) location ke liye
      // ⚠️ FIX: unawaited hataya — pehle save hona chahiye submit se pehle
      if (!isOffline.value) {
        await service.fetchAndSaveNoOfTreadDepthReadings(
          primaryLocation.locationId,
        );
      }

      final username = await SecureStorage.getUserName() ?? '';
      // ✅ FIX: getUserProfileName() = display name ("John Smith") — server ye nahi
      //    jaanta. Server ko login username chahiye jo getUserName() deta hai.
      final userId = username; // = login username e.g. "john@company.com"

      // ✅ Server ko properly confirm karo — fire-and-forget nahi.
      //    Offline ya fail hone par pending flag set karo taaki
      //    AppRefreshService background mein retry kar sake.
      bool pushedToWeb = false;
      if (!isOffline.value) {
        pushedToWeb = await service.postAccountLocationChange(
          parentAccountId: newAccountId,
          locationId: newLocationId,
          userId: userId,
        );
      }

      if (!pushedToWeb) {
        HivePref.set('pending_account_location_push', {
          'parentAccountId': newAccountId,
          'locationId': newLocationId,
          'userId': userId,
        });
      } else {
        HivePref.set('pending_account_location_push', null);
      }

      await Future.wait([
        SecureStorage.saveParentAccount(id: newAccountId, name: newAccountName),
        SecureStorage.saveLocation(id: newLocationId, name: newLocationName),
        SecureStorage.saveSelectedLocations(
          ids: allLocationIds,
          names: allLocationNames,
        ),

        if (username.isNotEmpty)
          SecureStorage.saveLocationForUser(
            username: username,
            id: newLocationId,
            name: newLocationName,
          ),

        if (username.isNotEmpty)
          SecureStorage.saveParentAccountForUser(
            username: username,
            id: newAccountId,
            name: newAccountName,
          ),

        SecureStorage.saveBool('own_selected', ownSelected.value),
        SecureStorage.saveBool('shared_selected', sharedSelected.value),
        if (newCurrency.isNotEmpty) SecureStorage.saveCurrency(newCurrency),
      ]);

      if (Get.isRegistered<HomeController>()) {
        final home = Get.find<HomeController>();
        home.selectedParentAccountName.value = newAccountName;
        home.selectedLocationName.value = newLocationName;

        home.refreshForNewAccount(
          newAccountId: newAccountId,
          newLocationId: newLocationId,
          newAccountName: newAccountName,
          newLocationName: newLocationName,
          newLocationIds: allLocationIds,
          newLocationNames: allLocationNames,
        );
      }

      isLoading.value = false;
      Get.back(result: true);
    } catch (e) {
      Get.snackbar('Error', 'Failed: $e', backgroundColor: Colors.red);
      isLoading.value = false;
    }
  }
}