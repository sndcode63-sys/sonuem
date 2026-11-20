// GENERATED CODE — MANUALLY WRITTEN (build_runner ke baad replace ho jayega)
// Run: flutter pub run build_runner build --delete-conflicting-outputs
//
// Agar @HiveType annotation wala approach use karna ho to
// offline_hive_models.dart ke har class me 'part' statement add karo
// aur build_runner se generate karo.
//
// Ya ye file use karo — dono same kaam karte hain.

import 'package:hive/hive.dart';
import 'offline_hive_models.dart';

// ─────────────────── MasterDataHiveModel ───────────────────
class MasterDataHiveModelAdapter extends TypeAdapter<MasterDataHiveModel> {
  @override
  final int typeId = 2;

  @override
  MasterDataHiveModel read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return MasterDataHiveModel(
      savedAt: f[0] as String,
      axleConfigs: (f[1] as List).cast<Map<dynamic, dynamic>>(),
      starRatings: (f[2] as List).cast<Map<dynamic, dynamic>>(),
      plyRatings: (f[3] as List).cast<Map<dynamic, dynamic>>(),
      casingConditions: (f[4] as List).cast<Map<dynamic, dynamic>>(),
      tireDispositions: (f[5] as List).cast<Map<dynamic, dynamic>>(),
      tireManufacturers: (f[6] as List).cast<Map<dynamic, dynamic>>(),
      tireRemovalReasons: (f[7] as List).cast<Map<dynamic, dynamic>>(),
      tireSizes: (f[8] as List).cast<Map<dynamic, dynamic>>(),
      tireTypes: (f[9] as List).cast<Map<dynamic, dynamic>>(),
      wearConditions: (f[10] as List).cast<Map<dynamic, dynamic>>(),
    );
  }

  @override
  void write(BinaryWriter writer, MasterDataHiveModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.savedAt)
      ..writeByte(1)
      ..write(obj.axleConfigs)
      ..writeByte(2)
      ..write(obj.starRatings)
      ..writeByte(3)
      ..write(obj.plyRatings)
      ..writeByte(4)
      ..write(obj.casingConditions)
      ..writeByte(5)
      ..write(obj.tireDispositions)
      ..writeByte(6)
      ..write(obj.tireManufacturers)
      ..writeByte(7)
      ..write(obj.tireRemovalReasons)
      ..writeByte(8)
      ..write(obj.tireSizes)
      ..writeByte(9)
      ..write(obj.tireTypes)
      ..writeByte(10)
      ..write(obj.wearConditions);
  }
}

// ─────────────────── VehicleHiveModel ───────────────────────
class VehicleHiveModelAdapter extends TypeAdapter<VehicleHiveModel> {
  @override
  final int typeId = 3;

  @override
  VehicleHiveModel read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return VehicleHiveModel(
      vehicleId: f[0] as int,
      vehicleNumber: f[1] as String,
      parentAccountId: f[2] as int,
      locationId: f[3] as int,
      manufacturerName: f[4] as String?,
      manufacturerId: f[5] as int?,
      modelName: f[6] as String?,
      modelId: f[7] as int?,
      axleConfig: f[8] as String?,
      axleConfigId: f[9] as int?,
      tireSizeId: f[10] as int?,
      // ✅ FIX: int? → String? (backward-compat: purana int bhi String mein convert)
      recommendedPressure: f[11]?.toString(),
      // ✅ FIX: int? → double? (decimal support)
      removalTread: f[12] == null
          ? null
          : (f[12] is double ? f[12] as double : (f[12] as num).toDouble()),
      currentHours: f[13] == null
          ? null
          : (f[13] is double ? f[13] as double : (f[13] as num).toDouble()),
      currentMiles: f[14] == null
          ? null
          : (f[14] is double ? f[14] as double : (f[14] as num).toDouble()),
      mileageType: f[15] as String?,
      tireCount: (f[16] as int?) ?? 0,
      savedAt: (f[17] as String?) ?? DateTime.now().toIso8601String(),
      isPendingSync: (f[18] as bool?) ?? false,
      typeName: f[19] as String?,
      // ✅ NEW fields (HiveField 20-23) — safely null agar purana record hai
      tireSizeName: f[20] as String?,
      severityComments: f[21] as String?,
      trackingMethod: f[22] as int?,
      removalTreadDouble: f[23] == null
          ? null
          : (f[23] is double ? f[23] as double : (f[23] as num).toDouble()),
    );
  }

  @override
  void write(BinaryWriter writer, VehicleHiveModel obj) {
    writer
      ..writeByte(24) // ✅ Updated: 24 fields
      ..writeByte(0)
      ..write(obj.vehicleId)
      ..writeByte(1)
      ..write(obj.vehicleNumber)
      ..writeByte(2)
      ..write(obj.parentAccountId)
      ..writeByte(3)
      ..write(obj.locationId)
      ..writeByte(4)
      ..write(obj.manufacturerName)
      ..writeByte(5)
      ..write(obj.manufacturerId)
      ..writeByte(6)
      ..write(obj.modelName)
      ..writeByte(7)
      ..write(obj.modelId)
      ..writeByte(8)
      ..write(obj.axleConfig)
      ..writeByte(9)
      ..write(obj.axleConfigId)
      ..writeByte(10)
      ..write(obj.tireSizeId)
      ..writeByte(11)
      ..write(obj.recommendedPressure) // String now
      ..writeByte(12)
      ..write(obj.removalTread) // double now
      ..writeByte(13)
      ..write(obj.currentHours)
      ..writeByte(14)
      ..write(obj.currentMiles)
      ..writeByte(15)
      ..write(obj.mileageType)
      ..writeByte(16)
      ..write(obj.tireCount)
      ..writeByte(17)
      ..write(obj.savedAt)
      ..writeByte(18)
      ..write(obj.isPendingSync)
      ..writeByte(19)
      ..write(obj.typeName)
      ..writeByte(20)
      ..write(obj.tireSizeName)
      ..writeByte(21)
      ..write(obj.severityComments)
      ..writeByte(22)
      ..write(obj.trackingMethod)
      ..writeByte(23)
      ..write(obj.removalTreadDouble);
  }
}

// ─────────────────── TyreHiveModel ──────────────────────────
class TyreHiveModelAdapter extends TypeAdapter<TyreHiveModel> {
  @override
  final int typeId = 4;

  @override
  TyreHiveModel read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return TyreHiveModel(
      tireId: f[0] as int,
      parentAccountId: f[1] as int,
      locationId: f[2] as int,
      serialNumber: f[3] as String?,
      manufacturerId: f[4] as int?,
      manufacturerName: f[5] as String?,
      tireSizeId: f[6] as int?,
      tireSizeName: f[7] as String?,
      tireTypeId: f[8] as int?,
      tireTypeName: f[9] as String?,
      dispositionId: f[10] as int?,
      dispositionName: f[11] as String?,
      vehicleId: f[12] as int?,
      wheelPosition: f[13] as String?,
      savedAt: (f[14] as String?) ?? DateTime.now().toIso8601String(),
      isPendingSync: (f[15] as bool?) ?? false,
      dispositionGroupId: f[16] as int?,
      typeName: f[17] as String?,
      outsideTread: f[18] == null ? null : (f[18] as num).toDouble(),
      insideTread: f[19] == null ? null : (f[19] as num).toDouble(),
      currentPressure: f[20] == null ? null : (f[20] as num).toDouble(),
      currentTreadDepth: f[21] == null ? null : (f[21] as num).toDouble(),
      // ✅ NEW fields — safely null for old records
      currentHours: f[22] == null ? null : (f[22] as num).toDouble(),
      currentMiles: f[23] == null ? null : (f[23] as num).toDouble(),
      originalTread: f[24] == null ? null : (f[24] as num).toDouble(),
      removeAt: f[25] == null ? null : (f[25] as num).toDouble(),
      purchasedTread: f[26] == null ? null : (f[26] as num).toDouble(),
      brandNo: f[27] as String?,
      tireStatusId: f[28] as int?,
      tireStatusName: f[29] as String?,
      mileageType: f[30] as String?,
      starRatingId: f[31] as int?,
      purchaseCost: f[32] == null ? null : (f[32] as num).toDouble(),
      percentageWorn: f[33] == null ? null : (f[33] as num).toDouble(),
      averageTreadDepth: f[34] == null ? null : (f[34] as num).toDouble(),
      // ✅ FIX: plyId (field 54) aur middleTread (field 55) — new fields, safely null for old records
      plyId: f[54] as int?,
      middleTread: f[55] == null ? null : (f[55] as num).toDouble(),
      // ✅ FIX: comments (field 56)
      comments: f[56] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TyreHiveModel obj) {
    writer
      ..writeByte(38) // ✅ updated total field count (was 35, now 38 with plyId + middleTread + comments)
      ..writeByte(0)
      ..write(obj.tireId)
      ..writeByte(1)
      ..write(obj.parentAccountId)
      ..writeByte(2)
      ..write(obj.locationId)
      ..writeByte(3)
      ..write(obj.serialNumber)
      ..writeByte(4)
      ..write(obj.manufacturerId)
      ..writeByte(5)
      ..write(obj.manufacturerName)
      ..writeByte(6)
      ..write(obj.tireSizeId)
      ..writeByte(7)
      ..write(obj.tireSizeName)
      ..writeByte(8)
      ..write(obj.tireTypeId)
      ..writeByte(9)
      ..write(obj.tireTypeName)
      ..writeByte(10)
      ..write(obj.dispositionId)
      ..writeByte(11)
      ..write(obj.dispositionName)
      ..writeByte(12)
      ..write(obj.vehicleId)
      ..writeByte(13)
      ..write(obj.wheelPosition)
      ..writeByte(14)
      ..write(obj.savedAt)
      ..writeByte(15)
      ..write(obj.isPendingSync)
      ..writeByte(16)
      ..write(obj.dispositionGroupId)
      ..writeByte(17)
      ..write(obj.typeName)
      ..writeByte(18)
      ..write(obj.outsideTread)
      ..writeByte(19)
      ..write(obj.insideTread)
      ..writeByte(20)
      ..write(obj.currentPressure)
      ..writeByte(21)
      ..write(obj.currentTreadDepth)
      ..writeByte(22)
      ..write(obj.currentHours)
      ..writeByte(23)
      ..write(obj.currentMiles)
      ..writeByte(24)
      ..write(obj.originalTread)
      ..writeByte(25)
      ..write(obj.removeAt)
      ..writeByte(26)
      ..write(obj.purchasedTread)
      ..writeByte(27)
      ..write(obj.brandNo)
      ..writeByte(28)
      ..write(obj.tireStatusId)
      ..writeByte(29)
      ..write(obj.tireStatusName)
      ..writeByte(30)
      ..write(obj.mileageType)
      ..writeByte(31)
      ..write(obj.starRatingId)
      ..writeByte(32)
      ..write(obj.purchaseCost)
      ..writeByte(33)
      ..write(obj.percentageWorn)
      ..writeByte(34)
      ..write(obj.averageTreadDepth)
    // ✅ FIX: plyId aur middleTread write
      ..writeByte(54)
      ..write(obj.plyId)
      ..writeByte(55)
      ..write(obj.middleTread)
    // ✅ FIX: comments write
      ..writeByte(56)
      ..write(obj.comments);
  }
}

// ─────────────────── AccountHiveModel ───────────────────────
class AccountHiveModelAdapter extends TypeAdapter<AccountHiveModel> {
  @override
  final int typeId = 5;

  @override
  AccountHiveModel read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return AccountHiveModel(
      parentAccountId: f[0] as int,
      accountName: f[1] as String,
      savedAt: f[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AccountHiveModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.parentAccountId)
      ..writeByte(1)
      ..write(obj.accountName)
      ..writeByte(2)
      ..write(obj.savedAt);
  }
}

// ─────────────────── LocationHiveModel ──────────────────────
class LocationHiveModelAdapter extends TypeAdapter<LocationHiveModel> {
  @override
  final int typeId = 6;

  @override
  LocationHiveModel read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return LocationHiveModel(
      locationId: f[0] as int,
      locationName: f[1] as String,
      parentAccountId: f[2] as int,
      savedAt: f[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LocationHiveModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.locationId)
      ..writeByte(1)
      ..write(obj.locationName)
      ..writeByte(2)
      ..write(obj.parentAccountId)
      ..writeByte(3)
      ..write(obj.savedAt);
  }
}

// ─────────────────── PendingOperationHiveModel ──────────────
class PendingOperationHiveModelAdapter
    extends TypeAdapter<PendingOperationHiveModel> {
  @override
  final int typeId = 7;

  @override
  PendingOperationHiveModel read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return PendingOperationHiveModel(
      id: f[0] as String,
      opType: f[1] as String,
      payload: f[2] as Map<dynamic, dynamic>,
      endpoint: f[3] as String,
      httpMethod: f[4] as String,
      createdAt: f[5] as String,
      retryCount: f[6] as int,
      isSynced: f[7] as bool,
      syncedAt: f[8] as String?,
      lastError: f[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PendingOperationHiveModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.opType)
      ..writeByte(2)
      ..write(obj.payload)
      ..writeByte(3)
      ..write(obj.endpoint)
      ..writeByte(4)
      ..write(obj.httpMethod)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.retryCount)
      ..writeByte(7)
      ..write(obj.isSynced)
      ..writeByte(8)
      ..write(obj.syncedAt)
      ..writeByte(9)
      ..write(obj.lastError);
  }
}