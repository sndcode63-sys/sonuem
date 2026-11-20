import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inspection_hive_models.dart';
import '../models/offline_hive_models.dart';
import '../utils/secure_storage.dart';
import '../utils/sync_service.dart';
import 'api_constants.dart';
import 'network_sync_servives.dart';

const _inspOpTypes = {
  'inspectTyre',
  'vehicleInspect',
  'installTyre',
  'removeTyre',
  'rotateTireRemove',
  'rotateTireInstall',
  // Approval-flow (temp API) & direct footprint submissions queued offline
  // by VehicleInspeService. Ye pehle is set me nahi the, isliye Home aur
  // View-Inspection ke "Unsynced" list me dikhte hi nahi the.
  'vehicleInspectApprovalTemp',
  'vehicleInspectDirect',
};

const _batchedOpTypes = {
  'vehicleInspectApprovalTemp',
  'vehicleInspectDirect',
};

/// Batched footprint payload me top-level 'vehicleId' nahi hota; wo
/// vehicleList / tireList / inspectionList ke andar hota hai.
String _vidOf(Map<String, dynamic> p) {
  final top = p['vehicleId']?.toString() ?? '';
  if (top.isNotEmpty) return top;
  for (final key in const ['vehicleList', 'tireList', 'inspectionList']) {
    final l = p[key];
    if (l is List && l.isNotEmpty && l.first is Map) {
      final v = (l.first as Map)['vehicleId']?.toString() ?? '';
      if (v.isNotEmpty) return v;
    }
  }
  return '';
}

/// UI metadata (vehicleNumber, comments, date...) ko batched payload se
/// flat map me nikalta hai. Normal ops ke liye payload as-is return hota hai.
Map<String, dynamic> _metaOf(PendingOperationHiveModel op) {
  final p = Map<String, dynamic>.from(op.payload);
  if (!_batchedOpTypes.contains(op.opType)) return p;
  Map<String, dynamic> first(String k) {
    final l = p[k];
    return (l is List && l.isNotEmpty && l.first is Map)
        ? Map<String, dynamic>.from(l.first as Map)
        : <String, dynamic>{};
  }
  final v = first('vehicleList');
  final t = first('tireList');
  return {
    ...p,
    'vehicleId':       _vidOf(p),
    'vehicleNumber':   v['vehicleNumber'] ?? t['vehicleNumber'] ?? '',
    'parentAccountId': v['parentAccountId'] ?? t['parentAccountId'],
    'locationId':      v['locationId'] ?? t['locationId'],
    'inspectionDate':  t['inspectionDate'] ?? v['inspectionDate'] ?? op.createdAt,
    'comments':        t['comments'] ?? '',
    'requestorName':   t['createdBy'] ?? '',
    'totalTyreCount':  (p['tireList'] is List) ? (p['tireList'] as List).length : 0,
  };
}

// 🔧 DEBUG: ek chhota helper — hamesha same tag ke saath print aayega
// taaki logcat/console me filter karna asaan ho ("[INSP-SVC]" search karo)
void _log(String msg) {
  debugPrint('[INSP-SVC] $msg');
}

class InspectionService {

  // Vehicle real-id mappings load
  static Future<void> _loadVehicleRealIdMappings() async {
    final prefs = await SharedPreferences.getInstance();
    int loaded = 0;
    for (final key in prefs.getKeys()) {
      if (key.startsWith('vehicle_real_id_')) {
        final tempId = key.replaceFirst('vehicle_real_id_', '');
        final realId = prefs.getInt(key);
        if (realId != null && realId > 0) {
          OfflineHiveService.registerVehicleRealId(
              tempId: tempId, realId: realId);
          loaded++;
        }
      }
    }
    _log('_loadVehicleRealIdMappings: $loaded vehicle real-id mapping(s) load hui');
  }

  // Get unsynced inspections
  Future<List<InspectionHiveModel>> getUnsyncedInspections() async {
    _log('getUnsyncedInspections() CALLED ---------------------------');
    await _loadVehicleRealIdMappings();

    final ops = OfflineHiveService.getPendingOperations()
        .where((op) => _inspOpTypes.contains(op.opType))
        .toList();
    _log('getUnsyncedInspections: pending inspection-type ops = ${ops.length}');

    final grouped = _groupOpsByVehicle(ops, isSynced: false);
    _log('getUnsyncedInspections: grouped from ops = ${grouped.length}');

    final legacyUnsynced = SyncHiveService.getUnsyncedList();
    _log('getUnsyncedInspections: legacy unsynced list = ${legacyUnsynced.length}');
    grouped.addAll(legacyUnsynced);

    grouped.sort((a, b) => b.inspectionDate.compareTo(a.inspectionDate));
    _log('getUnsyncedInspections: TOTAL unsynced returned = ${grouped.length}');
    for (final g in grouped) {
      _log('   -> UNSYNCED vehicleId=${g.vehicleId} vehicleNo=${g.vehicleNumber} action=${g.action} isSynced=${g.isSynced}');
    }
    return grouped;
  }

  // Get synced inspections
  Future<List<InspectionHiveModel>> getSyncedInspections() async {
    _log('getSyncedInspections() CALLED -----------------------------');
    await _loadVehicleRealIdMappings();

    final allOps = OfflineHiveService.getAllPendingOps()
        .where((op) => _inspOpTypes.contains(op.opType))
        .toList();
    _log('getSyncedInspections: total device ops (all) = ${allOps.length}');

    final vehicleIdsWithAnyPending = <String>{};
    for (final op in allOps) {
      if (!op.isSynced) {
        final p = Map<String, dynamic>.from(op.payload);
        final vid = _normalizeVid(_vidOf(p));
        if (vid.isNotEmpty && vid != '0') {
          vehicleIdsWithAnyPending.add(vid);
        }
      }
    }
    _log('getSyncedInspections: vehicles with pending(unsynced) ops = $vehicleIdsWithAnyPending');

    final syncedOps = allOps.where((op) {
      if (!op.isSynced) return false;
      final p = Map<String, dynamic>.from(op.payload);
      final vid = _normalizeVid(_vidOf(p));
      return !vehicleIdsWithAnyPending.contains(vid);
    }).toList();
    _log('getSyncedInspections: synced ops eligible (vehicle has no pending) = ${syncedOps.length}');

    final grouped = _groupOpsByVehicle(syncedOps, isSynced: true);

    final legacySynced = SyncHiveService.getSyncedList().where(
          (ins) => !vehicleIdsWithAnyPending.contains(ins.vehicleId),
    );
    _log('getSyncedInspections: legacy synced (after filter) = ${legacySynced.length}');
    grouped.addAll(legacySynced);
    grouped.sort((a, b) => (b.syncedAt ?? '').compareTo(a.syncedAt ?? ''));

    _log('getSyncedInspections: TOTAL synced returned = ${grouped.length}');
    for (final g in grouped) {
      _log('   -> SYNCED vehicleId=${g.vehicleId} vehicleNo=${g.vehicleNumber} action=${g.action} syncedAt=${g.syncedAt}');
    }
    return grouped;
  }

  // Normalize vehicleId
  static String _normalizeVid(String vid) {
    if (vid.startsWith('-')) {
      final real = OfflineHiveService.getVehicleRealIdMappingsSync()[vid];
      if (real != null && real > 0) {
        _log('_normalizeVid: tempId=$vid -> realId=$real');
        return real.toString();
      }
    }
    return vid;
  }

  //  Group ops by vehicle
  static List<InspectionHiveModel> _groupOpsByVehicle(
      List<PendingOperationHiveModel> ops, {
        required bool isSynced,
      }) {
    const tireOps = {
      'inspectTyre',
      'installTyre',
      'removeTyre',
      'rotateTireRemove',
      'rotateTireInstall',
    };

    final Map<String, List<PendingOperationHiveModel>> groups = {};
    for (final op in ops) {
      final p = Map<String, dynamic>.from(op.payload);
      final rawVid = _vidOf(p);
      if (rawVid.isEmpty || rawVid == '0') continue;
      final vid = _normalizeVid(rawVid);
      groups.putIfAbsent(vid, () => []).add(op);
    }
    _log('_groupOpsByVehicle(isSynced=$isSynced): ${ops.length} ops -> ${groups.length} vehicle group(s)');

    final allPendingDeviceOps = OfflineHiveService.getAllPendingOps();
    final result = <InspectionHiveModel>[];

    for (final entry in groups.entries) {
      final vehicleId  = entry.key;
      final opsInGroup = entry.value
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final rep = opsInGroup.first;
      _log('  group vehicleId=$vehicleId : ${opsInGroup.length} op(s) -> [${opsInGroup.map((o) => o.opType).join(", ")}]');

      // ── Metadata accumulation ──
      String vehicleNumber    = '';
      String accountName      = '';
      String locationName     = '';
      String requestorName    = '';
      String comments         = '';
      int    parentAccountId  = 0;
      int    locationId       = 0;
      String inspectionDate   = rep.createdAt;
      String? syncedAt        = rep.syncedAt;

      final globalUpdateVehicleOp = allPendingDeviceOps.firstWhereOrNull((op) {
        if (op.opType != 'updateVehicle') return false;
        final uvp = Map<String, dynamic>.from(op.payload);
        return _normalizeVid(uvp['vehicleId']?.toString() ?? '') == vehicleId;
      });

      if (globalUpdateVehicleOp != null) {
        final uvp = Map<String, dynamic>.from(globalUpdateVehicleOp.payload);
        final updatedNo = uvp['vehicleNumber']?.toString() ?? '';
        if (updatedNo.isNotEmpty) vehicleNumber = updatedNo;
      }

      // Local updateVehicle op within group
      if (vehicleNumber.isEmpty) {
        final localUpdateOp = opsInGroup
            .firstWhereOrNull((op) => op.opType == 'updateVehicle');
        if (localUpdateOp != null) {
          final uvp = Map<String, dynamic>.from(localUpdateOp.payload);
          final updatedNo = uvp['vehicleNumber']?.toString() ?? '';
          if (updatedNo.isNotEmpty) vehicleNumber = updatedNo;
        }
      }

      // Fill metadata from group ops
      for (final op in opsInGroup) {
        final pp = _metaOf(op);
        if (vehicleNumber.isEmpty)  vehicleNumber   = pp['vehicleNumber']?.toString()   ?? '';
        if (accountName.isEmpty)    accountName     = pp['accountName']?.toString()     ?? '';
        if (locationName.isEmpty)   locationName    = pp['locationName']?.toString()    ?? '';
        if (requestorName.isEmpty)  requestorName   = pp['requestorName']?.toString()   ?? '';
        if (comments.isEmpty)       comments        = pp['comments']?.toString()        ?? '';
        if (parentAccountId == 0)   parentAccountId = _int(pp['parentAccountId']);
        if (locationId == 0)        locationId      = _int(pp['locationId']);

        final d = pp['inspectionDate']?.toString() ?? '';
        if (d.isNotEmpty &&
            (inspectionDate == rep.createdAt ||
                d.compareTo(inspectionDate) < 0)) {
          inspectionDate = d;
        }
        if (syncedAt == null && op.syncedAt != null) syncedAt = op.syncedAt;
      }

      // Fallback: any other pending op for this vehicle
      if (vehicleNumber.isEmpty ||
          accountName.isEmpty ||
          locationName.isEmpty ||
          requestorName.isEmpty) {
        final fallbackOp = allPendingDeviceOps.firstWhereOrNull((op) {
          if (!_inspOpTypes.contains(op.opType)) return false;
          final pp = Map<String, dynamic>.from(op.payload);
          if (_normalizeVid(_vidOf(pp)) != vehicleId) {
            return false;
          }
          return (pp['vehicleNumber']?.toString() ?? '').isNotEmpty ||
              (pp['accountName']?.toString() ?? '').isNotEmpty ||
              (pp['locationName']?.toString() ?? '').isNotEmpty ||
              (pp['requestorName']?.toString() ?? '').isNotEmpty;
        });

        if (fallbackOp != null) {
          _log('  group vehicleId=$vehicleId : metadata fallback op mila (opId=${fallbackOp.id})');
          final fp = Map<String, dynamic>.from(fallbackOp.payload);
          if (vehicleNumber.isEmpty)  vehicleNumber   = fp['vehicleNumber']?.toString()   ?? '';
          if (accountName.isEmpty)    accountName     = fp['accountName']?.toString()     ?? '';
          if (locationName.isEmpty)   locationName    = fp['locationName']?.toString()    ?? '';
          if (requestorName.isEmpty)  requestorName   = fp['requestorName']?.toString()   ?? '';
          if (parentAccountId == 0)   parentAccountId = _int(fp['parentAccountId']);
          if (locationId == 0)        locationId      = _int(fp['locationId']);
        }
      }

      final tireOpsInGroup = opsInGroup
          .where((op) => tireOps.contains(op.opType))
          .toList();

      final Map<String, String> uniquePositionToTireMap = {};
      for (final op in tireOpsInGroup) {
        final pp  = Map<String, dynamic>.from(op.payload);
        final tid = pp['tireId']?.toString() ?? '';
        final wp  = pp['wheelPosition']?.toString() ?? '';
        final key = wp.isNotEmpty
            ? wp
            : (tid.isNotEmpty && tid != '0' ? tid : '');
        if (key.isNotEmpty) uniquePositionToTireMap[key] = tid;
      }

      // Batched (temp/direct) ops: tireList ke andar tyres hote hain
      for (final op in opsInGroup.where((o) => _batchedOpTypes.contains(o.opType))) {
        final tl = op.payload['tireList'];
        if (tl is List) {
          for (final t in tl) {
            if (t is! Map) continue;
            final wp  = t['wheelPosition']?.toString() ?? '';
            final tid = t['tireId']?.toString() ?? '';
            final key = wp.isNotEmpty ? wp : tid;
            if (key.isNotEmpty) uniquePositionToTireMap[key] = tid;
          }
        }
      }

      final inspectedCount = uniquePositionToTireMap.isNotEmpty
          ? uniquePositionToTireMap.length
          : tireOpsInGroup.length;

      int totalCount = 0;
      for (final op in opsInGroup) {
        final pp = Map<String, dynamic>.from(op.payload);
        final tc = _int(pp['totalTyreCount']);
        if (tc > totalCount) totalCount = tc;
      }
      if (totalCount == 0) totalCount = inspectedCount;

      final repOpType = opsInGroup
          .map((o) => o.opType)
          .firstWhere(
              (t) => t == 'vehicleInspect' || t == 'inspectTyre',
          orElse: () => rep.opType);

      String groupAction = _actionFromOpType(repOpType);
      final batchedOp = opsInGroup.firstWhereOrNull((o) => _batchedOpTypes.contains(o.opType));
      if (batchedOp != null) {
        final tl = batchedOp.payload['tireList'];
        if (tl is List && tl.isNotEmpty && tl.first is Map) {
          final a = (tl.first as Map)['action']?.toString() ?? '';
          if (a.isNotEmpty) groupAction = a;
        }
      }

      _log('  group vehicleId=$vehicleId : vehicleNumber="$vehicleNumber" inspectedCount=$inspectedCount/$totalCount action=${_actionFromOpType(repOpType)} isSynced=$isSynced syncedAt=$syncedAt');

      result.add(InspectionHiveModel(
        id:                 vehicleId,
        vehicleId:          vehicleId,
        vehicleNumber:      vehicleNumber.isNotEmpty
            ? vehicleNumber
            : 'Vehicle $vehicleId',
        accountName:        accountName,
        locationName:       locationName,
        parentAccountId:    parentAccountId,
        locationId:         locationId,
        inspectionDate:     inspectionDate,
        approverName:       '',
        requestorName:      requestorName,
        comments:           comments,
        status:             'A',
        isSynced:           isSynced,
        syncedAt:           syncedAt,
        inspectedTyreCount: inspectedCount,
        totalTyreCount:     totalCount,
        rejectionReason:    null,
        approverEmail:      null,
        action:             groupAction,
      ));
    }

    return result;
  }

  // : Save inspection offline
  Future<void> saveInspectionOffline(Map<String, dynamic> payload) async {
    final action = payload['action']?.toString() ?? 'Inspect';
    _log('saveInspectionOffline: action=$action vehicleId=${payload['vehicleId']} tireId=${payload['tireId']} -> opType=${_opTypeFromAction(action)} endpoint=${_endpointForAction(action)}');
    await OfflineHiveService.addPendingOperation(
      opType:     _opTypeFromAction(action),
      payload:    payload,
      endpoint:   _endpointForAction(action),
      httpMethod: 'PUT',
    );
    _log('saveInspectionOffline: pending operation ADD ho gaya (offline queue me)');
  }

  //  Sync single inspection  🔘 (SYNC-SINGLE BUTTON yaha se call hota hai)
  Future<bool> syncInspection(InspectionHiveModel inspection) async {
    _log('🔘 SYNC SINGLE BUTTON PRESSED -> syncInspection() vehicleId=${inspection.vehicleId} vehicleNo=${inspection.vehicleNumber} id=${inspection.id}');
    return SyncCoordinator.runExclusive<bool>(() async {
      final allOps = OfflineHiveService.getAllPendingOps()
          .where((o) => _inspOpTypes.contains(o.opType) && !o.isSynced)
          .toList();
      _log('syncInspection: total unsynced inspection ops on device = ${allOps.length}');

      // 🐛 FIX: pehle sirf raw payload['vehicleId'] se direct '==' compare hota
      // tha. List me dikhne wala inspection.vehicleId NORMALIZED (real id)
      // hota hai (_groupOpsByVehicle -> _normalizeVid), lekin agar wo vehicle
      // offline create hua tha aur abhi tak sirf createVehicle sync hua hai,
      // to us tyre-op ke Hive payload me abhi bhi PURANA temp (negative) id
      // pada rehta hai. Isliye raw id match nahi hota, relatedOps EMPTY aa
      // jaata, aur code galti se legacy path me chala jaata jo fail ho ke
      // FALSE return karta -> red "Syncing Unsuccessful" toast, jabki asal me
      // op bilkul sync-able tha. Ab hum raw id AUR normalized id dono se
      // match check karte hain.
      final relatedOps = inspection.vehicleId.isNotEmpty
          ? allOps.where((o) {
        final p = Map<String, dynamic>.from(o.payload);
        final rawVid = _vidOf(p);
        final normVid = _normalizeVid(rawVid);
        return rawVid == inspection.vehicleId || normVid == inspection.vehicleId;
      }).toList()
          : allOps.where((o) => o.id == inspection.id).toList();
      _log('syncInspection: related ops for vehicleId=${inspection.vehicleId} = ${relatedOps.length} -> [${relatedOps.map((o) => o.opType).join(", ")}]');
      if (relatedOps.isEmpty) {
        _log('syncInspection: ⚠️ relatedOps EMPTY hai — agar ye vehicle offline-created tha to ho sakta hai payload me abhi bhi temp/negative vehicleId pada ho. allOps ke raw vehicleId dump: ${allOps.map((o) => "${o.opType}:${o.payload['vehicleId']}").toList()}');
      }

      if (relatedOps.isNotEmpty) {
        int _priority(String opType) {
          if (opType == 'removeTyre' || opType == 'rotateTireRemove') return 0;
          if (opType == 'installTyre' || opType == 'rotateTireInstall') return 1;
          return 2;
        }

        relatedOps.sort((a, b) {
          final pa = _priority(a.opType);
          final pb = _priority(b.opType);
          if (pa != pb) return pa.compareTo(pb);
          return a.createdAt.compareTo(b.createdAt);
        });

        bool anyOk = false;
        final List<PendingOperationHiveModel> stillFailed = [];

        for (final op in relatedOps) {
          _log('syncInspection: -> calling API for opId=${op.id} opType=${op.opType}');
          final ok = await _callApiForOp(op);
          _log('syncInspection: <- result for opId=${op.id} opType=${op.opType} = ${ok ? "✅ SUCCESS" : "❌ FAILED"}');
          if (ok) {
            await OfflineHiveService.markOperationSynced(op.id);
            await OfflineHiveService.applyPostSyncTyreUpdate(
              opType:  op.opType,
              payload: Map<String, dynamic>.from(op.payload),
            );
            anyOk = true;
          } else {
            stillFailed.add(op);
          }
        }

        // Retry once after 1 second
        if (stillFailed.isNotEmpty) {
          _log('syncInspection: ${stillFailed.length} op(s) failed, 1 sec baad RETRY karenge');
          await Future.delayed(const Duration(seconds: 1));
          for (final op in stillFailed) {
            _log('syncInspection: RETRY -> opId=${op.id} opType=${op.opType}');
            final ok = await _callApiForOp(op);
            _log('syncInspection: RETRY result opId=${op.id} = ${ok ? "✅ SUCCESS" : "❌ STILL FAILED"}');
            if (ok) {
              await OfflineHiveService.markOperationSynced(op.id);
              await OfflineHiveService.applyPostSyncTyreUpdate(
                opType:  op.opType,
                payload: Map<String, dynamic>.from(op.payload),
              );
              anyOk = true;
            }
          }
        }

        _log('syncInspection: FINAL RESULT for vehicleId=${inspection.vehicleId} => ${anyOk ? "✅ SYNCED (at least 1 op ok)" : "❌ NOT SYNCED (sab fail)"}');
        return anyOk;
      }

      // 🐛 FIX #2: relatedOps khaali hone ka MATLAB ye nahi ki ye ek legacy
      // unsynced record hai — 90% case me iska matlab hota hai ki is
      // vehicle ke saare ops PEHLE SE HI SYNCED ho chuke hain (jaisa is
      // exact log me hua: "pending inspection-type ops = 0"). Pehle code
      // blindly _syncLegacy() bula deta tha, jo bina 'Action' field ke API
      // call karta aur backend se 400 "Action field is required" wapas
      // aata -> galat RED/FAIL toast, jabki row already sync ho chuki thi.

      // (a) Pehle asli legacy (SyncHiveService) unsynced list me dhundo —
      // sirf yahi genuine "legacy path" case hai.
      final legacyMatch = SyncHiveService.getUnsyncedList().firstWhereOrNull(
            (ins) => ins.id == inspection.id || ins.vehicleId == inspection.vehicleId,
      );
      if (legacyMatch != null) {
        _log('syncInspection: legacy unsynced entry mila (id=${legacyMatch.id}) -> _syncLegacy() call kar rahe hain');
        return _syncLegacy(legacyMatch);
      }

      // (b) Legacy me bhi nahi mila -> check karo ki is vehicle ke device
      // pe ops the hi lekin sab already synced hain. Agar haan, to karne
      // ko kuch hai hi nahi -> ye SUCCESS hai, FAIL nahi.
      final allDeviceOpsForVehicle = OfflineHiveService.getAllPendingOps()
          .where((o) => _inspOpTypes.contains(o.opType))
          .where((o) {
        final p = Map<String, dynamic>.from(o.payload);
        final rawVid = _vidOf(p);
        return rawVid == inspection.vehicleId || _normalizeVid(rawVid) == inspection.vehicleId;
      }).toList();

      if (allDeviceOpsForVehicle.isNotEmpty &&
          allDeviceOpsForVehicle.every((o) => o.isSynced)) {
        _log('syncInspection: ✅ is vehicle ke saare ${allDeviceOpsForVehicle.length} op(s) PEHLE SE SYNCED hain — kuch karne ki zaroorat nahi, SUCCESS treat kar rahe hain');
        return true;
      }

      _log('syncInspection: ❌ na pending op mila, na legacy record, na already-synced ops — genuinely kuch sync-able nahi mila, FALSE return');
      return false;
    });
  }

  //  Sync all pending inspections  🔘 (SYNC-ALL BUTTON yaha se call hota hai)
  Future<Map<String, int>> syncAll() async {
    _log('🔘 SYNC ALL BUTTON PRESSED -> syncAll() STARTED ==========================');
    return SyncCoordinator.runExclusive<Map<String, int>>(() async {
      int success = 0, failed = 0;
      final List<PendingOperationHiveModel> failedOpsForRetry = [];

      // Reload vehicle real-id mappings
      final prefs = await SharedPreferences.getInstance();
      await _reloadVehicleMappings(prefs);

      final allOps = OfflineHiveService.getPendingOperations()
          .where((op) => _inspOpTypes.contains(op.opType))
          .toList();
      _log('syncAll: total pending inspection ops = ${allOps.length}');

      // ── Remove ops: sequential ──
      final removeOps = allOps
          .where((op) =>
      op.opType == 'removeTyre' || op.opType == 'rotateTireRemove')
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _log('syncAll: STAGE 1 (remove ops, sequential) count=${removeOps.length}');

      for (final op in removeOps) {
        await Future<void>.delayed(Duration.zero);
        _log('syncAll: [remove] calling API opId=${op.id} opType=${op.opType}');
        final ok = await _callApiForOp(op);
        _log('syncAll: [remove] result opId=${op.id} = ${ok ? "✅ SUCCESS" : "❌ FAILED"}');
        if (ok) {
          await OfflineHiveService.markOperationSynced(op.id);
          await OfflineHiveService.applyPostSyncTyreUpdate(
            opType:  op.opType,
            payload: Map<String, dynamic>.from(op.payload),
          );
          success++;
        } else {
          await OfflineHiveService.incrementRetryCount(op.id,
              error: 'API failure');
          failed++;
          failedOpsForRetry.add(op);
        }
      }

      // ── Install ops: sequential ──
      final installOps = allOps
          .where((op) =>
      op.opType == 'installTyre' || op.opType == 'rotateTireInstall')
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _log('syncAll: STAGE 2 (install ops, sequential) count=${installOps.length}');

      for (final op in installOps) {
        _log('syncAll: [install] calling API opId=${op.id} opType=${op.opType}');
        final ok = await _callApiForOp(op);
        _log('syncAll: [install] result opId=${op.id} = ${ok ? "✅ SUCCESS" : "❌ FAILED"}');
        if (ok) {
          await OfflineHiveService.markOperationSynced(op.id);
          await OfflineHiveService.applyPostSyncTyreUpdate(
            opType:  op.opType,
            payload: Map<String, dynamic>.from(op.payload),
          );
          success++;
        } else {
          await OfflineHiveService.incrementRetryCount(op.id,
              error: 'API failure');
          failed++;
          failedOpsForRetry.add(op);
        }
      }

      // ── Other ops: parallel ──
      final otherOps = allOps
          .where((op) =>
      op.opType != 'installTyre' &&
          op.opType != 'rotateTireInstall' &&
          op.opType != 'removeTyre' &&
          op.opType != 'rotateTireRemove')
          .toList();
      _log('syncAll: STAGE 3 (other ops, parallel) count=${otherOps.length}');

      final otherResults = await Future.wait(
        otherOps.map((op) async {
          _log('syncAll: [other] calling API opId=${op.id} opType=${op.opType}');
          final ok = await _callApiForOp(op);
          _log('syncAll: [other] result opId=${op.id} opType=${op.opType} = ${ok ? "✅ SUCCESS" : "❌ FAILED"}');
          if (ok) {
            await OfflineHiveService.markOperationSynced(op.id);
            await OfflineHiveService.applyPostSyncTyreUpdate(
              opType:  op.opType,
              payload: Map<String, dynamic>.from(op.payload),
            );
            return true;
          } else {
            await OfflineHiveService.incrementRetryCount(op.id,
                error: 'API failure');
            return false;
          }
        }),
        eagerError: false,
      );

      for (int i = 0; i < otherResults.length; i++) {
        if (otherResults[i]) {
          success++;
        } else {
          failed++;
          failedOpsForRetry.add(otherOps[i]);
        }
      }

      // ── Legacy SyncHive: parallel ──
      final legacyList = SyncHiveService.getUnsyncedList();
      _log('syncAll: STAGE 4 (legacy inspections, parallel) count=${legacyList.length}');
      final legacyResults = await Future.wait(
        legacyList.map((ins) => _syncLegacy(ins)),
        eagerError: false,
      );
      final List<InspectionHiveModel> legacyFailedForRetry = [];
      for (int i = 0; i < legacyResults.length; i++) {
        _log('syncAll: [legacy] vehicleId=${legacyList[i].vehicleId} = ${legacyResults[i] ? "✅ SUCCESS" : "❌ FAILED"}');
        if (legacyResults[i]) {
          success++;
        } else {
          failed++;
          legacyFailedForRetry.add(legacyList[i]);
        }
      }

      _log('syncAll: after all stages -> success=$success failed=$failed (before retry)');

      // ── Retry failed ops after 2 seconds ──
      if (failedOpsForRetry.isNotEmpty || legacyFailedForRetry.isNotEmpty) {
        _log('syncAll: RETRY STAGE -> ${failedOpsForRetry.length} op(s) + ${legacyFailedForRetry.length} legacy, 2 sec baad retry');
        await Future.delayed(const Duration(seconds: 2));
        await _reloadVehicleMappings(prefs);

        failedOpsForRetry.sort((a, b) {
          int prio(String t) {
            if (t == 'removeTyre' || t == 'rotateTireRemove') return 0;
            if (t == 'installTyre' || t == 'rotateTireInstall') return 1;
            return 2;
          }
          final pa = prio(a.opType);
          final pb = prio(b.opType);
          if (pa != pb) return pa.compareTo(pb);
          return a.createdAt.compareTo(b.createdAt);
        });

        for (final op in failedOpsForRetry) {
          if (op.isSynced) continue;
          _log('syncAll: RETRY -> opId=${op.id} opType=${op.opType}');
          final ok = await _callApiForOp(op);
          _log('syncAll: RETRY result opId=${op.id} = ${ok ? "✅ SUCCESS" : "❌ STILL FAILED"}');
          if (ok) {
            await OfflineHiveService.markOperationSynced(op.id);
            await OfflineHiveService.applyPostSyncTyreUpdate(
              opType:  op.opType,
              payload: Map<String, dynamic>.from(op.payload),
            );
            success++;
            failed--;
          } else {
            await OfflineHiveService.incrementRetryCount(op.id,
                error: 'API failure (retry)');
          }
        }

        for (final ins in legacyFailedForRetry) {
          _log('syncAll: RETRY legacy -> vehicleId=${ins.vehicleId}');
          final ok = await _syncLegacy(ins);
          _log('syncAll: RETRY legacy result vehicleId=${ins.vehicleId} = ${ok ? "✅ SUCCESS" : "❌ STILL FAILED"}');
          if (ok) {
            success++;
            failed--;
          }
        }
      }

      _log('syncAll: ============ FINAL RESULT -> success=$success failed=$failed ============');
      return {'success': success, 'failed': failed};
    });
  }

  // ─────────────────────────────────────────────────────────
  // PUBLIC: Delete inspection
  // ─────────────────────────────────────────────────────────
  Future<void> deleteInspection(String vehicleIdOrOpId) async {
    _log('🔘 DELETE BUTTON PRESSED -> deleteInspection(id=$vehicleIdOrOpId)');
    final allOps = OfflineHiveService.getAllPendingOps()
        .where((o) => _inspOpTypes.contains(o.opType))
        .toList();

    bool deleted = false;
    for (final op in allOps) {
      final p = Map<String, dynamic>.from(op.payload);
      final vid = _vidOf(p);
      if (vid == vehicleIdOrOpId || op.id == vehicleIdOrOpId) {
        _log('deleteInspection: matching pending op mila opId=${op.id} opType=${op.opType} -> delete kar rahe hain');
        await OfflineHiveService.deletePendingOperation(op.id);
        deleted = true;
      }
    }

    if (!deleted) {
      _log('deleteInspection: koi pending op nahi mila, legacy delete try kar rahe hain');
      await SyncHiveService.deleteInspection(vehicleIdOrOpId);
    }
    _log('deleteInspection: DONE deleted=$deleted');
  }

  // ─────────────────────────────────────────────────────────
  // PRIVATE: HTTP call for a single PendingOperationHiveModel
  // ─────────────────────────────────────────────────────────
  Future<bool> _callApiForOp(PendingOperationHiveModel op) async {
    try {
      final cookie  = await SecureStorage.getCookie() ?? '';
      final payload = Map<String, dynamic>.from(op.payload);
      final prefs   = await SharedPreferences.getInstance();

      if (cookie.isEmpty) {
        _log('_callApiForOp[${op.id}]: ⚠️ COOKIE EMPTY HAI — login/session expired ho sakta hai');
      }

      // Batched (temp/direct) payload: nested negative ids resolve karo
      if (_batchedOpTypes.contains(op.opType)) {
        final resolved = await OfflineHiveService.resolveBatchedTempIds(payload);
        if (resolved == null) {
          _log('_callApiForOp[${op.id}]: ❌ FAIL - nested temp vehicleId/tireId abhi resolve nahi hui (createVehicle/createTyre pehle sync hona chahiye)');
          return false;
        }
        payload
          ..clear()
          ..addAll(resolved);
      }

      // Resolve negative tireId
      final rawTireId = payload['tireId'];
      if (rawTireId != null) {
        final tireIdStr = rawTireId.toString();
        if (tireIdStr.startsWith('-')) {
          final realTireId = prefs.getInt('tyre_real_id_$tireIdStr');
          if (realTireId != null && realTireId > 0) {
            payload['tireId']     = realTireId;
            op.payload['tireId']  = realTireId;
            await op.save();
            _log('_callApiForOp[${op.id}]: temp tireId=$tireIdStr -> realId=$realTireId resolve hua');
          } else {
            _log('_callApiForOp[${op.id}]: ❌ FAIL - temp tireId=$tireIdStr abhi tak resolve nahi hua (createTyre pehle sync hona chahiye)');
            return false;
          }
        }
      }

      // Resolve negative vehicleId
      final rawVehicleId = payload['vehicleId'];
      if (rawVehicleId != null) {
        final vIdStr = rawVehicleId.toString();
        if (vIdStr.startsWith('-')) {
          final realVehicleId = prefs.getInt('vehicle_real_id_$vIdStr');
          if (realVehicleId != null && realVehicleId > 0) {
            payload['vehicleId']     = realVehicleId;
            op.payload['vehicleId']  = realVehicleId;
            await op.save();
            _log('_callApiForOp[${op.id}]: temp vehicleId=$vIdStr -> realId=$realVehicleId resolve hua (prefs)');
          } else {
            final mappings    = OfflineHiveService.getVehicleRealIdMappingsSync();
            final resolvedId  = mappings[vIdStr];
            if (resolvedId != null && resolvedId > 0) {
              payload['vehicleId']     = resolvedId;
              op.payload['vehicleId']  = resolvedId;
              await op.save();
              _log('_callApiForOp[${op.id}]: temp vehicleId=$vIdStr -> realId=$resolvedId resolve hua (hive map)');
            } else {
              _log('_callApiForOp[${op.id}]: ❌ FAIL - temp vehicleId=$vIdStr abhi tak resolve nahi hua (createVehicle pehle sync hona chahiye)');
              return false;
            }
          }
        }
      }

      // Ensure rimDispositionId has a default
      final existingRim = payload['rimDispositionId'];
      if (!_batchedOpTypes.contains(op.opType) &&
          (existingRim == null || existingRim == '' || existingRim == 0)) {
        payload['rimDispositionId'] = 0;
      }

      // Strip UI-only fields before sending
      payload.remove('isPendingSync');
      payload.remove('vehicleNumber');
      payload.remove('locationName');
      payload.remove('accountName');
      payload.remove('requestorName');
      payload.remove('inspectedTyreCount');
      payload.remove('totalTyreCount');

      final uri = Uri.parse('${ApiConstants.baseUrl}${op.endpoint}');
      final headers = {
        'Content-Type': 'application/json',
        if (cookie.isNotEmpty) 'Cookie': cookie,
      };

      final isRemoveOp = op.opType == 'removeTyre' ||
          op.opType == 'rotateTireRemove';
      final body = jsonEncode(isRemoveOp ? [payload] : payload);

      _log('_callApiForOp[${op.id}]: ${op.httpMethod} $uri | opType=${op.opType} | body=$body');

      final response = op.httpMethod.toUpperCase() == 'PUT'
          ? await http
          .put(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 30))
          : await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      _log('_callApiForOp[${op.id}]: HTTP status=${response.statusCode} | resp=${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _log('_callApiForOp[${op.id}]: ❌ FAIL - HTTP status non-2xx');
        return false;
      }

      // Backend can return HTTP 200 with a business-logic failure encoded
      // in the body (didError: true) — e.g. tire already installed
      // elsewhere. Treating that as success silently drops the operation
      // and leaves local data permanently out of sync with the server.
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('didError')) {
          final ok = decoded['didError'] == false;
          _log('_callApiForOp[${op.id}]: didError=${decoded['didError']} -> ${ok ? "✅ SUCCESS" : "❌ FAIL (business logic error)"} msg=${decoded['message'] ?? decoded['errorMessage'] ?? ''}');
          return ok;
        }
        if (decoded is List) {
          final ok = decoded.every((e) => e is! Map || e['didError'] != true);
          _log('_callApiForOp[${op.id}]: list-response didError check -> ${ok ? "✅ SUCCESS" : "❌ FAIL"}');
          return ok;
        }
      } catch (_) {
        // Non-JSON body — fall back to HTTP status only.
        _log('_callApiForOp[${op.id}]: response JSON nahi hai, HTTP status ke hisaab se ✅ SUCCESS maan rahe hain');
      }

      _log('_callApiForOp[${op.id}]: ✅ SUCCESS');
      return true;
    } catch (e) {
      _log('_callApiForOp[${op.id}]: ❌ EXCEPTION -> $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // PRIVATE: Sync legacy InspectionHiveModel
  // ─────────────────────────────────────────────────────────
  Future<bool> _syncLegacy(InspectionHiveModel ins) async {
    try {
      final cookie = await SecureStorage.getCookie();
      if (cookie == null || cookie.isEmpty) {
        _log('_syncLegacy[${ins.vehicleId}]: ❌ FAIL - cookie missing/empty');
        return false;
      }

      final url = Uri.parse(
        '${ApiConstants.baseUrl}${_endpointForAction(ins.action)}',
      );

      final bodyMap = {
        'vehicleId':       ins.vehicleId,
        'vehicleNumber':   ins.vehicleNumber,
        'parentAccountId': ins.parentAccountId,
        'locationId':      ins.locationId,
        'inspectionDate':  ins.inspectionDate,
        'requestorName':   ins.requestorName,
        'comments':        ins.comments,
        'status':          ins.status,
        // 🐛 FIX: backend "Action field is required" 400 deta tha kyunki
        // ye field bhejte hi nahi the.
        'action':          ins.action,
      };
      _log('_syncLegacy[${ins.vehicleId}]: PUT $url | body=${jsonEncode(bodyMap)}');

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json', 'Cookie': cookie},
        body: jsonEncode(bodyMap),
      ).timeout(const Duration(seconds: 20));

      _log('_syncLegacy[${ins.vehicleId}]: HTTP status=${response.statusCode} resp=${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        await SyncHiveService.markAsSynced(ins.id);
        _log('_syncLegacy[${ins.vehicleId}]: ✅ SUCCESS, markAsSynced ho gaya');
        return true;
      }
      _log('_syncLegacy[${ins.vehicleId}]: ❌ FAIL - status ${response.statusCode}');
      return false;
    } catch (e) {
      _log('_syncLegacy[${ins.vehicleId}]: ❌ EXCEPTION -> $e');
      return false;
    }
  }

  //  HELPERS
  static Future<void> _reloadVehicleMappings(SharedPreferences prefs) async {
    int loaded = 0;
    for (final key in prefs.getKeys()) {
      if (key.startsWith('vehicle_real_id_')) {
        final tempId = key.replaceFirst('vehicle_real_id_', '');
        final realId = prefs.getInt(key);
        if (realId != null && realId > 0) {
          OfflineHiveService.registerVehicleRealId(
              tempId: tempId, realId: realId);
          loaded++;
        }
      }
    }
    _log('_reloadVehicleMappings: $loaded mapping(s) reload hui');
  }

  static String _opTypeFromAction(String action) {
    switch (action) {
      case 'Install': return 'installTyre';
      case 'Remove':  return 'removeTyre';
      default:        return 'vehicleInspect';
    }
  }

  static String _endpointForAction(String action) {
    switch (action) {
      case 'Install': return ApiConstants.installTire;   // /api/Inspection/InstallTire
      case 'Remove':  return ApiConstants.removeTire;    // /api/Inspection/RemoveTire
      default:        return ApiConstants.inspectTire;   // /api/Inspection/InspectTire
    }
  }

  static String _actionFromOpType(String opType) {
    switch (opType) {
      case 'installTyre':
      case 'rotateTireInstall':
        return 'Install';
      case 'removeTyre':
      case 'rotateTireRemove':
        return 'Remove';
      default:
        return 'Inspect';
    }
  }

  static int _int(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}
