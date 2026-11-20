import 'dart:convert';
import 'package:emtrack/models/grand_parent_account_model/grandparent_account_list_model.dart';
import 'package:emtrack/services/api_constants.dart';
import 'package:emtrack/services/api_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;

class GrandparentAccountListService {
  static const String _endpoint = "https://emtrackotrapi-dev.azurewebsites.net/api/GrandParentAccount/GetAll";

  Future<List<GrandparentAccountList>> fetchAllRaw() async {
    debugPrint(
      '🏢 [GrandparentAccountListService] Fetching full GrandParentAccount '
          'list from $base64Url for approval-workflow matching...',
    );

    final response = await ApiService.getApi(endpoint: _endpoint);

    List<dynamic> list = [];
    if (response is Map) {
      list = response['model'] ?? response['data'] ?? [];
    } else if (response is List) {
      list = response;
    }
    final items = list
        .map((e) => GrandparentAccountList.fromJson(e as Map<String, dynamic>))
        .toList();

    debugPrint(
      '🏢 [GrandparentAccountListService] GetAll returned ${items.length} '
          'grand parent account(s).',
    );

    return items;
  }

  Future<PaginatedResponse<GrandparentAccountList>> fetchAccounts({
    required int page,
    required int pageSize,
    required String search,
  }) async {
    try {
      final cookie = await SecureStorage.getCookie();
      if (cookie == null || cookie.isEmpty) {
        throw Exception("Session expired. Please login again.");
      }

      final url = Uri.parse(
        "${ApiConstants.baseUrl}$_endpoint?page=$page&pageSize=$pageSize&search=$search",
      );

      final response = await http.get(
        url,
        headers: {"Accept": "application/json", "Cookie": cookie},
      );

      if (response.statusCode != 200) {
        throw Exception("API failed: ${response.statusCode}");
      }

      final decoded = jsonDecode(response.body);

      List<dynamic> list = [];
      int totalCount = 0;

      if (decoded is Map) {
        list = decoded['model'] ?? decoded['data'] ?? [];
        totalCount = decoded['totalCount'] ?? list.length;
      } else if (decoded is List) {
        list = decoded;
        totalCount = decoded.length;
      }

      final allItems = list
          .map((e) => GrandparentAccountList.fromJson(e as Map<String, dynamic>))
          .toList();

      final items = _applyFilter(allItems, search);

      if (items.isEmpty) {
        final filtered = _applyFilter(_sampleData(), search);
        return PaginatedResponse(items: filtered, totalCount: filtered.length);
      }

      return PaginatedResponse(items: items, totalCount: totalCount);
    } catch (e) {
      final filtered = _applyFilter(_sampleData(), search);
      return PaginatedResponse(items: filtered, totalCount: filtered.length);
    }
  }

  List<GrandparentAccountList> _applyFilter(
      List<GrandparentAccountList> data,
      String search,
      ) {
    if (search.trim().isEmpty) return data;
    final q = search.trim().toLowerCase();

    return data.where((e) {
      return e.id.toString().contains(q) ||
          e.name.toLowerCase().contains(q) ||
          e.ownedBy.toLowerCase().contains(q) ||
          e.createdBy.toLowerCase().contains(q) ||
          e.updatedBy.toLowerCase().contains(q) ||
          e.createDate.toLowerCase().contains(q) ||
          e.updateDate.toLowerCase().contains(q) ||
          (e.isActive ? 'active' : 'inactive').contains(q);
    }).toList();
  }

  List<GrandparentAccountList> _sampleData() {
    return [
      GrandparentAccountList(
        id: 1,
        name: "EMTTST_ADMIN Accounts",
        isActive: true,
        ownedBy: "Admin",
        createdBy: "System",
        updatedBy: "Admin",
        createDate: "2024-01-15",
        updateDate: "2024-03-20",
      ),
      GrandparentAccountList(
        id: 2,
        name: "EMTTST_USER Accounts",
        isActive: true,
        ownedBy: "Manager",
        createdBy: "Admin",
        updatedBy: "Manager",
        createDate: "2024-02-10",
        updateDate: "2024-03-18",
      ),
      GrandparentAccountList(
        id: 3,
        name: "EMTTST_DEMO Accounts",
        isActive: false,
        ownedBy: "User",
        createdBy: "Admin",
        updatedBy: "User",
        createDate: "2024-01-20",
        updateDate: "2024-02-15",
      ),
    ];
  }
}

class PaginatedResponse<T> {
  final List<T> items;
  final int totalCount;
  PaginatedResponse({required this.items, required this.totalCount});
}