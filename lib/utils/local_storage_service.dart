
import '../services/offline_hive_service.dart';

class LocalStorageService {
  static Future<void> saveMasterData(Map<String, dynamic> data) async {
    await OfflineHiveService.saveMasterData(data);
  }

  static Future<Map<String, dynamic>?> getMasterData() async {
    final m = OfflineHiveService.getMasterData();
    if (m == null) return null;
    return {
      'axleConfigs': m.axleConfigs,
      'starRating': m.starRatings,
      'plyRating': m.plyRatings,
      'casingCondition': m.casingConditions,
      'tireDispositions': m.tireDispositions,
      'tireManufacturers': m.tireManufacturers,
      'tireRemovalReasons': m.tireRemovalReasons,
      'tireSizes': m.tireSizes,
      'tireTypes': m.tireTypes,
      'wearConditions': m.wearConditions,
      'savedAt': m.savedAt,
    };
  }

  static Future<void> saveVehicles(List<Map<String, dynamic>> list) async {
    await OfflineHiveService.saveVehicles(list);
  }

  static Future<List<Map<String, dynamic>>> getVehicles() async {
    return OfflineHiveService.getVehicles().map((v) => v.toMap()).toList();
  }

  static Future<void> saveAccounts(List<Map<String, dynamic>> list) async {
    await OfflineHiveService.saveAccounts(list);
  }

  static Future<List<Map<String, dynamic>>> getAccounts() async {
    return OfflineHiveService.getAccounts()
        .map((a) => {
      'parentAccountId': a.parentAccountId,
      'accountName': a.accountName,
    })
        .toList();
  }

  static Future<void> saveLocations(List<Map<String, dynamic>> list) async {
    await OfflineHiveService.saveLocations(list);
  }

  static Future<List<Map<String, dynamic>>> getLocations() async {
    return OfflineHiveService.getLocations()
        .map((l) => {
      'locationId': l.locationId,
      'locationName': l.locationName,
      'parentAccountId': l.parentAccountId,
    })
        .toList();
  }

  static Future<void> saveTyres(List<Map<String, dynamic>> list) async {
    await OfflineHiveService.saveTyres(list);
  }

  static Future<List<Map<String, dynamic>>> getTyres() async {
    return OfflineHiveService.getInventoryTyres().map((t) => t.toMap()).toList();
  }

  static Future<String?> getLastSyncedAt() async {
    return OfflineHiveService.getMasterData()?.savedAt;
  }

  static Future<void> clearAll() async {
    await OfflineHiveService.clearAll();
  }
}