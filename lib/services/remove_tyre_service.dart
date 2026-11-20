import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emtrack/models/masterDataMobileModel/Tire_remove_reason_model.dart';
import 'package:emtrack/models/masterDataMobileModel/tire_desposition_model.dart';
import 'package:emtrack/models/masterDataMobileModel/master_model.dart';
import 'package:emtrack/services/api_constants.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RemoveTyreService {
  static MasterModel? _cachedMaster;

  Future<bool> submitRemoveTyre(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

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

    final results = await Connectivity().checkConnectivity();
    final isOnline = results.any((r) => r != ConnectivityResult.none);


    if (isOnline) {
      try {
        final ok = await _callApi(data);
        if (ok) {

          final rawTId = data['tireId'];
          if (rawTId != null) {
            final tId = rawTId is int ? rawTId : (int.tryParse(rawTId.toString()) ?? 0);
            if (tId > 0) OfflineHiveService.markTireAsRecentlyRemoved(tId);
          }
          await _updateLocalOnRemove(data);
          return true;
        }
      } catch (e) {
      }
    } else {
    }

    await OfflineHiveService.addPendingOperation(
      opType: 'removeTyre',
      payload: data,
      endpoint: '/api/Inspection/RemoveTire',
      httpMethod: 'PUT',
    );
    await _updateLocalOnRemove(data);
    throw _OfflineSavedException('Saved offline');
  }

  Future<void> _updateLocalOnRemove(Map<String, dynamic> data) async {
    final tireId = data['tireId'];
    final vehicleId = data['vehicleId'];

    final rawDispName = (data['dispositionName']?.toString() ?? '').trim();
    final rawDispId = data['dispositionId'];

    final dispId = rawDispName.isNotEmpty
        ? _dispositionNameToId(rawDispName)
        : (rawDispId is int
        ? rawDispId
        : (int.tryParse(rawDispId.toString()) ?? 8));

    final dispName = rawDispName.isNotEmpty
        ? rawDispName
        : _dispositionIdToName(dispId);

    if (tireId != null) {
      final tId = tireId is int ? tireId : int.tryParse(tireId.toString());
      if (tId != null && tId > 0) {
        await OfflineHiveService.updateTyreDisposition(
          tireId: tId,
          dispositionId: dispId,
          dispositionName: dispName,
          wheelPosition: null,
          vehicleId: null,
        );
      }
    }
    if (vehicleId != null) {
      final vId = vehicleId is int
          ? vehicleId
          : int.tryParse(vehicleId.toString());
      if (vId != null && vId > 0) {
        await OfflineHiveService.updateVehicleTireCount(vId, -1);

      }
    }
  }

  int _dispositionNameToId(String name) {
    final normalized = name.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');
    switch (normalized) {
      case 'scrap':     return 1;
      case 'repair':    return 2;
      case 'retread':   return 3;
      case 'onhold':    return 4;
      case 'installed': return 7;
      case 'inventory': return 8;
      default:          return 8;
    }
  }

  String _dispositionIdToName(int id) {
    switch (id) {
      case 1:  return 'Scrap';
      case 2:  return 'Repair';
      case 3:  return 'Retread';
      case 4:  return 'On Hold';
      case 7:  return 'Installed';
      case 8:  return 'Inventory';
      default: return 'Inventory';
    }
  }

  Future<bool> _callApi(Map<String, dynamic> data) async {
    final url = Uri.parse("${ApiConstants.baseUrl}/api/Inspection/RemoveTire");
    final cookies = await SecureStorage.getCookie();

    final cleanData = Map<String, dynamic>.from(data);
    final rim = cleanData['rimDispositionId'];
    if (rim == null || rim == '' || rim.toString().isEmpty) {
      cleanData['rimDispositionId'] = 0;
    } else {
      cleanData['rimDispositionId'] = rim is int
          ? rim
          : (int.tryParse(rim.toString()) ?? 0);
    }

    final body = jsonEncode([cleanData]);

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          if (cookies != null) "Cookie": cookies,
        },
        body: body,
      ).timeout(const Duration(seconds: 30));


      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['didError'] == true) {
            return false;
          }
        } catch (_) {}
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  Future<MasterModel?> getMasterData() async {
    if (_cachedMaster != null) {
      return _cachedMaster;
    }

    final cachedJson = OfflineHiveService.getMasterDataJson();
    if (cachedJson != null) {
      try {
        final jsonMap = jsonDecode(cachedJson);
        if (jsonMap["model"] != null) {
          _cachedMaster = MasterModel.fromJson(jsonMap["model"]);
          return _cachedMaster;
        }
      } catch (e) {
      }
    }

    try {
      final results = await Connectivity().checkConnectivity();
      final isOnline = results.any((r) => r != ConnectivityResult.none);

      if (isOnline) {
        final url = Uri.parse("${ApiConstants.baseUrl}/api/MasterData/GetMasterDataMobile");
        final cookies = await SecureStorage.getCookie();
        if (cookies == null || cookies.isEmpty) throw Exception("No cookie");

        final response = await http
            .get(url, headers: {
          "Content-Type": "application/json",
          "Cookie": cookies,
        })
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic> && data["model"] != null) {
            await OfflineHiveService.saveMasterDataJson(response.body);
            _cachedMaster = MasterModel.fromJson(data["model"]);
            return _cachedMaster;
          }
        }
      }
    } catch (e) {
    }

    return null;
  }

  Future<List<TireRemovalReason>> getRemovalReason() async {
    final hiveReasons = OfflineHiveService.getTireRemovalReasons();
    if (hiveReasons.isNotEmpty) {
      try {
        return hiveReasons
            .map((e) => TireRemovalReason.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {}
    }
    final master = await getMasterData();
    if (master == null) return [];
    return master.tireRemovalReasons;
  }

  Future<List<TireDisposition>> getDispositions() async {
    final hiveDisp = OfflineHiveService.getTireDispositions();
    if (hiveDisp.isNotEmpty) {
      try {
        return hiveDisp
            .map((e) => TireDisposition.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {}
    }
    final master = await getMasterData();
    if (master == null) return [];
    return master.tireDispositions;
  }
}

class _OfflineSavedException implements Exception {
  final String message;
  _OfflineSavedException(this.message);
  @override
  String toString() => message;
}