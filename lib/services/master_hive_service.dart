

import 'package:hive/hive.dart';
import '../models/offline_hive_models.dart';

//  MasterDataHiveModel
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
      tireStatus: f[11] != null ? (f[11] as List).cast<Map<dynamic, dynamic>>() : [],
      tireIndCodes: f[12] != null ? (f[12] as List).cast<Map<dynamic, dynamic>>() : [],
      tireCompounds: f[13] != null ? (f[13] as List).cast<Map<dynamic, dynamic>>() : [],
      tireLoadRatings: f[14] != null ? (f[14] as List).cast<Map<dynamic, dynamic>>() : [],
      tireSpeedRatings: f[15] != null ? (f[15] as List).cast<Map<dynamic, dynamic>>() : [],
      tireFillTypes: f[16] != null ? (f[16] as List).cast<Map<dynamic, dynamic>>() : [],
      vehicleManufacturers: f[17] != null ? (f[17] as List).cast<Map<dynamic, dynamic>>() : [],
      vehicleTypes: f[18] != null ? (f[18] as List).cast<Map<dynamic, dynamic>>() : [],
      vehicleModels: f[19] != null ? (f[19] as List).cast<Map<dynamic, dynamic>>() : [],
      vehicleIcons: f[20] != null ? (f[20] as List).cast<Map<dynamic, dynamic>>() : [],
    );
  }

  @override
  void write(BinaryWriter writer, MasterDataHiveModel obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)..write(obj.savedAt)
      ..writeByte(1)..write(obj.axleConfigs)
      ..writeByte(2)..write(obj.starRatings)
      ..writeByte(3)..write(obj.plyRatings)
      ..writeByte(4)..write(obj.casingConditions)
      ..writeByte(5)..write(obj.tireDispositions)
      ..writeByte(6)..write(obj.tireManufacturers)
      ..writeByte(7)..write(obj.tireRemovalReasons)
      ..writeByte(8)..write(obj.tireSizes)
      ..writeByte(9)..write(obj.tireTypes)
      ..writeByte(10)..write(obj.wearConditions)
      ..writeByte(11)..write(obj.tireStatus)
      ..writeByte(12)..write(obj.tireIndCodes)
      ..writeByte(13)..write(obj.tireCompounds)
      ..writeByte(14)..write(obj.tireLoadRatings)
      ..writeByte(15)..write(obj.tireSpeedRatings)
      ..writeByte(16)..write(obj.tireFillTypes)
      ..writeByte(17)..write(obj.vehicleManufacturers)
      ..writeByte(18)..write(obj.vehicleTypes)
      ..writeByte(19)..write(obj.vehicleModels)
      ..writeByte(20)..write(obj.vehicleIcons);
  }
}

// VehicleHiveModel
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
      recommendedPressure: f[11] as String?,
      removalTread: f[12] as double?,
      currentHours: f[13] as double?,
      currentMiles: f[14] as double?,
      mileageType: f[15] as String?,
      tireCount: f[16] as int,
      savedAt: f[17] as String,
      isPendingSync: f[18] as bool,
      typeName: f[19] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, VehicleHiveModel obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)..write(obj.vehicleId)
      ..writeByte(1)..write(obj.vehicleNumber)
      ..writeByte(2)..write(obj.parentAccountId)
      ..writeByte(3)..write(obj.locationId)
      ..writeByte(4)..write(obj.manufacturerName)
      ..writeByte(5)..write(obj.manufacturerId)
      ..writeByte(6)..write(obj.modelName)
      ..writeByte(7)..write(obj.modelId)
      ..writeByte(8)..write(obj.axleConfig)
      ..writeByte(9)..write(obj.axleConfigId)
      ..writeByte(10)..write(obj.tireSizeId)
      ..writeByte(11)..write(obj.recommendedPressure)
      ..writeByte(12)..write(obj.removalTread)
      ..writeByte(13)..write(obj.currentHours)
      ..writeByte(14)..write(obj.currentMiles)
      ..writeByte(15)..write(obj.mileageType)
      ..writeByte(16)..write(obj.tireCount)
      ..writeByte(17)..write(obj.savedAt)
      ..writeByte(18)..write(obj.isPendingSync)
      ..writeByte(19)..write(obj.typeName);
  }
}

//  TyreHiveModel
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
      savedAt: f[14] as String,
      isPendingSync: f[15] as bool,
      dispositionGroupId: f[16] as int?,
      typeName: f[17] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TyreHiveModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)..write(obj.tireId)
      ..writeByte(1)..write(obj.parentAccountId)
      ..writeByte(2)..write(obj.locationId)
      ..writeByte(3)..write(obj.serialNumber)
      ..writeByte(4)..write(obj.manufacturerId)
      ..writeByte(5)..write(obj.manufacturerName)
      ..writeByte(6)..write(obj.tireSizeId)
      ..writeByte(7)..write(obj.tireSizeName)
      ..writeByte(8)..write(obj.tireTypeId)
      ..writeByte(9)..write(obj.tireTypeName)
      ..writeByte(10)..write(obj.dispositionId)
      ..writeByte(11)..write(obj.dispositionName)
      ..writeByte(12)..write(obj.vehicleId)
      ..writeByte(13)..write(obj.wheelPosition)
      ..writeByte(14)..write(obj.savedAt)
      ..writeByte(15)..write(obj.isPendingSync)
      ..writeByte(16)..write(obj.dispositionGroupId)
      ..writeByte(17)..write(obj.typeName);
  }
}

//  AccountHiveModel
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
      ..writeByte(0)..write(obj.parentAccountId)
      ..writeByte(1)..write(obj.accountName)
      ..writeByte(2)..write(obj.savedAt);
  }
}

// LocationHiveModel
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
      ..writeByte(0)..write(obj.locationId)
      ..writeByte(1)..write(obj.locationName)
      ..writeByte(2)..write(obj.parentAccountId)
      ..writeByte(3)..write(obj.savedAt);
  }
}

//  PendingOperationHiveModel
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
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.opType)
      ..writeByte(2)..write(obj.payload)
      ..writeByte(3)..write(obj.endpoint)
      ..writeByte(4)..write(obj.httpMethod)
      ..writeByte(5)..write(obj.createdAt)
      ..writeByte(6)..write(obj.retryCount)
      ..writeByte(7)..write(obj.isSynced)
      ..writeByte(8)..write(obj.syncedAt)
      ..writeByte(9)..write(obj.lastError);
  }
}