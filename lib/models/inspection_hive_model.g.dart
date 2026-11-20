// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build --delete-conflicting-outputs

import 'package:hive/hive.dart';

import 'inspection_hive_models.dart';

// part of 'inspection_hive_model.dart';


class InspectionHiveModelAdapter extends TypeAdapter<InspectionHiveModel> {
  @override
  final int typeId = 1;

  @override
  InspectionHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InspectionHiveModel(
      id:                 fields[0]  as String,
      vehicleId:          fields[1]  as String,
      vehicleNumber:      fields[2]  as String,
      accountName:        fields[3]  as String,
      locationName:       fields[4]  as String,
      parentAccountId:    fields[5]  as int,
      locationId:         fields[6]  as int,
      inspectionDate:     fields[7]  as String,
      approverName:       fields[8]  as String,
      requestorName:      fields[9]  as String,
      comments:           fields[10] as String,
      status:             fields[11] as String,
      isSynced:           fields[12] as bool,
      syncedAt:           fields[13] as String?,
      inspectedTyreCount: fields[14] as int,
      totalTyreCount:     fields[15] as int,
      rejectionReason:    fields[16] as String?,
      approverEmail:      fields[17] as String?,
      action:             fields[18] as String,
    );
  }

  @override
  void write(BinaryWriter writer, InspectionHiveModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)  ..write(obj.id)
      ..writeByte(1)  ..write(obj.vehicleId)
      ..writeByte(2)  ..write(obj.vehicleNumber)
      ..writeByte(3)  ..write(obj.accountName)
      ..writeByte(4)  ..write(obj.locationName)
      ..writeByte(5)  ..write(obj.parentAccountId)
      ..writeByte(6)  ..write(obj.locationId)
      ..writeByte(7)  ..write(obj.inspectionDate)
      ..writeByte(8)  ..write(obj.approverName)
      ..writeByte(9)  ..write(obj.requestorName)
      ..writeByte(10) ..write(obj.comments)
      ..writeByte(11) ..write(obj.status)
      ..writeByte(12) ..write(obj.isSynced)
      ..writeByte(13) ..write(obj.syncedAt)
      ..writeByte(14) ..write(obj.inspectedTyreCount)
      ..writeByte(15) ..write(obj.totalTyreCount)
      ..writeByte(16) ..write(obj.rejectionReason)
      ..writeByte(17) ..write(obj.approverEmail)
      ..writeByte(18) ..write(obj.action);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is InspectionHiveModelAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}