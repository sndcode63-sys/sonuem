
import '../services/offline_hive_service.dart';

class LocalDatabaseService {
  static Future<void> saveTires(List<Map<String, dynamic>> list) async {
    await OfflineHiveService.saveTyres(list);
  }

  static Future<void> saveVehicles(List<Map<String, dynamic>> list) async {
    await OfflineHiveService.saveVehicles(list);
  }

  static Future<void> updateTireDisposition({
    required int tireId,
    required int dispositionId,
    required String dispositionName,
    String? wheelPosition,
    int? vehicleId,
  }) async {
    await OfflineHiveService.updateTyreDisposition(
      tireId: tireId,
      dispositionId: dispositionId,
      dispositionName: dispositionName,
      wheelPosition: wheelPosition,
      vehicleId: vehicleId,
    );
  }

  static Future<void> addPendingInstall(Map<String, dynamic> data) async {
    await OfflineHiveService.addPendingOperation(
      opType: 'installTyre',
      payload: data,
      endpoint: '/api/Inspection/InstallTire',
      httpMethod: 'POST',
    );
  }

  static Future<List<Map<String, dynamic>>> getPendingInstalls() async {
    return OfflineHiveService.getPendingOperations()
        .where((op) => op.opType == 'installTyre')
        .map((op) => Map<String, dynamic>.from(op.payload))
        .toList();
  }

  static Future<void> markInstallSynced(dynamic id) async {
    await OfflineHiveService.markOperationSynced(id.toString());
  }

  static Future<int> getPendingInstallsCount() async {
    return OfflineHiveService.getPendingOperations()
        .where((op) => op.opType == 'installTyre')
        .length;
  }

  static Future<void> addPendingOperation({
    required String opType,
    required Map<String, dynamic> payload,
    required String endpoint,
    String httpMethod = 'POST',
  }) async {
    await OfflineHiveService.addPendingOperation(
      opType: opType,
      payload: payload,
      endpoint: endpoint,
      httpMethod: httpMethod,
    );
  }

  static Future<List<Map<String, dynamic>>> getPendingOperations() async {
    return OfflineHiveService.getPendingOperations()
        .map((op) => {
      'id': op.id,
      'opType': op.opType,
      'payload': Map<String, dynamic>.from(op.payload),
      'endpoint': op.endpoint,
      'httpMethod': op.httpMethod,
      'retryCount': op.retryCount,
    })
        .toList();
  }

  static Future<void> markOperationSynced(dynamic id) async {
    await OfflineHiveService.markOperationSynced(id.toString());
  }

  static Future<void> incrementRetryCount(dynamic id) async {
    await OfflineHiveService.incrementRetryCount(id.toString());
  }

  static Future<int> getPendingOperationsCount() async {
    return OfflineHiveService.pendingOperationsCount();
  }

  static Future<int> getTotalPendingCount() async {
    return OfflineHiveService.pendingOperationsCount();
  }

  static Future<List<Map<String, dynamic>>> getAllTires({
    int? parentAccountId,
    int? locationId,
  }) async {
    return OfflineHiveService.getInventoryTyres(
      parentAccountId: parentAccountId,
      locationId: locationId,
    ).map((t) => t.toMap()).toList();
  }

  static Future<List<Map<String, dynamic>>> getVehicles({
    int? parentAccountId,
    int? locationId,
  }) async {
    return OfflineHiveService.getVehicles(
      parentAccountId: parentAccountId,
      locationId: locationId,
    ).map((v) => v.toMap()).toList();
  }

  static Future<List<Map<String, dynamic>>> getInventoryTires({
    int? parentAccountId,
    int? locationId,
  }) async {
    return getAllTires(
        parentAccountId: parentAccountId, locationId: locationId);
  }

  static Future<List<Map<String, dynamic>>> searchInventoryTires({
    required String query,
    int? parentAccountId,
    int? locationId,
  }) async {
    final all = await getInventoryTires(
        parentAccountId: parentAccountId, locationId: locationId);
    final q = query.toLowerCase().trim();
    return all.where((t) {
      return (t['serialNumber']?.toString().toLowerCase().contains(q) ?? false) ||
          (t['brandNo']?.toString().toLowerCase().contains(q) ?? false) ||
          (t['brandNumber']?.toString().toLowerCase().contains(q) ?? false) ||
          (t['manufacturerName']?.toString().toLowerCase().contains(q) ?? false) ||
          (t['tireSizeName']?.toString().toLowerCase().contains(q) ?? false);
    }).toList();
  }

  static Future<void> clearAll() async {
    await OfflineHiveService.clearAll();
  }

  static Future<void> close() async {
    await OfflineHiveService.closeAll();
  }
}