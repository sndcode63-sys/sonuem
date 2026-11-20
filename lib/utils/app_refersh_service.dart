import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:emtrack/utils/hive_prefe.dart';
import 'package:emtrack/services/change_account_service.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/services/all_vehicles_services.dart';
import 'package:emtrack/services/preferences_service.dart';
import 'package:emtrack/models/preferences_model.dart';
import 'package:emtrack/controllers/all_vehicles_controller.dart';
import 'package:emtrack/controllers/all_tyre_controller.dart';
import 'package:emtrack/controllers/home_controller.dart';
import 'package:emtrack/controllers/tyre_view_controller.dart';
import 'package:emtrack/controllers/inspect_tyre_controller.dart';
import 'package:emtrack/controllers/install_tyre_controller.dart';


class AppRefreshService with WidgetsBindingObserver {
  AppRefreshService._();
  static final AppRefreshService _instance = AppRefreshService._();
  static AppRefreshService get instance => _instance;

  static const _kPeriodicMinutes = 5;

  static const _kDebounceSeconds = 60;

  Timer? _periodicTimer;
  DateTime? _lastRefreshAt;
  bool _isRefreshing = false;
  bool _initialized = false;

  static void init() {
    if (_instance._initialized) return;
    _instance._initialized = true;
    WidgetsBinding.instance.addObserver(_instance);
    _instance._startPeriodicTimer();
  }

  static void dispose() {
    _instance._periodicTimer?.cancel();
    _instance._periodicTimer = null;
    if (_instance._initialized) {
      WidgetsBinding.instance.removeObserver(_instance);
    }
    _instance._initialized = false;
    _instance._lastRefreshAt = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      triggerNow(reason: 'app_resume');
    }
  }

  void _startPeriodicTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(
      Duration(minutes: _kPeriodicMinutes),
          (_) => triggerNow(reason: 'periodic_timer'),
    );
  }


  static Future<void> triggerNow({String reason = 'manual'}) async {
    await _instance._doRefresh(reason: reason);
  }

  Future<void> _doRefresh({required String reason}) async {
    if (_isRefreshing) {
      return;
    }
    final now = DateTime.now();
    if (_lastRefreshAt != null &&
        now.difference(_lastRefreshAt!).inSeconds < _kDebounceSeconds) {
      return;
    }

    // Online check
    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = connectivity.any((r) => r != ConnectivityResult.none);
    if (!isOnline) {
      return;
    }

    final cookie = await SecureStorage.getCookie();
    if (cookie == null || cookie.isEmpty) {
      return;
    }

    _isRefreshing = true;
    _lastRefreshAt = now;

    try {
      await _retryPendingAccountLocationPush();

      await Future.wait([
        _refreshLocationSettings(),
        _refreshAccountLocationOnly(),
        _refreshMasterData(),
        _refreshVehicles(),
      ]);

      _notifyControllers();

    } catch (_) {
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _retryPendingAccountLocationPush() async {
    try {
      final pending = HivePref.get<Map>('pending_account_location_push');
      if (pending == null) return;

      final svc = ChangeAccountService();
      final success = await svc.postAccountLocationChange(
        parentAccountId: pending['parentAccountId']?.toString() ?? '',
        locationId: pending['locationId']?.toString() ?? '',
        userId: pending['userId']?.toString() ?? '',
      );

      if (success) {
        HivePref.set('pending_account_location_push', null);
      }
    } catch (_) {}
  }


  Future<void> _refreshLocationSettings() async {
    try {
      final locationIdStr = await SecureStorage.getLocationId();
      final locationId = int.tryParse(locationIdStr ?? '');
      if (locationId == null || locationId <= 0) return;

      final svc = ChangeAccountService();
      final newCount = await svc.fetchAndSaveNoOfTreadDepthReadings(locationId);


      _updateTreadDepthInControllers(newCount);
    } catch (_) {
    }
  }

  void _updateTreadDepthInControllers(int newCount) {
    try {
      if (Get.isRegistered<TyreViewController>()) {
        Get.find<TyreViewController>().noOfTreadDepthReadings.value = newCount;
      }
    } catch (_) {}

    try {
      if (Get.isRegistered<InspectTyreController>()) {
        Get.find<InspectTyreController>().noOfTreadDepthReadings.value = newCount;
      }
    } catch (_) {}

    try {
      if (Get.isRegistered<InstallTyreController>()) {
        Get.find<InstallTyreController>().noOfTreadDepthReadings.value = newCount;
      }
    } catch (_) {}
  }




  Future<void> _refreshAccountLocationOnly() async {
    try {
      final username = await SecureStorage.getUserName();
      if (username == null || username.isEmpty) return;

      final svc = PreferencesService();
      final prefs = await svc.fetchPreferences(username);
      if (prefs == null) {
        return;
      }


      await _applyWebAccountLocationChangeIfAny(prefs);
    } catch (_) {
    }
  }

  Future<void> _applyWebAccountLocationChangeIfAny(PreferencesModel prefs) async {
    try {

      if (HivePref.get<Map>('pending_account_location_push') != null) return;

      final webAccountId = prefs.lastAccessedAccountId ?? 0;
      final webLocationId = prefs.lastAccessedLocationId ?? 0;
      if (webAccountId <= 0 || webLocationId <= 0) return;

      final currentAccountId =
          int.tryParse(await SecureStorage.getParentAccountId() ?? '') ?? 0;
      final currentLocationId =
          int.tryParse(await SecureStorage.getLocationId() ?? '') ?? 0;

      final changed =
          webAccountId != currentAccountId || webLocationId != currentLocationId;
      if (!changed) return;

      final newAccountName = prefs.lastAccessedAccountName ?? '';
      final newLocationName = prefs.lastAccessedLocationName ?? '';
      final username = await SecureStorage.getUserName() ?? '';

      await Future.wait([
        SecureStorage.saveParentAccount(
            id: webAccountId.toString(), name: newAccountName),
        SecureStorage.saveLocation(
            id: webLocationId.toString(), name: newLocationName),
        if (username.isNotEmpty)
          SecureStorage.saveParentAccountForUser(
              username: username,
              id: webAccountId.toString(),
              name: newAccountName),
        if (username.isNotEmpty)
          SecureStorage.saveLocationForUser(
              username: username,
              id: webLocationId.toString(),
              name: newLocationName),
      ]);

      final svc = ChangeAccountService();
      await svc.fetchAndSaveNoOfTreadDepthReadings(webLocationId);

      if (Get.isRegistered<HomeController>()) {
        final home = Get.find<HomeController>();
        home.selectedParentAccountName.value = newAccountName;
        home.selectedLocationName.value = newLocationName;
        await home.refreshForNewAccount(
          newAccountId: webAccountId.toString(),
          newLocationId: webLocationId.toString(),
          newAccountName: newAccountName,
          newLocationName: newLocationName,
        );
      }
    } catch (_) {}
  }



  Future<void> _refreshMasterData() async {
    try {
    } catch (_) {
    }
  }


  Future<void> _refreshVehicles() async {
    try {
      final parentIdStr = await SecureStorage.getParentAccountId();
      final parentId = int.tryParse(parentIdStr ?? '');
      if (parentId == null || parentId <= 0) return;

      final vehicles = await AllVehicleService().getVehiclesByAccount(
        parentAccountId: parentId,
      );

      await OfflineHiveService.saveVehicles(
        vehicles.map((v) => v.toJson()..['parentAccountId'] = parentId).toList(),
      );

    } catch (_) {
    }
  }

  void _notifyControllers() {
    try {
      if (Get.isRegistered<AllVehicleController>()) {
        Get.find<AllVehicleController>().loadVehicles();
      }
    } catch (_) {
    }

    try {
      if (Get.isRegistered<AllTyreController>()) {
        Get.find<AllTyreController>().fetchData();
      }
    } catch (_) {
    }

    try {
      final homeCtrl = Get.find(tag: 'HomeController');
      (homeCtrl as dynamic).refreshCountsFromHive();
    } catch (_) {
    }
  }


}