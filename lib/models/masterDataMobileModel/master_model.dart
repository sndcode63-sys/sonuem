import 'package:emtrack/models/masterDataMobileModel/Tire_remove_reason_model.dart';
import 'package:emtrack/models/masterDataMobileModel/axle_config_model.dart';
import 'package:emtrack/models/masterDataMobileModel/casing_condition.dart';
import 'package:emtrack/models/masterDataMobileModel/ply_rating_model.dart';
import 'package:emtrack/models/masterDataMobileModel/star_rating_model.dart';
import 'package:emtrack/models/masterDataMobileModel/tire_compound_model.dart';
import 'package:emtrack/models/masterDataMobileModel/tire_desposition_model.dart';
import 'package:emtrack/models/masterDataMobileModel/tire_fill_type_model.dart';
import 'package:emtrack/models/masterDataMobileModel/tire_ind_code_model.dart';
import 'package:emtrack/models/masterDataMobileModel/tire_load_rating_model.dart';
import 'package:emtrack/models/masterDataMobileModel/tire_manufacturer_model.dart';
import 'package:emtrack/models/masterDataMobileModel/tire_size_model.dart';
import 'package:emtrack/models/masterDataMobileModel/tire_speed_rating_model.dart';
import 'package:emtrack/models/masterDataMobileModel/tire_status_model.dart';
import 'package:emtrack/models/masterDataMobileModel/tire_type_model.dart';
import 'package:emtrack/models/masterDataMobileModel/vehicle_icon_model.dart';
import 'package:emtrack/models/masterDataMobileModel/manufacturer_model.dart';
import 'package:emtrack/models/masterDataMobileModel/vehicle_model_item_model.dart';
import 'package:emtrack/models/masterDataMobileModel/vehicle_type_model.dart';
import 'package:emtrack/models/masterDataMobileModel/wear_condition_model.dart';

import '../offline_hive_models.dart';


class MasterModel {
  final List<Manufacturer> vehicleManufacturers;
  final List<VehicleType> vehicleTypes;
  final List<VehicleModelItem> vehicleModels;
  final List<VehicleIcon> vehicleIcons;
  final List<TireSize> tireSizes;
  final List<AxleConfig> axleConfigs;
  final List<WearCondition> wearConditions;
  final List<CasingCondition> casingCondition;
  final List<TireDisposition> tireDispositions;
  final List<TireRemovalReason> tireRemovalReasons;
  final List<TireManufacturer> tireManufacturers;
  final List<StarRating> starRating;
  final List<PlyRating> plyRating;
  final List<TireType> tireTypes;
  final List<TireCompound> tireCompounds;
  final List<TireLoadRating> tireLoadRatings;
  final List<TireIndCode> tireIndCodes;
  final List<TireSpeedRating> tireSpeedRatings;
  final List<TireStatus> tireStatus;
  final List<TireFillType> tireFillTypes;

  MasterModel({
    required this.vehicleManufacturers,
    required this.vehicleTypes,
    required this.vehicleModels,
    required this.vehicleIcons,
    required this.tireSizes,
    required this.axleConfigs,
    required this.wearConditions,
    required this.casingCondition,
    required this.tireDispositions,
    required this.tireRemovalReasons,
    required this.tireManufacturers,
    required this.starRating,
    required this.plyRating,
    required this.tireTypes,
    required this.tireCompounds,
    required this.tireLoadRatings,
    required this.tireIndCodes,
    required this.tireSpeedRatings,
    required this.tireStatus,
    required this.tireFillTypes,
  });

  factory MasterModel.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(
        String key,
        T Function(Map<String, dynamic>) fromJson,
        ) {
      return (json[key] as List? ?? []).map((e) => fromJson(e)).toList();
    }

    return MasterModel(
      vehicleManufacturers: parseList(
        'vehicleManufacturers',
        Manufacturer.fromJson,
      ),
      vehicleTypes: parseList('vehicleTypes', VehicleType.fromJson),
      vehicleModels: parseList('vehicleModels', VehicleModelItem.fromJson),
      vehicleIcons: parseList('vehicleIcons', VehicleIcon.fromJson),
      tireSizes: parseList('tireSizes', TireSize.fromJson),
      axleConfigs: parseList('axleConfigs', AxleConfig.fromJson),
      wearConditions: parseList('wearConditions', WearCondition.fromJson),
      casingCondition: parseList('casingCondition', CasingCondition.fromJson),
      tireDispositions: parseList('tireDispositions', TireDisposition.fromJson),
      tireRemovalReasons: parseList(
        'tireRemovalReasons',
        TireRemovalReason.fromJson,
      ),
      tireManufacturers: parseList(
        'tireManufacturers',
        TireManufacturer.fromJson,
      ),
      starRating: parseList('starRating', StarRating.fromJson),
      plyRating: parseList('plyRating', PlyRating.fromJson),
      tireTypes: parseList('tireTypes', TireType.fromJson),
      tireCompounds: parseList('tireCompounds', TireCompound.fromJson),
      tireLoadRatings: parseList('tireLoadRatings', TireLoadRating.fromJson),
      tireIndCodes: parseList('tireIndCodes', TireIndCode.fromJson),
      tireSpeedRatings: parseList('tireSpeedRatings', TireSpeedRating.fromJson),
      tireStatus: parseList('tireStatus', TireStatus.fromJson),
      tireFillTypes: parseList('tireFillTypes', TireFillType.fromJson),
    );
  }

  // ── Hive MasterDataHiveModel se construct karo (offline fallback) ──
  factory MasterModel.fromHive(MasterDataHiveModel hive) {
    List<T> parse<T>(List<Map<dynamic, dynamic>> raw, T Function(Map<String, dynamic>) fn) {
      return raw.map((e) {
        try { return fn(Map<String, dynamic>.from(e)); } catch (_) { return null; }
      }).whereType<T>().toList();
    }

    return MasterModel(
      vehicleManufacturers: parse(hive.vehicleManufacturers, Manufacturer.fromJson),
      vehicleTypes:         parse(hive.vehicleTypes,         VehicleType.fromJson),
      vehicleModels:        parse(hive.vehicleModels,        VehicleModelItem.fromJson),
      vehicleIcons:         parse(hive.vehicleIcons,         VehicleIcon.fromJson),
      tireSizes:            parse(hive.tireSizes,            TireSize.fromJson),
      axleConfigs:          parse(hive.axleConfigs,          AxleConfig.fromJson),
      wearConditions:       parse(hive.wearConditions,       WearCondition.fromJson),
      casingCondition:      parse(hive.casingConditions,     CasingCondition.fromJson),
      tireDispositions:     parse(hive.tireDispositions,     TireDisposition.fromJson),
      tireRemovalReasons:   parse(hive.tireRemovalReasons,   TireRemovalReason.fromJson),
      tireManufacturers:    parse(hive.tireManufacturers,    TireManufacturer.fromJson),
      starRating:           parse(hive.starRatings,          StarRating.fromJson),
      plyRating:            parse(hive.plyRatings,           PlyRating.fromJson),
      tireTypes:            parse(hive.tireTypes,            TireType.fromJson),
      tireCompounds:        parse(hive.tireCompounds,        TireCompound.fromJson),
      tireLoadRatings:      parse(hive.tireLoadRatings,      TireLoadRating.fromJson),
      tireIndCodes:         parse(hive.tireIndCodes,         TireIndCode.fromJson),
      tireSpeedRatings:     parse(hive.tireSpeedRatings,     TireSpeedRating.fromJson),
      tireStatus:           parse(hive.tireStatus,           TireStatus.fromJson),
      tireFillTypes:        parse(hive.tireFillTypes,        TireFillType.fromJson),
    );
  }
}