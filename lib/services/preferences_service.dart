import 'dart:convert';
import 'package:emtrack/services/global_logout_handler.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:emtrack/models/preferences_model.dart';
import 'package:emtrack/models/country/country_response.dart';
import 'package:emtrack/services/api_constants.dart';
import 'package:emtrack/utils/secure_storage.dart';

class PreferencesService {
  static const String _updatePrefUrl =
      ApiConstants.baseUrl + ApiConstants.updatePreferences;

  static const String _getCountriesUrl =
      ApiConstants.baseUrl + ApiConstants.getAllCountryName;

  static const String _getPrefByUserIdBase =
      '${ApiConstants.baseUrl}/api/UserPreferences/GetUserPreferencesById/';

  Future<PreferencesModel?> fetchPreferences(String userId) async {
    final cookie = await SecureStorage.getCookie();
    if (cookie == null || cookie.isEmpty) {
      throw Exception('Auth cookie missing. Please login again.');
    }

    final url = Uri.parse('$_getPrefByUserIdBase$userId');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Cookie': cookie,
      },
    );


    if (response.statusCode == 401 || response.statusCode == 403) {
      Get.find<GlobalLogoutHandler>().forceLogout();
      return null;
    }

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json['model'] ?? json;
      if (data == null) return null;
      return PreferencesModel.fromJson(data as Map<String, dynamic>);
    }

    throw Exception(
      'Preferences GET failed (${response.statusCode}) => ${response.body}',
    );
  }

  Future<bool> updatePreferences(PreferencesModel model) async {
    final cookie = await SecureStorage.getCookie();
    final username = await SecureStorage.getUserName();

    if (cookie == null || cookie.isEmpty) {
      throw Exception('Auth cookie missing. Please login again.');
    }
    if (username == null || username.isEmpty) {
      throw Exception('UpdatedBy missing. Please login again.');
    }

    final body = {
      'UserId': username,
      'UpdatedBy': username,
      'UserLanguage': model.language,
      'UserMeasurementSystemValue': model.measurementSystem,
      'UserPressureUnit': model.pressureUnit,
      'userId': username,
      'updatedBy': username,
      'userLanguage': model.language,
      'userMeasurementSystemValue': model.measurementSystem,
      'userPressureUnit': model.pressureUnit,
      'LastAccessedAccountId': model.lastAccessedAccountId ?? 0,
      'LastAccessedLocationId': model.lastAccessedLocationId ?? 0,
      'LastAccessedAccountName': model.lastAccessedAccountName ?? '',
      'LastAccessedLocationName': model.lastAccessedLocationName ?? '',
      'LogoLocation': model.logoLocation ?? '',
      'UpdatedDate': model.updatedDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };


    final response = await http.put(
      Uri.parse(_updatePrefUrl),
      headers: {'Content-Type': 'application/json', 'Cookie': cookie},
      body: jsonEncode(body),
    );



    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }
    throw Exception(
      'Preferences Update failed (${response.statusCode}) => ${response.body}',
    );
  }

  Future<CountryResponse> getCountries() async {
    final cookie = await SecureStorage.getCookie();
    if (cookie == null || cookie.isEmpty) {
      throw Exception('Auth cookie missing');
    }

    final response = await http.get(
      Uri.parse(_getCountriesUrl),
      headers: {'Content-Type': 'application/json', 'Cookie': cookie},
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      Get.find<GlobalLogoutHandler>().forceLogout();
      return getCountries();
    }

    if (response.statusCode == 200) {
      return CountryResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception(
      'Country API failed (${response.statusCode}) => ${response.body}',
    );
  }
}