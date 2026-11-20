import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/password_reset_model.dart';
import '../utils/secure_storage.dart';
import 'api_constants.dart';

class PasswordResetService {

  Future<http.Response> resetPassword(PasswordResetModel model) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.resetPassword}',
    );

    final headers = await SecureStorage.authHeaders();

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(model.toJson()),
    );

    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      await SecureStorage.saveCookie(setCookie);
    }

    return response;
  }
}