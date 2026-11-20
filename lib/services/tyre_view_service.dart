import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emtrack/models/masterDataMobileModel/Tire_remove_reason_model.dart';
import 'package:emtrack/models/masterDataMobileModel/axle_config_model.dart';
import 'package:emtrack/models/masterDataMobileModel/casing_condition.dart';
import 'package:emtrack/models/masterDataMobileModel/manufacturer_model.dart';
import 'package:emtrack/models/masterDataMobileModel/master_model.dart';
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
import 'package:emtrack/models/masterDataMobileModel/vehicle_model_item_model.dart';
import 'package:emtrack/models/masterDataMobileModel/vehicle_type_model.dart';
import 'package:emtrack/models/masterDataMobileModel/wear_condition_model.dart';
import 'package:emtrack/models/offline_hive_models.dart';
import 'package:emtrack/services/global_logout_handler.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:emtrack/models/tyre_view_model.dart';
import '../utils/secure_storage.dart';
import 'api_constants.dart';

class TyreViewService {

  static Future<bool> _isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<TyreViewModel> fetchTyreDetailsById(int tireId) async {
    final online = await _isOnline();

    if (online) {
      try {
        final url    = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getTyreById}$tireId');
        final cookie = await SecureStorage.getCookie();
        if (cookie == null || cookie.isEmpty) throw Exception("No cookie");

        final response = await http.get(url, headers: {
          'Content-Type': 'application/json',
          'Accept':       'application/json',
          'Cookie':       cookie,
        });

        if (response.statusCode == 200) {
          await OfflineHiveService.saveTireDetailCache(tireId, response.body);
          final jsonMap = json.decode(response.body);
          final model  = jsonMap['model'] as Map<String, dynamic>;
          return TyreViewModel.fromJson(model);
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          Get.find<GlobalLogoutHandler>().forceLogout();
          throw Exception("Session expired");
        } else {
          throw Exception("Status: ${response.statusCode}");
        }
      } catch (e) {}
    }

    final cached = OfflineHiveService.getTireDetailCache(tireId);
    if (cached != null) {
      try {
        final jsonMap = jsonDecode(cached);
        final model  = jsonMap['model'] as Map<String, dynamic>;
        _showOfflineSnack('Showing cached tire data.');
        return TyreViewModel.fromJson(model);
      } catch (e) {}
    }

    final hiveTyre = OfflineHiveService.getTyreById(tireId);
    if (hiveTyre != null) {
      _showOfflineSnack('Limited tire data available offline.');
      return TyreViewModel(
        tireId:            hiveTyre.tireId,
        tireSerialNo:      hiveTyre.serialNumber,
        manufacturerName:  hiveTyre.manufacturerName,
        manufacturerId:    hiveTyre.manufacturerId,
        sizeName:          hiveTyre.tireSizeName,
        sizeId:            hiveTyre.tireSizeId,
        typeName:          hiveTyre.tireTypeName ?? hiveTyre.typeName,
        typeId:            hiveTyre.tireTypeId,
        dispositionId:     hiveTyre.dispositionId,
        dispositionName:   hiveTyre.dispositionName,
        vehicleId:         hiveTyre.vehicleId,
        wheelPosition:     hiveTyre.wheelPosition,
        outsideTread:      hiveTyre.outsideTread,
        insideTread:       hiveTyre.insideTread,
        currentPressure:   hiveTyre.currentPressure,
        currentTreadDepth: hiveTyre.currentTreadDepth,
      );
    }

    throw Exception('No offline data for tireId=$tireId');
  }


  Future<MasterModel> fetchMasterData() async {
    final online = await _isOnline();

    if (online) {
      try {
        final url    = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getMasterDataMobile}');
        final cookie = await SecureStorage.getCookie();
        if (cookie == null || cookie.isEmpty) throw Exception("No cookie");

        final response = await http.get(url, headers: {
          'Content-Type': 'application/json',
          'Accept':       'application/json',
          'Cookie':       cookie,
        });

        if (response.statusCode == 200) {
          await OfflineHiveService.saveMasterDataJson(response.body);
          final jsonMap = json.decode(response.body);
          final data   = jsonMap['model'] as Map<String, dynamic>;
          return MasterModel.fromJson(data);
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          Get.find<GlobalLogoutHandler>().forceLogout();
          throw Exception("Session expired");
        } else {
          throw Exception("Status: ${response.statusCode}");
        }
      } catch (e) {}
    }

    final cachedJson = OfflineHiveService.getMasterDataJson();
    if (cachedJson != null) {
      try {
        final jsonMap = jsonDecode(cachedJson);
        final data   = jsonMap['model'] as Map<String, dynamic>;
        return MasterModel.fromJson(data);
      } catch (e) {}
    }

    final hiveMaster = OfflineHiveService.getMasterData();
    if (hiveMaster != null) {
      return _masterModelFromHive(hiveMaster);
    }

    throw Exception('No offline master data. Please connect to internet first.');
  }

  MasterModel _masterModelFromHive(MasterDataHiveModel h) {
    List<T> parse<T>(
        List<Map<dynamic, dynamic>> raw,
        T Function(Map<String, dynamic>) fn,
        ) {
      return raw.map((e) {
        try {
          return fn(Map<String, dynamic>.from(e));
        } catch (_) {
          return null;
        }
      }).whereType<T>().toList();
    }

    return MasterModel(
      vehicleManufacturers: parse(h.vehicleManufacturers, Manufacturer.fromJson),
      vehicleTypes:         parse(h.vehicleTypes,         VehicleType.fromJson),
      vehicleModels:        parse(h.vehicleModels,        VehicleModelItem.fromJson),
      vehicleIcons:         parse(h.vehicleIcons,         VehicleIcon.fromJson),
      tireSizes:            parse(h.tireSizes,            TireSize.fromJson),
      axleConfigs:          parse(h.axleConfigs,          AxleConfig.fromJson),
      wearConditions:       parse(h.wearConditions,       WearCondition.fromJson),
      casingCondition:      parse(h.casingConditions,     CasingCondition.fromJson),
      tireDispositions:     parse(h.tireDispositions,     TireDisposition.fromJson),
      tireRemovalReasons:   parse(h.tireRemovalReasons,   TireRemovalReason.fromJson),
      tireManufacturers:    parse(h.tireManufacturers,    TireManufacturer.fromJson),
      starRating:           parse(h.starRatings,          StarRating.fromJson),
      plyRating:            parse(h.plyRatings,           PlyRating.fromJson),
      tireTypes:            parse(h.tireTypes,            TireType.fromJson),
      tireCompounds:        parse(h.tireCompounds,        TireCompound.fromJson),
      tireLoadRatings:      parse(h.tireLoadRatings,      TireLoadRating.fromJson),
      tireIndCodes:         parse(h.tireIndCodes,         TireIndCode.fromJson),
      tireSpeedRatings:     parse(h.tireSpeedRatings,     TireSpeedRating.fromJson),
      tireStatus:           parse(h.tireStatus,           TireStatus.fromJson),
      tireFillTypes:        parse(h.tireFillTypes,        TireFillType.fromJson),
    );
  }

  void _showOfflineSnack(String msg) {
    // Get.snackbar(
    //   'Offline Mode',
    //   msg,
    //   backgroundColor: const Color(0xFFE65100),
    //   colorText: const Color(0xFFFFFFFF),
    //   duration: const Duration(seconds: 3),
    //   snackPosition: SnackPosition.BOTTOM,
    // );
  }
}