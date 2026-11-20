import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:emtrack/utils/app_refersh_service.dart';
import 'package:emtrack/inspection/vehicle_inspe_service.dart';
import 'package:emtrack/services/all_vehicles_services.dart';
import 'package:emtrack/services/tyre_view_service.dart';
import 'package:emtrack/services/update_vehicle_service.dart';
import 'package:get/get.dart';
import '../models/home_model.dart';
import '../models/statical_model.dart';
import '../services/home_service.dart';
import '../services/master_data_service.dart';
import '../services/offline_hive_service.dart';
import '../utils/secure_storage.dart';
import 'inspection_controller.dart';
import '../services/inspection_service.dart';
// 🔧 NEW: pending-inspections API (same one IWSearchScreen uses) so Home
// can show the exact same Vehicle/Tire pending inspection counts.
import '../inspection_approval/search.dart';
import '../routes/app_pages.dart';
import 'download_controller.dart';

class HomeController extends GetxController {
  var isLoading = false.obs;
  var isSyncing = false.obs;
  var username = ''.obs;
  RxBool isCreateOpen = false.obs;
  RxBool isUserMenuOpen = false.obs;
  RxBool isGrandparentMenuOpen = false.obs;
  RxBool isUserOpen = false.obs;

  var homeCount = Rxn<DashboardModel>();
  RxInt tyreCount = (SecureStorage.getLastTyreCount() ?? 0).obs;
  RxInt vehicleCount = (SecureStorage.getLastVehicleCount() ?? 0).obs;
  var homeData = Rxn<HomeModel>();

  RxString selectedParentAccountName = ''.obs;
  RxString selectedLocationName = ''.obs;
  RxList<String> selectedLocationIds = <String>[].obs;
  RxList<String> selectedLocationNames = <String>[].obs;

  RxInt pendingCount = 0.obs;

  // ✅ NEW: koi bhi error jo count-refresh ke dauran aaya (e.g. account
  // switch ke baad naye location ka data load karte waqt). Home screen
  // isse read karke error message dikha sakta hai jab loader hat jaye.
  RxnString accountSwitchError = RxnString();

  // Inspection count cards
  RxInt unsyncedInspectionCount = 0.obs;
  RxInt syncedInspectionCount = 0.obs;
  final RxInt vehicleInspectionCount = 0.obs;
  final RxInt tireInspectionCount = 0.obs;

  // Last inspection date
  RxString lastInspectionDate = ''.obs;

  String get role => homeData.value?.role ?? '';
  String get parentAccount => homeData.value?.parentAccount ?? '';
  String get location => homeData.value?.location ?? '';
  String get imageUrl => homeData.value?.imageUrl ?? '';
  int get totalTyres => homeData.value?.totalTyres ?? 0;
  int get vehicles => homeData.value?.vehicles ?? 0;
  int get unsynced => homeData.value?.unsyncedInspections ?? 0;
  int get synced => homeData.value?.syncedInspections ?? 0;
  String get lastInspection => lastInspectionDate.value.isNotEmpty
      ? lastInspectionDate.value
      : (homeData.value?.lastInspection ?? '—');
  String get appVersion => homeData.value?.appVersion ?? '1.0';

  void updateInspectionCounts({required int unsynced, required int synced}) {
    unsyncedInspectionCount.value = unsynced;
    syncedInspectionCount.value = synced;

    if (homeData.value != null) {
      homeData.value = homeData.value!.copyWith(
        unsyncedInspections: unsynced,
        syncedInspections: synced,
      );
      homeData.refresh();
    }
  }

  void openCreateMenu() {
    isCreateOpen.value = true;
    isUserOpen.value = false;
  }

  void closeCreateMenu() => isCreateOpen.value = false;

  void openUserMenu() {
    isUserOpen.value = true;
    isCreateOpen.value = false;
  }

  void closeUserMenu() => isUserOpen.value = false;

  @override
  void onInit() {
    super.onInit();
    _initHome();
  }

  @override
  void onReady() {
    super.onReady();
    _checkDailySyncRequirement();
  }

  Future<void> _checkDailySyncRequirement() async {
    try {
      final isExpired = await SecureStorage.isFullDownloadExpired();
      if (isExpired) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showMandatoryDailySyncDialog();
        });
      }
    } catch (_) {}
  }

  void _showMandatoryDailySyncDialog() {
    if (Get.isDialogOpen == true) return;

    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(60),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sync_problem_rounded,
                    color: Colors.redAccent,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Data Sync Required",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  "It has been 1 day since your last data download. A complete download is required to continue using the application with updated vehicles and tyres.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      if (Get.isRegistered<DownloadController>()) {
                        Get.delete<DownloadController>();
                      }
                      Get.offAllNamed(
                        AppPages.DOWNLOAD,
                        arguments: {'force': true},
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _initHome() async {
    AppRefreshService.init();
    await _loadFromSecureStorage();
    _refreshInspectionCounts();
    _refreshInspectionApprovalCounts(); // 🔧 NEW
    await _backgroundRefresh();
    AppRefreshService.triggerNow(reason: 'home_init');
  }

  int _getPendingOfflineTyreCount() {
    try {
      return OfflineHiveService.getAllPendingOps()
          .where(
            (op) =>
        !op.isSynced &&
            (op.opType == 'createTyre' ||
                op.opType == 'addTyre' ||
                op.opType == 'submitTyre'),
      )
          .length;
    } catch (e) {
      return 0;
    }
  }

  int _getPendingOfflineVehicleCount() {
    try {
      return OfflineHiveService.getAllPendingOps()
          .where(
            (op) =>
        !op.isSynced &&
            (op.opType == 'createVehicle' ||
                op.opType == 'addVehicle' ||
                op.opType == 'submitVehicle'),
      )
          .length;
    } catch (e) {
      return 0;
    }
  }

  final InspectionService _inspectionService = InspectionService();

  // 🔧 NEW: same SearchApi jo IWSearchController use karta hai, taaki
  // Home ke "Vehicle Inspection" / "Tire Inspection" cards bilkul wahi
  // count dikhayein jo IWSearchScreen ke Vehicles/Tyres tab me pending
  // items ke roop me dikhte hain.
  final SearchApi _searchApi = SearchApi();

  Future<void> _refreshInspectionCounts() async {
    try {
      final unsynced = await _inspectionService.getUnsyncedInspections();
      final synced = await _inspectionService.getSyncedInspections();

      unsyncedInspectionCount.value = unsynced.length;
      syncedInspectionCount.value = synced.length;

      if (homeData.value != null) {
        homeData.value = homeData.value!.copyWith(
          unsyncedInspections: unsyncedInspectionCount.value,
          syncedInspections: syncedInspectionCount.value,
        );
      }
      homeData.refresh();
    } catch (_) {}
  }

  /// 🔧 NEW: Fetches /api/Inspection/GetAllPendingInspections/{AccountId}
  /// (same endpoint & same dedup rules as IWSearchController._loadData)
  /// and derives unique pending Vehicle / Tire counts for the Home
  /// dashboard cards ("Vehicle Inspection" / "Tire Inspection").
  ///
  /// Dedup rule matches IWSearchController exactly:
  /// - Vehicles: keyed by vehicleId -> same vehicle shown once even if it
  ///   has multiple pending tyres/events.
  /// - Tyres: every pending tyre counted (keyed by tireId so duplicates
  ///   collapse but distinct tyres on the same vehicle all count).
  /// 🔧 UPDATED: counts actual pending INSPECTION rows/entries (each one
  /// carrying its own unique InspectionStatusId) — the exact same items the
  /// "Vehicle Inspection" / "Tire Inspection" list screens show as separate
  /// cards — instead of deduping down to unique vehicleId/tireId. A vehicle
  /// or tyre with multiple separate pending submissions now counts once per
  /// submission (matching what the person actually sees after tapping
  /// "view"), not once per vehicle/tyre.
  Future<void> _refreshInspectionApprovalCounts() async {
    try {
      final int? profileAccountId =
      await SecureStorage.getProfileParentAccountId();
      final int? accountId = profileAccountId ??
          int.tryParse(await SecureStorage.getParentAccountId() ?? '');
      if (accountId == null) return;

      final results = await Connectivity().checkConnectivity();
      final online = results.any((r) => r != ConnectivityResult.none);
      if (!online) return; // offline -> keep whatever count we already have

      final pending = await _searchApi.fetchPendingInspections(accountId);

      int vehicleInspectionEntries = 0;
      int tireInspectionEntries = 0;

      for (final p in pending) {
        if (p.vehicle?.vehicleId != null) {
          vehicleInspectionEntries++;
        }

        // 🔧 DUPLICATE FIX: PendingInspectionEntry.fromModelJson `tire` ko
        // `tiresList.first` se set karta hai, yaani pehla tyre `p.tire` aur
        // `p.tiresList` DONO me hota hai. Pehle yahan `[p.tire, ...tiresList]`
        // ki length direct count hoti thi, isliye har entry ka pehla tyre 2
        // baar gina jaata tha (3 tyres -> 4 count). Ab search screen
        // (inspection_approval/search.dart) jaisa hi dedup + null-tireId skip.
        final Set<String> seenTireKeysInEntry = {};
        for (final cand in <PendingInspectionTire>[
          if (p.tire != null) p.tire!,
          ...p.tiresList,
        ]) {
          if (cand.tireId == null) continue; // search screen bhi skip karta hai
          final String dedupeKey = cand.tireId != 0
              ? 'id_${cand.tireId}'
              : 'sn_${(cand.tireSerialNo ?? '').trim().toUpperCase()}_${(cand.wheelPosition ?? '').trim().toUpperCase()}';
          if (seenTireKeysInEntry.add(dedupeKey)) {
            tireInspectionEntries++;
          }
        }
      }

      // 🚚 Include local draft vehicles awaiting approval
      try {
        final prefs = await SharedPreferences.getInstance();
        final drafts = OfflineHiveService.getDraftVehiclesAwaitingApproval(prefs);
        vehicleInspectionEntries += drafts.where((hv) => hv.vehicleId < 0).length;
      } catch (_) {}

      vehicleInspectionCount.value = vehicleInspectionEntries;
      tireInspectionCount.value = tireInspectionEntries;

      debugPrint(
          '[HOME_CONTROLLER] 🔢 Pending approval counts -> '
              'vehicles: ${vehicleInspectionCount.value}, '
              'tyres: ${tireInspectionCount.value}');
    } catch (e) {
      debugPrint('[HOME_CONTROLLER] ⚠️ _refreshInspectionApprovalCounts failed -> $e');
      // Fail ho jaye to purana count hi rehne do, UI ko galat 0 na dikhe.
    }
  }

  void refreshCounts() {
    loadTyreCountByAccount();
    loadVehicleCountByAccount();
    _refreshLastInspectionDate();

    _refreshInspectionCounts();
    _refreshInspectionApprovalCounts(); // 🔧 NEW
  }

  Future<void> refreshCountsFromHive() async {
    loadTyreCountByAccount();
    loadVehicleCountByAccount();
    await _refreshInspectionCounts();
    await _refreshInspectionApprovalCounts(); // 🔧 NEW
    _refreshLastInspectionDate();
  }

  Future<void> _refreshLastInspectionDate() async {
    final saved = await SecureStorage.getLastInspectionDate();
    if (saved != null && saved.isNotEmpty) {
      lastInspectionDate.value = saved;
      final cur = homeData.value;
      if (cur != null) {
        homeData.value = HomeModel(
          username: cur.username,
          parentAccount: cur.parentAccount,
          location: cur.location,
          role: cur.role,
          lastInspection: saved,
          unsyncedInspections: unsyncedInspectionCount.value,
          syncedInspections: syncedInspectionCount.value,
          totalTyres: tyreCount.value,
          vehicles: vehicleCount.value,
          appVersion: cur.appVersion,
          imageUrl: cur.imageUrl,
        );
      }
    }
  }

  Future<void> _loadFromSecureStorage() async {
    await SecureStorage.loadAll();

    final name = await SecureStorage.getUserProfileName();
    final parentName = await SecureStorage.getParentAccountName();
    final locationName = await SecureStorage.getLocationName();
    final role = await SecureStorage.getUserProfileRole() ?? '';
    final lastInspe = await SecureStorage.getLastInspectionDate();

    debugPrint(
        '[HOME_CONTROLLER] 👤 Loaded from secure storage -> user: $name | '
            'role: $role | parentAccount: $parentName | location: $locationName');

    if (name != null && name.isNotEmpty) username.value = name;
    selectedParentAccountName.value = parentName ?? 'Select Account';
    selectedLocationName.value = locationName ?? 'Select Location';

    selectedLocationIds.value = SecureStorage.getSelectedLocationIds();
    selectedLocationNames.value = SecureStorage.getSelectedLocationNames();

    debugPrint(
        '[HOME_CONTROLLER] ✅ Active account/location set -> '
            'account: ${selectedParentAccountName.value} | '
            'location: ${selectedLocationName.value}');

    if (lastInspe != null && lastInspe.isNotEmpty) {
      lastInspectionDate.value = lastInspe;
    }

    final cachedVehicle = SecureStorage.getLastVehicleCount() ?? 0;
    final cachedTyre = SecureStorage.getLastTyreCount() ?? 0;

    vehicleCount.value = cachedVehicle + _getPendingOfflineVehicleCount();
    tyreCount.value = cachedTyre + _getPendingOfflineTyreCount();

    homeData.value = HomeModel(
      username: name ?? 'User',
      parentAccount: selectedParentAccountName.value,
      location: selectedLocationName.value,
      role: role,
      lastInspection: lastInspe ?? '--',
      unsyncedInspections: unsyncedInspectionCount.value,
      syncedInspections: syncedInspectionCount.value,
      totalTyres: tyreCount.value,
      vehicles: vehicleCount.value,
      appVersion: '1.0',
      imageUrl: '',
    );
    homeData.refresh();
  }

  Future<void> _backgroundRefresh() async {
    try {
      final cookie = await SecureStorage.getCookie();
      if (cookie == null || cookie.isEmpty) return;

      final results = await Future.wait([
        HomeService.fetchHomeData(),
        HomeService.fetchReportDashboardHomeData(),
      ]);

      final dash = results[1] as DashboardModel?;
      if (dash != null) {
        homeCount.value = dash;
        final baseVehicle = dash.vehicleCount ?? 0;
        final baseTyre = dash.totalTiresCount ?? 0;

        await SecureStorage.saveDashboardCounts(
          vehicleCount: baseVehicle,
          tyreCount: baseTyre,
        );

        vehicleCount.value = baseVehicle + _getPendingOfflineVehicleCount();
        tyreCount.value = baseTyre + _getPendingOfflineTyreCount();
        _updateHomeDataCounts();
      }

      await _refreshLastInspectionDate();

      MasterDataService()
          .fetchMasterData(forceRefresh: true)
          .catchError((_) => <String, dynamic>{});
      _silentFullPreCache().catchError((_) {});
    } catch (_) {}
  }

  static bool _isCaching = false;

  Future<void> _silentFullPreCache() async {
    if (_isCaching) return;
    _isCaching = true;
    try {
      final results = await Connectivity().checkConnectivity();
      final online = results.any((r) => r != ConnectivityResult.none);
      if (!online) return;

      final parentIdStr = await SecureStorage.getParentAccountId();
      if (parentIdStr == null || parentIdStr.isEmpty || parentIdStr == '0') {
        return;
      }
      final parentId = int.tryParse(parentIdStr);
      if (parentId == null) return;

      final inspeService = VehicleInspeService();
      final vehicleService = UpdateVehicleService();
      final tyreViewService = TyreViewService();
      final vehicleApiSvc = AllVehicleService();

      try {
        final vehicles = await vehicleApiSvc.getVehiclesByAccount(
          parentAccountId: parentId,
        );
        await OfflineHiveService.saveVehicles(
          vehicles
              .map((v) => v.toJson()..['parentAccountId'] = parentId)
              .toList(),
        );
      } catch (_) {}

      final hivVehicles = OfflineHiveService.getVehicles(
        parentAccountId: parentId,
      );
      for (final v in hivVehicles) {
        if (v.vehicleId <= 0) continue;
        try {
          await inspeService.getInspectionRecord(v.vehicleId.toString());
          if (!OfflineHiveService.hasVehicleDetailCache(v.vehicleId)) {
            await vehicleService.getVehicleById(v.vehicleId);
          }
          await Future.delayed(const Duration(milliseconds: 200));
        } catch (_) {}
      }

      final hivTyres = OfflineHiveService.getAllTyres(
        parentAccountId: parentId,
      );
      for (final t in hivTyres) {
        if (t.tireId <= 0) continue;
        try {
          if (!OfflineHiveService.hasTireDetailCache(t.tireId)) {
            await tyreViewService.fetchTyreDetailsById(t.tireId);
          }
          await Future.delayed(const Duration(milliseconds: 200));
        } catch (_) {}
      }
    } finally {
      _isCaching = false;
    }
  }

  /// ✅ FIXED: ab is function mein poora try/catch/finally hai.
  /// - Purane counts turant 0 nahi kiye jaate (isse loader ke dauran UI
  ///   "0" flash nahi karega) — sirf naye data se REPLACE hote hain jab
  ///   fetch safal ho.
  /// - Agar fetch FAIL ho jaye (server error / no connectivity / any
  ///   exception): purane counts wapas restore ho jaate hain (as fallback,
  ///   taaki ghalat "0" na dikhe), `accountSwitchError` set hota hai
  ///   (Home screen ye read karke error dikha sakta hai), aur loader
  ///   (isLoading) hamesha `finally` me hat jaata hai — chahe success ho
  ///   ya fail.
  Future<void> refreshForNewAccount({
    required String newAccountId,
    required String newLocationId,
    required String newAccountName,
    required String newLocationName,
    // ✅ Optional multi-location list. Jab caller (e.g. Change Account
    // screen) multiple locations bhejta hai, dashboard un sabka combined
    // total fetch karta hai. Agar nahi diya (e.g. web-sync single-location
    // flow — AppRefreshService), toh single location wala hi behavior
    // chalta rahega (backward compatible).
    List<String>? newLocationIds,
    List<String>? newLocationNames,
  }) async {
    final locationIds = (newLocationIds != null && newLocationIds.isNotEmpty)
        ? newLocationIds
        : [newLocationId];
    final locationNames =
    (newLocationNames != null && newLocationNames.isNotEmpty)
        ? newLocationNames
        : [newLocationName];

    selectedLocationIds.value = locationIds;
    selectedLocationNames.value = locationNames;

    debugPrint(
        '[HOME_CONTROLLER] 🔄 Switching active account/location(s) -> '
            'accountId: $newAccountId ($newAccountName) | '
            'locationIds: ${locationIds.join(', ')} (${locationNames.join(', ')})');

    // Fallback ke liye purane counts yaad rakho (0 pe force reset nahi
    // karenge ab, taaki fail hone par UI galat "0" na dikhaye).
    final int prevVehicleCount = vehicleCount.value;
    final int prevTyreCount = tyreCount.value;
    final HomeModel? prevHomeData = homeData.value;

    isLoading.value = true;
    accountSwitchError.value = null;

    try {
      selectedParentAccountName.value = newAccountName;
      selectedLocationName.value = newLocationName;

      final cur = homeData.value;
      if (cur != null) {
        homeData.value = HomeModel(
          username: cur.username,
          parentAccount: newAccountName,
          location: newLocationName,
          role: cur.role,
          lastInspection: lastInspectionDate.value.isNotEmpty
              ? lastInspectionDate.value
              : cur.lastInspection,
          unsyncedInspections: unsyncedInspectionCount.value,
          syncedInspections: syncedInspectionCount.value,
          // Purane counts hi dikhate raho jab tak naya data na aaye
          totalTyres: prevTyreCount,
          vehicles: prevVehicleCount,
          appVersion: cur.appVersion,
          imageUrl: cur.imageUrl,
        );
      }

      final dash = await HomeService.fetchReportDashboardHomeDataWithIds(
        accountId: newAccountId,
        locationId: locationIds.join(','),
      );

      if (dash == null) {
        // Server se kuch nahi mila -> fail treat karo, purana data restore.
        throw Exception('Could not load data for the selected account/location.');
      }

      final baseVehicle = dash.vehicleCount ?? 0;
      final baseTyre = dash.totalTiresCount ?? 0;
      await SecureStorage.saveDashboardCounts(
        vehicleCount: baseVehicle,
        tyreCount: baseTyre,
      );
      vehicleCount.value = baseVehicle + _getPendingOfflineVehicleCount();
      tyreCount.value = baseTyre + _getPendingOfflineTyreCount();
      _updateHomeDataCounts();

      _isCaching = false;
      _silentFullPreCache().catchError((_) {});

      // 🔧 NEW: naye account/location ke liye bhi pending inspection
      // approval counts (Vehicle Inspection / Tire Inspection cards)
      // refresh karo, warna account switch ke baad purane account ke
      // counts hi dikhte reh jaate.
      await _refreshInspectionApprovalCounts();

      debugPrint(
          '[HOME_CONTROLLER] ✅ Active account/location now -> '
              'account: ${selectedParentAccountName.value} | '
              'location: ${selectedLocationName.value}');
    } catch (e) {
      debugPrint('[HOME_CONTROLLER] ❌ refreshForNewAccount EXCEPTION -> $e');

      // Fallback: purane counts + homeData wapas restore karo, taaki UI
      // par ghalat "0" ya blank data na reh jaaye.
      vehicleCount.value = prevVehicleCount;
      tyreCount.value = prevTyreCount;
      if (prevHomeData != null) {
        homeData.value = prevHomeData;
      }
      homeData.refresh();

      accountSwitchError.value =
      'Could not update counts for $newAccountName - $newLocationName. Please try again.';

      // User ko turant bhi dikha do (Home screen isse consume karke apna
      // banner bhi dikha sakta hai via accountSwitchError listener).
      if (!Get.isSnackbarOpen) {
        Get.snackbar(
          'Update Failed',
          accountSwitchError.value!,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      // Chahe success ho ya fail, loader hamesha hatna chahiye.
      isLoading.value = false;
    }
  }

  void _updateHomeDataCounts() {
    final cur = homeData.value;
    if (cur != null) {
      homeData.value = cur.copyWith(
        lastInspection: lastInspectionDate.value.isNotEmpty
            ? lastInspectionDate.value
            : cur.lastInspection,
        unsyncedInspections: unsyncedInspectionCount.value,
        syncedInspections: syncedInspectionCount.value,
        totalTyres: tyreCount.value,
        vehicles: vehicleCount.value,
      );
      homeData.refresh();
    }
  }

  Future<void> incrementVehicleCount() async {
    vehicleCount.value = vehicleCount.value + 1;
    _updateHomeDataCounts();
    final pendingV = _getPendingOfflineVehicleCount();
    final pendingT = _getPendingOfflineTyreCount();
    final baseV = (vehicleCount.value - pendingV).clamp(0, 999999);
    final baseT = (tyreCount.value - pendingT).clamp(0, 999999);
    await SecureStorage.saveDashboardCounts(
      vehicleCount: baseV,
      tyreCount: baseT,
    );
  }

  Future<void> incrementTyreCount() async {
    tyreCount.value = tyreCount.value + 1;
    _updateHomeDataCounts();
    final pendingV = _getPendingOfflineVehicleCount();
    final pendingT = _getPendingOfflineTyreCount();
    final baseV = (vehicleCount.value - pendingV).clamp(0, 999999);
    final baseT = (tyreCount.value - pendingT).clamp(0, 999999);
    await SecureStorage.saveDashboardCounts(
      vehicleCount: baseV,
      tyreCount: baseT,
    );
  }

  Future<void> fetchHome({bool showLoader = false}) async {
    if (showLoader) isLoading.value = true;
    try {
      final response = await HomeService.fetchHomeData();
      if (response != null) {
        final currentTyres = tyreCount.value;
        final currentVehicles = vehicleCount.value;
        homeData.value = response.copyWith(
          totalTyres: currentTyres > 0 ? currentTyres : response.totalTyres,
          vehicles: currentVehicles > 0 ? currentVehicles : response.vehicles,
          unsyncedInspections: unsyncedInspectionCount.value,
          syncedInspections: syncedInspectionCount.value,
          lastInspection: lastInspectionDate.value.isNotEmpty
              ? lastInspectionDate.value
              : response.lastInspection,
        );
        if (response.parentAccount.isNotEmpty) {
          selectedParentAccountName.value = response.parentAccount;
        }
        if (response.location.isNotEmpty) {
          selectedLocationName.value = response.location;
        }
        if (response.username.isNotEmpty) username.value = response.username;
        debugPrint(
            '[HOME_CONTROLLER] 📡 fetchHome() API response -> '
                'user: ${response.username} | account: ${response.parentAccount} | '
                'location: ${response.location}');
      } else {
        debugPrint('[HOME_CONTROLLER] ⚠️ fetchHome() API returned null');
      }
      _updateHomeDataCounts();
      await _refreshLastInspectionDate();
    } finally {
      if (showLoader) isLoading.value = false;
    }
  }

  Future<void> refreshHome({bool showLoader = false}) async {
    if (showLoader) isLoading.value = true;
    try {
      await Future.wait([
        fetchHome(showLoader: false),
        loadTyreCountByAccount(),
        loadVehicleCountByAccount(),
      ]);
      _updateHomeDataCounts();
      await _refreshLastInspectionDate();
      await _refreshInspectionApprovalCounts(); // 🔧 NEW
    } finally {
      if (showLoader) isLoading.value = false;
    }
  }

  Future<void> loadTyreCountByAccount() async {
    int baseCount = SecureStorage.getLastTyreCount() ??
        (tyreCount.value - _getPendingOfflineTyreCount()).clamp(0, 999999);
    try {
      final dash = await HomeService.fetchReportDashboardHomeData();
      if (dash != null && dash.totalTiresCount != null) {
        baseCount = dash.totalTiresCount!;
        await SecureStorage.saveDashboardCounts(
          vehicleCount: SecureStorage.getLastVehicleCount() ?? vehicleCount.value,
          tyreCount: baseCount,
        );
      }
    } catch (_) {}
    tyreCount.value = baseCount + _getPendingOfflineTyreCount();
    _updateHomeDataCounts();
  }

  Future<void> loadVehicleCountByAccount() async {
    int baseCount = SecureStorage.getLastVehicleCount() ??
        (vehicleCount.value - _getPendingOfflineVehicleCount()).clamp(0, 999999);
    try {
      final dash = await HomeService.fetchReportDashboardHomeData();
      if (dash != null && dash.vehicleCount != null) {
        baseCount = dash.vehicleCount!;
        await SecureStorage.saveDashboardCounts(
          vehicleCount: baseCount,
          tyreCount: SecureStorage.getLastTyreCount() ?? tyreCount.value,
        );
      }
    } catch (_) {}
    vehicleCount.value = baseCount + _getPendingOfflineVehicleCount();
    _updateHomeDataCounts();
  }

  Future<void> clearLocalStorage() async {}

  void rollbackSyncCounts(int prevUnsynced, int prevSynced) {
    unsyncedInspectionCount.value = prevUnsynced;
    syncedInspectionCount.value = prevSynced;
    if (homeData.value != null) {
      homeData.value = homeData.value!.copyWith(
        unsyncedInspections: prevUnsynced,
        syncedInspections: prevSynced,
      );
    }
    homeData.refresh();
    try {
      if (Get.isRegistered<InspectionController>()) {
        Get.find<InspectionController>().loadData();

      }
    } catch (_) {}
  }
}