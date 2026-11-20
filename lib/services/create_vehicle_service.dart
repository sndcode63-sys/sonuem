import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emtrack/services/api_constants.dart';
import 'package:emtrack/services/global_logout_handler.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models/vehicle_model.dart';

class VehicleService {

  Future<int?> createVehicle(VehicleModel vehicle) async {
    final results = await Connectivity().checkConnectivity();
    final isOnline = results.any((r) => r != ConnectivityResult.none);

    if (isOnline) {
      try {
        final vehicleId = await _callCreateApi(vehicle);
        return vehicleId;
      } catch (e) {

        return await _saveOffline(vehicle);
      }
    } else {
      return await _saveOffline(vehicle);
    }
  }

  Future<int?> createVehicleOnServer(VehicleModel vehicle) async {
    return await _callCreateApi(vehicle);
  }

  Future<int> saveDraftVehicleLocally(VehicleModel vehicle) async {
    final payload = vehicle.toJson();

    payload['tireSizeName'] = vehicle.tireSize ?? '';
    payload['tireSize']     = vehicle.tireSize ?? '';
    payload['trackingMethod'] = vehicle.trackingMethod ?? vehicle.mileageType ?? 1;
    payload['typeName']     = vehicle.typeName ?? '';
    payload['manufacturerName'] = vehicle.manufacturer ?? '';

    final tempIdStr = await OfflineHiveService.saveOfflineVehicle(payload);
    return int.parse(tempIdStr);
  }

  Future<int?> _callCreateApi(VehicleModel vehicle) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/api/Vehicle/Create');
    final cookie = await SecureStorage.getCookie();
    if (cookie == null || cookie.isEmpty) {
      throw Exception('Unauthorized: No cookie found.');
    }
    final body = jsonEncode(vehicle.toJson());

    final response = await http
        .post(
      url,
      headers: {'Content-Type': 'application/json', 'Cookie': cookie},
      body: body,
    )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 401 || response.statusCode == 403) {
      Get.find<GlobalLogoutHandler>().forceLogout();
      return null;
    }


    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResp = jsonDecode(response.body);
      if (jsonResp['didError'] == false) {
        final insertedId = jsonResp['insertedId'] as int;
        try {
          final payload = vehicle.toJson();
          payload['vehicleId'] = insertedId;
          payload['tireSizeName'] = vehicle.tireSize ?? '';
          payload['tireSize']     = vehicle.tireSize ?? '';
          payload['trackingMethod'] = vehicle.trackingMethod ?? vehicle.mileageType ?? 1;
          payload['typeName']     = vehicle.typeName ?? '';
          payload['manufacturerName'] = vehicle.manufacturer ?? '';
          await OfflineHiveService.saveSingleVehicle(payload);
        } catch (_) {}
        return insertedId;
      }
      throw Exception(jsonResp['errorMessage'] ?? 'Unknown error');
    }

    throw Exception('Server error ${response.statusCode}');
  }

  Future<int> _saveOffline(VehicleModel vehicle) async {
    final payload = vehicle.toJson();

    payload['tireSizeName'] = vehicle.tireSize ?? '';
    payload['tireSize']     = vehicle.tireSize ?? '';
    payload['trackingMethod'] = vehicle.trackingMethod ?? vehicle.mileageType ?? 1;
    payload['typeName']     = vehicle.typeName ?? '';
    payload['manufacturerName'] = vehicle.manufacturer ?? '';

    final tempIdStr = await OfflineHiveService.saveOfflineVehicle(payload);
    final tempId = int.parse(tempIdStr);

    await OfflineHiveService.addPendingOperation(
      opType: 'createVehicle',
      payload: payload,
      endpoint: '/api/Vehicle/Create',
      httpMethod: 'POST',
    );

    return tempId;
  }
}