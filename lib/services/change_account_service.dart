import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:emtrack/services/api_constants.dart';
import 'package:emtrack/services/global_logout_handler.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models/change_account_model.dart';

class ChangeAccountService {

  Future<List<ParentAccountModel>> fetchParentAccounts() async {
    try {
      final cookie = await SecureStorage.getCookie();
      if (cookie == null || cookie.isEmpty) {
        return _accountsFromHive();
      }

      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/ParentAccount/GetAccountList/0?timeStamp=0'),
        headers: {"Accept": "application/json", "Cookie": cookie},
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List list = decoded['model'] ?? [];
        final accounts = list.map((e) => ParentAccountModel.fromJson(e)).toList();

        if (accounts.isNotEmpty) {
          await OfflineHiveService.saveAccounts(
            accounts.map((a) => {
              'parentAccountId': a.parentAccountId,
              'accountName': a.accountName,
            }).toList(),
          );
        }
        return accounts;
      }

      if (res.statusCode == 401 || res.statusCode == 403) {
        if (Get.isRegistered<GlobalLogoutHandler>()) {
          Get.find<GlobalLogoutHandler>().forceLogout();
        }
        return [];
      }

      return _accountsFromHive();

    } catch (e) {
      return _accountsFromHive();
    }
  }

  Future<List<LocationModel>> fetchLocations(int parentAccountId) async {
    try {
      final cookie = await SecureStorage.getCookie();
      if (cookie == null || cookie.isEmpty) {
        return _locationsFromHive(parentAccountId);
      }

      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/Location/GetLocationList/$parentAccountId'),
        headers: {"Accept": "application/json", "Cookie": cookie},
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List list = decoded['model'] ?? [];
        final locations = list.map((e) => LocationModel.fromJson(e)).toList();

        if (locations.isNotEmpty) {
          await _mergeLocationsToHive(parentAccountId, locations);
        }
        return locations;
      }

      if (res.statusCode == 401 || res.statusCode == 403) {
        if (Get.isRegistered<GlobalLogoutHandler>()) {
          Get.find<GlobalLogoutHandler>().forceLogout();
        }
        return [];
      }

      return _locationsFromHive(parentAccountId);

    } catch (e) {
      return _locationsFromHive(parentAccountId);
    }
  }

  List<ParentAccountModel> _accountsFromHive() {
    final cached = OfflineHiveService.getAccounts();
    if (cached.isEmpty) {
      return [];
    }
    return cached.map((a) => ParentAccountModel(
      parentAccountId: a.parentAccountId,
      accountName: a.accountName,
      createdBy: '',
    )).toList();
  }

  List<LocationModel> _locationsFromHive(int parentAccountId) {
    final cached = OfflineHiveService.getLocations(parentAccountId: parentAccountId);
    if (cached.isEmpty) {
      return [];
    }
    return cached.map((l) => LocationModel(
      locationId: l.locationId,
      locationName: l.locationName,

    )).toList();
  }

  Future<void> _mergeLocationsToHive(
      int parentAccountId, List<LocationModel> fresh) async {
    final existing = OfflineHiveService.getLocations()
        .where((l) => l.parentAccountId != parentAccountId)
        .map((l) => {
      'locationId': l.locationId,
      'locationName': l.locationName,
      'parentAccountId': l.parentAccountId,
    })
        .toList();

    final newEntries = fresh.map((l) => {
      'locationId': l.locationId,
      'locationName': l.locationName,
      'parentAccountId': parentAccountId,
    }).toList();

    await OfflineHiveService.saveLocations([...existing, ...newEntries]);
  }

  Future<int> fetchAndSaveNoOfTreadDepthReadings(int locationId) async {
    try {
      final cookie = await SecureStorage.getCookie();
      if (cookie == null || cookie.isEmpty) {
        return SecureStorage.getNoOfTreadDepthReadings();
      }

      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/Location/GetLocationById/$locationId'),
        headers: {"Accept": "application/json", "Cookie": cookie},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final model = decoded['model'];
        if (model != null) {
          if (model['currency'] != null) {
            await SecureStorage.saveCurrency(model['currency'].toString());
          }
          final int count =
              (model['noOfTreadDepthReadings'] as num?)?.toInt() ?? 3;
          await SecureStorage.saveNoOfTreadDepthReadings(count);

          final double defaultRemoveAt =
              (model['defaultRemovalTreadDepth'] as num?)?.toDouble() ?? 0.0;
          await SecureStorage.saveDefaultRemovalTreadDepth(defaultRemoveAt);

          return count;
        }
      }
    } catch (e) {
    }
    return SecureStorage.getNoOfTreadDepthReadings();
  }

  Future<String?> fetchLocationCurrency(int locationId) async {
    try {
      final cookie = await SecureStorage.getCookie();
      if (cookie == null || cookie.isEmpty) return null;

      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/Location/GetLocationById/$locationId'),
        headers: {"Accept": "application/json", "Cookie": cookie},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final model = decoded['model'];
        if (model != null && model['currency'] != null) {
          return model['currency'].toString();
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> postAccountLocationChange({
    required String parentAccountId,
    required String locationId,
    required String userId,
  }) async {
    try {
      final cookie = await SecureStorage.getCookie();
      if (cookie == null || cookie.isEmpty) return false;

      final payload = {
        'userId': userId,
        'LastAccessedAccountId': int.tryParse(parentAccountId) ?? 0,
        'LastAccessedLocationId': int.tryParse(locationId) ?? 0,
        'updatedBy': userId,
        'updatedDate': DateTime.now().toUtc().toIso8601String(),
      };


      final uri = Uri.parse(ApiConstants.baseUrl + ApiConstants.updateLastAccessed);

      debugPrint('=== postAccountLocationChange ===');
      debugPrint('URL: $uri');
      debugPrint('Payload: ${jsonEncode(payload)}');
      debugPrint('Cookie exists: ${cookie.isNotEmpty}');

      final res = await http.put(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Cookie": cookie,
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      debugPrint('Response status: ${res.statusCode}');
      debugPrint('Response body: ${res.body}');

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('postAccountLocationChange ERROR: \$e');
      return false;
    }
  }
}