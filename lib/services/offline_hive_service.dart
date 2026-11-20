import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/offline_hive_adaptive.dart';
import '../models/offline_hive_models.dart';

class OfflineHiveService {
  // ─── Box Names
  static const _masterBox = 'masterDataBox';
  static const _vehicleBox = 'vehicleBox';
  static const _tyreBox = 'tyreBox';
  static const _accountBox = 'accountBox';
  static const _locationBox = 'locationBox';
  static const _pendingBox = 'pendingOpsBox';
  static const _inspectionCacheBox = 'inspectionCacheBox';


  static final Map<String, int> _vehicleRealIdMap = {};

  static final Map<int, DateTime> _recentlyRemovedTireIds = {};

  static void markTireAsRecentlyRemoved(int tireId) {
    _recentlyRemovedTireIds[tireId] = DateTime.now();
  }

  static void _evictExpiredRemovedTires() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 5));
    _recentlyRemovedTireIds.removeWhere((_, ts) => ts.isBefore(cutoff));
  }

  static Set<int> getRecentlyRemovedTireIds() {
    _evictExpiredRemovedTires();
    return Set.unmodifiable(_recentlyRemovedTireIds.keys);
  }

  /// Reject ke baad tyre wapas apni jagah aa raha hai -> "recently removed"
  /// flag hata do, warna All Tyres / vehicle list me tyre hidden rehta hai.
  static void unmarkTireAsRecentlyRemoved(int tireId) {
    _recentlyRemovedTireIds.remove(tireId);
  }

  static bool isTireRecentlyRemoved(int tireId) {
    _evictExpiredRemovedTires();
    return _recentlyRemovedTireIds.containsKey(tireId);
  }

  static Map<String, int> getVehicleRealIdMappingsSync() =>
      Map.unmodifiable(_vehicleRealIdMap);

  static void registerVehicleRealId({required String tempId, required int realId}) {
    _vehicleRealIdMap[tempId] = realId;
  }

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter<MasterDataHiveModel>(MasterDataHiveModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter<VehicleHiveModel>(VehicleHiveModelAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter<TyreHiveModel>(TyreHiveModelAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter<AccountHiveModel>(AccountHiveModelAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter<LocationHiveModel>(LocationHiveModelAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter<PendingOperationHiveModel>(
        PendingOperationHiveModelAdapter(),
      );
    }

    await _openIfClosed<MasterDataHiveModel>(_masterBox);
    await _openIfClosed<VehicleHiveModel>(_vehicleBox);
    await _openIfClosed<TyreHiveModel>(_tyreBox);
    await _openIfClosed<AccountHiveModel>(_accountBox);
    await _openIfClosed<LocationHiveModel>(_locationBox);
    await _openIfClosed<PendingOperationHiveModel>(_pendingBox);
    await _openIfClosed<String>(_inspectionCacheBox);
  }


  static Future<void> _openIfClosed<T>(String name) async {
    if (!Hive.isBoxOpen(name)) {
      await Hive.openBox<T>(name);
    }
  }



  // ─── Box Getters
  static Box<MasterDataHiveModel> get _master =>
      Hive.box<MasterDataHiveModel>(_masterBox);
  static Box<VehicleHiveModel> get _vehicles =>
      Hive.box<VehicleHiveModel>(_vehicleBox);
  static Box<TyreHiveModel> get _tyres => Hive.box<TyreHiveModel>(_tyreBox);
  static Box<AccountHiveModel> get _accounts =>
      Hive.box<AccountHiveModel>(_accountBox);
  static Box<LocationHiveModel> get _locs =>
      Hive.box<LocationHiveModel>(_locationBox);
  static Box<PendingOperationHiveModel> get _pending =>
      Hive.box<PendingOperationHiveModel>(_pendingBox);
  static Box<String> get _inspCache => Hive.box<String>(_inspectionCacheBox);

  // ════════════════════════════════════════════════════════════
  //  MASTER DATA
  // ════════════════════════════════════════════════════════════

  static Future<void> saveMasterData(Map<String, dynamic> data) async {
    final box = Hive.box<MasterDataHiveModel>(_masterBox);

    final model = MasterDataHiveModel.fromApiMap(data);

    await box.put('master', model);
  }

  static MasterDataHiveModel? getMasterData() => _master.get('master');

  static bool hasMasterData() => _master.containsKey('master');

  static List<Map<String, dynamic>> getAxleConfigs() =>
      _castList(_master.get('master')?.axleConfigs);

  static List<Map<String, dynamic>> getCasingConditions() =>
      _castList(_master.get('master')?.casingConditions);

  static List<Map<String, dynamic>> getTireDispositions() =>
      _castList(_master.get('master')?.tireDispositions);

  static List<Map<String, dynamic>> getTireManufacturers() =>
      _castList(_master.get('master')?.tireManufacturers);

  static List<Map<String, dynamic>> getTireRemovalReasons() =>
      _castList(_master.get('master')?.tireRemovalReasons);

  static List<Map<String, dynamic>> getTireSizes() =>
      _castList(_master.get('master')?.tireSizes);

  static List<Map<String, dynamic>> getTireTypes() =>
      _castList(_master.get('master')?.tireTypes);

  static List<Map<String, dynamic>> getStarRatings() =>
      _castList(_master.get('master')?.starRatings);

  static List<Map<String, dynamic>> getPlyRatings() =>
      _castList(_master.get('master')?.plyRatings);

  static List<Map<String, dynamic>> getWearConditions() =>
      _castList(_master.get('master')?.wearConditions);

  static List<Map<String, dynamic>> getTireStatus() =>
      _castList(_master.get('master')?.tireStatus);

  static List<Map<String, dynamic>> getTireIndCodes() =>
      _castList(_master.get('master')?.tireIndCodes);

  static List<Map<String, dynamic>> getTireCompounds() =>
      _castList(_master.get('master')?.tireCompounds);

  static List<Map<String, dynamic>> getTireLoadRatings() =>
      _castList(_master.get('master')?.tireLoadRatings);

  static List<Map<String, dynamic>> getTireSpeedRatings() =>
      _castList(_master.get('master')?.tireSpeedRatings);

  static List<Map<String, dynamic>> getTireFillTypes() =>
      _castList(_master.get('master')?.tireFillTypes);

  static List<Map<String, dynamic>> getVehicleManufacturers() =>
      _castList(_master.get('master')?.vehicleManufacturers);

  static List<Map<String, dynamic>> getVehicleTypes() =>
      _castList(_master.get('master')?.vehicleTypes);

  static List<Map<String, dynamic>> getVehicleModels() =>
      _castList(_master.get('master')?.vehicleModels);

  static List<Map<String, dynamic>> getVehicleIcons() =>
      _castList(_master.get('master')?.vehicleIcons);

  // manufacturerId se filtered tireSizes
  static List<Map<String, dynamic>> getTireSizesByManufacturer(
      int manufacturerId,
      ) {
    return getTireSizes()
        .where((s) => s['tireManufacturerId'] == manufacturerId)
        .toList();
  }

  // ════════════════════════════════════════════════════════════
  //  VEHICLES
  // ════════════════════════════════════════════════════════════

  static Future<void> saveVehicles(List<Map<String, dynamic>> list) async {
    final box = Hive.box<VehicleHiveModel>(_vehicleBox);

    final serverIds = list
        .map((e) => e['vehicleId'])
        .where((id) => id != null)
        .toSet();

    final pendingVehicles = box.toMap().entries.where((e) {
      final v = e.value;
      if (v.isPendingSync != true) return false;
      if (serverIds.contains(v.vehicleId)) return false;
      return true;
    }).toList();

    final Map<int, Map<String, dynamic>> latestUpdatePayloads = {};
    try {
      final allOps = getAllPendingOps();
      for (final op in allOps) {
        if (op.isSynced) continue;
        if (op.opType != 'updateVehicle') continue;
        final vId = op.payload['vehicleId'];
        if (vId == null) continue;
        final id = vId is int ? vId : int.tryParse(vId.toString());
        if (id == null) continue;
        latestUpdatePayloads[id] = Map<String, dynamic>.from(
          op.payload.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
    } catch (_) {}

    await box.clear();

    final items = list.map((e) => VehicleHiveModel.fromMap(e)).toList();
    await box.addAll(items);

    for (final entry in pendingVehicles) {
      var pending = entry.value;
      final alreadyExists = box.values.any(
            (v) => v.vehicleId == pending.vehicleId,
      );
      if (!alreadyExists) {

        final updatePayload = latestUpdatePayloads[pending.vehicleId];
        if (updatePayload != null) {
          final merged = pending.toMap()..addAll(updatePayload);
          merged['isPendingSync'] = true;
          try {
            pending = VehicleHiveModel.fromMap(
              merged.map((k, v) => MapEntry(k.toString(), v)),
            );
          } catch (_) {}
        }
        await box.put(entry.key, pending);
      }
    }
  }
  static List<VehicleHiveModel> getVehicles({
    int? parentAccountId,
    int? locationId,
  }) {
    return _vehicles.values.where((v) {
      if (parentAccountId != null && v.parentAccountId != parentAccountId) {
        return false;
      }
      if (locationId != null && locationId != 0 && v.locationId != locationId) {
        return false;
      }
      return true;
    }).toList();
  }

  static List<VehicleHiveModel> getAllVehicles() => _vehicles.values.toList();

  /// True if we already have at least one cached vehicle for this account.
  /// Used to decide whether the download/sync screen can be skipped on
  /// login (see DownloadController / AuthController).
  static bool hasAnyVehicles({int? parentAccountId}) {
    if (parentAccountId == null) return _vehicles.values.isNotEmpty;
    return _vehicles.values.any((v) => v.parentAccountId == parentAccountId);
  }

  static VehicleHiveModel? getVehicleById(int vehicleId) {
    try {
      return _vehicles.values.firstWhere((e) => e.vehicleId == vehicleId);
    } catch (_) {
      return null;
    }
  }

  static int vehicleCount({int? parentAccountId}) {
    if (parentAccountId == null) return _vehicles.length;
    return _vehicles.values
        .where((v) => v.parentAccountId == parentAccountId)
        .length;
  }

  static Future<void> saveSingleVehicle(Map<String, dynamic> data) async {
    final v = VehicleHiveModel.fromMap(data);
    await _vehicles.put(v.vehicleId.toString(), v);
  }

  static Future<String> saveOfflineVehicle(Map<String, dynamic> data) async {
    final tempId = -(1 + (DateTime.now().millisecondsSinceEpoch % 2000000000));
    data['vehicleId'] = tempId;
    data['isPendingSync'] = true;
    final v = VehicleHiveModel.fromMap(data);
    await _vehicles.put(tempId.toString(), v);
    return tempId.toString();
  }

  static Future<void> deleteVehicle(int vehicleId) async {
    await _vehicles.delete(vehicleId.toString());
  }

  static Future<void> replaceVehicleTempId({
    required int tempId,
    required int realId,
  }) async {
    final existing = _vehicles.get(tempId.toString());
    if (existing == null) return;


    final updatedMap = <String, dynamic>{
      'vehicleId': realId,
      'vehicleNumber': existing.vehicleNumber,
      'typeName': existing.typeName,
      'manufacturerName': existing.manufacturerName,
      'tireSizeName': existing.tireSizeName,
      'tireSize': existing.tireSizeName,
      'axleConfig': existing.axleConfig,
      'axleConfigId': existing.axleConfigId,
      'trackingMethod': existing.trackingMethod,
      'mileageType': existing.mileageType,
      'currentHours': existing.currentHours,
      'currentMiles': existing.currentMiles,
      'tireCount': existing.tireCount,
      'parentAccountId': existing.parentAccountId,
      'locationId': existing.locationId,
      'isPendingSync': false,
      'savedAt': DateTime.now().toIso8601String(),


    };
    final updated = VehicleHiveModel.fromMap({
      ...updatedMap,
      'isPendingSync': false,
    });
    await _vehicles.delete(tempId.toString());
    await _vehicles.put(realId.toString(), updated);

    await _vehicles.delete(tempId.toString());
    await _vehicles.put(realId.toString(), updated);


    final oldCacheKey = 'insp_$tempId';
    final newCacheKey = 'insp_$realId';
    final cachedJson = _inspCache.get(oldCacheKey);
    if (cachedJson != null) {
      try {
        final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
        final model = decoded['model'] as Map<String, dynamic>?;
        if (model != null) {
          model['vehicleId'] = realId;
          decoded['model'] = model;
        }
        await _inspCache.put(newCacheKey, jsonEncode(decoded));
        await _inspCache.delete(oldCacheKey);
      } catch (e) {
        await _inspCache.put(newCacheKey, cachedJson);
        await _inspCache.delete(oldCacheKey);
      }
    }
  }

  static Future<void> replaceTyreTempId({
    required int tempId,
    required int realId,
  }) async {
    final existing = _tyres.get(tempId.toString());
    if (existing == null) return;

    final updatedMap = <String, dynamic>{
      'tireId': realId,
      'serialNumber': existing.serialNumber,
      'manufacturerId': existing.manufacturerId,
      'manufacturerName': existing.manufacturerName,
      'tireSizeId': existing.tireSizeId,
      'tireSizeName': existing.tireSizeName,
      'tireTypeId': existing.tireTypeId,
      'tireTypeName': existing.tireTypeName,
      'dispositionId': existing.dispositionId,
      'dispositionName': existing.dispositionName,
      'tireStatusId': existing.tireStatusId,
      'tireStatusName': existing.tireStatusName,
      'vehicleId': existing.vehicleId,
      'wheelPosition': existing.wheelPosition,
      'parentAccountId': existing.parentAccountId,
      'locationId': existing.locationId,
      'outsideTread': existing.outsideTread,
      'insideTread': existing.insideTread,
      'originalTread': existing.originalTread,
      'removeAt': existing.removeAt,
      'currentHours': existing.currentHours,
      'currentMiles': existing.currentMiles,
      'purchaseCost': existing.purchaseCost,
      'starRatingId': existing.starRatingId,
      'mileageType': existing.mileageType,
      'isPendingSync': false,
      'savedAt': DateTime.now().toIso8601String(),
    };

    final updated = TyreHiveModel.fromMap(updatedMap);
    await _tyres.delete(tempId.toString());
    await _tyres.put(realId.toString(), updated);

    final prefix = 'insp_';
    final keysToUpdate = _inspCache.keys
        .where((k) => k.toString().startsWith(prefix))
        .toList();

    for (final key in keysToUpdate) {
      final cachedJson = _inspCache.get(key.toString());
      if (cachedJson == null) continue;
      try {
        final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
        final model = decoded['model'] as Map<String, dynamic>?;
        if (model == null) continue;
        final installedTires = model['installedTires'] as List<dynamic>?;
        if (installedTires == null) continue;

        bool changed = false;
        for (int i = 0; i < installedTires.length; i++) {
          final t = installedTires[i];
          if (t is Map && t['tireId']?.toString() == tempId.toString()) {
            final updated = Map<String, dynamic>.from(t);
            updated['tireId'] = realId;
            installedTires[i] = updated;
            changed = true;
          }
        }

        if (changed) {
          model['installedTires'] = installedTires;
          decoded['model'] = model;
          await _inspCache.put(key.toString(), jsonEncode(decoded));

        }
      } catch (_) {
      }
    }

    final oldTireKey = 'tire_$tempId';
    final newTireKey = 'tire_$realId';
    final tireCached = _inspCache.get(oldTireKey);
    if (tireCached != null) {
      await _inspCache.put(newTireKey, tireCached);
      await _inspCache.delete(oldTireKey);
    }
  }

  static Future<void> updateTyreVehicleId({
    required int tireId,
    required int vehicleId,
  }) async {
    TyreHiveModel? t;
    try {
      t = _tyres.values.firstWhere((e) => e.tireId == tireId);
    } catch (_) {
      return;
    }
    t.vehicleId = vehicleId;
    await t.save();

  }

  static Future<void> clearVehicles() async => await _vehicles.clear();

  static Future<void> updateVehicleTireCount(int vehicleId, int delta) async {
    VehicleHiveModel? v;
    try {
      v = _vehicles.values.firstWhere((e) => e.vehicleId == vehicleId);
    } catch (_) {

      return;
    }
    final newCount = (v.tireCount + delta).clamp(0, 999);
    v.tireCount = newCount;
    await v.save();
  }

  /// Absolute tyre count set karta hai (delta nahi). Reject restore me use hota hai.
  static Future<void> setVehicleTireCount(int vehicleId, int count) async {
    VehicleHiveModel? v;
    try {
      v = _vehicles.values.firstWhere((e) => e.vehicleId == vehicleId);
    } catch (_) {
      return;
    }
    v.tireCount = count.clamp(0, 999);
    await v.save();
  }

  static Future<void> updateVehicleHours(
      int vehicleId,
      double hours,
      double miles, {
        String? lastRecordedDate,
      }) async {
    VehicleHiveModel? v;
    try {
      v = _vehicles.values.firstWhere((e) => e.vehicleId == vehicleId);
    } catch (_) {
      return;
    }
    if (hours > 0) v.currentHours = hours;
    if (miles > 0) v.currentMiles = miles;

    if (lastRecordedDate != null && lastRecordedDate.isNotEmpty) {
      v.lastRecordedDate = lastRecordedDate;
    }

    v.savedAt = DateTime.now().toIso8601String();
    await v.save();

  }

  static String _mileageTypeToStr(int trackingMethod) {
    switch (trackingMethod) {
      case 1: return 'Hours';
      case 2: return 'Distance';
      case 3: return 'Both';
      default: return 'Hours';
    }
  }


  static Future<void> addTireToInspectionCache(
      String vehicleId,
      Map<String, dynamic> tirePayload,
      ) async {
    final cached = getInspectionCache(vehicleId);
    Map<String, dynamic> jsonData;
    if (cached != null) {
      try {
        jsonData = jsonDecode(cached) as Map<String, dynamic>;
      } catch (_) {
        return;
      }
    } else {

      final vIdInt = int.tryParse(vehicleId);
      if (vIdInt == null) return;
      final h = getVehicleById(vIdInt);
      if (h == null) return;

      jsonData = {
        'didError': false,
        'message': 'Offline vehicle',
        'model': {
          'vehicleId': vIdInt,
          'vehicleNumber': h.vehicleNumber,
          'vehicleType': h.typeName ?? '',
          'vehicleModel': h.modelName ?? '',
          'axleConfig': h.axleConfig ?? '22',
          'vehicleManufacturer': h.manufacturerName ?? '',
          'tireSize': h.tireSizeName ?? '',
          'tireSizeId': h.tireSizeId ?? 0,
          'lastRecordedHours': h.currentHours,
          'lastRecordedMiles': h.currentMiles,
          'comments': h.severityComments ?? '',
          'vehicleMileageType': _mileageTypeToStr(h.trackingMethod ?? 1),
          'installedTires': <dynamic>[],
        },
      };
    }

    final model = jsonData['model'] as Map<String, dynamic>?;
    if (model == null) return;

    final List<dynamic> existingTires =
        (model['installedTires'] as List<dynamic>?) ?? [];

    final wheelPos = tirePayload['wheelPosition']?.toString() ?? '';
    existingTires.removeWhere((t) {
      final pos = (t is Map) ? t['wheelPosition']?.toString() ?? '' : '';
      return pos == wheelPos;
    });

    final newTire = <String, dynamic>{
      'tireId': tirePayload['tireId'],
      'tireSerialNo': tirePayload['tireSerialNo'],
      'wheelPosition': tirePayload['wheelPosition'],
      'outsideTread': tirePayload['outsideTread'] ?? 0.0,
      'middleTread': tirePayload['middleTread'] ?? 0.0,
      'insideTread': tirePayload['insideTread'] ?? 0.0,
      'currentTreadDepth': tirePayload['currentTreadDepth'] ?? 0.0,
      'currentPressure': tirePayload['currentPressure'] ?? 0.0,
      'currentHours': tirePayload['currentHours'] ?? 0.0,
      'currentMiles': tirePayload['currentMiles'] ?? 0.0,
      'dispositionId': tirePayload['dispositionId'] ?? 0,
      'percentageWorn': tirePayload['percentageWorn'] ?? 0.0,
      'brandNo': tirePayload['brandNo'] ?? '',
      'casingConditionId': tirePayload['casingConditionId'] ?? 0,
      'wearConditionId': tirePayload['wearConditionId'] ?? 0,
      'comments': tirePayload['comments'] ?? '',
      'inspectionDate':
      tirePayload['inspectionDate'] ?? DateTime.now().toIso8601String(),
      'action': tirePayload['action'] ?? 'Install',
      'manufacturerName': tirePayload['manufacturerName'] ?? '',
      'sizeName': tirePayload['sizeName'] ?? '',
      'typeName': tirePayload['typeName'] ?? '',
      'originalTread': tirePayload['originalTread'] ?? 0.0,
      'removeAt': tirePayload['removeAt'] ?? 0.0,
      'sizeId': tirePayload['sizeId'] ?? 0,
      'typeId': tirePayload['typeId'] ?? 0,
      'manufacturerId': tirePayload['manufacturerId'] ?? 0,
      'isOfflineTyre': tirePayload['isOfflineTyre'] ?? false,
    };
    existingTires.add(newTire);

    model['installedTires'] = existingTires;
    jsonData['model'] = model;

    await saveInspectionCache(vehicleId, jsonEncode(jsonData));
  }

  static Future<void> updateTireInInspectionCache(
      String vehicleId,
      Map<String, dynamic> tirePayload,
      ) async {
    final cached = getInspectionCache(vehicleId);
    if (cached == null) return;
    Map<String, dynamic> jsonData;
    try {
      jsonData = jsonDecode(cached) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final model = jsonData['model'] as Map<String, dynamic>?;
    if (model == null) return;

    final List<dynamic> existingTires =
        (model['installedTires'] as List<dynamic>?) ?? [];
    final tireId = tirePayload['tireId'];
    final wheelPos = tirePayload['wheelPosition']?.toString() ?? '';

    for (int i = 0; i < existingTires.length; i++) {
      final t = existingTires[i];
      if (t is Map &&
          (t['tireId'] == tireId ||
              t['wheelPosition']?.toString() == wheelPos)) {
        final updated = Map<String, dynamic>.from(t);
        if (tirePayload['tireSerialNo'] != null) {
          updated['tireSerialNo'] = tirePayload['tireSerialNo'];
        }
        if (tirePayload['serialNumber'] != null) {
          updated['tireSerialNo'] = tirePayload['serialNumber'];
        }
        if (tirePayload['sizeName'] != null) {
          updated['sizeName'] = tirePayload['sizeName'];
        }
        if (tirePayload['typeName'] != null) {
          updated['typeName'] = tirePayload['typeName'];
        }
        if (tirePayload['manufacturerName'] != null) {
          updated['manufacturerName'] = tirePayload['manufacturerName'];
        }
        if (tirePayload['brandNo'] != null) {
          updated['brandNo'] = tirePayload['brandNo'];
        }
        if (tirePayload['dispositionId'] != null) {
          updated['dispositionId'] = tirePayload['dispositionId'];
        }
        if (tirePayload['dispositionName'] != null) {
          updated['dispositionName'] = tirePayload['dispositionName'];
        }
        if (tirePayload['sizeId'] != null) {
          updated['sizeId'] = tirePayload['sizeId'];
        }
        if (tirePayload['typeId'] != null) {
          updated['typeId'] = tirePayload['typeId'];
        }
        if (tirePayload['manufacturerId'] != null) {
          updated['manufacturerId'] = tirePayload['manufacturerId'];
        }
        if (tirePayload['originalTread'] != null) {
          updated['originalTread'] = tirePayload['originalTread'];
        }
        if (tirePayload['removeAt'] != null) {
          updated['removeAt'] = tirePayload['removeAt'];
        }
        if (tirePayload['outsideTread'] != null) {
          updated['outsideTread'] = tirePayload['outsideTread'];
        }
        if (tirePayload['middleTread'] != null) {
          updated['middleTread'] = tirePayload['middleTread'];
        }
        if (tirePayload['insideTread'] != null) {
          updated['insideTread'] = tirePayload['insideTread'];
        }
        if (tirePayload['currentTreadDepth'] != null) {
          updated['currentTreadDepth'] = tirePayload['currentTreadDepth'];
        }
        if (tirePayload['currentPressure'] != null) {
          updated['currentPressure'] = tirePayload['currentPressure'];
        }
        if (tirePayload['currentHours'] != null) {
          updated['currentHours'] = tirePayload['currentHours'];
        }
        if (tirePayload['currentMiles'] != null) {
          updated['currentMiles'] = tirePayload['currentMiles'];
        }
        if (tirePayload['percentageWorn'] != null) {
          updated['percentageWorn'] = tirePayload['percentageWorn'];
        }
        if (tirePayload['casingConditionId'] != null) {
          updated['casingConditionId'] = tirePayload['casingConditionId'];
        }
        if (tirePayload['wearConditionId'] != null) {
          updated['wearConditionId'] = tirePayload['wearConditionId'];
        }
        if (tirePayload['comments'] != null) {
          updated['comments'] = tirePayload['comments'];
        }
        updated['inspectionDate'] =
            tirePayload['inspectionDate'] ?? DateTime.now().toIso8601String();
        existingTires[i] = updated;
        break;
      }
    }

    model['installedTires'] = existingTires;
    jsonData['model'] = model;
    await saveInspectionCache(vehicleId, jsonEncode(jsonData));

  }

  static Future<void> patchTireInAllInspectionCaches(
      int tireId, Map<String, dynamic> payload) async {
    try {
      final allKeys = listInspectionCacheKeys();
      for (final vehicleIdKey in allKeys) {
        final cached = getInspectionCache(vehicleIdKey);
        if (cached == null) continue;

        Map<String, dynamic> jsonData;
        try {
          jsonData = jsonDecode(cached) as Map<String, dynamic>;
        } catch (_) {
          continue;
        }

        final model = jsonData['model'] as Map<String, dynamic>?;
        if (model == null) continue;

        final List<dynamic> tires =
            (model['installedTires'] as List<dynamic>?) ?? [];
        bool changed = false;

        for (int i = 0; i < tires.length; i++) {
          final t = tires[i];
          if (t is! Map) continue;
          final tIdInCache = t['tireId'];
          if (tIdInCache == null) continue;
          final tIdInt = tIdInCache is int
              ? tIdInCache
              : (int.tryParse(tIdInCache.toString()) ?? 0);
          if (tIdInt != tireId) continue;

          final updated = Map<String, dynamic>.from(t);
          if (payload['tireSerialNo'] != null) {
            updated['tireSerialNo'] = payload['tireSerialNo'];
          }
          if (payload['serialNumber'] != null) {
            updated['tireSerialNo'] = payload['serialNumber'];
          }
          if (payload['sizeName'] != null) {
            updated['sizeName'] = payload['sizeName'];
          }
          if (payload['typeName'] != null) {
            updated['typeName'] = payload['typeName'];
          }
          if (payload['manufacturerName'] != null) {
            updated['manufacturerName'] = payload['manufacturerName'];
          }
          if (payload['brandNo'] != null) {
            updated['brandNo'] = payload['brandNo'];
          }
          if (payload['dispositionId'] != null) {
            updated['dispositionId'] = payload['dispositionId'];
          }
          if (payload['dispositionName'] != null) {
            updated['dispositionName'] = payload['dispositionName'];
          }
          if (payload['sizeId'] != null) updated['sizeId'] = payload['sizeId'];
          if (payload['typeId'] != null) updated['typeId'] = payload['typeId'];
          if (payload['manufacturerId'] != null) {
            updated['manufacturerId'] = payload['manufacturerId'];
          }
          if (payload['originalTread'] != null) {
            updated['originalTread'] = payload['originalTread'];
          }
          if (payload['removeAt'] != null) {
            updated['removeAt'] = payload['removeAt'];
          }
          // Measurement fields
          if (payload['outsideTread'] != null) {
            updated['outsideTread'] = payload['outsideTread'];
          }
          if (payload['middleTread'] != null) {
            updated['middleTread'] = payload['middleTread'];
          }
          if (payload['insideTread'] != null) {
            updated['insideTread'] = payload['insideTread'];
          }
          if (payload['currentTreadDepth'] != null) {
            updated['currentTreadDepth'] = payload['currentTreadDepth'];
          }
          if (payload['currentPressure'] != null) {
            updated['currentPressure'] = payload['currentPressure'];
          }

          if (payload['currentHours'] != null) {
            updated['currentHours'] = payload['currentHours'];
          }
          if (payload['currentMiles'] != null) {
            updated['currentMiles'] = payload['currentMiles'];
          }

          tires[i] = updated;
          changed = true;

          break;
        }

        if (changed) {
          model['installedTires'] = tires;
          jsonData['model'] = model;
          await saveInspectionCache(vehicleIdKey, jsonEncode(jsonData));
        }
      }
    } catch (_) {
    }
  }

  //  TYRES
  static String _dispositionIdToName(int id) {
    switch (id) {
      case 1: return 'Scrap';
      case 2: return 'Repair';
      case 3: return 'Retread';
      case 4: return 'On Hold';
      case 7: return 'Installed';
      case 8: return 'Inventory';
      default: return 'Inventory';
    }
  }

  static Future<void> saveTyres(List<Map<String, dynamic>> list) async {
    final box = Hive.box<TyreHiveModel>(_tyreBox);

    final pendingTires = box.values
        .where((t) => t.isPendingSync == true)
        .toList();

    final pendingRemoveTireIds = <int>{};
    try {
      for (final op in getAllPendingOps()) {
        if (op.opType == 'removeTyre' || op.opType == 'rotateTireRemove') {
          final payload = op.payload;
          final tId = payload['tireId'];
          if (tId != null) {
            pendingRemoveTireIds.add(
              tId is int ? tId : (int.tryParse(tId.toString()) ?? 0),
            );
          }
        }
      }
    } catch (_) {}

    final removePendingTires = pendingRemoveTireIds.isEmpty
        ? <TyreHiveModel>[]
        : box.values
        .where((t) =>
        pendingRemoveTireIds.contains(t.tireId))
        .toList();

    _evictExpiredRemovedTires();
    final recentlyRemovedTires = <TyreHiveModel>[];
    if (_recentlyRemovedTireIds.isNotEmpty) {
      for (final t in box.values) {
        if (_recentlyRemovedTireIds.containsKey(t.tireId)) {
          recentlyRemovedTires.add(t);
        }
      }
    }

    // ✅ FIX: clear karne se pehle local tread/pressure values snapshot karo.
    // Server ki inventory list kai baar insideTread/middleTread/outsideTread
    // null ya 0 bhejti hai; us case me purani local value (jaise inside 99)
    // overwrite hokar 0 ho jaati thi, aur install screen par outside (100)
    // wala fallback inside me dikhta tha.
    final Map<int, Map<String, double>> _oldTreads = {};
    for (final t in box.values) {
      _oldTreads[t.tireId] = {
        'outsideTread': t.outsideTread ?? 0.0,
        'middleTread': t.middleTread ?? 0.0,
        'insideTread': t.insideTread ?? 0.0,
        'currentTreadDepth': t.currentTreadDepth ?? 0.0,
        'currentPressure': t.currentPressure ?? 0.0,
      };
    }

    await box.clear();

    for (final e in list) {
      final rawId = e['tireId'];
      final tId = rawId is int ? rawId : (int.tryParse('${rawId ?? 0}') ?? 0);
      final old = _oldTreads[tId];
      if (old == null) continue;
      for (final k in old.keys) {
        final nv = e[k] is num
            ? (e[k] as num).toDouble()
            : double.tryParse('${e[k] ?? ''}') ?? 0.0;
        if (nv <= 0 && old[k]! > 0) e[k] = old[k];
      }
    }

    final filteredList = _recentlyRemovedTireIds.isEmpty
        ? list
        : list.where((e) {
      final rawId = e['tireId'];
      if (rawId == null) return true;
      final tId = rawId is int ? rawId : (int.tryParse(rawId.toString()) ?? 0);
      if (_recentlyRemovedTireIds.containsKey(tId)) {
        return false;
      }
      return true;
    }).toList();

    final items = filteredList.map((e) => TyreHiveModel.fromMap(e)).toList();
    await box.addAll(items);

    final savedIds = items.map((t) => t.tireId).toSet();

    for (final pt in pendingTires) {
      if (!savedIds.contains(pt.tireId)) {
        await box.put(pt.tireId.toString(), pt);
      }
    }

    for (final rt in removePendingTires) {
      await box.put(rt.tireId.toString(), rt);
    }

    for (final rt in recentlyRemovedTires) {
      await box.put(rt.tireId.toString(), rt);
    }


    try {
      for (final op in getPendingOperations()) {
        if (op.opType != 'updateTyre') continue;
        final payload = Map<String, dynamic>.from(op.payload);
        final rawId = payload['tireId'];
        if (rawId == null) continue;
        final tId = rawId is int ? rawId : (int.tryParse(rawId.toString()) ?? 0);
        if (tId <= 0) continue;
        final existing = _tyres.values.where((t) => t.tireId == tId).toList();
        if (existing.isEmpty) continue;
        final t = existing.first;
        if (payload['tireSerialNo'] != null) t.serialNumber = payload['tireSerialNo'].toString();
        if (payload['serialNumber'] != null) t.serialNumber = payload['serialNumber'].toString();
        if (payload['dispositionId'] != null) {
          t.dispositionId = _toIntSafe(payload['dispositionId']);
        }
        if (payload['tireStatusId'] != null) {
          t.tireStatusId = _toIntSafe(payload['tireStatusId']);
        }
        if (payload['manufacturerId'] != null) {
          t.manufacturerId = _toIntSafe(payload['manufacturerId']);
        }
        if (payload['sizeId'] != null) t.tireSizeId = _toIntSafe(payload['sizeId']);
        if (payload['typeId'] != null) t.tireTypeId = _toIntSafe(payload['typeId']);
        if (payload['outsideTread'] != null) {
          t.outsideTread = _toDoubleSafe(payload['outsideTread']);
        }
        if (payload['insideTread'] != null) {
          t.insideTread = _toDoubleSafe(payload['insideTread']);
        }
        if (payload['middleTread'] != null) {
          t.middleTread = _toDoubleSafe(payload['middleTread']);
        }
        if (payload['originalTread'] != null) {
          t.originalTread = _toDoubleSafe(payload['originalTread']);
        }
        if (payload['removeAt'] != null) {
          t.removeAt = _toDoubleSafe(payload['removeAt']);
        }
        if (payload['purchasedTread'] != null) {
          t.purchasedTread = _toDoubleSafe(payload['purchasedTread']);
        }
        await t.save();
      }
    } catch (_) {
    }
  }

  static List<TyreHiveModel> getAllTyres({int? parentAccountId}) {
    return _tyres.values.where((t) {
      if (parentAccountId != null && t.parentAccountId != parentAccountId) {
        return false;
      }
      return true;
    }).toList();
  }

  static List<TyreHiveModel> getInventoryTyres({
    int? parentAccountId,
    int? locationId,
  }) {
    return _tyres.values.where((t) {
      if (parentAccountId != null && t.parentAccountId != parentAccountId) {
        return false;
      }
      if (locationId != null && locationId != 0 && t.locationId != locationId) {
        return false;
      }

      final dispId = t.dispositionId ?? 0;

      if (dispId == 7) return false;

      if (t.vehicleId != null && t.vehicleId! > 0) return false;

      if (dispId != 8 && dispId != 0) return false;

      return true;
    }).toList();
  }
  static List<TyreHiveModel> getTyresByVehicle(int vehicleId) =>
      _tyres.values.where((t) => t.vehicleId == vehicleId).toList();

  static TyreHiveModel? getTyreById(int tireId) {
    try {
      return _tyres.values.firstWhere((e) => e.tireId == tireId);
    } catch (_) {
      return null;
    }
  }

  static int tyreCount({int? parentAccountId}) {
    if (parentAccountId == null) return _tyres.length;
    return _tyres.values
        .where((t) => t.parentAccountId == parentAccountId)
        .length;
  }

  static Future<String> saveOfflineTyre(Map<String, dynamic> data) async {
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    data['tireId'] = tempId;
    data['isPendingSync'] = true;
    final t = TyreHiveModel.fromMap(data);
    await _tyres.put(tempId.toString(), t);
    return tempId.toString();
  }

  static Future<void> updateTyreDisposition({
    required int tireId,
    required int dispositionId,
    required String dispositionName,
    String? wheelPosition,
    int? vehicleId,
    double? outsideTread,
    double? middleTread,
    double? insideTread,
    double? currentTreadDepth,
    double? currentPressure,
    double? currentHours,
    double? currentMiles,
    int? wearConditionId,
    int? casingConditionId,
    String? comments,
  }) async {
    TyreHiveModel? t;
    try {
      t = _tyres.values.firstWhere((e) => e.tireId == tireId);
    } catch (_) {
      // 🔎 DEBUG A — is tireId ka tyre record HIVE me hi nahi mila.
      // Agar yeh print aaya, toh matlab install ke time jo tireId pass
      // hua wo actual saved offline tyre ke tireId se MATCH nahi kar raha.
      debugPrint(
        '[VEHICLE-ID DEBUG A] updateTyreDisposition: tireId=$tireId '
            'NOT FOUND in _tyres box! incoming vehicleId=$vehicleId. '
            'Available tireIds in box: ${_tyres.values.map((e) => e.tireId).toList()}',
      );
      return;
    }

    // 🔎 DEBUG B — tyre record mil gaya, ab dekho vehicleId set hone se
    // pehle aur baad me kya tha.
    debugPrint(
      '[VEHICLE-ID DEBUG B] updateTyreDisposition: tireId=$tireId FOUND. '
          'old t.vehicleId=${t.vehicleId} incoming vehicleId=$vehicleId '
          '=> will set t.vehicleId to ${(vehicleId != null && vehicleId != 0) ? vehicleId : null}',
    );
    t.dispositionId = dispositionId;
    t.dispositionName = dispositionName.isNotEmpty
        ? dispositionName
        : _dispositionIdToName(dispositionId);
    // NOTE: tireStatusName must NOT be overwritten here.
    // tireStatusName holds the status selected by the user at tire-creation
    // time (e.g. New/Used/Retreaded) and is a different concept from
    // dispositionName (Installed/Inventory/On Hold/Scrap/...), which only
    // tracks where the tyre currently is. Previously this line forced
    // tireStatusName = dispositionName, so installing a tyre on a vehicle
    // (which sets dispositionName = 'Installed') silently overwrote and lost
    // the originally selected status shown in the "Status:" field on the
    // All Tire list.
    if (wheelPosition != null) t.wheelPosition = wheelPosition.isEmpty ? null : wheelPosition;
    if (vehicleId != null) t.vehicleId = (vehicleId == 0) ? null : vehicleId;

    if (outsideTread != null && outsideTread > 0) t.outsideTread = outsideTread;
    if (middleTread != null && middleTread > 0) t.middleTread = middleTread;
    if (insideTread != null && insideTread > 0) t.insideTread = insideTread;
    if (currentTreadDepth != null && currentTreadDepth > 0) t.currentTreadDepth = currentTreadDepth;
    if (currentPressure != null && currentPressure > 0) t.currentPressure = currentPressure;
    if (currentHours != null && currentHours > 0) t.currentHours = currentHours;
    if (currentMiles != null && currentMiles > 0) t.currentMiles = currentMiles;
    if (wearConditionId != null && wearConditionId > 0) t.wearConditionId = wearConditionId;
    if (casingConditionId != null && casingConditionId > 0) t.casingConditionId = casingConditionId;
    if (comments != null && comments.isNotEmpty) t.comments = comments;

    await t.save();
    await _patchTireDetailCacheDisposition(
      tireId: tireId,
      dispositionId: dispositionId,
      dispositionName: dispositionName,
      wheelPosition: wheelPosition,
      vehicleId: vehicleId,
    );
  }

  static Future<void> _patchTireDetailCacheDisposition({
    required int tireId,
    required int dispositionId,
    required String dispositionName,
    String? wheelPosition,
    int? vehicleId,
  }) async {
    try {
      final cached = getTireDetailCache(tireId);
      if (cached == null) return;

      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      final model = decoded['model'] as Map<String, dynamic>?;
      if (model == null) return;

      model['dispositionId'] = dispositionId;
      model['dispositionName'] = dispositionName;
      model['tireStatusId'] = dispositionId;

      if (vehicleId == null || vehicleId == 0) {
        model['vehicleId'] = null;
        model['vehicleNumber'] = null;
        model['wheelPosition'] = null;
        model['mountStatus'] = 'Not Mounted';
        model['isMountToRim'] = false;
      } else {
        if (wheelPosition != null) model['wheelPosition'] = wheelPosition;
        model['vehicleId'] = vehicleId;
      }

      decoded['model'] = model;
      await saveTireDetailCache(tireId, jsonEncode(decoded));

    } catch (_) {
    }
  }

  static Future<void> applyPostSyncTyreUpdate({
    required String opType,
    required Map<String, dynamic> payload,
  }) async {
    try {
      if (opType == 'removeTyre' || opType == 'rotateTireRemove') {
        final rawTireId = payload['tireId'];
        if (rawTireId == null) return;
        final tIdInt = rawTireId is int
            ? rawTireId
            : (int.tryParse(rawTireId.toString()) ?? 0);
        if (tIdInt <= 0) return;

        final rawDispId = payload['dispositionId'] ?? 8;
        final dispId = rawDispId is int
            ? rawDispId
            : (int.tryParse(rawDispId.toString()) ?? 8);
        final dispName = (payload['dispositionName']?.toString().isNotEmpty ?? false)
            ? payload['dispositionName'].toString()
            : _dispositionIdToName(dispId);


        markTireAsRecentlyRemoved(tIdInt);

        await updateTyreDisposition(
          tireId: tIdInt,
          dispositionId: dispId,
          dispositionName: dispName,
          vehicleId: 0,
          wheelPosition: '',
        );
      } else if (opType == 'installTyre' || opType == 'rotateTireInstall') {
        final rawTireId = payload['tireId'];
        final rawVehicleId = payload['vehicleId'];
        if (rawTireId == null) return;
        final tIdInt = rawTireId is int
            ? rawTireId
            : (int.tryParse(rawTireId.toString()) ?? 0);
        if (tIdInt <= 0) return;
        final vIdInt = rawVehicleId is int
            ? rawVehicleId
            : (int.tryParse(rawVehicleId?.toString() ?? '0') ?? 0);
        final wheelPos = payload['wheelPosition']?.toString() ?? '';

        await updateTyreDisposition(
          tireId: tIdInt,
          dispositionId: 7, // Installed
          dispositionName: 'Installed',
          vehicleId: vIdInt,
          wheelPosition: wheelPos,
        );
      } else {
        return;
      }

      _notifyPostSyncTyreListeners();
    } catch (_) {
    }
  }

  static void _notifyPostSyncTyreListeners() {
    for (final cb in List<void Function()>.from(_postSyncTyreListeners)) {
      try {
        cb();
      } catch (_) {}
    }
  }


  static void notifyPostSyncTyreListenersExternal() {
    _notifyPostSyncTyreListeners();
  }


  static final List<void Function()> _postSyncTyreListeners = [];

  static void registerPostSyncTyreListener(void Function() callback) {
    if (!_postSyncTyreListeners.contains(callback)) {
      _postSyncTyreListeners.add(callback);
    }
  }

  static void unregisterPostSyncTyreListener(void Function() callback) {
    _postSyncTyreListeners.remove(callback);
  }

  static Future<void> updateTyreInBox(
      int tireId,
      Map<String, dynamic> payload,
      ) async {
    TyreHiveModel? t;
    try {
      t = _tyres.values.firstWhere((e) => e.tireId == tireId);
    } catch (_) {
      return;
    }

    if (payload['tireSerialNo'] != null) {
      t.serialNumber = payload['tireSerialNo'].toString();
    }
    if (payload['serialNumber'] != null) {
      t.serialNumber = payload['serialNumber'].toString();
    }
    if (payload['manufacturerId'] != null) {
      t.manufacturerId = _toIntSafe(payload['manufacturerId']);
    }
    if (payload['sizeId'] != null) t.tireSizeId = _toIntSafe(payload['sizeId']);
    if (payload['typeId'] != null) t.tireTypeId = _toIntSafe(payload['typeId']);
    if (payload['dispositionId'] != null) {
      t.dispositionId = _toIntSafe(payload['dispositionId']);
    }
    if (payload['tireStatusId'] != null) {
      t.tireStatusId = _toIntSafe(payload['tireStatusId']);
    }
    if (payload['tireStatusName'] != null && payload['tireStatusName'].toString().isNotEmpty) {
      t.tireStatusName = payload['tireStatusName'].toString();
    }
    if (payload['mileageType'] != null) {
      t.mileageType = payload['mileageType'].toString();
    }
    if (payload['starRatingId'] != null) {
      t.starRatingId = _toIntSafe(payload['starRatingId']);
    }
    if (payload['outsideTread'] != null) {
      t.outsideTread = _toDoubleSafe(payload['outsideTread']);
    }
    if (payload['insideTread'] != null) {
      t.insideTread = _toDoubleSafe(payload['insideTread']);
    }
    if (payload['currentPressure'] != null) {
      t.currentPressure = _toDoubleSafe(payload['currentPressure']);
    }
    if (payload['wearConditionId'] != null) {
      t.wearConditionId = _toIntSafe(payload['wearConditionId']);
    }
    if (payload['casingConditionId'] != null) {
      t.casingConditionId = _toIntSafe(payload['casingConditionId']);
    }
    if (payload['originalTread'] != null) {
      t.originalTread = _toDoubleSafe(payload['originalTread']);
    }
    if (payload['removeAt'] != null) {
      t.removeAt = _toDoubleSafe(payload['removeAt']);
    }
    if (payload['purchasedTread'] != null) {
      t.purchasedTread = _toDoubleSafe(payload['purchasedTread']);
    }
    if (payload['currentHours'] != null) {
      t.currentHours = _toDoubleSafe(payload['currentHours']);
    }
    if (payload['currentMiles'] != null) {
      t.currentMiles = _toDoubleSafe(payload['currentMiles']);
    }
    if (payload['purchaseCost'] != null) {
      t.purchaseCost = _toDoubleSafe(payload['purchaseCost']);
    }
    if (payload['casingValue'] != null) {
      t.casingValue = _toDoubleSafe(payload['casingValue']);
    }
    if (payload['fillCost'] != null) {
      t.fillCost = _toDoubleSafe(payload['fillCost']);
    }
    if (payload['repairCost'] != null) {
      t.repairCost = _toDoubleSafe(payload['repairCost']);
    }
    if (payload['retreadCost'] != null) {
      t.retreadCost = _toDoubleSafe(payload['retreadCost']);
    }
    if (payload['warrantyAdjustment'] != null) {
      t.warrantyAdjustment = _toDoubleSafe(payload['warrantyAdjustment']);
    }
    if (payload['costAdjustment'] != null) {
      t.costAdjustment = _toDoubleSafe(payload['costAdjustment']);
    }
    if (payload['soldAmount'] != null) {
      t.soldAmount = _toDoubleSafe(payload['soldAmount']);
    }
    if (payload['netCost'] != null) {
      t.netCost = _toDoubleSafe(payload['netCost']);
    }
    if (payload['loadRatingId'] != null) {
      t.loadRatingId = _toIntSafe(payload['loadRatingId']);
    }
    if (payload['speedRatingId'] != null) {
      t.speedRatingId = _toIntSafe(payload['speedRatingId']);
    }
    if (payload['compoundId'] != null) {
      t.compoundId = _toIntSafe(payload['compoundId']);
    }
    if (payload['indCodeId'] != null) {
      t.indCodeId = _toIntSafe(payload['indCodeId']);
    }
    if (payload['fillTypeId'] != null) {
      t.fillTypeId = _toIntSafe(payload['fillTypeId']);
    }
    if (payload['lotNo'] != null) t.lotNo = payload['lotNo'].toString();
    if (payload['poNo'] != null) t.poNo = payload['poNo'].toString();
    if (payload['evaluationNo'] != null) {
      t.evaluationNo = payload['evaluationNo'].toString();
    }
    if (payload['registeredDate'] != null) {
      t.registeredDate = payload['registeredDate'].toString();
    }
    if (payload['plyId'] != null) {
      t.plyId = _toIntSafe(payload['plyId']);
    }
    if (payload['middleTread'] != null) {
      t.middleTread = _toDoubleSafe(payload['middleTread']);
    }
    if (payload['comments'] != null && payload['comments'].toString().isNotEmpty) {
      t.comments = payload['comments'].toString();
    }

    t.savedAt = DateTime.now().toIso8601String();
    await t.save();
  }

  static int? _toIntSafe(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static double? _toDoubleSafe(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    return double.tryParse(v.toString());
  }

  static Future<void> deleteTyre(int tireId) async {
    await _tyres.delete(tireId.toString());
  }

  static Future<void> clearTyres() async => await _tyres.clear();

  //  ACCOUNTS
  static Future<void> saveAccounts(List<Map<String, dynamic>> list) async {
    final box = Hive.box<AccountHiveModel>(_accountBox);

    await box.clear();

    final items = list.map((e) => AccountHiveModel.fromMap(e)).toList();

    await box.addAll(items);
  }

  static List<AccountHiveModel> getAccounts() => _accounts.values.toList();

  static AccountHiveModel? getAccountById(int id) =>
      _accounts.get(id.toString());

  static Future<void> clearAccounts() async => await _accounts.clear();

  //  LOCATIONS
  static Future<void> saveLocations(List<Map<String, dynamic>> list) async {
    final box = Hive.box<LocationHiveModel>(_locationBox);

    await box.clear();

    final items = list.map((e) => LocationHiveModel.fromMap(e)).toList();

    await box.addAll(items);
  }

  static List<LocationHiveModel> getLocations({int? parentAccountId}) {
    if (parentAccountId == null) return _locs.values.toList();
    return _locs.values
        .where((l) => l.parentAccountId == parentAccountId)
        .toList();
  }

  static Future<void> clearLocations() async => await _locs.clear();
  //  PENDING OPERATIONS QUEUE
  static Future<String> addPendingOperation({
    required String opType,
    required Map<String, dynamic> payload,
    required String endpoint,
    String httpMethod = 'POST',
  }) async {

    if (opType == 'installTyre' || opType == 'removeTyre') {
      final tireIdKey = payload['tireId']?.toString();
      if (tireIdKey != null && tireIdKey.isNotEmpty) {
        final superseded = _pending.values
            .where((op) =>
        !op.isSynced &&
            (op.opType == 'installTyre' || op.opType == 'removeTyre') &&
            op.payload['tireId']?.toString() == tireIdKey)
            .toList();
        for (final old in superseded) {
          await _pending.delete(old.key);
        }
      }
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final op = PendingOperationHiveModel(
      id: id,
      opType: opType,
      payload: Map<dynamic, dynamic>.from(payload),
      endpoint: endpoint,
      httpMethod: httpMethod,
      createdAt: DateTime.now().toIso8601String(),
    );
    await _pending.put(id, op);
    return id;
  }


  static Future<bool> mergeIntoPendingCreateTyre(
      int tempTireId, Map<String, dynamic> updates) async {
    final matches = _pending.values
        .where((op) =>
    !op.isSynced &&
        op.opType == 'createTyre' &&
        op.payload['tireId']?.toString() == tempTireId.toString())
        .toList();

    if (matches.isEmpty) return false;

    for (final op in matches) {
      final merged = Map<String, dynamic>.from(op.payload);
      updates.forEach((key, value) {
        if (key == 'tireId') return;
        merged[key] = value;
      });
      op.payload = Map<dynamic, dynamic>.from(merged);
      await op.save();
    }
    return true;
  }

  static List<PendingOperationHiveModel> getPendingOperations() =>
      _pending.values.where((op) => !op.isSynced).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  static List<PendingOperationHiveModel> getAllPendingOps() =>
      _pending.values.toList();

  static int pendingOperationsCount() =>
      _pending.values.where((op) => !op.isSynced).length;

  /// Count of not-yet-synced pending operations of a specific [opType]
  /// (e.g. 'createUser') — used to show "X pending sync" badges on
  /// feature-specific screens (User Management, etc.) instead of only
  /// the global pending count.
  static int pendingOperationsCountByType(String opType) => _pending.values
      .where((op) => !op.isSynced && op.opType == opType)
      .length;

  /// Not-yet-synced pending operations of a specific [opType], oldest
  /// first — so offline-created records can be shown inline in a list
  /// (with a "Pending Sync" chip) until the real sync happens.
  static List<PendingOperationHiveModel> getPendingOperationsByType(
      String opType) =>
      _pending.values.where((op) => !op.isSynced && op.opType == opType).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  static Future<void> markOperationSynced(String id) async {
    final op = _pending.get(id);
    if (op == null) return;
    op.isSynced = true;
    op.syncedAt = DateTime.now().toIso8601String();
    op.lastError = null;
    await op.save();
  }

  static Future<void> incrementRetryCount(String id, {String? error}) async {
    final op = _pending.get(id);
    if (op == null) return;
    op.retryCount++;
    op.lastError = error;
    await op.save();
  }

  static Future<void> deletePendingOperation(String id) async {
    await _pending.delete(id);
  }

  static Future<void> clearSyncedOperations() async {
    final synced = _pending.values.where((op) => op.isSynced).toList();
    for (final op in synced) {
      await op.delete();
    }
  }


  static Set<int> getPendingInstallTireIds(int vehicleId) {
    final pendingTireIds = <int>{};

    for (final op in getPendingOperations()) {
      if (op.opType != 'installTyre') continue;

      final payload = Map<String, dynamic>.from(op.payload);
      final payloadVehicleId = payload['vehicleId'];
      final payloadTireId    = payload['tireId'];

      final opVehicleId = payloadVehicleId is int
          ? payloadVehicleId
          : int.tryParse(payloadVehicleId?.toString() ?? '');

      if (opVehicleId == null || opVehicleId != vehicleId) continue;

      if (payloadTireId != null) {
        final tId = payloadTireId is int
            ? payloadTireId
            : int.tryParse(payloadTireId.toString());
        if (tId != null) {
          pendingTireIds.add(tId);
        }
      }
    }

    return pendingTireIds;
  }


  /// Un-synced (abhi queue me pade) install ops ke saare tireIds — normal
  /// installTyre/rotateTireInstall aur approval-flow (temp/direct batched)
  /// payload dono se. Inventory/search list me ye tyres nahi dikhne chahiye.
  static Set<int> getAllPendingInstallTireIds() {
    final ids = <int>{};
    int? toInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '');
    for (final op in getPendingOperations()) {
      if (op.opType == 'installTyre' || op.opType == 'rotateTireInstall') {
        final t = toInt(op.payload['tireId']);
        if (t != null && t != 0) ids.add(t);
      } else if (op.opType == 'vehicleInspectApprovalTemp' ||
          op.opType == 'vehicleInspectDirect') {
        final tl = op.payload['tireList'];
        if (tl is List) {
          for (final e in tl) {
            if (e is! Map) continue;
            if ((e['action']?.toString() ?? '') != 'Install') continue;
            final t = toInt(e['tireId']);
            if (t != null && t != 0) ids.add(t);
          }
        }
      }
    }
    return ids;
  }

  // ─────────────────────────────────────────────────────────
  //  Approval-flow (temp) batched payload helpers
  // ─────────────────────────────────────────────────────────
  static const _batchedListKeys = ['vehicleList', 'inspectionList', 'tireList'];

  static String _nestedVehicleId(Map<String, dynamic> p) {
    final top = p['vehicleId']?.toString() ?? '';
    if (top.isNotEmpty && top != '0') return top;
    for (final k in _batchedListKeys) {
      final l = p[k];
      if (l is List && l.isNotEmpty) {
        for (final item in l) {
          if (item is Map) {
            final v = (item['vehicleId'] ?? item['VehicleId'])?.toString() ?? '';
            if (v.isNotEmpty && v != '0') return v;
          }
        }
      }
    }
    return '';
  }

  static String _nestedVehicleNumber(Map<String, dynamic> p) {
    final top = (p['vehicleNumber'] ?? p['VehicleNumber'])?.toString().trim().toUpperCase() ?? '';
    if (top.isNotEmpty) return top;
    for (final k in _batchedListKeys) {
      final l = p[k];
      if (l is List && l.isNotEmpty) {
        for (final item in l) {
          if (item is Map) {
            final vn = (item['vehicleNumber'] ?? item['VehicleNumber'])?.toString().trim().toUpperCase() ?? '';
            if (vn.isNotEmpty) return vn;
          }
        }
      }
    }
    return '';
  }

  /// Is (offline-created) vehicle ka temp-inspection op abhi tak server par
  /// submit nahi hua? (true => vehicle ko "Pending" list me dikhaate raho)
  static bool hasUnsyncedTempOpForVehicle(int tempVehicleId) {
    final tempStr = tempVehicleId.toString();
    final real = _vehicleRealIdMap[tempStr]?.toString();
    for (final op in getPendingOperations()) {
      if (op.opType != 'vehicleInspectApprovalTemp') continue;
      final vid = _nestedVehicleId(Map<String, dynamic>.from(op.payload));
      if (vid == tempStr || (real != null && vid == real)) return true;
    }
    return false;
  }

  /// Is vehicle ka koi inspection SUBMIT offline hua tha aur abhi tak server
  /// par sync nahi hua? (queue me unsynced vehicleInspect / temp / direct op)
  ///
  /// true => jab tak sync na ho, us vehicle par tyre inspect, image
  /// upload/delete, update hours, install/rotate aur dobara submit block
  /// hona chahiye (PendingInspectionGuard.canProceed isi ko use karta hai).
  /// Temp (negative) aur real vehicleId dono match hote hain.
  static bool hasUnsyncedInspectionSubmitForVehicle(int vehicleId, {String? vehicleNumber}) {
    const submitOpTypes = {
      'vehicleInspect',
      'vehicleInspectApprovalTemp',
      'vehicleInspectDirect',
      'installTyre',
    };

    final candidates = <String>{};
    if (vehicleId != 0) {
      candidates.add(vehicleId.toString());
      final mappedReal = _vehicleRealIdMap[vehicleId.toString()];
      if (mappedReal != null) candidates.add(mappedReal.toString());
      _vehicleRealIdMap.forEach((temp, real) {
        if (real == vehicleId) candidates.add(temp);
      });
    }
    if (vehicleNumber != null && vehicleNumber.trim().isNotEmpty) {
      candidates.add(vehicleNumber.trim().toUpperCase());
    }

    if (candidates.isEmpty) return false;

    for (final op in getPendingOperations()) {
      if (!submitOpTypes.contains(op.opType)) continue;
      final payload = Map<String, dynamic>.from(op.payload);
      final vid = _nestedVehicleId(payload);
      if (vid.isNotEmpty && candidates.contains(vid)) return true;
      final vnum = _nestedVehicleNumber(payload);
      if (vnum.isNotEmpty && candidates.contains(vnum)) return true;
    }
    return false;
  }

  /// Is tyre ka koi inspection SUBMIT offline hua tha aur abhi tak server
  /// par sync nahi hua? Ya ye tyre kisi aise vehicle par laga hai jiska inspection unsynced hai?
  static bool hasUnsyncedInspectionSubmitForTire(int tireId, {String? tireSerialNo}) {
    // 1. Agar ye tyre kisi vehicle par laga hai aur us vehicle ka inspection unsynced hai:
    final tyre = getTyreById(tireId);
    if (tyre != null && tyre.vehicleId != null && tyre.vehicleId! > 0) {
      if (hasUnsyncedInspectionSubmitForVehicle(tyre.vehicleId!)) return true;
    }

    const submitOpTypes = {
      'vehicleInspect',
      'vehicleInspectApprovalTemp',
      'vehicleInspectDirect',
      'tireInspection',
    };

    final sTid = tireId.toString();
    final sn = tireSerialNo?.trim().toUpperCase();

    for (final op in getPendingOperations()) {
      if (!submitOpTypes.contains(op.opType)) continue;
      final p = Map<String, dynamic>.from(op.payload);

      final opTid = (p['tireId'] ?? p['TireId'])?.toString();
      if (opTid != null && opTid == sTid) return true;

      final opSn = (p['tireSerialNo'] ?? p['TireSerialNo'])?.toString().trim().toUpperCase();
      if (sn != null && sn.isNotEmpty && opSn != null && opSn == sn) return true;

      final tList = (p['tireList'] ?? p['tiresList'] ?? p['installedTires']) as List?;
      if (tList != null) {
        for (final item in tList) {
          if (item is Map) {
            final itTid = (item['tireId'] ?? item['TireId'])?.toString();
            if (itTid != null && itTid == sTid) return true;
            final itSn = (item['tireSerialNo'] ?? item['TireSerialNo'])?.toString().trim().toUpperCase();
            if (sn != null && sn.isNotEmpty && itSn != null && itSn == sn) return true;
          }
        }
      }
    }
    return false;
  }

  /// Batched (temp/direct) payload ke andar ke negative (offline) vehicleId /
  /// tireId ko real ids se replace karta hai. Payload ki deep copy return
  /// hoti hai. Agar koi temp id abhi resolve nahi hui (createVehicle /
  /// createTyre pehle sync hona baaki hai) to null return hota hai.
  static Future<Map<String, dynamic>?> resolveBatchedTempIds(
      Map<String, dynamic> payload, {
        Map<String, int>? vehicleMap,
        Map<String, int>? tyreMap,
      }) async {
    final copy = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(payload)) as Map<String, dynamic>);
    final prefs = await SharedPreferences.getInstance();

    int? lookup(String field, String raw) {
      final map = field == 'vehicleId' ? vehicleMap : tyreMap;
      final prefKey = field == 'vehicleId'
          ? 'vehicle_real_id_$raw'
          : 'tyre_real_id_$raw';
      final fromMap = map?[raw] ??
          (field == 'vehicleId' ? _vehicleRealIdMap[raw] : null);
      if (fromMap != null && fromMap > 0) return fromMap;
      final p = prefs.getInt(prefKey);
      return (p != null && p > 0) ? p : null;
    }

    for (final k in _batchedListKeys) {
      final l = copy[k];
      if (l is! List) continue;
      for (final e in l) {
        if (e is! Map) continue;
        for (final field in const ['vehicleId', 'tireId']) {
          final v = e[field];
          if (v == null) continue;
          final raw = v.toString();
          if (!raw.startsWith('-')) continue;
          final real = lookup(field, raw);
          if (real == null) return null;
          e[field] = real;
        }
      }
    }
    return copy;
  }

  /// Offline create hue vehicles jinka temp inspection abhi server tak nahi
  /// pahuncha. Pehle sirf Hive me negative-id wale vehicles dekhe jaate the;
  /// createVehicle sync hote hi Hive me id real ho jaati thi aur vehicle
  /// "Pending" list se gayab ho jaata tha (jabki temp inspection abhi
  /// pending hi tha). Ab jab tak temp op sync nahi hota, draft banaa rehta hai.
  static List<VehicleHiveModel> getDraftVehiclesAwaitingApproval(
      SharedPreferences prefs) {
    final drafts = <VehicleHiveModel>[];
    final seen = <int>{};

    for (final hv in getAllVehicles()) {
      if (hv.vehicleId >= 0) continue;
      final hasCreate = prefs.containsKey('pending_vehicle_create_${hv.vehicleId}');
      final resolved = prefs.containsKey('vehicle_real_id_${hv.vehicleId}');
      if (hasCreate && !resolved) {
        drafts.add(hv);
        seen.add(hv.vehicleId);
      }
    }

    const prefix = 'pending_vehicle_create_';
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(prefix)) continue;
      final tempId = int.tryParse(key.substring(prefix.length));
      if (tempId == null || tempId >= 0 || seen.contains(tempId)) continue;
      if (!hasUnsyncedTempOpForVehicle(tempId)) continue;
      final realId = prefs.getInt('vehicle_real_id_$tempId');
      if (realId == null || realId <= 0) continue;
      final rv = getVehicleById(realId);
      if (rv == null) continue;
      drafts.add(VehicleHiveModel.fromMap({
        'vehicleId': tempId,
        'vehicleNumber': rv.vehicleNumber,
        'typeName': rv.typeName,
        'manufacturerName': rv.manufacturerName,
        'tireSizeName': rv.tireSizeName,
        'axleConfig': rv.axleConfig,
        'axleConfigId': rv.axleConfigId,
        'trackingMethod': rv.trackingMethod,
        'mileageType': rv.mileageType,
        'currentHours': rv.currentHours,
        'currentMiles': rv.currentMiles,
        'removalTread': rv.removalTread,
        'severityComments': rv.severityComments,
        'tireCount': rv.tireCount,
        'parentAccountId': rv.parentAccountId,
        'locationId': rv.locationId,
        'isPendingSync': false,
        'savedAt': DateTime.now().toIso8601String(),
      }));
      seen.add(tempId);
    }
    return drafts;
  }

  static Map<String, int> getSummaryCounts({int? parentAccountId}) {
    return {
      'vehicles': vehicleCount(parentAccountId: parentAccountId),
      'tyres': tyreCount(parentAccountId: parentAccountId),
      'pendingOps': pendingOperationsCount(),
    };
  }


  static Future<void> saveInspectionCache(
      String vehicleId,
      String jsonString,
      ) async {
    await _inspCache.put('insp_$vehicleId', jsonString);
  }

  static String? getInspectionCache(String vehicleId) =>
      _inspCache.get('insp_$vehicleId');

  static List<String> listInspectionCacheKeys() {
    return _inspCache.keys
        .whereType<String>()
        .where((k) => k.startsWith('insp_'))
        .map((k) => k.replaceFirst('insp_', ''))
        .where((k) => int.tryParse(k) != null)
        .toList();
  }

  static bool hasInspectionCache(String vehicleId) =>
      _inspCache.containsKey('insp_$vehicleId');

  static Future<void> clearInspectionCache(String vehicleId) async =>
      await _inspCache.delete('insp_$vehicleId');

  static List<int> getAllCachedPositiveVehicleIds() {
    const prefix = 'insp_';
    final result = <int>[];
    for (final key in _inspCache.keys) {
      final keyStr = key.toString();
      if (!keyStr.startsWith(prefix)) continue;
      final idStr = keyStr.substring(prefix.length);
      final id = int.tryParse(idStr);
      if (id != null && id > 0) result.add(id);
    }
    return result;
  }



  static Future<void> saveVehicleDetailCache(
      int vehicleId,
      String jsonString,
      ) async {
    await _inspCache.put('vehicleDetail_$vehicleId', jsonString);
  }

  static String? getVehicleDetailCache(int vehicleId) =>
      _inspCache.get('vehicleDetail_$vehicleId');

  static bool hasVehicleDetailCache(int vehicleId) =>
      _inspCache.containsKey('vehicleDetail_$vehicleId');

  static Future<void> clearVehicleDetailCache(int vehicleId) async =>
      await _inspCache.delete('vehicleDetail_$vehicleId');



  static Future<void> saveTireDetailCache(int tireId, String jsonString) async {
    await _inspCache.put('tire_$tireId', jsonString);
  }

  static String? getTireDetailCache(int tireId) =>
      _inspCache.get('tire_$tireId');

  static bool hasTireDetailCache(int tireId) =>
      _inspCache.containsKey('tire_$tireId');

  static Future<void> clearTireDetailCache(int tireId) async {
    await _inspCache.delete('tire_$tireId');
  }



  static Future<void> saveMasterDataJson(String jsonString) async {
    await _inspCache.put('master_data_json', jsonString);
  }

  static String? getMasterDataJson() => _inspCache.get('master_data_json');



  // ════════════════════════════════════════════════════════════
  //  STATUS MASTER (GET /api/MasterData/GetAllStatus)
  //  Inspection Approval Flow — cached at login/download time so the
  //  approval statuses (Pending / Approved / Rejected etc.) are
  //  available offline too.
  // ════════════════════════════════════════════════════════════

  static Future<void> saveStatusMasterJson(String jsonString) async {
    await _inspCache.put('status_master_json', jsonString);
  }

  static String? getStatusMasterJson() =>
      _inspCache.get('status_master_json');

  static bool hasStatusMaster() =>
      _inspCache.containsKey('status_master_json');

  /// Parsed list of status master records, e.g.
  /// [{"statusId": 1, "statusName": "Pending"}, ...]
  /// Returns an empty list if nothing is cached yet or parsing fails.
  static List<Map<String, dynamic>> getStatusMasterList() {
    final raw = getStatusMasterJson();
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      dynamic listPart = decoded;
      if (decoded is Map<String, dynamic>) {
        listPart = decoded['model'] ?? decoded['data'] ?? decoded['list'];
      }
      if (listPart is List) {
        return listPart
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> clearStatusMaster() async =>
      await _inspCache.delete('status_master_json');



  static Future<void> clearAll() async {
    await _master.clear();
    await _vehicles.clear();
    await _tyres.clear();
    await _accounts.clear();
    await _locs.clear();
    await _pending.clear();
    await _inspCache.clear();
  }



  static Future<void> closeAll() async {
    for (final name in [
      _masterBox,
      _vehicleBox,
      _tyreBox,
      _accountBox,
      _locationBox,
      _pendingBox,
      _inspectionCacheBox,
    ]) {
      if (Hive.isBoxOpen(name)) await Hive.box(name).close();
    }
  }
  // static Future<void> setVehicleTireCount(int vehicleId, int count) async {
  //   VehicleHiveModel? v;
  //   try {
  //     v = _vehicles.values.firstWhere((e) => e.vehicleId == vehicleId);
  //   } catch (_) {
  //     return;
  //   }
  //   v.tireCount = count;
  //   await v.save();
  // }

  static List<Map<String, dynamic>> _castList(
      List<Map<dynamic, dynamic>>? raw,
      ) {
    if (raw == null) return [];
    return raw.map((m) => Map<String, dynamic>.from(m)).toList();
  }
}