import '../utils/local_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/inspection_hive_models.dart';
import '../services/inspection_service.dart';
import '../services/network_sync_servives.dart';
import '../utils/app_snackbar.dart';
import 'home_controller.dart';

void _log(String msg) {
  debugPrint('[INSP-CTRL] $msg');
}

void _showNoInternetToast() {
  Get.snackbar(
    "Syncing Unsuccessful.",
    'All Vehicle inspections synced Unsuccessfully.',
    backgroundColor: Colors.green,
    colorText: Colors.white,
    snackPosition: SnackPosition.TOP,
    margin: const EdgeInsets.all(10),
    borderRadius: 8,
    duration: const Duration(seconds: 3),
    icon: const Icon(Icons.wifi_off, color: Colors.white),
  );
}

class InspectionController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final InspectionService _service = InspectionService();

  late TabController tabController;

  final unsyncedList = <InspectionHiveModel>[].obs;
  final syncedList = <InspectionHiveModel>[].obs;

  final isLoading = false.obs;
  final isSyncingAll = false.obs;

  final syncingIds = <String>{}.obs;

  int get unsyncedCount => unsyncedList.length;
  int get syncedCount => syncedList.length;

  final isOnline = true.obs;

  @override
  void onInit() {
    super.onInit();
    _log('onInit: InspectionController init ho raha hai');
    final initialIndex = (Get.arguments is int) ? Get.arguments as int : 0;
    tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialIndex,
    );
    _checkConnectivity();
    _listenConnectivity();
    loadData();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    isOnline.value = result.any((r) => r != ConnectivityResult.none);
    _log('_checkConnectivity: isOnline=${isOnline.value}');
  }

  void _listenConnectivity() {
    Connectivity().onConnectivityChanged.listen((result) {
      final wasOffline = !isOnline.value;
      isOnline.value = result.any((r) => r != ConnectivityResult.none);
      _log('connectivityChanged: wasOffline=$wasOffline nowOnline=${isOnline.value} unsyncedCount=${unsyncedList.length}');

      if (wasOffline && isOnline.value && unsyncedList.isNotEmpty) {
        _log('connectivityChanged: 🔁 auto-sync trigger karenge (offline->online + pending unsynced hai)');
        _triggerAutoSync();
      }
    });
  }

  Future<void> _triggerAutoSync() async {
    _log('_triggerAutoSync: 2 sec wait karke check karenge');
    await Future.delayed(const Duration(seconds: 2));
    if (unsyncedList.isEmpty) {
      _log('_triggerAutoSync: unsyncedList empty ho gayi (shayad already sync ho gaya), SKIP');
      return;
    }
    if (!await ManualSyncService.isOnline()) {
      _log('_triggerAutoSync: isOnline check FALSE aaya, SKIP');
      return;
    }

    try {
      _log('_triggerAutoSync: 🔁 _service.syncAll() CALL kar rahe hain');
      final result = await _service.syncAll();
      _log('_triggerAutoSync: syncAll() result=$result');
      await loadData();
      _refreshHomeCount();
      final success = result['success'] ?? 0;
      if (success > 0) {
        _log('_triggerAutoSync: ✅ success toast dikha rahe hain');
        AppSnackbar.success(
          'All Vehicle inspections synced successfully.',
          title: 'Syncing Successful.',
        );
      } else {
        _log('_triggerAutoSync: success=0, koi toast nahi (silent)');
      }
    } catch (e) {
      _log('_triggerAutoSync: ❌ EXCEPTION -> $e');
    }
  }

  Future<void> loadData() async {
    _log('loadData: CALLED, data reload ho raha hai...');
    isLoading.value = true;
    try {
      unsyncedList.value = await _service.getUnsyncedInspections();
      syncedList.value = await _service.getSyncedInspections();
      _log('loadData: DONE -> unsynced=${unsyncedList.length} synced=${syncedList.length}');

      _refreshHomeCount();
    } catch (e) {
      _log('loadData: ❌ EXCEPTION -> $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _refreshHomeCount() {
    try {
      if (!Get.isRegistered<HomeController>()) {
        _log('_refreshHomeCount: HomeController registered nahi hai, SKIP');
        return;
      }
      final hc = Get.find<HomeController>();
      if (hc.isSyncing.value) {
        _log('_refreshHomeCount: HomeController abhi sync kar raha hai, SKIP (race avoid)');
        return;
      }
      hc.unsyncedInspectionCount.value = unsyncedList.length;
      hc.syncedInspectionCount.value = syncedList.length;
      if (hc.homeData.value != null) {
        hc.homeData.value = hc.homeData.value!.copyWith(
          unsyncedInspections: unsyncedList.length,
          syncedInspections: syncedList.length,
        );
      }
      hc.homeData.refresh();
      _log('_refreshHomeCount: home counts update ho gaye -> unsynced=${unsyncedList.length} synced=${syncedList.length}');
    } catch (e) {
      _log('_refreshHomeCount: ❌ EXCEPTION -> $e');
    }
  }

  //  🔘🔘🔘 SINGLE-ROW "SYNC" BUTTON YAHAN SE CALL HOTA HAI 🔘🔘🔘
  Future<void> syncSingle(InspectionHiveModel inspection) async {
    _log('🔘🔘🔘 SYNC (SINGLE ROW) BUTTON PRESSED -> vehicleId=${inspection.vehicleId} vehicleNo=${inspection.vehicleNumber}');

    if (!await ManualSyncService.isOnline()) {
      _log('syncSingle: ❌ internet NAHI HAI -> toast dikha ke ABORT kar rahe hain');
      _showNoInternetToast();
      return;
    }

    syncingIds.add(inspection.id);
    _log('syncSingle: spinner ON (syncingIds me id=${inspection.id} add hui)');

    await WidgetsBinding.instance.endOfFrame;

    try {
      _log('syncSingle: _service.syncInspection() CALL kar rahe hain...');
      final ok = await _service.syncInspection(inspection);
      _log('syncSingle: _service.syncInspection() RESULT = ${ok ? "✅ TRUE (synced)" : "❌ FALSE (sync NAHI hua)"}');
      await loadData();
      _refreshHomeCount();

      if (ok) {
        _log('syncSingle: ✅ SUCCESS toast dikha rahe hain');
        _showSyncSuccessfulToast('A Vehicle inspections synced successfully.');
      } else {
        _log('syncSingle: ❌ FAIL toast dikha rahe hain (retry baad me hoga)');
        _showSyncUnsuccessfulToast(
          'This inspection could not be synced. It will be retried later.',
        );
      }
    } catch (e) {
      _log('syncSingle: ❌ EXCEPTION -> $e');
    } finally {
      syncingIds.remove(inspection.id);
      _log('syncSingle: spinner OFF (id=${inspection.id} remove hui) — DONE');
    }
  }

  //  🔘🔘🔘 "SYNC ALL" BUTTON YAHAN SE CALL HOTA HAI 🔘🔘🔘
  Future<void> syncAll() async {
    _log('🔘🔘🔘 SYNC ALL BUTTON PRESSED -> unsyncedList.length=${unsyncedList.length}');
    if (unsyncedList.isEmpty) {
      _log('syncAll: unsyncedList EMPTY hai, kuch bhi karne ki zaroorat nahi -> RETURN');
      return;
    }

    if (!await ManualSyncService.isOnline()) {
      _log('syncAll: ❌ internet NAHI HAI -> toast dikha ke ABORT kar rahe hain');
      _showNoInternetToast();
      return;
    }

    isSyncingAll.value = true;
    _log('syncAll: isSyncingAll=true (button per loading state)');

    await WidgetsBinding.instance.endOfFrame;

    try {
      _log('syncAll: _service.syncAll() CALL kar rahe hain...');
      final result = await _service.syncAll();
      _log('syncAll: _service.syncAll() RESULT = $result');

      await loadData();
      _refreshHomeCount();

      final success = result['success'] ?? 0;
      _log('syncAll: success=$success remainingUnsynced=${unsyncedList.length}');

      if (success > 0 || unsyncedList.isEmpty) {
        _log('syncAll: ✅ SUCCESS toast dikha rahe hain');
        _showSyncSuccessfulToast(
          'All Vehicle inspections synced successfully.',
        );
      } else {
        _log('syncAll: ❌ FAIL toast dikha rahe hain (kuch bhi sync nahi hua)');
        _showSyncUnsuccessfulToast(
          'Inspections could not be synced. They will be retried later.',
        );
      }
    } catch (e) {
      _log('syncAll: ❌ EXCEPTION -> $e');
      await loadData();
      _refreshHomeCount();
    } finally {
      isSyncingAll.value = false;
      _log('syncAll: isSyncingAll=false — DONE');
    }
  }

  void _showSyncSuccessfulToast(String body) {
    Get.snackbar(
      'Syncing Successful.',
      body,
      backgroundColor: Colors.green.shade700,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  void _showSyncUnsuccessfulToast(String body) {
    Get.snackbar(
      'Syncing Unsuccessful.',
      body,
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  //  🔘 "DELETE" BUTTON YAHAN SE CALL HOTA HAI 🔘
  Future<void> deleteInspection(InspectionHiveModel inspection) async {
    _log('🔘 DELETE BUTTON PRESSED -> vehicleId=${inspection.vehicleId} vehicleNo=${inspection.vehicleNumber}');
    await _service.deleteInspection(inspection.id);
    await loadData();
    _refreshHomeCount();
    _log('deleteInspection: DONE, "Deleted" toast dikha rahe hain');
    Get.snackbar(
      'Deleted',
      'Inspection for ${inspection.vehicleNumber} deleted.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
    );
  }

  String formatDate(String isoDate) {
    try {
      return LocaleHelper.formatLongDateTime(DateTime.parse(isoDate).toLocal());
    } catch (_) {
      return isoDate;
    }
  }

  @override
  void onClose() {
    _log('onClose: InspectionController dispose ho raha hai');
    tabController.dispose();
    super.onClose();
  }
}