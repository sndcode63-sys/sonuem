import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/secure_storage.dart';
import 'api_constants.dart';
import 'image_upload_service.dart';
import '../utils/api_logger.dart';
import 'global_logout_handler.dart';



/// Outcome of a successful (online) InspectTire save.
/// [inspectionId] is needed for Inspection/CreateImages afterwards.
class InspectSaveResult {
  final int? inspectionId;
  const InspectSaveResult({this.inspectionId});
}

class InspectTyreService {

  // Submit Inspection
  Future<InspectSaveResult> submitInspection(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    // Negative tireId
    final rawTireId = data['tireId'];
    if (rawTireId != null) {
      final tireIdStr = rawTireId.toString();
      if (tireIdStr.startsWith('-')) {
        final realTireId = prefs.getInt('tyre_real_id_$tireIdStr');
        if (realTireId != null && realTireId > 0) {
          data['tireId'] = realTireId;
        }
      }
    }

    // Negative vehicleId
    final rawVehicleId = data['vehicleId'];
    if (rawVehicleId != null) {
      final vIdStr = rawVehicleId.toString();
      if (vIdStr.startsWith('-')) {
        final realVehicleId = prefs.getInt('vehicle_real_id_$vIdStr');
        if (realVehicleId != null && realVehicleId > 0) {
          data['vehicleId'] = realVehicleId;
        }
      }
    }

    final isOnline = await _checkOnline();

    if (isOnline) {
      try {
        final saved = await _callApi(data);
        if (saved != null) return saved;
      } catch (e) {
        ApiLog.error('Inspection/InspectTire', 'save failed -> $e (will queue offline)');
      }
    }

    // Offline fallback
    await OfflineHiveService.addPendingOperation(
      opType:     'inspectTyre',
      payload:    data,
      endpoint:   ApiConstants.inspectTire,
      httpMethod: 'PUT',
    );

    final vehicleId = data['vehicleId'];
    if (vehicleId != null) {
      await OfflineHiveService.updateTireInInspectionCache(
        vehicleId.toString(),
        data,
      );
    }

    throw _OfflineSavedException('Saved offline');
  }

  //  Call API
  Future<InspectSaveResult?> _callApi(Map<String, dynamic> data) async {
    final cookie = await _getCookieOrThrow();

    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.inspectTire}');

    ApiLog.request(
      name: 'Inspection/InspectTire',
      method: 'PUT',
      url: url,
      body: jsonEncode(data),
    );

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Accept":       "application/json",
        "Cookie":       cookie,
      },
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 20));

    ApiLog.response(
      name: 'Inspection/InspectTire',
      statusCode: response.statusCode,
      body: response.body,
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        if (decoded["didError"] == false) {
          final ids = ImageUploadService.extractInspectionIds(response.body);
          final tid = int.tryParse('${data['tireId']}');
          final inspectionId = ids[tid] ?? ids[0];
          ApiLog.info('Inspection/InspectTire',
              'inspectionId from save response -> $inspectionId');
          return InspectSaveResult(inspectionId: inspectionId);
        }
        throw Exception(decoded["errorMessage"] ?? "Inspection failed");
      }
      return const InspectSaveResult();
    }

    _handleAuthError(response.statusCode);
    throw Exception("InspectTyre failed (${response.statusCode})");
  }

  //  Get Tire by ID
  Future<Map<String, dynamic>> getTireById(int tireId) async {
    // Offline-created tyre (negative id) — Hive से लो
    if (tireId < 0) {
      final hiveTyre = OfflineHiveService.getTyreById(tireId);
      if (hiveTyre != null) return _mapHiveTyre(hiveTyre);
      throw Exception('Offline tyre data not found for tempId=$tireId');
    }

    final isOnline = await _checkOnline();

    if (isOnline) {
      try {
        final cookie = await _getCookieOrThrow();

        final url = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.getTyreById}$tireId',
        );

        final response = await http.get(
          url,
          headers: {"Accept": "application/json", "Cookie": cookie},
        ).timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded["didError"] == false) {
            await OfflineHiveService.saveTireDetailCache(
                tireId, response.body);
            return decoded["model"] ?? {};
          }
          throw Exception(
              decoded["errorMessage"] ?? "Failed to load tire");
        }

        _handleAuthError(response.statusCode);
        throw Exception("GetTireById failed (${response.statusCode})");
      } catch (_) {}
    }

    // Offline fallback
    final cached = OfflineHiveService.getTireDetailCache(tireId);
    if (cached != null) {
      try {
        final decoded = jsonDecode(cached);
        return (decoded['model'] as Map<String, dynamic>?) ?? {};
      } catch (_) {}
    }

    // Offline fallback
    final hiveTyre = OfflineHiveService.getTyreById(tireId);
    if (hiveTyre != null) return _mapHiveTyre(hiveTyre);

    throw Exception(
      'No offline data for tireId=$tireId. '
          'Please inspect this tire while online first.',
    );
  }

  // Upload tyre photos -> POST Tire/CreateImages (tireId + imgsrc).
  // Returns comma separated blob URLs (from response `message`),
  // or '' when nothing was uploaded.
  Future<String> uploadTireImages({
    required List<File> images,
    required int tireId,
  }) async {
    final res = await ImageUploadService.uploadTireImages(
      tireId: tireId,
      images: images,
    );
    return res.joined;
  }

  // Same as uploadTireImages but keeps the tyre's existing server photos
  // (they are sent again together with the new ones).
  Future<String> uploadTireImagesKeepingExisting({
    required List<File> newImages,
    required List<String> existingUrls,
    required int tireId,
  }) async {
    final res = await ImageUploadService.uploadTireImagesKeepingExisting(
      tireId: tireId,
      newImages: newImages,
      existingUrls: existingUrls,
    );
    return res.joined;
  }

  // Tire Inspection Images -> POST Inspection/CreateImages
  // (needs the inspectionId returned by the save step).
  Future<String> uploadInspectionImages({
    required List<File> images,
    required int? inspectionId,
  }) async {
    if (inspectionId == null || inspectionId <= 0) {
      ApiLog.error('Inspection/CreateImages',
          'ABORT -> inspectionId missing in save response, photos NOT uploaded');
      return '';
    }
    final res = await ImageUploadService.uploadInspectionImages(
      inspectionId: inspectionId,
      images: images,
    );
    return res.joined;
  }

  // Fetch Tire Images
  Future<List<String>> fetchTireImages(int tireId, {int? vehicleId}) async {
    try {
      final cookie = await _getCookieOrThrow();
      if (vehicleId == null || vehicleId <= 0) return [];

      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.listInspectionImages}?vehicleId=$vehicleId',
      );

      final response = await http.get(
        url,
        headers: {"Accept": "application/json", "Cookie": cookie},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['message'] is String) {
          final msg = (data['message'] as String).trim();
          if (msg.isEmpty) return [];
          return msg
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.startsWith('http'))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // HELPERS
  // Connectivity check
  Future<bool> _checkOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  // Cookie fetch
  Future<String> _getCookieOrThrow() async {
    final cookie = await SecureStorage.getCookie();
    if (cookie == null || cookie.isEmpty) {
      throw Exception("Authentication cookie missing");
    }
    return cookie;
  }

  // force logout
  void _handleAuthError(int statusCode) {
    if (statusCode == 401 || statusCode == 403) {
      Get.find<GlobalLogoutHandler>().forceLogout();
      throw Exception("Session expired.");
    }
  }

  Map<String, dynamic> _mapHiveTyre(dynamic hiveTyre) {
    return {
      'tireId':            hiveTyre.tireId,
      'tireSerialNo':      hiveTyre.serialNumber,
      'manufacturerId':    hiveTyre.manufacturerId,
      'sizeId':            hiveTyre.tireSizeId,
      'typeId':            hiveTyre.tireTypeId,
      'dispositionId':     hiveTyre.dispositionId,
      'vehicleId':         hiveTyre.vehicleId,
      'wheelPosition':     hiveTyre.wheelPosition,
      'outsideTread':      hiveTyre.outsideTread,
      'middleTread':       hiveTyre.middleTread,
      'insideTread':       hiveTyre.insideTread,
      'currentPressure':   hiveTyre.currentPressure,
      'currentTreadDepth': hiveTyre.currentTreadDepth,
      'currentHours':      hiveTyre.currentHours,
      'currentMiles':      hiveTyre.currentMiles,
    };
  }
}
class _OfflineSavedException implements Exception {
  final String message;
  _OfflineSavedException(this.message);
  @override String toString() => message;
}