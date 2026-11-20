import 'package:emtrack/models/vehicle_history.dart';

class VehicleModel {
  final int? vehicleId;
  final int? parentAccountId;
  final String? parentAccountName;

  final int? locationId;
  final String? locationName;

  final int? manufacturerId;
  final String? manufacturer;

  final int? modelId;
  final String? modelName;

  final int? typeId;
  final String? typeName;

  final int? tireSizeId;
  final String? tireSize;

  final String? vehicleNumber;
  final DateTime? registeredDate;

  int? mileageType;
  final int? trackingMethod;

  final double? currentMiles;
  final double? currentHours;
  final double? removalTread;

  final String? axleConfig;
  final int? axleConfigId;

  final String? areaOfOperation;
  final String? modifications;
  final String? imagesLocation;

  String? recommendedPressure;   // comma string e.g. "32,45"
  final String? severityComments;

  final int? installedTireCount;
  final bool? isEditable;

  final String? assetNumber;
  final bool? hasMultipleTireSizes;
  final String? multipleTireSizeIds;
  final String? vehjsonFootprint;

  final DateTime? hoursDate;
  final DateTime? createdDate;
  final String? createdBy;
  final DateTime? updatedDate;
  final String? updatedBy;
  final DateTime? lastUpdatedDate;

  final int? averageLoadingReqId;
  final String? averageLoadingReq;
  final int? speedId;
  final String? speed;
  final String? cutting;
  final int? cuttingId;

  final List<VehicleHistory>? vehicleHistory;
  List<dynamic>? installedTires;

  VehicleModel({
    this.vehicleId,
    this.parentAccountId,
    this.parentAccountName,
    this.locationId,
    this.locationName,
    this.manufacturerId,
    this.manufacturer,
    this.modelId,
    this.modelName,
    this.typeId,
    this.typeName,
    this.tireSizeId,
    this.tireSize,
    this.vehicleNumber,
    this.registeredDate,
    this.mileageType,
    this.trackingMethod,
    this.currentMiles,
    this.currentHours,
    this.removalTread,
    this.axleConfig,
    this.axleConfigId,
    this.areaOfOperation,
    this.modifications,
    this.imagesLocation,
    this.recommendedPressure,
    this.severityComments,
    this.installedTireCount,
    this.installedTires,
    this.isEditable,
    this.assetNumber,
    this.hasMultipleTireSizes,
    this.multipleTireSizeIds,
    this.vehjsonFootprint,
    this.hoursDate,
    this.createdDate,
    this.createdBy,
    this.updatedDate,
    this.updatedBy,
    this.lastUpdatedDate,
    this.vehicleHistory,
    this.averageLoadingReqId,
    this.averageLoadingReq,
    this.speedId,
    this.speed,
    this.cutting,
    this.cuttingId,
  });

  Map<String, dynamic> toJson() {
    // ✅ ISO datetime strings
    final String regDate = (registeredDate ?? DateTime.now()).toUtc().toIso8601String();
    final String nowIso = DateTime.now().toUtc().toIso8601String();

    // ✅ mileageType must be String "1"/"2"/"3" for some backend APIs
    final String mileageTypeStr = (mileageType ?? 1).toString();

    // ✅ axleConfig logic
    final String axleConfigStr = (axleConfig != null && axleConfig!.isNotEmpty) ? axleConfig! : "22";

    // ✅ recommendedPressure logic
    final String recPressure = (recommendedPressure != null && recommendedPressure!.isNotEmpty)
        ? recommendedPressure!
        : "0,0";

    // ✅ Audit Logic: createdBy/updatedBy empty nahi honi chahiye
    final String auditId = (updatedBy != null && updatedBy!.isNotEmpty)
        ? updatedBy!
        : (parentAccountId?.toString() ?? "");

    final Map<String, dynamic> data = {
      // ── Core IDs ─────────────────────────────────────────────
      "locationId":       locationId,
      "manufacturerId":   manufacturerId,
      "modelId":          modelId,
      "parentAccountId":  parentAccountId,
      "tireSizeId":       tireSizeId,
      "typeId":           typeId,
      "axleConfigId":     axleConfigId ?? 0,

      // ── Vehicle Info ──────────────────────────────────────────
      "vehicleNumber":    vehicleNumber ?? "",
      "manufacturer":     manufacturer ?? "",
      "typeName":         typeName ?? "",
      "modelName":        modelName ?? "",
      "tireSize":         tireSize ?? "",
      "axleConfig":       axleConfigStr,
      "vehjsonFootprint": vehjsonFootprint ?? "{}",
      "assetNumber":      assetNumber ?? "",
      "locationName":     locationName ?? "",
      "parentAccountName": parentAccountName ?? "",

      // ── Tracking ──────────────────────────────────────────────
      "mileageType":      mileageTypeStr,
      "trackingMethod":   trackingMethod ?? mileageType ?? 1,

      // ── Dates ─────────────────────────────────────────────────
      "registeredDate":   regDate,
      "hoursDate":        nowIso,
      "createdDate":      createdDate?.toUtc().toIso8601String() ?? nowIso,
      "updatedDate":      nowIso,
      "lastUpdatedDate":  nowIso,

      // ── Measurements ──────────────────────────────────────────
      "currentHours":     currentHours ?? 0.0,
      "currentMiles":     currentMiles ?? 0.0,
      "removalTread":     removalTread ?? 0.0,

      // ── Pressure & Comments ───────────────────────────────────
      "recommendedPressure": recPressure,
      "severityComments": severityComments ?? "",
      "siteSeverityIndex": 0,

      // ── Optional fields ───────────────────────────────────────
      "areaOfOperation":  areaOfOperation ?? "",
      "modifications":    modifications ?? "",
      "imagesLocation":   imagesLocation ?? "",
      "averageLoadingReqId": averageLoadingReqId ?? 0,
      "averageLoadingReq":   averageLoadingReq ?? "",
      "speedId":          speedId ?? 0,
      "speed":            speed ?? "",
      "cutting":          cutting ?? "",
      "cuttingId":        cuttingId ?? 0,

      // ── Tires ─────────────────────────────────────────────────
      "installedTireCount": installedTireCount ?? 0,
      "installedTires":     installedTires ?? [],
      "imgsrc":             [],

      // ── Flags ─────────────────────────────────────────────────
      "hasMultipleTireSizes": hasMultipleTireSizes ?? false,
      "multipleTireSizeIds":  multipleTireSizeIds ?? "0,0",
      "isEditable":           isEditable ?? false,

      // ── Audit ─────────────────────────────────────────────────
      "createdBy":  (createdBy != null && createdBy!.isNotEmpty) ? createdBy : auditId,
      "updatedBy":  auditId,

      // ── 🔥 CRITICAL FIX: DYNAMIC EVENT ────────────────────────
      "event": (vehicleId != null && vehicleId! > 0) ? "Update" : "Create",

      "vehicleHistory":     vehicleHistory?.map((e) => e.toJson()).toList() ?? [],
      "inspectionOrderId":  0,
    };

    if (vehicleId != null && vehicleId! > 0) {
      data["vehicleId"] = vehicleId;
    } else if (vehicleId != null && vehicleId! < 0) {
      // ✅ FIX: Offline vehicle ka negative tempId bhi preserve karo
      // Taaki edit ke baad Hive mein same vehicleId se save ho — double nahi bane
      data["vehicleId"] = vehicleId;
    }

    return data;
  }

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      vehicleId:           _toInt(json['vehicleId']),
      parentAccountId:     _toInt(json['parentAccountId']),
      parentAccountName:   json['parentAccountName'],
      locationId:          _toInt(json['locationId']),
      locationName:        json['locationName'],
      manufacturerId:      _toInt(json['manufacturerId']),
      manufacturer:        json['manufacturer'],
      modelId:             _toInt(json['modelId']),
      modelName:           json['modelName'],
      typeId:              _toInt(json['typeId']),
      typeName:            json['typeName'],
      tireSizeId:          _toInt(json['tireSizeId']),
      tireSize:            json['tireSize'],
      vehicleNumber:       json['vehicleNumber'],
      registeredDate:      _toDate(json['registeredDate']),
      mileageType:         _toInt(json['mileageType']),
      trackingMethod:      _toInt(json['trackingMethod']),
      currentMiles:        _toDouble(json['currentMiles']),
      currentHours:        _toDouble(json['currentHours']),
      removalTread:        _toDouble(json['removalTread']),
      axleConfig:          json['axleConfig'],
      axleConfigId:        _toInt(json['axleConfigId']),
      areaOfOperation:     json['areaOfOperation'],
      modifications:       json['modifications'],
      imagesLocation:      json['imagesLocation'],
      recommendedPressure: json['recommendedPressure']?.toString(),
      severityComments:    json['severityComments'],
      installedTireCount:  _toInt(json['installedTireCount']),
      installedTires:      json['installedTires'] ?? [],
      isEditable:          _toBool(json['isEditable']),
      assetNumber:         json['assetNumber'],
      hasMultipleTireSizes: _toBool(json['hasMultipleTireSizes']),
      multipleTireSizeIds: json['multipleTireSizeIds'],
      vehjsonFootprint:    json['vehjsonFootprint'],
      hoursDate:           _toDate(json['hoursDate']),
      createdDate:         _toDate(json['createdDate']),
      createdBy:           json['createdBy'],
      updatedDate:         _toDate(json['updatedDate']),
      updatedBy:           json['updatedBy'],
      lastUpdatedDate:     _toDate(json['lastUpdatedDate']),
      averageLoadingReqId: _toInt(json['averageLoadingReqId']),
      averageLoadingReq:   json['averageLoadingReq'],
      speedId:             _toInt(json['speedId']),
      speed:               json['speed'],
      cutting:             json['cutting'],
      cuttingId:           _toInt(json['cuttingId']),
      vehicleHistory:      (json['vehicleHistory'] as List?)
          ?.map((e) => VehicleHistory.fromJson(e))
          .toList(),
    );
  }
}

// Helper functions (same as yours but cleaned up)
int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  if (v is double) return v.toInt();
  return null;
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool? _toBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is String) return v.toLowerCase() == 'true';
  if (v is int) return v == 1;
  return null;
}

DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  if (v is String) return DateTime.tryParse(v);
  if (v is DateTime) return v;
  return null;
}