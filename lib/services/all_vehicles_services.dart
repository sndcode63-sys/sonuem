import 'dart:convert';
import 'package:emtrack/services/global_logout_handler.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models/all_vehicle_account_model.dart';
import '../utils/secure_storage.dart';
import 'api_constants.dart';

class AllVehicleService {
  Future<List<AccountVehicleModel>> getVehiclesByAccount({
    required int parentAccountId,
    int pageNumber = 0,
    int timeStamp = 0,
  }) async {
    try {
      if (parentAccountId == 0) {
        throw Exception("Invalid parentAccountId");
      }

      final cookie = await SecureStorage.getCookie();
      if (cookie == null || cookie.isEmpty) {
        throw Exception("Session expired. Please login again.");
      }

      final url = Uri.parse(
        "${ApiConstants.baseUrl}/api/Vehicle/GetVehicleByUser/$parentAccountId/$pageNumber?timeStamp=$timeStamp",
      );

      final response = await http.get(
        url,
        headers: {"Accept": "application/json", "Cookie": cookie},
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        Get.find<GlobalLogoutHandler>().forceLogout();
        return [];
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded == null) {
          return [];
        }

        if (decoded['didError'] == true) {
          return [];
        }

        if (decoded['model'] == null) {
          return [];
        }

        final List list = decoded['model'];
        final vehicles = list
            .map((e) => AccountVehicleModel.fromJson(e as Map<String, dynamic>))
            .toList();

        return vehicles;
      }


      throw Exception("Failed to load vehicles (${response.statusCode})");
    } catch (e, s) {
      rethrow;
    }
  }
}
