import 'dart:convert';
import 'package:emtrack/services/api_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:emtrack/utils/secure_storage.dart';
import 'package:emtrack/models/user_models.dart';
import 'package:emtrack/services/api_constants.dart';
import '../models/role/profile_model.dart';

class AuthService {

  static Future<UserModel?> login(String username, String password) async {
    final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.login);

    http.Response response;
    try {
      response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({"username": username, "password": password}),
      );
    } catch (e) {
      // If iOS blocked first attempt while user is accepting Wireless Data dialog, retry once
      debugPrint('⚠️ [AuthService] First login attempt failed ($e), retrying in 1s...');
      await Future.delayed(const Duration(milliseconds: 1000));
      response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({"username": username, "password": password}),
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      await SecureStorage.clearCookie();
      return null;
    }

    final rawCookie = response.headers['set-cookie'] ?? response.headers['Set-Cookie'];
    if (rawCookie != null) {
      String authCookie = rawCookie.split(';').first;
      await SecureStorage.saveCookie(authCookie);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) return null;

    final json = jsonDecode(response.body);
    if (json['message'] != null && json['message'].toString().toLowerCase().contains('access granted')) {
      return UserModel.fromJson(json);
    }
    return null;
  }
  static Future<bool> logout() async {
    final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.logout);
    final cookie = await SecureStorage.getCookie();

    final response = await http.post(
      url,
      headers: {if (cookie != null) 'Cookie': cookie},
    );

    await SecureStorage.clearCookie();


    return response.statusCode == 200;
  }

  /// GET /api/UserProfile
  /// Returns the logged-in user's profile, including the `isApprover`
  /// flag used to drive the Inspection Approval Flow:
  ///  - isApprover == true  -> user can directly approve/reject inspections
  ///  - isApprover == false/null -> inspection goes through approval flow
  static Future<UserProfile?> getUserprofile() async {
    debugPrint(
      '👤 [AuthService] GET ${ApiConstants.baseUrl}${ApiConstants.getUserProfile}',
    );

    final response = await ApiService.getApi(
      endpoint: ApiConstants.getUserProfile,
    );

    final json = response;

    if (json['model'] != null) {
      UserProfile user = UserProfile.fromJson(json['model']);

      debugPrint(
        '👤 [AuthService] UserProfile loaded -> userId: ${user.userId}, '
        'userRole: ${user.userRole}, isApprover: ${user.isApprover}',
      );

      return user;
    }

    debugPrint('👤 [AuthService] UserProfile response had no "model": $json');
    return null;
  }
}
