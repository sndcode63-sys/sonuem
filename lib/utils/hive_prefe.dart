import 'package:hive/hive.dart';

class HivePref {
  static final box = Hive.box('preferencesBox');

  static void set(String key, dynamic value) {
    box.put(key, value);
  }

  static T? get<T>(String key) {
    return box.get(key);
  }

  static const String offlineVehicleKey = "offline_vehicles";

  static Future<void> saveOfflineVehicle(Map<String, dynamic> data) async {
    final box = await Hive.openBox(offlineVehicleKey);

    final List list =
    box.get(offlineVehicleKey, defaultValue: []) as List;

    list.add({
      "data": data,
      "createdAt": DateTime.now().toIso8601String(),
    });

    await box.put(offlineVehicleKey, list);

  }

  static Future<List> getOfflineVehicles() async {
    final box = await Hive.openBox(offlineVehicleKey);
    return box.get(offlineVehicleKey, defaultValue: []) as List;
  }

  static Future<void> clearOfflineVehicles() async {
    final box = await Hive.openBox(offlineVehicleKey);
    await box.put(offlineVehicleKey, []);
  }
}