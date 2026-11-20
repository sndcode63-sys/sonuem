import 'dart:convert';
import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emtrack/create_tyre/create_tyre_model.dart';
import 'package:emtrack/services/api_constants.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:emtrack/utils/mesurment_helper_class.dart';
import 'package:emtrack/utils/tyre_unit_history.dart';
import 'package:http/http.dart' as http;

class CreateTyreService {
  static const String _url = ApiConstants.baseUrl + ApiConstants.createTyre;

  static Future<bool> saveTyre(
      CreateTyreModel model, {
        String? manufacturerName,
        String? tireSizeName,
        String? tireStatusName,
        String? tireTypeName,
      }) async {
    final results = await Connectivity().checkConnectivity();
    final isOnline = results.any((r) => r != ConnectivityResult.none);

    if (isOnline) {
      try {
        final success = await _callApi(model);
        return success;
      } catch (e) {
        await _saveOffline(


          model,
          manufacturerName: manufacturerName,
          tireSizeName: tireSizeName,
          tireStatusName: tireStatusName,
          tireTypeName: tireTypeName,
        );
        return false;
      }
    } else {
      await _saveOffline(
        model,
        manufacturerName: manufacturerName,
        tireSizeName: tireSizeName,
        tireStatusName: tireStatusName,
        tireTypeName: tireTypeName,
      );
      return false;
    }
  }

  static Future<bool> _callApi(CreateTyreModel model) async {
    final cookie = await SecureStorage.getCookie();
    if (cookie == null || cookie.isEmpty) {
      throw Exception("Session expired. Please login again.");
    }

    final body = _sanitizeTyreJson(model.toJson());

    body.remove("tireId");
    body.remove("vehicleId");
    body.remove("mountedRimId");

    log("SENDING TO SERVER: ${jsonEncode(body)}");

    final response = await http.post(
      Uri.parse(_url),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Cookie": cookie,
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 200 || response.statusCode == 201) return true;

    throw Exception("API failed: ${response.statusCode}");
  }

  static Future<void> _saveOffline(
      CreateTyreModel model, {
        String? manufacturerName,
        String? tireSizeName,
        String? tireStatusName,
        String? tireTypeName,
      }) async {
    final payload = _sanitizeTyreJson(model.toJson());
    payload.remove("vehicleId");    // ✅ already hai
    payload.remove("mountedRimId"); // ✅ already hai
    payload.remove("tireId");

    payload['serialNumber'] = payload['tireSerialNo'];
    payload['tireSizeId'] = payload['sizeId'];
    payload['tireTypeId'] = payload['typeId'];
    payload['dispositionName'] = 'Inventory';
    payload['dispositionId'] = 8;
    payload['isPendingSync'] = true;

    payload['tireTypeName'] = tireTypeName ?? '';

    if (manufacturerName != null) payload['manufacturerName'] = manufacturerName;
    if (tireSizeName != null) payload['tireSizeName'] = tireSizeName;
    if (tireStatusName != null) payload['tireStatusName'] = tireStatusName;

    final tempIdStr = await OfflineHiveService.saveOfflineTyre(payload);
    final tempId = int.tryParse(tempIdStr);
    if (tempId != null) {
      TyreUnitHistory.recordRawReadings(
        tireId: tempId,
        outside: model.outsideTread,
        middle: model.middleTread,
        inside: model.insideTread,
        miles: model.currentMiles,
        percentageWorn: model.percentageWorn,
        treadUnit: MeasurementHelper.isMetric ? 'Metric' : 'Imperial',
        distanceUnit: MeasurementHelper.distanceLabel,
      );
    }
    await OfflineHiveService.addPendingOperation(
      opType: 'createTyre',
      payload: payload,
      endpoint: ApiConstants.createTyre,
      httpMethod: 'POST',
    );
  }

  static Map<String, dynamic> _sanitizeTyreJson(Map<String, dynamic> json) {
    final sanitized = <String, dynamic>{};
    json.forEach((key, value) {
      if (value == null) {
        sanitized[key] = (key.contains("Id") ||
            key.contains("Miles") ||
            key.contains("Tread") ||
            key.contains("Cost") ||
            key.contains("Adjustment") ||
            key == "removeAt" ||
            key == "purchasedTread" ||
            key == "percentageWorn" ||
            key == "currentHours" ||
            key == "currentMiles")
            ? 0.0
            : null;
      } else {
        sanitized[key] = value;
      }
    });
    return sanitized;
  }
}