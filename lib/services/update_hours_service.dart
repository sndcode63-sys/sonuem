import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emtrack/models/update_hours_model.dart';
import 'package:emtrack/services/api_constants.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:http/http.dart' as http;

class UpdateHoursService {
  Future<bool> submitUpdate(UpdateHoursModel model) async {
    final results  = await Connectivity().checkConnectivity();
    final isOnline = results.any((r) => r != ConnectivityResult.none);

    if (isOnline) {
      try {
        final ok = await _callApi(model);
        if (ok) return true;
      } catch (_) {
      }
    }

    await OfflineHiveService.addPendingOperation(
      opType:     'updateHours',
      payload:    model.toJson(),
      endpoint:   '/api/Inspection/UpdateHoursForVehicle',
      httpMethod: 'PUT',
    );
    return false;
  }

  Future<bool> _callApi(UpdateHoursModel model) async {
    final cookie = await SecureStorage.getCookie();
    if (cookie == null || cookie.isEmpty) {
      throw Exception('Session expired.');
    }

    final url      = "${ApiConstants.baseUrl}/api/Inspection/UpdateHoursForVehicle";
    final bodyData = jsonEncode(model.toJson());


    final response = await http.put(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Accept":       "application/json",
        "Cookie":       cookie,
      },
      body: bodyData,
    ).timeout(const Duration(seconds: 20));


    if (response.statusCode == 200) return true;
    if (response.statusCode == 401 || response.statusCode == 403) {
      await SecureStorage.clearCookie();
      throw Exception('Session expired.');
    }
    throw Exception('UpdateHours failed (${response.statusCode})');
  }
}