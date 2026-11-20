import 'package:hive/hive.dart';
import 'hive_prefe.dart';

class TyreUnitHistory {
  TyreUnitHistory._();
  static Box get _box => HivePref.box;
  static String _distanceKey(dynamic tireId) => 'unit_hist_${tireId}_distance';
  static String _treadKey(dynamic tireId) => 'unit_hist_${tireId}_tread';
  static String _pressureKey(dynamic tireId) => 'unit_hist_${tireId}_pressure';
  static String _pctKey(dynamic tireId) => 'unit_hist_${tireId}_pct';
  static String _rawOutsideKey(dynamic tireId) => 'unit_hist_${tireId}_raw_to';
  static String _rawMiddleKey(dynamic tireId) => 'unit_hist_${tireId}_raw_tm';
  static String _rawInsideKey(dynamic tireId) => 'unit_hist_${tireId}_raw_ti';
  static String _rawPressureKey(dynamic tireId) => 'unit_hist_${tireId}_raw_p';
  static String _rawMilesKey(dynamic tireId) => 'unit_hist_${tireId}_raw_m';

  static void recordDistanceUnit(dynamic tireId, String measurementSystem) {
    if (tireId == null) return;
    _box.put(_distanceKey(tireId), measurementSystem);
  }

  static void recordTreadUnit(dynamic tireId, String measurementSystem) {
    if (tireId == null) return;
    _box.put(_treadKey(tireId), measurementSystem);
  }

  static void recordPressureUnit(dynamic tireId, String pressureUnit) {
    if (tireId == null) return;
    _box.put(_pressureKey(tireId), pressureUnit);
  }

  static void recordPercentageWorn(dynamic tireId, num? pct) {
    if (tireId == null || pct == null) return;
    _box.put(_pctKey(tireId), pct.toDouble());
  }

  static void recordRawReadings({
    required dynamic tireId,
    num? outside,
    num? middle,
    num? inside,
    num? pressure,
    num? miles,
    num? percentageWorn,
    String? treadUnit,
    String? pressureUnit,
    String? distanceUnit,
  }) {
    if (tireId == null) return;
    if (outside != null && outside > 0) _box.put(_rawOutsideKey(tireId), outside.toDouble());
    if (middle != null && middle > 0) _box.put(_rawMiddleKey(tireId), middle.toDouble());
    if (inside != null && inside > 0) _box.put(_rawInsideKey(tireId), inside.toDouble());
    if (pressure != null && pressure > 0) _box.put(_rawPressureKey(tireId), pressure.toDouble());
    if (miles != null && miles > 0) _box.put(_rawMilesKey(tireId), miles.toDouble());
    if (percentageWorn != null && percentageWorn >= 0) _box.put(_pctKey(tireId), percentageWorn.toDouble());
    if (treadUnit != null && treadUnit.isNotEmpty) recordTreadUnit(tireId, treadUnit);
    if (pressureUnit != null && pressureUnit.isNotEmpty) recordPressureUnit(tireId, pressureUnit);
    if (distanceUnit != null && distanceUnit.isNotEmpty) recordDistanceUnit(tireId, distanceUnit);
  }

  static double? getRawOutside(dynamic tireId) {
    if (tireId == null) return null;
    final v = _box.get(_rawOutsideKey(tireId));
    return (v is num) ? v.toDouble() : null;
  }

  static double? getRawMiddle(dynamic tireId) {
    if (tireId == null) return null;
    final v = _box.get(_rawMiddleKey(tireId));
    return (v is num) ? v.toDouble() : null;
  }

  static double? getRawInside(dynamic tireId) {
    if (tireId == null) return null;
    final v = _box.get(_rawInsideKey(tireId));
    return (v is num) ? v.toDouble() : null;
  }

  static double? getRawPressure(dynamic tireId) {
    if (tireId == null) return null;
    final v = _box.get(_rawPressureKey(tireId));
    return (v is num) ? v.toDouble() : null;
  }

  static double? getRawMiles(dynamic tireId) {
    if (tireId == null) return null;
    final v = _box.get(_rawMilesKey(tireId));
    return (v is num) ? v.toDouble() : null;
  }

  static double? getPercentageWorn(dynamic tireId) {
    if (tireId == null) return null;
    final v = _box.get(_pctKey(tireId));
    return (v is num) ? v.toDouble() : null;
  }

  static String? getDistanceUnit(dynamic tireId) {
    if (tireId == null) return null;
    return _box.get(_distanceKey(tireId)) as String?;
  }

  static String? getTreadUnit(dynamic tireId) {
    if (tireId == null) return null;
    return _box.get(_treadKey(tireId)) as String?;
  }

  static String? getPressureUnit(dynamic tireId) {
    if (tireId == null) return null;
    return _box.get(_pressureKey(tireId)) as String?;
  }

  // ─────────────────────────────────────────────────────────────
  //  PRE-INSPECTION BACKUP & ROLLBACK (FOR REJECTION HANDLING)
  // ─────────────────────────────────────────────────────────────
  static String _bakOutsideKey(dynamic tireId) => 'unit_hist_${tireId}_bak_to';
  static String _bakMiddleKey(dynamic tireId) => 'unit_hist_${tireId}_bak_tm';
  static String _bakInsideKey(dynamic tireId) => 'unit_hist_${tireId}_bak_ti';
  static String _bakPressureKey(dynamic tireId) => 'unit_hist_${tireId}_bak_p';
  static String _bakMilesKey(dynamic tireId) => 'unit_hist_${tireId}_bak_m';
  static String _bakPctKey(dynamic tireId) => 'unit_hist_${tireId}_bak_pct';
  static String _bakTreadUnitKey(dynamic tireId) => 'unit_hist_${tireId}_bak_tu';
  static String _bakPressUnitKey(dynamic tireId) => 'unit_hist_${tireId}_bak_pu';
  static String _bakDistUnitKey(dynamic tireId) => 'unit_hist_${tireId}_bak_du';
  static String _bakDispositionKey(dynamic tireId) => 'unit_hist_${tireId}_bak_disp';

  /// Inspection flow me kisi tyre ko install ya inspect karne se pehle
  /// uski baseline readings ka snapshot save karo taaki reject hone par
  /// exact pehli state restore ki jaa sake.
  static void backupPreInspectionReadings({
    required dynamic tireId,
    num? outside,
    num? middle,
    num? inside,
    num? pressure,
    num? miles,
    num? percentageWorn,
    String? treadUnit,
    String? pressureUnit,
    String? distanceUnit,
    int? dispositionId,
    bool force = false,
  }) {
    if (tireId == null) return;
    // Sirf tab backup lo jab already backup na ho, ya force=true ho
    if (!force && _box.containsKey(_bakOutsideKey(tireId))) return;

    final double curTo = (outside != null && outside > 0) ? outside.toDouble() : (getRawOutside(tireId) ?? 0.0);
    final double curTm = (middle != null && middle > 0) ? middle.toDouble() : (getRawMiddle(tireId) ?? 0.0);
    final double curTi = (inside != null && inside > 0) ? inside.toDouble() : (getRawInside(tireId) ?? 0.0);
    final double curP = (pressure != null && pressure > 0) ? pressure.toDouble() : (getRawPressure(tireId) ?? 0.0);
    final double curM = (miles != null && miles > 0) ? miles.toDouble() : (getRawMiles(tireId) ?? 0.0);
    final double curPct = (percentageWorn != null && percentageWorn >= 0) ? percentageWorn.toDouble() : (getPercentageWorn(tireId) ?? 0.0);
    final String curTu = (treadUnit != null && treadUnit.isNotEmpty) ? treadUnit : (getTreadUnit(tireId) ?? '');
    final String curPu = (pressureUnit != null && pressureUnit.isNotEmpty) ? pressureUnit : (getPressureUnit(tireId) ?? '');
    final String curDu = (distanceUnit != null && distanceUnit.isNotEmpty) ? distanceUnit : (getDistanceUnit(tireId) ?? '');

    if (curTo > 0) _box.put(_bakOutsideKey(tireId), curTo);
    if (curTm > 0) _box.put(_bakMiddleKey(tireId), curTm);
    if (curTi > 0) _box.put(_bakInsideKey(tireId), curTi);
    if (curP > 0) _box.put(_bakPressureKey(tireId), curP);
    if (curM > 0) _box.put(_bakMilesKey(tireId), curM);
    if (curPct >= 0) _box.put(_bakPctKey(tireId), curPct);
    if (curTu.isNotEmpty) _box.put(_bakTreadUnitKey(tireId), curTu);
    if (curPu.isNotEmpty) _box.put(_bakPressUnitKey(tireId), curPu);
    if (curDu.isNotEmpty) _box.put(_bakDistUnitKey(tireId), curDu);
    if (dispositionId != null && dispositionId > 0) {
      _box.put(_bakDispositionKey(tireId), dispositionId);
    }
  }

  /// Inspection REJECT hone par tyre ki readings ko pre-inspection backup
  /// se restore karta hai aur restored data map return karta hai.
  static Map<String, dynamic>? restorePreInspectionReadings(dynamic tireId) {
    if (tireId == null) return null;
    final to = _box.get(_bakOutsideKey(tireId));
    final tm = _box.get(_bakMiddleKey(tireId));
    final ti = _box.get(_bakInsideKey(tireId));
    final p = _box.get(_bakPressureKey(tireId));
    final m = _box.get(_bakMilesKey(tireId));
    final pct = _box.get(_bakPctKey(tireId));
    final tu = _box.get(_bakTreadUnitKey(tireId)) as String?;
    final pu = _box.get(_bakPressUnitKey(tireId)) as String?;
    final du = _box.get(_bakDistUnitKey(tireId)) as String?;
    final disp = _box.get(_bakDispositionKey(tireId)) as int?;

    if (to == null && tm == null && ti == null && disp == null) {
      return null;
    }

    final restored = <String, dynamic>{
      'outside': (to is num) ? to.toDouble() : null,
      'middle': (tm is num) ? tm.toDouble() : null,
      'inside': (ti is num) ? ti.toDouble() : null,
      'pressure': (p is num) ? p.toDouble() : null,
      'miles': (m is num) ? m.toDouble() : null,
      'percentageWorn': (pct is num) ? pct.toDouble() : null,
      'treadUnit': tu,
      'pressureUnit': pu,
      'distanceUnit': du,
      'dispositionId': disp,
    };

    // Active reading keys ko restore karo
    if (to is num) _box.put(_rawOutsideKey(tireId), to.toDouble());
    if (tm is num) _box.put(_rawMiddleKey(tireId), tm.toDouble());
    if (ti is num) _box.put(_rawInsideKey(tireId), ti.toDouble());
    if (p is num) _box.put(_rawPressureKey(tireId), p.toDouble());
    if (m is num) _box.put(_rawMilesKey(tireId), m.toDouble());
    if (pct is num) _box.put(_pctKey(tireId), pct.toDouble());
    if (tu != null && tu.isNotEmpty) _box.put(_treadKey(tireId), tu);
    if (pu != null && pu.isNotEmpty) _box.put(_pressureKey(tireId), pu);
    if (du != null && du.isNotEmpty) _box.put(_distanceKey(tireId), du);

    clearPreInspectionBackup(tireId);
    return restored;
  }

  /// Inspection APPROVE hone par backup saaf karo (naya data permanent ban gaya).
  static void clearPreInspectionBackup(dynamic tireId) {
    if (tireId == null) return;
    _box.delete(_bakOutsideKey(tireId));
    _box.delete(_bakMiddleKey(tireId));
    _box.delete(_bakInsideKey(tireId));
    _box.delete(_bakPressureKey(tireId));
    _box.delete(_bakMilesKey(tireId));
    _box.delete(_bakPctKey(tireId));
    _box.delete(_bakTreadUnitKey(tireId));
    _box.delete(_bakPressUnitKey(tireId));
    _box.delete(_bakDistUnitKey(tireId));
    _box.delete(_bakDispositionKey(tireId));
  }

  static void clearRawReadings(dynamic tireId) {
    if (tireId == null) return;
    _box.delete(_rawOutsideKey(tireId));
    _box.delete(_rawMiddleKey(tireId));
    _box.delete(_rawInsideKey(tireId));
    _box.delete(_rawPressureKey(tireId));
    _box.delete(_rawMilesKey(tireId));
    _box.delete(_pctKey(tireId));
  }
}

