import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../inspection/vehicle_inspe_controller.dart';
import '../models/offline_hive_models.dart';
import '../utils/sync_service.dart';
import 'master_data_service.dart';
import 'offline_hive_service.dart';
import '../inspection/vehicle_inspe_service.dart';
import 'image_upload_service.dart';
import '../utils/api_logger.dart';
import '../controllers/all_tyre_controller.dart';
import '../models/tyre_model.dart';
import '../utils/hive_prefe.dart';
import '../utils/local_image_cache.dart';

// 🔧 DEBUG: tag "[SYNC-NET]" se console/logcat me filter karo
void _log(String msg) {
  debugPrint('[SYNC-NET] $msg');
}

class SyncCoordinator {
  static bool _busy = false;


  static Future<T> runExclusive<T>(Future<T> Function() job) async {
    if (_busy) {
      _log('runExclusive: ⏳ pehle se koi sync chal raha hai, WAIT kar rahe hain (max 60s)...');
    }
    int waited = 0;
    while (_busy && waited < 60000) {
      await Future.delayed(const Duration(milliseconds: 250));
      waited += 250;
    }
    if (waited >= 60000) {
      _log('runExclusive: ⚠️ 60 sec wait ke baad bhi busy tha, aage badh rahe hain anyway');
    }
    _busy = true;
    _log('runExclusive: 🔒 LOCK liya, job start');
    try {
      final result = await job();
      _log('runExclusive: job complete, result=$result');
      return result;
    } finally {
      _busy = false;
      _log('runExclusive: 🔓 LOCK release');
    }
  }

  static bool get isBusy => _busy;
}

class ManualSyncService {
  static String? _baseUrl;
  static Future<String?> Function()? _getCookie;
  static bool _isSyncing = false;
  static StreamSubscription? _connectivitySub;

  static void setup({
    required String baseUrl,
    required Future<String?> Function() getCookie,
    bool enableAutoSync = true,
  }) {
    _baseUrl = baseUrl;
    _getCookie = getCookie;
    _log('setup: baseUrl=$baseUrl enableAutoSync=$enableAutoSync');
    if (enableAutoSync) _startConnectivityListener();
  }

  static void _startConnectivityListener() {
    _connectivitySub?.cancel();
    bool wasOffline = false;
    _log('_startConnectivityListener: connectivity listener START ho gaya');
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((results) async {
          final online = results.any((r) => r != ConnectivityResult.none);
          _log('connectivityChanged: online=$online (results=$results) wasOffline=$wasOffline');
          if (!online) {
            wasOffline = true;
            _log('connectivityChanged: OFFLINE ho gaye, flag set kiya');
            return;
          }
          if (wasOffline && online) {
            wasOffline = false;
            _log('connectivityChanged: ✅ OFFLINE -> ONLINE transition detect hua, 3 sec wait karke pending check karenge');
            await Future.delayed(const Duration(seconds: 3));
            final pending = pendingCount();
            _log('connectivityChanged: pendingCount=$pending isSyncing=$_isSyncing coordinatorBusy=${SyncCoordinator.isBusy}');

            if (pending > 0 && !_isSyncing && !SyncCoordinator.isBusy) {
              _log('connectivityChanged: 🔁 AUTO-SYNC TRIGGER ho raha hai (connectivity restore)');
              await syncNow();
            } else {
              _log('connectivityChanged: auto-sync SKIP (pending=$pending, isSyncing=$_isSyncing, busy=${SyncCoordinator.isBusy})');
            }
          }
        });
  }

  static void dispose() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _log('dispose: connectivity listener band kar diya');
  }

  //  🔘 (SYNC BUTTON / AUTO-SYNC dono yahi function call karte hain)
  static Future<SyncResult> syncNow() async {
    _log('🔘 syncNow() CALLED =====================================');
    return SyncCoordinator.runExclusive<SyncResult>(() async {
      if (_isSyncing) {
        _log('syncNow: ⚠️ already syncing hai, is call ko SKIP kar rahe hain');
        return SyncResult(alreadyRunning: true);
      }
      _isSyncing = true;
      final result = SyncResult();

      try {
        final online = await isOnline();
        _log('syncNow: isOnline=$online');
        if (!online) {
          result.errorMessage = 'No Internet, Please check your network.';
          _log('syncNow: ❌ NO INTERNET, sync abort');
          return result;
        }

        final prefs = await SharedPreferences.getInstance();
        final cookie = await _getCookie?.call() ?? '';
        _log('syncNow: cookie ${cookie.isEmpty ? "❌ EMPTY (login expired ho sakta hai)" : "✅ present"}');

        await _runAllOperationsAwaited(result, prefs, cookie);
        _log('syncNow: pehla pass complete -> success=${result.successCount} fail=${result.failCount} failedOps=${result.failedOps}');

        if (result.failCount > 0) {
          _log('syncNow: ${result.failCount} fail hue the, 1 sec baad RETRY pass chalayenge');
          await Future.delayed(const Duration(seconds: 1));
          final retryResult = SyncResult();
          await _runAllOperationsAwaited(retryResult, prefs, cookie);
          _log('syncNow: retry pass complete -> success=${retryResult.successCount} fail=${retryResult.failCount} failedOps=${retryResult.failedOps}');
          result.successCount += retryResult.successCount;
          result.failCount = retryResult.failCount;
          result.failedOps = retryResult.failedOps;
        }

        _log('syncNow: ============ FINAL: success=${result.successCount} fail=${result.failCount} isSuccess=${result.isSuccess} ============');

      } catch (e) {
        result.errorMessage = e.toString();
        _log('syncNow: ❌ EXCEPTION -> $e');
      } finally {
        _isSyncing = false;
      }
      return result;
    });
  }


  static Future<void> _runAllOperationsAwaited(
      SyncResult result, SharedPreferences prefs, String cookie) async {
    final allOps = OfflineHiveService.getPendingOperations();
    _log('_runAllOperationsAwaited: total pending device ops = ${allOps.length}');

    if (allOps.isNotEmpty) {
      await _pushPendingOperationsWithCookie(result, prefs, cookie, allOps);
    }

    await _pushPendingInspections(result, cookieOverride: cookie);

    _log('_runAllOperationsAwaited: master data refresh trigger kar rahe hain (background)');
    MasterDataService().refreshMasterData().catchError((e) {
      _log('_runAllOperationsAwaited: master data refresh FAILED -> $e');
      return <String, dynamic>{};
    });
  }

  static Future<void> _pushPendingOperationsWithCookie(SyncResult result,
      SharedPreferences prefs, String cookie,
      List<PendingOperationHiveModel> allOps) async {
    if (allOps.isEmpty) {
      _log('_pushPendingOperationsWithCookie: koi pending op nahi, SKIP');
      return;
    }

    _log('_pushPendingOperationsWithCookie: START, total ops=${allOps.length}');

    final createVehicleOps =
    allOps.where((op) => op.opType == 'createVehicle').toList();
    final createTyreOps =
    allOps.where((op) => op.opType == 'createTyre').toList();
    final createUserOps =
    allOps.where((op) => op.opType == 'createUser').toList();
    final otherOps = allOps
        .where((op) =>
    op.opType != 'createVehicle' &&
        op.opType != 'createTyre' &&
        op.opType != 'createUser')
        .toList();
    _log('_pushPendingOperationsWithCookie: createVehicle=${createVehicleOps.length} createTyre=${createTyreOps.length} createUser=${createUserOps.length} other=${otherOps.length}');


    if (createUserOps.isNotEmpty) {
      _log('_pushPendingOperationsWithCookie: STAGE createUser (parallel) x${createUserOps.length}');
      await Future.wait(createUserOps.map((op) async {
        await _syncCreateUserOp(op, cookie, result);
      }), eagerError: false);
    }

    final Map<String, int> vehicleTempToReal = {};
    final Map<String, int> tyreTempToReal = {};

    final allKeys = prefs.getKeys();

    for (final key in allKeys) {
      if (key.startsWith('tyre_real_id_')) {
        final tempId = key.replaceFirst('tyre_real_id_', '');
        final realId = prefs.getInt(key);
        if (realId != null && realId > 0) {
          tyreTempToReal[tempId] = realId;
        }
      }
    }

    // Load persisted vehicle mappings
    for (final key in allKeys) {
      if (key.startsWith('vehicle_real_id_')) {
        final tempId = key.replaceFirst('vehicle_real_id_', '');
        final realId = prefs.getInt(key);
        if (realId != null && realId > 0) {
          vehicleTempToReal[tempId] = realId;
          OfflineHiveService.registerVehicleRealId(
              tempId: tempId, realId: realId);
        }
      }
    }
    _log('_pushPendingOperationsWithCookie: preloaded vehicleTempToReal=${vehicleTempToReal.length} tyreTempToReal=${tyreTempToReal.length}');



    _log('_pushPendingOperationsWithCookie: STAGE createVehicle (parallel) x${createVehicleOps.length}');
    await Future.wait(createVehicleOps.map((op) async {
      try {
        final payload = Map<String, dynamic>.from(op.payload);
        final tempId = payload['vehicleId']?.toString();

        payload.remove('vehicleId');
        payload.remove('isPendingSync');

        _log('createVehicle[${op.id}]: calling API tempId=$tempId endpoint=${op.endpoint}');
        final realId = await _callApiGetId(
          endpoint: op.endpoint,
          method: op.httpMethod,
          payload: payload,
          cookie: cookie,
          idField: 'insertedId',
        );
        _log('createVehicle[${op.id}]: realId=$realId (${realId != null && realId > 0 ? "✅ SUCCESS" : "❌ FAIL"})');

        if (realId != null && realId > 0) {
          await OfflineHiveService.markOperationSynced(op.id);
          result.successCount++;
          if (tempId != null) {
            vehicleTempToReal[tempId] = realId;
            await OfflineHiveService.replaceVehicleTempId(
              tempId: int.tryParse(tempId) ?? 0,
              realId: realId,
            );

            await prefs.setInt('vehicle_real_id_$tempId', realId);
            OfflineHiveService.registerVehicleRealId(
                tempId: tempId, realId: realId);
            _log('createVehicle[${op.id}]: tempId=$tempId -> realId=$realId map/persist ho gaya');

            await Future.wait([
              _migrateDeltaKeys(
                  tempId: tempId, realId: realId.toString(), prefs: prefs),
              _migrateInspectionCache(
                  tempId: tempId, realId: realId.toString()),
            ]);

            try {
              if (Get.isRegistered<VehicleInspeController>()) {
                final ctrl = Get.find<VehicleInspeController>();
                if (ctrl.vehicleId.value == tempId) {
                  ctrl.vehicleId.value = realId.toString();
                  ctrl.fetchInspectionData();
                }
              }
            } catch (_) {}
          }
        } else {
          await OfflineHiveService.incrementRetryCount(op.id,
              error: 'No insertedId');
          result.failCount++;
          result.failedOps.add(op.opType);
        }
      } catch (e) {
        _log('createVehicle[${op.id}]: ❌ EXCEPTION -> $e');
        await OfflineHiveService.incrementRetryCount(op.id,
            error: e.toString());
        result.failCount++;
        result.failedOps.add(op.opType);
      }
    }), eagerError: false);

    // ⚡ Speed fix: ye bhi pehle sequential for-await tha, ab parallel.
    _log('_pushPendingOperationsWithCookie: STAGE createTyre (parallel) x${createTyreOps.length}');
    await Future.wait(createTyreOps.map((op) async {
      try {
        final payload = Map<String, dynamic>.from(op.payload);
        final tempId = payload['tireId']?.toString();

        payload.remove('tireId');
        payload.remove('mountedRimId');
        payload.remove('isPendingSync');
        payload.remove('serialNumber');
        payload.remove('tireSizeId');
        payload.remove('tireTypeId');
        payload.remove('dispositionName');
        payload.remove('tireTypeName');
        payload.remove('manufacturerName');
        payload.remove('tireSizeName');
        payload.remove('tireStatusName');
        payload.remove('vehicleId');

        final rawMileage = payload['mileageType'];
        if (rawMileage is int) {
          payload['mileageType'] = rawMileage.toString();
        }
        if (payload['mileageType'] == null ||
            payload['mileageType'].toString().isEmpty) {
          payload['mileageType'] = '1';
        }

        final rawDate = payload['registeredDate']?.toString();
        if (rawDate != null && rawDate.contains('.')) {
          payload['registeredDate'] = rawDate.split('.')[0];
        }

        payload['isMountToRim'] ??= false;
        payload['recommendedPressure'] ??= 0.0;
        payload['currentPressure'] ??= 0.0;
        payload['repairCount'] ??= 0;
        payload['retreadCount'] ??= 0;
        payload['isEditable'] ??= false;

        final treadKeys = [
          'removeAt', 'originalTread', 'purchasedTread',
          'outsideTread', 'middleTread', 'insideTread',
          'averageTreadDepth', 'currentTreadDepth',
          'currentHours', 'currentMiles', 'percentageWorn',
          'purchaseCost', 'casingValue', 'fillCost',
          'repairCost', 'retreadCost', 'warrantyAdjustment',
          'costAdjustment', 'soldAmount', 'netCost',
          'recommendedPressure', 'currentPressure',
        ];
        for (final key in treadKeys) {
          if (payload[key] == null) payload[key] = 0.0;
          if (payload[key] is String) {
            payload[key] = double.tryParse(payload[key]) ?? 0.0;
          }
        }

        final intKeys = [
          'starRatingId', 'plyId', 'indCodeId', 'compoundId',
          'loadRatingId', 'speedRatingId', 'fillTypeId',
          'dispositionId', 'tireStatusId', 'repairCount', 'retreadCount',
        ];
        for (final key in intKeys) {
          if (payload[key] == null) payload[key] = 0;
          if (payload[key] is String) {
            payload[key] = int.tryParse(payload[key]) ?? 0;
          }
        }

        _log('createTyre[${op.id}]: calling API tempId=$tempId endpoint=${op.endpoint}');
        final realId = await _callApiGetId(
          endpoint: op.endpoint,
          method: op.httpMethod,
          payload: payload,
          cookie: cookie,
          idField: 'insertedId',
        );
        _log('createTyre[${op.id}]: realId=$realId (${realId != null && realId > 0 ? "✅ SUCCESS" : "❌ FAIL"})');

        if (realId != null && realId > 0) {
          await OfflineHiveService.markOperationSynced(op.id);
          result.successCount++;
          if (tempId != null) {
            tyreTempToReal[tempId] = realId;
            await prefs.setInt('tyre_real_id_$tempId', realId);

            // 🖼️ Migrate tyre images in prefs from tempId to realId
            try {
              final tempTireImages = prefs.getStringList('inspect_tire_images_$tempId');
              if (tempTireImages != null && tempTireImages.isNotEmpty) {
                await prefs.setStringList('inspect_tire_images_$realId', tempTireImages);
                _log('createTyre[${op.id}]: migrated ${tempTireImages.length} image(s) from inspect_tire_images_$tempId to inspect_tire_images_$realId');
              }
            } catch (_) {}

            await OfflineHiveService.replaceTyreTempId(
              tempId: int.tryParse(tempId) ?? 0,
              realId: realId,
            );

            final rawVehicleIdForCache = op.payload['vehicleId']?.toString() ?? '';
            final resolvedVIdForCache = vehicleTempToReal[rawVehicleIdForCache] ??
                (rawVehicleIdForCache.isNotEmpty &&
                    !rawVehicleIdForCache.startsWith('-')
                    ? int.tryParse(rawVehicleIdForCache)
                    : null);
            if (resolvedVIdForCache != null) {
              await _migrateTireIdsInInspectionCache(
                vehicleId: resolvedVIdForCache.toString(),
                tyreTempToReal: {tempId: realId},
                prefs: prefs,
              );
            }

            try {
              if (Get.isRegistered<VehicleInspeController>()) {
                Get.find<VehicleInspeController>().fetchInspectionData();
              }
            } catch (_) {}

            // Update tyre vehicleId in hive if vehicleId was temp
            if (rawVehicleIdForCache.startsWith('-')) {
              final resolvedVehicleId =
              vehicleTempToReal[rawVehicleIdForCache];
              if (resolvedVehicleId != null) {
                await OfflineHiveService.updateTyreVehicleId(
                  tireId: realId,
                  vehicleId: resolvedVehicleId,
                );
              }
            }
          }
        } else {
          await OfflineHiveService.incrementRetryCount(op.id,
              error: 'No insertedId');
          result.failCount++;
          result.failedOps.add(op.opType);
        }
      } catch (e) {
        _log('createTyre[${op.id}]: ❌ EXCEPTION -> $e');
        await OfflineHiveService.incrementRetryCount(op.id,
            error: e.toString());
        result.failCount++;
        result.failedOps.add(op.opType);
      }
    }), eagerError: false);


    final updateVehicleOps =
    otherOps.where((op) => op.opType == 'updateVehicle').toList();
    final updateTyreOps =
    otherOps.where((op) => op.opType == 'updateTyre').toList();
    final remainingOps2Raw = otherOps
        .where((op) =>
    op.opType != 'updateVehicle' && op.opType != 'updateTyre')
        .toList();
    _log('_pushPendingOperationsWithCookie: STAGE updateVehicle=${updateVehicleOps.length} updateTyre=${updateTyreOps.length} remaining=${remainingOps2Raw.length}');

    final seenRotateKeys = <String>{};
    final remainingOps2 = <PendingOperationHiveModel>[];
    for (final op in remainingOps2Raw) {
      if (op.opType == 'rotateTireRemove' || op.opType == 'rotateTireInstall') {
        final p = Map<String, dynamic>.from(op.payload);
        final tId = p['tireId']?.toString() ?? '';
        final vId = p['vehicleId']?.toString() ?? '';
        final pos = p['wheelPosition']?.toString() ?? '';
        final key = '${op.opType}_${tId}_${vId}_$pos';
        if (seenRotateKeys.contains(key)) {
          _log('remainingOps2: DUPLICATE rotate op opId=${op.id} key=$key -> synced-mark karke SKIP');
          OfflineHiveService.markOperationSynced(op.id).catchError((_) {});
          continue;
        }
        seenRotateKeys.add(key);
      }
      remainingOps2.add(op);
    }

    await Future.wait([
      // ── updateVehicle parallel ──────────────────────────
      ...updateVehicleOps.map((op) async {
        try {
          final payload = Map<String, dynamic>.from(op.payload);
          payload.remove('isPendingSync');

          final vehicleIdStr = payload['vehicleId']?.toString() ?? '';
          if (vehicleIdStr.isNotEmpty) {
            if (vehicleTempToReal.containsKey(vehicleIdStr)) {
              payload['vehicleId'] = vehicleTempToReal[vehicleIdStr]!;
            } else {
              final spKey = 'vehicle_real_id_$vehicleIdStr';
              final persistedId = prefs.getInt(spKey);
              if (persistedId != null && persistedId > 0) {
                payload['vehicleId'] = persistedId;
                vehicleTempToReal[vehicleIdStr] = persistedId;
              } else if (vehicleIdStr.startsWith('-')) {
                _log('updateVehicle[${op.id}]: ❌ FAIL - vehicleId=$vehicleIdStr unresolved (createVehicle abhi sync nahi hua)');
                result.failCount++;
                result.failedOps.add('updateVehicle-unresolved');
                return;
              }
            }
          }

          _log('updateVehicle[${op.id}]: calling API vehicleId=${payload['vehicleId']}');
          final success = await _callApiWithBody(
            endpoint: op.endpoint,
            method: op.httpMethod,
            body: jsonEncode(payload),
            cookie: cookie,
          );
          _log('updateVehicle[${op.id}]: result=${success ? "✅ SUCCESS" : "❌ FAIL"}');

          if (success) {
            await OfflineHiveService.markOperationSynced(op.id);
            result.successCount++;
            final resolvedVId = payload['vehicleId'];
            if (resolvedVId != null) {
              final resolvedInt = resolvedVId is int
                  ? resolvedVId
                  : (int.tryParse(resolvedVId.toString()) ?? 0);
              if (resolvedInt > 0) {
                await OfflineHiveService.saveVehicleDetailCache(
                  resolvedInt,
                  jsonEncode({'didError': false, 'model': payload}),
                );
              }
            }
          } else {
            await OfflineHiveService.incrementRetryCount(op.id,
                error: 'API returned failure for updateVehicle');
            result.failCount++;
            result.failedOps.add('updateVehicle');
          }
        } catch (e) {
          _log('updateVehicle[${op.id}]: ❌ EXCEPTION -> $e');
          await OfflineHiveService.incrementRetryCount(op.id,
              error: e.toString());
          result.failCount++;
          result.failedOps.add('updateVehicle');
        }
      }),

      // ── updateTyre parallel ─────────────────────────────
      ...updateTyreOps.map((op) async {
        try {
          final payload = Map<String, dynamic>.from(op.payload);
          payload.remove('isPendingSync');
          payload.remove('tireStatusName');
          payload.remove('dispositionName');

          final rawTireId = payload['tireId'];
          if (rawTireId != null) {
            final tireIdStr = rawTireId.toString();
            if (tireIdStr.startsWith('-')) {
              final realTireId = tyreTempToReal[tireIdStr];
              if (realTireId != null) {
                payload['tireId'] = realTireId;
              } else {
                _log('updateTyre[${op.id}]: ❌ FAIL - tireId=$tireIdStr unresolved');
                result.failCount++;
                result.failedOps.add('updateTyre-unresolved');
                return;
              }
            }
          }

          final rawVehicleId = payload['vehicleId'];
          if (rawVehicleId != null) {
            final vIdStr = rawVehicleId.toString();
            if (vIdStr.startsWith('-')) {
              if (vehicleTempToReal.containsKey(vIdStr)) {
                payload['vehicleId'] = vehicleTempToReal[vIdStr];
              } else {
                final persistedId = prefs.getInt('vehicle_real_id_$vIdStr');
                if (persistedId != null) {
                  payload['vehicleId'] = persistedId;
                  vehicleTempToReal[vIdStr] = persistedId;
                } else {
                  payload.remove('vehicleId');
                }
              }
            }
          }

          final rawMileage = payload['mileageType'];
          if (rawMileage is int) {
            payload['mileageType'] = rawMileage.toString();
          }

          final treadKeys = [
            'removeAt', 'originalTread', 'purchasedTread',
            'outsideTread', 'middleTread', 'insideTread'
          ];
          for (final key in treadKeys) {
            if (payload[key] == null) payload[key] = 0.0;
          }

          _log('updateTyre[${op.id}]: calling API tireId=${payload['tireId']}');
          final success = await _callApiWithBody(
            endpoint: op.endpoint,
            method: op.httpMethod,
            body: jsonEncode(payload),
            cookie: cookie,
          );
          _log('updateTyre[${op.id}]: result=${success ? "✅ SUCCESS" : "❌ FAIL"}');

          if (success) {
            await OfflineHiveService.markOperationSynced(op.id);
            result.successCount++;
            final tId = payload['tireId'];
            if (tId != null) {
              final tIdInt =
              tId is int ? tId : (int.tryParse(tId.toString()) ?? 0);
              if (tIdInt > 0) {
                await Future.wait([
                  OfflineHiveService.updateTyreInBox(tIdInt, payload),
                  OfflineHiveService.saveTireDetailCache(
                    tIdInt,
                    jsonEncode({'didError': false, 'model': payload}),
                  ),
                  OfflineHiveService.patchTireInAllInspectionCaches(
                      tIdInt, payload),
                ]);
              }
            }
            if (Get.isRegistered<AllTyreController>()) {
              try {
                Get.find<AllTyreController>().reapplyFilters();
              } catch (_) {}
            }
          } else {
            await OfflineHiveService.incrementRetryCount(op.id,
                error: 'API returned failure for updateTyre');
            result.failCount++;
            result.failedOps.add('updateTyre');
          }
        } catch (e) {
          _log('updateTyre[${op.id}]: ❌ EXCEPTION -> $e');
          await OfflineHiveService.incrementRetryCount(op.id,
              error: e.toString());
          result.failCount++;
          result.failedOps.add('updateTyre');
        }
      }),
    ], eagerError: false);

    for (final key in prefs.getKeys()) {
      if (key.startsWith('tyre_real_id_')) {
        final tempKey = key.replaceFirst('tyre_real_id_', '');
        final realId = prefs.getInt(key);
        if (realId != null && realId > 0 && !tyreTempToReal.containsKey(tempKey)) {
          tyreTempToReal[tempKey] = realId;
        }
      }
    }

    remainingOps2.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final Map<String, List<PendingOperationHiveModel>> opGroups = {};
    for (final op in remainingOps2) {
      final groupKey = op.payload['tireId']?.toString() ?? op.id;
      opGroups.putIfAbsent(groupKey, () => []).add(op);
    }
    _log('_pushPendingOperationsWithCookie: STAGE remaining ops (${remainingOps2.length}) grouped into ${opGroups.length} tireId-group(s), har group sequential par groups parallel');

    await Future.wait(
      opGroups.values.map((group) async {
        for (final op in group) {
          try {
            final payload = Map<String, dynamic>.from(op.payload);

            final rawTireId = payload['tireId'];
            if (rawTireId != null) {
              final tireIdStr = rawTireId.toString();
              if (tireIdStr.startsWith('-')) {
                final realTireId = tyreTempToReal[tireIdStr];
                if (realTireId == null) {
                  _log('${op.opType}[${op.id}]: ❌ FAIL - waiting for createTyre sync (tempTireId=$tireIdStr)');
                  await OfflineHiveService.incrementRetryCount(
                    op.id,
                    error:
                    'Waiting for createTyre to sync (tempTireId=$tireIdStr)',
                  );
                  result.failCount++;
                  result.failedOps
                      .add('${op.opType}(tireId not resolved)');
                  return;
                }
                payload['tireId'] = realTireId;
              }
            }

            // Approval-flow (temp/direct) batched payload: negative vehicleId /
            // tireId nested lists ke andar hoti hai, top-level par nahi.
            if (op.opType == 'vehicleInspectApprovalTemp' ||
                op.opType == 'vehicleInspectDirect') {
              final resolved = await OfflineHiveService.resolveBatchedTempIds(
                payload,
                vehicleMap: vehicleTempToReal,
                tyreMap: tyreTempToReal,
              );
              if (resolved == null) {
                _log('${op.opType}[${op.id}]: ❌ FAIL - waiting for createVehicle/createTyre sync (nested temp ids unresolved)');
                await OfflineHiveService.incrementRetryCount(
                  op.id,
                  error: 'Waiting for createVehicle/createTyre to sync',
                );
                result.failCount++;
                result.failedOps.add('${op.opType}(temp ids not resolved)');
                return;
              }
              payload
                ..clear()
                ..addAll(resolved);
            }

            final rawVehicleId = payload['vehicleId'];
            if (rawVehicleId != null) {
              final vIdStr = rawVehicleId.toString();
              if (vIdStr.startsWith('-')) {
                final realVehicleId = vehicleTempToReal[vIdStr];
                if (realVehicleId == null) {
                  _log('${op.opType}[${op.id}]: ❌ FAIL - waiting for createVehicle sync (tempVehicleId=$vIdStr)');
                  await OfflineHiveService.incrementRetryCount(
                    op.id,
                    error:
                    'Waiting for createVehicle to sync (tempVehicleId=$vIdStr)',
                  );
                  result.failCount++;
                  result.failedOps
                      .add('${op.opType}(vehicleId not resolved)');
                  return;
                }
                payload['vehicleId'] = realVehicleId;
              }
            }

            if (op.opType == 'inspectTyre') {
              final vId = payload['vehicleId'];
              if (vId == null || vId == 0 || vId.toString() == 'null') {
                final tId = payload['tireId'];
                if (tId != null) {
                  final tireIdInt =
                  tId is int ? tId : (int.tryParse(tId.toString()) ?? 0);
                  final hiveTyre = OfflineHiveService.getTyreById(tireIdInt);
                  var vehId = hiveTyre?.vehicleId;
                  if (vehId == null || vehId == 0) {
                    try {
                      final allKeys2 =
                      OfflineHiveService.listInspectionCacheKeys();
                      for (final key in allKeys2) {
                        final cached =
                        OfflineHiveService.getInspectionCache(key);
                        if (cached == null) continue;
                        final jsonData =
                        jsonDecode(cached) as Map<String, dynamic>;
                        final innerModel =
                        jsonData['model'] as Map<String, dynamic>?;
                        if (innerModel == null) continue;
                        final tires =
                        innerModel['installedTires'] as List<dynamic>?;
                        if (tires == null) continue;
                        final found = tires.any(
                              (t) =>
                          t is Map &&
                              t['tireId']?.toString() ==
                                  tireIdInt.toString(),
                        );
                        if (found) {
                          vehId = int.tryParse(key);
                          break;
                        }
                      }
                    } catch (_) {}
                  }
                  if (vehId != null && vehId != 0) {
                    payload['vehicleId'] = vehId;
                    _log('inspectTyre[${op.id}]: vehicleId cache se recover kiya = $vehId');
                  } else {
                    _log('inspectTyre[${op.id}]: ❌ FAIL - vehicleId null hi raha, recover nahi ho paya');
                    await OfflineHiveService.incrementRetryCount(op.id,
                        error: 'vehicleId null in inspectTyre payload');
                    result.failCount++;
                    result.failedOps.add('inspectTyre(vehicleId null)');
                    return;
                  }
                }
              }
            }

            if (op.opType == 'vehicleInspect') {
              // Same rule as online: API images only. Local photos are
              // uploaded now, merged with the images already on the server.
              try {
                final vIdForImages = payload['vehicleId']?.toString() ?? '';
                if (vIdForImages.isNotEmpty) {
                  final prefList =
                      prefs.getStringList('vehicle_images_$vIdForImages') ?? [];
                  final merged = await _syncMergeVehicleImages(
                    vehicleId: vIdForImages,
                    sources: [
                      payload['imagesLocation']?.toString(),
                      prefList.join(','),
                    ],
                  );
                  if (merged != null) {
                    payload['imagesLocation'] = merged;
                    await prefs.setStringList(
                        'vehicle_images_$vIdForImages', merged.split(','));
                    _log('vehicleInspect[${op.id}]: image upload ✅ SUCCESS -> $merged');
                  }
                }
              } catch (e) {
                _log('vehicleInspect[${op.id}]: image upload ❌ EXCEPTION -> $e');
              }
            }

            if (op.opType == 'inspectTyre') {
              try {
                final tireIdForImages = payload['tireId']?.toString() ?? '';
                final tireIdInt = int.tryParse(tireIdForImages) ?? 0;
                if (tireIdInt > 0) {
                  final prefList =
                      prefs.getStringList('inspect_tire_images_$tireIdForImages') ?? [];
                  final merged = await _syncMergeTyreImages(
                    tireId: tireIdInt,
                    sources: [
                      payload['imagesLocation']?.toString(),
                      prefList.join(','),
                    ],
                  );
                  if (merged != null) {
                    payload['imagesLocation'] = merged;
                    final combined = <String>{
                      ...merged.split(','),
                      ...prefList.where((p) => !p.startsWith('http')),
                    }.toList();
                    await prefs.setStringList(
                        'inspect_tire_images_$tireIdForImages', combined);
                    _log('inspectTyre[${op.id}]: image upload ✅ SUCCESS -> $merged');
                  }
                }
              } catch (e) {
                _log('inspectTyre[${op.id}]: image upload ❌ EXCEPTION -> $e');
              }
            }

            if (op.opType == 'vehicleInspectApprovalTemp' ||
                op.opType == 'vehicleInspectDirect') {
              try {
                // 1. Vehicle images (local photos + images already on server)
                final vehicleList = payload['vehicleList'] as List?;
                if (vehicleList != null && vehicleList.isNotEmpty && vehicleList.first is Map) {
                  final vMap = vehicleList.first as Map<String, dynamic>;
                  final vId = vMap['vehicleId']?.toString() ?? payload['vehicleId']?.toString() ?? '';
                  if (vId.isNotEmpty) {
                    final prefList = prefs.getStringList('vehicle_images_$vId') ??
                        prefs.getStringList('pending_images_$vId') ?? [];
                    final merged = await _syncMergeVehicleImages(
                      vehicleId: vId,
                      sources: [vMap['imagesLocation']?.toString(), prefList.join(',')],
                    );
                    if (merged != null) {
                      vMap['imagesLocation'] = merged;
                      payload['imagesLocation'] = merged;
                      final combined = <String>{
                        ...merged.split(','),
                        ...prefList.where((p) => !p.startsWith('http')),
                      }.toList();
                      await prefs.setStringList('vehicle_images_$vId', combined);
                      await prefs.setStringList('pending_images_$vId', combined);
                      _log('${op.opType}[${op.id}]: vehicle image upload ✅ SUCCESS -> $merged');
                    }
                  }
                }

                // 2. Tyre images across tireList and inspectionList
                final tireList = payload['tireList'] as List?;
                final inspList = payload['inspectionList'] as List?;
                final List<Map<String, dynamic>> allTireRecords = [
                  if (tireList != null) ...tireList.whereType<Map<String, dynamic>>(),
                  if (inspList != null) ...inspList.whereType<Map<String, dynamic>>(),
                ];
                final Map<int, String> uploadedByTire = {};

                for (final tRecord in allTireRecords) {
                  final rawTid = tRecord['tireId']?.toString() ?? '';
                  if (rawTid.isEmpty) continue;
                  int? tIdInt = int.tryParse(rawTid);
                  if (tIdInt == null || tIdInt <= 0) {
                    tIdInt = tyreTempToReal[rawTid] ?? prefs.getInt('tyre_real_id_$rawTid');
                  }
                  if (tIdInt == null || tIdInt <= 0) continue;

                  // same tyre appears in tireList AND inspectionList -> upload once
                  if (uploadedByTire.containsKey(tIdInt)) {
                    tRecord['imagesLocation'] = uploadedByTire[tIdInt];
                    continue;
                  }

                  final fromReal = prefs.getStringList('inspect_tire_images_$tIdInt') ?? [];
                  final fromTemp = prefs.getStringList('inspect_tire_images_$rawTid') ?? [];
                  final merged = await _syncMergeTyreImages(
                    tireId: tIdInt,
                    sources: [
                      tRecord['imagesLocation']?.toString(),
                      fromReal.join(','),
                      fromTemp.join(','),
                    ],
                  );
                  if (merged != null) {
                    tRecord['imagesLocation'] = merged;
                    uploadedByTire[tIdInt] = merged;
                    final combined = <String>{
                      ...merged.split(','),
                      ...fromReal.where((p) => !p.startsWith('http')),
                      ...fromTemp.where((p) => !p.startsWith('http')),
                    }.toList();
                    await prefs.setStringList('inspect_tire_images_$tIdInt', combined);
                    await prefs.setStringList('inspect_tire_images_$rawTid', combined);
                    _log('${op.opType}[${op.id}]: tyre image upload ✅ SUCCESS -> $merged');
                  }
                }
              } catch (e) {
                _log('${op.opType}[${op.id}]: inspection image sync ❌ error -> $e');
              }
            }

            if (op.opType == 'installTyre' ||
                op.opType == 'inspectTyre' ||
                op.opType == 'vehicleInspect' ||
                op.opType == 'rotateTireRemove' ||
                op.opType == 'rotateTireInstall') {
              final existingRim = payload['rimDispositionId'];
              if (existingRim == null ||
                  existingRim == '' ||
                  existingRim == 0) {
                payload['rimDispositionId'] = 0;
              }
              payload.remove('isPendingSync');
            } else if (op.opType == 'updateHours') {
              if (payload['inspectionDate'] is DateTime) {
                payload['inspectionDate'] =
                    (payload['inspectionDate'] as DateTime).toIso8601String();
              }
              payload.remove('isPendingSync');
            } else {
              payload.remove('isPendingSync');
            }

            final apiBody =
            (op.opType == 'removeTyre' || op.opType == 'rotateTireRemove')
                ? jsonEncode([payload])
                : jsonEncode(payload);

            _log('${op.opType}[${op.id}]: calling API endpoint=${op.endpoint} vehicleId=${payload['vehicleId']} tireId=${payload['tireId']}');
            final success = await _callApiWithBody(
              endpoint: op.endpoint,
              method: op.httpMethod,
              body: apiBody,
              cookie: cookie,
            );
            _log('${op.opType}[${op.id}]: result=${success ? "✅ SUCCESS" : "❌ FAIL"}');

            if (success) {
              await OfflineHiveService.markOperationSynced(op.id);
              result.successCount++;

              if (op.opType == 'removeTyre' ||
                  op.opType == 'rotateTireRemove' ||
                  op.opType == 'installTyre' ||
                  op.opType == 'rotateTireInstall') {
                OfflineHiveService.notifyPostSyncTyreListenersExternal();
              }

              final rawVId = payload['vehicleId'];
              final vId = rawVId?.toString() ?? '';
              if (vId.isNotEmpty) {
                await prefs.setInt(
                  'cache_protected_$vId',
                  DateTime.now().millisecondsSinceEpoch,
                );
              }

              if (op.opType == 'removeTyre' ||
                  op.opType == 'rotateTireRemove') {
                try {
                  final tireId = payload['tireId'];
                  final dispId = payload['dispositionId'] ?? 8;
                  final dispName = payload['dispositionName'] != null &&
                      payload['dispositionName'].toString().isNotEmpty
                      ? payload['dispositionName'].toString()
                      : 'Inventory';
                  final tIdInt = tireId is int
                      ? tireId
                      : (int.tryParse(tireId.toString()) ?? 0);
                  final resolvedDispId = dispId is int
                      ? dispId
                      : (int.tryParse(dispId.toString()) ?? 8);

                  if (tIdInt > 0) {
                    OfflineHiveService.markTireAsRecentlyRemoved(tIdInt);
                  }

                  if (tIdInt > 0) {
                    await OfflineHiveService.updateTyreDisposition(
                      tireId: tIdInt,
                      dispositionId: resolvedDispId,
                      dispositionName: dispName,
                      vehicleId: 0,
                      wheelPosition: '',
                    );
                  }

                  if (Get.isRegistered<AllTyreController>()) {
                    final allTyreCtrl = Get.find<AllTyreController>();
                    final idx = allTyreCtrl.allTyres
                        .indexWhere((t) => t.tireId == tIdInt);
                    if (idx != -1) {
                      final old = allTyreCtrl.allTyres[idx];
                      allTyreCtrl.allTyres[idx] = TyreModel(
                        tireId: old.tireId,
                        tireSerialNo: old.tireSerialNo,
                        brandNo: old.brandNo,
                        sizeName: old.sizeName,
                        sizeId: old.sizeId,
                        typeName: old.typeName,
                        typeId: old.typeId,
                        tireStatusName: dispName,
                        vehicleId: null,
                        vehicleNumber: null,
                        wheelPosition: null,
                        dispositionId: resolvedDispId,
                        dispositionName: dispName,
                        dispositionGroupId: old.dispositionGroupId,
                        manufacturerName: old.manufacturerName,
                        manufacturerId: old.manufacturerId,
                        currentTreadDepth: old.currentTreadDepth,
                        outsideTread: old.outsideTread,
                        insideTread: old.insideTread,
                        currentPressure: old.currentPressure,
                        inspectionDate: old.inspectionDate,
                        evaluationNo: old.evaluationNo,
                        lotNo: old.lotNo,
                        poNo: old.poNo,
                        mileageType: old.mileageType,
                        currentHours: old.currentHours,
                        currentMiles: old.currentMiles,
                        originalTread: old.originalTread,
                        purchasedTread: old.purchasedTread,
                        removeAt: old.removeAt,
                        starRatingId: old.starRatingId,
                        compoundId: old.compoundId,
                        loadRatingId: old.loadRatingId,
                        speedRatingId: old.speedRatingId,
                        fillTypeId: old.fillTypeId,
                        purchaseCost: old.purchaseCost,
                        casingValue: old.casingValue,
                        fillCost: old.fillCost,
                        repairCost: old.repairCost,
                        retreadCost: old.retreadCost,
                        costAdjustment: old.costAdjustment,
                        netCost: old.netCost,
                      );
                      allTyreCtrl.allTyres.refresh();
                      allTyreCtrl.reapplyFilters();

                    } else {
                      allTyreCtrl.reapplyFilters();
                    }
                  }
                } catch (_) {
                }
              }

              if (op.opType == 'installTyre' ||
                  op.opType == 'vehicleInspect' ||
                  op.opType == 'inspectTyre' ||
                  op.opType == 'rotateTireRemove' ||
                  op.opType == 'rotateTireInstall') {
                if (op.opType == 'installTyre' ||
                    op.opType == 'rotateTireInstall') {
                  try {
                    final rawTireIdForInstall = payload['tireId'];
                    final rawVIdForInstall = payload['vehicleId'];
                    final wheelPosForInstall = payload['wheelPosition']?.toString() ?? '';
                    if (rawTireIdForInstall != null) {
                      final tIdInstall = rawTireIdForInstall is int
                          ? rawTireIdForInstall
                          : (int.tryParse(rawTireIdForInstall.toString()) ?? 0);
                      final vIdInstall = rawVIdForInstall is int
                          ? rawVIdForInstall
                          : (int.tryParse(rawVIdForInstall?.toString() ?? '0') ?? 0);
                      if (tIdInstall > 0) {
                        await OfflineHiveService.updateTyreDisposition(
                          tireId: tIdInstall,
                          dispositionId: 7,
                          dispositionName: 'Installed',
                          vehicleId: vIdInstall,
                          wheelPosition: wheelPosForInstall,
                        );


                        try {
                          if (Get.isRegistered<AllTyreController>()) {
                            final allTyreCtrl = Get.find<AllTyreController>();
                            final idx = allTyreCtrl.allTyres
                                .indexWhere((t) => t.tireId == tIdInstall);
                            if (idx != -1) {
                              final old = allTyreCtrl.allTyres[idx];
                              final vehNum = vIdInstall > 0
                                  ? OfflineHiveService
                                  .getVehicleById(vIdInstall)
                                  ?.vehicleNumber
                                  : null;
                              allTyreCtrl.allTyres[idx] = TyreModel(
                                tireId: old.tireId,
                                tireSerialNo: old.tireSerialNo,
                                brandNo: old.brandNo,
                                sizeName: old.sizeName,
                                sizeId: old.sizeId,
                                typeName: old.typeName,
                                typeId: old.typeId,
                                tireStatusName: 'Installed',
                                vehicleId: vIdInstall > 0 ? vIdInstall : null,
                                vehicleNumber: vehNum,
                                wheelPosition: wheelPosForInstall.isEmpty
                                    ? null
                                    : wheelPosForInstall,
                                dispositionId: 7,
                                dispositionName: 'Installed',
                                dispositionGroupId: old.dispositionGroupId,
                                manufacturerName: old.manufacturerName,
                                manufacturerId: old.manufacturerId,
                                currentTreadDepth: old.currentTreadDepth,
                                outsideTread: old.outsideTread,
                                insideTread: old.insideTread,
                                currentPressure: old.currentPressure,
                                inspectionDate: old.inspectionDate,
                                evaluationNo: old.evaluationNo,
                                lotNo: old.lotNo,
                                poNo: old.poNo,
                                mileageType: old.mileageType,
                                currentHours: old.currentHours,
                                currentMiles: old.currentMiles,
                                originalTread: old.originalTread,
                                purchasedTread: old.purchasedTread,
                                removeAt: old.removeAt,
                                starRatingId: old.starRatingId,
                                compoundId: old.compoundId,
                                loadRatingId: old.loadRatingId,
                                speedRatingId: old.speedRatingId,
                                fillTypeId: old.fillTypeId,
                                purchaseCost: old.purchaseCost,
                                casingValue: old.casingValue,
                                fillCost: old.fillCost,
                                repairCost: old.repairCost,
                                retreadCost: old.retreadCost,
                                costAdjustment: old.costAdjustment,
                                netCost: old.netCost,
                              );
                              allTyreCtrl.allTyres.refresh();
                            }
                            allTyreCtrl.reapplyFilters();
                          }
                        } catch (_) {}
                      }
                    }
                  } catch (_) {
                  }
                }

                try {
                  final vId2 = payload['vehicleId'];
                  if (vId2 != null && vId2.toString().isNotEmpty) {
                    if (Get.isRegistered<VehicleInspeController>()) {
                      final ctrl = Get.find<VehicleInspeController>();
                      if (ctrl.vehicleId.value == vId2.toString()) {
                        ctrl.isOffline.value = false;
                      }
                    }
                    VehicleInspeService()
                        .getInspectionRecord(vId2.toString())
                        .catchError((_) => null);
                  }
                } catch (_) {}

                if (op.opType == 'inspectTyre') {
                  final uploadedLoc = payload['imagesLocation']?.toString() ?? '';
                  final rawTireId = payload['tireId'];
                  if (uploadedLoc.isNotEmpty && rawTireId != null) {
                    final tIdInt = rawTireId is int
                        ? rawTireId
                        : (int.tryParse(rawTireId.toString()) ?? 0);
                    if (tIdInt > 0) {
                      try {
                        await OfflineHiveService.updateTyreInBox(tIdInt, {
                          'imagesLocation': uploadedLoc,
                        });

                        final existing = OfflineHiveService.getTireDetailCache(tIdInt);
                        if (existing != null) {
                          try {
                            final map = jsonDecode(existing) as Map<String, dynamic>;
                            final model = map['model'] as Map<String, dynamic>?;
                            if (model != null) {
                              model['imagesLocation'] = uploadedLoc;
                              map['model'] = model;
                              await OfflineHiveService.saveTireDetailCache(
                                tIdInt,
                                jsonEncode(map),
                              );
                            }
                          } catch (_) {}
                        }

                        await OfflineHiveService.patchTireInAllInspectionCaches(
                          tIdInt,
                          {'imagesLocation': uploadedLoc},
                        );

                        await prefs.setStringList(
                          'inspect_tire_images_$tIdInt',
                          uploadedLoc
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.startsWith('http'))
                              .toList(),
                        );

                      } catch (_) {
                      }
                    }
                  }
                }
              }
            } else {
              await OfflineHiveService.incrementRetryCount(op.id,
                  error: 'API returned failure');
              result.failCount++;
              result.failedOps.add(op.opType);

              if (op.opType == 'inspectTyre' ||
                  op.opType == 'vehicleInspect') {
                try {
                  final vId3 = payload['vehicleId'];
                  if (vId3 != null) {
                    await OfflineHiveService.updateTireInInspectionCache(
                      vId3.toString(),
                      payload,
                    );
                  }
                } catch (_) {}
              }
            }
          } catch (e) {
            _log('${op.opType}[${op.id}]: ❌ EXCEPTION -> $e');
            await OfflineHiveService.incrementRetryCount(op.id,
                error: e.toString());
            result.failCount++;
            result.failedOps.add(op.opType);
          }
        }
      }),
      eagerError: false,
    );

    _log('_pushPendingOperationsWithCookie: DONE -> success=${result.successCount} fail=${result.failCount}');
  }

  static Future<void> _pushPendingInspections(SyncResult result,
      {String? cookieOverride}) async {
    final unsynced = SyncHiveService.getUnsyncedList();
    if (unsynced.isEmpty) {
      _log('_pushPendingInspections: koi legacy unsynced inspection nahi, SKIP');
      return;
    }

    _log('_pushPendingInspections: START, count=${unsynced.length}');
    final cookie = cookieOverride ?? await _getCookie?.call() ?? '';

    await Future.wait(
      unsynced.map((ins) async {
        try {
          final payload = ins.toMap();
          final vehicleIdStr = payload['vehicleId']?.toString() ?? '';
          final tireIdStr = payload['tireId']?.toString() ?? '';

          if (vehicleIdStr.startsWith('-') || tireIdStr.startsWith('-')) {
            _log('legacy[${ins.vehicleNumber}]: ❌ FAIL - abhi IDs resolve nahi hui (waiting)');
            result.failCount++;
            result.failedOps
                .add('inspection:${ins.vehicleNumber}(waiting for IDs)');
            return;
          }

          _log('legacy[${ins.vehicleNumber}]: calling API');
          final success = await _callApi(
            endpoint: '/api/Inspection/InspectTireMobile',
            method: 'POST',
            payload: payload,
            cookie: cookie,
          );
          _log('legacy[${ins.vehicleNumber}]: result=${success ? "✅ SUCCESS" : "❌ FAIL"}');

          if (success) {
            await SyncHiveService.markAsSynced(ins.id);
            result.successCount++;
          } else {
            result.failCount++;
            result.failedOps.add('inspection:${ins.vehicleNumber}');
          }
        } catch (e) {
          _log('legacy[${ins.vehicleNumber}]: ❌ EXCEPTION -> $e');
          result.failCount++;
        }
      }),
      eagerError: false,
    );
  }

  static Future<bool> _callApi({
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
    required String cookie,
  }) async {
    return _callApiWithBody(
      endpoint: endpoint,
      method: method,
      body: jsonEncode(payload),
      cookie: cookie,
    );
  }

  static Future<bool> _callApiWithBody({
    required String endpoint,
    required String method,
    required String body,
    required String cookie,
  }) async {
    if (_baseUrl == null) {
      _log('_callApiWithBody: ❌ FAIL - _baseUrl null hai (setup() call nahi hua?)');
      return false;
    }
    final uri = Uri.parse('$_baseUrl$endpoint');
    final hdrs = {
      'Content-Type': 'application/json',
      if (cookie.isNotEmpty) 'Cookie': cookie,
    };

    _log('_callApiWithBody: $method $uri body=$body');

    final resp = method.toUpperCase() == 'PUT'
        ? await http
        .put(uri, headers: hdrs, body: body)
        .timeout(const Duration(seconds: 30))
        : await http
        .post(uri, headers: hdrs, body: body)
        .timeout(const Duration(seconds: 30));

    _log('_callApiWithBody: <- status=${resp.statusCode} resp=${resp.body}');

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      _log('_callApiWithBody: ❌ non-2xx status');
    }
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }

  static Future<int?> _callApiGetId({
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
    required String cookie,
    required String idField,
  }) async {
    if (_baseUrl == null) {
      _log('_callApiGetId: ❌ FAIL - _baseUrl null hai');
      return null;
    }
    final uri = Uri.parse('$_baseUrl$endpoint');
    final hdrs = {
      'Content-Type': 'application/json',
      if (cookie.isNotEmpty) 'Cookie': cookie,
    };
    final body = jsonEncode(payload);
    _log('_callApiGetId: $method $uri body=$body');

    final resp = method.toUpperCase() == 'PUT'
        ? await http
        .put(uri, headers: hdrs, body: body)
        .timeout(const Duration(seconds: 30))
        : await http
        .post(uri, headers: hdrs, body: body)
        .timeout(const Duration(seconds: 30));

    _log('_callApiGetId: <- status=${resp.statusCode} resp=${resp.body}');

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      try {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map) {
          if (decoded['didError'] == true) {
            _log('_callApiGetId: ❌ didError=true -> ${decoded['message'] ?? decoded['errorMessage'] ?? ''}');
            return null;
          }
          final id = decoded[idField];
          if (id is int && id > 0) return id;
          if (id is String) return int.tryParse(id);
        }
      } catch (_) {}
    }

    if (resp.statusCode == 409 && endpoint.contains('/api/Tire')) {
      _log('_callApiGetId: 409 conflict, existing tyre id fetch karne ki koshish kar rahe hain (duplicate serial no)');
      final serialNo = payload['tireSerialNo']?.toString() ?? '';
      final accountId = payload['parentAccountId'];
      if (serialNo.isNotEmpty && accountId != null) {

        final existingId = await _fetchExistingTyreId(
          serialNo: serialNo,
          accountId: accountId.toString(),
          cookie: cookie,
        );
        _log('_callApiGetId: 409 recovery existingId=$existingId');
        if (existingId != null && existingId > 0) return existingId;
      }
    }

    return null;
  }

  /// Ek offline-queued `createUser` op ko backend par chalata hai:
  /// CreateUser -> CreateUserProfile -> AssignRole -> CreateUserPreference,
  /// sequentially, usi payload se jo `UserManagementController._saveUserOffline`
  /// ne banaya tha. Sirf saare 4 steps success hone par hi op ko
  /// `markOperationSynced` kiya jata hai — koi bhi step fail ho jaye to
  /// poora op retry ke liye pending hi rehta hai (agli sync pass me
  /// dubara try hoga).
  static Future<void> _syncCreateUserOp(
      PendingOperationHiveModel op, String cookie, SyncResult result) async {
    final payload = Map<String, dynamic>.from(op.payload);
    final username = payload['username']?.toString() ?? '';

    try {
      // ── Step 1: CreateUser ──
      String? userId = await _createUserStep(
        endpoint: op.endpoint,
        username: username,
        password: payload['password']?.toString() ?? '',
        email: payload['email']?.toString() ?? '',
        cookie: cookie,
      );

      // 409/"already exists" -> pichhle attempt me user ban chuka hai,
      // sirf profile/role/preference steps abhi baaki hain. Duplicate
      // error par bhi chain ko aage badhne dete hain (idempotent retry).
      userId ??= username;

      // ── Step 2: CreateUserProfile ──
      final profileOk = await _callApi(
        endpoint: '/api/UserProfile/CreateUserProfile',
        method: 'POST',
        cookie: cookie,
        payload: {
          'userId': userId,
          'firstName': payload['firstName'] ?? '',
          'middleName': payload['middleName'] ?? '',
          'lastName': payload['lastName'] ?? '',
          'emailAddress': payload['email'] ?? '',
          'phoneNumber': payload['phoneNumber'] ?? '',
          'countryCode': payload['countryCode'] ?? '',
          'userRole': payload['userRole'] ?? '',
          'updatedDate': DateTime.now().toIso8601String(),
        },
      );
      if (!profileOk) {
        throw Exception('CreateUserProfile failed');
      }

      // ── Step 3: AssignRole ──
      final roleOk = await _callApi(
        endpoint: '/Role/AssignRole',
        method: 'POST',
        cookie: cookie,
        payload: {
          'roleName': payload['roleName'] ?? payload['userRole'] ?? '',
          'username': username,
        },
      );
      if (!roleOk) {
        throw Exception('AssignRole failed');
      }

      // ── Step 4: CreateUserPreference (best-effort, jaisa online flow
      // me bhi hai — iski failure poore chain ko fail nahi karti) ──
      await _callApi(
        endpoint: '/api/UserPreferences/CreateUserPreference',
        method: 'POST',
        cookie: cookie,
        payload: {
          'userId': userId,
          'userLanguage': payload['userLanguage'] ?? '',
          'userMeasurementSystemValue':
          payload['userMeasurementSystemValue'] ?? '',
          'userPressureUnit': payload['userPressureUnit'] ?? '',
          'logoLocation': '',
          'updatedBy': username,
          'updatedDate': DateTime.now().toIso8601String(),
          'lastAccessedAccountId': payload['lastAccessedAccountId'] ?? 0,
          'lastAccessedLocationId': payload['lastAccessedLocationId'] ?? 0,
          'lastAccessedAccountName': payload['lastAccessedAccountName'] ?? '',
          'lastAccessedLocationName':
          payload['lastAccessedLocationName'] ?? '',
        },
      );

      await OfflineHiveService.markOperationSynced(op.id);
      result.successCount++;
      _log('createUser[${op.id}]: ✅ SUCCESS (username=$username)');
    } catch (e) {
      _log('createUser[${op.id}]: ❌ FAIL -> $e');
      await OfflineHiveService.incrementRetryCount(op.id, error: e.toString());
      result.failCount++;
      result.failedOps.add('createUser');
    }
  }

  /// CreateUser step ka apna handling chahiye kyunki response me userId
  /// alag-alag shape me aa sakta hai (String / model / userId / id), aur
  /// "duplicate username" (409/already exists) ko fail nahi, retry-safe
  /// treat karna hai.
  static Future<String?> _createUserStep({
    required String endpoint,
    required String username,
    required String password,
    required String email,
    required String cookie,
  }) async {
    if (_baseUrl == null) return null;
    final uri = Uri.parse('$_baseUrl$endpoint');
    final hdrs = {
      'Content-Type': 'application/json',
      if (cookie.isNotEmpty) 'Cookie': cookie,
    };
    final body = jsonEncode({
      'username': username,
      'password': password,
      'email': email,
    });

    final resp =
    await http.post(uri, headers: hdrs, body: body).timeout(const Duration(seconds: 30));
    _log('createUserStep: -> status=${resp.statusCode} resp=${resp.body}');

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      try {
        final decoded = jsonDecode(resp.body);
        if (decoded is String) return decoded;
        if (decoded is Map) {
          if (decoded['model'] != null) return decoded['model'].toString();
          if (decoded['userId'] != null) return decoded['userId'].toString();
          if (decoded['id'] != null) return decoded['id'].toString();
        }
      } catch (_) {}
      return username;
    }

    // Duplicate-username / already-exists -> treat as "already created",
    // let the chain continue with profile/role/preference steps.
    final lowerBody = resp.body.toLowerCase();
    if (resp.statusCode == 409 ||
        lowerBody.contains('already exist') ||
        lowerBody.contains('already registered')) {
      _log('createUserStep: user already exists -> continuing chain as idempotent retry');
      return username;
    }

    throw Exception('CreateUser failed (HTTP ${resp.statusCode}): ${resp.body}');
  }

  static Future<int?> _fetchExistingTyreId({
    required String serialNo,
    required String accountId,
    required String cookie,
  }) async {
    try {
      final uri =
      Uri.parse('$_baseUrl/api/Tire/GetTiresByAccount/$accountId');
      final resp = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (cookie.isNotEmpty) 'Cookie': cookie,
        },
      ).timeout(const Duration(seconds: 30));

      _log('_fetchExistingTyreId: status=${resp.statusCode}');

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);
        final List<dynamic> tyres = decoded is Map
            ? (decoded['model'] as List<dynamic>? ?? [])
            : (decoded is List ? decoded : []);

        for (final t in tyres) {
          if (t is Map &&
              t['tireSerialNo']?.toString().trim().toLowerCase() ==
                  serialNo.trim().toLowerCase()) {
            final id = t['tireId'];
            if (id is int && id > 0) return id;
            if (id is String) return int.tryParse(id);
          }
        }
      }
    } catch (e) {
      _log('_fetchExistingTyreId: ❌ EXCEPTION -> $e');
    }
    return null;
  }

  static Future<void> _migrateDeltaKeys({
    required String tempId,
    required String realId,
    required SharedPreferences prefs,
  }) async {
    try {
      final prefixes = [
        'vehicle_hours_delta_',
        'vehicle_km_delta_',
        'vehicle_prev_hours_',
        'vehicle_prev_km_',
        'tire_hours_delta_map_',
        'tire_km_delta_map_',
        'tire_comment_map_',
        'vehicle_comment_',
        'vehicle_images_',
        'server_hours_',
        'server_km_',
        'vehicle_dist_unit_',
      ];

      final oldUnit = HivePref.get<String>('vehicle_dist_unit_$tempId') ?? prefs.getString('vehicle_dist_unit_$tempId');
      if (oldUnit != null && oldUnit.isNotEmpty) {
        HivePref.set('vehicle_dist_unit_$realId', oldUnit);
        await prefs.setString('vehicle_dist_unit_$realId', oldUnit);
      }

      await Future.wait(prefixes.map((prefix) async {
        final oldKey = '$prefix$tempId';
        final newKey = '$prefix$realId';
        if (prefs.containsKey(oldKey)) {
          final val = prefs.get(oldKey);
          if (val is List<String>) {
            await prefs.setStringList(newKey, val);
          } else if (val is String) {
            await prefs.setString(newKey, val);
          } else if (val is double) {
            await prefs.setDouble(newKey, val);
          } else if (val is int) {
            await prefs.setInt(newKey, val);
          } else if (val is bool) {
            await prefs.setBool(newKey, val);
          }
        }
      }));

    } catch (_) {
    }
  }

  static Future<void> _migrateInspectionCache({
    required String tempId,
    required String realId,
  }) async {
    try {
      final oldCache = OfflineHiveService.getInspectionCache(tempId);
      if (oldCache != null) {
        await OfflineHiveService.saveInspectionCache(realId, oldCache);
        await OfflineHiveService.clearInspectionCache(tempId);
        _log('_migrateInspectionCache: tempId=$tempId -> realId=$realId cache migrate ho gaya');
      }
    } catch (_) {
    }
  }

  static Future<void> _migrateTireIdsInInspectionCache({
    required String vehicleId,
    required Map<String, int> tyreTempToReal,
    required SharedPreferences prefs,
  }) async {
    try {
      final cached = OfflineHiveService.getInspectionCache(vehicleId);
      if (cached == null) return;

      final map = jsonDecode(cached) as Map<String, dynamic>;
      final model = map['model'] as Map<String, dynamic>?;
      if (model == null) return;

      bool changed = false;

      final tires = model['installedTires'] as List<dynamic>?;
      if (tires != null) {
        for (int i = 0; i < tires.length; i++) {
          final tire = tires[i];
          if (tire is Map) {
            final tIdStr = tire['tireId']?.toString() ?? '';
            if (tIdStr.startsWith('-')) {
              int? realTireId = tyreTempToReal[tIdStr];
              realTireId ??= prefs.getInt('tyre_real_id_$tIdStr');
              if (realTireId != null && realTireId > 0) {
                (tires[i] as Map)['tireId'] = realTireId;
                changed = true;

              }
            }
          }
        }
      }

      final tireData = model['tireData'] as Map<String, dynamic>?;
      if (tireData != null) {
        final keysToMigrate = <String, String>{};
        for (final key in tireData.keys) {
          if (key.startsWith('-')) {
            int? realTireId = tyreTempToReal[key];
            realTireId ??= prefs.getInt('tyre_real_id_$key');
            if (realTireId != null && realTireId > 0) {
              keysToMigrate[key] = realTireId.toString();
            }
          }
        }
        for (final entry in keysToMigrate.entries) {
          tireData[entry.value] = tireData.remove(entry.key);
          changed = true;

        }
      }

      if (changed) {
        await OfflineHiveService.saveInspectionCache(
            vehicleId, jsonEncode(map));
        _log('_migrateTireIdsInInspectionCache: vehicleId=$vehicleId cache update ho gaya');
      }
    } catch (_) {
    }
  }

  static Future<bool> isOnline() async {
    final r = await Connectivity().checkConnectivity();
    if (!r.any((r) => r != ConnectivityResult.none)) {
      _log('isOnline: connectivity_plus khud bolta hai NONE -> false');
      return false;
    }

    // Run the HEAD check and DNS lookup in parallel instead of sequentially,
    // and use shorter timeouts so a slow/unreachable server doesn't stall
    // the sync button for several seconds before it even starts.
    Future<bool> headCheck() async {
      try {
        final uri = Uri.parse(_baseUrl ?? '');
        if (uri.host.isEmpty) return false;
        final response = await http
            .head(uri.replace(path: '/'))
            .timeout(const Duration(seconds: 2));
        _log('isOnline: HEAD check status=${response.statusCode}');
        return response.statusCode > 0;
      } catch (e) {
        _log('isOnline: HEAD check FAILED -> $e');
        return false;
      }
    }

    Future<bool> dnsCheck() async {
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 2));
        final ok = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        _log('isOnline: DNS check ok=$ok');
        return ok;
      } catch (e) {
        _log('isOnline: DNS check FAILED -> $e');
        return false;
      }
    }

    final results = await Future.wait([headCheck(), dnsCheck()]);
    final online = results.any((ok) => ok);
    _log('isOnline: FINAL = $online');
    return online;
  }

  static int pendingCount() {
    final c = OfflineHiveService.pendingOperationsCount() +
        SyncHiveService.unsyncedCount();
    _log('pendingCount() = $c');
    return c;
  }

  static bool get isSyncing => _isSyncing;
}

class SyncResult {
  int successCount = 0;
  int failCount = 0;
  List<String> failedOps = [];
  String? errorMessage;
  bool alreadyRunning;

  SyncResult({this.alreadyRunning = false});

  bool get isSuccess =>
      errorMessage == null && !alreadyRunning && failCount == 0;
  bool get hasPartialSuccess => successCount > 0 && failCount > 0;
  int get totalProcessed => successCount + failCount;

  @override
  String toString() =>
      'SyncResult(success=$successCount, fail=$failCount, alreadyRunning=$alreadyRunning, error=$errorMessage, failedOps=$failedOps)';
}

// ═══════════════════════════════════════════════════════════
//  Offline-sync image helpers — same behaviour as the online screens:
//   * local photos are uploaded (CreateImages, ONE multi-file request)
//   * photos already on the server are kept (http URLs)
//   * the record gets API URLs only, never device paths
// ═══════════════════════════════════════════════════════════
List<String> _syncHttpUrls(Iterable<String?> sources) => sources
    .expand((c) => (c ?? '').split(','))
    .map((e) => e.trim())
    .where((e) => e.startsWith('http'))
    .toSet()
    .toList();

List<File> _syncLocalFiles(Iterable<String?> sources) {
  final seen = <String>{};
  final out = <File>[];
  for (final c in sources) {
    for (final raw in (c ?? '').split(',')) {
      final p = raw.trim();
      if (p.isEmpty || p.startsWith('http') || !seen.add(p)) continue;
      final f = File(p);
      if (f.existsSync()) out.add(f);
    }
  }
  return out;
}

/// Uploads the local tyre photos (Tire/CreateImages) together with the
/// photos the tyre already has on the server. Returns the full comma
/// separated URL list, or null when there was nothing to upload / it failed.
Future<String?> _syncMergeTyreImages({
  required int tireId,
  required Iterable<String?> sources,
}) async {
  final local = _syncLocalFiles(sources);
  if (local.isEmpty) return null;
  final res = await ImageUploadService.uploadTireImagesKeepingExisting(
    tireId: tireId,
    newImages: local,
    existingUrls: _syncHttpUrls(sources),
  );
  if (!res.success) {
    ApiLog.error('SYNC Tire/CreateImages', 'tireId=$tireId upload failed -> ${res.error}');
    return null;
  }
  for (var i = 0; i < local.length; i++) {
    if (i < res.urls.length) {
      await LocalImageCache.associate(res.urls[i], local[i].path);
    }
  }
  return res.joined;
}

/// Uploads the local vehicle photos (Vehicle/CreateImages) and merges them
/// with the vehicle photos that are already on the server.
Future<String?> _syncMergeVehicleImages({
  required String vehicleId,
  required Iterable<String?> sources,
}) async {
  final local = _syncLocalFiles(sources);
  if (local.isEmpty) return null;
  final uploaded = await VehicleInspeService()
      .uploadInspectionImages(images: local, vehicleId: vehicleId);
  if (uploaded.isEmpty) {
    ApiLog.error('SYNC Vehicle/CreateImages', 'vehicleId=$vehicleId upload failed');
    return null;
  }
  final upList = uploaded.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  for (var i = 0; i < local.length; i++) {
    if (i < upList.length) {
      await LocalImageCache.associate(upList[i], local[i].path);
    }
  }
  return {
    ..._syncHttpUrls(sources),
    ...uploaded.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
  }.join(',');
}