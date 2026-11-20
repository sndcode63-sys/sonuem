// ============================================================
//  EMTrack Offline Hive Models
//  Ionic app ke SQLite tables ka Flutter/Hive equivalent
//
//  TypeId Map:
//    1  → InspectionHiveModel       (pehle se tha — mat badlo)
//    2  → MasterDataHiveModel
//    3  → VehicleHiveModel
//    4  → TyreHiveModel
//    5  → AccountHiveModel
//    6  → LocationHiveModel
//    7  → PendingOperationHiveModel
// ============================================================

import 'package:hive/hive.dart';

// ─────────────────────────────────────────────────────────────
// 1.  MASTER DATA MODEL  (typeId = 2)
// ─────────────────────────────────────────────────────────────
@HiveType(typeId: 2)
class MasterDataHiveModel extends HiveObject {
  @HiveField(0)
  String savedAt;

  @HiveField(1)
  List<Map<dynamic, dynamic>> axleConfigs;

  @HiveField(2)
  List<Map<dynamic, dynamic>> starRatings;

  @HiveField(3)
  List<Map<dynamic, dynamic>> plyRatings;

  @HiveField(4)
  List<Map<dynamic, dynamic>> casingConditions;

  @HiveField(5)
  List<Map<dynamic, dynamic>> tireDispositions;

  @HiveField(6)
  List<Map<dynamic, dynamic>> tireManufacturers;

  @HiveField(7)
  List<Map<dynamic, dynamic>> tireRemovalReasons;

  @HiveField(8)
  List<Map<dynamic, dynamic>> tireSizes;

  @HiveField(9)
  List<Map<dynamic, dynamic>> tireTypes;

  @HiveField(10)
  List<Map<dynamic, dynamic>> wearConditions;

  @HiveField(11)
  List<Map<dynamic, dynamic>> tireStatus;

  @HiveField(12)
  List<Map<dynamic, dynamic>> tireIndCodes;

  @HiveField(13)
  List<Map<dynamic, dynamic>> tireCompounds;

  @HiveField(14)
  List<Map<dynamic, dynamic>> tireLoadRatings;

  @HiveField(15)
  List<Map<dynamic, dynamic>> tireSpeedRatings;

  @HiveField(16)
  List<Map<dynamic, dynamic>> tireFillTypes;

  @HiveField(17)
  List<Map<dynamic, dynamic>> vehicleManufacturers;

  @HiveField(18)
  List<Map<dynamic, dynamic>> vehicleTypes;

  @HiveField(19)
  List<Map<dynamic, dynamic>> vehicleModels;

  @HiveField(20)
  List<Map<dynamic, dynamic>> vehicleIcons;

  MasterDataHiveModel({
    required this.savedAt,
    required this.axleConfigs,
    required this.starRatings,
    required this.plyRatings,
    required this.casingConditions,
    required this.tireDispositions,
    required this.tireManufacturers,
    required this.tireRemovalReasons,
    required this.tireSizes,
    required this.tireTypes,
    required this.wearConditions,
    this.tireStatus = const [],
    this.tireIndCodes = const [],
    this.tireCompounds = const [],
    this.tireLoadRatings = const [],
    this.tireSpeedRatings = const [],
    this.tireFillTypes = const [],
    this.vehicleManufacturers = const [],
    this.vehicleTypes = const [],
    this.vehicleModels = const [],
    this.vehicleIcons = const [],
  });

  factory MasterDataHiveModel.fromApiMap(Map<String, dynamic> m) {
    List<Map<dynamic, dynamic>> _list(String key) {
      final raw = m[key];
      if (raw == null) return [];
      return (raw as List)
          .map((e) => Map<dynamic, dynamic>.from(e as Map))
          .toList();
    }

    return MasterDataHiveModel(
      savedAt: 'v3|${DateTime.now().toIso8601String()}',
      axleConfigs: _list('axleConfigs'),
      starRatings: _list('starRating'),
      plyRatings: _list('plyRating'),
      casingConditions: _list('casingCondition'),
      tireDispositions: _list('tireDispositions'),
      tireManufacturers: _list('tireManufacturers'),
      tireRemovalReasons: _list('tireRemovalReasons'),
      tireSizes: _list('tireSizes'),
      tireTypes: _list('tireTypes'),
      wearConditions: _list('wearConditions'),
      tireStatus: _list('tireStatus'),
      tireIndCodes: _list('tireIndCodes'),
      tireCompounds: _list('tireCompounds'),
      tireLoadRatings: _list('tireLoadRatings'),
      tireSpeedRatings: _list('tireSpeedRatings'),
      tireFillTypes: _list('tireFillTypes'),
      vehicleManufacturers: _list('vehicleManufacturers'),
      vehicleTypes: _list('vehicleTypes'),
      vehicleModels: _list('vehicleModels'),
      vehicleIcons: _list('vehicleIcons'),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 2.  VEHICLE MODEL  (typeId = 3)
// ─────────────────────────────────────────────────────────────
@HiveType(typeId: 3)
class VehicleHiveModel extends HiveObject {
  @HiveField(0)
  int vehicleId;

  @HiveField(1)
  String vehicleNumber;

  @HiveField(2)
  int parentAccountId;

  @HiveField(3)
  int locationId;

  @HiveField(4)
  String? manufacturerName;

  @HiveField(5)
  int? manufacturerId;

  @HiveField(6)
  String? modelName;

  @HiveField(7)
  int? modelId;

  @HiveField(8)
  String? axleConfig;

  @HiveField(9)
  int? axleConfigId;

  @HiveField(10)
  int? tireSizeId;

  @HiveField(11)
  String? recommendedPressure;

  @HiveField(12)
  double? removalTread;

  @HiveField(13)
  double? currentHours;

  @HiveField(14)
  double? currentMiles;

  @HiveField(15)
  String? mileageType;

  @HiveField(16)
  int tireCount;

  @HiveField(17)
  String savedAt;

  @HiveField(18)
  bool isPendingSync;

  @HiveField(19)
  String? typeName;

  @HiveField(20)
  String? tireSizeName;

  @HiveField(21)
  String? severityComments;

  @HiveField(22)
  int? trackingMethod;

  @HiveField(23)
  double? removalTreadDouble;

  // ✅ NEW: actual survey/inspection date — offline reload ke liye
  @HiveField(24)
  String? lastRecordedDate;

  VehicleHiveModel({
    required this.vehicleId,
    required this.vehicleNumber,
    required this.parentAccountId,
    required this.locationId,
    this.manufacturerName,
    this.manufacturerId,
    this.modelName,
    this.modelId,
    this.axleConfig,
    this.axleConfigId,
    this.tireSizeId,
    this.recommendedPressure,
    this.removalTread,
    this.currentHours,
    this.currentMiles,
    this.mileageType,
    this.tireCount = 0,
    required this.savedAt,
    this.isPendingSync = false,
    this.typeName,
    this.tireSizeName,
    this.severityComments,
    this.trackingMethod,
    this.removalTreadDouble,
    this.lastRecordedDate, // ✅ NEW
  });

  factory VehicleHiveModel.fromMap(Map<String, dynamic> m) {
    return VehicleHiveModel(
      vehicleId: _toInt(m['vehicleId']),
      vehicleNumber: m['vehicleNumber']?.toString() ?? '',
      parentAccountId: _toInt(m['parentAccountId']),
      locationId: _toInt(m['locationId']),
      manufacturerName: m['manufacturerName']?.toString(),
      manufacturerId: m['manufacturerId'] != null
          ? _toInt(m['manufacturerId'])
          : null,
      modelName: m['modelName']?.toString(),
      modelId: m['modelId'] != null ? _toInt(m['modelId']) : null,
      axleConfig: m['axleConfig']?.toString(),
      axleConfigId: m['axleConfigId'] != null
          ? _toInt(m['axleConfigId'])
          : null,
      tireSizeId: m['tireSizeId'] != null ? _toInt(m['tireSizeId']) : null,
      recommendedPressure: m['recommendedPressure']?.toString(),
      removalTread: m['removalTread'] != null
          ? _toDouble(m['removalTread'])
          : null,
      currentHours: m['currentHours'] != null
          ? _toDouble(m['currentHours'])
          : null,
      currentMiles: m['currentMiles'] != null
          ? _toDouble(m['currentMiles'])
          : null,
      mileageType: m['mileageType']?.toString(),
      tireCount: _toInt(m['tireCount']),
      savedAt: DateTime.now().toIso8601String(),
      isPendingSync: m['isPendingSync'] == true,
      typeName: m['typeName']?.toString(),
      tireSizeName: m['tireSizeName']?.toString() ?? m['tireSize']?.toString(),
      severityComments: m['severityComments']?.toString(),
      trackingMethod: m['trackingMethod'] != null
          ? _toInt(m['trackingMethod'])
          : (m['mileageType'] != null ? _toInt(m['mileageType']) : null),
      removalTreadDouble: m['removalTread'] != null
          ? _toDouble(m['removalTread'])
          : null,
      // ✅ NEW: lastRecordedDate — API key fallback ke saath
      lastRecordedDate:
      m['lastRecordedDate']?.toString() ??
          m['lastInspectionDate']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'vehicleId': vehicleId,
    'vehicleNumber': vehicleNumber,
    'parentAccountId': parentAccountId,
    'locationId': locationId,
    'manufacturerName': manufacturerName,
    'manufacturerId': manufacturerId,
    'modelName': modelName,
    'modelId': modelId,
    'axleConfig': axleConfig,
    'axleConfigId': axleConfigId,
    'tireSizeId': tireSizeId,
    'recommendedPressure': recommendedPressure,
    'removalTread': removalTread,
    'currentHours': currentHours,
    'currentMiles': currentMiles,
    'mileageType': mileageType,
    'tireCount': tireCount,
    'tireSizeName': tireSizeName,
    'tireSize': tireSizeName,
    'severityComments': severityComments,
    'trackingMethod': trackingMethod,
    'lastRecordedDate': lastRecordedDate, // ✅ NEW
  };
}

// ─────────────────────────────────────────────────────────────
// 3.  TYRE MODEL  (typeId = 4)
// ─────────────────────────────────────────────────────────────
@HiveType(typeId: 4)
class TyreHiveModel extends HiveObject {
  @HiveField(0)
  int tireId;

  @HiveField(1)
  int parentAccountId;

  @HiveField(2)
  int locationId;

  @HiveField(3)
  String? serialNumber;

  @HiveField(4)
  int? manufacturerId;

  @HiveField(5)
  String? manufacturerName;

  @HiveField(6)
  int? tireSizeId;

  @HiveField(7)
  String? tireSizeName;

  @HiveField(8)
  int? tireTypeId;

  @HiveField(9)
  String? tireTypeName;

  @HiveField(10)
  int? dispositionId;

  @HiveField(11)
  String? dispositionName;

  @HiveField(12)
  int? vehicleId;

  @HiveField(13)
  String? wheelPosition;

  @HiveField(14)
  String savedAt;

  @HiveField(15)
  bool isPendingSync;

  @HiveField(16)
  int? dispositionGroupId;

  @HiveField(17)
  String? typeName;

  @HiveField(18)
  double? outsideTread;

  @HiveField(19)
  double? insideTread;

  @HiveField(20)
  double? currentPressure;

  @HiveField(21)
  double? currentTreadDepth;

  @HiveField(22)
  double? currentHours;

  @HiveField(23)
  double? currentMiles;

  @HiveField(24)
  double? originalTread;

  @HiveField(25)
  double? removeAt;

  @HiveField(26)
  double? purchasedTread;

  @HiveField(27)
  String? brandNo;

  @HiveField(28)
  int? tireStatusId;

  @HiveField(29)
  String? tireStatusName;

  @HiveField(30)
  String? mileageType;

  @HiveField(31)
  int? starRatingId;

  @HiveField(32)
  double? purchaseCost;

  @HiveField(33)
  double? percentageWorn;

  @HiveField(34)
  double? averageTreadDepth;

  @HiveField(35)
  double? casingValue;

  @HiveField(36)
  double? fillCost;

  @HiveField(37)
  double? repairCost;

  @HiveField(38)
  double? retreadCost;

  @HiveField(39)
  double? warrantyAdjustment;

  @HiveField(40)
  double? costAdjustment;

  @HiveField(41)
  double? soldAmount;

  @HiveField(42)
  double? netCost;

  @HiveField(43)
  int? loadRatingId;

  @HiveField(44)
  int? speedRatingId;

  @HiveField(45)
  int? compoundId;

  @HiveField(46)
  int? indCodeId;

  @HiveField(47)
  int? fillTypeId;

  @HiveField(48)
  String? lotNo;

  @HiveField(49)
  String? poNo;

  @HiveField(50)
  String? evaluationNo;

  @HiveField(51)
  String? registeredDate;

  @HiveField(52)
  int? wearConditionId;

  @HiveField(53)
  int? casingConditionId;

  // ✅ FIX: plyId aur middleTread add kiye — offline create/edit ke baad show hoga
  @HiveField(54)
  int? plyId;

  @HiveField(55)
  double? middleTread;

  // ✅ FIX: comments field add kiya — install/inspect ke baad SearchVehicleTyre pe dikhe
  @HiveField(56)
  String? comments;

  TyreHiveModel({
    required this.tireId,
    required this.parentAccountId,
    required this.locationId,
    this.serialNumber,
    this.manufacturerId,
    this.manufacturerName,
    this.tireSizeId,
    this.tireSizeName,
    this.tireTypeId,
    this.tireTypeName,
    this.dispositionId,
    this.dispositionName,
    this.vehicleId,
    this.wheelPosition,
    required this.savedAt,
    this.isPendingSync = false,
    this.dispositionGroupId,
    this.typeName,
    this.outsideTread,
    this.insideTread,
    this.currentPressure,
    this.currentTreadDepth,
    this.currentHours,
    this.currentMiles,
    this.originalTread,
    this.removeAt,
    this.purchasedTread,
    this.brandNo,
    this.tireStatusId,
    this.tireStatusName,
    this.mileageType,
    this.starRatingId,
    this.purchaseCost,
    this.percentageWorn,
    this.averageTreadDepth,
    this.casingValue,
    this.fillCost,
    this.repairCost,
    this.retreadCost,
    this.warrantyAdjustment,
    this.costAdjustment,
    this.soldAmount,
    this.netCost,
    this.loadRatingId,
    this.speedRatingId,
    this.compoundId,
    this.indCodeId,
    this.fillTypeId,
    this.lotNo,
    this.poNo,
    this.evaluationNo,
    this.registeredDate,
    this.wearConditionId,
    this.casingConditionId,
    this.plyId,
    this.middleTread,
    this.comments,
  });

  factory TyreHiveModel.fromMap(Map<String, dynamic> m) {
    return TyreHiveModel(
      tireId: _toInt(m['tireId']),
      parentAccountId: _toInt(m['parentAccountId']),
      locationId: _toInt(m['locationId']),
      // ✅ FIX: API raw response mein 'tireSerialNo' key hoti hai,
      // lekin local payload mein 'serialNumber' — dono support karo
      serialNumber: (m['serialNumber'] ?? m['tireSerialNo'])?.toString(),
      manufacturerId: m['manufacturerId'] != null
          ? _toInt(m['manufacturerId'])
          : null,
      manufacturerName: m['manufacturerName']?.toString(),
      tireSizeId: m['tireSizeId'] != null ? _toInt(m['tireSizeId']) : null,
      tireSizeName: (m['tireSizeName'] ?? m['sizeName'])?.toString(),
      tireTypeId: m['tireTypeId'] != null ? _toInt(m['tireTypeId']) : null,
      tireTypeName: m['tireTypeName']?.toString(),
      dispositionId: m['dispositionId'] != null
          ? _toInt(m['dispositionId'])
          : null,
      dispositionName: m['dispositionName']?.toString(),
      vehicleId: m['vehicleId'] != null ? _toInt(m['vehicleId']) : null,
      wheelPosition: m['wheelPosition']?.toString(),
      savedAt: DateTime.now().toIso8601String(),
      isPendingSync: m['isPendingSync'] == true,
      dispositionGroupId: m['dispositionGroupId'] != null
          ? _toInt(m['dispositionGroupId'])
          : null,
      typeName: m['typeName']?.toString(),
      outsideTread: m['outsideTread'] != null
          ? _toDouble(m['outsideTread'])
          : null,
      insideTread: m['insideTread'] != null
          ? _toDouble(m['insideTread'])
          : null,
      currentPressure: m['currentPressure'] != null
          ? _toDouble(m['currentPressure'])
          : null,
      currentTreadDepth: m['currentTreadDepth'] != null
          ? _toDouble(m['currentTreadDepth'])
          : null,
      currentHours: m['currentHours'] != null
          ? _toDouble(m['currentHours'])
          : null,
      currentMiles: m['currentMiles'] != null
          ? _toDouble(m['currentMiles'])
          : null,
      originalTread: m['originalTread'] != null
          ? _toDouble(m['originalTread'])
          : null,
      removeAt: m['removeAt'] != null ? _toDouble(m['removeAt']) : null,
      purchasedTread: m['purchasedTread'] != null
          ? _toDouble(m['purchasedTread'])
          : null,
      brandNo: m['brandNo']?.toString(),
      tireStatusId: m['tireStatusId'] != null
          ? _toInt(m['tireStatusId'])
          : null,
      tireStatusName: m['tireStatusName']?.toString(),
      mileageType: m['mileageType']?.toString(),
      starRatingId: m['starRatingId'] != null
          ? _toInt(m['starRatingId'])
          : null,
      purchaseCost: m['purchaseCost'] != null
          ? _toDouble(m['purchaseCost'])
          : null,
      percentageWorn: m['percentageWorn'] != null
          ? _toDouble(m['percentageWorn'])
          : null,
      averageTreadDepth: m['averageTreadDepth'] != null
          ? _toDouble(m['averageTreadDepth'])
          : null,
      casingValue: m['casingValue'] != null
          ? _toDouble(m['casingValue'])
          : null,
      fillCost: m['fillCost'] != null ? _toDouble(m['fillCost']) : null,
      repairCost: m['repairCost'] != null ? _toDouble(m['repairCost']) : null,
      retreadCost: m['retreadCost'] != null
          ? _toDouble(m['retreadCost'])
          : null,
      warrantyAdjustment: m['warrantyAdjustment'] != null
          ? _toDouble(m['warrantyAdjustment'])
          : null,
      costAdjustment: m['costAdjustment'] != null
          ? _toDouble(m['costAdjustment'])
          : null,
      soldAmount: m['soldAmount'] != null ? _toDouble(m['soldAmount']) : null,
      netCost: m['netCost'] != null ? _toDouble(m['netCost']) : null,
      loadRatingId: m['loadRatingId'] != null
          ? _toInt(m['loadRatingId'])
          : null,
      speedRatingId: m['speedRatingId'] != null
          ? _toInt(m['speedRatingId'])
          : null,
      compoundId: m['compoundId'] != null ? _toInt(m['compoundId']) : null,
      indCodeId: m['indCodeId'] != null ? _toInt(m['indCodeId']) : null,
      fillTypeId: m['fillTypeId'] != null ? _toInt(m['fillTypeId']) : null,
      lotNo: m['lotNo']?.toString(),
      poNo: m['poNo']?.toString(),
      evaluationNo: m['evaluationNo']?.toString(),
      registeredDate: m['registeredDate']?.toString(),
      wearConditionId: m['wearConditionId'] != null
          ? _toInt(m['wearConditionId'])
          : null,
      casingConditionId: m['casingConditionId'] != null
          ? _toInt(m['casingConditionId'])
          : null,
      // ✅ FIX: plyId aur middleTread fromMap
      plyId: m['plyId'] != null ? _toInt(m['plyId']) : null,
      middleTread: m['middleTread'] != null ? _toDouble(m['middleTread']) : null,
      // ✅ FIX: comments fromMap
      comments: m['comments']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'tireId': tireId,
    'parentAccountId': parentAccountId,
    'locationId': locationId,
    'serialNumber': serialNumber,
    'tireSerialNo': serialNumber,
    'manufacturerId': manufacturerId,
    'manufacturerName': manufacturerName,
    'tireSizeId': tireSizeId,
    'sizeId': tireSizeId,
    'tireSizeName': tireSizeName,
    'tireTypeId': tireTypeId,
    'typeId': tireTypeId,
    'tireTypeName': tireTypeName,
    'dispositionId': dispositionId,
    'dispositionName': dispositionName,
    'vehicleId': vehicleId,
    'wheelPosition': wheelPosition,
    'outsideTread': outsideTread,
    'insideTread': insideTread,
    'currentPressure': currentPressure,
    'currentTreadDepth': currentTreadDepth,
    'currentHours': currentHours,
    'currentMiles': currentMiles,
    'originalTread': originalTread,
    'removeAt': removeAt,
    'purchasedTread': purchasedTread,
    'brandNo': brandNo,
    'tireStatusId': tireStatusId,
    'tireStatusName': tireStatusName,
    'mileageType': mileageType,
    'starRatingId': starRatingId,
    'purchaseCost': purchaseCost,
    'percentageWorn': percentageWorn,
    'averageTreadDepth': averageTreadDepth,
    'casingValue': casingValue,
    'fillCost': fillCost,
    'repairCost': repairCost,
    'retreadCost': retreadCost,
    'warrantyAdjustment': warrantyAdjustment,
    'costAdjustment': costAdjustment,
    'soldAmount': soldAmount,
    'netCost': netCost,
    'loadRatingId': loadRatingId,
    'speedRatingId': speedRatingId,
    'compoundId': compoundId,
    'indCodeId': indCodeId,
    'fillTypeId': fillTypeId,
    'lotNo': lotNo,
    'poNo': poNo,
    'evaluationNo': evaluationNo,
    'registeredDate': registeredDate,
    'wearConditionId': wearConditionId,
    'casingConditionId': casingConditionId,
    // ✅ FIX: plyId aur middleTread toMap
    'plyId': plyId,
    'middleTread': middleTread,
    // ✅ FIX: comments toMap
    'comments': comments,
  };
}

// ─────────────────────────────────────────────────────────────
// 4.  ACCOUNT MODEL  (typeId = 5)
// ─────────────────────────────────────────────────────────────
@HiveType(typeId: 5)
class AccountHiveModel extends HiveObject {
  @HiveField(0)
  int parentAccountId;

  @HiveField(1)
  String accountName;

  @HiveField(2)
  String savedAt;

  AccountHiveModel({
    required this.parentAccountId,
    required this.accountName,
    required this.savedAt,
  });

  factory AccountHiveModel.fromMap(Map<String, dynamic> m) {
    return AccountHiveModel(
      parentAccountId: _toInt(m['parentAccountId'] ?? m['id']),
      accountName: m['accountName']?.toString() ?? '',
      savedAt: DateTime.now().toIso8601String(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 5.  LOCATION MODEL  (typeId = 6)
// ─────────────────────────────────────────────────────────────
@HiveType(typeId: 6)
class LocationHiveModel extends HiveObject {
  @HiveField(0)
  int locationId;

  @HiveField(1)
  String locationName;

  @HiveField(2)
  int parentAccountId;

  @HiveField(3)
  String savedAt;

  LocationHiveModel({
    required this.locationId,
    required this.locationName,
    required this.parentAccountId,
    required this.savedAt,
  });

  factory LocationHiveModel.fromMap(Map<String, dynamic> m) {
    return LocationHiveModel(
      locationId: _toInt(m['locationId'] ?? m['id']),
      locationName: m['locationName']?.toString() ?? '',
      parentAccountId: _toInt(m['parentAccountId']),
      savedAt: DateTime.now().toIso8601String(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 6.  PENDING OPERATION MODEL  (typeId = 7)
// ─────────────────────────────────────────────────────────────
@HiveType(typeId: 7)
class PendingOperationHiveModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String opType;

  @HiveField(2)
  Map<dynamic, dynamic> payload;

  @HiveField(3)
  String endpoint;

  @HiveField(4)
  String httpMethod;

  @HiveField(5)
  String createdAt;

  @HiveField(6)
  int retryCount;

  @HiveField(7)
  bool isSynced;

  @HiveField(8)
  String? syncedAt;

  @HiveField(9)
  String? lastError;

  PendingOperationHiveModel({
    required this.id,
    required this.opType,
    required this.payload,
    required this.endpoint,
    required this.httpMethod,
    required this.createdAt,
    this.retryCount = 0,
    this.isSynced = false,
    this.syncedAt,
    this.lastError,
  });
}


// ─── shared helpers ────────────────────────────────────────
int _toInt(dynamic val) {
  if (val == null) return 0;
  if (val is int) return val;
  return int.tryParse(val.toString()) ?? 0;
}

double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is double) return val;
  return double.tryParse(val.toString()) ?? 0.0;
}