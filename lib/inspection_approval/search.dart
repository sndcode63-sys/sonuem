import 'package:emtrack/utils/mesurment_helper_class.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emtrack/search_tyre_vehicle/tire_item_model.dart';
import 'package:emtrack/search_tyre_vehicle/vehicle_item_model.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_constants.dart';

const String _kYellow = '\x1B[33m';
const String _kReset = '\x1B[0m';
void _logYellow(String msg) {
  debugPrint('$_kYellow🟡 [IWSearchController] $msg$_kReset');
}

enum IWInspectionStatus { pending, approved, rejected }

class IWSearchController extends GetxController {
  final int initialTab;
  IWSearchController({this.initialTab = 0});

  final SearchApi _api = SearchApi();

  final RxInt selectedTab = 0.obs;
  final RxString searchText = ''.obs;
  final RxBool isLoading = false.obs;

  final RxList<VehicleItem> vehicles = <VehicleItem>[].obs;
  final RxList<TireItem> tyres = <TireItem>[].obs;
  final RxList<dynamic> visibleList = <dynamic>[].obs;

  /// Raw result of GET /api/Inspection/GetAllPendingInspections/{AccountId}
  final RxList<PendingInspectionEntry> pendingInspections =
      <PendingInspectionEntry>[].obs;

  final RxList<VehicleItem> recentVehicles = <VehicleItem>[].obs;
  final RxList<TireItem> recentTyres = <TireItem>[].obs;

  final Map<String, IWInspectionStatus> statusMap = {};

  // 🔧 Composite keys: vehicleId/tireId ALONE unique nahi hai kyunki same
  // vehicle/tyre ki multiple pending inspections ho sakti hain. Isliye
  // pendingInspectionId (jab available ho) ko bhi key mein jodte hain,
  // taaki har CARD apna status/removal independently track kare.
  String _vehicleKey(VehicleItem v) =>
      '${v.vehicleId}_${v.pendingInspectionId ?? ''}';

  String _tireKey(TireItem t) =>
      '${t.tireId}_${t.pendingInspectionId ?? ''}';

  static Future<bool> _isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  @override
  void onInit() {
    super.onInit();
    selectedTab.value = initialTab;
    _loadData();
    _loadRecentFromStorage();
  }

  Future<void> refreshData() => _loadData();

  Future<void> _loadData() async {
    int? accountId;
    try {
      isLoading.value = true;
      _logYellow('🚀 Simple API _loadData STARTED');

      final int? profileAccountId = await SecureStorage.getProfileParentAccountId();
      accountId = profileAccountId ?? int.tryParse(await SecureStorage.getParentAccountId() ?? '');

      if (accountId == null) {
        _logYellow('❌ accountId is NULL. Stopping data load.');
        return;
      }

      final online = await _isOnline();
      if (!online) {
        _logYellow('📴 DEVICE OFFLINE -> Loading pending inspections from local storage');
        pendingInspections.clear();
      } else {
        // 🌐 Direct API Call
        try {
          pendingInspections.value = await _api.fetchPendingInspections(accountId);
          _logYellow('📥 fetchPendingInspections SUCCESS -> ${pendingInspections.length} item(s) found');
        } catch (e) {
          _logYellow('⚠️ fetchPendingInspections API call failed: $e');
          pendingInspections.clear();
        }
      }

      // 🔧 EK vehicle/tyre ki MULTIPLE pending inspections ho sakti hain
      // (har ek apne khud ke InspectionStatusId ke saath). Pehle yeh
      // vehicleId/tireId KEYED Map mein store hote the, isliye same
      // vehicleId/tireId doosri baar aane par pehli entry OVERWRITE ho
      // jaati thi aur sirf 1 hi card dikhta tha. Ab har pending-inspection
      // "event" ke liye ALAG List entry banate hain (List — Map nahi),
      // taaki same vehicleId/tireId ke MULTIPLE cards bhi sahi se dikhein.
      // Har entry apna khud ka `pendingInspectionId` (InspectionStatusId)
      // carry karta hai, jo status-tracking aur card-open dono ke liye
      // UNIQUE identity ka kaam karta hai (vehicleId/tireId nahi).
      final List<VehicleItem> vehicleList = [];
      final List<TireItem> tireList = [];

      for (final p in pendingInspections) {
        final pv = p.vehicle;
        final String currentVehicleNum = pv?.vehicleNumber ?? '';
        final int? pendingId = p.status?.inspectionStatusId;

        if (pv?.vehicleId != null) {
          vehicleList.add(VehicleItem(
            vehicleId: pv!.vehicleId,
            vehicleNumber: pv.vehicleNumber,
            parentAccountId: pv.parentAccountId,
            mileageType: pv.mileageType,
            currentHours: pv.currentHours,
            currentMiles: pv.currentMiles,
            removalTread: pv.removalTread,
            severityComments: pv.severityComments,
            pendingInspectionId: pendingId ?? pv.inspectionStatusId,
            imagesLocation: pv.imagesLocation?.toString(),
          ));
        }

        // 🔧 DUPLICATE FIX: PendingInspectionEntry.fromModelJson `tire` ko
        // `tiresList.first` se set karta hai, yaani PEHLA tyre `p.tire` aur
        // `p.tiresList` DONO me hota hai. Pehle `[p.tire, ...p.tiresList]`
        // se wahi tyre 2 baar loop me aata tha aur 2 card ban jaate the.
        // Ab ek hi entry ke andar same tyre sirf ek baar liya jaata hai.
        // (Alag pendingInspectionId wale cards phir bhi alag rahenge.)
        final Set<String> seenTireKeysInEntry = {};
        final tiresForEntry = <PendingInspectionTire>[];
        for (final cand in <PendingInspectionTire>[
          if (p.tire != null) p.tire!,
          ...p.tiresList,
        ]) {
          final String dedupeKey = (cand.tireId != null && cand.tireId != 0)
              ? 'id_${cand.tireId}'
              : 'sn_${(cand.tireSerialNo ?? '').trim().toUpperCase()}_${(cand.wheelPosition ?? '').trim().toUpperCase()}';
          if (seenTireKeysInEntry.add(dedupeKey)) {
            tiresForEntry.add(cand);
          }
        }

        for (final pt in tiresForEntry) {
          if (pt.tireId == null) continue;

          final String resolvedVehicleNum = (pt.vehicleNumber != null && pt.vehicleNumber!.trim().isNotEmpty)
              ? pt.vehicleNumber!
              : currentVehicleNum;

          // 🛞 Har tyre-entry ek ALAG card — same tireId doosri pending
          // inspection mein bhi aaye to overwrite nahi, naya card add hoga.
          tireList.add(TireItem(
            tireId: pt.tireId!,
            tireSerialNo: pt.tireSerialNo ?? '',
            brandNo: pt.brandNo,
            manufacturerName: pt.manufacturerName ?? '',
            sizeName: pt.sizeName ?? '',
            typeName: pt.typeName ?? '',
            currentHours: pt.currentHours ?? 0.0,
            currentMiles: pt.currentMiles ?? 0.0,
            currentTreadDepth: pt.currentTreadDepth ?? 0.0,
            percentageWorn: pt.percentageWorn ?? 0.0,
            wheelPosition: pt.wheelPosition ?? '',
            dispositionName: (pt.isRemoved == true || pt.action?.trim().toLowerCase() == 'remove')
                ? 'Removed'
                : (pt.dispositionId == 2 ? 'Installed' : ''),
            vehicleNumber: resolvedVehicleNum,
            vehicleId: pt.vehicleId ?? pv?.vehicleId,
            inspectionDate: (pt.inspectionDate != null && pt.inspectionDate!.trim().isNotEmpty)
                ? pt.inspectionDate
                : (p.status?.createdDate ?? p.tire?.inspectionDate),
            outsideTread: pt.outsideTread,
            middleTread: pt.middleTread,
            insideTread: pt.insideTread,
            currentPressure: pt.currentPressure,
            originalTread: pt.originalTread,
            removeAt: pt.removeAt,
            wearConditionId: pt.wearConditionId,
            casingConditionId: pt.casingConditionId,
            comments: pt.comments,
            pendingInspectionId: pendingId ?? pt.inspectionStatusId,
            imagesLocation: pt.imagesLocation?.toString(),
            action: pt.action,
          ));
        }
      }

      // 🚚 Also include locally created draft vehicles waiting for approval
      try {
        final prefs = await SharedPreferences.getInstance();
        final allHiveVehicles = OfflineHiveService.getDraftVehiclesAwaitingApproval(prefs);
        for (final hv in allHiveVehicles) {
          if (hv.vehicleId < 0) {
            {
              final alreadyInList = vehicleList.any((v) => v.vehicleId == hv.vehicleId);
              if (!alreadyInList) {
                vehicleList.add(VehicleItem(
                  vehicleId: hv.vehicleId,
                  vehicleNumber: hv.vehicleNumber,
                  parentAccountId: hv.parentAccountId,
                  mileageType: hv.mileageType?.toString(),
                  currentHours: hv.currentHours,
                  currentMiles: hv.currentMiles,
                  removalTread: hv.removalTread,
                  severityComments: hv.severityComments,
                  pendingInspectionId: hv.vehicleId,
                ));
              }

              // 🛞 Retrieve any pending tyres installed on this draft vehicle
              List<PendingInspectionTire> draftTires = [];
              final tireKeys = [
                'pending_inspection_tires_${hv.vehicleId}',
                if (hv.vehicleNumber.isNotEmpty)
                  'pending_inspection_tires_${hv.vehicleNumber}',
              ];
              for (final k in tireKeys) {
                final raw = prefs.getString(k);
                if (raw != null && raw.trim().isNotEmpty) {
                  try {
                    final decoded = jsonDecode(raw);
                    if (decoded is List) {
                      draftTires = decoded
                          .whereType<Map<String, dynamic>>()
                          .map((e) => PendingInspectionTire.fromJson(
                          MeasurementHelper.localRawTireJsonToCanonical(e)))
                          .toList();
                      if (draftTires.isNotEmpty) break;
                    }
                  } catch (_) {}
                }
              }

              if (draftTires.isEmpty) {
                final cacheKeys = [
                  hv.vehicleId.toString(),
                  if (hv.vehicleNumber.isNotEmpty)
                    hv.vehicleNumber,
                ];
                for (final k in cacheKeys) {
                  final cached = OfflineHiveService.getInspectionCache(k);
                  if (cached != null && cached.trim().isNotEmpty) {
                    try {
                      final decoded = jsonDecode(cached) as Map<String, dynamic>;
                      final m = (decoded['model'] as Map<String, dynamic>?) ?? decoded;
                      final rawTires = m['installedTires'] as List?;
                      if (rawTires != null && rawTires.isNotEmpty) {
                        draftTires = rawTires
                            .whereType<Map<String, dynamic>>()
                            .map((e) => PendingInspectionTire.fromJson(
                            MeasurementHelper.localRawTireJsonToCanonical(e)))
                            .toList();
                        if (draftTires.isNotEmpty) break;
                      }
                    } catch (_) {}
                  }
                }
              }

              // Add each draft tyre to tireList so it appears on "Inspection Tires" tab
              for (final pt in draftTires) {
                final alreadyInTireList = tireList.any((t) =>
                (pt.tireId != null && pt.tireId != 0 && t.tireId == pt.tireId) ||
                    (pt.tireSerialNo != null && pt.tireSerialNo!.isNotEmpty && t.tireSerialNo == pt.tireSerialNo && t.vehicleId == hv.vehicleId));
                if (!alreadyInTireList) {
                  tireList.add(TireItem(
                    tireId: pt.tireId ?? -(1 + (DateTime.now().millisecondsSinceEpoch % 1000000)),
                    tireSerialNo: pt.tireSerialNo ?? '',
                    brandNo: pt.brandNo,
                    manufacturerName: pt.manufacturerName ?? '',
                    sizeName: pt.sizeName ?? '',
                    typeName: pt.typeName ?? '',
                    currentHours: pt.currentHours ?? hv.currentHours ?? 0.0,
                    currentMiles: pt.currentMiles ?? hv.currentMiles ?? 0.0,
                    currentTreadDepth: pt.currentTreadDepth ?? 0.0,
                    percentageWorn: pt.percentageWorn ?? 0.0,
                    wheelPosition: pt.wheelPosition ?? '',
                    dispositionName: (pt.isRemoved == true || pt.action?.trim().toLowerCase() == 'remove')
                        ? 'Removed'
                        : (pt.dispositionId == 2 ? 'Installed' : ''),
                    vehicleNumber: hv.vehicleNumber,
                    vehicleId: hv.vehicleId,
                    inspectionDate: (pt.inspectionDate != null && pt.inspectionDate!.trim().isNotEmpty)
                        ? pt.inspectionDate
                        : DateTime.now().toIso8601String(),
                    outsideTread: pt.outsideTread,
                    middleTread: pt.middleTread,
                    insideTread: pt.insideTread,
                    currentPressure: pt.currentPressure,
                    originalTread: pt.originalTread,
                    removeAt: pt.removeAt,
                    wearConditionId: pt.wearConditionId,
                    casingConditionId: pt.casingConditionId,
                    comments: pt.comments,
                    pendingInspectionId: hv.vehicleId,
                    imagesLocation: pt.imagesLocation?.toString(),
                    action: pt.action,
                  ));
                }
              }

              // Add or update pending inspection entry in pendingInspections
              int existingIdx = -1;
              for (int i = 0; i < pendingInspections.length; i++) {
                final p = pendingInspections[i];
                if (p.vehicle?.vehicleId == hv.vehicleId ||
                    (hv.vehicleNumber.isNotEmpty &&
                        p.vehicle?.vehicleNumber == hv.vehicleNumber)) {
                  existingIdx = i;
                  break;
                }
              }

              final pendingEntry = PendingInspectionEntry(
                vehicle: PendingInspectionVehicle(
                  vehicleId: hv.vehicleId,
                  vehicleNumber: hv.vehicleNumber,
                  parentAccountId: hv.parentAccountId,
                  mileageType: hv.mileageType?.toString(),
                  currentHours: hv.currentHours,
                  currentMiles: hv.currentMiles,
                  removalTread: hv.removalTread,
                  severityComments: hv.severityComments,
                  inspectionStatusId: hv.vehicleId,
                ),
                status: PendingInspectionStatus(
                  inspectionStatusId: hv.vehicleId,
                  statusId: 1, // Pending
                  comments: hv.severityComments,
                  createdDate: DateTime.now().toIso8601String(),
                ),
                tire: draftTires.isNotEmpty ? draftTires.first : null,
                tiresList: draftTires,
              );

              if (existingIdx != -1) {
                pendingInspections[existingIdx] = pendingEntry;
              } else {
                pendingInspections.add(pendingEntry);
              }
            }
          }
        }

        // 🛞 Also check if any existing pending vehicle has locally staged pending tyres
        for (int i = 0; i < pendingInspections.length; i++) {
          final p = pendingInspections[i];
          if (p.tiresList.isEmpty) {
            final vId = p.vehicle?.vehicleId;
            final vNum = p.vehicle?.vehicleNumber;
            final localTireKeys = [
              if (vId != null) 'pending_inspection_tires_$vId',
              if (vNum != null && vNum.isNotEmpty) 'pending_inspection_tires_$vNum',
            ];
            List<PendingInspectionTire> localTires = [];
            for (final k in localTireKeys) {
              final raw = prefs.getString(k);
              if (raw != null && raw.trim().isNotEmpty) {
                try {
                  final decoded = jsonDecode(raw);
                  if (decoded is List) {
                    localTires = decoded
                        .whereType<Map<String, dynamic>>()
                        .map((e) => PendingInspectionTire.fromJson(
                        MeasurementHelper.localRawTireJsonToCanonical(e)))
                        .toList();
                    if (localTires.isNotEmpty) break;
                  }
                } catch (_) {}
              }
            }
            if (localTires.isEmpty && vId != null) {
              final cached = OfflineHiveService.getInspectionCache(vId.toString());
              if (cached != null && cached.trim().isNotEmpty) {
                try {
                  final decoded = jsonDecode(cached) as Map<String, dynamic>;
                  final m = (decoded['model'] as Map<String, dynamic>?) ?? decoded;
                  final rawTires = m['installedTires'] as List?;
                  if (rawTires != null && rawTires.isNotEmpty) {
                    localTires = rawTires
                        .whereType<Map<String, dynamic>>()
                        .map((e) => PendingInspectionTire.fromJson(
                        MeasurementHelper.localRawTireJsonToCanonical(e)))
                        .toList();
                  }
                } catch (_) {}
              }
            }

            if (localTires.isNotEmpty) {
              pendingInspections[i] = PendingInspectionEntry(
                vehicle: p.vehicle,
                status: p.status,
                tire: localTires.first,
                tiresList: localTires,
                unrecognizedKeys: p.unrecognizedKeys,
              );
              for (final pt in localTires) {
                final alreadyInTireList = tireList.any((t) =>
                (pt.tireId != null && pt.tireId != 0 && t.tireId == pt.tireId) ||
                    (pt.tireSerialNo != null && pt.tireSerialNo!.isNotEmpty && t.tireSerialNo == pt.tireSerialNo));
                if (!alreadyInTireList) {
                  tireList.add(TireItem(
                    tireId: pt.tireId ?? -(1 + (DateTime.now().millisecondsSinceEpoch % 1000000)),
                    tireSerialNo: pt.tireSerialNo ?? '',
                    brandNo: pt.brandNo,
                    manufacturerName: pt.manufacturerName ?? '',
                    sizeName: pt.sizeName ?? '',
                    typeName: pt.typeName ?? '',
                    currentHours: pt.currentHours ?? p.vehicle?.currentHours ?? 0.0,
                    currentMiles: pt.currentMiles ?? p.vehicle?.currentMiles ?? 0.0,
                    currentTreadDepth: pt.currentTreadDepth ?? 0.0,
                    percentageWorn: pt.percentageWorn ?? 0.0,
                    wheelPosition: pt.wheelPosition ?? '',
                    dispositionName: (pt.isRemoved == true || pt.action?.trim().toLowerCase() == 'remove')
                        ? 'Removed'
                        : '',
                    vehicleNumber: vNum ?? '',
                    vehicleId: vId,
                    inspectionDate: pt.inspectionDate,
                    outsideTread: pt.outsideTread,
                    middleTread: pt.middleTread,
                    insideTread: pt.insideTread,
                    currentPressure: pt.currentPressure,
                    originalTread: pt.originalTread,
                    removeAt: pt.removeAt,
                    wearConditionId: pt.wearConditionId,
                    casingConditionId: pt.casingConditionId,
                    comments: pt.comments,
                    pendingInspectionId: p.status?.inspectionStatusId ?? vId,
                    imagesLocation: pt.imagesLocation?.toString(),
                  ));
                }
              }
            }
          }
        }
      } catch (e) {
        _logYellow('⚠️ Error checking local draft vehicles in _loadData: $e');
      }

      // 🚚 Also include offline pending payloads saved in SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        const payloadPrefix = 'pending_inspection_payload_';
        final Set<String> loadedPayloadVehicles = {};
        for (final k in prefs.getKeys()) {
          if (!k.startsWith(payloadPrefix)) continue;
          final vKey = k.substring(payloadPrefix.length);
          if (!loadedPayloadVehicles.add(vKey)) continue;

          final rawPayload = prefs.getString(k);
          if (rawPayload != null && rawPayload.trim().isNotEmpty) {
            try {
              final decoded = jsonDecode(rawPayload) as Map<String, dynamic>;
              final entries = PendingInspectionEntry.fromModelJson(decoded);
              for (final e in entries) {
                final vNum = e.vehicle?.vehicleNumber?.trim().toUpperCase() ?? '';
                final vId = e.vehicle?.vehicleId;
                final alreadyInPending = pendingInspections.any((p) {
                  final pNum = p.vehicle?.vehicleNumber?.trim().toUpperCase() ?? '';
                  final pId = p.vehicle?.vehicleId;
                  if (vNum.isNotEmpty && pNum.isNotEmpty && vNum == pNum) return true;
                  if (vId != null && vId != 0 && pId == vId) return true;
                  return false;
                });
                if (!alreadyInPending) {
                  pendingInspections.add(e);
                  if (e.vehicle?.vehicleId != null) {
                    vehicleList.add(VehicleItem(
                      vehicleId: e.vehicle!.vehicleId,
                      vehicleNumber: e.vehicle?.vehicleNumber,
                      parentAccountId: e.vehicle?.parentAccountId,
                      mileageType: e.vehicle?.mileageType,
                      currentHours: e.vehicle?.currentHours,
                      currentMiles: e.vehicle?.currentMiles,
                      removalTread: e.vehicle?.removalTread,
                      severityComments: e.vehicle?.severityComments,
                      pendingInspectionId: e.status?.inspectionStatusId ?? e.vehicle?.inspectionStatusId,
                      imagesLocation: e.vehicle?.imagesLocation?.toString(),
                    ));
                  }
                  for (final pt in e.tiresList) {
                    tireList.add(TireItem(
                      tireId: pt.tireId ?? -(1 + (DateTime.now().millisecondsSinceEpoch % 1000000)),
                      tireSerialNo: pt.tireSerialNo ?? '',
                      brandNo: pt.brandNo,
                      manufacturerName: pt.manufacturerName ?? '',
                      sizeName: pt.sizeName ?? '',
                      typeName: pt.typeName ?? '',
                      currentHours: pt.currentHours ?? e.vehicle?.currentHours ?? 0.0,
                      currentMiles: pt.currentMiles ?? e.vehicle?.currentMiles ?? 0.0,
                      currentTreadDepth: pt.currentTreadDepth ?? 0.0,
                      percentageWorn: pt.percentageWorn ?? 0.0,
                      wheelPosition: pt.wheelPosition ?? '',
                      dispositionName: (pt.isRemoved == true || pt.action?.trim().toLowerCase() == 'remove') ? 'Removed' : '',
                      vehicleNumber: e.vehicle?.vehicleNumber ?? '',
                      vehicleId: e.vehicle?.vehicleId,
                      inspectionDate: pt.inspectionDate ?? e.status?.createdDate,
                      outsideTread: pt.outsideTread,
                      middleTread: pt.middleTread,
                      insideTread: pt.insideTread,
                      currentPressure: pt.currentPressure,
                      originalTread: pt.originalTread,
                      removeAt: pt.removeAt,
                      wearConditionId: pt.wearConditionId,
                      casingConditionId: pt.casingConditionId,
                      comments: pt.comments,
                      pendingInspectionId: e.status?.inspectionStatusId ?? pt.inspectionStatusId,
                      imagesLocation: pt.imagesLocation?.toString(),
                      action: pt.action,
                    ));
                  }
                }
              }
            } catch (e) {
              _logYellow('⚠️ Error parsing offline pending payload for $vKey: $e');
            }
          }
        }
      } catch (e) {
        _logYellow('⚠️ Error scanning pending_inspection_payload_ keys: $e');
      }

      // ═══════════════════════════════════════════════════════════
      // 🛡️ STRICT DEDUPLICATION: VEHICLES (Exactly 1 card per vehicle)
      // ═══════════════════════════════════════════════════════════
      final Map<String, VehicleItem> uniqueVehicles = {};
      for (final v in vehicleList) {
        final vNum = (v.vehicleNumber ?? '').trim().toUpperCase();
        final vId = v.vehicleId;
        final String key = vNum.isNotEmpty
            ? 'num_$vNum'
            : ((vId != null && vId != 0) ? 'id_$vId' : '');
        if (key.isEmpty) continue;

        if (!uniqueVehicles.containsKey(key)) {
          uniqueVehicles[key] = v;
        } else {
          final existing = uniqueVehicles[key]!;
          if ((existing.pendingInspectionId == null || existing.pendingInspectionId == 0) &&
              (v.pendingInspectionId != null && v.pendingInspectionId != 0)) {
            uniqueVehicles[key] = v;
          }
        }
      }

      // ═══════════════════════════════════════════════════════════
      // 🛡️ STRICT DEDUPLICATION: TYRES (Exactly 1 card per physical tyre)
      // ═══════════════════════════════════════════════════════════
      final Map<String, TireItem> uniqueTyres = {};
      for (final t in tireList) {
        final tId = t.tireId;
        final tSerial = t.tireSerialNo.trim().toUpperCase();
        final vNum = t.vehicleNumber.trim().toUpperCase();
        final pos = t.wheelPosition.trim().toUpperCase();

        final String key = (tSerial.isNotEmpty)
            ? 'sn_${tSerial}_$vNum'
            : ((tId > 0)
                ? 'id_$tId'
                : (pos.isNotEmpty ? 'pos_${pos}_$vNum' : 'temp_${t.hashCode}'));

        if (!uniqueTyres.containsKey(key)) {
          uniqueTyres[key] = t;
        } else {
          final existing = uniqueTyres[key]!;
          if ((existing.pendingInspectionId == null || existing.pendingInspectionId == 0) &&
              (t.pendingInspectionId != null && t.pendingInspectionId != 0)) {
            uniqueTyres[key] = t;
          }
        }
      }

      vehicles.value = uniqueVehicles.values.toList();
      tyres.value = uniqueTyres.values.toList();

      _logYellow('✅ Loaded Vehicles: ${vehicles.length}, Tyres: ${tyres.length}');

      for (final v in vehicles) {
        statusMap.putIfAbsent(_vehicleKey(v), () => IWInspectionStatus.pending);
      }
      for (final t in tyres) {
        statusMap.putIfAbsent(_tireKey(t), () => IWInspectionStatus.pending);
      }

      _updateVisibleList();
      await pruneRecentSearches();
    } catch (e) {
      _logYellow('❌ Error in _loadData: $e');
      if (accountId != null) {
        _loadFromHive(accountId);
        _filterToPendingOnly();
      } else {
        vehicles.value = [];
        tyres.value = [];
      }
      await pruneRecentSearches();
    } finally {
      isLoading.value = false;
      _logYellow('🏁 _loadData COMPLETED');
    }
  }

  void _filterToPendingOnly() {
    if (pendingInspections.isEmpty) {
      _logYellow('⚠️ pendingInspections is EMPTY -> Hive tabs are unfiltered.');
      return;
    }

    final pendingTireIds = <int>{};
    for (final p in pendingInspections) {
      if (p.tire?.tireId != null) {
        pendingTireIds.add(p.tire!.tireId!);
      }
      for (final t in p.tiresList) {
        if (t.tireId != null) {
          pendingTireIds.add(t.tireId!);
        }
      }
    }

    final pendingVehicleIds = pendingInspections
        .map((p) => p.vehicle?.vehicleId)
        .whereType<int>()
        .toSet();

    final filteredTyres = pendingTireIds.isNotEmpty
        ? tyres.where((t) => pendingTireIds.contains(t.tireId)).toList()
        : <TireItem>[];

    final filteredVehicles = vehicles
        .where((v) => v.vehicleId != null && pendingVehicleIds.contains(v.vehicleId))
        .toList();

    // Deduplicate vehicles
    final Map<String, VehicleItem> uVehicles = {};
    for (final v in filteredVehicles) {
      final vNum = (v.vehicleNumber ?? '').trim().toUpperCase();
      final vId = v.vehicleId;
      final key = vNum.isNotEmpty ? 'num_$vNum' : ((vId != null && vId != 0) ? 'id_$vId' : '');
      if (key.isNotEmpty) uVehicles.putIfAbsent(key, () => v);
    }
    vehicles.value = uVehicles.values.toList();

    // Deduplicate tyres
    final Map<String, TireItem> uTyres = {};
    for (final t in filteredTyres) {
      final tId = t.tireId;
      final tSerial = t.tireSerialNo.trim().toUpperCase();
      final vNum = t.vehicleNumber.trim().toUpperCase();
      final pos = t.wheelPosition.trim().toUpperCase();
      final key = tSerial.isNotEmpty
          ? 'sn_${tSerial}_$vNum'
          : ((tId > 0) ? 'id_$tId' : (pos.isNotEmpty ? 'pos_${pos}_$vNum' : 'temp_${t.hashCode}'));
      uTyres.putIfAbsent(key, () => t);
    }
    tyres.value = uTyres.values.toList();

    _logYellow(
      '✨ Hive fallback filtered to pending -> Vehicles: ${vehicles.length}, Tyres: ${tyres.length}',
    );
  }

  void _loadFromHive(int accountId) {
    _logYellow('📦 Loading data from Hive for accountId=$accountId');
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
    _logYellow('📦 Hive Vehicles Loaded: ${vehicles.length}');

    final hiveTyres = OfflineHiveService.getAllTyres(
      parentAccountId: accountId,
    );
    tyres.value = hiveTyres
        .where((h) => h.vehicleId != null && h.vehicleId != 0)
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
    _logYellow('📦 Hive Tyres Loaded: ${tyres.length}');
  }

  Future<void> _loadRecentFromStorage() async {
    try {
      final savedVehiclesStr = await SecureStorage.getVehicle();
      if (savedVehiclesStr != null && savedVehiclesStr.isNotEmpty) {
        final List decoded = jsonDecode(savedVehiclesStr);
        recentVehicles.value =
            decoded.map((e) => VehicleItem.fromJson(e)).toList();
      }

      final savedTyresStr = await SecureStorage.getTyre();
      if (savedTyresStr != null && savedTyresStr.isNotEmpty) {
        final List decoded = jsonDecode(savedTyresStr);
        final List<TireItem> total =
        decoded.map((e) => TireItem.fromJson(e)).toList();

        recentTyres.value = total.where((t) {
          if (t.vehicleId == null || t.vehicleId == 0) return false;
          if (t.tireId != 0) {
            final hive = OfflineHiveService.getTyreById(t.tireId);
            if (hive != null) {
              final hiveVehicleId = hive.vehicleId;
              final hiveDispId = hive.dispositionId ?? 0;
              if ((hiveVehicleId == null || hiveVehicleId == 0) &&
                  hiveDispId != 7) {
                return false;
              }
            }
          }
          return true;
        }).toList();

        if (recentTyres.length != total.length) {
          await _saveRecentTyres();
        }
      }

      // If pending data is already loaded, auto-prune immediately
      if (!isLoading.value) {
        await pruneRecentSearches();
      }
    } catch (_) {}
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
    _logYellow('🔄 Switching Tab to: $index');
    selectedTab.value = index;
    searchText.value = '';
    _updateVisibleList();
  }

  void onSearch(String value) {
    searchText.value = value;
    _updateVisibleList();
  }


  void _updateVisibleList() {
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

  void clearSearch() {
    searchText.value = '';
    _updateVisibleList();
  }

  void selectItem(dynamic item) {
    if (selectedTab.value == 0) {
      final vehicle = item as VehicleItem;
      recentVehicles.removeWhere((e) =>
          (vehicle.vehicleId != null && vehicle.vehicleId != 0 && e.vehicleId == vehicle.vehicleId) ||
          ((e.vehicleNumber ?? '').trim().isNotEmpty &&
              (vehicle.vehicleNumber ?? '').trim().isNotEmpty &&
              (e.vehicleNumber ?? '').trim().toUpperCase() ==
                  (vehicle.vehicleNumber ?? '').trim().toUpperCase()));
      recentVehicles.insert(0, vehicle);
      if (recentVehicles.length > 5) recentVehicles.removeLast();
      _saveRecentVehicles();
    } else {
      final tyre = item as TireItem;
      recentTyres.removeWhere((e) =>
          (tyre.tireId != 0 && e.tireId == tyre.tireId) ||
          (e.tireSerialNo.trim().isNotEmpty &&
              tyre.tireSerialNo.trim().isNotEmpty &&
              e.tireSerialNo.trim().toUpperCase() ==
                  tyre.tireSerialNo.trim().toUpperCase()));
      recentTyres.insert(0, tyre);
      if (recentTyres.length > 5) recentTyres.removeLast();
      _saveRecentTyres();
    }
  }

  void updateStatus(String itemId, IWInspectionStatus status) {
    statusMap[itemId] = status;
    visibleList.refresh();
  }

  /// Removes ONLY the specific pending-inspection card for this vehicle.
  /// Pass [pendingInspectionId] whenever it's known (it always is, from
  /// the tapped card) so that OTHER pending cards for the SAME vehicleId
  /// stay untouched. Falls back to removing every card for that vehicle
  /// only when no pendingInspectionId is available (legacy callers).
  void removePendingItem(int? vehicleId, {int? pendingInspectionId}) {
    if (vehicleId == null) return;

    final beforeVehicles = vehicles.length;
    final beforeTyres = tyres.length;
    final beforePending = pendingInspections.length;

    bool matchesVehicle(int? vId, int? pId) {
      if (vId != vehicleId) return false;
      if (pendingInspectionId == null) return true; // legacy: nuke all for vehicle
      return pId == pendingInspectionId;
    }

    final removedVehicles = vehicles
        .where((v) => matchesVehicle(v.vehicleId, v.pendingInspectionId))
        .toList();
    vehicles.removeWhere((v) => matchesVehicle(v.vehicleId, v.pendingInspectionId));
    tyres.removeWhere((t) => matchesVehicle(t.vehicleId, t.pendingInspectionId));
    pendingInspections.removeWhere((p) => matchesVehicle(
        p.vehicle?.vehicleId, p.status?.inspectionStatusId));

    for (final v in removedVehicles) {
      statusMap.remove(_vehicleKey(v));
    }

    // ✅ Remove resolved vehicle from recentVehicles and persist
    final beforeRecent = recentVehicles.length;
    recentVehicles.removeWhere((rv) {
      final idMatch = vehicleId > 0 && rv.vehicleId == vehicleId;
      final numMatch = rv.vehicleNumber != null &&
          rv.vehicleNumber!.trim().isNotEmpty &&
          removedVehicles.any((rm) =>
              (rm.vehicleNumber ?? '').trim().toUpperCase() ==
              rv.vehicleNumber!.trim().toUpperCase());
      return idMatch || numMatch;
    });
    if (recentVehicles.length != beforeRecent) {
      _saveRecentVehicles();
    }

    _logYellow(
      '🗑️ removePendingItem(vehicleId=$vehicleId, pendingInspectionId=$pendingInspectionId) -> '
          'vehicles: $beforeVehicles→${vehicles.length}, '
          'tyres: $beforeTyres→${tyres.length}, '
          'pendingInspections: $beforePending→${pendingInspections.length}',
    );

    _updateVisibleList();
    // Only mark fully resolved (hidden) if no other pending cards remain
    // for this vehicleId.
    if (!vehicles.any((v) => v.vehicleId == vehicleId)) {
      _markVehicleResolvedLocally(vehicleId);
    }
  }

  /// Removes ONLY the specific pending-inspection card for this tyre.
  /// Pass [pendingInspectionId] whenever known so other pending cards for
  /// the SAME tireId stay untouched.
  void removePendingTire(int? tireId, {int? pendingInspectionId}) {
    if (tireId == null) return;

    final beforeTyres = tyres.length;
    final beforePending = pendingInspections.length;

    bool matchesTire(int? tId, int? pId) {
      if (tId != tireId) return false;
      if (pendingInspectionId == null) return true; // legacy: nuke all for tyre
      return pId == pendingInspectionId;
    }

    final removedTyres = tyres
        .where((t) => matchesTire(t.tireId, t.pendingInspectionId))
        .toList();
    tyres.removeWhere((t) => matchesTire(t.tireId, t.pendingInspectionId));
    pendingInspections.removeWhere((p) {
      final matchTireEntry = p.tire?.tireId == tireId ||
          p.tiresList.any((pt) => pt.tireId == tireId);
      if (!matchTireEntry) return false;
      if (pendingInspectionId == null) return true;
      return p.status?.inspectionStatusId == pendingInspectionId;
    });

    for (final t in removedTyres) {
      statusMap.remove(_tireKey(t));
    }

    // ✅ Remove resolved tyre from recentTyres and persist
    final beforeRecent = recentTyres.length;
    recentTyres.removeWhere((rt) {
      final idMatch = tireId > 0 && rt.tireId == tireId;
      final serialMatch = rt.tireSerialNo.trim().isNotEmpty &&
          removedTyres.any((rm) =>
              rm.tireSerialNo.trim().toUpperCase() ==
              rt.tireSerialNo.trim().toUpperCase());
      return idMatch || serialMatch;
    });
    if (recentTyres.length != beforeRecent) {
      _saveRecentTyres();
    }

    _logYellow(
      '🗑️ removePendingTire(tireId=$tireId, pendingInspectionId=$pendingInspectionId) -> '
          'tyres: $beforeTyres→${tyres.length}, '
          'pendingInspections: $beforePending→${pendingInspections.length}',
    );

    _updateVisibleList();
  }

  /// ✅ Auto-prunes items from recent searches if they are no longer in pending inspections.
  Future<void> pruneRecentSearches() async {
    try {
      final beforeVehicles = recentVehicles.length;
      final beforeTyres = recentTyres.length;

      // 1. Prune recentVehicles: Remove any vehicle not present in pending vehicles
      recentVehicles.removeWhere((rv) {
        final rvNum = (rv.vehicleNumber ?? '').trim().toUpperCase();
        final rvId = rv.vehicleId;
        final isStillPending = vehicles.any((v) {
          final vNum = (v.vehicleNumber ?? '').trim().toUpperCase();
          final vId = v.vehicleId;
          if (rvNum.isNotEmpty && vNum.isNotEmpty && rvNum == vNum) return true;
          if (rvId != null && rvId > 0 && vId != null && vId == rvId) return true;
          return false;
        });
        return !isStillPending;
      });

      // 2. Prune recentTyres: Remove any tyre not present in pending tyres
      recentTyres.removeWhere((rt) {
        final rtSerial = rt.tireSerialNo.trim().toUpperCase();
        final rtId = rt.tireId;
        final isStillPending = tyres.any((t) {
          final tSerial = t.tireSerialNo.trim().toUpperCase();
          final tId = t.tireId;
          if (rtSerial.isNotEmpty && tSerial.isNotEmpty && rtSerial == tSerial) return true;
          if (rtId > 0 && tId > 0 && rtId == tId) return true;
          return false;
        });
        return !isStillPending;
      });

      if (recentVehicles.length != beforeVehicles) {
        _logYellow('🧹 Pruned recentVehicles: $beforeVehicles -> ${recentVehicles.length}');
        await _saveRecentVehicles();
      }
      if (recentTyres.length != beforeTyres) {
        _logYellow('🧹 Pruned recentTyres: $beforeTyres -> ${recentTyres.length}');
        await _saveRecentTyres();
      }
    } catch (e) {
      _logYellow('⚠️ Error in pruneRecentSearches: $e');
    }
  }

  IWInspectionStatus getStatus(dynamic item) {
    if (item is VehicleItem) {
      return statusMap[_vehicleKey(item)] ?? IWInspectionStatus.pending;
    } else if (item is TireItem) {
      return statusMap[_tireKey(item)] ?? IWInspectionStatus.pending;
    }
    return IWInspectionStatus.pending;
  }

  int? getPendingInspectionIdForVehicle(int? vehicleId) {
    if (vehicleId == null) return null;
    for (final p in pendingInspections) {
      if (p.vehicle?.vehicleId == vehicleId) {
        return p.status?.inspectionStatusId;
      }
    }
    return null;
  }

  static const String _resolvedPendingPrefsKey = 'iw_locally_resolved_pending_vehicles';
  static const Duration _resolvedTtl = Duration(hours: 48);

  Future<void> _markVehicleResolvedLocally(int vehicleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_resolvedPendingPrefsKey);
      final Map<String, dynamic> map =
      raw != null ? (jsonDecode(raw) as Map<String, dynamic>) : {};
      map[vehicleId.toString()] = DateTime.now().toIso8601String();
      await prefs.setString(_resolvedPendingPrefsKey, jsonEncode(map));
      _logYellow('💾 Locally marked vehicleId=$vehicleId as resolved (hidden from pending for ${_resolvedTtl.inHours}h)');
    } catch (e) {
      _logYellow('⚠️ _markVehicleResolvedLocally failed for vehicleId=$vehicleId -> $e');
    }
  }

  void removeRecentVehicle(VehicleItem item) {
    recentVehicles.removeWhere((e) =>
        (item.vehicleId != null && item.vehicleId != 0 && e.vehicleId == item.vehicleId) ||
        (item.vehicleNumber != null && item.vehicleNumber!.trim().isNotEmpty &&
            (e.vehicleNumber ?? '').trim().toUpperCase() == item.vehicleNumber!.trim().toUpperCase()));
    _saveRecentVehicles();
  }

  void removeRecentTyre(TireItem item) {
    recentTyres.removeWhere((e) =>
        (item.tireId != 0 && e.tireId == item.tireId) ||
        (item.tireSerialNo.trim().isNotEmpty &&
            e.tireSerialNo.trim().toUpperCase() == item.tireSerialNo.trim().toUpperCase()));
    _saveRecentTyres();
  }
}

class SearchApi {
  final String baseUrl = ApiConstants.baseUrl;

  Future<List<VehicleItem>> fetchVehicles(int accountId) async {
    try {
      final cookie = await SecureStorage.getCookie();
      if (cookie == null || cookie.isEmpty) {
        throw Exception("Auth cookie missing");
      }

      final timeStamp = 0;
      final url = Uri.parse(
        "$baseUrl/api/Vehicle/GetVehicleByUser/$accountId/$timeStamp?timeStamp=$timeStamp",
      );

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Cookie": cookie,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['model'] == null) return [];

        final List list = data['model'] as List;

        return list.map<VehicleItem>((e) => VehicleItem.fromJson(e)).toList();
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception("Session expired");
      }

      throw Exception("Vehicle API failed");
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TireItem>> fetchTyres(int accountId) async {
    try {
      final cookie = await SecureStorage.getCookie();
      if (cookie == null || cookie.isEmpty) {
        throw Exception("Auth cookie missing");
      }

      final url = Uri.parse("$baseUrl/api/Tire/GetTiresByAccount/$accountId");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Cookie": cookie,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['model'] == null) return [];

        final List list = data['model'] as List;

        return list.map<TireItem>((e) => TireItem.fromJson(e)).toList();
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception("Session expired");
      }

      throw Exception("Tyre API failed");
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PendingInspectionEntry>> fetchPendingInspections(
      int accountId,
      ) async {
    final url = Uri.parse(
      "$baseUrl${ApiConstants.getAllPendingInspections(accountId)}",
    );

    _logYellow('===== [GetAllPendingInspections] CALLED =====');
    _logYellow('URL -> GET $url');

    try {
      final cookie = await SecureStorage.getCookie();
      if (cookie == null || cookie.isEmpty) {
        _logYellow('❌ Auth cookie missing — request nahi bheja gaya');
        throw Exception("Auth cookie missing");
      }

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Cookie": cookie,
        },
      );

      _logYellow('⬅️ STATUS CODE -> ${response.statusCode}');
      // Android logcat truncates a single long debugPrint line (~1000
      // chars) — with 13+ pending tyres in one response this JSON is
      // easily 5-10x that, so printing it in one line hides most of it.
      // Print length + chunks so the FULL body is actually visible.
      final rawBody = response.body.isEmpty ? "(empty body)" : response.body;
      _logYellow('⬅️ RAW BODY (length=${rawBody.length} chars):');
      const chunkSize = 800;
      for (var i = 0; i < rawBody.length; i += chunkSize) {
        final end = (i + chunkSize < rawBody.length) ? i + chunkSize : rawBody.length;
        _logYellow('  [chunk ${(i / chunkSize).floor() + 1}] ${rawBody.substring(i, end)}');
      }

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          _logYellow('⚠️ 200 OK but body khaali hai -> returning empty list');
          return [];
        }

        final dynamic decoded = jsonDecode(response.body);

        List rawList;
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          final dynamic candidate = decoded['model'] ??
              decoded['Model'] ??
              decoded['inspectionList'] ??
              decoded['data'];
          if (candidate is! List) {
            _logYellow(
              '⚠️ Response me koi list nahi mili -> returning empty list',
            );
            return [];
          }
          rawList = candidate;
        } else {
          return [];
        }

        // 🔧 Backend har "model" object me EK Vehicle + poori Tires list +
        // status LOG (Pendinginspections) bhejta hai. FIX: is log me se sirf
        // wahi ek status row lo jiska InspectionStatusId Vehicle/Tire ke
        // InspectionStatusId se match karta hai — baaki sab rows kisi aur
        // account/vehicle ke purane history entries hain (dekho:
        // GrandParentAccountId aur CreatedBy alag-alag hain un rows me),
        // isliye unhe entries me expand nahi karna. Pehle wala code har
        // status row ke liye ek naya PendingInspectionEntry bana raha tha
        // (same Vehicle/Tire ke saath), jisse 700+ duplicate entries ban
        // rahe the ek hi pending vehicle ke liye.
        final List<PendingInspectionEntry> parsed = [];
        for (final rawModel in rawList.whereType<Map<String, dynamic>>()) {
          parsed.addAll(PendingInspectionEntry.fromModelJson(rawModel));
        }

        return parsed;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception("Session expired");
      }

      throw Exception("Pending Inspections API failed");
    } catch (e) {
      _logYellow('❌ EXCEPTION in fetchPendingInspections -> $e');
      rethrow;
    }
  }
}

// ── SAFE JSON PARSING HELPERS ──
// Backend kabhi kabhi whole-number fields ko double bhejta hai (e.g. 6.0
// instead of 6), aur kabhi PascalCase kabhi camelCase keys use karta hai.
// Direct `json['x'] as int?` isi wajah se crash karta tha:
// "type 'double' is not a subtype of type 'int?'". Yeh helpers har
// numeric/bool/string field ko safely convert karte hain aur dono
// case-variants ke keys check karte hain, chahe backend kuch bhi bheje.

dynamic _pick(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    if (json.containsKey(k) && json[k] != null) return json[k];
  }
  return null;
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt();
  return null;
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

String? _asString(dynamic v) {
  if (v == null) return null;
  return v.toString();
}

bool? _asBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v.toLowerCase() == 'true' || v == '1';
  return null;
}

class PendingInspectionStatus {
  final int? inspectionStatusId;
  final int? inspectionTypeId;
  final int? inspectionId;
  final int? grandParentAccountId;
  final int? statusId;
  final String? statusUpdatedBy;
  final String? statusUpdatedDate;
  final String? comments;
  final String? createdBy;
  final String? createdDate;
  final String? modifiedBy;
  final String? modifiedDate;

  PendingInspectionStatus({
    this.inspectionStatusId,
    this.inspectionTypeId,
    this.inspectionId,
    this.grandParentAccountId,
    this.statusId,
    this.statusUpdatedBy,
    this.statusUpdatedDate,
    this.comments,
    this.createdBy,
    this.createdDate,
    this.modifiedBy,
    this.modifiedDate,
  });

  factory PendingInspectionStatus.fromJson(Map<String, dynamic> json) {
    return PendingInspectionStatus(
      inspectionStatusId: _asInt(_pick(json, ['InspectionStatusId', 'inspectionStatusId'])),
      inspectionTypeId: _asInt(_pick(json, ['InspectionTypeId', 'inspectionTypeId'])),
      inspectionId: _asInt(_pick(json, ['InspectionId', 'inspectionId'])),
      grandParentAccountId: _asInt(_pick(json, ['GrandParentAccountId', 'grandParentAccountId'])),
      statusId: _asInt(_pick(json, ['StatusId', 'statusId'])),
      statusUpdatedBy: _asString(_pick(json, ['StatusUpdatedBy', 'statusUpdatedBy'])),
      statusUpdatedDate: _asString(_pick(json, ['StatusUpdatedDate', 'statusUpdatedDate'])),
      comments: _asString(_pick(json, ['Comments', 'comments'])),
      createdBy: _asString(_pick(json, ['CreatedBy', 'createdBy'])),
      createdDate: _asString(_pick(json, ['CreatedDate', 'createdDate'])),
      modifiedBy: _asString(_pick(json, ['ModifiedBy', 'modifiedBy'])),
      modifiedDate: _asString(_pick(json, ['ModifiedDate', 'modifiedDate'])),
    );
  }
}

class PendingInspectionVehicle {
  final int? vehicleId;
  final String? vehicleNumber;
  final int? locationId;
  final int? parentAccountId;
  final String? mileageType;
  final double? currentMiles;
  final double? currentHours;
  final int? manufacturerId;
  final int? typeId;
  final int? modelId;
  final int? tireSizeId;
  final double? removalTread;
  final String? severityComments;
  final int? axleConfigId;
  final String? axleConfig;
  final String? tireSize;
  final String? vehicleManufacturer;
  final String? vehicleType;
  final String? vehicleModel;
  final bool? isActive;
  final int? inspectionStatusId; // 🔧 NEW — correlation key to pick the right status row
  final dynamic imagesLocation;

  PendingInspectionVehicle({
    this.vehicleId,
    this.vehicleNumber,
    this.locationId,
    this.parentAccountId,
    this.mileageType,
    this.currentMiles,
    this.currentHours,
    this.manufacturerId,
    this.typeId,
    this.modelId,
    this.tireSizeId,
    this.removalTread,
    this.severityComments,
    this.axleConfigId,
    this.axleConfig,
    this.tireSize,
    this.vehicleManufacturer,
    this.vehicleType,
    this.vehicleModel,
    this.isActive,
    this.inspectionStatusId,
    this.imagesLocation,
  });

  factory PendingInspectionVehicle.fromJson(Map<String, dynamic> json) {
    return PendingInspectionVehicle(
      vehicleId: _asInt(_pick(json, ['VehicleId', 'vehicleId'])),
      vehicleNumber: _asString(_pick(json, ['VehicleNumber', 'vehicleNumber'])),
      locationId: _asInt(_pick(json, ['LocationId', 'locationId'])),
      parentAccountId: _asInt(_pick(json, ['ParentAccountId', 'parentAccountId'])),
      mileageType: _asString(_pick(json, ['MileageType', 'mileageType'])),
      currentMiles: _asDouble(_pick(json, ['CurrentMiles', 'currentMiles'])),
      currentHours: _asDouble(_pick(json, ['CurrentHours', 'currentHours'])),
      manufacturerId: _asInt(_pick(json, ['ManufacturerId', 'manufacturerId'])),
      typeId: _asInt(_pick(json, ['TypeId', 'typeId'])),
      modelId: _asInt(_pick(json, ['ModelId', 'modelId'])),
      tireSizeId: _asInt(_pick(json, ['TireSizeId', 'tireSizeId'])),
      removalTread: _asDouble(_pick(json, ['RemovalTread', 'removalTread'])),
      severityComments: _asString(_pick(json, ['SeverityComments', 'severityComments'])),
      axleConfigId: _asInt(_pick(json, ['AxleConfigId', 'axleConfigId'])),
      axleConfig: _asString(_pick(json, ['AxleConfig', 'axleConfig'])),
      tireSize: _asString(_pick(json, ['TireSize', 'tireSize'])),
      vehicleManufacturer: _asString(_pick(json, ['VehicleManufacturer', 'vehicleManufacturer'])),
      vehicleType: _asString(_pick(json, ['VehicleType', 'vehicleType'])),
      vehicleModel: _asString(_pick(json, ['VehicleModel', 'vehicleModel'])),
      isActive: _asBool(_pick(json, ['IsActive', 'isActive'])),
      inspectionStatusId: _asInt(_pick(json, ['InspectionStatusId', 'inspectionStatusId'])),
      imagesLocation: _pick(json, ['ImagesLocation', 'imagesLocation']),
    );
  }
}

class PendingInspectionTire {
  final int? tireId;
  final String? tireSerialNo;
  final String? wheelPosition;
  final String? manufacturerName;
  final String? sizeName;
  final String? typeName;
  final double? currentTreadDepth;
  final double? percentageWorn;
  final double? currentPressure;
  final int? locationId;
  final int? parentAccountId;
  final int? manufacturerId;
  final int? typeId;
  final int? sizeId;
  final double? currentHours;
  final double? currentMiles;
  final String? registeredDate;
  final double? originalTread;
  final double? removeAt;
  final double? outsideTread;
  final double? middleTread;
  final double? insideTread;
  final String? comments;
  final String? inspectionDate;
  final String? mileageType;
  final String? brandNo;
  final int? dispositionId;
  final String? dispositionName;
  final String? createdBy;
  final int? vehicleId;
  final String? vehicleNumber;
  final dynamic wearConditionId;
  final dynamic casingConditionId;
  final dynamic mountedRimId;
  final dynamic removalReasonId;
  final dynamic imagesLocation;
  final String? action;
  final int? inspectionStatusId; // 🔧 NEW — correlation key (fallback if vehicle's is null)
  final bool? isRemoved;

  PendingInspectionTire({
    this.tireId,
    this.tireSerialNo,
    this.wheelPosition,
    this.manufacturerName,
    this.sizeName,
    this.typeName,
    this.currentTreadDepth,
    this.percentageWorn,
    this.currentPressure,
    this.locationId,
    this.parentAccountId,
    this.manufacturerId,
    this.typeId,
    this.sizeId,
    this.currentHours,
    this.currentMiles,
    this.registeredDate,
    this.originalTread,
    this.removeAt,
    this.outsideTread,
    this.middleTread,
    this.insideTread,
    this.comments,
    this.inspectionDate,
    this.mileageType,
    this.brandNo,
    this.dispositionId,
    this.dispositionName,
    this.createdBy,
    this.vehicleId,
    this.vehicleNumber,
    this.wearConditionId,
    this.casingConditionId,
    this.mountedRimId,
    this.removalReasonId,
    this.imagesLocation,
    this.action,
    this.inspectionStatusId,
    this.isRemoved,
  });

  factory PendingInspectionTire.fromJson(Map<String, dynamic> json) {
    final rawAction = _asString(_pick(json, ['Action', 'action', 'actionName', 'ActionName']));
    final rawRemovalReason = _pick(json, ['RemovalReasonId', 'removalReasonId', 'RemovalReason', 'removalReason', 'ReasonId', 'reasonId']);
    final removalReasonInt = rawRemovalReason is int
        ? rawRemovalReason
        : int.tryParse(rawRemovalReason?.toString() ?? '');
    final rawDispObj = _pick(json, ['Disposition', 'disposition']);
    int? dispId = _asInt(_pick(json, [
      'DispositionId', 'dispositionId',
      'rimDispositionId', 'RimDispositionId',
      'TireDispositionId', 'tireDispositionId',
    ]));
    String? rawDispName = _asString(_pick(json, [
      'DispositionName', 'dispositionName',
      'rimDispositionName', 'RimDispositionName',
    ]));

    if (dispId == null && rawDispObj is int) {
      dispId = rawDispObj;
    }
    if ((rawDispName == null || rawDispName.isEmpty) && rawDispObj is String) {
      final lower = rawDispObj.trim().toLowerCase();
      if (lower != 'remove' && lower != 'install' && lower != 'inspect' && lower != 'mounted') {
        rawDispName = rawDispObj.trim();
      }
    }

    int? finalDispId = dispId;
    String? finalDispName = rawDispName;

    if (rawDispName != null && rawDispName.isNotEmpty) {
      final norm = rawDispName.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');
      if (norm.contains('scrap')) {
        finalDispId = 1;
        finalDispName = 'Scrap';
      } else if (norm.contains('repair')) {
        finalDispId = 2;
        finalDispName = 'Repair';
      } else if (norm.contains('retread')) {
        finalDispId = 3;
        finalDispName = 'Retread';
      } else if (norm.contains('hold')) {
        finalDispId = 4;
        finalDispName = 'On Hold';
      } else if (norm.contains('inventory')) {
        finalDispId = 8;
        finalDispName = 'Inventory';
      }
    }

    if (finalDispId == 1) {
      finalDispName = 'Scrap';
    } else if (finalDispId == 2) {
      finalDispName = 'Repair';
    } else if (finalDispId == 3) {
      finalDispName = 'Retread';
    } else if (finalDispId == 4) {
      finalDispName = 'On Hold';
    } else if (finalDispId == 7) {
      finalDispName = 'Installed';
    } else if (finalDispId == 8) {
      finalDispName = 'Inventory';
    }

    final rawWheelPos = _asString(_pick(json, ['WheelPosition', 'wheelPosition']));
    final posTrim = (rawWheelPos ?? '').trim();
    final bool hasWheelPos = posTrim.isNotEmpty && posTrim != '0' && posTrim != '-';

    final isExplicitRemoved = _pick(json, ['IsRemoved', 'isRemoved']) == true ||
        _pick(json, ['IsRemoved', 'isRemoved']) == 1 ||
        _pick(json, ['IsRemoved', 'isRemoved']) == '1' ||
        _pick(json, ['IsRemoved', 'isRemoved']) == 'true';

    final bool isExplicitInstall = (rawAction != null && rawAction.toLowerCase().contains('install'));
    final bool isExplicitRemove = (rawAction != null && rawAction.toLowerCase().contains('remove'));

    final bool isMountedDisp = (dispId == 7) ||
        (rawDispName != null && rawDispName.toLowerCase().contains('mount'));

    final bool isUnmountedDisp = (dispId != null && (dispId == 8 || dispId == 1 || dispId == 2 || dispId == 3 || dispId == 4 || dispId == 6)) ||
        (rawDispName != null && (
            rawDispName.toLowerCase().contains('remove') ||
                rawDispName.toLowerCase().contains('inventory') ||
                rawDispName.toLowerCase().contains('scrap') ||
                rawDispName.toLowerCase().contains('repair') ||
                rawDispName.toLowerCase().contains('retread') ||
                rawDispName.toLowerCase().contains('hold')
        ));

    final bool isRemoval = !isExplicitInstall && (
        isExplicitRemove ||
            isExplicitRemoved ||
            (removalReasonInt != null && removalReasonInt > 0) ||
            (!hasWheelPos && isUnmountedDisp) ||
            (!hasWheelPos && !isMountedDisp)
    );

    String? resolvedAction = rawAction;
    if (isRemoval || isExplicitRemove || isExplicitRemoved) {
      resolvedAction = 'Remove';
    } else if (isExplicitInstall) {
      resolvedAction = 'Install';
    } else if (rawAction?.isNotEmpty == true) {
      resolvedAction = rawAction;
    }

    return PendingInspectionTire(
      tireId: _asInt(_pick(json, ['TireId', 'tireId'])),
      tireSerialNo: _asString(_pick(json, ['TireSerialNo', 'tireSerialNo'])),
      wheelPosition: _asString(_pick(json, ['WheelPosition', 'wheelPosition'])),
      manufacturerName: _asString(_pick(json, ['ManufacturerName', 'manufacturerName'])),
      sizeName: _asString(_pick(json, ['SizeName', 'sizeName'])),
      typeName: _asString(_pick(json, ['TypeName', 'typeName'])),
      currentTreadDepth: _asDouble(_pick(json, ['CurrentTreadDepth', 'currentTreadDepth'])),
      percentageWorn: _asDouble(_pick(json, ['PercentageWorn', 'percentageWorn'])),
      currentPressure: _asDouble(_pick(json, ['CurrentPressure', 'currentPressure'])),
      locationId: _asInt(_pick(json, ['LocationId', 'locationId'])),
      parentAccountId: _asInt(_pick(json, ['ParentAccountId', 'parentAccountId'])),
      manufacturerId: _asInt(_pick(json, ['ManufacturerId', 'manufacturerId'])),
      typeId: _asInt(_pick(json, ['TypeId', 'typeId'])),
      sizeId: _asInt(_pick(json, ['SizeId', 'sizeId'])),
      currentHours: _asDouble(_pick(json, ['CurrentHours', 'currentHours'])),
      currentMiles: _asDouble(_pick(json, ['CurrentMiles', 'currentMiles'])),
      registeredDate: _asString(_pick(json, ['RegisteredDate', 'registeredDate'])),
      originalTread: _asDouble(_pick(json, ['OriginalTread', 'originalTread'])),
      removeAt: _asDouble(_pick(json, ['RemoveAt', 'removeAt'])),
      outsideTread: _asDouble(_pick(json, ['OutsideTread', 'outsideTread'])),
      middleTread: _asDouble(_pick(json, ['MiddleTread', 'middleTread'])),
      insideTread: _asDouble(_pick(json, ['InsideTread', 'insideTread'])),
      comments: _asString(_pick(json, ['Comments', 'comments', 'Comment', 'comment', 'TireComments', 'tireComments', 'Remarks', 'remarks'])),
      inspectionDate: _asString(_pick(json, ['InspectionDate', 'inspectionDate'])),
      mileageType: _asString(_pick(json, ['MileageType', 'mileageType'])),
      brandNo: _asString(_pick(json, ['BrandNo', 'brandNo', 'BrandNumber', 'brandNumber'])),
      dispositionId: finalDispId,
      dispositionName: finalDispName,
      createdBy: _asString(_pick(json, ['CreatedBy', 'createdBy'])),
      vehicleId: _asInt(_pick(json, ['VehicleId', 'vehicleId'])),
      vehicleNumber: _asString(_pick(json, ['VehicleNumber', 'vehicleNumber'])),
      wearConditionId: _pick(json, ['WearConditionId', 'wearConditionId', 'WearCondition', 'wearCondition', 'WearConditionsId', 'wearConditionsId', 'WearNonSkid', 'wearNonSkid']),
      casingConditionId: _pick(json, ['CasingConditionId', 'casingConditionId', 'CasingCondition', 'casingCondition', 'CasingConditionsId', 'casingConditionsId']),
      mountedRimId: _pick(json, ['MountedRimId', 'mountedRimId']),
      removalReasonId: _pick(json, ['RemovalReasonId', 'removalReasonId']),
      imagesLocation: _pick(json, ['ImagesLocation', 'imagesLocation']),
      action: resolvedAction,
      inspectionStatusId: _asInt(_pick(json, ['InspectionStatusId', 'inspectionStatusId'])),
      isRemoved: isRemoval || isExplicitRemoved || isExplicitRemove,
    );
  }
}

class PendingInspectionEntry {
  final PendingInspectionStatus? status;
  final PendingInspectionVehicle? vehicle;
  final PendingInspectionTire? tire;
  final List<PendingInspectionTire> tiresList;
  final List<String> unrecognizedKeys;

  PendingInspectionEntry({
    this.status,
    this.vehicle,
    this.tire,
    this.tiresList = const [],
    this.unrecognizedKeys = const [],
  });

  static const Set<String> _knownModelKeys = <String>{
    'Status', 'status', 'Pendinginspections', 'PendingInspections', 'pendinginspections',
    'pendingInspections', 'Vehicle', 'vehicle', 'VehicleDetails', 'vehicleList', 'VehicleList',
    'Tire', 'Tyre', 'tire', 'tyre', 'TireDetails', 'TyreDetails',
    'Tires', 'tires', 'tireList', 'TireList', 'Rims', 'rims', 'Inspection', 'inspection',
  };

  /// 🔧 EK "Model" object backend se aata hai jisme Vehicle/Tires/
  /// Pendinginspections teeno hi LISTS hoti hain — na ki hamesha ek-ek
  /// item ki. Har Vehicle-list entry EK ALAG pending-inspection "event"
  /// represent karti hai, chahe wahi VehicleId kai baar repeat ho (jaise
  /// ek truck ke 6 alag tyres 6 alag events ke roop me pending ho sakte
  /// hain — dekho terminal: VehicleId 60742 chhe baar aaya hai, har baar
  /// apne khud ke InspectionStatusId (744..749) ke saath).
  ///
  /// Correlation key hamesha InspectionStatusId hai: Vehicle, Tire, aur
  /// Status row teeno par same id hoti hai jab wo teeno EK hi event ka
  /// hissa hon. "Pendinginspections" list me baaki bacha hua bahut sara
  /// data (jinka id kisi Vehicle/Tire se match nahi karta) doosre
  /// accounts/vehicles ki purani history hai (GrandParentAccountId aur
  /// CreatedBy alag-alag hain) — use ignore kar dete hain.
  ///
  /// Pehle ka code sirf list ka PEHLA Vehicle aur PEHLA Tire leta tha aur
  /// ek hi entry banata tha — isse (a) 700+ duplicate status-log rows ke
  /// case me sahi tha (dedupe ho gaya), lekin (b) jab genuinely MULTIPLE
  /// alag-alag pending items hote hain (jaisa is naye response me hai)
  /// to sirf 1 hi dikhta tha aur baaki 6 discard ho jaate the. Ab har
  /// Vehicle-list entry ko uske matching Tire + Status ke saath alag
  /// PendingInspectionEntry banate hain.
  static List<PendingInspectionEntry> fromModelJson(Map<String, dynamic> json) {
    final dynamic statusCandidate = _pick(json, [
      'Pendinginspections', 'PendingInspections', 'pendinginspections', 'pendingInspections',
      'Status', 'status',
    ]);

    final dynamic vehicleCandidate = _pick(json, [
      'Vehicle', 'vehicle', 'VehicleDetails', 'vehicleList', 'VehicleList',
    ]);

    List<PendingInspectionVehicle> parsedVehicles = [];
    if (vehicleCandidate is Map<String, dynamic>) {
      parsedVehicles = [PendingInspectionVehicle.fromJson(vehicleCandidate)];
    } else if (vehicleCandidate is List) {
      parsedVehicles = vehicleCandidate
          .whereType<Map<String, dynamic>>()
          .map((e) => PendingInspectionVehicle.fromJson(e))
          .toList();
    }

    final dynamic tireCandidate = _pick(json, [
      'Tires', 'tires', 'Tire', 'tire', 'Tyre', 'tyre',
      'TireDetails', 'TyreDetails', 'tireList', 'TireList',
    ]);

    List<PendingInspectionTire> parsedTires = [];
    if (tireCandidate is Map<String, dynamic>) {
      parsedTires = [PendingInspectionTire.fromJson(tireCandidate)];
    } else if (tireCandidate is List) {
      parsedTires = tireCandidate
          .whereType<Map<String, dynamic>>()
          .map((e) => PendingInspectionTire.fromJson(e))
          .toList();
    }

    final unrecognized =
    json.keys.where((k) => !_knownModelKeys.contains(k)).toList();

    List<Map<String, dynamic>> statusMaps;
    if (statusCandidate is List) {
      statusMaps = statusCandidate.whereType<Map<String, dynamic>>().toList();
    } else if (statusCandidate is Map<String, dynamic>) {
      statusMaps = [statusCandidate];
    } else {
      statusMaps = [];
    }

    // Index status rows aur tires unke InspectionStatusId se — O(1) lookup
    // taaki N vehicles x M status rows ka nested loop na karna pade.
    final Map<int, Map<String, dynamic>> statusById = {};
    for (final s in statusMaps) {
      final id = _asInt(_pick(s, ['InspectionStatusId', 'inspectionStatusId']));
      if (id != null) statusById[id] = s;
    }
    // 🔧 IMPORTANT: after the submit() batching fix, ALL tyres of one
    // vehicle-inspection are sent under a SINGLE shared InspectionStatusId
    // (one Status object covers the whole tireList — see the API doc). The
    // backend echoes every one of those tyres back tagged with that SAME
    // id. A plain Map<int, Tire> here would silently OVERWRITE all-but-the
    // -last tyre for that id — which is exactly why only 1 tyre out of 6
    // was showing up. Use a Map<int, List<Tire>> so every tyre sharing an
    // id is kept, not just the last one processed.
    final Map<int, List<PendingInspectionTire>> tiresByStatusId = {};
    for (final t in parsedTires) {
      if (t.inspectionStatusId != null) {
        tiresByStatusId.putIfAbsent(t.inspectionStatusId!, () => []).add(t);
      }
    }

    if (parsedVehicles.isEmpty) {
      // Vehicle bilkul nahi mila (rare/flat shape) — check if parsedTires has vehicle info
      PendingInspectionVehicle? fallbackVehicle;
      for (final t in parsedTires) {
        if ((t.vehicleId != null && t.vehicleId != 0) ||
            (t.vehicleNumber != null && t.vehicleNumber!.trim().isNotEmpty)) {
          fallbackVehicle = PendingInspectionVehicle(
            vehicleId: t.vehicleId,
            vehicleNumber: t.vehicleNumber ?? '',
            inspectionStatusId: t.inspectionStatusId,
          );
          break;
        }
      }

      if (statusMaps.isEmpty) {
        return [
          PendingInspectionEntry(
            status: null,
            vehicle: fallbackVehicle,
            tire: parsedTires.isNotEmpty ? parsedTires.first : null,
            tiresList: parsedTires,
            unrecognizedKeys: unrecognized,
          ),
        ];
      }
      return [
        PendingInspectionEntry(
          status: PendingInspectionStatus.fromJson(statusMaps.last),
          vehicle: fallbackVehicle,
          tire: parsedTires.isNotEmpty ? parsedTires.first : null,
          tiresList: parsedTires,
          unrecognizedKeys: unrecognized,
        ),
      ];
    }

    // 🔧 Har Vehicle entry = ek alag event. Uske InspectionStatusId se
    // uska apna Tire aur Status row nikalo.
    // 🔧 Vehicle-list rows can repeat with the SAME InspectionStatusId (the
    // backend may echo the vehicle once per tyre it links to that status).
    // Dedupe by id so we build exactly ONE PendingInspectionEntry per
    // batch/event, carrying its COMPLETE tiresList — not one entry per
    // tyre with the rest silently dropped.
    final List<PendingInspectionEntry> entries = [];
    final Set<int> seenStatusIds = {};
    for (final v in parsedVehicles) {
      int? id = v.inspectionStatusId;
      if (id == null || id == 0) {
        // Fallback: lookup from statusMaps matching vehicleId
        final matchingStatus = statusMaps.firstWhereOrNull((s) {
          final sid = _asInt(_pick(s, ['InspectionStatusId', 'inspectionStatusId']));
          final vId = _asInt(_pick(s, ['VehicleId', 'vehicleId']));
          return (v.vehicleId != null && vId == v.vehicleId) ||
              (v.vehicleId != null && sid == v.vehicleId);
        });
        if (matchingStatus != null) {
          id = _asInt(_pick(matchingStatus, ['InspectionStatusId', 'inspectionStatusId']));
        }
      }
      if (id == null || id == 0) {
        // Try finding status ID from matching tires
        final matchingTireWithStatus = parsedTires.firstWhereOrNull((t) =>
        t.inspectionStatusId != null &&
            t.inspectionStatusId != 0 &&
            ((v.vehicleId != null && v.vehicleId != 0 && t.vehicleId == v.vehicleId) ||
                (v.vehicleNumber != null && v.vehicleNumber!.isNotEmpty &&
                    t.vehicleNumber?.trim().toLowerCase() == v.vehicleNumber!.trim().toLowerCase())));
        if (matchingTireWithStatus != null) {
          id = matchingTireWithStatus.inspectionStatusId;
        } else if (statusMaps.length == 1) {
          id = _asInt(_pick(statusMaps.first, ['InspectionStatusId', 'inspectionStatusId']));
        }
      }

      if (id != null) {
        if (seenStatusIds.contains(id)) continue;
        seenStatusIds.add(id);
      }

      final List<PendingInspectionTire> matchedTires = [];
      if (id != null && (tiresByStatusId[id]?.isNotEmpty ?? false)) {
        matchedTires.addAll(tiresByStatusId[id]!);
      } else if (parsedVehicles.length == 1) {
        matchedTires.addAll(parsedTires);
      }

      // Also merge any tyres from parsedTires whose vehicleId, vehicleNumber, or status matches this vehicle
      for (final t in parsedTires) {
        // 🔒 CRITICAL: If this tyre has an inspectionStatusId that does NOT match id,
        // it belongs to a DIFFERENT inspection event! NEVER merge it into this entry!
        if (id != null && id != 0 && t.inspectionStatusId != null && t.inspectionStatusId != 0 && t.inspectionStatusId != id) {
          continue;
        }
        final idMatches = v.vehicleId != null && v.vehicleId != 0 && t.vehicleId == v.vehicleId;
        final numMatches = v.vehicleNumber != null && v.vehicleNumber!.isNotEmpty &&
            t.vehicleNumber?.trim().toLowerCase() == v.vehicleNumber!.trim().toLowerCase();
        final statusMatches = id != null && id != 0 && t.inspectionStatusId == id;
        final singleVehicleMatch = parsedVehicles.length == 1 &&
            (t.vehicleId == null || t.vehicleId == 0) &&
            (t.vehicleNumber == null || t.vehicleNumber!.isEmpty);
        if (idMatches || numMatches || statusMatches || singleVehicleMatch) {
          final alreadyPresent = matchedTires.any((mt) =>
          (mt.tireId != null && mt.tireId != 0 && mt.tireId == t.tireId) ||
              (mt.tireSerialNo != null && mt.tireSerialNo!.trim().isNotEmpty &&
                  mt.tireSerialNo!.trim().toUpperCase() == (t.tireSerialNo ?? '').trim().toUpperCase()));
          if (!alreadyPresent) {
            matchedTires.add(t);
          }
        }
      }

      Map<String, dynamic>? matchedStatusMap = id != null ? statusById[id] : null;
      if (matchedStatusMap == null && statusMaps.isNotEmpty) {
        matchedStatusMap = statusMaps.firstWhereOrNull((s) {
          final sid = _asInt(_pick(s, ['InspectionStatusId', 'inspectionStatusId']));
          return sid == id || sid == v.vehicleId;
        }) ?? statusMaps.last;
      }

      entries.add(
        PendingInspectionEntry(
          status: matchedStatusMap != null
              ? PendingInspectionStatus.fromJson(matchedStatusMap)
              : null,
          vehicle: v,
          tire: matchedTires.isNotEmpty ? matchedTires.first : null,
          tiresList: matchedTires,
          unrecognizedKeys: unrecognized,
        ),
      );
    }

    // 🔧 Recover any tyres in parsedTires that were not matched by vehicle inspectionStatusId
    // (e.g. tyre removals or individual tyre updates that have their own status or no vehicle row)
    final Set<String> includedTireKeys = {};
    for (final e in entries) {
      final statusId = e.status?.inspectionStatusId ?? e.vehicle?.inspectionStatusId;
      if (e.tire != null) {
        includedTireKeys.add('${e.tire!.inspectionStatusId ?? statusId}_${e.tire!.tireId}_${e.tire!.tireSerialNo}');
      }
      for (final t in e.tiresList) {
        includedTireKeys.add('${t.inspectionStatusId ?? statusId}_${t.tireId}_${t.tireSerialNo}');
      }
    }

    final orphanedTires = parsedTires.where((t) {
      final key = '${t.inspectionStatusId}_${t.tireId}_${t.tireSerialNo}';
      return !includedTireKeys.contains(key);
    }).toList();
    if (orphanedTires.isNotEmpty) {
      final Map<int?, List<PendingInspectionTire>> orphanedGroups = {};
      for (final t in orphanedTires) {
        orphanedGroups.putIfAbsent(t.inspectionStatusId, () => []).add(t);
      }
      for (final entry in orphanedGroups.entries) {
        final statusId = entry.key;
        final tires = entry.value;
        final sampleTire = tires.first;

        // Try to match sampleTire to an existing parsedVehicle with rich vehicle metadata
        final matchingVehicle = parsedVehicles.firstWhereOrNull((pv) {
          if (statusId != null && statusId != 0 && pv.inspectionStatusId == statusId) {
            return true;
          }
          if (sampleTire.vehicleId != null && sampleTire.vehicleId != 0 && pv.vehicleId == sampleTire.vehicleId) {
            return true;
          }
          if (sampleTire.vehicleNumber != null && sampleTire.vehicleNumber!.trim().isNotEmpty &&
              pv.vehicleNumber != null && pv.vehicleNumber!.trim().toLowerCase() == sampleTire.vehicleNumber!.trim().toLowerCase()) {
            return true;
          }
          return false;
        }) ?? (parsedVehicles.length == 1 ? parsedVehicles.first : null);

        final v = matchingVehicle ?? PendingInspectionVehicle(
          vehicleId: sampleTire.vehicleId,
          vehicleNumber: sampleTire.vehicleNumber ?? '',
          inspectionStatusId: statusId,
        );
        final matchedStatusMap = statusId != null ? statusById[statusId] : null;
        entries.add(
          PendingInspectionEntry(
            status: matchedStatusMap != null ? PendingInspectionStatus.fromJson(matchedStatusMap) : null,
            vehicle: v,
            tire: sampleTire,
            tiresList: tires,
            unrecognizedKeys: unrecognized,
          ),
        );
      }
    }


    return entries;
  }

  /// Backward-compatible single-object parse (kahin aur is API se koi flat
  factory PendingInspectionEntry.fromJson(Map<String, dynamic> json) {
    final entries = fromModelJson(json);

    return entries.isNotEmpty
        ? entries.first
        : PendingInspectionEntry(unrecognizedKeys: json.keys.toList())
    ;
  }
}