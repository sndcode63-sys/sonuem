import 'dart:convert';
import 'package:emtrack/services/api_constants.dart';
import 'package:emtrack/services/global_logout_handler.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class MasterDataService {
  static const _cacheDurationHours = 24;

  Future<Map<String, dynamic>> fetchMasterData({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _isCacheValid()) {
      return _buildMapFromHive();
    }

    try {
      final data = await fetchMasterDataFromApi();

      await OfflineHiveService.saveMasterData(data);

      return data;
    } catch (e) {
      final cachedJson = OfflineHiveService.getMasterDataJson();
      if (cachedJson != null) {
        try {
          final jsonMap = jsonDecode(cachedJson);
          final model = jsonMap['model'];
          if (model is Map<String, dynamic> && model.isNotEmpty) {
            return model;
          }
        } catch (jsonErr) {}
      }
      if (OfflineHiveService.hasMasterData()) {
        final fromHive = _buildMapFromHive();
        // Only use if has actual data
        if ((fromHive['tireManufacturers'] as List).isNotEmpty ||
            (fromHive['vehicleManufacturers'] as List).isNotEmpty) {
          return fromHive;
        }
      }
      rethrow;
    }
  }

  static const _cacheVersion = 'v3';

  bool _isCacheValid() {
    if (!OfflineHiveService.hasMasterData()) return false;

    final cached = OfflineHiveService.getMasterData();
    if (cached == null) return false;

    // Version check
    if (!cached.savedAt.startsWith('$_cacheVersion|')) return false;

    final hasVehicleData =
        cached.vehicleManufacturers.isNotEmpty ||
        cached.vehicleTypes.isNotEmpty;
    final hasTyreData =
        cached.tireManufacturers.isNotEmpty || cached.tireSizes.isNotEmpty;
    if (!hasVehicleData && !hasTyreData) {
      return false;
    }

    try {
      final savedAt = DateTime.parse(cached.savedAt.split('|').last);
      final age = DateTime.now().difference(savedAt);
      return age.inHours < _cacheDurationHours;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _buildMapFromHive() {
    return {
      'axleConfigs': OfflineHiveService.getAxleConfigs(),
      'starRating': OfflineHiveService.getStarRatings(),
      'plyRating': OfflineHiveService.getPlyRatings(),
      'casingCondition': OfflineHiveService.getCasingConditions(),
      'tireDispositions': OfflineHiveService.getTireDispositions(),
      'tireManufacturers': OfflineHiveService.getTireManufacturers(),
      'tireRemovalReasons': OfflineHiveService.getTireRemovalReasons(),
      'tireSizes': OfflineHiveService.getTireSizes(),
      'tireTypes': OfflineHiveService.getTireTypes(),
      'wearConditions': OfflineHiveService.getWearConditions(),
      'tireStatus': OfflineHiveService.getTireStatus(),
      'tireIndCodes': OfflineHiveService.getTireIndCodes(),
      'tireCompounds': OfflineHiveService.getTireCompounds(),
      'tireLoadRatings': OfflineHiveService.getTireLoadRatings(),
      'tireSpeedRatings': OfflineHiveService.getTireSpeedRatings(),
      'tireFillTypes': OfflineHiveService.getTireFillTypes(),
      'vehicleManufacturers': OfflineHiveService.getVehicleManufacturers(),
      'vehicleTypes': OfflineHiveService.getVehicleTypes(),
      'vehicleModels': OfflineHiveService.getVehicleModels(),
      'vehicleIcons': OfflineHiveService.getVehicleIcons(),
    };
  }

  Future<Map<String, dynamic>> fetchMasterDataFromApi() async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/api/MasterData/GetMasterDataMobile',
    );
    final cookie = await SecureStorage.getCookie();

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Cookie': ?cookie,
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['didError'] == true) {
        throw Exception(json['errorMessage'] ?? 'Unknown server error');
      }
      return json['model'] as Map<String, dynamic>;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      Get.find<GlobalLogoutHandler>().forceLogout();
      throw Exception('Session expired');
    }

    throw Exception('Master data failed (${response.statusCode})}');
  }

  Future<Map<String, dynamic>> refreshMasterData() async {
    return fetchMasterData(forceRefresh: true);
  }

  /// GET /api/MasterData/GetAllStatus (Inspection Approval Flow — Step 2)
  /// Returns cached status list if available and not forcing refresh,
  /// otherwise hits the API and refreshes the local Hive cache.
  Future<List<Map<String, dynamic>>> fetchStatusMaster({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && OfflineHiveService.hasStatusMaster()) {
      final cached = OfflineHiveService.getStatusMasterList();
      if (cached.isNotEmpty) return cached;
    }

    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getAllStatus}');
    debugPrint('➡️ [MasterDataService] GET $url');

    final cookie = await SecureStorage.getCookie();
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Cookie': ?cookie,
      },
    );

    debugPrint(
      '⬅️ [MasterDataService] GetAllStatus -> ${response.statusCode} from $url',
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty) {
        await OfflineHiveService.saveStatusMasterJson(response.body);
      }
      return OfflineHiveService.getStatusMasterList();
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      Get.find<GlobalLogoutHandler>().forceLogout();
      throw Exception('Session expired');
    }

    debugPrint(
      '❌ [MasterDataService] GetAllStatus failed (${response.statusCode}) at $url',
    );
    // Fall back to whatever is cached, even if stale/empty.
    return OfflineHiveService.getStatusMasterList();
  }

  Future<List<String>> fetchLanguageList() async {
    try {
      return List<String>.from(ApiConstants.languages);
    } catch (e) {
      return ['English'];
    }
  }

  Future<List<String>> fetchMeasurementSystems() async {
    try {
      return List<String>.from(ApiConstants.measurements);
    } catch (e) {
      return ['Metric', 'Imperial'];
    }
  }

  Future<List<String>> fetchPressureUnits() async {
    try {
      return List<String>.from(ApiConstants.pressureUnits);
    } catch (e) {
      return ['PSI', 'KPA', 'BAR'];
    }
  }
}
