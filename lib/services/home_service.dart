import 'dart:convert';
import 'package:emtrack/models/statical_model.dart';
import 'package:emtrack/services/api_constants.dart';
import 'package:emtrack/services/api_service.dart';
import 'package:emtrack/services/global_logout_handler.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models/home_model.dart';

class HomeService {
  static Future<List<Map<String, dynamic>>?> fetchVehicleRawList(
      String parentAccountId,
      ) async {
    try {
      final cookie = await SecureStorage.getCookie();
      if (cookie == null || cookie.isEmpty) return null;

      final uri = Uri.parse(
        "${ApiConstants.baseUrl}/api/Vehicle/GetVehicleByUser/$parentAccountId/0?timeStamp=0",
      );

      final resp = await http.get(
        uri,
        headers: {"Accept": "application/json", "Cookie": cookie},
      );


      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        if (json['didError'] == true) return null;
        final List list = json['model'] ?? [];
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> fetchTyreRawList(
      String parentAccountId,
      ) async {
    try {
      final cookie = await SecureStorage.getCookie();
      if (cookie == null) return null;

      final uri = Uri.parse(
        "${ApiConstants.baseUrl}/api/Tire/GetTiresByAccount/$parentAccountId",
      );

      final resp = await http.get(
        uri,
        headers: {"Content-Type": "application/json", "Cookie": cookie},
      );

      if (resp.statusCode == 401 || resp.statusCode == 403) {
        await SecureStorage.clearCookie();
        Get.find<GlobalLogoutHandler>().forceLogout();
        return null;
      }

      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        final List list = json['model'] ?? [];
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }


  static Future<HomeModel?> fetchHomeData() async {
    try {
      final cookie = await SecureStorage.getCookie();
      if (cookie == null || cookie.isEmpty) {
        throw Exception("Session expired. Please login again.");
      }

      final uri = Uri.parse("${ApiConstants.baseUrl}/api/Home");
      final resp = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Cookie": cookie,
        },
      );


      if (resp.statusCode == 401 || resp.statusCode == 403) {
        await SecureStorage.clearCookie();
        Get.find<GlobalLogoutHandler>().forceLogout();
        return null;
      }

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);

        if (decoded is String) {

          return await _buildHomeModelFromLocal();
        }

        if (decoded is Map<String, dynamic>) {
          final payload = decoded['data'] ?? decoded;
          if (payload is Map<String, dynamic>) {
            return HomeModel.fromJson(payload);
          }
        }

        return null;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<HomeModel?> _buildHomeModelFromLocal() async {
    try {
      final accountName = await SecureStorage.getParentAccountName() ?? '';
      final locationName = await SecureStorage.getLocationName() ?? '';
      final userName = await SecureStorage.getUserProfileName() ?? '';
      final userRole = await SecureStorage.getUserProfileRole() ?? '';



      return HomeModel(
        username: userName,
        parentAccount: accountName,
        location: locationName,
        role: userRole,
        lastInspection: '--',
        unsyncedInspections: 0,
        syncedInspections: 0,
        totalTyres: 0,
        vehicles: 0,
        appVersion: '1.0',
        imageUrl: '',
      );
    } catch (e) {
      return null;
    }
  }

  static Future<bool> syncInspections() async {
    try {
      final cookie = await SecureStorage.getCookie();
      if (cookie == null || cookie.isEmpty) {
        throw Exception("Session expired. Please login again.");
      }

      final uri = Uri.parse("${ApiConstants.baseUrl}/inspections/sync");
      final resp = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Cookie": cookie,
        },
      );

      if (resp.statusCode == 200) return true;

      if (resp.statusCode == 401 || resp.statusCode == 403) {
        await SecureStorage.clearCookie();
        Get.find<GlobalLogoutHandler>().forceLogout();
        return false;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<int> fetchTyreCountByAccount(String parentAccountId) async {
    try {
      final cookie = await SecureStorage.getCookie();
      if (cookie == null) return 0;

      final uri = Uri.parse(
        "${ApiConstants.baseUrl}/api/Tire/GetTiresByAccount/$parentAccountId",
      );

      final resp = await http.get(
        uri,
        headers: {"Content-Type": "application/json", "Cookie": cookie},
      );

      if (resp.statusCode == 401 || resp.statusCode == 403) {
        await SecureStorage.clearCookie();
        Get.find<GlobalLogoutHandler>().forceLogout();
        return 0;
      }

      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        final List list = json['model'] ?? [];
        return list.length;
      }

      return 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<int> fetchVehicleCountByAccount(String parentAccountId) async {
    try {
      final cookie = await SecureStorage.getCookie();
      if (cookie == null || cookie.isEmpty) return 0;

      final uri = Uri.parse(
        "${ApiConstants.baseUrl}/api/Vehicle/GetVehicleByUser/$parentAccountId/0?timeStamp=0",
      );


      final resp = await http.get(
        uri,
        headers: {"Accept": "application/json", "Cookie": cookie},
      );


      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        if (json['didError'] == true) {
          return 0;
        }
        final List list = json['model'] ?? [];
        return list.length;
      }

      return 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<DashboardModel?> fetchReportDashboardHomeData() async {
    final parentAccountId = await SecureStorage.getParentAccountId();
    if (parentAccountId == null || parentAccountId.isEmpty || parentAccountId == '0') {
      return null;
    }
    // ✅ Multi-location: agar user ne Change Account screen se multiple
    // locations select kiye hain, unn sabke IDs comma-joined bhejo taaki
    // dashboard counts saari selected locations ka combined total hon.
    // Koi multi-select save nahi hua ho (purana session) to yeh apne aap
    // single active location par fallback ho jaata hai.
    final selectedLocationIds = SecureStorage.getSelectedLocationIds();
    final locationIdsParam =
    selectedLocationIds.isNotEmpty ? selectedLocationIds.join(',') : "0";

    try {
      final cookie = await SecureStorage.getCookie();
      if (cookie == null || cookie.isEmpty) {
        throw Exception("Session expired. Please login again.");
      }

      final Map<String, dynamic> requestBody = {
        "accountIds": parentAccountId,
        "locationIds": locationIdsParam,
      };

      final resp = await ApiService.postApi(
        endpoint: "/api/Report/GetReportDashboardData",
        body: requestBody,
        timeoutSeconds: 30,
      );


      if (resp != null && resp['model'] != null) {
        final dashboard = DashboardModel.fromJson(resp["model"]);

        return dashboard;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }


  static Future<DashboardModel?> fetchReportDashboardHomeDataWithIds({
    required String accountId,
    required String locationId,
  }) async {
    final Map<String, dynamic> requestBody = {
      "accountIds": accountId,
      "locationIds": locationId,
    };

    // Ye endpoint account/location switch ke turant baad heavy aggregation
    // karta hai, isliye normal 20s se zyada time deते hain, aur agar
    // pehli try timeout ho jaye to ek baar silently retry karte hain
    // (turant error dikhane ke bajaye).
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        final cookie = await SecureStorage.getCookie();
        if (cookie == null || cookie.isEmpty) return null;

        final resp = await ApiService.postApi(
          endpoint: "/api/Report/GetReportDashboardData",
          body: requestBody,
          timeoutSeconds: 45,
        );

        if (resp != null && resp['model'] != null) {
          return DashboardModel.fromJson(resp["model"]);
        }
        print('🔧 [DASHBOARD_DEBUG] fetchReportDashboardHomeDataWithIds: '
            'resp=null-or-no-model -> resp=$resp');
        return null;
      } catch (e) {
        print('🔧 [DASHBOARD_DEBUG] fetchReportDashboardHomeDataWithIds '
            '(attempt $attempt): EXCEPTION -> $e');
        if (attempt == 2) return null;
        // agla attempt se pehle thoda ruk jao
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return null;
  }
}