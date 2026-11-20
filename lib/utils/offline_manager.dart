

import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/offline_hive_service.dart';

class OfflineManager {
  static Future<bool> isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  static int generateTempId() => -DateTime.now().millisecondsSinceEpoch;

  static Future<int> saveOfflineVehicle(Map<String, dynamic> data) async {
    final tempKey = await OfflineHiveService.saveOfflineVehicle(data);

    await OfflineHiveService.addPendingOperation(
      opType: 'createVehicle',
      payload: data,
      endpoint: '/api/Vehicle/Create',
      httpMethod: 'POST',
    );

    return int.tryParse(tempKey) ?? generateTempId();
  }

  static Future<int> saveOfflineTyre(Map<String, dynamic> data) async {
    final tempKey = await OfflineHiveService.saveOfflineTyre(data);

    await OfflineHiveService.addPendingOperation(
      opType: 'createTyre',
      payload: data,
      endpoint: '/api/Tire',
      httpMethod: 'POST',
    );

    return int.tryParse(tempKey) ?? generateTempId();
  }

  static int pendingCount() => OfflineHiveService.pendingOperationsCount();
}