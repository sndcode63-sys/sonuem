import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emtrack/services/api_constants.dart';
import 'package:emtrack/services/global_logout_handler.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/offline_hive_models.dart';
import '../models/vehicle_model.dart';

class UpdateVehicleService {
  Future<VehicleModel?> getVehicleById(int vehicleId) async {
    if (vehicleId < 0) {
      return _buildVehicleFromHive(vehicleId);
    }

    final isOnline = await _isOnline();

    if (isOnline) {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}/api/Vehicle/GetDetailsById/$vehicleId',
      );

      final cookie = await SecureStorage.getCookie();
      if (cookie == null || cookie.isEmpty) {
        throw Exception('Unauthorized: No cookie found.');
      }

      try {
        final response = await http.get(
          url,
          headers: {'Content-Type': 'application/json', 'Cookie': cookie},
        );

        if (response.statusCode == 401 || response.statusCode == 403) {
          Get.find<GlobalLogoutHandler>().forceLogout();
          return null;
        }

        if (response.statusCode == 200) {
          final jsonResp = jsonDecode(response.body);

          if (jsonResp['didError'] == false) {
            await OfflineHiveService.saveVehicleDetailCache(
              vehicleId,
              response.body,
            );
            return VehicleModel.fromJson(jsonResp['model']);
          }

          throw Exception(jsonResp['errorMessage'] ?? 'Unknown error');
        }

        throw Exception('Server error ${response.statusCode}');
      } catch (_) {
      }
    }


    final cached = OfflineHiveService.getVehicleDetailCache(vehicleId);
    if (cached != null) {
      try {
        final jsonResp = jsonDecode(cached);
        final vehicle = VehicleModel.fromJson(jsonResp['model']);

        return vehicle;
      } catch (e) {
        return null;
      }
    }



    return null;
  }

  static Future<bool> _isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<bool> updateVehicle(VehicleModel vehicle) async {
    if (vehicle.vehicleId == null) {
      throw Exception("vehicleId is required for update");
    }

    final isOnline = await _isOnline();
    final payload = vehicle.toJson();
    final body = jsonEncode(payload);

    if (isOnline) {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/Vehicle/Update');
      final cookie = await SecureStorage.getCookie();
      if (cookie == null || cookie.isEmpty) {
        throw Exception('Unauthorized: No cookie found.');
      }

      try {
        final response = await http.put(
          url,
          headers: {'Content-Type': 'application/json', 'Cookie': cookie},
          body: body,
        );



        if (response.statusCode == 401 || response.statusCode == 403) {
          Get.find<GlobalLogoutHandler>().forceLogout();
          return false;
        }

        if (response.statusCode == 200) {
          final jsonResp = jsonDecode(response.body);

          if (jsonResp['didError'] == false) {
            if (vehicle.vehicleId != null) {

              await OfflineHiveService.saveVehicleDetailCache(
                vehicle.vehicleId!,
                jsonEncode({'didError': false, 'model': vehicle.toJson()}),
              );
              await patchInspectionCacheWithVehicleFields(vehicle);}
            return true;
          }
          throw Exception(jsonResp['errorMessage'] ?? 'Update failed');
        }

        throw Exception('Server error ${response.statusCode}');
      } catch (_) {
      }
    }

    await OfflineHiveService.addPendingOperation(
      opType:     'updateVehicle',
      payload:    payload,
      endpoint:   '/api/Vehicle/Update',
      httpMethod: 'PUT',
    );

    if (vehicle.vehicleId != null) {
      final existingCache = OfflineHiveService.getVehicleDetailCache(vehicle.vehicleId!);
      List<dynamic> existingTires = [];
      if (existingCache != null) {
        try {
          final existingJson = jsonDecode(existingCache);
          final existingModel = existingJson['model'] as Map<String, dynamic>?;
          existingTires = (existingModel?['installedTires'] as List<dynamic>?) ?? [];
        } catch (_) {}
      }

      final payloadWithTires = Map<String, dynamic>.from(payload);
      if (existingTires.isNotEmpty) {
        payloadWithTires['installedTires'] = existingTires;
      }

      await OfflineHiveService.saveVehicleDetailCache(
        vehicle.vehicleId!,
        jsonEncode({'didError': false, 'model': payloadWithTires}),
      );
      await _updateHiveVehicle(vehicle);
    }
    return true;
  }
  VehicleModel? _buildVehicleFromHive(int vehicleId) {
    final h = OfflineHiveService.getVehicleById(vehicleId);
    if (h == null) {
      return null;
    }
    return VehicleModel(
      vehicleId:          h.vehicleId,
      vehicleNumber:      h.vehicleNumber,
      parentAccountId:    h.parentAccountId,
      locationId:         h.locationId,
      manufacturerId:     h.manufacturerId ?? 0,
      manufacturer:       h.manufacturerName ?? '',
      typeId:             0,
      typeName:           h.typeName ?? '',
      modelId:            h.modelId ?? 0,
      modelName:          h.modelName ?? '',
      tireSizeId:         h.tireSizeId ?? 0,
      tireSize:           h.tireSizeName ?? '',
      axleConfig:         h.axleConfig ?? '22',
      axleConfigId:       h.axleConfigId ?? 0,
      mileageType:        h.trackingMethod ?? 1,
      trackingMethod:     h.trackingMethod ?? 1,
      removalTread:       h.removalTread ?? h.removalTreadDouble ?? 0,
      currentHours:       h.currentHours ?? 0,
      currentMiles:       h.currentMiles ?? 0,
      severityComments:   h.severityComments ?? '',
      recommendedPressure: h.recommendedPressure ?? '0,0',
      registeredDate:     DateTime.now(),
      hoursDate:          DateTime.now(),
      vehjsonFootprint:   '{}',
      areaOfOperation:    '',
      modifications:      '',
      imagesLocation:     '',
      installedTireCount: 0,
      installedTires:     [],
      averageLoadingReqId: 0,
      averageLoadingReq:  '',
      speedId:            0,
      speed:              '',
      cutting:            '',
      cuttingId:          0,
      createdBy:          null,
      createdDate:        DateTime.now(),
      updatedBy:          null,
      updatedDate:        DateTime.now(),
      lastUpdatedDate:    DateTime.now(),
    );
  }

  Future<void> _updateHiveVehicle(VehicleModel vehicle) async {
    try {
      final vId = vehicle.vehicleId;
      if (vId == null) return;

      final box = Hive.box<VehicleHiveModel>('vehicleBox');
      final existing = OfflineHiveService.getVehicleById(vId);
      final existingTireCount = existing?.tireCount ?? 0;

      final payload = {
        'vehicleId':          vId,
        'vehicleNumber':      vehicle.vehicleNumber,
        'parentAccountId':    vehicle.parentAccountId,
        'locationId':         vehicle.locationId,
        'manufacturerId':     vehicle.manufacturerId,
        'manufacturerName':   vehicle.manufacturer,
        'modelId':            vehicle.modelId,
        'modelName':          vehicle.modelName,
        'typeName':           vehicle.typeName,
        'tireSizeId':         vehicle.tireSizeId,
        'tireSizeName':       vehicle.tireSize,
        'tireSize':           vehicle.tireSize,
        'axleConfig':         vehicle.axleConfig,
        'axleConfigId':       vehicle.axleConfigId,
        'trackingMethod':     vehicle.trackingMethod,
        'mileageType':        vehicle.mileageType,
        'removalTread':       vehicle.removalTread,
        'currentHours':       vehicle.currentHours,
        'currentMiles':       vehicle.currentMiles,
        'severityComments':   vehicle.severityComments,
        'recommendedPressure': vehicle.recommendedPressure,
        'tireCount':          existingTireCount,
        'isPendingSync':      true,
      };
      final h = VehicleHiveModel.fromMap(payload.map((k, v) => MapEntry(k, v)));


      dynamic existingKey;
      for (final entry in box.toMap().entries) {
        final val = entry.value as VehicleHiveModel?;
        if (val?.vehicleId == vId) {
          existingKey = entry.key;
          break;
        }
      }

      if (existingKey != null) {
        await box.put(existingKey, h);
      } else {

      }

      await patchInspectionCacheWithVehicleFields(vehicle);
    } catch (_) {
    }
  }


  Future<void> patchInspectionCacheWithVehicleFields(VehicleModel vehicle) async {
    try {
      final vId = vehicle.vehicleId;
      if (vId == null) return;

      final cached = OfflineHiveService.getInspectionCache(vId.toString());
      if (cached == null) {
        return;
      }

      final jsonData = jsonDecode(cached) as Map<String, dynamic>;
      final model = jsonData['model'] as Map<String, dynamic>?;
      if (model == null) return;

      model['vehicleNumber']       = vehicle.vehicleNumber ?? model['vehicleNumber'];
      model['vehicleId']           = vehicle.vehicleId ?? model['vehicleId'];
      model['axleConfig']          = vehicle.axleConfig ?? model['axleConfig'];
      model['vehicleType']         = vehicle.typeName ?? model['vehicleType'];
      model['vehicleModel']        = vehicle.modelName ?? model['vehicleModel'];
      model['vehicleManufacturer'] = vehicle.manufacturer ?? model['vehicleManufacturer'];
      model['tireSize']            = vehicle.tireSize ?? model['tireSize'];
      model['tireSizeId']          = vehicle.tireSizeId ?? model['tireSizeId'];
      model['lastRecordedHours']   = vehicle.currentHours ?? model['lastRecordedHours'];
      model['lastRecordedMiles']   = vehicle.currentMiles ?? model['lastRecordedMiles'];
      model['vehicleMileageType']  = _mileageTypeStr(vehicle.mileageType) ?? model['vehicleMileageType'];

      model['comments'] = vehicle.severityComments ?? model['comments'];

      jsonData['model'] = model;
      await OfflineHiveService.saveInspectionCache(vId.toString(), jsonEncode(jsonData));
    } catch (_) {
    }
  }
  String? _mileageTypeStr(dynamic mt) {
    if (mt == null) return null;
    final v = mt.toString();
    switch (v) {
      case '1': return 'Hours';
      case '2': return 'Distance';
      case '3': return 'Both';
      default:  return v;
    }
  }
}