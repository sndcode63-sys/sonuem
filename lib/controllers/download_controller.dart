import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:emtrack/inspection/vehicle_inspe_service.dart';
import 'package:emtrack/services/api_constants.dart';
import 'package:emtrack/services/change_account_service.dart';
import 'package:emtrack/services/home_service.dart';
import 'package:emtrack/services/master_data_service.dart';
import 'package:emtrack/services/tyre_view_service.dart';
import 'package:emtrack/services/update_vehicle_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models/approva.dart';
import '../routes/app_pages.dart';
import '../services/offline_hive_service.dart';

class DownloadController extends GetxController {
  final progress = 0.0.obs;
  final statusText = 'Starting...'.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  final _client = http.Client();

  // How long a data-section is considered "fresh" before we bother
  // re-downloading it. Tune per section if needed.
  static const Duration _freshWindow = Duration(minutes: 30);

  // Section keys used for SecureStorage.isSectionFresh / saveLastSyncTime.
  static const _secMaster = 'master_data';
  static const _secStatus = 'status_master';
  static const _secAccountsLocations = 'accounts_locations';
  static const _secVehicles = 'vehicles';
  static const _secTyres = 'tyres';
  static const _secDashboard = 'dashboard';

  /// If true, freshness checks are ignored and everything is re-downloaded.
  /// Set by [retry]'s force flag or a manual "Sync Now" action.
  bool _forceFull = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['force'] == true) {
      _forceFull = true;
    }
    _startDownload();
  }

  @override
  void onClose() {
    _client.close();
    super.onClose();
  }

  Future<void> _startDownload() async {
    try {
      hasError.value = false;

      // 🔍 DEBUG LOGS: Check approval workflow & approver status right here
      final gpId = await SecureStorage.getProfileGrandParentAccountId();
      final workflowEnabled = await SecureStorage.getApprovalWorkflowEnabled();
      final workflowMatched = await SecureStorage.getApprovalWorkflowGpMatched();
      final isApproverUser = await SecureStorage.getIsApprover();

      AppLogger.success(
        '[DownloadController] CHECK STATE -> grandParentAccountId=$gpId | '
            'workflowEnabled=$workflowEnabled | workflowMatched=$workflowMatched | isApprover=$isApproverUser',
      );

      if (_forceFull) {
        await SecureStorage.clearAllSyncTimes();
      }

      _update(0.05, 'Setting up account...');
      final existingAccountId = await SecureStorage.getParentAccountId();
      final existingLocationId = await SecureStorage.getLocationId();
      final hasExistingAccount =
          existingAccountId != null &&
              existingAccountId.isNotEmpty &&
              existingAccountId != '0' &&
              existingLocationId != null &&
              existingLocationId.isNotEmpty &&
              existingLocationId != '0';

      if (!hasExistingAccount) {
        await _setupDefaultAccountAndLocation();
      }
      _update(0.15, 'Account ready ✓');

      // Fast-path: if initial download was done, local data exists, and NOT expired (< 24 hours),
      // we don't re-download everything on every login!
      final bool initialDone = await SecureStorage.isInitialDownloadDone();
      final bool isExpired = await SecureStorage.isFullDownloadExpired();
      final bool hasLocalVehicles = OfflineHiveService.hasAnyVehicles();
      final bool hasMaster = OfflineHiveService.hasMasterData();

      if (!_forceFull && initialDone && (hasLocalVehicles || hasMaster) && !isExpired) {
        _update(1.0, 'Up to date ✓');
        await Future.delayed(const Duration(milliseconds: 300));
        Get.offAllNamed(AppPages.HOME);
        return;
      }

      _update(0.18, 'Downloading data...');
      await Future.wait([
        _downloadAndSaveMasterData(),
        _downloadAndSaveStatusMaster(),
        _downloadAndSaveAccountsLocations(),
        _downloadAndSaveVehicles(),
        _downloadAndSaveTyres(),
      ]);
      _update(0.72, 'Data downloaded ✓');

      _update(0.74, 'Caching dashboard...');
      await _cacheDashboardCounts();
      _update(0.78, 'Dashboard ready ✓');

      _update(0.80, 'Caching details...');
      await _preCacheAllDetails();
      _update(1.0, 'All done! ✓');
      await SecureStorage.setInitialDownloadDone(true);
      await SecureStorage.saveLastFullDownloadTime();

      await Future.delayed(const Duration(milliseconds: 400));
      Get.offAllNamed(AppPages.HOME);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Download failed. Check connection and retry.';
    }
  }



  void _update(double val, String text) {
    progress.value = val;
    statusText.value = text;
  }

  Future<void> _downloadAndSaveMasterData() async {
    if (!_forceFull &&
        await SecureStorage.isSectionFresh(_secMaster, maxAge: _freshWindow)) {
      return; // already synced recently, skip network call
    }
    try {
      final cookie = await SecureStorage.getCookie();
      if (cookie == null || cookie.isEmpty) return;

      final url = Uri.parse(
        '${ApiConstants.baseUrl}/api/MasterData/GetMasterDataMobile',
      );
      final resp = await _client
          .get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': cookie,
        },
      )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        await OfflineHiveService.saveMasterDataJson(resp.body);

        try {
          final decoded = jsonDecode(resp.body);
          if (decoded is Map<String, dynamic>) {
            final modelData = decoded['model'];
            if (modelData is Map<String, dynamic> && modelData.isNotEmpty) {
              await OfflineHiveService.saveMasterData(modelData);
            }
          }
        } catch (_) {
          try {
            final svc = MasterDataService();
            final data = await svc.fetchMasterDataFromApi();
            await OfflineHiveService.saveMasterData(data);
          } catch (_) {}
        }
        await SecureStorage.saveLastSyncTime(_secMaster);
      }
    } catch (_) {
      try {
        final svc = MasterDataService();
        final data = await svc.fetchMasterDataFromApi();
        await OfflineHiveService.saveMasterData(data);
        await SecureStorage.saveLastSyncTime(_secMaster);
      } catch (_) {}
    }

    await _saveAndLogAccountIdsAfterMasterData();
  }


  Future<void> _saveAndLogAccountIdsAfterMasterData() async {
    try {
      final accountId = await SecureStorage.getParentAccountId();
      final accountName = await SecureStorage.getParentAccountName();
      final grandParentAccountId =
      await SecureStorage.getProfileGrandParentAccountId();

      if (accountId != null && accountId.isNotEmpty) {

        await SecureStorage.saveParentAccount(
          id: accountId,
          name: accountName ?? '',
        );

        AppLogger.success(
          '[DownloadController] MASTER DATA DOWNLOADED -> '
              'accountId(parentAccountId)=$accountId | '
              'parentAccountName=${accountName ?? "null"} | '
              'grandParentAccountId=${grandParentAccountId ?? "null"} '
              '— saved to SecureStorage ✔',
        );
      } else {
        AppLogger.warn(
          '[DownloadController] MASTER DATA DOWNLOADED but accountId is '
              'still empty in SecureStorage — check _setupDefaultAccountAndLocation().',
        );
      }
    } catch (e) {
      AppLogger.error(
        '[DownloadController] Failed to read/save accountId after master data download: $e',
      );
    }
  }

  Future<void> _downloadAndSaveStatusMaster() async {
    if (!_forceFull &&
        await SecureStorage.isSectionFresh(_secStatus, maxAge: _freshWindow)) {
      return;
    }
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getAllStatus}');
    try {
      final cookie = await SecureStorage.getCookie();
      if (cookie == null || cookie.isEmpty) {
        debugPrint('⚠️ [DownloadController] Skipping GetAllStatus — no cookie yet');
        return;
      }

      debugPrint('➡️ [DownloadController] GET $url');

      final resp = await _client
          .get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': cookie,
        },
      )
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '⬅️ [DownloadController] GetAllStatus -> ${resp.statusCode} '
            '(${resp.body.length} bytes) from $url',
      );

      debugPrint('📦 [DownloadController] Status Master Response Body: ${resp.body}');

      if (resp.statusCode == 200) {
        await OfflineHiveService.saveStatusMasterJson(resp.body);
        await SecureStorage.saveLastSyncTime(_secStatus);
        debugPrint('✅ [DownloadController] Status master cached from $url');
      } else {
        debugPrint(
          '❌ [DownloadController] GetAllStatus failed (${resp.statusCode}) at $url',
        );
      }
    } catch (e) {
      debugPrint('❌ [DownloadController] GetAllStatus error at $url -> $e');
    }
  }

  Future<void> _downloadAndSaveAccountsLocations() async {
    if (!_forceFull &&
        await SecureStorage.isSectionFresh(_secAccountsLocations,
            maxAge: _freshWindow)) {
      return;
    }
    try {
      final svc = ChangeAccountService();

      final parentIdStr = await SecureStorage.getParentAccountId();
      final parentId = int.tryParse(parentIdStr ?? '');

      await Future.wait([
        svc
            .fetchParentAccounts()
            .then((accounts) async {
          await OfflineHiveService.saveAccounts(
            accounts
                .map(
                  (a) => {
                'parentAccountId': a.parentAccountId,
                'accountName': a.accountName,
              },
            )
                .toList(),
          );
        })
            .catchError((_) {}),

        if (parentId != null)
          svc
              .fetchLocations(parentId)
              .then((locs) async {
            await OfflineHiveService.saveLocations(
              locs
                  .map(
                    (l) => {
                  'locationId': l.locationId,
                  'locationName': l.locationName,
                  'parentAccountId': parentId,
                },
              )
                  .toList(),
            );
          })
              .catchError((_) {}),
      ]);
      await SecureStorage.saveLastSyncTime(_secAccountsLocations);
    } catch (_) {}
  }

  Future<void> _downloadAndSaveVehicles() async {
    if (!_forceFull &&
        await SecureStorage.isSectionFresh(_secVehicles, maxAge: _freshWindow)) {
      return;
    }
    try {
      final parentIdStr = await SecureStorage.getParentAccountId();
      if (parentIdStr == null || parentIdStr.isEmpty || parentIdStr == '0')
        return;

      final rawList = await HomeService.fetchVehicleRawList(parentIdStr);
      if (rawList != null && rawList.isNotEmpty) {
        await OfflineHiveService.saveVehicles(rawList);
        await SecureStorage.saveLastSyncTime(_secVehicles);
      }
    } catch (_) {}
  }

  Future<void> _downloadAndSaveTyres() async {
    if (!_forceFull &&
        await SecureStorage.isSectionFresh(_secTyres, maxAge: _freshWindow)) {
      return;
    }
    try {
      final parentIdStr = await SecureStorage.getParentAccountId();
      if (parentIdStr == null || parentIdStr.isEmpty || parentIdStr == '0')
        return;

      final rawList = await HomeService.fetchTyreRawList(parentIdStr);
      if (rawList != null && rawList.isNotEmpty) {
        await OfflineHiveService.saveTyres(rawList);
        await SecureStorage.saveLastSyncTime(_secTyres);
      }
    } catch (_) {}
  }

  Future<void> _preCacheAllDetails() async {
    try {
      final parentIdStr = await SecureStorage.getParentAccountId();
      if (parentIdStr == null || parentIdStr.isEmpty || parentIdStr == '0') {
        return;
      }
      final parentId = int.tryParse(parentIdStr);
      if (parentId == null) return;

      final inspeService = VehicleInspeService();
      final vehicleService = UpdateVehicleService();
      final tyreViewService = TyreViewService();

      final vehicles = OfflineHiveService.getVehicles(
        parentAccountId: parentId,
      );
      final tyres = OfflineHiveService.getAllTyres(parentAccountId: parentId);

      final vehiclesToCache = vehicles
          .where(
            (v) =>
        v.vehicleId > 0 &&
            (!OfflineHiveService.hasVehicleDetailCache(v.vehicleId) ||
                !OfflineHiveService.hasInspectionCache(
                  v.vehicleId.toString(),
                )),
      )
          .toList();

      final tyresToCache = tyres
          .where(
            (t) =>
        t.tireId > 0 &&
            !OfflineHiveService.hasTireDetailCache(t.tireId),
      )
          .toList();

      final total = vehiclesToCache.length + tyresToCache.length;
      if (total == 0) return;

      int done = 0;
      const baseProgress = 0.80;
      const rangeProgress = 0.18;

      void tick() {
        done++;
        final pct = baseProgress + (done / total) * rangeProgress;
        _update(pct.clamp(0.80, 0.97), 'Caching ($done/$total)...');
      }

      const concurrency = 10;

      Future<void> runWithConcurrency<T>(
          List<T> items,
          Future<void> Function(T) task,
          ) async {
        final semaphore = <Future>[];
        for (final item in items) {
          final f = task(item).catchError((_) {}).whenComplete(tick);
          semaphore.add(f);
          if (semaphore.length >= concurrency) {
            await Future.wait(semaphore);
            semaphore.clear();
          }
        }
        if (semaphore.isNotEmpty) await Future.wait(semaphore);
      }

      await Future.wait([
        runWithConcurrency(vehiclesToCache, (v) async {
          final needsVehicle = !OfflineHiveService.hasVehicleDetailCache(
            v.vehicleId,
          );
          final needsInspect = !OfflineHiveService.hasInspectionCache(
            v.vehicleId.toString(),
          );

          await Future.wait([
            if (needsVehicle)
              vehicleService
                  .getVehicleById(v.vehicleId)
                  .timeout(const Duration(seconds: 8))
                  .catchError((_) => null),
            if (needsInspect)
              inspeService
                  .getInspectionRecord(v.vehicleId.toString())
                  .timeout(const Duration(seconds: 8))
                  .catchError((_) => null),
          ]);
        }),

        runWithConcurrency(tyresToCache, (t) async {
          await tyreViewService
              .fetchTyreDetailsById(t.tireId)
              .timeout(const Duration(seconds: 8))
              .catchError((_) async {});
        }),
      ]);
    } catch (_) {}
  }

  Future<void> _cacheDashboardCounts() async {
    if (!_forceFull &&
        await SecureStorage.isSectionFresh(_secDashboard, maxAge: _freshWindow)) {
      return;
    }
    try {
      final dash = await HomeService.fetchReportDashboardHomeData().timeout(
        const Duration(seconds: 10),
      );
      if (dash != null) {
        await SecureStorage.saveDashboardCounts(
          vehicleCount: dash.vehicleCount ?? 0,
          tyreCount: dash.totalTiresCount ?? 0,
        );
        await SecureStorage.saveLastSyncTime(_secDashboard);
      }
    } catch (_) {}
  }

  Future<void> _setupDefaultAccountAndLocation() async {
    try {
      final svc = ChangeAccountService();
      final cookie = await SecureStorage.getCookie();

      try {
        final homeResp = await _client
            .get(
          Uri.parse('${ApiConstants.baseUrl}/api/Home'),
          headers: {'Accept': 'application/json', 'Cookie': cookie ?? ''},
        )
            .timeout(const Duration(seconds: 8));

        if (homeResp.statusCode == 200) {
          final decoded = jsonDecode(homeResp.body);
          if (decoded is Map<String, dynamic>) {
            final payload = decoded['data'] ?? decoded['model'] ?? decoded;
            if (payload is Map<String, dynamic>) {
              final accountId = payload['parentAccountId']?.toString();
              final accountName =
              (payload['parentAccount'] ?? payload['accountName'] ?? '')
                  .toString();
              if (accountId != null &&
                  accountId.isNotEmpty &&
                  accountId != '0') {
                await _saveAccountAndLocation(svc, accountId, accountName);
                return;
              }
            }
          }
        }
      } catch (_) {}

      final accounts = await svc.fetchParentAccounts();
      if (accounts.isEmpty) return;

      bool found = false;
      final chunks = <List>[];
      for (var i = 0; i < accounts.length && i < 15; i += 5) {
        chunks.add(accounts.sublist(i, (i + 5).clamp(0, accounts.length)));
      }

      for (final chunk in chunks) {
        if (found) break;
        final results = await Future.wait(
          chunk.map((acc) async {
            try {
              final resp = await _client
                  .get(
                Uri.parse(
                  '${ApiConstants.baseUrl}/api/Vehicle/GetVehicleByUser/${acc.parentAccountId}/0?timeStamp=0',
                ),
                headers: {
                  'Accept': 'application/json',
                  'Cookie': cookie ?? '',
                },
              )
                  .timeout(const Duration(seconds: 5));
              if (resp.statusCode == 200) {
                final json = jsonDecode(resp.body);
                if (json['didError'] != true) return acc;
              }
            } catch (_) {}
            return null;
          }),
        );

        final validAcc = results.firstWhere(
              (r) => r != null,
          orElse: () => null,
        );
        if (validAcc != null) {
          found = true;
          await _saveAccountAndLocation(
            svc,
            validAcc.parentAccountId.toString(),
            validAcc.accountName,
          );
          return;
        }
      }

      final first = accounts.first;
      await _saveAccountAndLocation(
        svc,
        first.parentAccountId.toString(),
        first.accountName,
      );
    } catch (_) {}
  }

  Future<void> _saveAccountAndLocation(
      ChangeAccountService svc,
      String accountId,
      String accountName,
      ) async {
    await SecureStorage.saveParentAccount(id: accountId, name: accountName);
    final parentIdInt = int.tryParse(accountId);
    if (parentIdInt == null) return;
    final locs = await svc.fetchLocations(parentIdInt);
    if (locs.isEmpty) {
      await SecureStorage.saveLocation(id: '0', name: 'All Locations');
    } else {
      final firstLoc = locs.first;
      await SecureStorage.saveLocation(
        id: firstLoc.locationId.toString(),
        name: firstLoc.locationName,
      );
      String currency = firstLoc.currency ?? '';
      if (currency.isEmpty) {
        final fetched = await svc.fetchLocationCurrency(firstLoc.locationId);
        currency = fetched ?? '';
      }
      if (currency.isNotEmpty) {
        await SecureStorage.saveCurrency(currency);
      }
      await svc.fetchAndSaveNoOfTreadDepthReadings(firstLoc.locationId);
    }
  }

  void retry() {
    hasError.value = false;
    progress.value = 0.0;
    statusText.value = 'Starting...';
    _startDownload();
  }

  /// Call this from a "Sync Now" / manual refresh button anywhere in the
  /// app (e.g. Home screen) to force a full re-download, ignoring the
  /// freshness cache. Navigates to the Download screen to show progress.
  static Future<void> forceFullResync() async {
    await SecureStorage.clearAllSyncTimes();
    Get.offAllNamed(AppPages.DOWNLOAD);
  }
}