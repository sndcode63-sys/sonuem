import 'dart:convert';
import 'dart:io';
import 'package:emtrack/services/api_constants.dart';
import 'package:emtrack/services/auth_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:emtrack/routes/app_pages.dart';

class ApiService {

  // ─── DEBUG LOGGING ───────────────────────────────────────────────────
  // Logs the FULL request URL + method + (truncated) body/response for
  // every API call so issues can be traced from the console during
  // development/QA. Safe no-op in release builds (debugPrint is stripped).
  static void _logRequest(String method, Uri url, {Map<String, dynamic>? body}) {
    debugPrint('➡️ [API REQUEST] $method $url'
        '${body != null ? '\n   body: ${jsonEncode(body)}' : ''}');
  }

  static void _logResponse(String method, Uri url, http.Response response) {
    final preview = response.body.length > 500
        ? '${response.body.substring(0, 500)}…(truncated)'
        : response.body;
    debugPrint('⬅️ [API RESPONSE] $method $url'
        '\n   status: ${response.statusCode}'
        '\n   body: $preview');
  }

  static Future<bool> _attemptSilentLogin() async {
    final user = await SecureStorage.getUserName();
    final pass = await SecureStorage.getPassword();
    if (user != null && pass != null) {
      try {
        final result = await AuthService.login(user, pass);
        return result != null;
      } catch (e) {
        return false;
      }
    }
    return false;
  }


  static bool _isNetworkError(dynamic e) {
    return e is SocketException ||
        e is HttpException ||
        e.toString().contains('Connection refused') ||
        e.toString().contains('Network is unreachable') ||
        e.toString().contains('Failed host lookup') ||
        e.toString().contains('TimeoutException');
  }

  // ─── POST API ───
  static Future<dynamic> postApi({
    required String endpoint,
    required Map<String, dynamic> body,
    int timeoutSeconds = 10,
  }) async {
    final url = Uri.parse(ApiConstants.baseUrl + endpoint);
    var cookie = await SecureStorage.getCookie();

    http.Response response;

    _logRequest('POST', url, body: body);

    try {
      response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
        },
        body: jsonEncode(body),
      ).timeout(Duration(seconds: timeoutSeconds));
      _logResponse('POST', url, response);
    } catch (e) {
      debugPrint('❌ [API ERROR] POST $url -> $e');
      if (_isNetworkError(e)) {
        throw Exception("Network unavailable: $e");
      }
      rethrow;
    }


    if (response.statusCode == 401 || response.statusCode == 403) {
      final success = await _attemptSilentLogin();
      if (success) {
        cookie = await SecureStorage.getCookie();
        try {
          _logRequest('POST (retry)', url, body: body);
          response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
            },
            body: jsonEncode(body),
          ).timeout(Duration(seconds: timeoutSeconds));
          _logResponse('POST (retry)', url, response);
        } catch (e) {
          debugPrint('❌ [API ERROR] POST (retry) $url -> $e');
          if (_isNetworkError(e)) throw Exception("Network unavailable: $e");
          rethrow;
        }
      } else {

        if (Get.currentRoute != AppPages.LOGIN) {
          Get.offAllNamed(AppPages.LOGIN);
        }
        throw Exception("Session Expired");
      }
    }

    if (response.body.isEmpty) return {};
    return jsonDecode(response.body);
  }

  // ─── GET API ───
  static Future<dynamic> getApi({
    required String endpoint,
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse(ApiConstants.baseUrl + endpoint)
        .replace(queryParameters: queryParams);
    var cookie = await SecureStorage.getCookie();

    http.Response response;

    _logRequest('GET', uri);

    try {
      response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
        },
      ).timeout(const Duration(seconds: 10));
      _logResponse('GET', uri, response);
    } catch (e) {
      debugPrint('❌ [API ERROR] GET $uri -> $e');
      if (_isNetworkError(e)) {
        throw Exception("Network unavailable: $e");
      }
      rethrow;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      final success = await _attemptSilentLogin();
      if (success) {
        cookie = await SecureStorage.getCookie();
        try {
          _logRequest('GET (retry)', uri);
          response = await http.get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
            },
          ).timeout(const Duration(seconds: 10));
          _logResponse('GET (retry)', uri, response);
        } catch (e) {
          debugPrint('❌ [API ERROR] GET (retry) $uri -> $e');
          if (_isNetworkError(e)) throw Exception("Network unavailable: $e");
          rethrow;
        }
      } else {
        if (Get.currentRoute != AppPages.LOGIN) {
          Get.offAllNamed(AppPages.LOGIN);
        }
        throw Exception("Session Expired");
      }
    }

    if (response.body.isEmpty) return {};
    return jsonDecode(response.body);
  }

  // ─── DELETE API ───
  static Future<dynamic> deleteApi({
    required String endpoint,
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse(ApiConstants.baseUrl + endpoint);
    var cookie = await SecureStorage.getCookie();

    Future<http.Response> _send() async {
      final request = http.Request('DELETE', url);
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
      });
      if (body != null) request.body = jsonEncode(body);
      final streamedResponse = await request.send()
          .timeout(const Duration(seconds: 20));
      return await http.Response.fromStream(streamedResponse);
    }

    http.Response response;
    _logRequest('DELETE', url, body: body);
    try {
      response = await _send();
      _logResponse('DELETE', url, response);
    } catch (e) {
      debugPrint('❌ [API ERROR] DELETE $url -> $e');
      if (_isNetworkError(e)) {
        throw Exception("Network unavailable: $e");
      }
      rethrow;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      final success = await _attemptSilentLogin();
      if (success) {
        cookie = await SecureStorage.getCookie();
        try {
          _logRequest('DELETE (retry)', url, body: body);
          response = await _send();
          _logResponse('DELETE (retry)', url, response);
        } catch (e) {
          debugPrint('❌ [API ERROR] DELETE (retry) $url -> $e');
          if (_isNetworkError(e)) throw Exception("Network unavailable: $e");
          rethrow;
        }
      } else {
        if (Get.currentRoute != AppPages.LOGIN) {
          Get.offAllNamed(AppPages.LOGIN);
        }
        throw Exception("Session Expired");
      }
    }

    if (response.body.isEmpty) return {};
    return jsonDecode(response.body);
  }

  // ─── PUT API ───
  // Used for "Update" style endpoints (e.g. /api/UserProfile/Update) that
  // return 405 Method Not Allowed when called with POST.
  static Future<dynamic> putApi({
    required String endpoint,
    required Map<String, dynamic> body,
    int timeoutSeconds = 20,
  }) async {
    final url = Uri.parse(ApiConstants.baseUrl + endpoint);
    var cookie = await SecureStorage.getCookie();

    http.Response response;

    _logRequest('PUT', url, body: body);

    try {
      response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
        },
        body: jsonEncode(body),
      ).timeout(Duration(seconds: timeoutSeconds));
      _logResponse('PUT', url, response);
    } catch (e) {
      debugPrint('❌ [API ERROR] PUT $url -> $e');
      if (_isNetworkError(e)) {
        throw Exception("Network unavailable: $e");
      }
      rethrow;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      final success = await _attemptSilentLogin();
      if (success) {
        cookie = await SecureStorage.getCookie();
        try {
          _logRequest('PUT (retry)', url, body: body);
          response = await http.put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
            },
            body: jsonEncode(body),
          ).timeout(Duration(seconds: timeoutSeconds));
          _logResponse('PUT (retry)', url, response);
        } catch (e) {
          debugPrint('❌ [API ERROR] PUT (retry) $url -> $e');
          if (_isNetworkError(e)) throw Exception("Network unavailable: $e");
          rethrow;
        }
      } else {
        if (Get.currentRoute != AppPages.LOGIN) {
          Get.offAllNamed(AppPages.LOGIN);
        }
        throw Exception("Session Expired");
      }
    }

    if (response.body.isEmpty) return {};
    return jsonDecode(response.body);
  }
}