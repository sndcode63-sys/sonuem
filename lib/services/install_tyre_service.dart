import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emtrack/services/api_constants.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:http/http.dart' as http;

class InstallTyreService {
  Future<bool> submitInspection(Map<String, dynamic> data) async {
    if (data['inspectionDate'] is DateTime) {
      data['inspectionDate'] = (data['inspectionDate'] as DateTime)
          .toIso8601String();
    }

    final results = await Connectivity().checkConnectivity();
    final isOnline = results.any((r) => r != ConnectivityResult.none);

    if (isOnline) {
      try {
        final ok = await _callApi(data);
        if (ok) {
          final tireId = data['tireId'];
          final vehicleId = data['vehicleId'];
          if (tireId != null && tireId is int && tireId > 0) {
            await OfflineHiveService.updateTyreDisposition(
              tireId: tireId,
              dispositionId: data['dispositionId'] ?? 7,
              dispositionName: 'Installed',
              wheelPosition: data['wheelPosition']?.toString(),
              vehicleId: vehicleId is int
                  ? vehicleId
                  : int.tryParse(vehicleId.toString()),
              outsideTread: (data['outsideTread'] as num?)?.toDouble(),
              middleTread: (data['middleTread'] as num?)?.toDouble(),
              insideTread: (data['insideTread'] as num?)?.toDouble(),
              currentTreadDepth: (data['currentTreadDepth'] as num?)
                  ?.toDouble(),
              currentPressure: (data['currentPressure'] as num?)?.toDouble(),
              currentHours: (data['currentHours'] as num?)?.toDouble(),
              currentMiles: (data['currentMiles'] as num?)?.toDouble(),
              wearConditionId: data['wearConditionId'] is int
                  ? data['wearConditionId']
                  : int.tryParse(data['wearConditionId']?.toString() ?? ''),
              casingConditionId: data['casingConditionId'] is int
                  ? data['casingConditionId']
                  : int.tryParse(data['casingConditionId']?.toString() ?? ''),
              comments: data['comments']?.toString(),
            );
          }
          if (vehicleId != null) {
            final vId = vehicleId is int
                ? vehicleId
                : int.tryParse(vehicleId.toString());
            if (vId != null && vId > 0) {
              await OfflineHiveService.updateVehicleTireCount(vId, 1);
            }
          }
          return true;
        }
      } catch (_) {}
    }

    await OfflineHiveService.addPendingOperation(
      opType: 'installTyre',
      payload: data,
      endpoint: '/api/Inspection/InstallTire',
      httpMethod: 'PUT',
    );

    final tireId = data['tireId'];
    final vehicleId = data['vehicleId'];
    if (tireId != null && tireId is int && tireId > 0) {
      await OfflineHiveService.updateTyreDisposition(
        tireId: tireId,
        dispositionId: data['dispositionId'] ?? 7,
        dispositionName: 'Installed',
        wheelPosition: data['wheelPosition']?.toString(),
        vehicleId: vehicleId is int
            ? vehicleId
            : int.tryParse(vehicleId.toString()),
        outsideTread: (data['outsideTread'] as num?)?.toDouble(),
        middleTread: (data['middleTread'] as num?)?.toDouble(),
        insideTread: (data['insideTread'] as num?)?.toDouble(),
        currentTreadDepth: (data['currentTreadDepth'] as num?)?.toDouble(),
        currentPressure: (data['currentPressure'] as num?)?.toDouble(),
        currentHours: (data['currentHours'] as num?)?.toDouble(),
        currentMiles: (data['currentMiles'] as num?)?.toDouble(),
        wearConditionId: data['wearConditionId'] is int
            ? data['wearConditionId']
            : int.tryParse(data['wearConditionId']?.toString() ?? ''),
        casingConditionId: data['casingConditionId'] is int
            ? data['casingConditionId']
            : int.tryParse(data['casingConditionId']?.toString() ?? ''),
        comments: data['comments']?.toString(),
      );
    }

    if (vehicleId != null) {
      final vId = vehicleId is int
          ? vehicleId
          : int.tryParse(vehicleId.toString());
      if (vId != null && vId > 0) {
        await OfflineHiveService.updateVehicleTireCount(vId, 1);
      }
    }

    if (vehicleId != null) {
      await OfflineHiveService.addTireToInspectionCache(
        vehicleId.toString(),
        data,
      );
    }

    throw _OfflineSavedException('Saved offline');
  }

  Future<bool> _callApi(Map<String, dynamic> data) async {
    final cookie = await SecureStorage.getCookie();
    if (cookie == null || cookie.isEmpty) throw Exception('Session expired.');

    final url = Uri.parse('${ApiConstants.baseUrl}/api/Inspection/InstallTire');

    final response = await http
        .put(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Cookie': cookie,
          },
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded['didError'] == false) return true;
      throw Exception(decoded['errorMessage'] ?? 'Backend error');
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      await SecureStorage.clearCookie();
      throw Exception('Session expired.');
    }
    throw Exception('InstallTyre failed (${response.statusCode})');
  }
}

class _OfflineSavedException implements Exception {
  final String message;
  _OfflineSavedException(this.message);
  @override
  String toString() => message;
}
