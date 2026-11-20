import 'package:get/get.dart';
import 'hive_prefe.dart';

class GlobalPrefsState extends GetxController {
  static GlobalPrefsState get to => Get.find();

  final RxString measurement = 'Imperial'.obs;
  final RxString pressure = 'PSI'.obs;

  String get distanceLabel =>
      measurement.value.toLowerCase() == 'metric' ? 'KM' : 'Miles';

  bool get isMetric => measurement.value.toLowerCase() == 'metric';

  String get pressureLabel => pressure.value.toUpperCase();

  String get treadUnit => isMetric ? 'mm' : '/32nds';

  void loadFromHive() {
    final m = HivePref.get<String>('pref_measurement') ?? 'Imperial';
    final p = HivePref.get<String>('pref_pressure') ?? 'PSI';
    measurement.value = m;
    pressure.value = p;
  }

  void applyFromApi(String newMeasurement, String newPressure) {
    measurement.value = newMeasurement;
    pressure.value = newPressure;
    HivePref.set('pref_measurement', newMeasurement);
    HivePref.set('pref_pressure', newPressure);
  }
}
