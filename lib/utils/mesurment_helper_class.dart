import 'package:get/get.dart';
import 'global_state_referesh.dart';
import 'hive_prefe.dart';

class MeasurementHelper {
  MeasurementHelper._();

  static const double _kmPerMile = 1.609344;
  static const double kmPerMile = _kmPerMile;


  // Web portal & backend factor: 1 /32nd = 0.79 mm (100 mm / 0.79 = 127)
  static const double _mmPer32nd = 0.79;

  static String get _rawMeasurement {
    if (Get.isRegistered<GlobalPrefsState>()) {
      return Get.find<GlobalPrefsState>().measurement.value;
    }
    return HivePref.get<String>('pref_measurement') ?? 'Imperial';
  }

  static String get distanceLabel =>
      _rawMeasurement.toLowerCase() == 'metric' ? 'KM' : 'Miles';

  static bool get isMetric => _rawMeasurement.toLowerCase() == 'metric';

  static bool get isImperial => !isMetric;

  static String get treadUnit => isMetric ? 'mm' : '/32nds';

  /// ✅ CORRECTED LOGIC FOR DISTANCE (KM / MILES):
  /// Agar user ne Imperial mode me tyre install kiya (e.g., 100 Miles), toh value raw save hogi.
  /// Jab user preferences me 'Metric' karega, tabhi $100 \times 1.609344 = 160.9344$ KM banega.
  ///
  /// IMPORTANT: `sourceUnit` yaha wahi unit honi chahiye jisme value
  /// ORIGINALLY save hui thi (TyreUnitHistory.getDistanceUnit(tireId) se
  /// lo) — CURRENT preference (MeasurementHelper.distanceLabel) yaha
  /// kabhi mat pass karo, warna conversion kabhi trigger nahi hoga
  /// (dono side same ho jaate hain — yehi purana bug tha).
  static double toDisplayDistance(double rawValue, {String? sourceUnit}) {
    // sourceUnit na diya ho (purana data / history missing) -> conversion
    // ke liye kuch bhi assume karna galat guess hoga, isliye as-is dikhate
    // hain (legacy-safe fallback).
    if (sourceUnit == null) return rawValue;

    final bool wasSavedAsImperial =
        sourceUnit.toLowerCase() == 'miles' ||
            sourceUnit.toLowerCase() == 'imperial';

    if (isImperial) {
      if (wasSavedAsImperial) {
        return rawValue; // Imperial me save kiya aur Imperial me hi dekh rahe hain -> As-is (e.g., 100 Miles)
      }
      return rawValue / _kmPerMile; // Metric (KM) me save kiya tha par ab Imperial me dekh rahe hain -> KM to Miles (exact)
    } else {
      if (wasSavedAsImperial) {
        return rawValue * _kmPerMile; // Imperial (Miles) me save kiya tha par ab Metric me dekh rahe hain -> Miles to KM (exact)
      }
      return rawValue; // Metric me save kiya aur Metric me hi dekh rahe hain -> As-is (e.g., 100 KM)
    }
  }

  static double toRawKm(double displayValue) {
    return displayValue; // Saving raw input directly as per your rule
  }

  /// ✅ CORRECTED LOGIC FOR TREAD DEPTH (TO/TM/TI):
  /// `sourceUnit` yaha bhi original-save-time ki unit honi chahiye
  /// (TyreUnitHistory.getTreadUnit(tireId)) — current unit nahi.
  /// Conversion ab exact fraction (1 inch = 25.4mm, 1/32" = 0.79375mm)
  /// se hota hai, purane approximate 1.26 multiplier ke bajaye.
  static double toDisplayTread(double rawValue, {String? sourceUnit}) {
    if (sourceUnit == null) return rawValue;

    final bool wasSavedAsImperial = sourceUnit == '/32nds' ||
        sourceUnit == '/32' ||
        sourceUnit.toLowerCase() == 'imperial';

    if (isImperial) {
      if (wasSavedAsImperial) {
        return rawValue; // /32nds me save, /32nds me dekh rahe -> as-is
      }
      return rawValue / _mmPer32nd; // mm me save, /32nds me dekh rahe -> mm to /32nds (exact)
    } else {
      if (wasSavedAsImperial) {
        return rawValue * _mmPer32nd; // /32nds me save, mm me dekh rahe -> /32nds to mm (exact)
      }
      return rawValue; // mm me save, mm me dekh rahe -> as-is
    }
  }

  /// Backend (GetAllPendingInspections) /32nds ko mm me 0.79 factor se
  /// convert karke deta hai (110 -> 86.90), 0.79375 se nahi. Isliye pending
  /// mm value ko wapas /32nds me laate waqt bhi wahi 0.79 use karo, warna
  /// 110 -> 109 ho jata hai.
  static const double backendMmPer32nd = 0.79;

  static double toDisplayTreadFromBackendMm(double mmValue) {
    return isImperial ? mmValue / backendMmPer32nd : mmValue;
  }

  static double toRawTread(double displayValue) {
    return displayValue;
  }

  /// ✅ NEW: PRESSURE CONVERSION (PSI / KPA / BAR)
  /// `sourceUnit` = wahi unit jisme value original save hui thi
  /// (TyreUnitHistory.getPressureUnit(tireId)) — current pressureLabel
  /// nahi. null hone par as-is dikhate hain (purana data / history missing).
  static double toDisplayPressure(double rawValue, {String? sourceUnit}) {
    if (sourceUnit == null) return rawValue;

    final String from = sourceUnit.toUpperCase();
    final String to = pressureLabel.toUpperCase();
    if (from == to) return rawValue;

    // Sab kuch pehle KPA me convert karo (common base unit), phir target me.
    double kpa;
    switch (from) {
      case 'BAR':
        kpa = rawValue * 100.0;
        break;
      case 'PSI':
        kpa = rawValue * 6.89476;
        break;
      case 'KPA':
      default:
        kpa = rawValue;
        break;
    }

    switch (to) {
      case 'BAR':
        return kpa / 100.0;
      case 'PSI':
        return kpa / 6.89476;
      case 'KPA':
      default:
        return kpa;
    }
  }

  static String get pressureLabel {
    if (Get.isRegistered<GlobalPrefsState>()) {
      return Get.find<GlobalPrefsState>().pressure.value.toUpperCase();
    }
    return (HivePref.get<String>('pref_pressure') ?? 'PSI').toUpperCase();
  }

  // ─────────────────────────────────────────────────────────────
  //  APPROVAL SAVE ke liye: canonical (backend pending) -> RAW input
  //  GetAllPendingInspections values canonical deta hai:
  //    pressure = PSI (100 BAR -> 1450 PSI), tread = mm (0.79 factor),
  //    distance = KM (100 Miles -> 160.93 KM).
  //  Lekin main DB me app hamesha user ka RAW typed number (100) save
  //  karta hai (unit alag se track hoti hai). Isliye approve/reject ke
  //  time canonical ko wapas RAW me laana zaroori hai, warna DB me
  //  1450 / 87 / 161 save ho jata hai.
  // ─────────────────────────────────────────────────────────────
  static double _r(double v, int d) {
    final f = _pow10(d);
    return (v * f).round() / f;
  }

  static double _pow10(int d) {
    double f = 1;
    for (var i = 0; i < d; i++) {
      f *= 10;
    }
    return f;
  }

  /// PSI (canonical) -> user ki current pressure preference ka raw number.
  /// Backend factors: 1 BAR = 14.5 PSI, 1 KPA = 0.145 PSI.
  static double canonicalPsiToRaw(double psi, {String? pressureUnit}) {
    if (psi == 0) return 0;
    switch ((pressureUnit ?? pressureLabel).toUpperCase()) {
      case 'BAR':
        return _r(psi / 14.5, 2);
      case 'KPA':
        return _r(psi / 0.145, 1);
      case 'PSI':
      default:
        return _r(psi, 2);
    }
  }

  /// mm (canonical, backend 0.79 factor) -> raw tread number.
  /// Imperial = whole /32nds, Metric = mm as-is.
  static double canonicalMmToRaw(double mm, {bool? imperial}) {
    if (mm == 0) return 0;
    if (imperial ?? isImperial) return (mm / backendMmPer32nd).roundToDouble();
    return _r(mm, 2);
  }

  /// KM (canonical) -> raw distance number (Miles ya KM, preference ke hisaab se).
  static double canonicalKmToRaw(double km, {bool? imperial}) {
    if (km == 0) return 0;
    final shown = (imperial ?? isImperial) ? km / _kmPerMile : km;
    return shown.roundToDouble();
  }

  // ─────────────────────────────────────────────────────────────
  //  LOCAL RAW -> CANONICAL (approval screen ke liye)
  //  Approval screen (vehicle.dart / iw tyre screen) pending values ko
  //  canonical (PSI / mm / KM) maan kar user ki preference me convert
  //  karke dikhati hai. Server se aayi pending values already canonical
  //  hoti hain, lekin device par local save hui values (SharedPreferences
  //  `pending_inspection_tires_*`, payload, Hive inspection cache — jo
  //  offline submit ke baad milti hain) RAW typed hoti hain (100 BAR /
  //  100 /32nds / 100 Miles). Unhe bina convert kiye dikhane par 100 ->
  //  7 BAR / 127 / 62 Miles jaisa galat dikhta tha. Backend factors:
  //  1 BAR = 14.5 PSI, 1 KPA = 0.145 PSI, 1 /32nd = 0.79 mm.
  // ─────────────────────────────────────────────────────────────
  static double rawPressureToCanonicalPsi(double v, {String? pressureUnit}) {
    if (v == 0) return 0;
    switch ((pressureUnit ?? pressureLabel).toUpperCase()) {
      case 'BAR':
        return _r(v * 14.5, 2);
      case 'KPA':
        return _r(v * 0.145, 2);
      case 'PSI':
      default:
        return _r(v, 2);
    }
  }

  static double rawTreadToCanonicalMm(double v, {bool? imperial}) {
    if (v == 0) return 0;
    return (imperial ?? isImperial) ? _r(v * backendMmPer32nd, 2) : _r(v, 2);
  }

  static double rawDistanceToCanonicalKm(double v, {bool? imperial}) {
    if (v == 0) return 0;
    return (imperial ?? isImperial) ? _r(v * _kmPerMile, 2) : _r(v, 2);
  }

  /// Local (device par saved) tyre JSON ke RAW values ko preserve karta hai.
  /// 🔧 FIX: Values must NOT be scaled (pressure, tread, distance) here.
  /// Scaling local raw JSON causes severe distortion:
  ///   - 100 BAR multiplied by 14.5 -> 1450
  ///   - 110 KM multiplied by 1.609 -> 177
  ///   - tread depths scaled -> 70 / 79
  /// Keeping RAW input ensures the exact values entered by the user are retained.
  static Map<String, dynamic> localRawTireJsonToCanonical(
      Map<String, dynamic> src) {
    return Map<String, dynamic>.from(src);
  }

  static void syncToGlobalState() {
    try {
      if (Get.isRegistered<GlobalPrefsState>()) {
        Get.find<GlobalPrefsState>().loadFromHive();
      }
    } catch (_) {}
  }
}

