import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emtrack/inspection_approval/search.dart';
import 'package:emtrack/inspection_approval/tyre.dart';
import 'package:emtrack/widgets/vehicle_daigram.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/all_vehicles_controller.dart';
import '../controllers/all_tyre_controller.dart';
import '../inspection/vehicle_inspe_model.dart';
import '../inspection/vehicle_inspe_service.dart';
import '../services/create_vehicle_service.dart';
import '../services/preferences_service.dart';
import '../services/update_vehicle_service.dart';
import '../services/install_tyre_service.dart';
import '../services/remove_tyre_service.dart';
import '../services/offline_hive_service.dart';
import '../models/vehicle_model.dart';
import '../routes/app_pages.dart';
import '../utils/secure_storage.dart';
import '../utils/mesurment_helper_class.dart';
import '../utils/approval_localizations.dart';
import '../search_tyre_vehicle/Search_vehicle_tyre_controller.dart';
import '../utils/tyre_unit_history.dart';
import '../utils/hive_prefe.dart';
import '../utils/local_image_cache.dart';
import '../utils/network_helper.dart';
import '../services/tyre_service.dart';
import '../utils/global_state_referesh.dart';
import '../controllers/inspect_tyre_controller.dart';

class IWVehicleInspectionScreen extends StatefulWidget {
  final String vehicleId;
  final int vehicleIdInt;
  final String vehicleNumber;
  final String axleConfig;
  final RxList<InstalledTire> oldTires;
  final RxList<InstalledTire> newTires;
  final int? pendingInspectionId;
  final dynamic imagesLocation;

  const IWVehicleInspectionScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleIdInt,
    required this.vehicleNumber,
    required this.oldTires,
    required this.newTires,
    this.axleConfig = '22',
    this.pendingInspectionId,
    this.imagesLocation,
  });

  @override
  State<IWVehicleInspectionScreen> createState() =>
      _IWVehicleInspectionScreenState();
}

class _IWVehicleInspectionScreenState
    extends State<IWVehicleInspectionScreen> {
  final AuthController auth = Get.find<AuthController>();

  final TextEditingController _vehicleIdCtrl   = TextEditingController();
  final TextEditingController _hoursCtrl       = TextEditingController();
  final TextEditingController _kmCtrl          = TextEditingController();
  final TextEditingController _commentsCtrl    = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoading    = true;

  String _axleConfig = '22';
  String _mileageUnitLabel = 'KM';
  // Exact canonical (KM) value jo server/pending se aayi — display text
  // (rounded/converted) se wapas nahi nikalte, taaki save me precision na jaye.
  double? _canonicalKm;
  String _canonicalDistanceUnit = 'KM';

  void _syncVehicleDistanceDisplay() {
    final double base = _canonicalKm ?? 0.0;
    _mileageUnitLabel = _canonicalDistanceUnit;
    if (base <= 0) {
      _kmCtrl.text = '0';
      return;
    }
    _kmCtrl.text = base.round().toString();
  }

  // Specific inspection images list for this vehicle/tire only
  final RxList<String> _inspectionImages = <String>[].obs;

  PendingInspectionVehicle? _pendingVehicle;
  String? _pendingInspectionDate;
  List<InstalledTire> _liveTires = [];
  List<PendingInspectionTire> _allPendingTiresForVehicle = [];
  final RxList<PendingInspectionTire> _pendingRemovedTires = <PendingInspectionTire>[].obs;

  double _resolveServerPressure(num? v) {
    if (v == null || v == 0) return 0.0;
    final double val = v.toDouble();
    if (val > 250) {
      final double normalized = (val / 14.5038).roundToDouble();
      if (MeasurementHelper.pressureLabel == 'BAR' || MeasurementHelper.pressureLabel == 'PSI') {
        return normalized;
      }
      return MeasurementHelper.toDisplayPressure(val, sourceUnit: 'PSI');
    }
    return val;
  }

  double _resolveServerTread(num? v) {
    if (v == null || v == 0) return 0.0;
    final double val = v.toDouble();
    if (MeasurementHelper.isImperial) {
      return MeasurementHelper.toDisplayTreadFromBackendMm(val);
    }
    return val;
  }

  double _resolveServerDistance(num? v, {dynamic tireId}) {
    if (v == null || v == 0) return 0.0;
    if (tireId != null) {
      final savedRaw = TyreUnitHistory.getRawMiles(tireId);
      final savedUnit = TyreUnitHistory.getDistanceUnit(tireId);
      if (savedRaw != null && savedRaw > 0) {
        if (MeasurementHelper.isImperial) return savedRaw;
        if (MeasurementHelper.isMetric) {
          if (savedUnit != null && (savedUnit.toLowerCase() == 'miles' || savedUnit.toLowerCase() == 'imperial')) {
            return MeasurementHelper.toDisplayDistance(savedRaw, sourceUnit: 'Miles');
          }
          return savedRaw;
        }
      }
      if (savedUnit != null && savedUnit.isNotEmpty) {
        if (MeasurementHelper.isImperial && (savedUnit.toLowerCase() == 'miles' || savedUnit.toLowerCase() == 'imperial')) {
          return v.toDouble();
        }
        return MeasurementHelper.toDisplayDistance(v.toDouble(), sourceUnit: savedUnit);
      }
    }
    // If pending inspection was submitted in Imperial (Miles) or user is in Imperial mode:
    if (_srcMeasurement?.toLowerCase() == 'imperial' || MeasurementHelper.isImperial) {
      return v.toDouble();
    }
    return MeasurementHelper.toDisplayDistance(v.toDouble(), sourceUnit: _srcMeasurement ?? 'km');
  }

  InstalledTire _resolveLiveTireForDisplay(InstalledTire lt) {
    final int? tId = lt.tireId;
    final double? rawTo = tId != null ? TyreUnitHistory.getRawOutside(tId) : null;
    final double? rawTm = tId != null ? TyreUnitHistory.getRawMiddle(tId) : null;
    final double? rawTi = tId != null ? TyreUnitHistory.getRawInside(tId) : null;
    final double? rawPress = tId != null ? TyreUnitHistory.getRawPressure(tId) : null;
    final double? rawMiles = tId != null ? TyreUnitHistory.getRawMiles(tId) : null;
    final double? rawPct = (tId != null ? TyreUnitHistory.getPercentageWorn(tId) : null) ??
        (lt.tireSerialNo != null ? TyreUnitHistory.getPercentageWorn(lt.tireSerialNo!) : null);

    final double to = (rawTo != null && rawTo > 0)
        ? rawTo
        : (lt.outsideTread != null && lt.outsideTread! > 0
        ? _resolveServerTread(lt.outsideTread!)
        : 0.0);
    final double tm = (rawTm != null && rawTm > 0)
        ? rawTm
        : (lt.middleTread != null && lt.middleTread! > 0
        ? _resolveServerTread(lt.middleTread!)
        : 0.0);
    final double ti = (rawTi != null && rawTi > 0)
        ? rawTi
        : (lt.insideTread != null && lt.insideTread! > 0
        ? _resolveServerTread(lt.insideTread!)
        : 0.0);
    final double press = (rawPress != null && rawPress > 0)
        ? rawPress
        : (lt.currentPressure != null && lt.currentPressure! > 0
        ? _resolveServerPressure(lt.currentPressure!)
        : 0.0);
    final double miles = (rawMiles != null && rawMiles > 0)
        ? rawMiles
        : (lt.currentMiles != null && lt.currentMiles! > 0
        ? _resolveServerDistance(lt.currentMiles, tireId: lt.tireId)
        : 0.0);
    final double pct = (rawPct != null && rawPct >= 0)
        ? rawPct
        : (lt.percentageWorn ?? 0.0);

    return InstalledTire(
      tireId: lt.tireId,
      locationId: lt.locationId,
      parentAccountId: lt.parentAccountId,
      tireSerialNo: lt.tireSerialNo,
      registeredDate: lt.registeredDate,
      manufacturerId: lt.manufacturerId,
      typeId: lt.typeId,
      sizeId: lt.sizeId,
      sizeName: lt.sizeName,
      typeName: lt.typeName,
      currentHours: lt.currentHours,
      currentMiles: miles > 0 ? miles : lt.currentMiles,
      wheelPosition: lt.wheelPosition,
      percentageWorn: pct,
      wearConditionId: lt.wearConditionId,
      currentTreadDepth: tm > 0 ? tm : (to > 0 ? to : lt.currentTreadDepth),
      currentPressure: press > 0 ? press : lt.currentPressure,
      casingConditionId: lt.casingConditionId,
      mountedRimId: lt.mountedRimId,
      outsideTread: to > 0 ? to : lt.outsideTread,
      middleTread: tm > 0 ? tm : lt.middleTread,
      insideTread: ti > 0 ? ti : lt.insideTread,
      originalTread: lt.originalTread,
      removeAt: lt.removeAt,
      comments: lt.comments,
      inspectionDate: lt.inspectionDate,
      mileageType: lt.mileageType,
      imagesLocation: lt.imagesLocation,
      brandNo: lt.brandNo,
      dispositionId: lt.dispositionId,
      dispositionName: lt.dispositionName,
      createdBy: lt.createdBy,
      manufacturerName: lt.manufacturerName,
      vehicleId: lt.vehicleId,
      vehicleNumber: lt.vehicleNumber,
      removalReasonId: lt.removalReasonId,
      isFromSearch: lt.isFromSearch,
      action: lt.action,
    );
  }

  InstalledTire _mapPendingToInstalled(PendingInspectionTire t) {
    dynamic resolvedWear = t.wearConditionId;
    dynamic resolvedCasing = t.casingConditionId;
    String? resolvedComments = (t.comments != null && t.comments!.trim().isNotEmpty) ? t.comments!.trim() : null;
    dynamic resolvedImages = t.imagesLocation;

    bool needsWear = resolvedWear == null || resolvedWear == 0 || resolvedWear == '0' || resolvedWear.toString().trim().isEmpty;
    bool needsCasing = resolvedCasing == null || resolvedCasing == 0 || resolvedCasing == '0' || resolvedCasing.toString().trim().isEmpty;
    bool needsComments = resolvedComments == null || resolvedComments.isEmpty;
    bool needsImages = resolvedImages == null || resolvedImages.toString().trim().isEmpty;

    // Check vehicle inspection cache (which has the latest submitted inspection tyre data)
    if (needsWear || needsCasing || needsComments || needsImages) {
      final cacheKeys = [
        widget.vehicleId,
        widget.vehicleIdInt.toString(),
        if (widget.vehicleNumber.isNotEmpty) widget.vehicleNumber,
      ];
      for (final k in cacheKeys) {
        final cached = OfflineHiveService.getInspectionCache(k);
        if (cached != null) {
          try {
            final decoded = jsonDecode(cached) as Map<String, dynamic>;
            final m = (decoded['model'] as Map<String, dynamic>?) ?? decoded;
            final tList = (m['installedTires'] ?? m['tireList'] ?? m['tiresList']) as List?;
            if (tList != null) {
              for (final raw in tList.whereType<Map<String, dynamic>>()) {
                final cTid = raw['tireId'] ?? raw['TireId'];
                final cSn = (raw['tireSerialNo'] ?? raw['TireSerialNo'])?.toString().trim().toUpperCase();
                final cPos = (raw['wheelPosition'] ?? raw['WheelPosition'])?.toString().trim().toUpperCase();
                final matchId = (t.tireId != null && t.tireId != 0 && cTid != null && cTid.toString() == t.tireId.toString());
                final matchSn = (t.tireSerialNo != null && t.tireSerialNo!.trim().isNotEmpty && cSn == t.tireSerialNo!.trim().toUpperCase());
                final matchPos = (t.wheelPosition != null && t.wheelPosition!.trim().isNotEmpty && cPos == t.wheelPosition!.trim().toUpperCase());

                if (matchId || matchSn || matchPos) {
                  if (needsWear && raw['wearConditionId'] != null) {
                    resolvedWear = raw['wearConditionId'];
                    needsWear = false;
                  }
                  if (needsCasing && raw['casingConditionId'] != null) {
                    resolvedCasing = raw['casingConditionId'];
                    needsCasing = false;
                  }
                  if (needsComments && raw['comments'] != null && raw['comments'].toString().trim().isNotEmpty) {
                    resolvedComments = raw['comments'].toString().trim();
                    needsComments = false;
                  }
                  if (needsImages && raw['imagesLocation'] != null && raw['imagesLocation'].toString().trim().isNotEmpty) {
                    resolvedImages = raw['imagesLocation'];
                    needsImages = false;
                  }
                  break;
                }
              }
            }
          } catch (_) {}
        }
        if (!needsWear && !needsCasing && !needsComments && !needsImages) break;
      }
    }

    if (t.tireId != null && t.tireId! > 0) {
      if (needsWear || needsCasing || needsComments) {
        final cached = OfflineHiveService.getTireDetailCache(t.tireId!);
        if (cached != null) {
          try {
            final decoded = jsonDecode(cached) as Map<String, dynamic>;
            final m = decoded['model'] as Map<String, dynamic>?;
            if (m != null) {
              if (needsWear && m['wearConditionId'] != null) {
                resolvedWear = m['wearConditionId'];
                needsWear = false;
              }
              if (needsCasing && m['casingConditionId'] != null) {
                resolvedCasing = m['casingConditionId'];
                needsCasing = false;
              }
              if (needsComments && m['comments'] != null && m['comments'].toString().trim().isNotEmpty) {
                resolvedComments = m['comments'].toString().trim();
                needsComments = false;
              }
            }
          } catch (_) {}
        }
      }
      if (needsWear || needsCasing || needsComments) {
        final hiveTyre = OfflineHiveService.getTyreById(t.tireId!);
        if (hiveTyre != null) {
          if (needsWear && hiveTyre.wearConditionId != null) {
            resolvedWear = hiveTyre.wearConditionId;
            needsWear = false;
          }
          if (needsCasing && hiveTyre.casingConditionId != null) {
            resolvedCasing = hiveTyre.casingConditionId;
            needsCasing = false;
          }
          if (needsComments && hiveTyre.comments != null && hiveTyre.comments!.trim().isNotEmpty) {
            resolvedComments = hiveTyre.comments!.trim();
            needsComments = false;
          }
        }
      }
    }

    double? rawOutside;
    double? rawMiddle;
    double? rawInside;
    double? rawPressure;
    double? rawDepth;
    double? rawMiles;

    // 1. Check TyreUnitHistory by tireId
    if (t.tireId != null && t.tireId! > 0) {
      final savedRawOutside = TyreUnitHistory.getRawOutside(t.tireId!);
      if (savedRawOutside != null && savedRawOutside > 0) rawOutside = savedRawOutside;
      final savedRawMiddle = TyreUnitHistory.getRawMiddle(t.tireId!);
      if (savedRawMiddle != null && savedRawMiddle > 0) rawMiddle = savedRawMiddle;
      final savedRawInside = TyreUnitHistory.getRawInside(t.tireId!);
      if (savedRawInside != null && savedRawInside > 0) rawInside = savedRawInside;
      final savedRawPress = TyreUnitHistory.getRawPressure(t.tireId!);
      if (savedRawPress != null && savedRawPress > 0) rawPressure = savedRawPress;
      final savedRawM = TyreUnitHistory.getRawMiles(t.tireId!);
      if (savedRawM != null && savedRawM > 0) rawMiles = savedRawM;
    }

    // 2. Check TyreUnitHistory by tireSerialNo
    if (t.tireSerialNo != null && t.tireSerialNo!.trim().isNotEmpty) {
      final sn = t.tireSerialNo!.trim();
      final snOutside = TyreUnitHistory.getRawOutside(sn);
      if (rawOutside == null && snOutside != null && snOutside > 0) rawOutside = snOutside;
      final snMiddle = TyreUnitHistory.getRawMiddle(sn);
      if (rawMiddle == null && snMiddle != null && snMiddle > 0) rawMiddle = snMiddle;
      final snInside = TyreUnitHistory.getRawInside(sn);
      if (rawInside == null && snInside != null && snInside > 0) rawInside = snInside;
      final snPress = TyreUnitHistory.getRawPressure(sn);
      if (rawPressure == null && snPress != null && snPress > 0) rawPressure = snPress;
      final snMiles = TyreUnitHistory.getRawMiles(sn);
      if (rawMiles == null && snMiles != null && snMiles > 0) rawMiles = snMiles;
    }

    // 3. Check inspection cache (which has the exact values submitted by user)
    if (rawOutside == null || rawMiddle == null || rawInside == null || rawPressure == null) {
      final cacheKeys = [
        widget.vehicleId,
        widget.vehicleIdInt.toString(),
        if (widget.vehicleNumber.isNotEmpty) widget.vehicleNumber,
      ];
      for (final k in cacheKeys) {
        final cached = OfflineHiveService.getInspectionCache(k);
        if (cached != null) {
          try {
            final decoded = jsonDecode(cached) as Map<String, dynamic>;
            final m = (decoded['model'] as Map<String, dynamic>?) ?? decoded;
            final tList = (m['installedTires'] ?? m['tireList'] ?? m['tiresList']) as List?;
            if (tList != null) {
              for (final raw in tList.whereType<Map<String, dynamic>>()) {
                final cTid = raw['tireId'] ?? raw['TireId'];
                final cSn = (raw['tireSerialNo'] ?? raw['TireSerialNo'])?.toString().trim().toUpperCase();
                final cPos = (raw['wheelPosition'] ?? raw['WheelPosition'])?.toString().trim().toUpperCase();
                final matchId = (t.tireId != null && t.tireId != 0 && cTid != null && cTid.toString() == t.tireId.toString());
                final matchSn = (t.tireSerialNo != null && t.tireSerialNo!.trim().isNotEmpty && cSn == t.tireSerialNo!.trim().toUpperCase());
                final matchPos = (t.wheelPosition != null && t.wheelPosition!.trim().isNotEmpty && cPos == t.wheelPosition!.trim().toUpperCase());

                if (matchId || matchSn || matchPos) {
                  final co = double.tryParse(raw['outsideTread']?.toString() ?? '');
                  final cm = double.tryParse(raw['middleTread']?.toString() ?? '');
                  final ci = double.tryParse(raw['insideTread']?.toString() ?? '');
                  final cp = double.tryParse(raw['currentPressure']?.toString() ?? '');
                  final ckm = double.tryParse(raw['currentMiles']?.toString() ?? '');
                  if (rawOutside == null && co != null && co > 0) rawOutside = co;
                  if (rawMiddle == null && cm != null && cm > 0) rawMiddle = cm;
                  if (rawInside == null && ci != null && ci > 0) rawInside = ci;
                  if (rawPressure == null && cp != null && cp > 0) rawPressure = cp;
                  if (rawMiles == null && ckm != null && ckm > 0) rawMiles = ckm;
                  break;
                }
              }
            }
          } catch (_) {}
        }
        if (rawOutside != null && rawMiddle != null && rawInside != null && rawPressure != null) break;
      }
    }

    // 4. Fallback to PendingInspectionTire fields
    if (rawOutside == null && t.outsideTread != null && t.outsideTread! > 0) {
      rawOutside = t.outsideTread;
    }
    if (rawMiddle == null && t.middleTread != null && t.middleTread! > 0) {
      rawMiddle = t.middleTread;
    }
    if (rawInside == null && t.insideTread != null && t.insideTread! > 0) {
      rawInside = t.insideTread;
    }
    if (rawPressure == null && t.currentPressure != null && t.currentPressure! > 0) {
      rawPressure = t.currentPressure;
    }
    if (t.currentTreadDepth != null && t.currentTreadDepth! > 0) {
      rawDepth = t.currentTreadDepth;
    }
    if (rawMiles == null && t.currentMiles != null && t.currentMiles! > 0) {
      rawMiles = t.currentMiles;
    }

    // 5. Fallback to TireDetailCache ONLY for any missing fields (never overwrite valid readings)
    if (t.tireId != null && t.tireId! > 0 &&
        (rawOutside == null || rawMiddle == null || rawInside == null || rawPressure == null || rawMiles == null)) {
      final cached = OfflineHiveService.getTireDetailCache(t.tireId!);
      if (cached != null) {
        try {
          final decoded = jsonDecode(cached) as Map<String, dynamic>;
          final m = decoded['model'] as Map<String, dynamic>?;
          if (m != null) {
            final co = double.tryParse(m['outsideTread']?.toString() ?? '');
            final cm = double.tryParse(m['middleTread']?.toString() ?? '');
            final ci = double.tryParse(m['insideTread']?.toString() ?? '');
            final cp = double.tryParse(m['currentPressure']?.toString() ?? '');
            final ckm = double.tryParse(m['currentMiles']?.toString() ?? '');
            if (rawOutside == null && co != null && co > 0) rawOutside = co;
            if (rawMiddle == null && cm != null && cm > 0) rawMiddle = cm;
            if (rawInside == null && ci != null && ci > 0) rawInside = ci;
            if (rawPressure == null && cp != null && cp > 0) rawPressure = cp;
            if (rawMiles == null && ckm != null && ckm > 0) rawMiles = ckm;
          }
        } catch (_) {}
      }
    }

    final double resolvedPressure = rawPressure != null ? _resolveServerPressure(rawPressure) : 0.0;
    final double resolvedOutside = rawOutside != null ? _resolveServerTread(rawOutside) : 0.0;
    final double resolvedMiddle = rawMiddle != null ? _resolveServerTread(rawMiddle) : 0.0;
    final double resolvedInside = rawInside != null ? _resolveServerTread(rawInside) : 0.0;
    final double resolvedDepth = rawDepth != null ? _resolveServerTread(rawDepth) : (resolvedMiddle > 0 ? resolvedMiddle : 0.0);
    final double resolvedMiles = rawMiles != null ? _resolveServerDistance(rawMiles, tireId: t.tireId) : 0.0;
    final double? rawPct = (t.tireId != null ? TyreUnitHistory.getPercentageWorn(t.tireId) : null) ??
        (t.tireSerialNo != null ? TyreUnitHistory.getPercentageWorn(t.tireSerialNo!) : null);
    final double resolvedPct = (rawPct != null && rawPct >= 0)
        ? rawPct
        : (t.percentageWorn ?? 0.0);

    final String? resolvedInspectionDate = (t.inspectionDate != null && t.inspectionDate!.trim().isNotEmpty)
        ? t.inspectionDate
        : _pendingInspectionDate;

    return InstalledTire(
      tireId:            t.tireId,
      locationId:        t.locationId,
      parentAccountId:   t.parentAccountId,
      tireSerialNo:      t.tireSerialNo,
      registeredDate:    t.registeredDate,
      manufacturerId:    t.manufacturerId,
      typeId:            t.typeId,
      sizeId:            t.sizeId,
      sizeName:          t.sizeName,
      typeName:          t.typeName,
      currentHours:      t.currentHours,
      currentMiles:      resolvedMiles > 0 ? resolvedMiles : t.currentMiles,
      wheelPosition:     t.wheelPosition,
      percentageWorn:    resolvedPct,
      wearConditionId:   resolvedWear,
      currentTreadDepth: resolvedDepth > 0 ? resolvedDepth : t.currentTreadDepth,
      currentPressure:   resolvedPressure > 0 ? resolvedPressure : t.currentPressure,
      casingConditionId: resolvedCasing,
      mountedRimId:      t.mountedRimId,
      outsideTread:      resolvedOutside > 0 ? resolvedOutside : t.outsideTread,
      middleTread:       resolvedMiddle > 0 ? resolvedMiddle : t.middleTread,
      insideTread:       resolvedInside > 0 ? resolvedInside : t.insideTread,
      originalTread:     t.originalTread,
      removeAt:          t.removeAt,
      comments:          resolvedComments,
      inspectionDate:    resolvedInspectionDate ?? t.inspectionDate,
      mileageType:       t.mileageType,
      imagesLocation:    resolvedImages ?? t.imagesLocation,
      brandNo:           t.brandNo,
      dispositionId:     t.dispositionId,
      dispositionName:   t.dispositionName,
      createdBy:         t.createdBy,
      manufacturerName:  t.manufacturerName,
      vehicleId:         t.vehicleId ?? widget.vehicleIdInt,
      vehicleNumber:     t.vehicleNumber ?? widget.vehicleNumber,
      removalReasonId:   t.removalReasonId,
    );
  }

  String _dispositionIdToName(int id) {
    switch (id) {
      case 1:  return 'Scrap';
      case 2:  return 'Repair';
      case 3:  return 'Retread';
      case 4:  return 'On Hold';
      case 7:  return 'Installed';
      case 8:  return 'Inventory';
      default: return 'Inventory';
    }
  }

  int _resolveRemovedDispositionId(InstalledTire t) {
    final dName = (t.dispositionName ?? '').trim().toLowerCase();
    if (dName.contains('scrap') || t.dispositionId == 1) return 1;
    if (dName.contains('repair') || t.dispositionId == 2) return 2;
    if (dName.contains('retread') || t.dispositionId == 3) return 3;
    if (dName.contains('hold') || t.dispositionId == 4) return 4;

    // Check Hive if local tyre has user's selected remove disposition
    if (t.tireId != null && t.tireId! > 0) {
      final hiveTyre = OfflineHiveService.getTyreById(t.tireId!);
      if (hiveTyre != null) {
        final hId = hiveTyre.dispositionId ?? 0;
        final hName = (hiveTyre.dispositionName ?? '').trim().toLowerCase();
        if (hId == 1 || hName.contains('scrap')) return 1;
        if (hId == 2 || hName.contains('repair')) return 2;
        if (hId == 3 || hName.contains('retread')) return 3;
        if (hId == 4 || hName.contains('hold')) return 4;
      }
    }

    if (t.dispositionId != null && t.dispositionId! > 0 && t.dispositionId != 7 && t.dispositionId != 5) {
      return t.dispositionId!;
    }
    if (dName.contains('inventory') || t.dispositionId == 8) return 8;
    return 8;
  }

  bool _isTireRemoved(PendingInspectionTire t, [List<InstalledTire>? liveList]) {
    final act = (t.action ?? '').trim().toLowerCase();
    if (act.contains('remove')) return true;

    final rId = t.removalReasonId is int
        ? t.removalReasonId as int
        : int.tryParse(t.removalReasonId?.toString() ?? '') ?? 0;
    if (rId > 0) return true;

    if (t.isRemoved == true) return true;

    if (t.tireId != null && t.tireId! > 0 && OfflineHiveService.isTireRecentlyRemoved(t.tireId!)) {
      return true;
    }

    final pos = (t.wheelPosition ?? '').trim();
    final bool hasWheelPos = pos.isNotEmpty && pos != '0' && pos != '-';

    // 🛞 If it has NO wheel position, it is unmounted/removed!
    if (!hasWheelPos) return true;

    final dId = t.dispositionId is int
        ? t.dispositionId as int
        : int.tryParse(t.dispositionId?.toString() ?? '') ?? 0;
    final dispName = (t.dispositionName ?? '').trim().toLowerCase();

    // 🛞 If disposition is explicitly Scrap, Repair, Retread, Hold, it IS removed!
    if (dId == 1 || dId == 2 || dId == 3 || dId == 4 || dId == 6 ||
        dispName.contains('scrap') ||
        dispName.contains('repair') ||
        dispName.contains('retread') ||
        dispName.contains('hold') ||
        dispName.contains('remove')) {
      return true;
    }

    // 🛞 Check against live tyres on this vehicle:
    final currentLive = liveList ?? (_liveTires.isNotEmpty ? _liveTires : widget.oldTires);
    final bool wasMountedOnThisVehicle = currentLive.any((lt) =>
    (t.tireId != null && t.tireId! > 0 && lt.tireId == t.tireId) ||
        (t.tireSerialNo != null && t.tireSerialNo!.trim().isNotEmpty &&
            (lt.tireSerialNo ?? '').trim().toUpperCase() == t.tireSerialNo!.trim().toUpperCase())
    );

    if (wasMountedOnThisVehicle) {
      // It was mounted on the vehicle before inspection.
      // If its pending disposition is Inventory (8) or anything other than Mounted (7),
      // it was removed to Inventory!
      if (dId == 8 || dispName.contains('inventory') || (!dispName.contains('mount') && dId != 7)) {
        return true;
      }
    } else {
      // It was NOT mounted on this vehicle previously in live database.
      // If it has a wheel position and is not explicitly removed, it is an INSTALLED tyre!
      if (hasWheelPos && !act.contains('remove')) {
        return false;
      }
    }

    // 🛞 If disposition is Mounted (7), it is NOT removed!
    if (dId == 7 || dispName.contains('mount')) {
      return false;
    }

    if (act.contains('install')) return false;

    // Fallback: If it has a valid wheel position and no removal reason:
    if (hasWheelPos && rId == 0 && dId != 8) {
      return false;
    }

    return false;
  }

  PendingInspectionTire _mapInstalledToPending(InstalledTire t, {String action = 'Remove'}) {
    return PendingInspectionTire(
      tireId:            t.tireId,
      locationId:        t.locationId,
      parentAccountId:   t.parentAccountId,
      tireSerialNo:      t.tireSerialNo,
      registeredDate:    t.registeredDate,
      manufacturerId:    t.manufacturerId,
      typeId:            t.typeId,
      sizeId:            t.sizeId,
      sizeName:          t.sizeName,
      typeName:          t.typeName,
      currentHours:      t.currentHours,
      currentMiles:      t.currentMiles,
      wheelPosition:     t.wheelPosition,
      percentageWorn:    t.percentageWorn,
      wearConditionId:   t.wearConditionId,
      currentTreadDepth: t.currentTreadDepth,
      currentPressure:   t.currentPressure,
      casingConditionId: t.casingConditionId,
      mountedRimId:      t.mountedRimId,
      outsideTread:      t.outsideTread,
      middleTread:       t.middleTread,
      insideTread:       t.insideTread,
      originalTread:     t.originalTread,
      removeAt:          t.removeAt,
      comments:          t.comments,
      inspectionDate:    t.inspectionDate,
      mileageType:       t.mileageType,
      imagesLocation:    t.imagesLocation,
      brandNo:           t.brandNo,
      dispositionId:     _resolveRemovedDispositionId(t),
      dispositionName:   (t.dispositionName != null && t.dispositionName!.isNotEmpty && !t.dispositionName!.toLowerCase().contains('mount'))
          ? t.dispositionName!
          : (action.toLowerCase().contains('remove') ? _dispositionIdToName(_resolveRemovedDispositionId(t)) : 'Mounted'),
      createdBy:         t.createdBy,
      manufacturerName:  t.manufacturerName,
      vehicleId:         t.vehicleId ?? widget.vehicleIdInt,
      vehicleNumber:     t.vehicleNumber ?? widget.vehicleNumber,
      removalReasonId:   t.removalReasonId,
      action:            action,
      isRemoved:         action.toLowerCase().contains('remove'),
    );
  }

  @override
  void initState() {
    super.initState();
    _vehicleIdCtrl.text = widget.vehicleNumber;

    debugPrint(
      '\x1B[35m┌──────────────────────────────────────────────\n'
          '│ 🚚 [VEHICLE-ID TRACE] vehicle.dart initState()\n'
          '│   widget.vehicleId (String)    = ${widget.vehicleId}\n'
          '│   widget.vehicleIdInt (int)    = ${widget.vehicleIdInt}\n'
          '│   widget.vehicleNumber         = ${widget.vehicleNumber}\n'
          '│   widget.pendingInspectionId   = ${widget.pendingInspectionId}\n'
          '└──────────────────────────────────────────────\x1B[0m',
    );
    // 🔄 Live reactive listener: Settings/Preferences change hone par vehicle distance screen turant convert ho
    if (Get.isRegistered<GlobalPrefsState>()) {
      ever(GlobalPrefsState.to.measurement, (_) {
        if (mounted) {
          _syncVehicleDistanceDisplay();
          setState(() {});
        }
      });
      ever(GlobalPrefsState.to.pressure, (_) {
        if (mounted) {
          setState(() {});
        }
      });
    }

    _fetchInspectionData();
  }

  @override
  void dispose() {
    _vehicleIdCtrl.dispose();
    _hoursCtrl.dispose();
    _kmCtrl.dispose();
    _commentsCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchInspectionData() async {
    setState(() => _isLoading = true);
    final bool isSpecificInspection =
        widget.pendingInspectionId != null && widget.pendingInspectionId != 0;
    try {
      final service  = VehicleInspeService();
      final response = await service.getInspectionRecord(widget.vehicleId);

      final modelInstalledTires = response?.model?.installedTires ?? <InstalledTire>[];
      _liveTires = modelInstalledTires;
      final liveTireIds = modelInstalledTires
          .map((lt) => lt.tireId)
          .whereType<int>()
          .where((id) => id > 0)
          .toSet();
      final liveTireSerials = modelInstalledTires
          .map((lt) => (lt.tireSerialNo ?? '').trim().toUpperCase())
          .where((s) => s.isNotEmpty)
          .toSet();

      List<PendingInspectionEntry> pendingForThisVehicle = [];
      List<PendingInspectionTire> allPendingTiresForVehicle = [];
      try {
        final IWSearchController searchCtrl =
        Get.isRegistered<IWSearchController>(tag: 'iw_search')
            ? Get.find<IWSearchController>(tag: 'iw_search')
            : (Get.isRegistered<IWSearchController>()
            ? Get.find<IWSearchController>()
            : Get.put(IWSearchController(), tag: 'iw_search'));
        await searchCtrl.refreshData();
        await _loadSubmitterUnits(widget.pendingInspectionId ?? 0);

        // 🔧 Broad matching: match by vehicleIdInt, string vehicleId, vehicleNumber, or live tyres
        final int effectiveVehicleId = widget.vehicleIdInt > 0
            ? widget.vehicleIdInt
            : (int.tryParse(widget.vehicleId) ?? 0);
        final targetNum = widget.vehicleNumber.trim().toUpperCase();

        final vehicleEntries = searchCtrl.pendingInspections.where((p) {
          // Direct matching by widget.pendingInspectionId
          if (widget.pendingInspectionId != null && widget.pendingInspectionId != 0) {
            if (p.status?.inspectionStatusId == widget.pendingInspectionId ||
                p.vehicle?.inspectionStatusId == widget.pendingInspectionId ||
                p.tire?.inspectionStatusId == widget.pendingInspectionId ||
                p.tiresList.any((t) => t.inspectionStatusId == widget.pendingInspectionId)) {
              return true;
            }
          }

          final vId = p.vehicle?.vehicleId;
          final vNum = p.vehicle?.vehicleNumber?.trim().toUpperCase();
          final tVId = p.tire?.vehicleId;
          final tVNum = p.tire?.vehicleNumber?.trim().toUpperCase();

          if (effectiveVehicleId > 0 && vId == effectiveVehicleId) return true;
          if (targetNum.isNotEmpty && vNum == targetNum) return true;
          if (effectiveVehicleId > 0 && tVId == effectiveVehicleId) return true;
          if (targetNum.isNotEmpty && tVNum == targetNum) return true;
          if (p.tiresList.any((t) =>
          (effectiveVehicleId > 0 && t.vehicleId == effectiveVehicleId) ||
              (targetNum.isNotEmpty && t.vehicleNumber?.trim().toUpperCase() == targetNum))) {
            return true;
          }
          // 🔧 CROSS-MATCH WITH LIVE TIRES: Match any pending entry carrying tyres for this vehicle
          if (p.tiresList.any((t) =>
          (t.tireId != null && t.tireId! > 0 && liveTireIds.contains(t.tireId!)) ||
              (t.tireSerialNo != null && liveTireSerials.contains(t.tireSerialNo!.trim().toUpperCase())))) {
            return true;
          }
          if (p.tire != null) {
            if (p.tire!.tireId != null && p.tire!.tireId! > 0 && liveTireIds.contains(p.tire!.tireId!)) return true;
            if (p.tire!.tireSerialNo != null && liveTireSerials.contains(p.tire!.tireSerialNo!.trim().toUpperCase())) return true;
          }
          return false;
        }).toList();

        List<PendingInspectionEntry> targetEntries = [];
        if (isSpecificInspection) {
          targetEntries = vehicleEntries.where((p) {
            return p.status?.inspectionStatusId == widget.pendingInspectionId ||
                p.vehicle?.inspectionStatusId == widget.pendingInspectionId ||
                p.tire?.inspectionStatusId == widget.pendingInspectionId ||
                p.tiresList.any((t) => t.inspectionStatusId == widget.pendingInspectionId);
          }).toList();
        }

        if (targetEntries.isEmpty) {
          targetEntries = vehicleEntries;
        }

        pendingForThisVehicle = targetEntries;
        if (pendingForThisVehicle.isNotEmpty) {
          _pendingInspectionDate = pendingForThisVehicle.first.status?.createdDate ??
              pendingForThisVehicle.first.tire?.inspectionDate;
        }
        debugPrint('🔎 [BATCH-DEBUG] vehicleId=${widget.vehicleIdInt}, isSpecificInspection=$isSpecificInspection, pendingInspectionId=${widget.pendingInspectionId} -> matched ${pendingForThisVehicle.length}/${vehicleEntries.length} entry/entries for this vehicle');

        // 🛞 Aggregate tyres across ONLY target entries for this vehicle
        final sortedEntries = List<PendingInspectionEntry>.from(pendingForThisVehicle);
        sortedEntries.sort((a, b) {
          final aDate = a.status?.createdDate ?? a.tire?.inspectionDate ?? '';
          final bDate = b.status?.createdDate ?? b.tire?.inspectionDate ?? '';
          return aDate.compareTo(bDate);
        });

        final Map<dynamic, PendingInspectionTire> flatTireMap = {};
        for (final p in sortedEntries) {
          final tiresForEntry = <PendingInspectionTire>[
            if (p.tire != null) p.tire!,
            ...p.tiresList,
          ];
          for (final t in tiresForEntry) {
            // If viewing a specific pending inspection, ignore any tyre explicitly tagged with a different status ID
            if (isSpecificInspection &&
                t.inspectionStatusId != null &&
                t.inspectionStatusId != 0 &&
                t.inspectionStatusId != widget.pendingInspectionId) {
              continue;
            }

            final key = (t.tireId != null && t.tireId != 0)
                ? t.tireId!
                : (t.tireSerialNo?.trim().isNotEmpty == true
                ? t.tireSerialNo!.trim().toUpperCase()
                : (t.wheelPosition?.trim().isNotEmpty == true
                ? t.wheelPosition!.trim().toUpperCase()
                : null));
            if (key != null) {
              final isRemoved = _isTireRemoved(t);
              if (isRemoved) {
                flatTireMap[key] = t;
              } else if (!flatTireMap.containsKey(key) || !_isTireRemoved(flatTireMap[key]!)) {
                flatTireMap[key] = t;
              }
            }
          }
        }

        // 🔧 ACCOUNT-WIDE PENDING CHECK: Scan ALL pending inspections in the account for ANY tyre that matches
        // our live mounted tyres and is marked as removed! Only needed when viewing general vehicle state,
        // NOT when viewing a specific historical inspection snapshot.
        if (!isSpecificInspection) {
          for (final p in searchCtrl.pendingInspections) {
            final allTires = <PendingInspectionTire>[
              if (p.tire != null) p.tire!,
              ...p.tiresList,
            ];
            for (final t in allTires) {
              final matchesTireId = t.tireId != null && t.tireId! > 0 && liveTireIds.contains(t.tireId!);
              final sNo = (t.tireSerialNo ?? '').trim().toUpperCase();
              final matchesSerial = sNo.isNotEmpty && liveTireSerials.contains(sNo);
              if (matchesTireId || matchesSerial) {
                if (_isTireRemoved(t)) {
                  final key = (t.tireId != null && t.tireId != 0)
                      ? t.tireId!
                      : (sNo.isNotEmpty ? sNo : t.wheelPosition?.trim().toUpperCase());
                  if (key != null) {
                    flatTireMap[key] = t;
                    debugPrint('🚨 [PENDING-MATCH] Found removed tyre in pending inspections for this vehicle: key=$key, serial=${t.tireSerialNo}, position=${t.wheelPosition}');
                  }
                }
              }
            }
          }
        }

        allPendingTiresForVehicle = flatTireMap.values.toList();
        debugPrint('🔧 [TIRE-DEBUG] vehicleId=${widget.vehicleIdInt} -> aggregated ${allPendingTiresForVehicle.length} tyre(s) across ${sortedEntries.length} pending entry/entries');

        // Merge local storage pending tires to enrich any missing fields (comments, wear, casing, middle tread)
        try {
          final prefs = await SharedPreferences.getInstance();
          final candidateKeys = [
            if (isSpecificInspection) 'pending_inspection_tires_${widget.vehicleIdInt}_${widget.pendingInspectionId}',
            if (isSpecificInspection && widget.vehicleNumber.isNotEmpty) 'pending_inspection_tires_${widget.vehicleNumber}_${widget.pendingInspectionId}',
            'pending_inspection_tires_${widget.vehicleIdInt}',
            'pending_inspection_tires_${widget.vehicleId}',
            if (widget.vehicleNumber.isNotEmpty) 'pending_inspection_tires_${widget.vehicleNumber}',
          ];
          for (final k in candidateKeys) {
            final raw = prefs.getString(k);
            if (raw != null && raw.isNotEmpty) {
              final decoded = jsonDecode(raw);
              if (decoded is List) {
                for (final item in decoded) {
                  if (item is Map<String, dynamic>) {
                    final localT = PendingInspectionTire.fromJson(
                        MeasurementHelper.localRawTireJsonToCanonical(item));
                    if (isSpecificInspection &&
                        localT.inspectionStatusId != null &&
                        localT.inspectionStatusId != 0 &&
                        localT.inspectionStatusId != widget.pendingInspectionId) {
                      continue;
                    }
                    final key = (localT.tireId != null && localT.tireId != 0)
                        ? localT.tireId!
                        : (localT.tireSerialNo?.trim().isNotEmpty == true
                        ? localT.tireSerialNo!.trim().toUpperCase()
                        : (localT.wheelPosition?.trim().isNotEmpty == true
                        ? localT.wheelPosition!.trim().toUpperCase()
                        : null));
                    if (key != null) {
                      if (!flatTireMap.containsKey(key)) {
                        flatTireMap[key] = localT;
                      } else {
                        final existingT = flatTireMap[key]!;
                        flatTireMap[key] = PendingInspectionTire(
                          tireId: existingT.tireId ?? localT.tireId,
                          tireSerialNo: existingT.tireSerialNo ?? localT.tireSerialNo,
                          wheelPosition: existingT.wheelPosition ?? localT.wheelPosition,
                          manufacturerName: existingT.manufacturerName ?? localT.manufacturerName,
                          sizeName: existingT.sizeName ?? localT.sizeName,
                          typeName: existingT.typeName ?? localT.typeName,
                          currentTreadDepth: (localT.currentTreadDepth != null && localT.currentTreadDepth! > 0)
                              ? localT.currentTreadDepth
                              : _resolveServerTread(existingT.currentTreadDepth),
                          percentageWorn: (localT.percentageWorn ?? existingT.percentageWorn)?.clamp(0.0, 100.0),
                          currentPressure: (localT.currentPressure != null && localT.currentPressure! > 0)
                              ? localT.currentPressure
                              : _resolveServerPressure(existingT.currentPressure),
                          locationId: existingT.locationId ?? localT.locationId,
                          parentAccountId: existingT.parentAccountId ?? localT.parentAccountId,
                          manufacturerId: existingT.manufacturerId ?? localT.manufacturerId,
                          typeId: existingT.typeId ?? localT.typeId,
                          sizeId: existingT.sizeId ?? localT.sizeId,
                          currentHours: (localT.currentHours != null && localT.currentHours! > 0)
                              ? localT.currentHours
                              : existingT.currentHours,
                          currentMiles: (localT.currentMiles != null && localT.currentMiles! > 0)
                              ? localT.currentMiles
                              : _resolveServerDistance(existingT.currentMiles, tireId: existingT.tireId),
                          registeredDate: existingT.registeredDate ?? localT.registeredDate,
                          originalTread: (localT.originalTread != null && localT.originalTread! > 0)
                              ? localT.originalTread
                              : existingT.originalTread,
                          removeAt: (localT.removeAt != null && localT.removeAt! > 0)
                              ? localT.removeAt
                              : existingT.removeAt,
                          outsideTread: (localT.outsideTread != null && localT.outsideTread! > 0)
                              ? localT.outsideTread
                              : _resolveServerTread(existingT.outsideTread),
                          middleTread: (localT.middleTread != null && localT.middleTread! > 0)
                              ? localT.middleTread
                              : _resolveServerTread(existingT.middleTread),
                          insideTread: (localT.insideTread != null && localT.insideTread! > 0)
                              ? localT.insideTread
                              : _resolveServerTread(existingT.insideTread),
                          comments: (existingT.comments != null && existingT.comments!.trim().isNotEmpty)
                              ? existingT.comments
                              : localT.comments,
                          inspectionDate: existingT.inspectionDate ?? localT.inspectionDate,
                          mileageType: existingT.mileageType ?? localT.mileageType,
                          brandNo: (existingT.brandNo != null && existingT.brandNo!.trim().isNotEmpty && existingT.brandNo!.trim().toLowerCase() != 'null')
                              ? existingT.brandNo
                              : localT.brandNo,
                          dispositionId: (localT.dispositionId != null && localT.dispositionId! > 0 && localT.dispositionId != 7 && localT.dispositionId != 8)
                              ? localT.dispositionId
                              : (existingT.dispositionId ?? localT.dispositionId),
                          dispositionName: (localT.dispositionId != null && localT.dispositionId! > 0 && localT.dispositionId != 7 && localT.dispositionId != 8 && localT.dispositionName != null && localT.dispositionName!.isNotEmpty)
                              ? localT.dispositionName
                              : (existingT.dispositionName ?? localT.dispositionName),
                          createdBy: existingT.createdBy ?? localT.createdBy,
                          vehicleId: existingT.vehicleId ?? localT.vehicleId,
                          vehicleNumber: existingT.vehicleNumber ?? localT.vehicleNumber,
                          wearConditionId: (existingT.wearConditionId != null && existingT.wearConditionId != 0 && existingT.wearConditionId != '0' && existingT.wearConditionId.toString().trim().isNotEmpty)
                              ? existingT.wearConditionId
                              : localT.wearConditionId,
                          casingConditionId: (existingT.casingConditionId != null && existingT.casingConditionId != 0 && existingT.casingConditionId != '0' && existingT.casingConditionId.toString().trim().isNotEmpty)
                              ? existingT.casingConditionId
                              : localT.casingConditionId,
                          mountedRimId: existingT.mountedRimId ?? localT.mountedRimId,
                          removalReasonId: (localT.removalReasonId != null && localT.removalReasonId is num && (localT.removalReasonId as num) > 0)
                              ? localT.removalReasonId
                              : (existingT.removalReasonId ?? localT.removalReasonId),
                          imagesLocation: (existingT.imagesLocation != null && existingT.imagesLocation.toString().trim().isNotEmpty)
                              ? existingT.imagesLocation
                              : localT.imagesLocation,
                          action: (localT.action?.toLowerCase().contains('remove') == true)
                              ? localT.action
                              : (existingT.action ?? localT.action),
                          inspectionStatusId: existingT.inspectionStatusId ?? localT.inspectionStatusId,
                          isRemoved: (localT.isRemoved == true || localT.action?.toLowerCase().contains('remove') == true)
                              ? true
                              : (existingT.isRemoved ?? localT.isRemoved),
                        );
                      }
                    }
                  }
                }
              }
            }
          }
          allPendingTiresForVehicle = flatTireMap.values.toList();
        } catch (e) {
          debugPrint('⚠️ [IW-VEHICLE] Error reading local pending tires: $e');
        }

        // Fallback to local storage (payload / Hive) if search controller had no tires
        if (allPendingTiresForVehicle.isEmpty) {
          try {
            final prefs = await SharedPreferences.getInstance();
            final payloadKeys = [
              'pending_inspection_payload_${widget.vehicleIdInt}',
              'pending_inspection_payload_${widget.vehicleId}',
              if (widget.vehicleNumber.isNotEmpty) 'pending_inspection_payload_${widget.vehicleNumber}',
            ];
            for (final k in payloadKeys) {
              final raw = prefs.getString(k);
              if (raw != null && raw.isNotEmpty) {
                final decoded = jsonDecode(raw);
                if (decoded is Map<String, dynamic>) {
                  final tList = decoded['tireList'] ?? decoded['tiresList'] ?? decoded['installedTires'];
                  if (tList is List) {
                    for (final item in tList) {
                      if (item is Map<String, dynamic>) {
                        allPendingTiresForVehicle.add(PendingInspectionTire.fromJson(
                            MeasurementHelper.localRawTireJsonToCanonical(item)));
                      }
                    }
                    if (allPendingTiresForVehicle.isNotEmpty) break;
                  }
                }
              }
            }

            if (allPendingTiresForVehicle.isEmpty) {
              final cached = OfflineHiveService.getInspectionCache(widget.vehicleId) ??
                  OfflineHiveService.getInspectionCache(widget.vehicleIdInt.toString());
              if (cached != null) {
                final decoded = jsonDecode(cached);
                final m = (decoded is Map && decoded['model'] is Map)
                    ? decoded['model'] as Map<String, dynamic>
                    : (decoded is Map<String, dynamic> ? decoded : null);
                if (m != null) {
                  final tList = m['installedTires'] ?? m['tireList'] ?? m['tiresList'];
                  if (tList is List) {
                    for (final item in tList) {
                      if (item is Map<String, dynamic>) {
                        allPendingTiresForVehicle.add(PendingInspectionTire.fromJson(
                            MeasurementHelper.localRawTireJsonToCanonical(item)));
                      }
                    }
                  }
                }
              }
            }
          } catch (e) {
            debugPrint('⚠️ [IW-VEHICLE] Error reading local fallback tires: $e');
          }
        }

        // 🖼️ Extract imagesLocation from vehicle itself (widget, pending vehicle, pending entries)
        final List<String> candidateVehicleImgs = [
          if (widget.imagesLocation != null) widget.imagesLocation.toString(),
          if (_pendingVehicle?.imagesLocation != null) _pendingVehicle!.imagesLocation.toString(),
          for (final p in pendingForThisVehicle)
            if (p.vehicle?.imagesLocation != null) p.vehicle!.imagesLocation.toString(),
        ];
        for (final raw in candidateVehicleImgs) {
          final s = raw.trim();
          if (s.isNotEmpty) {
            for (final path in s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty)) {
              if (!_inspectionImages.contains(path)) {
                _inspectionImages.add(path);
              }
            }
          }
        }

        // 🖼️ Extract local image captures from SharedPreferences
        try {
          final prefs = await SharedPreferences.getInstance();
          final spKeys = [
            'pending_images_${widget.vehicleIdInt}',
            'vehicle_images_${widget.vehicleIdInt}',
            'pending_images_${widget.vehicleId}',
            'vehicle_images_${widget.vehicleId}',
            if (widget.vehicleNumber.isNotEmpty) 'pending_images_${widget.vehicleNumber}',
            if (widget.vehicleNumber.isNotEmpty) 'vehicle_images_${widget.vehicleNumber}',
          ];
          for (final k in spKeys) {
            final list = prefs.getStringList(k);
            if (list != null) {
              for (final raw in list) {
                final p = raw.trim();
                if (p.isNotEmpty && !_inspectionImages.contains(p)) {
                  _inspectionImages.add(p);
                }
              }
            }
            final single = prefs.getString(k);
            if (single != null && single.trim().isNotEmpty) {
              for (final raw in single.split(',')) {
                final p = raw.trim();
                if (p.isNotEmpty && !_inspectionImages.contains(p)) {
                  _inspectionImages.add(p);
                }
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ [IW-VEHICLE] Error reading prefs images: $e');
        }

        // 🖼️ Extract from offline Hive inspection cache if available
        try {
          final cached = OfflineHiveService.getInspectionCache(widget.vehicleId) ??
              OfflineHiveService.getInspectionCache(widget.vehicleIdInt.toString());
          if (cached != null) {
            final decoded = jsonDecode(cached) as Map<String, dynamic>;
            final m = (decoded['model'] as Map<String, dynamic>?) ?? decoded;
            final loc = m['imagesLocation']?.toString().trim() ?? '';
            if (loc.isNotEmpty) {
              for (final p in loc.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty)) {
                if (!_inspectionImages.contains(p)) {
                  _inspectionImages.add(p);
                }
              }
            }
          }
        } catch (_) {}
      } catch (e) {
        debugPrint('⚠️ [IW-VEHICLE] IWSearchController not found -> $e');
      }

      if (_pendingInspectionDate == null || _pendingInspectionDate!.isEmpty) {
        try {
          final cached = OfflineHiveService.getInspectionCache(widget.vehicleId) ??
              OfflineHiveService.getInspectionCache(widget.vehicleIdInt.toString());
          if (cached != null) {
            final decoded = jsonDecode(cached) as Map<String, dynamic>;
            final m = (decoded['model'] as Map<String, dynamic>?) ?? decoded;
            final d = m['inspectionDate'] ?? m['createdDate'];
            if (d != null && d.toString().trim().isNotEmpty) {
              _pendingInspectionDate = d.toString().trim();
            }
          }
        } catch (_) {}
      }

      debugPrint('🎯 [IMAGE-DEBUG] Total unique inspection images loaded for this vehicle: ${_inspectionImages.length} -> $_inspectionImages');

      if (response != null && response.didError == false && response.model != null) {
        final model = response.model!;
        final resolvedAxle = (model.axleConfig?.trim().isNotEmpty == true)
            ? model.axleConfig!
            : _resolveFromAxleConfigId(model.axleConfigId ?? 1);

        final liveTires = model.installedTires ?? [];
        _liveTires = liveTires;
        _allPendingTiresForVehicle = allPendingTiresForVehicle;
        _axleConfig = resolvedAxle;

        if (pendingForThisVehicle.isNotEmpty || allPendingTiresForVehicle.isNotEmpty) {
          final removedPending = allPendingTiresForVehicle
              .where((t) => _isTireRemoved(t) ||
              (t.wheelPosition ?? '').trim().isEmpty ||
              t.wheelPosition?.trim() == '0' ||
              t.wheelPosition?.trim() == '-')
              .toList();
          final activePending = allPendingTiresForVehicle
              .where((t) => !_isTireRemoved(t) &&
              (t.wheelPosition ?? '').trim().isNotEmpty &&
              t.wheelPosition?.trim() != '0' &&
              t.wheelPosition?.trim() != '-')
              .toList();

          final removedIds = removedPending.map((t) => t.tireId).whereType<int>().toSet();
          final removedPositions = removedPending
              .map((t) => (t.wheelPosition ?? '').trim().toUpperCase())
              .where((p) => p.isNotEmpty)
              .toSet();
          final removedSerials = removedPending
              .map((t) => (t.tireSerialNo ?? '').trim().toUpperCase())
              .where((s) => s.isNotEmpty)
              .toSet();

          // 🛞 1. Collect all active pending tyre IDs and Serials
          final activePendingTireIds = activePending
              .map((t) => t.tireId)
              .whereType<int>()
              .where((id) => id > 0)
              .toSet();
          final activePendingTireSerials = activePending
              .map((t) => (t.tireSerialNo ?? '').trim().toUpperCase())
              .where((s) => s.isNotEmpty)
              .toSet();

          // 🛞 2. Cross-check live tyres against active pending inspection tyres:
          // In a pending inspection, activePending represents the true inspected state of the vehicle.
          // If a tyre was in liveTires (pre-inspection database), but is NOT present in activePending,
          // it was UNMOUNTED/REMOVED during this inspection!
          for (final lt in liveTires) {
            final ltId = lt.tireId ?? 0;
            final ltSerial = (lt.tireSerialNo ?? '').trim().toUpperCase();
            final ltPos = (lt.wheelPosition ?? '').trim().toUpperCase();

            final bool isStillActive = (ltId > 0 && activePendingTireIds.contains(ltId)) ||
                (ltSerial.isNotEmpty && activePendingTireSerials.contains(ltSerial));

            final bool recentlyRemovedInHive = !isSpecificInspection && ltId > 0 && OfflineHiveService.isTireRecentlyRemoved(ltId);

            if (!isStillActive || recentlyRemovedInHive) {
              if (ltId > 0) removedIds.add(ltId);
              if (ltSerial.isNotEmpty) removedSerials.add(ltSerial);
              if (ltPos.isNotEmpty) removedPositions.add(ltPos);

              if (!removedPending.any((t) =>
              (t.tireId != null && t.tireId! > 0 && t.tireId == ltId) ||
                  (ltSerial.isNotEmpty && (t.tireSerialNo ?? '').trim().toUpperCase() == ltSerial))) {
                removedPending.add(_mapInstalledToPending(lt, action: 'Remove'));
                debugPrint('🚨 [IW-VEHICLE] Live tyre unmounted in pending inspection -> marked as removed: id=$ltId, serial=$ltSerial, pos=$ltPos');
              }
            }
          }

          _pendingRemovedTires.assignAll(removedPending);

          // 🛞 3. Start with live installed tires from server, excluding any that were marked as removed
          final List<InstalledTire> currentInstalled = liveTires.where((lt) {
            if (lt.tireId != null && lt.tireId! > 0 && removedIds.contains(lt.tireId)) {
              return false;
            }
            final sNo = (lt.tireSerialNo ?? '').trim().toUpperCase();
            if (sNo.isNotEmpty && removedSerials.contains(sNo)) {
              return false;
            }
            final pos = (lt.wheelPosition ?? '').trim().toUpperCase();
            if (pos.isNotEmpty && removedPositions.contains(pos)) {
              return false;
            }
            return true;
          }).toList();

          // 🛞 4. Merge or update active pending tires
          for (final pt in activePending) {
            if (pt.tireId != null && pt.tireId! > 0 && removedIds.contains(pt.tireId)) {
              continue;
            }
            final ptSerial = (pt.tireSerialNo ?? '').trim().toUpperCase();
            if (ptSerial.isNotEmpty && removedSerials.contains(ptSerial)) {
              continue;
            }
            final ptPos = (pt.wheelPosition ?? '').trim().toUpperCase();
            final idx = currentInstalled.indexWhere((it) =>
            (pt.tireId != null && pt.tireId != 0 && it.tireId == pt.tireId) ||
                (ptPos.isNotEmpty && (it.wheelPosition ?? '').trim().toUpperCase() == ptPos)
            );
            final mapped = _mapPendingToInstalled(pt);
            if (idx != -1) {
              currentInstalled[idx] = mapped;
            } else {
              currentInstalled.add(mapped);
            }
          }

          final pendingVehicle = pendingForThisVehicle.isNotEmpty ? pendingForThisVehicle.first.vehicle : null;
          _pendingVehicle = pendingVehicle;

          widget.newTires.assignAll(currentInstalled);

          _hoursCtrl.text = (pendingVehicle?.currentHours?.toInt() ??
              model.lastRecordedHours?.toInt() ??
              0)
              .toString();

          num? kmVal = pendingVehicle?.currentMiles ?? model.lastRecordedMiles;
          String? payloadDistUnit;
          try {
            final prefs = await SharedPreferences.getInstance();
            final vIdKey = widget.vehicleId;
            final rawPayload = prefs.getString('pending_inspection_payload_$vIdKey') ??
                prefs.getString('pending_inspection_payload_${widget.vehicleIdInt}') ??
                (widget.vehicleNumber.isNotEmpty ? prefs.getString('pending_inspection_payload_${widget.vehicleNumber}') : null);
            if (rawPayload != null && rawPayload.isNotEmpty) {
              final Map<String, dynamic> decoded = jsonDecode(rawPayload);
              final vList = decoded['vehicleList'] as List?;
              if (vList != null && vList.isNotEmpty && vList.first is Map) {
                final vMap = vList.first as Map<String, dynamic>;
                final km = vMap['currentMiles'];
                if (km != null) {
                  final d = num.tryParse(km.toString());
                  if (d != null && d > 0) kmVal = d;
                }
                final pdu = vMap['distUnit']?.toString().trim();
                if (pdu != null && pdu.isNotEmpty) payloadDistUnit = pdu;
              }
            }
          } catch (_) {}

          final num finalKm = (kmVal != null && kmVal > 0) ? kmVal : 0;
          _canonicalKm = finalKm.toDouble();
          _canonicalDistanceUnit = (payloadDistUnit != null && payloadDistUnit.isNotEmpty)
              ? payloadDistUnit
              : MeasurementHelper.distanceLabel;
          _syncVehicleDistanceDisplay();

          _commentsCtrl.text =
              pendingVehicle?.severityComments ?? model.comments ?? '';
        } else {
          final List<PendingInspectionTire> localRemoved = [];
          final List<InstalledTire> currentInstalled = [];
          for (final lt in liveTires) {
            if (lt.tireId != null && lt.tireId! > 0 && OfflineHiveService.isTireRecentlyRemoved(lt.tireId!)) {
              localRemoved.add(_mapInstalledToPending(lt, action: 'Remove'));
            } else {
              currentInstalled.add(_resolveLiveTireForDisplay(lt));
            }
          }
          _pendingRemovedTires.assignAll(localRemoved);
          widget.newTires.assignAll(currentInstalled);
          _hoursCtrl.text    = (model.lastRecordedHours?.toInt() ?? 0).toString();

          final num? kmVal = model.lastRecordedMiles;
          String srcUnit = HivePref.get<String>('vehicle_dist_unit_${widget.vehicleIdInt}') ?? '';
          if (srcUnit.isEmpty && widget.vehicleNumber.isNotEmpty) {
            srcUnit = HivePref.get<String>('vehicle_dist_unit_${widget.vehicleNumber}') ?? '';
          }
          if (srcUnit.isEmpty) {
            final mt = model.vehicleMileageType?.toString().trim().toLowerCase() ?? '';
            srcUnit = (mt == 'miles') ? 'Miles' : 'KM';
          }
          _canonicalKm = (kmVal != null && kmVal > 0) ? kmVal.toDouble() : 0.0;
          _canonicalDistanceUnit = srcUnit;
          _syncVehicleDistanceDisplay();
          _commentsCtrl.text = model.comments ?? '';
        }
      } else {
        // 🚚 Fallback for newly created / draft vehicles or offline vehicles without live server records
        _liveTires = [];
        _allPendingTiresForVehicle = allPendingTiresForVehicle;

        PendingInspectionVehicle? pendingVehicle;
        String? localAxleConfig;
        if (pendingForThisVehicle.isNotEmpty && pendingForThisVehicle.first.vehicle != null) {
          pendingVehicle = pendingForThisVehicle.first.vehicle;
          if (pendingVehicle?.axleConfig != null && pendingVehicle!.axleConfig!.trim().isNotEmpty) {
            localAxleConfig = pendingVehicle.axleConfig;
          }
        }
        if (pendingVehicle == null) {
          final offlineVeh = OfflineHiveService.getVehicleById(widget.vehicleIdInt);
          if (offlineVeh != null) {
            localAxleConfig = offlineVeh.axleConfig;
            pendingVehicle = PendingInspectionVehicle(
              vehicleId: offlineVeh.vehicleId,
              vehicleNumber: offlineVeh.vehicleNumber,
              axleConfigId: offlineVeh.axleConfigId,
              currentHours: offlineVeh.currentHours,
              currentMiles: offlineVeh.currentMiles,
              locationId: offlineVeh.locationId,
              parentAccountId: offlineVeh.parentAccountId,
            );
          }
        }
        if (pendingVehicle == null && widget.vehicleNumber.isNotEmpty) {
          final allVehs = OfflineHiveService.getAllVehicles();
          for (final ov in allVehs) {
            if (ov.vehicleNumber.trim().toUpperCase() == widget.vehicleNumber.trim().toUpperCase()) {
              localAxleConfig = ov.axleConfig;
              pendingVehicle = PendingInspectionVehicle(
                vehicleId: ov.vehicleId,
                vehicleNumber: ov.vehicleNumber,
                axleConfigId: ov.axleConfigId,
                currentHours: ov.currentHours,
                currentMiles: ov.currentMiles,
                locationId: ov.locationId,
                parentAccountId: ov.parentAccountId,
              );
              break;
            }
          }
        }
        if (pendingVehicle == null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            final raw = prefs.getString('pending_vehicle_create_${widget.vehicleIdInt}') ??
                (widget.vehicleNumber.isNotEmpty ? prefs.getString('pending_vehicle_create_${widget.vehicleNumber}') : null);
            if (raw != null && raw.isNotEmpty) {
              final m = jsonDecode(raw) as Map<String, dynamic>;
              localAxleConfig = m['axleConfig']?.toString();
              pendingVehicle = PendingInspectionVehicle(
                vehicleId: widget.vehicleIdInt,
                vehicleNumber: m['vehicleNumber']?.toString() ?? widget.vehicleNumber,
                axleConfigId: m['axleConfigId'] is int ? m['axleConfigId'] : int.tryParse(m['axleConfigId']?.toString() ?? ''),
                currentHours: (m['currentHours'] is num) ? (m['currentHours'] as num).toDouble() : double.tryParse(m['currentHours']?.toString() ?? ''),
                currentMiles: (m['currentMiles'] is num) ? (m['currentMiles'] as num).toDouble() : double.tryParse(m['currentMiles']?.toString() ?? ''),
                locationId: m['locationId'] is int ? m['locationId'] : int.tryParse(m['locationId']?.toString() ?? ''),
                parentAccountId: m['parentAccountId'] is int ? m['parentAccountId'] : int.tryParse(m['parentAccountId']?.toString() ?? ''),
                imagesLocation: m['imagesLocation']?.toString(),
              );
            }
          } catch (_) {}
        }
        _pendingVehicle = pendingVehicle;

        final resolvedAxle = (localAxleConfig?.trim().isNotEmpty == true)
            ? localAxleConfig!
            : (pendingVehicle?.axleConfigId != null
            ? _resolveFromAxleConfigId(pendingVehicle!.axleConfigId!)
            : (widget.axleConfig.isNotEmpty ? widget.axleConfig : '22'));
        _axleConfig = resolvedAxle;

        final removedPending = allPendingTiresForVehicle
            .where((t) => _isTireRemoved(t) ||
            (t.wheelPosition ?? '').trim().isEmpty ||
            t.wheelPosition?.trim() == '0' ||
            t.wheelPosition?.trim() == '-')
            .toList();
        final activePending = allPendingTiresForVehicle
            .where((t) => !_isTireRemoved(t) &&
            (t.wheelPosition ?? '').trim().isNotEmpty &&
            t.wheelPosition?.trim() != '0' &&
            t.wheelPosition?.trim() != '-')
            .toList();

        final removedIds = removedPending.map((t) => t.tireId).whereType<int>().toSet();
        final removedPositions = removedPending
            .map((t) => (t.wheelPosition ?? '').trim().toUpperCase())
            .where((p) => p.isNotEmpty)
            .toSet();
        final removedSerials = removedPending
            .map((t) => (t.tireSerialNo ?? '').trim().toUpperCase())
            .where((s) => s.isNotEmpty)
            .toSet();

        final activePendingTireIds = activePending
            .map((t) => t.tireId)
            .whereType<int>()
            .where((id) => id > 0)
            .toSet();
        final activePendingTireSerials = activePending
            .map((t) => (t.tireSerialNo ?? '').trim().toUpperCase())
            .where((s) => s.isNotEmpty)
            .toSet();

        for (final ot in widget.oldTires) {
          final otId = ot.tireId ?? 0;
          final otSerial = (ot.tireSerialNo ?? '').trim().toUpperCase();
          final otPos = (ot.wheelPosition ?? '').trim().toUpperCase();

          final bool isStillActive = (otId > 0 && activePendingTireIds.contains(otId)) ||
              (otSerial.isNotEmpty && activePendingTireSerials.contains(otSerial));

          final bool recentlyRemovedInHive = !isSpecificInspection && otId > 0 && OfflineHiveService.isTireRecentlyRemoved(otId);

          if (!isStillActive || recentlyRemovedInHive) {
            if (otId > 0) removedIds.add(otId);
            if (otPos.isNotEmpty) removedPositions.add(otPos);
            if (otSerial.isNotEmpty) removedSerials.add(otSerial);
            if (!removedPending.any((t) =>
            (t.tireId != null && t.tireId! > 0 && t.tireId == otId) ||
                (otSerial.isNotEmpty && (t.tireSerialNo ?? '').trim().toUpperCase() == otSerial))) {
              removedPending.add(_mapInstalledToPending(ot, action: 'Remove'));
            }
          }
        }

        _pendingRemovedTires.assignAll(removedPending);

        final List<InstalledTire> currentInstalled = List<InstalledTire>.from(widget.oldTires).where((lt) {
          if (lt.tireId != null && lt.tireId! > 0 && removedIds.contains(lt.tireId)) {
            return false;
          }
          final sNo = (lt.tireSerialNo ?? '').trim().toUpperCase();
          if (sNo.isNotEmpty && removedSerials.contains(sNo)) {
            return false;
          }
          final pos = (lt.wheelPosition ?? '').trim().toUpperCase();
          if (pos.isNotEmpty && removedPositions.contains(pos)) {
            return false;
          }
          return true;
        }).toList();

        for (final pt in activePending) {
          if (pt.tireId != null && pt.tireId! > 0 && removedIds.contains(pt.tireId)) {
            continue;
          }
          final ptSerial = (pt.tireSerialNo ?? '').trim().toUpperCase();
          if (ptSerial.isNotEmpty && removedSerials.contains(ptSerial)) {
            continue;
          }
          final ptPos = (pt.wheelPosition ?? '').trim().toUpperCase();
          final idx = currentInstalled.indexWhere((it) =>
          (pt.tireId != null && pt.tireId != 0 && it.tireId == pt.tireId) ||
              (ptPos.isNotEmpty && (it.wheelPosition ?? '').trim().toUpperCase() == ptPos)
          );
          final mapped = _mapPendingToInstalled(pt);
          if (idx != -1) {
            currentInstalled[idx] = mapped;
          } else {
            currentInstalled.add(mapped);
          }
        }

        widget.newTires.assignAll(currentInstalled);

        final num? hoursVal = pendingVehicle?.currentHours;
        _hoursCtrl.text = hoursVal != null ? hoursVal.toInt().toString() : '0';

        num? kmVal = pendingVehicle?.currentMiles;
        String? payloadDistUnit;
        try {
          final prefs = await SharedPreferences.getInstance();
          final vIdKey = widget.vehicleId;
          final rawPayload = prefs.getString('pending_inspection_payload_$vIdKey') ??
              prefs.getString('pending_inspection_payload_${widget.vehicleIdInt}') ??
              (widget.vehicleNumber.isNotEmpty ? prefs.getString('pending_inspection_payload_${widget.vehicleNumber}') : null);
          if (rawPayload != null && rawPayload.isNotEmpty) {
            final Map<String, dynamic> decoded = jsonDecode(rawPayload);
            final vList = decoded['vehicleList'] as List?;
            if (vList != null && vList.isNotEmpty && vList.first is Map) {
              final vMap = vList.first as Map<String, dynamic>;
              final km = vMap['currentMiles'];
              if (km != null) {
                final d = num.tryParse(km.toString());
                if (d != null && d > 0) kmVal = d;
              }
              final pdu = vMap['distUnit']?.toString().trim();
              if (pdu != null && pdu.isNotEmpty) payloadDistUnit = pdu;
            }
          }
        } catch (_) {}

        final num finalKm = (kmVal != null && kmVal > 0) ? kmVal : 0;
        _canonicalKm = finalKm.toDouble();
        _canonicalDistanceUnit = (payloadDistUnit != null && payloadDistUnit.isNotEmpty)
            ? payloadDistUnit
            : MeasurementHelper.distanceLabel;
        _syncVehicleDistanceDisplay();
        _syncVehicleDistanceDisplay();

        _commentsCtrl.text = pendingVehicle?.severityComments ?? '';
      }
    } catch (e) {
      debugPrint('⚠️ _fetchInspectionData error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _resolveFromAxleConfigId(int axleConfigId) {
    switch (axleConfigId) {
      case 1: return "22";
      case 2: return "222";
      case 3: return "2222";
      case 4: return "22222";
      case 5: return "24";
      case 6: return "224";
      case 7: return "2";
      case 8: return "242";
      case 9: return "24";
      default: return "22";
    }
  }

  Future<String> _resolveLoggedInUserName() async {
    try {
      final profileName = await SecureStorage.getUserProfileName();
      if (profileName != null && profileName.trim().isNotEmpty) {
        return profileName.trim();
      }
      final username = await SecureStorage.getUserName();
      if (username != null && username.trim().isNotEmpty) {
        return username.trim();
      }
    } catch (e) {
      debugPrint('⚠️ [IW-VEHICLE] _resolveLoggedInUserName error -> $e');
    }
    return 'Unknown User';
  }

  // 🔑 Secure resolution of exact InspectionStatusId
  int _resolveInspectionStatusId() {
    if (widget.pendingInspectionId != null && widget.pendingInspectionId! > 0) {
      return widget.pendingInspectionId!;
    }

    try {
      final c = Get.find<IWSearchController>(tag: 'iw_search');
      for (final p in c.pendingInspections) {
        final vId = p.vehicle?.vehicleId;
        final vNum = p.vehicle?.vehicleNumber?.trim().toUpperCase();
        final targetNum = widget.vehicleNumber.trim().toUpperCase();
        final match = (vId != null && vId == widget.vehicleIdInt) ||
            (targetNum.isNotEmpty && vNum == targetNum);
        if (match) {
          if (p.status?.inspectionStatusId != null && p.status!.inspectionStatusId! > 0) {
            return p.status!.inspectionStatusId!;
          }
        }
      }
    } catch (_) {}

    // 🔧 FIX: pehle yahan vehicleId ko InspectionStatusId bana ke bhej diya jata tha
    // -> server par aisa pending row hota hi nahi -> 500 (DbUpdateConcurrencyException).
    // Ab unresolved hone par 0 return hota hai aur caller error dikhata hai.
    return 0;
  }

  // 🔒 Approve/Reject gate: EMTUSER ke liye sirf tab allowed jab workflow
  // enabled AND isApprover dono true hon. Koi bhi aur role ho, uske liye
  // hamesha allowed hai (koi extra condition nahi).
  Future<bool> _canPerformApprovalAction() async {
    final role = auth.userRole.value.trim().toUpperCase();
    if (role != 'EMTUSER') return true;

    final bool isWorkflowEnabled =
    await SecureStorage.getApprovalWorkflowEnabled();
    if (!isWorkflowEnabled) return false;

    return auth.isApprover.value;
  }

  Future<void> _onApprove() async {
    final a = ApprovalLocalizations.of(Get.context ?? context);
    final bool allowed = await _canPerformApprovalAction();
    if (!allowed) {
      Get.snackbar(
        a.notAllowed,
        a.notAllowedPermission,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return;
    }

    final int resolvedInspectionId = _resolveInspectionStatusId();

    if (resolvedInspectionId <= 0 && widget.vehicleIdInt > 0) {
      Get.snackbar(
        a.error,
        a.invalidInspectionId,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return;
    }

    final remark = await _showRemarkDialog(
      isApprove: true,
      title: a.approveInspection,
      hint: a.enterRemarkApproval,
      accentColor: Colors.green,
      confirmLabel: a.approve,
    );
    if (remark == null) return;

    setState(() => _isSubmitting = true);

    try {
      final approverName = await _resolveLoggedInUserName();
      await _loadSubmitterUnits(resolvedInspectionId);
      int resolvedVehicleIdInt = widget.vehicleIdInt;

      // 🔧 FIX: agar createVehicle sync ho chuka hai to uska real id already prefs me hai.
      // Pehle yahan dobara server par vehicle create ho jata tha (duplicate vehicle number
      // -> 500, ya naya vehicle id -> galat inspection par approve).
      if (resolvedVehicleIdInt <= 0) {
        final mappedPrefs = await SharedPreferences.getInstance();
        final mappedReal = mappedPrefs.getInt('vehicle_real_id_$resolvedVehicleIdInt');
        if (mappedReal != null && mappedReal > 0) {
          debugPrint('♻️ [IW-VEHICLE] Reusing already-synced real vehicleId $mappedReal for temp id $resolvedVehicleIdInt (no duplicate create)');
          resolvedVehicleIdInt = mappedReal;
        }
      }

      // 🔑 Offline-created tyres ke temp (negative) ids -> real ids
      final Map<int, int> tempTireMap = {};
      {
        final tp = await SharedPreferences.getInstance();
        for (final k in tp.getKeys()) {
          if (!k.startsWith('tyre_real_id_')) continue;
          final tmp = int.tryParse(k.substring('tyre_real_id_'.length));
          final real = tp.getInt(k);
          if (tmp != null && real != null && real > 0) tempTireMap[tmp] = real;
        }
      }
      int? realTireId(int? id) => (id != null && id < 0) ? tempTireMap[id] : id;

      // 🚚 1. IF DRAFT VEHICLE (vehicleIdInt <= 0): Create vehicle on live server first
      if (resolvedVehicleIdInt <= 0) {
        debugPrint('🚚 [IW-VEHICLE] Vehicle ID is $resolvedVehicleIdInt (draft/pending). Creating on server...');
        final prefs = await SharedPreferences.getInstance();
        final storedPayload = prefs.getString('pending_vehicle_create_$resolvedVehicleIdInt') ??
            (widget.vehicleNumber.isNotEmpty ? prefs.getString('pending_vehicle_create_${widget.vehicleNumber}') : null);
        VehicleModel? vehToCreate;
        if (storedPayload != null && storedPayload.isNotEmpty) {
          try {
            vehToCreate = VehicleModel.fromJson(jsonDecode(storedPayload));
          } catch (e) {
            debugPrint('⚠️ [IW-VEHICLE] Failed to parse pending_vehicle_create payload: $e');
          }
        }
        if (vehToCreate == null) {
          final offlineVeh = OfflineHiveService.getVehicleById(resolvedVehicleIdInt);
          if (offlineVeh != null) {
            vehToCreate = VehicleModel(
              vehicleNumber: offlineVeh.vehicleNumber,
              manufacturerId: offlineVeh.manufacturerId,
              manufacturer: offlineVeh.manufacturerName,
              modelId: offlineVeh.modelId,
              modelName: offlineVeh.modelName,
              typeId: null,
              typeName: offlineVeh.typeName,
              tireSizeId: offlineVeh.tireSizeId,
              tireSize: offlineVeh.tireSizeName,
              axleConfig: offlineVeh.axleConfig,
              axleConfigId: offlineVeh.axleConfigId,
              currentHours: double.tryParse(_hoursCtrl.text) ?? offlineVeh.currentHours ?? 0,
              currentMiles: _canonicalKm ?? offlineVeh.currentMiles ?? 0,
              locationId: offlineVeh.locationId,
              parentAccountId: offlineVeh.parentAccountId,
              recommendedPressure: offlineVeh.recommendedPressure,
              removalTread: offlineVeh.removalTread,
              severityComments: _commentsCtrl.text,
              registeredDate: DateTime.now(),
              createdDate: DateTime.now(),
            );
          }
        }
        if (vehToCreate == null && widget.vehicleNumber.isNotEmpty) {
          final allVehs = OfflineHiveService.getAllVehicles();
          for (final ov in allVehs) {
            if (ov.vehicleNumber.trim().toUpperCase() == widget.vehicleNumber.trim().toUpperCase()) {
              vehToCreate = VehicleModel(
                vehicleNumber: ov.vehicleNumber,
                manufacturerId: ov.manufacturerId,
                manufacturer: ov.manufacturerName,
                modelId: ov.modelId,
                modelName: ov.modelName,
                typeId: null,
                typeName: ov.typeName,
                tireSizeId: ov.tireSizeId,
                tireSize: ov.tireSizeName,
                axleConfig: ov.axleConfig,
                axleConfigId: ov.axleConfigId,
                currentHours: double.tryParse(_hoursCtrl.text) ?? ov.currentHours ?? 0,
                currentMiles: _canonicalKm ?? ov.currentMiles ?? 0,
                locationId: ov.locationId,
                parentAccountId: ov.parentAccountId,
                recommendedPressure: ov.recommendedPressure,
                removalTread: ov.removalTread,
                severityComments: _commentsCtrl.text,
                registeredDate: DateTime.now(),
                createdDate: DateTime.now(),
              );
              break;
            }
          }
        }

        if (vehToCreate != null) {
          final createService = VehicleService();
          final realId = await createService.createVehicleOnServer(vehToCreate);
          if (realId != null && realId > 0) {
            debugPrint('✅ [IW-VEHICLE] Server created vehicle with real ID: $realId');
            await OfflineHiveService.replaceVehicleTempId(
              tempId: resolvedVehicleIdInt,
              realId: realId,
            );
            await prefs.setInt('vehicle_real_id_$resolvedVehicleIdInt', realId);
            resolvedVehicleIdInt = realId;
          } else {
            throw Exception('Failed to create vehicle on server');
          }
        }
      }

      // 🚚 2. IF PENDING VEHICLE UPDATE: Apply update to server
      final prefs = await SharedPreferences.getInstance();
      final pendingUpdateJson = prefs.getString('pending_vehicle_update_$resolvedVehicleIdInt');
      if (pendingUpdateJson != null && pendingUpdateJson.isNotEmpty) {
        try {
          final updateVeh = VehicleModel.fromJson(jsonDecode(pendingUpdateJson));
          final updateService = UpdateVehicleService();
          await updateService.updateVehicle(updateVeh);
          await prefs.remove('pending_vehicle_update_$resolvedVehicleIdInt');
          debugPrint('✅ [IW-VEHICLE] Applied pending vehicle update on server for $resolvedVehicleIdInt');
        } catch (e) {
          debugPrint('⚠️ [IW-VEHICLE] Error applying pending vehicle update: $e');
        }
      }

      // 🔑 3. IDENTIFY ANY NEWLY INSTALLED TYRES THAT MUST BE MOUNTED TO THE VEHICLE ON SERVER
      final newlyInstalledTires = widget.newTires.where((t) {
        final rid = realTireId(t.tireId);
        if (rid == null || rid <= 0) return false;
        final wasAlreadyLive = _liveTires.any((lt) => lt.tireId == rid);
        final isInventory = (t.dispositionId == 7);
        return !wasAlreadyLive || isInventory || widget.vehicleIdInt <= 0;
      }).toList();

      if (newlyInstalledTires.isNotEmpty) {
        debugPrint('🚚 [IW-VEHICLE] Mounting ${newlyInstalledTires.length} newly installed tyre(s) to server database...');
        final installService = InstallTyreService();
        final nowIso = DateTime.now().toIso8601String();
        for (final t in newlyInstalledTires) {
          try {
            final installPayload = <String, dynamic>{
              'action': 'Install',
              'inspectionDate': nowIso,
              'wheelPosition': t.wheelPosition?.trim().toUpperCase(),
              'tireId': realTireId(t.tireId) ?? t.tireId,
              'currentHours': t.currentHours ?? double.tryParse(_hoursCtrl.text) ?? 0.0,
              'currentTreadDepth': t.currentTreadDepth ?? t.middleTread ?? 0.0,
              'currentMiles': t.currentMiles ?? _canonicalKm ?? 0.0,
              'tireSerialNo': t.tireSerialNo ?? '',
              'vehicleId': resolvedVehicleIdInt,
              'locationId': t.locationId ?? _pendingVehicle?.locationId ?? 0,
              'parentAccountId': t.parentAccountId ?? _pendingVehicle?.parentAccountId ?? 0,
              'currentPressure': t.currentPressure ?? 0.0,
              'rimDispositionId': 0,
              'pressureType': 'C',
              'casingConditionId': (t.casingConditionId is int && t.casingConditionId > 0) ? t.casingConditionId : null,
              'wearConditionId': (t.wearConditionId is int && t.wearConditionId > 0) ? t.wearConditionId : null,
              'brandNo': t.brandNo ?? '',
              'comments': t.comments ?? '',
              'outsideTread': t.outsideTread ?? t.currentTreadDepth ?? 0.0,
              'insideTread': t.insideTread ?? t.currentTreadDepth ?? 0.0,
              'middleTread': t.middleTread ?? t.currentTreadDepth ?? 0.0,
              'dispositionId': 2,
              'percentageWorn': (t.percentageWorn ?? 0.0).clamp(0.0, 100.0),
              'isOfflineTyre': false,
            };
            await installService.submitInspection(_canonToRawMap(installPayload));
            debugPrint('✅ [IW-VEHICLE] InstallTire succeeded for tyre ${t.tireId} at ${t.wheelPosition}');
          } catch (e) {
            debugPrint('⚠️ [IW-VEHICLE] InstallTire exception for tyre ${t.tireId}: $e');
          }
        }
      }

      // 🔑 4. IDENTIFY ANY REMOVED TYRES THAT MUST BE UNMOUNTED FROM THE VEHICLE ON SERVER
      final pendingRemovedTireIds = _allPendingTiresForVehicle
          .where((t) => _isTireRemoved(t))
          .map((t) => t.tireId)
          .whereType<int>()
          .toSet();

      final List<InstalledTire> removedTires = [];
      for (final lt in _liveTires) {
        if (lt.tireId == null || lt.tireId! <= 0) continue;
        final notInNewTires = !widget.newTires.any((nt) => nt.tireId == lt.tireId);
        final explicitlyRemoved = pendingRemovedTireIds.contains(lt.tireId);
        if (notInNewTires || explicitlyRemoved) {
          final pendingMatch = _pendingRemovedTires.firstWhereOrNull((p) => p.tireId == lt.tireId) ??
              _allPendingTiresForVehicle.firstWhereOrNull((p) => p.tireId == lt.tireId && _isTireRemoved(p));

          if (pendingMatch != null) {
            final mapped = _mapPendingToInstalled(pendingMatch);
            mapped.wheelPosition = (mapped.wheelPosition != null && mapped.wheelPosition!.isNotEmpty)
                ? mapped.wheelPosition
                : lt.wheelPosition;
            mapped.tireSerialNo = (mapped.tireSerialNo != null && mapped.tireSerialNo!.isNotEmpty)
                ? mapped.tireSerialNo
                : lt.tireSerialNo;
            removedTires.add(mapped);
          } else {
            removedTires.add(lt);
          }
        }
      }

      for (final pt in _pendingRemovedTires) {
        if (pt.tireId != null && pt.tireId! > 0) {
          if (!removedTires.any((rt) => rt.tireId == pt.tireId)) {
            removedTires.add(_mapPendingToInstalled(pt));
          }
        }
      }

      if (removedTires.isNotEmpty) {
        debugPrint('🚚 [IW-VEHICLE] Removing ${removedTires.length} tyre(s) on server database...');
        final removeService = RemoveTyreService();
        final nowIso = DateTime.now().toIso8601String();
        for (final t in removedTires) {
          try {
            final int resolvedDispId = _resolveRemovedDispositionId(t);
            final String resolvedDispName = _dispositionIdToName(resolvedDispId);
            t.dispositionId = resolvedDispId;
            t.dispositionName = resolvedDispName;
            final int resolvedRemovalReason = (t.removalReasonId != null && t.removalReasonId is num && (t.removalReasonId as num) > 0)
                ? (t.removalReasonId as num).toInt()
                : (int.tryParse(t.removalReasonId?.toString() ?? '') ?? 1);
            t.removalReasonId = resolvedRemovalReason;

            final removePayload = <String, dynamic>{
              'action': 'Remove',
              'inspectionDate': nowIso,
              'wheelPosition': t.wheelPosition?.trim().toUpperCase(),
              'tireId': t.tireId,
              'currentHours': t.currentHours ?? double.tryParse(_hoursCtrl.text) ?? 0.0,
              'currentTreadDepth': t.currentTreadDepth ?? t.middleTread ?? 0.0,
              'currentMiles': t.currentMiles ?? _canonicalKm ?? 0.0,
              'tireSerialNo': t.tireSerialNo ?? '',
              'vehicleId': resolvedVehicleIdInt,
              'locationId': t.locationId ?? _pendingVehicle?.locationId ?? 0,
              'parentAccountId': t.parentAccountId ?? _pendingVehicle?.parentAccountId ?? 0,
              'currentPressure': t.currentPressure ?? 0.0,
              'rimDispositionId': resolvedDispId,
              'pressureType': 'C',
              'casingConditionId': (t.casingConditionId is int && t.casingConditionId > 0) ? t.casingConditionId : null,
              'wearConditionId': (t.wearConditionId is int && t.wearConditionId > 0) ? t.wearConditionId : null,
              'brandNo': t.brandNo ?? '',
              'comments': t.comments ?? '',
              'outsideTread': t.outsideTread ?? t.currentTreadDepth ?? 0.0,
              'insideTread': t.insideTread ?? t.currentTreadDepth ?? 0.0,
              'middleTread': t.middleTread ?? t.currentTreadDepth ?? 0.0,
              'dispositionId': resolvedDispId,
              'dispositionName': resolvedDispName,
              'removalReasonId': resolvedRemovalReason > 0 ? resolvedRemovalReason : 1,
              'percentageWorn': (t.percentageWorn ?? 0.0).clamp(0.0, 100.0),
              'isOfflineTyre': false,
            };
            final bool fromPending = widget.newTires.any((n) => n.tireId == t.tireId) ||
                _pendingRemovedTires.any((p) => p.tireId == t.tireId);
            await removeService.submitRemoveTyre(
              fromPending ? _canonToRawMap(removePayload) : removePayload,
            );
            debugPrint('✅ [IW-VEHICLE] RemoveTyre succeeded for tyre ${t.tireId} with disposition $resolvedDispName ($resolvedDispId)');
          } catch (e) {
            debugPrint('⚠️ [IW-VEHICLE] RemoveTyre exception for tyre ${t.tireId}: $e');
          }
        }
      }

      // 🔑 5. SUBMIT APPROVAL DECISION
      final List<Map<String, dynamic>> tireMaps = widget.newTires.map((t) {
        final map = _canonToRawMap(t.toJson());
        map['vehicleId'] = resolvedVehicleIdInt;
        final rawTid = map['tireId'];
        final int? tidInt = rawTid is num ? rawTid.toInt() : int.tryParse('${rawTid ?? ''}');
        final int? rTid = realTireId(tidInt);
        if (rTid != null) map['tireId'] = rTid;
        map['action'] = (map['action']?.toString().isNotEmpty == true) ? map['action'] : 'Inspect';
        if ((map['imagesLocation'] == null || map['imagesLocation'].toString().trim().isEmpty) &&
            t.imagesLocation != null &&
            t.imagesLocation.toString().trim().isNotEmpty) {
          map['imagesLocation'] = t.imagesLocation.toString().trim();
        }
        return map;
      }).toList();

      for (final t in removedTires) {
        final int resolvedDispId = _resolveRemovedDispositionId(t);
        final String resolvedDispName = _dispositionIdToName(resolvedDispId);
        final int resolvedRemovalReason = (t.removalReasonId != null && t.removalReasonId is num && (t.removalReasonId as num) > 0)
            ? (t.removalReasonId as num).toInt()
            : (int.tryParse(t.removalReasonId?.toString() ?? '') ?? 1);

        final map = _canonToRawMap(t.toJson());
        map['vehicleId'] = resolvedVehicleIdInt;
        map['action'] = 'Remove';
        map['actionType'] = 'Remove';
        map['isRemoved'] = true;
        map['IsRemoved'] = true;
        map['dispositionId'] = resolvedDispId;
        map['dispositionName'] = resolvedDispName;
        map['rimDispositionId'] = resolvedDispId;
        map['wheelPosition'] = t.wheelPosition?.trim().toUpperCase() ?? '';
        map['removalReasonId'] = resolvedRemovalReason > 0 ? resolvedRemovalReason : 1;
        tireMaps.add(map);
      }

      final String resolvedImagesLocation = _inspectionImages.isNotEmpty
          ? _inspectionImages.join(',')
          : (widget.imagesLocation?.toString() ??
          _pendingVehicle?.imagesLocation?.toString() ??
          '');

      final Map<String, dynamic> vehicleEntry = {
        "vehicleId": resolvedVehicleIdInt,
        "inspectionDate": DateTime.now().toIso8601String(),
        "currentHours": double.tryParse(_hoursCtrl.text) ?? 0,
        // ✅ FIX (100 Miles -> 62 Miles bug): vehicle-level distance app me
        // hamesha KM (canonical) me store hoti hai aur display par KM->Miles
        // convert hoti hai (vehicle_view / inspection screen: sourceUnit 'km').
        // Pehle yahan RAW miles (100) bheja ja raha tha -> server ne 100 KM
        // maan liya -> display par 100/1.609 = 62 miles. Ab canonical KM
        // (160.93) bhejte hain -> display par wapas 100 miles.
        // NOTE: tyre-level currentMiles ab bhi RAW jaata hai (_canonToRawMap).
        "currentMiles": _vehicleKmForServer(_canonicalKm ?? _pendingVehicle?.currentMiles),
        "distUnit": _canonicalDistanceUnit,
        "action": "Inspect",
        "imagesLocation": resolvedImagesLocation.isNotEmpty ? resolvedImagesLocation : null,
        "locationId": _pendingVehicle?.locationId ??
            (tireMaps.isNotEmpty ? tireMaps.first['locationId'] ?? 0 : 0),
        "parentAccountId": _pendingVehicle?.parentAccountId ??
            (tireMaps.isNotEmpty ? tireMaps.first['parentAccountId'] ?? 0 : 0),
      };

      final service = VehicleInspeService();
      final success = await service.submitApprovalDecision(
        tireDataList: tireMaps,
        vehicleListEntry: vehicleEntry,
        approverName: approverName,
        remarks: remark,
        isApproved: true,
        inspectionId: resolvedInspectionId > 0 ? resolvedInspectionId : 0,
      );

      if (success) {
        for (final t in widget.newTires) {
          if (t.tireId != null && t.tireId! > 0) {
            double? resolvedWorn = (t.percentageWorn != null && t.percentageWorn! >= 0)
                ? t.percentageWorn
                : (TyreUnitHistory.getPercentageWorn(t.tireId) ??
                (t.tireSerialNo != null ? TyreUnitHistory.getPercentageWorn(t.tireSerialNo!) : null));
            if (resolvedWorn == null || resolvedWorn < 0) {
              final treadSrc = TyreUnitHistory.getTreadUnit(t.tireId);
              final double orig = MeasurementHelper.toDisplayTread(t.originalTread ?? 0.0, sourceUnit: treadSrc);
              final double rem = MeasurementHelper.toDisplayTread(t.removeAt ?? 0.0, sourceUnit: treadSrc);
              final double curr = t.middleTread ?? t.currentTreadDepth ?? t.outsideTread ?? 0.0;
              if (orig > 0 && curr > 0) {
                if (curr >= orig) {
                  resolvedWorn = 0.0;
                } else {
                  final double denom = (orig - rem) > 0 ? (orig - rem) : orig;
                  resolvedWorn = ((1 - (curr - (orig > rem ? rem : 0.0)) / denom) * 100).clamp(0.0, 100.0);
                }
              } else {
                resolvedWorn = 0.0;
              }
            }

            final double? rawTo = TyreUnitHistory.getRawOutside(t.tireId) ??
                (t.tireSerialNo != null ? TyreUnitHistory.getRawOutside(t.tireSerialNo!) : null);
            final double? rawTm = TyreUnitHistory.getRawMiddle(t.tireId) ??
                (t.tireSerialNo != null ? TyreUnitHistory.getRawMiddle(t.tireSerialNo!) : null);
            final double? rawTi = TyreUnitHistory.getRawInside(t.tireId) ??
                (t.tireSerialNo != null ? TyreUnitHistory.getRawInside(t.tireSerialNo!) : null);
            final double? rawP = TyreUnitHistory.getRawPressure(t.tireId) ??
                (t.tireSerialNo != null ? TyreUnitHistory.getRawPressure(t.tireSerialNo!) : null);
            final double? rawM = TyreUnitHistory.getRawMiles(t.tireId) ??
                (t.tireSerialNo != null ? TyreUnitHistory.getRawMiles(t.tireSerialNo!) : null);

            // 🔧 FIX (100 -> 127 / 48 bug): widget.newTires ki values pehle hi
            // display-resolved hain (_mapPendingToInstalled / _resolveLiveTireForDisplay
            // me current preference me convert ho chuki). Pehle yaha unpar
            // _resolveServerTread()/_resolveServerPressure() DOBARA lagta tha
            // (100 -> 127, 100 PSI -> 689 kPa -> /14.5 = 48) aur wo galat number
            // "raw" ban kar TyreUnitHistory me chala jata tha.
            // Ab: raw history ho to wahi (uski apni unit ke saath); nahi ho to
            // t.* ko AS-IS lo aur unit = abhi ki preference likho.
            final String curTreadUnit = MeasurementHelper.isMetric ? 'Metric' : 'Imperial';
            final String curPressUnit = MeasurementHelper.pressureLabel;
            final String curDistUnit = MeasurementHelper.isMetric ? 'Metric' : 'Imperial';

            final bool treadFromRaw = rawTo != null && rawTo > 0 &&
                rawTm != null && rawTm > 0 && rawTi != null && rawTi > 0;
            final bool pressFromRaw = rawP != null && rawP > 0;
            final bool milesFromRaw = rawM != null && rawM > 0;

            final String effTreadUnit = treadFromRaw
                ? (TyreUnitHistory.getTreadUnit(t.tireId) ??
                (t.tireSerialNo != null ? TyreUnitHistory.getTreadUnit(t.tireSerialNo!) : null) ??
                curTreadUnit)
                : curTreadUnit;
            final String effPressUnit = pressFromRaw
                ? (TyreUnitHistory.getPressureUnit(t.tireId) ??
                (t.tireSerialNo != null ? TyreUnitHistory.getPressureUnit(t.tireSerialNo!) : null) ??
                curPressUnit)
                : curPressUnit;
            final String effDistUnit = milesFromRaw
                ? (TyreUnitHistory.getDistanceUnit(t.tireId) ??
                (t.tireSerialNo != null ? TyreUnitHistory.getDistanceUnit(t.tireSerialNo!) : null) ??
                curDistUnit)
                : curDistUnit;

            final double finalTo = treadFromRaw ? rawTo : (t.outsideTread ?? 0.0);
            final double finalTm = treadFromRaw ? rawTm : (t.middleTread ?? t.currentTreadDepth ?? 0.0);
            final double finalTi = treadFromRaw ? rawTi : (t.insideTread ?? 0.0);
            final double finalP = pressFromRaw ? rawP : (t.currentPressure ?? 0.0);

            TyreUnitHistory.recordRawReadings(
              tireId: t.tireId,
              outside: finalTo,
              middle: finalTm,
              inside: finalTi,
              pressure: finalP,
              miles: rawM ?? t.currentMiles,
              percentageWorn: resolvedWorn,
              treadUnit: effTreadUnit,
              pressureUnit: effPressUnit,
              distanceUnit: effDistUnit,
            );
            if (t.tireSerialNo != null && t.tireSerialNo!.isNotEmpty) {
              TyreUnitHistory.recordRawReadings(
                tireId: t.tireSerialNo!,
                outside: finalTo,
                middle: finalTm,
                inside: finalTi,
                pressure: finalP,
                miles: rawM ?? t.currentMiles,
                percentageWorn: resolvedWorn,
                treadUnit: effTreadUnit,
                pressureUnit: effPressUnit,
                distanceUnit: effDistUnit,
              );
            }
          }
        }

        final unitKeys = [
          resolvedVehicleIdInt.toString(),
          widget.vehicleId.toString(),
          widget.vehicleIdInt.toString(),
          if (widget.vehicleNumber.isNotEmpty) widget.vehicleNumber,
        ];
        for (final k in unitKeys) {
          HivePref.set('vehicle_dist_unit_$k', _canonicalDistanceUnit);
          try {
            final sp = await SharedPreferences.getInstance();
            await sp.setString('vehicle_dist_unit_$k', _canonicalDistanceUnit);
          } catch (_) {}
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('pending_vehicle_create_${widget.vehicleIdInt}');
        await prefs.remove('pending_vehicle_update_${widget.vehicleIdInt}');
        await prefs.remove('pending_inspection_tires_${widget.vehicleIdInt}');
        await prefs.remove('pending_inspection_payload_${widget.vehicleIdInt}');
        if (widget.vehicleNumber.isNotEmpty) {
          await prefs.remove('pending_vehicle_create_${widget.vehicleNumber}');
          await prefs.remove('pending_vehicle_update_${widget.vehicleNumber}');
          await prefs.remove('pending_inspection_tires_${widget.vehicleNumber}');
          await prefs.remove('pending_inspection_payload_${widget.vehicleNumber}');
        }
        if (resolvedImagesLocation.isNotEmpty) {
          final keys = [
            resolvedVehicleIdInt.toString(),
            widget.vehicleId.toString(),
            widget.vehicleIdInt.toString(),
            if (widget.vehicleNumber.isNotEmpty) widget.vehicleNumber,
          ];
          for (final k in keys) {
            final cachedStr = OfflineHiveService.getInspectionCache(k);
            if (cachedStr != null) {
              try {
                final cachedMap = jsonDecode(cachedStr);
                if (cachedMap is Map<String, dynamic> && cachedMap['model'] is Map) {
                  cachedMap['model']['imagesLocation'] = resolvedImagesLocation;
                  if (_canonicalKm != null && _canonicalKm! > 0) {
                    cachedMap['model']['lastRecordedMiles'] = _canonicalKm;
                  }
                  await OfflineHiveService.saveInspectionCache(k, jsonEncode(cachedMap));
                }
              } catch (_) {}
            }
          }
          final imgList = resolvedImagesLocation.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          for (final k in keys) {
            await prefs.setStringList('vehicle_images_$k', imgList);
          }
        }

        _updateStatus(IWInspectionStatus.approved, remark: remark, newRealId: resolvedVehicleIdInt);
        await _postDecisionLocalCleanup(
          approved: true,
          removedTires: removedTires,
          vehicleId: resolvedVehicleIdInt,
        );
        if (Get.isRegistered<AllVehicleController>()) {
          Get.find<AllVehicleController>().refreshVehicles();
        }
        if (!mounted) return;
        await _showResultPopup(
          isApprove: true,
          title: a.approved,
          message: a.vehicleAndTiresApproved,
          remark: remark,
        );
        Get.offAllNamed(AppPages.HOME, arguments: {"refreshOnly": true});
      } else {
        Get.snackbar(a.error, a.failedToApprove);
      }
    } catch (e) {
      Get.snackbar(a.error, "Exception: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Approve/Reject ke baad local staged state saaf karta hai taaki removed tyre
  /// install-selection / tyre list me galat status ke saath na dikhe.
  Future<void> _postDecisionLocalCleanup({
    required bool approved,
    required List<InstalledTire> removedTires,
    required int vehicleId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = <String>{
        '${widget.vehicleIdInt}',
        widget.vehicleId.toString(),
        if (vehicleId > 0) '$vehicleId',
        if (widget.vehicleNumber.isNotEmpty) widget.vehicleNumber,
      };
      for (final id in ids) {
        await prefs.remove('pending_inspection_tires_$id');
        await prefs.remove('pending_inspection_payload_$id');
        if (widget.pendingInspectionId != null) {
          await prefs.remove('pending_inspection_tires_${id}_${widget.pendingInspectionId}');
        }
      }

      if (!approved) {
        // ❌ REJECT: staged removal undo karo -> tyre wapas apni position par.
        await _restoreRemovedTiresAfterReject(removedTires, vehicleId);
        // ❌ REJECT: staged installs and inspections undo karo -> tyres wapas pre-inspection state / inventory me
        await _rollbackInstalledAndInspectedTiresAfterReject(vehicleId);
      }

      if (approved) {
        for (final t in removedTires) {
          final tId = t.tireId ?? 0;
          if (tId <= 0) continue;
          final int resolvedDispId = _resolveRemovedDispositionId(t);
          final String resolvedDispName = _dispositionIdToName(resolvedDispId);
          OfflineHiveService.markTireAsRecentlyRemoved(tId);
          await OfflineHiveService.updateTyreDisposition(
            tireId: tId,
            dispositionId: resolvedDispId,
            dispositionName: resolvedDispName,
            vehicleId: 0,
            wheelPosition: '',
          );
        }
        for (final t in [...widget.newTires, ...widget.oldTires]) {
          if (t.tireId != null) TyreUnitHistory.clearPreInspectionBackup(t.tireId);
          if (t.tireSerialNo != null) TyreUnitHistory.clearPreInspectionBackup(t.tireSerialNo);
        }
      }

      try {
        if (Get.isRegistered<AllTyreController>()) {
          await Get.find<AllTyreController>().refresh();
        }
      } catch (_) {}
      try {
        if (Get.isRegistered<IWSearchController>(tag: 'iw_search')) {
          Get.find<IWSearchController>(tag: 'iw_search').refreshData();
        } else if (Get.isRegistered<IWSearchController>()) {
          Get.find<IWSearchController>().refreshData();
        }
      } catch (_) {}

      // ✅ FIX: Remove approved OR rejected vehicle & its tyres from Recent Searches (SecureStorage + Controllers)
      await _cleanupApprovedFromRecentSearches(vehicleId: vehicleId);
    } catch (e) {
      debugPrint('⚠️ [IW-VEHICLE] post-decision cleanup error: $e');
    }
  }

  /// Removes the approved or rejected vehicle and all its associated tyres from Recent Searches.
  Future<void> _cleanupApprovedFromRecentSearches({required int vehicleId}) async {
    try {
      final vIdTarget = vehicleId > 0 ? vehicleId : widget.vehicleIdInt;
      final vNumTarget = widget.vehicleNumber.trim().toLowerCase();

      // 1. Remove vehicle from SecureStorage recent_vehicles
      final rawVehicles = await SecureStorage.getVehicle();
      if (rawVehicles != null && rawVehicles.isNotEmpty) {
        try {
          final List decoded = jsonDecode(rawVehicles);
          final filtered = decoded.where((item) {
            if (item is Map) {
              final id = item['vehicleId'] ?? item['id'];
              final numStr = (item['vehicleNumber'] ?? item['name'] ?? '').toString().toLowerCase().trim();
              if (vIdTarget > 0 && id != null && (id == vIdTarget || id.toString() == '$vIdTarget')) {
                return false;
              }
              if (vNumTarget.isNotEmpty && numStr == vNumTarget) {
                return false;
              }
            }
            return true;
          }).toList();
          await SecureStorage.saveVehicle(jsonEncode(filtered));
        } catch (_) {}
      }

      // Collect all tyre IDs & serials associated with this inspection
      final targetTireIds = <int>{};
      final targetSerials = <String>{};
      for (final t in [...widget.newTires, ...widget.oldTires]) {
        if (t.tireId != null && t.tireId! > 0) targetTireIds.add(t.tireId!);
        if (t.tireSerialNo != null && t.tireSerialNo!.trim().isNotEmpty) {
          targetSerials.add(t.tireSerialNo!.trim().toLowerCase());
        }
      }

      // 2. Remove associated tyres from SecureStorage recent_tyres
      if (targetTireIds.isNotEmpty || targetSerials.isNotEmpty) {
        final rawTyres = await SecureStorage.getTyre();
        if (rawTyres != null && rawTyres.isNotEmpty) {
          try {
            final List decoded = jsonDecode(rawTyres);
            final filtered = decoded.where((item) {
              if (item is Map) {
                final id = item['tireId'] ?? item['id'];
                final serial = (item['tireSerialNo'] ?? item['serialNo'] ?? item['name'] ?? '').toString().toLowerCase().trim();
                if (id != null && targetTireIds.any((tId) => id == tId || id.toString() == '$tId')) {
                  return false;
                }
                if (serial.isNotEmpty && targetSerials.contains(serial)) {
                  return false;
                }
              }
              return true;
            }).toList();
            await SecureStorage.saveTyre(jsonEncode(filtered));
          } catch (_) {}
        }
      }

      // 3. Update active SearchVehicleTyreController in-memory lists if registered
      if (Get.isRegistered<SearchVehicleTyreController>()) {
        final sc = Get.find<SearchVehicleTyreController>();
        sc.recentVehicles.removeWhere((v) {
          final idMatches = vIdTarget > 0 && v.vehicleId == vIdTarget;
          final numMatches = vNumTarget.isNotEmpty && (v.vehicleNumber ?? '').toLowerCase().trim() == vNumTarget;
          return idMatches || numMatches;
        });
        if (targetTireIds.isNotEmpty || targetSerials.isNotEmpty) {
          sc.recentTyres.removeWhere((t) {
            final idMatches = targetTireIds.contains(t.tireId);
            final serialMatches = targetSerials.contains(t.tireSerialNo.toLowerCase().trim());
            return idMatches || serialMatches;
          });
        }
        sc.updateVisibleList();
      }

      // 4. Update active IWSearchController in-memory lists if registered
      IWSearchController? iw;
      if (Get.isRegistered<IWSearchController>(tag: 'iw_search')) {
        iw = Get.find<IWSearchController>(tag: 'iw_search');
      } else if (Get.isRegistered<IWSearchController>()) {
        iw = Get.find<IWSearchController>();
      }
      if (iw != null) {
        iw.recentVehicles.removeWhere((v) {
          final idMatches = vIdTarget > 0 && v.vehicleId == vIdTarget;
          final numMatches = vNumTarget.isNotEmpty && (v.vehicleNumber ?? '').toLowerCase().trim() == vNumTarget;
          return idMatches || numMatches;
        });
        if (targetTireIds.isNotEmpty || targetSerials.isNotEmpty) {
          iw.recentTyres.removeWhere((t) {
            final idMatches = targetTireIds.contains(t.tireId);
            final serialMatches = targetSerials.contains(t.tireSerialNo.toLowerCase().trim());
            return idMatches || serialMatches;
          });
        }
        await iw.pruneRecentSearches();
      }
    } catch (e) {
      debugPrint('⚠️ [IW-VEHICLE] _cleanupApprovedFromRecentSearches error: $e');
    }
  }

  /// Reject pe wapas laane wale tyres (jo inspection me remove stage hue the).
  /// Pehle server ka original (live) tyre lete hain kyunki usme original
  /// wheelPosition/data hota hai; nahi mila to pending record se map karte hain.
  List<InstalledTire> _collectRemovedTiresForRestore() {
    final pendingRemovedIds = _allPendingTiresForVehicle
        .where((t) => _isTireRemoved(t))
        .map((t) => t.tireId)
        .whereType<int>()
        .toSet();
    final result = <InstalledTire>[];
    void add(InstalledTire t) {
      final id = t.tireId ?? 0;
      if (id <= 0) return;
      if (result.any((r) => r.tireId == id)) return;
      result.add(t);
    }

    for (final lt in _liveTires) {
      final id = lt.tireId ?? 0;
      if (id <= 0) continue;
      final notInNewTires = !widget.newTires.any((nt) => nt.tireId == id);
      final explicitlyRemoved = pendingRemovedIds.contains(id) ||
          _pendingRemovedTires.any((p) => p.tireId == id);
      if (notInNewTires || explicitlyRemoved) add(lt);
    }
    for (final pt in _pendingRemovedTires) {
      if ((pt.tireId ?? 0) > 0) add(_mapPendingToInstalled(pt));
    }
    return result;
  }

  /// Reject ke baad removed tyre ko local state me wapas install karta hai:
  ///  1. "recently removed" flag hatao
  ///  2. Hive tyre: disposition = Installed, vehicleId + wheelPosition wapas
  ///  3. Inspection cache (installedTires) me tyre wapas add
  ///  4. Vehicle tyre count update
  Future<void> _restoreRemovedTiresAfterReject(
      List<InstalledTire> tires,
      int vehicleId,
      ) async {
    if (tires.isEmpty) return;
    final int vId = vehicleId > 0 ? vehicleId : widget.vehicleIdInt;

    for (final t in tires) {
      final int tId = t.tireId ?? 0;
      if (tId <= 0) continue;
      try {
        // Original state: Installed on this vehicle at its original position.
        t.dispositionId = 7;
        t.dispositionName = 'Installed';
        t.action = 'Inspect';
        t.vehicleId = vId;
        t.removalReasonId = null;

        OfflineHiveService.unmarkTireAsRecentlyRemoved(tId);

        await OfflineHiveService.updateTyreDisposition(
          tireId: tId,
          dispositionId: 7,
          dispositionName: 'Installed',
          vehicleId: vId,
          wheelPosition: (t.wheelPosition ?? '').trim(),
        );
      } catch (e) {
        debugPrint('⚠️ [IW-VEHICLE] restore tyre $tId (hive) failed: $e');
      }
    }

    // Inspection cache me tyre wapas daalo (saari possible keys)
    int restoredCount = -1;
    final cacheKeys = <String>{
      widget.vehicleId.toString(),
      '${widget.vehicleIdInt}',
      if (vId > 0) '$vId',
      if (widget.vehicleNumber.isNotEmpty) widget.vehicleNumber,
    };
    for (final key in cacheKeys) {
      try {
        final cached = OfflineHiveService.getInspectionCache(key);
        if (cached == null) continue;
        final map = jsonDecode(cached) as Map<String, dynamic>;
        final model = (map['model'] as Map<String, dynamic>?) ?? <String, dynamic>{};
        final installed = List<dynamic>.from((model['installedTires'] as List?) ?? const []);
        for (final t in tires) {
          final int tId = t.tireId ?? 0;
          if (tId <= 0) continue;
          final pos = (t.wheelPosition ?? '').trim().toUpperCase();
          installed.removeWhere((e) =>
          e is Map &&
              (e['tireId']?.toString() == tId.toString() ||
                  (pos.isNotEmpty &&
                      (e['wheelPosition']?.toString().trim().toUpperCase() ?? '') == pos)));
          installed.add(t.toJson());
        }
        model['installedTires'] = installed;
        map['model'] = model;
        await OfflineHiveService.saveInspectionCache(key, jsonEncode(map));
        restoredCount = installed.length;
      } catch (e) {
        debugPrint('⚠️ [IW-VEHICLE] restore inspection cache ($key) failed: $e');
      }
    }

    // Vehicle tyre count
    try {
      if (vId > 0 && restoredCount >= 0) {
        await OfflineHiveService.setVehicleTireCount(vId, restoredCount);
      }
    } catch (_) {}
    try {
      if (Get.isRegistered<AllVehicleController>()) {
        Get.find<AllVehicleController>().refreshVehicles();
      }
    } catch (_) {}
  }

  /// Reject ke baad installed ya inspected tyres ko revert karta hai:
  /// 1. Installed tyre jo is inspection me newly install hua tha -> wapas Inventory (disposition 8),
  ///    vehicleId = 0, wheelPosition = '', original pre-inspection readings (e.g. 100, 100, 100).
  /// 2. Inspected tyre jo pehle se vehicle par tha -> position wahi rahegi, lekin readings
  ///    pre-inspection readings par wapas revert hongi.
  /// 3. Offline backup (TyreUnitHistory) se restore karega, aur online hone par server se
  ///    fresh tyre data fetch karke 100% sync karega.
  Future<void> _rollbackInstalledAndInspectedTiresAfterReject(int vehicleId) async {
    final int vId = vehicleId > 0 ? vehicleId : widget.vehicleIdInt;
    final Set<int> liveTireIds = _liveTires
        .map((lt) => lt.tireId)
        .whereType<int>()
        .where((id) => id > 0)
        .toSet();
    final Set<String> liveTireSerials = _liveTires
        .map((lt) => (lt.tireSerialNo ?? '').trim().toUpperCase())
        .where((s) => s.isNotEmpty)
        .toSet();

    // Saare candidate tyres collect karo jo is inspection ka hissa the
    final Map<dynamic, InstalledTire> candidateTires = {};
    for (final t in widget.newTires) {
      if (t.tireId != null && t.tireId! > 0) {
        candidateTires[t.tireId!] = t;
      } else if (t.tireSerialNo != null && t.tireSerialNo!.trim().isNotEmpty) {
        candidateTires[t.tireSerialNo!.trim().toUpperCase()] = t;
      }
    }
    for (final pt in _allPendingTiresForVehicle) {
      if (!_isTireRemoved(pt)) {
        if (pt.tireId != null && pt.tireId! > 0) {
          candidateTires.putIfAbsent(pt.tireId!, () => _mapPendingToInstalled(pt));
        } else if (pt.tireSerialNo != null && pt.tireSerialNo!.trim().isNotEmpty) {
          candidateTires.putIfAbsent(pt.tireSerialNo!.trim().toUpperCase(), () => _mapPendingToInstalled(pt));
        }
      }
    }

    final hasNet = await NetworkHelper.hasInternet();
    final TyreService tyreService = TyreService();
    final List<int> newlyInstalledTireIdsToRemoveFromVehicle = [];

    for (final entry in candidateTires.entries) {
      final t = entry.value;
      final int tId = t.tireId ?? 0;
      final String sNo = (t.tireSerialNo ?? '').trim().toUpperCase();

      // Check whether this tyre was already installed on vehicle prior to this inspection
      final bool wasAlreadyOnVehicle = (tId > 0 && liveTireIds.contains(tId)) ||
          (sNo.isNotEmpty && liveTireSerials.contains(sNo));

      // Restore from TyreUnitHistory pre-inspection backup
      final backup = (tId > 0 ? TyreUnitHistory.restorePreInspectionReadings(tId) : null) ??
          (sNo.isNotEmpty ? TyreUnitHistory.restorePreInspectionReadings(sNo) : null);

      final double? origOut = (backup != null) ? (backup['outside'] as num?)?.toDouble() : null;
      final double? origMid = (backup != null) ? (backup['middle'] as num?)?.toDouble() : null;
      final double? origIn = (backup != null) ? (backup['inside'] as num?)?.toDouble() : null;
      final double? origPress = (backup != null) ? (backup['pressure'] as num?)?.toDouble() : null;
      final double? origMiles = (backup != null) ? (backup['miles'] as num?)?.toDouble() : null;
      final double? origPct = (backup != null) ? (backup['percentageWorn'] as num?)?.toDouble() : null;
      final String origTreadUnit = (backup != null)
          ? (backup['treadUnit']?.toString() ?? (MeasurementHelper.isMetric ? 'Metric' : 'Imperial'))
          : (TyreUnitHistory.getTreadUnit(tId) ?? (MeasurementHelper.isMetric ? 'Metric' : 'Imperial'));
      final String origPressUnit = (backup != null)
          ? (backup['pressureUnit']?.toString() ?? MeasurementHelper.pressureLabel)
          : MeasurementHelper.pressureLabel;
      final String origDistUnit = (backup != null)
          ? (backup['distanceUnit']?.toString() ?? (MeasurementHelper.isMetric ? 'Metric' : 'Imperial'))
          : (MeasurementHelper.isMetric ? 'Metric' : 'Imperial');
      final int origDispId = (backup != null)
          ? ((backup['dispositionId'] as num?)?.toInt() ?? (wasAlreadyOnVehicle ? 7 : 8))
          : (wasAlreadyOnVehicle ? 7 : 8);

      if (backup != null) {

        // 1. Re-record raw readings in TyreUnitHistory
        if (tId > 0) {
          TyreUnitHistory.recordRawReadings(
            tireId: tId,
            outside: origOut,
            middle: origMid,
            inside: origIn,
            pressure: origPress,
            miles: origMiles,
            percentageWorn: origPct,
            treadUnit: origTreadUnit,
            pressureUnit: origPressUnit,
            distanceUnit: origDistUnit,
          );
          TyreUnitHistory.clearPreInspectionBackup(tId);
        }
        if (sNo.isNotEmpty) {
          TyreUnitHistory.recordRawReadings(
            tireId: sNo,
            outside: origOut,
            middle: origMid,
            inside: origIn,
            pressure: origPress,
            miles: origMiles,
            percentageWorn: origPct,
            treadUnit: origTreadUnit,
            pressureUnit: origPressUnit,
            distanceUnit: origDistUnit,
          );
          TyreUnitHistory.clearPreInspectionBackup(sNo);
        }

        // 2. Update OfflineHiveService
        if (tId > 0) {
          if (!wasAlreadyOnVehicle || origDispId == 8) {
            // Newly installed tyre rejected -> revert to Inventory (8)
            newlyInstalledTireIdsToRemoveFromVehicle.add(tId);
            await OfflineHiveService.updateTyreDisposition(
              tireId: tId,
              dispositionId: 8,
              dispositionName: 'Inventory',
              vehicleId: 0,
              wheelPosition: '',
              outsideTread: origOut,
              middleTread: origMid,
              insideTread: origIn,
              currentTreadDepth: origMid,
              currentPressure: origPress,
            );
          } else {
            // Tyre was already on vehicle, keep installed (7) but restore tread/pressure
            await OfflineHiveService.updateTyreInBox(tId, {
              'outsideTread': origOut,
              'middleTread': origMid,
              'insideTread': origIn,
              'currentTreadDepth': origMid,
              'currentPressure': origPress,
            });
          }
        }
      } else {
        // No backup found (e.g. freshly uninstalled/inspected without backup)
        if (!wasAlreadyOnVehicle && tId > 0) {
          newlyInstalledTireIdsToRemoveFromVehicle.add(tId);
          final hiveT = OfflineHiveService.getTyreById(tId);
          final double outT = (hiveT?.outsideTread is num) ? (hiveT!.outsideTread as num).toDouble() : 0.0;
          final double midT = (hiveT?.middleTread is num) ? (hiveT!.middleTread as num).toDouble() : ((hiveT?.currentTreadDepth is num) ? (hiveT!.currentTreadDepth as num).toDouble() : 0.0);
          final double inT = (hiveT?.insideTread is num) ? (hiveT!.insideTread as num).toDouble() : 0.0;
          final double pressT = (hiveT?.currentPressure is num) ? (hiveT!.currentPressure as num).toDouble() : 0.0;

          await OfflineHiveService.updateTyreDisposition(
            tireId: tId,
            dispositionId: 8,
            dispositionName: 'Inventory',
            vehicleId: 0,
            wheelPosition: '',
            outsideTread: outT > 0 ? outT : null,
            middleTread: midT > 0 ? midT : null,
            insideTread: inT > 0 ? inT : null,
            currentTreadDepth: midT > 0 ? midT : null,
            currentPressure: pressT > 0 ? pressT : null,
          );

          if (outT > 0 || midT > 0 || inT > 0) {
            final String u = TyreUnitHistory.getTreadUnit(tId) ?? (MeasurementHelper.isMetric ? 'Metric' : 'Imperial');
            TyreUnitHistory.recordRawReadings(
              tireId: tId,
              outside: outT > 0 ? outT : null,
              middle: midT > 0 ? midT : null,
              inside: inT > 0 ? inT : null,
              pressure: pressT > 0 ? pressT : null,
              treadUnit: u,
            );
            if (sNo.isNotEmpty) {
              TyreUnitHistory.recordRawReadings(
                tireId: sNo,
                outside: outT > 0 ? outT : null,
                middle: midT > 0 ? midT : null,
                inside: inT > 0 ? inT : null,
                pressure: pressT > 0 ? pressT : null,
                treadUnit: u,
              );
            }
          } else {
            TyreUnitHistory.clearRawReadings(tId);
            if (sNo.isNotEmpty) TyreUnitHistory.clearRawReadings(sNo);
          }
        }
      }

      // 3. Online sync: agar internet hai to server se fresh tyre fetch karke sync karo
      // 🔧 FIX: Jo tyre inspection se pehle hi vehicle par tha aur is inspection me
      // install/inspect nahi hua (backup == null), uski readings reject par
      // BADALNI hi nahi chahiye. Pehle yaha server value dobara convert hokar
      // overwrite ho jaati thi (100 -> 127 -> 161). Isliye skip karo.
      final bool untouchedExistingTyre = wasAlreadyOnVehicle && backup == null;
      if (hasNet && tId > 0 && !untouchedExistingTyre) {
        try {
          final serverList = await tyreService.getTyresById(tId);
          if (serverList.isNotEmpty) {
            final st = serverList.first;
            final bool isNewlyInstalledRejected = !wasAlreadyOnVehicle || origDispId == 8;

            final int finalDispId = isNewlyInstalledRejected ? 8 : (st.dispositionId ?? 7);
            final int finalVehicleId = isNewlyInstalledRejected ? 0 : (st.vehicleId ?? 0);
            final String finalWheelPos = isNewlyInstalledRejected ? '' : (st.wheelPosition ?? '');

            // 🔧 FIX (161 bug): getTyresById DB ka RAW typed number deta hai
            // (e.g. 100), canonical mm/PSI/KM nahi. Pehle yaha
            // _resolveServerTread()/_resolveServerPressure() lagta tha jo
            // 0.79 se divide karta tha (100 -> 127, aur dobara convert hone
            // par 127 -> 161). Isliye server ki value AS-IS lo, aur agar
            // pre-inspection backup hai to wahi priority se restore karo
            // (new-install aur already-on-vehicle dono tyres ke liye).
            double rawSrv(num? v) => (v == null) ? 0.0 : v.toDouble();

            final double finalOutside = (origOut != null && origOut > 0)
                ? origOut
                : rawSrv(st.outsideTread);
            final double finalMiddle = (origMid != null && origMid > 0)
                ? origMid
                : rawSrv(st.middleTread ?? st.currentTreadDepth);
            final double finalInside = (origIn != null && origIn > 0)
                ? origIn
                : rawSrv(st.insideTread);
            final double finalPressure = (origPress != null && origPress > 0)
                ? origPress
                : rawSrv(st.currentPressure);
            final double finalMiles = (origMiles != null && origMiles > 0)
                ? origMiles
                : _resolveServerDistance(st.currentMiles, tireId: tId);
            final double? finalPct = (origPct != null && origPct >= 0)
                ? origPct
                : st.percentageWorn;

            await OfflineHiveService.updateTyreInBox(tId, {
              'dispositionId': finalDispId,
              'dispositionName': finalDispId == 8 ? 'Inventory' : (st.dispositionName ?? 'Mounted'),
              'vehicleId': finalVehicleId,
              'wheelPosition': finalWheelPos,
              'outsideTread': finalOutside,
              'insideTread': finalInside,
              'middleTread': finalMiddle,
              'currentTreadDepth': finalMiddle,
              'currentPressure': finalPressure,
              'currentMiles': finalMiles,
              'currentHours': st.currentHours,
            });

            final String serverUnit = origTreadUnit.isNotEmpty
                ? origTreadUnit
                : (TyreUnitHistory.getTreadUnit(tId) ?? (MeasurementHelper.isMetric ? 'Metric' : 'Imperial'));

            TyreUnitHistory.recordRawReadings(
              tireId: tId,
              outside: finalOutside,
              middle: finalMiddle,
              inside: finalInside,
              pressure: finalPressure,
              miles: finalMiles,
              percentageWorn: finalPct,
              treadUnit: serverUnit,
            );
            if (st.tireSerialNo != null && st.tireSerialNo!.isNotEmpty) {
              TyreUnitHistory.recordRawReadings(
                tireId: st.tireSerialNo!,
                outside: finalOutside,
                middle: finalMiddle,
                inside: finalInside,
                pressure: finalPressure,
                miles: finalMiles,
                percentageWorn: finalPct,
                treadUnit: serverUnit,
              );
            }
          }
        } catch (e) {
          debugPrint('⚠️ [IW-VEHICLE] Failed to refresh tyre $tId from server: $e');
        }
      }

      // 4. Purge all inspection artifacts (images, hot/cold pressure type, comments) for rejected tyres
      if (tId > 0) {
        await InspectTyreController.purgeTireInspectionCache(tId, sNo);
      } else if (sNo.isNotEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('inspect_tire_images_$sNo');
          await prefs.remove('inspect_tire_hotcold_$sNo');
          await prefs.remove('inspect_tire_comment_$sNo');
          await prefs.remove('inspect_tire_still_relevant_$sNo');
          await prefs.remove('tire_conditions_$sNo');
        } catch (_) {}
      }
    }

    // 5. Vehicle inspection cache se rejected newly installed tyres ko remove karo
    if (newlyInstalledTireIdsToRemoveFromVehicle.isNotEmpty) {
      final cacheKeys = <String>{
        widget.vehicleId.toString(),
        '${widget.vehicleIdInt}',
        if (vId > 0) '$vId',
        if (widget.vehicleNumber.isNotEmpty) widget.vehicleNumber,
      };
      for (final key in cacheKeys) {
        try {
          final cached = OfflineHiveService.getInspectionCache(key);
          if (cached == null) continue;
          final map = jsonDecode(cached) as Map<String, dynamic>;
          final model = (map['model'] as Map<String, dynamic>?) ?? <String, dynamic>{};
          final installed = List<dynamic>.from((model['installedTires'] as List?) ?? const []);
          installed.removeWhere((e) {
            if (e is Map) {
              final rawId = e['tireId'];
              final tid = rawId is int ? rawId : (int.tryParse(rawId?.toString() ?? '') ?? 0);
              return newlyInstalledTireIdsToRemoveFromVehicle.contains(tid);
            }
            return false;
          });
          model['installedTires'] = installed;
          map['model'] = model;
          await OfflineHiveService.saveInspectionCache(key, jsonEncode(map));
        } catch (_) {}
      }
    }

    // 6. Purge vehicle inspection images if vehicle inspection is rejected
    if (vId > 0) {
      await LocalImageCache.clearLocalImagesForVehicle(vId);
    }
  }

  Future<void> _onReject() async {
    final a = ApprovalLocalizations.of(Get.context ?? context);
    final bool allowed = await _canPerformApprovalAction();
    if (!allowed) {
      Get.snackbar(
        a.notAllowed,
        a.notAllowedPermission,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return;
    }

    final int resolvedInspectionId = _resolveInspectionStatusId();

    if (resolvedInspectionId <= 0 && widget.vehicleIdInt > 0) {
      Get.snackbar(
        a.error,
        a.invalidInspectionId,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return;
    }

    final remark = await _showRemarkDialog(
      isApprove: false,
      title: a.rejectInspection,
      hint: a.enterReasonRejection,
      accentColor: Colors.red,
      confirmLabel: a.reject,
    );
    if (remark == null) return;

    setState(() => _isSubmitting = true);

    // 🔁 Reject se pehle hi un tyres ko capture kar lo jo remove stage hue the,
    // taaki reject ke baad unhe wapas apni position par restore kar sakein.
    final List<InstalledTire> tiresToRestore = _collectRemovedTiresForRestore();

    try {
      final approverName = await _resolveLoggedInUserName();
      await _loadSubmitterUnits(resolvedInspectionId);
      final List<Map<String, dynamic>> tireMaps =
      widget.newTires.map((t) => _canonToRawMap(t.toJson())).toList();
      final Map<String, dynamic> vehicleEntry = {
        "vehicleId": widget.vehicleIdInt,
        "inspectionDate": DateTime.now().toIso8601String(),
        "currentHours": double.tryParse(_hoursCtrl.text) ?? 0,
        "currentMiles": _vehicleKmForServer(_canonicalKm ?? _pendingVehicle?.currentMiles),
        "distUnit": _canonicalDistanceUnit,
        "action": "Inspect",
        "locationId": _pendingVehicle?.locationId ??
            (tireMaps.isNotEmpty ? tireMaps.first['locationId'] ?? 0 : 0),
        "parentAccountId": _pendingVehicle?.parentAccountId ??
            (tireMaps.isNotEmpty ? tireMaps.first['parentAccountId'] ?? 0 : 0),
      };

      final service = VehicleInspeService();
      final success = await service.submitApprovalDecision(
        tireDataList: tireMaps,      // 🛞 Saare tyres ek sath
        vehicleListEntry: vehicleEntry, // 🚚 Vehicle entry
        approverName: approverName,
        remarks: remark,
        isApproved: false,           // StatusId = 3 (Rejected)[cite: 1]
        inspectionId: resolvedInspectionId > 0 ? resolvedInspectionId : 0,
      );

      if (success) {
        final unitKeys = [
          widget.vehicleId.toString(),
          widget.vehicleIdInt.toString(),
          if (widget.vehicleNumber.isNotEmpty) widget.vehicleNumber,
        ];
        for (final k in unitKeys) {
          HivePref.set('vehicle_dist_unit_$k', _canonicalDistanceUnit);
          try {
            final sp = await SharedPreferences.getInstance();
            await sp.setString('vehicle_dist_unit_$k', _canonicalDistanceUnit);
          } catch (_) {}
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('pending_vehicle_create_${widget.vehicleIdInt}');
        await prefs.remove('pending_vehicle_update_${widget.vehicleIdInt}');
        await prefs.remove('pending_inspection_tires_${widget.vehicleIdInt}');
        await prefs.remove('pending_inspection_payload_${widget.vehicleIdInt}');
        if (widget.vehicleNumber.isNotEmpty) {
          await prefs.remove('pending_vehicle_create_${widget.vehicleNumber}');
          await prefs.remove('pending_vehicle_update_${widget.vehicleNumber}');
          await prefs.remove('pending_inspection_tires_${widget.vehicleNumber}');
          await prefs.remove('pending_inspection_payload_${widget.vehicleNumber}');
        }
        _updateStatus(IWInspectionStatus.rejected, remark: remark);
        await _postDecisionLocalCleanup(
          approved: false,
          removedTires: tiresToRestore,
          vehicleId: widget.vehicleIdInt,
        );
        if (!mounted) return;
        await _showResultPopup(
          isApprove: false,
          title: a.rejected,
          message: a.vehicleAndTiresRejected,
          remark: remark,
        );
        Get.offAllNamed(AppPages.HOME, arguments: {"refreshOnly": true});
      } else {
        Get.snackbar(a.error, a.failedToReject);
      }
    } catch (e) {
      Get.snackbar(a.error, "Exception: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }


  void _updateStatus(IWInspectionStatus status, {String? remark, int? newRealId}) {
    try {
      final c = Get.isRegistered<IWSearchController>(tag: 'iw_search')
          ? Get.find<IWSearchController>(tag: 'iw_search')
          : (Get.isRegistered<IWSearchController>()
          ? Get.find<IWSearchController>()
          : null);
      if (c != null) {
        c.removePendingItem(widget.vehicleIdInt);
        if (newRealId != null && newRealId > 0) {
          c.removePendingItem(newRealId);
        }
        c.pendingInspections.removeWhere((p) {
          final vId = p.vehicle?.vehicleId;
          final vNum = p.vehicle?.vehicleNumber?.trim().toUpperCase();
          final targetNum = widget.vehicleNumber.trim().toUpperCase();
          return (vId != null && (vId == widget.vehicleIdInt || (newRealId != null && vId == newRealId))) ||
              (targetNum.isNotEmpty && vNum == targetNum);
        });
        c.tyres.removeWhere((t) {
          final vId = t.vehicleId;
          final vNum = t.vehicleNumber.trim().toUpperCase();
          final targetNum = widget.vehicleNumber.trim().toUpperCase();
          return (vId != null && (vId == widget.vehicleIdInt || (newRealId != null && vId == newRealId))) ||
              (targetNum.isNotEmpty && vNum == targetNum);
        });
      }
    } catch (_) {}

    try {
      Get.find<HomeController>().refreshCounts();
    } catch (_) {}
  }

  Future<String?> _showRemarkDialog({
    required bool isApprove,
    required String title,
    required String hint,
    required Color accentColor,
    required String confirmLabel,
  }) async {
    final a = ApprovalLocalizations.of(Get.context ?? context);
    final remarkCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return Get.dialog<String>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isApprove ? Icons.check_circle_outline : Icons.cancel_outlined,
                      color: accentColor,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: remarkCtrl,
                  autofocus: true,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: hint,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return a.remarkIsRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(result: null),
                      child: Text(
                        a.cancel,
                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          Get.back(result: remarkCtrl.text.trim());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _showResultPopup({
    required bool isApprove,
    required String title,
    required String message,
    required String remark,
  }) {
    final color = isApprove ? Colors.green : Colors.red;
    final icon  = isApprove ? Icons.check_rounded : Icons.close_rounded;

    return Get.dialog(
      _AnimatedResultDialog(
        color: color,
        icon: icon,
        title: title,
        message: message,
        remark: remark,
      ),
      barrierDismissible: false,
    ).then((_) {});
  }


  // ───────────────────────────────────────────────────────────────
  // 🔧 Pending (GetAllPendingInspections) values CANONICAL hoti hain:
  //    pressure = PSI, tread = mm, miles = KM. Main DB me app RAW typed
  //    number save karta hai (100 BAR / 110 /32nds / 100 Miles), isliye
  //    approve/reject payload bhejne se pehle canonical -> RAW convert.
  // ───────────────────────────────────────────────────────────────
  double? _numOrNull(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());

  // 🔧 FIX (100 -> 1450 / 127 / 62): backend canonical (PSI / mm / KM) value
  // SUBMIT KARNE WALE user ki server-side preference se banata hai. Pehle yahan
  // canonical -> raw ke liye APPROVER ki *local* preference use hoti thi, isliye
  // mismatch hone par 100 BAR = 1450 PSI, 100 mm = 127 (/32nds), 100 KM = 62 Miles
  // save ho jata tha. Ab submitter ki preference (createdBy) server se laakar
  // usi se inverse conversion hota hai.
  String? _srcMeasurement; // 'Metric' / 'Imperial'
  String? _srcPressure; // 'PSI' / 'BAR' / 'KPA'

  Future<void> _loadSubmitterUnits(int inspectionId) async {
    _srcMeasurement = null;
    _srcPressure = null;
    try {
      String? submitter;
      final c = Get.find<IWSearchController>(tag: 'iw_search');
      for (final p in c.pendingInspections) {
        final sameInsp = inspectionId > 0 && p.status?.inspectionStatusId == inspectionId;
        final sameVeh = p.vehicle?.vehicleId != null && p.vehicle?.vehicleId == widget.vehicleIdInt;
        if (sameInsp || sameVeh) {
          final cb = p.status?.createdBy?.trim();
          if (cb != null && cb.isNotEmpty) {
            submitter = cb;
            if (sameInsp) break;
          }
        }
      }
      if (submitter == null) return;
      final prefs = await PreferencesService()
          .fetchPreferences(submitter)
          .timeout(const Duration(seconds: 10));
      if (prefs == null) return;
      if (prefs.measurementSystem.trim().isNotEmpty) _srcMeasurement = prefs.measurementSystem.trim();
      if (prefs.pressureUnit.trim().isNotEmpty) _srcPressure = prefs.pressureUnit.trim();
      debugPrint('🧭 [IW-UNITS] submitter=$submitter measurement=$_srcMeasurement pressure=$_srcPressure '
          '(approver local: ${MeasurementHelper.isMetric ? 'Metric' : 'Imperial'}/${MeasurementHelper.pressureLabel})');
    } catch (e) {
      debugPrint('⚠️ [IW-UNITS] submitter prefs fetch failed, falling back to local prefs: $e');
    }
  }

  Map<String, dynamic> _canonToRawMap(Map<String, dynamic> src) {
    final m = Map<String, dynamic>.from(src);
    // 🔧 FIX: Values must NOT be scaled during approval.
    // The user's entered raw values (Pressure, Tread, Distance) must be preserved as entered.
    final rawPct = _numOrNull(m['percentageWorn']);
    if (rawPct != null) {
      m['percentageWorn'] = rawPct.clamp(0.0, 100.0);
    }
    return m;
  }

  /// Vehicle-level distance server ko bhejo (2 decimals).
  double _vehicleKmForServer(num? canonicalKm) =>
      double.parse(((canonicalKm ?? 0).toDouble()).toStringAsFixed(2));

  @override
  Widget build(BuildContext context) {
    final a = ApprovalLocalizations.of(context);
    _syncVehicleDistanceDisplay();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: const BackButton(color: Colors.white),
        title: Text(
          a.getVehicleInspectionData,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.vehicleNumber,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              _readOnlyField(_vehicleIdCtrl),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.hours,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        _readOnlyField(_hoursCtrl),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_mileageUnitLabel,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        _readOnlyField(_kmCtrl),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(a.vehicleComments,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              _readOnlyField(_commentsCtrl),

              const SizedBox(height: 24),

              Text(a.vehicleDiagram,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: VehicleDiagram(
                  tires: widget.newTires,
                  vehicleId: widget.vehicleIdInt,
                  vehicleNumber: widget.vehicleNumber,
                  axleConfig: _axleConfig,
                  isEditMode: true,
                  canonicalPressureTread: false, // Display values as entered by user without scaling
                  onTireTap: (tire) async {
                    final String? inspDate = (tire.inspectionDate != null && tire.inspectionDate!.trim().isNotEmpty)
                        ? tire.inspectionDate
                        : _pendingInspectionDate;

                    final prefs = await SharedPreferences.getInstance();
                    String? tyreImg = (tire.imagesLocation != null && tire.imagesLocation.toString().trim().isNotEmpty)
                        ? tire.imagesLocation.toString()
                        : (tire.tireId != null
                        ? (prefs.getStringList('inspect_tire_images_${tire.tireId}')?.join(','))
                        : null);

                    if ((tyreImg == null || tyreImg.trim().isEmpty) && tire.tireId != null && tire.tireId! > 0) {
                      final cached = OfflineHiveService.getTireDetailCache(tire.tireId!);
                      if (cached != null) {
                        try {
                          final jd = jsonDecode(cached) as Map<String, dynamic>;
                          final m = jd['model'] as Map<String, dynamic>?;
                          final loc = m?['imagesLocation']?.toString();
                          if (loc != null && loc.trim().isNotEmpty) {
                            tyreImg = loc.trim();
                          }
                        } catch (_) {}
                      }
                    }

                    Get.to(
                          () => IWTyreInspectionScreen(
                        serialNo: tire.tireSerialNo ?? '',
                        tireId: tire.tireId,
                        vehicleNumber: widget.vehicleNumber,
                        inspectionDate: inspDate,
                        wearConditionId: tire.wearConditionId,
                        casingConditionId: tire.casingConditionId,
                        comments: tire.comments,
                        outsideTread: tire.outsideTread,
                        middleTread: tire.middleTread ?? tire.currentTreadDepth,
                        insideTread: tire.insideTread,
                        currentPressure: tire.currentPressure,
                        wheelPosition: tire.wheelPosition,
                        pendingInspectionId: widget.pendingInspectionId,
                        imagesLocation: tyreImg,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // 🖼️ IMAGES DISPLAY SECTION
              Text(a.inspectionImages,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Obx(() {
                // Approval screen shows ONLY server (API) images — never local device files.
                final List<String> apiImages = _inspectionImages
                    .where((String p) => p.startsWith('http'))
                    .toSet()
                    .toList();
                if (apiImages.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        a.noUploadedImagesHere,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: apiImages.length,
                    itemBuilder: (_, index) {
                      final imgPath = apiImages[index];
                      final isHttp = imgPath.startsWith('http');
                      final localFile = File(imgPath);
                      final isLocalFile = !isHttp && localFile.existsSync();
                      final imageUrl = isHttp
                          ? imgPath
                          : "https://emtrackotrapi-dev.azurewebsites.net/${imgPath.startsWith('/') ? imgPath.substring(1) : imgPath}";

                      Widget imageChild;
                      final cachedVehicleImg = LocalImageCache.resolveSync(imageUrl);
                      if (isLocalFile) {
                        imageChild = Image.file(
                          localFile,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 150,
                            height: 150,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        );
                      } else if (cachedVehicleImg != null && cachedVehicleImg.existsSync()) {
                        imageChild = Image.file(
                          cachedVehicleImg,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 150,
                            height: 150,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        );
                      } else {
                        imageChild = Image.network(
                          imageUrl,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              width: 150,
                              height: 150,
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 150,
                            height: 150,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () {
                            Get.dialog(
                              Dialog(
                                backgroundColor: Colors.black.withValues(alpha: 0.88),
                                insetPadding: const EdgeInsets.all(12),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: InteractiveViewer(
                                        child: isLocalFile
                                            ? Image.file(localFile, fit: BoxFit.contain)
                                            : (cachedVehicleImg != null && cachedVehicleImg.existsSync())
                                            ? Image.file(cachedVehicleImg, fit: BoxFit.contain)
                                            : Image.network(imageUrl, fit: BoxFit.contain),
                                      ),
                                    ),
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: CircleAvatar(
                                        backgroundColor: Colors.black54,
                                        child: IconButton(
                                          icon: const Icon(Icons.close, color: Colors.white),
                                          onPressed: () => Get.back(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: imageChild,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),

              const SizedBox(height: 24),

              // 🔒 Approve/Reject buttons: sabhi non-EMTUSER roles ke liye
              // hamesha dikhenge. Sirf EMTUSER ke liye extra condition hai —
              // usko tabhi dikhega jab workflow enabled AND isApprover dono
              // true hon.
              FutureBuilder<bool>(
                future: SecureStorage.getApprovalWorkflowEnabled(),
                builder: (context, snapshot) {
                  final bool isWorkflowEnabled = snapshot.data ?? false;

                  return Obx(() {
                    final role = auth.userRole.value.trim().toUpperCase();
                    final bool isApprover = auth.isApprover.value;

                    final bool canShowButtons = role == 'EMTUSER'
                        ? (isWorkflowEnabled && isApprover)
                        : true;

                    if (!canShowButtons) {
                      return const SizedBox.shrink();
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _onApprove,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : Text(a.approve,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _onReject,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : Text(a.reject,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    );
                  });
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _readOnlyField(TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}

class _AnimatedResultDialog extends StatefulWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String message;
  final String remark;

  const _AnimatedResultDialog({
    required this.color,
    required this.icon,
    required this.title,
    required this.message,
    required this.remark,
  });

  @override
  State<_AnimatedResultDialog> createState() => _AnimatedResultDialogState();
}

class _AnimatedResultDialogState extends State<_AnimatedResultDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim  = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) Get.back();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // End of dialog widget
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.12),
                ),
                child: Icon(widget.icon, color: widget.color, size: 40),
              ),
            ),
            const SizedBox(height: 18),
            FadeTransition(
              opacity: _fadeAnim,
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: _fadeAnim,
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
            if (widget.remark.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ApprovalLocalizations.of(context).remarkLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.remark,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ],

                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}