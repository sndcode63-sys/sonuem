import 'dart:convert';
import 'dart:io';
import 'package:emtrack/models/inspect_tyre_model.dart';
import 'package:emtrack/models/offline_hive_models.dart';
import 'package:emtrack/services/inspect_tyre_service.dart';
import 'package:emtrack/services/master_data_service.dart';
import 'package:emtrack/utils/hive_prefe.dart';
import 'package:emtrack/utils/mesurment_helper_class.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:emtrack/utils/tyre_unit_history.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/offline_hive_service.dart';
import '../utils/global_state_referesh.dart';
import 'search.dart' show SearchApi, PendingInspectionTire, PendingInspectionEntry;
import '../l10n/app_localizations.dart';
import '../utils/approval_localizations.dart';
import '../utils/local_helper.dart';
import '../utils/local_image_cache.dart';

const String _kCyan = '\x1B[36m';
const String _kReset = '\x1B[0m';
void _logCyan(String msg) {
  debugPrint('$_kCyan🛞 [IW-TYRE-DEBUG] $msg$_kReset');
}

class IWTyreInspectionScreen extends StatefulWidget {
  final String serialNo;
  final int? tireId;
  final String vehicleNumber;
  final String? inspectionDate;
  final dynamic wearConditionId;
  final dynamic casingConditionId;
  final String? comments;
  final double? outsideTread;
  final double? middleTread;
  final double? insideTread;
  final double? currentPressure;
  final String? wheelPosition;
  final int? pendingInspectionId;
  final dynamic imagesLocation;

  const IWTyreInspectionScreen({
    super.key,
    required this.serialNo,
    this.tireId,
    required this.vehicleNumber,
    this.inspectionDate,
    this.wearConditionId,
    this.casingConditionId,
    this.comments,
    this.outsideTread,
    this.middleTread,
    this.insideTread,
    this.currentPressure,
    this.wheelPosition,
    this.pendingInspectionId,
    this.imagesLocation,
  });

  @override
  State<IWTyreInspectionScreen> createState() => _IWTyreInspectionScreenState();
}

class _IWTyreInspectionScreenState extends State<IWTyreInspectionScreen> {
  final InspectTyreService _service = InspectTyreService();

  bool _isLoading = true;

  String _vehicleId = '';
  String _vehicleNumber = '';
  String _wheelPosition = '';
  String _lastInspection = '';
  String _brandNo = '';

  // ── Read-only values from API (already converted to display unit) ──
  double _oldOutside = 0;
  double _oldMiddle = 0;
  double _oldInside = 0;
  double _oldAirPressure = 0;
  double _oldAverageTread = 0;
  String _oldWearCondition = '';
  String _oldCasingCondition = '';
  String _oldComments = '';
  final List<String> _tyreImages = [];

  // ── Unit preferences (same source as InspectTyreController) ──
  // measurementUnit: 'mm' (Metric) ya '/32nds' (Imperial)
  // pressureUnit: HivePref me jo bhi saved hai (e.g. PSI / BAR)
  String _measurementUnit = '/32nds';
  String _pressureUnit = 'PSI';
  String? _sourceTreadUnit;
  String? _sourcePressureUnit;

  // 1, 2, ya 3 — kitni tread-depth readings lene ka preference hai,
  // isi se Middle/Inside rows show/hide hote hain (InspectTyreView jaisa)
  int _noOfTreadDepthReadings = 3;

  Map<int, String> _wearIdToName = {};
  Map<int, String> _casingIdToName = {};
  InspectTyreModel? _apiModel;

  @override
  void initState() {
    super.initState();
    _logCyan('🟢 initState() called -> serialNo: ${widget.serialNo}, tireId: ${widget.tireId}, vehicleNumber: ${widget.vehicleNumber}, inspectionDate: ${widget.inspectionDate}');
    _vehicleNumber = widget.vehicleNumber;
    _loadUnitPreferences();

    // 🔄 Live reactive listener: Settings/Preferences change hone par screen turant update ho
    if (Get.isRegistered<GlobalPrefsState>()) {
      ever(GlobalPrefsState.to.measurement, (_) {
        if (mounted) {
          _loadUnitPreferences();
          setState(() {});
        }
      });
      ever(GlobalPrefsState.to.pressure, (_) {
        if (mounted) {
          _loadUnitPreferences();
          setState(() {});
        }
      });
    }

    _fetchTireData();
  }

  void _addImages(dynamic raw) {
    if (raw == null) return;
    if (raw is List) {
      for (final item in raw) {
        _addImages(item);
      }
      return;
    }
    final str = raw.toString().trim();
    if (str.isEmpty) return;
    for (final part in str.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty)) {
      _addSingleImage(part);
    }
  }

  void _addSingleImage(String candidate) {
    final clean = candidate.trim();
    if (clean.isEmpty) return;
    if (_tyreImages.contains(clean)) return;

    final isCandidateHttp = clean.startsWith('http');
    final candidateResolved = LocalImageCache.resolveSync(clean, tireId: widget.tireId);
    final candidateResolvedPath = candidateResolved?.path;

    for (int i = 0; i < _tyreImages.length; i++) {
      final existing = _tyreImages[i];
      final isExistingHttp = existing.startsWith('http');
      final existingResolved = LocalImageCache.resolveSync(existing, tireId: widget.tireId);
      final existingResolvedPath = existingResolved?.path;

      // 1. Both point to the exact same local file on disk
      if (candidateResolvedPath != null &&
          existingResolvedPath != null &&
          candidateResolvedPath == existingResolvedPath) {
        if (isCandidateHttp && !isExistingHttp) {
          _tyreImages[i] = clean; // Keep canonical HTTP URL
        }
        return; // Duplicate
      }

      // 2. Candidate is local file, and an existing HTTP URL already resolves to it
      if (!isCandidateHttp && existingResolvedPath == clean) {
        return; // Duplicate
      }

      // 3. Candidate is HTTP URL, and resolves to an already listed local file
      if (isCandidateHttp && !isExistingHttp && candidateResolvedPath == existing) {
        _tyreImages[i] = clean; // Upgrade to canonical HTTP URL
        return;
      }
    }

    _tyreImages.add(clean);
  }

  // ✅ Same preference source as InspectTyreController._loadPreferences() —
  // taaki dono screens hamesha same unit label + same conversion dikhayen.
  void _loadUnitPreferences() {
    _noOfTreadDepthReadings = SecureStorage.getNoOfTreadDepthReadings();

    final savedPressure = HivePref.get<String>('pref_pressure');
    if (savedPressure != null && savedPressure.isNotEmpty) {
      _pressureUnit = savedPressure.toUpperCase();
    }

    final savedMeasurement = HivePref.get<String>('pref_measurement');
    if (savedMeasurement != null && savedMeasurement.isNotEmpty) {
      _measurementUnit =
      savedMeasurement.toLowerCase() == 'metric' ? 'mm' : '/32nds';
    }
  }

  // ✅ Rounded whole number without decimals (. ke baad show nahi, e.g. 125.98 -> 126)
  String _clean(dynamic val) {
    if (val == null) return '-';
    final d = double.tryParse(val.toString());
    if (d == null) return val.toString();
    return d.round().toString();
  }

  Future<void> _fetchTireData() async {
    setState(() => _isLoading = true);
    _logCyan('🚀 _fetchTireData() started...');
    try {
      await _loadMasterData();

      final int? tireId = widget.tireId;

      // ── 1. Initial readings from widget parameters & TyreUnitHistory ──
      // (Works for both online AND offline created/installed tyres)
      final int? tId = widget.tireId;
      final String sNo = widget.serialNo.trim();

      if (tId != null && tId > 0) {
        _sourceTreadUnit ??= TyreUnitHistory.getTreadUnit(tId);
        _sourcePressureUnit ??= TyreUnitHistory.getPressureUnit(tId);
      }
      if (sNo.isNotEmpty) {
        _sourceTreadUnit ??= TyreUnitHistory.getTreadUnit(sNo);
        _sourcePressureUnit ??= TyreUnitHistory.getPressureUnit(sNo);
      }

      double? savedTo = tId != null ? TyreUnitHistory.getRawOutside(tId) : null;
      double? savedTm = tId != null ? TyreUnitHistory.getRawMiddle(tId) : null;
      double? savedTi = tId != null ? TyreUnitHistory.getRawInside(tId) : null;
      double? savedPress = tId != null ? TyreUnitHistory.getRawPressure(tId) : null;

      if (savedTo == null && sNo.isNotEmpty) savedTo = TyreUnitHistory.getRawOutside(sNo);
      if (savedTm == null && sNo.isNotEmpty) savedTm = TyreUnitHistory.getRawMiddle(sNo);
      if (savedTi == null && sNo.isNotEmpty) savedTi = TyreUnitHistory.getRawInside(sNo);
      if (savedPress == null && sNo.isNotEmpty) savedPress = TyreUnitHistory.getRawPressure(sNo);

      if (savedTo != null && savedTo > 0) {
        _oldOutside = savedTo;
      } else if (widget.outsideTread != null && widget.outsideTread! > 0) {
        _oldOutside = widget.outsideTread!;
      }

      if (savedTm != null && savedTm > 0) {
        _oldMiddle = savedTm;
      } else if (widget.middleTread != null && widget.middleTread! > 0) {
        _oldMiddle = widget.middleTread!;
      }

      if (savedTi != null && savedTi > 0) {
        _oldInside = savedTi;
      } else if (widget.insideTread != null && widget.insideTread! > 0) {
        _oldInside = widget.insideTread!;
      }

      if (savedPress != null && savedPress > 0) {
        _oldAirPressure = savedPress;
      } else if (widget.currentPressure != null && widget.currentPressure! > 0) {
        _oldAirPressure = (widget.currentPressure! > 250 && _sourcePressureUnit?.toUpperCase() == 'BAR')
            ? MeasurementHelper.canonicalPsiToRaw(widget.currentPressure!, pressureUnit: 'BAR')
            : widget.currentPressure!;
      }

      // Initial vehicle info and wheel position
      _vehicleNumber = widget.vehicleNumber.trim();
      final String passedPos = (widget.wheelPosition ?? '').trim();
      if (passedPos.isNotEmpty && passedPos != '0' && passedPos != '-') {
        _wheelPosition = passedPos;
      }
      if (widget.inspectionDate != null && widget.inspectionDate!.trim().isNotEmpty) {
        _lastInspection = _formatApiDate(widget.inspectionDate!);
      } else {
        _lastInspection = 'N/A';
      }

      // Initial wear, casing, comments, images
      _oldWearCondition = _conditionText(widget.wearConditionId, _wearIdToName) ?? '';
      _oldCasingCondition = _conditionText(widget.casingConditionId, _casingIdToName) ?? '';
      if (widget.comments != null && widget.comments!.trim().isNotEmpty) {
        _oldComments = widget.comments!.trim();
      }
      _tyreImages.clear();
      _addImages(widget.imagesLocation);

      // ── 2. If online and tireId > 0, fetch master tyre from server ──
      if (tireId != null && tireId > 0) {
        _logCyan('🌐 Calling _service.getTireById($tireId)...');
        try {
          final data = await _service.getTireById(tireId);
          _logCyan('📥 API Response received for tireId $tireId');
          _apiModel = InspectTyreModel.fromJson(data);
        } catch (e) {
          _logCyan('⚠️ getTireById failed -> $e (continuing with pending data)');
          _apiModel = null;
        }

        if (_apiModel != null) {
          _vehicleId = _apiModel!.vehicleId?.toString() ?? '';
          if (_vehicleNumber.isEmpty || _vehicleNumber == 'N/A') {
            if (_apiModel!.vehicleId != null) {
              final cachedVehicle = OfflineHiveService.getVehicleById(_apiModel!.vehicleId!);
              if (cachedVehicle != null && cachedVehicle.vehicleNumber.trim().isNotEmpty) {
                _vehicleNumber = cachedVehicle.vehicleNumber;
              }
            }
            if (_vehicleNumber.isEmpty || _vehicleNumber == 'N/A') {
              _vehicleNumber = _vehicleId.isNotEmpty ? _vehicleId : 'N/A';
            }
          }

          if (_wheelPosition.isEmpty && _apiModel!.wheelPosition != null && _apiModel!.wheelPosition!.trim().isNotEmpty) {
            _wheelPosition = _apiModel!.wheelPosition!.trim();
          }
          if (_brandNo.isEmpty && _apiModel!.brandNo != null && _apiModel!.brandNo!.trim().isNotEmpty && _apiModel!.brandNo!.trim().toLowerCase() != 'null') {
            _brandNo = _apiModel!.brandNo!.trim();
          }
          if (_lastInspection == 'N/A' && _apiModel!.inspectionDate != null) {
            _lastInspection = _apiModel!.inspectionDate!.toIso8601String();
          }
          if (_oldOutside <= 0 && _apiModel!.outsideTread > 0) {
            _oldOutside = _apiModel!.outsideTread;
          }
          if (_oldMiddle <= 0 && _apiModel!.middleTread > 0) {
            _oldMiddle = _apiModel!.middleTread;
          }
          if (_oldInside <= 0 && _apiModel!.insideTread > 0) {
            _oldInside = _apiModel!.insideTread;
          }
          if (_oldAirPressure <= 0 && _apiModel!.currentPressure > 0) {
            _oldAirPressure = (_apiModel!.currentPressure > 250)
                ? MeasurementHelper.toDisplayPressure(_apiModel!.currentPressure, sourceUnit: 'PSI')
                : _apiModel!.currentPressure;
          }
          if (_oldWearCondition.isEmpty && _apiModel!.wearConditionId != null) {
            _oldWearCondition = _conditionText(_apiModel!.wearConditionId, _wearIdToName) ?? '';
          }
          if (_oldCasingCondition.isEmpty && _apiModel!.casingConditionId != null) {
            _oldCasingCondition = _conditionText(_apiModel!.casingConditionId, _casingIdToName) ?? '';
          }
          if (_oldComments.isEmpty && _apiModel!.comments.trim().isNotEmpty) {
            _oldComments = _apiModel!.comments.trim();
          }
          _addImages(_apiModel!.imagesLocation);
        }
      }

      // ── 3. Fallback to Local Caches (OfflineHiveService & SharedPreferences) ──
      // This is crucial when an offline tyre was inspected or when a vehicle inspection was just submitted
      await _fillFromLocalInspectionCache(tireId);

      if (_tyreImages.isEmpty && tireId != null) {
        final diskFiles = await LocalImageCache.getLocalImagesForTire(tireId);
        for (final f in diskFiles) {
          _addImages(f.path);
        }
        final prefs = await SharedPreferences.getInstance();
        final sp = prefs.getStringList('inspect_tire_images_$tireId');
        if (sp != null) {
          for (final p in sp) {
            _addImages(p);
          }
        }
      }

      // ── 4. Fill any remaining missing values from Pending API ──
      await _fillMissingFromPendingApi(tireId);

      // ── 5. Average tread calculation based on reading preference ──
      if (_noOfTreadDepthReadings == 1) {
        _oldAverageTread = _oldOutside;
      } else if (_noOfTreadDepthReadings == 2) {
        _oldAverageTread = (_oldOutside + _oldInside) / 2;
      } else {
        _oldAverageTread = _oldMiddle > 0
            ? (_oldOutside + _oldMiddle + _oldInside) / 3
            : (_oldOutside + _oldInside) / 2;
      }

      // ── 6. Fallback defaults if still empty ──
      if (_oldWearCondition.isEmpty) _oldWearCondition = '—';
      if (_oldCasingCondition.isEmpty) _oldCasingCondition = '—';
      if (_oldComments.isEmpty) _oldComments = 'No comments provided';

      _logCyan('✅ Resolved readings -> Outside: $_oldOutside, Middle: $_oldMiddle, Inside: $_oldInside, Pressure: $_oldAirPressure, Comments: $_oldComments, Wear: $_oldWearCondition, Casing: $_oldCasingCondition, Images: ${_tyreImages.length}');
    } catch (e, stackTrace) {
      _logCyan('❌ ERROR in _fetchTireData -> $e');
      debugPrint('$stackTrace');
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _logCyan('🏁 _fetchTireData() finished.');
    }
  }

  Future<void> _fillFromLocalInspectionCache(int? tireId) async {
    try {
      final serial = widget.serialNo.trim().toUpperCase();
      final prefs = await SharedPreferences.getInstance();

      final candidateKeys = [
        if (_vehicleNumber.isNotEmpty && _vehicleNumber != 'N/A') _vehicleNumber,
        if (_vehicleId.isNotEmpty && _vehicleId != 'N/A') _vehicleId,
        widget.vehicleNumber.trim(),
      ];

      // 1. Check SharedPreferences pending_inspection_tires_*
      for (final vKey in candidateKeys) {
        if (vKey.isEmpty || vKey == 'N/A') continue;
        final rawJson = prefs.getString('pending_inspection_tires_$vKey');
        if (rawJson != null && rawJson.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(rawJson);
            if (decoded is List) {
              for (final rawItem in decoded.whereType<Map<String, dynamic>>()) {
                final item = MeasurementHelper.localRawTireJsonToCanonical(rawItem);
                final cId = item['tireId'] ?? item['TireId'];
                final cSn = (item['tireSerialNo'] ?? item['TireSerialNo'])?.toString().trim().toUpperCase();

                final idMatch = (tireId != null && tireId != 0 && cId != null && cId.toString() == tireId.toString());
                final snMatch = (serial.isNotEmpty && cSn == serial);

                if (idMatch || snMatch) {
                  _applyCachedTireData(item);
                  break;
                }
              }
            }
          } catch (_) {}
        }
      }

      // 2. Check OfflineHiveService.getInspectionCache
      for (final vKey in candidateKeys) {
        if (vKey.isEmpty || vKey == 'N/A') continue;
        final cached = OfflineHiveService.getInspectionCache(vKey);
        if (cached != null && cached.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(cached) as Map<String, dynamic>;
            final m = (decoded['model'] as Map<String, dynamic>?) ?? decoded;
            final tList = (m['installedTires'] ?? m['tireList'] ?? m['tiresList']) as List?;
            if (tList != null) {
              for (final rawItem in tList.whereType<Map<String, dynamic>>()) {
                final item = MeasurementHelper.localRawTireJsonToCanonical(rawItem);
                final cId = item['tireId'] ?? item['TireId'];
                final cSn = (item['tireSerialNo'] ?? item['TireSerialNo'])?.toString().trim().toUpperCase();

                final idMatch = (tireId != null && tireId != 0 && cId != null && cId.toString() == tireId.toString());
                final snMatch = (serial.isNotEmpty && cSn == serial);

                if (idMatch || snMatch) {
                  _applyCachedTireData(item);
                  break;
                }
              }
            }
            final cDate = m['inspectionDate'] ?? m['createdDate'];
            if ((_lastInspection == 'N/A' || _lastInspection.isEmpty) && cDate != null && cDate.toString().trim().isNotEmpty) {
              _lastInspection = _formatApiDate(cDate.toString());
            }
          } catch (_) {}
        }
      }

      // 🛞 Tyre-specific images from prefs (both current tireId and mapped temporary offline IDs)
      if (_tyreImages.isEmpty && tireId != null) {
        final directTireImgs = prefs.getStringList('inspect_tire_images_$tireId');
        if (directTireImgs != null && directTireImgs.isNotEmpty) {
          for (final p in directTireImgs) {
            _addImages(p);
          }
        }
        if (tireId > 0) {
          for (final key in prefs.getKeys()) {
            if (!key.startsWith('tyre_real_id_')) continue;
            if (prefs.getInt(key) == tireId) {
              final tempId = key.substring('tyre_real_id_'.length);
              final tempImgs = prefs.getStringList('inspect_tire_images_$tempId');
              if (tempImgs != null && tempImgs.isNotEmpty) {
                for (final p in tempImgs) {
                  _addImages(p);
                }
              }
            }
          }
        }
      }

      // 4. Check OfflineHiveService getTyreById or find by serial
      if (_oldOutside <= 0 || _oldAirPressure <= 0 || _oldWearCondition.isEmpty || _oldCasingCondition.isEmpty || _oldComments.isEmpty) {
        TyreHiveModel? hiveTyre;
        if (tireId != null && tireId != 0) {
          hiveTyre = OfflineHiveService.getTyreById(tireId);
        }
        if (hiveTyre == null && serial.isNotEmpty) {
          try {
            for (final t in OfflineHiveService.getAllTyres()) {
              if (t.serialNumber != null && t.serialNumber!.trim().toUpperCase() == serial) {
                hiveTyre = t;
                break;
              }
            }
          } catch (_) {}
        }

        if (hiveTyre != null) {
          if (_oldOutside <= 0 && hiveTyre.outsideTread != null && hiveTyre.outsideTread! > 0) {
            _oldOutside = hiveTyre.outsideTread!;
          }
          if (_oldMiddle <= 0 && hiveTyre.middleTread != null && hiveTyre.middleTread! > 0) {
            _oldMiddle = hiveTyre.middleTread!;
          }
          if (_oldInside <= 0 && hiveTyre.insideTread != null && hiveTyre.insideTread! > 0) {
            _oldInside = hiveTyre.insideTread!;
          }
          if (_oldAirPressure <= 0 && hiveTyre.currentPressure != null && hiveTyre.currentPressure! > 0) {
            _oldAirPressure = MeasurementHelper.toDisplayPressure(hiveTyre.currentPressure!, sourceUnit: 'PSI');
          }
          if (_wheelPosition.isEmpty && hiveTyre.wheelPosition != null && hiveTyre.wheelPosition!.trim().isNotEmpty) {
            _wheelPosition = hiveTyre.wheelPosition!.trim();
          }
          if (_brandNo.isEmpty && hiveTyre.brandNo != null && hiveTyre.brandNo!.trim().isNotEmpty && hiveTyre.brandNo!.trim().toLowerCase() != 'null') {
            _brandNo = hiveTyre.brandNo!.trim();
          }
          if ((_oldWearCondition.isEmpty || _oldWearCondition == '—') && hiveTyre.wearConditionId != null) {
            _oldWearCondition = _conditionText(hiveTyre.wearConditionId, _wearIdToName) ?? '';
          }
          if ((_oldCasingCondition.isEmpty || _oldCasingCondition == '—') && hiveTyre.casingConditionId != null) {
            _oldCasingCondition = _conditionText(hiveTyre.casingConditionId, _casingIdToName) ?? '';
          }
          if ((_oldComments.isEmpty || _oldComments == 'No comments provided') && hiveTyre.comments != null && hiveTyre.comments!.trim().isNotEmpty) {
            _oldComments = hiveTyre.comments!.trim();
          }
          if (tireId != null && tireId > 0) {
            final cached = OfflineHiveService.getTireDetailCache(tireId);
            if (cached != null) {
              try {
                final jd = jsonDecode(cached) as Map<String, dynamic>;
                final m = jd['model'] as Map<String, dynamic>?;
                final loc = m?['imagesLocation']?.toString();
                if (loc != null && loc.trim().isNotEmpty) {
                  _addImages(loc.trim());
                }
                final cDate = m?['inspectionDate']?.toString();
                if ((_lastInspection == 'N/A' || _lastInspection.isEmpty) && cDate != null && cDate.trim().isNotEmpty) {
                  _lastInspection = _formatApiDate(cDate.trim());
                }
              } catch (_) {}
            }
          }
        }
      }
    } catch (e) {
      _logCyan('⚠️ _fillFromLocalInspectionCache error -> $e');
    }
  }

  void _applyCachedTireData(Map<String, dynamic> item) {
    final ot = item['outsideTread'] ?? item['OutsideTread'];
    final mt = item['middleTread'] ?? item['MiddleTread'];
    final it = item['insideTread'] ?? item['InsideTread'];
    final cp = item['currentPressure'] ?? item['CurrentPressure'] ?? item['airPressure'] ?? item['AirPressure'];
    final wp = item['wheelPosition'] ?? item['WheelPosition'];
    final wc = item['wearConditionId'] ?? item['WearConditionId'] ?? item['wearCondition'] ?? item['WearCondition'];
    final cc = item['casingConditionId'] ?? item['CasingConditionId'] ?? item['casingCondition'] ?? item['CasingCondition'];
    final comm = item['comments'] ?? item['Comments'] ?? item['remarks'] ?? item['Remarks'];
    final imgs = item['imagesLocation'] ?? item['ImagesLocation'];
    final tu = item['treadUnit'] ?? item['TreadUnit'];
    final pu = item['pressureUnit'] ?? item['PressureUnit'];

    if (tu != null && tu.toString().trim().isNotEmpty) {
      _sourceTreadUnit = tu.toString().trim();
    }
    if (pu != null && pu.toString().trim().isNotEmpty) {
      _sourcePressureUnit = pu.toString().trim();
    }

    if (_oldOutside <= 0 && ot != null) {
      final v = double.tryParse(ot.toString());
      if (v != null && v > 0) {
        _oldOutside = v;
      }
    }
    if (_oldMiddle <= 0 && mt != null) {
      final v = double.tryParse(mt.toString());
      if (v != null && v > 0) {
        _oldMiddle = v;
      }
    }
    if (_oldInside <= 0 && it != null) {
      final v = double.tryParse(it.toString());
      if (v != null && v > 0) {
        _oldInside = v;
      }
    }
    if (_oldAirPressure <= 0 && cp != null) {
      final v = double.tryParse(cp.toString());
      if (v != null && v > 0) {
        _oldAirPressure = (v > 250)
            ? MeasurementHelper.toDisplayPressure(v, sourceUnit: 'PSI')
            : v;
      }
    }
    if (_wheelPosition.isEmpty && wp != null && wp.toString().trim().isNotEmpty && wp.toString().trim() != '0') {
      _wheelPosition = wp.toString().trim();
    }
    if ((_oldWearCondition.isEmpty || _oldWearCondition == '—') && wc != null) {
      _oldWearCondition = _conditionText(wc, _wearIdToName) ?? '';
    }
    if ((_oldCasingCondition.isEmpty || _oldCasingCondition == '—') && cc != null) {
      _oldCasingCondition = _conditionText(cc, _casingIdToName) ?? '';
    }
    if ((_oldComments.isEmpty || _oldComments == 'No comments provided') && comm != null && comm.toString().trim().isNotEmpty) {
      _oldComments = comm.toString().trim();
    }
    if (imgs != null) {
      _addImages(imgs);
    }
    final inspDate = item['inspectionDate'] ?? item['InspectionDate'] ?? item['createdDate'] ?? item['CreatedDate'];
    if ((_lastInspection == 'N/A' || _lastInspection.isEmpty) && inspDate != null && inspDate.toString().trim().isNotEmpty) {
      _lastInspection = _formatApiDate(inspDate.toString());
    }
  }

  bool get _needWheel {
    final w = _wheelPosition.trim();
    return w.isEmpty || w == '0' || w == '-';
  }

  bool get _needWear =>
      _oldWearCondition.isEmpty || _oldWearCondition == '—';
  bool get _needCasing =>
      _oldCasingCondition.isEmpty || _oldCasingCondition == '—';
  bool get _needComments =>
      _oldComments.isEmpty || _oldComments == 'No comments provided';

  // raw value id (int/double/"6") ya name ("Even") — dono handle karta hai.
  String? _conditionText(dynamic raw, Map<int, String> map) {
    if (raw == null) return null;
    final n = int.tryParse(raw.toString()) ?? double.tryParse(raw.toString())?.toInt();
    if (n != null) {
      if (n <= 0) return null;
      final name = map[n];
      return (name != null && name.isNotEmpty) ? name : 'ID: $n';
    }
    final str = raw.toString().trim();
    return str.isEmpty ? null : str;
  }

  Future<void> _fillMissingFromPendingApi(int? tireId) async {
    try {
      final int? accountId = await SecureStorage.getProfileParentAccountId() ??
          int.tryParse(await SecureStorage.getParentAccountId() ?? '');
      if (accountId == null) return;

      final entries = await SearchApi()
          .fetchPendingInspections(accountId)
          .timeout(const Duration(seconds: 10));

      final serial = widget.serialNo.trim().toUpperCase();
      final List<PendingInspectionTire> matches = [];
      for (final e in entries) {
        for (final t in <PendingInspectionTire>[
          if (e.tire != null) e.tire!,
          ...e.tiresList,
        ]) {
          final idMatch = tireId != null && tireId != 0 && t.tireId == tireId;
          final snMatch = serial.isNotEmpty &&
              (t.tireSerialNo ?? '').trim().toUpperCase() == serial;
          if (idMatch || snMatch) matches.add(t);
        }
      }
      if (matches.isEmpty) {
        _logCyan('🔎 pending API me tyre nahi mila (tireId=$tireId, serial=$serial)');
        return;
      }

      final PendingInspectionTire pt = matches.firstWhere(
            (t) => widget.pendingInspectionId != null &&
            t.inspectionStatusId == widget.pendingInspectionId,
        orElse: () => matches.last,
      );
      _logCyan('🔎 pending tyre mila -> pos=${pt.wheelPosition}, wear=${pt.wearConditionId}, casing=${pt.casingConditionId}, comments=${pt.comments}');

      if (_needWheel) {
        final w = (pt.wheelPosition ?? '').trim();
        if (w.isNotEmpty && w != '0' && w != '-') _wheelPosition = w;
      }
      if (_needWear) {
        final txt = _conditionText(pt.wearConditionId, _wearIdToName);
        if (txt != null) _oldWearCondition = txt;
      }
      if (_needCasing) {
        final txt = _conditionText(pt.casingConditionId, _casingIdToName);
        if (txt != null) _oldCasingCondition = txt;
      }
      if (_needComments) {
        final c = (pt.comments ?? '').trim();
        if (c.isNotEmpty) _oldComments = c;
      }
      if (_brandNo.isEmpty && pt.brandNo != null && pt.brandNo!.trim().isNotEmpty && pt.brandNo!.trim().toLowerCase() != 'null') {
        _brandNo = pt.brandNo!.trim();
      }
      if (_oldOutside <= 0 && pt.outsideTread != null && pt.outsideTread! > 0) {
        _oldOutside = pt.outsideTread!;
      }
      if (_oldMiddle <= 0 && pt.middleTread != null && pt.middleTread! > 0) {
        _oldMiddle = pt.middleTread!;
      }
      if (_oldInside <= 0 && pt.insideTread != null && pt.insideTread! > 0) {
        _oldInside = pt.insideTread!;
      }
      if (_oldAirPressure <= 0 && pt.currentPressure != null && pt.currentPressure! > 0) {
        _oldAirPressure = (pt.currentPressure! > 250)
            ? MeasurementHelper.toDisplayPressure(pt.currentPressure!, sourceUnit: 'PSI')
            : pt.currentPressure!;
      }
      if (pt.imagesLocation != null) {
        _addImages(pt.imagesLocation);
      }
      if (_lastInspection == 'N/A' || _lastInspection.isEmpty) {
        PendingInspectionEntry? parentEntry;
        for (final e in entries) {
          final foundInThis = (e.tire != null && (e.tire!.tireId == pt.tireId || (pt.tireSerialNo != null && e.tire!.tireSerialNo == pt.tireSerialNo))) ||
              e.tiresList.any((t) => (pt.tireId != null && pt.tireId != 0 && t.tireId == pt.tireId) ||
                  (pt.tireSerialNo != null && pt.tireSerialNo!.isNotEmpty && t.tireSerialNo == pt.tireSerialNo));
          if (foundInThis) {
            parentEntry = e;
            break;
          }
        }
        final eDate = pt.inspectionDate ??
            parentEntry?.status?.createdDate ??
            parentEntry?.status?.statusUpdatedDate ??
            parentEntry?.tire?.inspectionDate;
        if (eDate != null && eDate.trim().isNotEmpty) {
          _lastInspection = _formatApiDate(eDate.trim());
        }
      }
    } catch (e) {
      _logCyan('⚠️ _fillMissingFromPendingApi failed -> $e');
    }
  }

  Future<void> _loadMasterData() async {
    try {
      _logCyan('📦 Loading master data for wear & casing conditions...');
      final data = await MasterDataService().fetchMasterData();
      final wearList = (data['wearConditions'] as List?) ?? [];
      final casingList = (data['casingCondition'] as List?) ?? [];

      _wearIdToName = {
        for (final e in wearList)
          if (e['wearConditionId'] != null)
            (e['wearConditionId'] as num).toInt(): (e['wearConditionName'] ?? '').toString(),
      };
      _casingIdToName = {
        for (final e in casingList)
          if (e['casingConditionId'] != null)
            (e['casingConditionId'] as num).toInt(): (e['casingConditionName'] ?? '').toString(),
      };

      _logCyan('✅ Master data loaded successfully.');
    } catch (e) {
      _logCyan('⚠️ Failed to load master data -> $e');
    }
  }

  /// _lastInspection me hamesha RAW date (ISO / API string) store hoti hai.
  /// Format sirf display ke time hota hai, taaki current preference
  /// (UK/Australia = DD/MM/YYYY, US/Canada = MM/DD/YYYY) hamesha apply ho.
  String _formatApiDate(String dateStr) {
    final raw = dateStr.trim();
    return raw.isEmpty ? 'N/A' : raw;
  }

  String _displayLastInspection() {
    final raw = _lastInspection.trim();
    if (raw.isEmpty || raw == 'N/A') return 'N/A';
    final res = LocaleHelper.formatApiDate(raw);
    return (res == '-' || res.isEmpty) ? raw : res;
  }

  void _openImageDialog(String pathOrUrl, bool isLocal) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Builder(
                builder: (_) {
                  final cached = !isLocal
                      ? LocalImageCache.resolveSync(pathOrUrl, tireId: widget.tireId)
                      : null;
                  if (isLocal && LocalImageCache.safePathExists(pathOrUrl)) {
                    return Image.file(
                      File(pathOrUrl),
                      fit: BoxFit.contain,
                      cacheWidth: 1080,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.white, size: 50),
                      ),
                    );
                  }
                  if (LocalImageCache.safeFileExists(cached) && cached != null) {
                    return Image.file(
                      cached,
                      fit: BoxFit.contain,
                      cacheWidth: 1080,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.white, size: 50),
                      ),
                    );
                  }
                  if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
                    return Image.network(
                      pathOrUrl,
                      fit: BoxFit.contain,
                      cacheWidth: 1080,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.white, size: 50),
                      ),
                    );
                  }
                  return const Center(
                    child: Icon(Icons.broken_image, color: Colors.white, size: 50),
                  );
                },
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = ApprovalLocalizations.of(context);
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: const BackButton(color: Colors.white),
        title: Text(a.tireInspectionDetails, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Obx(() {
              // 🔄 Read live preferences dynamically
              final String currentMeasurement = Get.isRegistered<GlobalPrefsState>()
                  ? GlobalPrefsState.to.measurement.value
                  : (HivePref.get<String>('pref_measurement') ?? 'Imperial');
              final String currentPressurePref = Get.isRegistered<GlobalPrefsState>()
                  ? GlobalPrefsState.to.pressure.value
                  : (HivePref.get<String>('pref_pressure') ?? 'PSI');

              final bool isMetric = currentMeasurement.toLowerCase() == 'metric';
              _measurementUnit = isMetric ? 'mm' : '/32nds';
              _pressureUnit = currentPressurePref.toUpperCase();
              final String currentTreadUnit = _measurementUnit;
              final String currentPressureUnit = _pressureUnit;
              final int noOfReadings = SecureStorage.getNoOfTreadDepthReadings();

              final String srcTread = _sourceTreadUnit ??
                  (widget.tireId != null ? TyreUnitHistory.getTreadUnit(widget.tireId!) : null) ??
                  (widget.serialNo.isNotEmpty ? TyreUnitHistory.getTreadUnit(widget.serialNo) : null) ??
                  (isMetric ? 'mm' : '/32nds');

              final String srcPress = _sourcePressureUnit ??
                  (widget.tireId != null ? TyreUnitHistory.getPressureUnit(widget.tireId!) : null) ??
                  (widget.serialNo.isNotEmpty ? TyreUnitHistory.getPressureUnit(widget.serialNo) : null) ??
                  currentPressureUnit;

              final double displayOutside = _oldOutside > 0
                  ? MeasurementHelper.toDisplayTread(_oldOutside, sourceUnit: srcTread)
                  : 0.0;
              final double displayMiddle = _oldMiddle > 0
                  ? MeasurementHelper.toDisplayTread(_oldMiddle, sourceUnit: srcTread)
                  : 0.0;
              final double displayInside = _oldInside > 0
                  ? MeasurementHelper.toDisplayTread(_oldInside, sourceUnit: srcTread)
                  : 0.0;

              double displayAverage = 0.0;
              if (noOfReadings == 1) {
                displayAverage = displayOutside;
              } else if (noOfReadings == 2) {
                displayAverage = (displayOutside + displayInside) / 2;
              } else {
                displayAverage = displayMiddle > 0
                    ? (displayOutside + displayMiddle + displayInside) / 3
                    : (displayOutside + displayInside) / 2;
              }
              _oldAverageTread = displayAverage;

              final double displayPressure = _oldAirPressure > 0
                  ? MeasurementHelper.toDisplayPressure(_oldAirPressure, sourceUnit: srcPress)
                  : 0.0;

              final String pressureDisplayStr = currentPressureUnit == 'BAR'
                  ? '${_clean(displayPressure)} $currentPressureUnit'
                  : '${displayPressure.round()} $currentPressureUnit';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoCard(a),
                    const SizedBox(height: 16),
                    _sectionBox(
                      title: a.treadDepthInformation,
                      children: [
                        _displayRow(t.outsideTread, '${_clean(displayOutside)} $currentTreadUnit'),

                        // ✅ Middle sirf tab dikhao jab 3-reading preference ho
                        if (noOfReadings == 3) ...[
                          const SizedBox(height: 8),
                          _displayRow(t.middleTread, '${_clean(displayMiddle)} $currentTreadUnit'),
                        ],

                        // ✅ Inside sirf tab dikhao jab 2 ya 3-reading preference ho
                        if (noOfReadings == 2 || noOfReadings == 3) ...[
                          const SizedBox(height: 8),
                          _displayRow(t.insideTread, '${_clean(displayInside)} $currentTreadUnit'),
                        ],

                        const Divider(height: 16),
                        _displayRow(t.averageTread, '${_clean(_oldAverageTread)} $currentTreadUnit'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _sectionBox(
                      title: a.airPressureAndConditions,
                      children: [
                        _displayRow(t.airPressure, pressureDisplayStr),
                        const Divider(height: 16),
                        _displayRow(t.wearCondition, _oldWearCondition.isNotEmpty ? _oldWearCondition : '—'),
                        const Divider(height: 16),
                        _displayRow(t.casingCondition, _oldCasingCondition.isNotEmpty ? _oldCasingCondition : '—'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _sectionBox(
                      title: a.comments,
                      children: [
                        Text(
                          _oldComments.isNotEmpty ? _oldComments : a.noCommentsProvided,
                          style: TextStyle(
                            fontSize: 14,
                            color: _oldComments.isNotEmpty && _oldComments != a.noCommentsProvided && _oldComments != 'No comments provided'
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            }),
    );
  }

  Widget _imagesSection(ApprovalLocalizations a) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          a.inspectionImages,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        if (_tyreImages.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Text(
                a.noUploadedImagesHere,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _tyreImages.length,
              itemBuilder: (_, index) {
                final imgPath = _tyreImages[index];
                final isHttp = imgPath.startsWith('http://') || imgPath.startsWith('https://');
                final isLocalFile = LocalImageCache.safePathExists(imgPath);
                final localFile = isLocalFile ? File(imgPath) : null;
                final cachedLocal = isHttp
                    ? LocalImageCache.resolveSync(imgPath, tireId: widget.tireId)
                    : null;
                final hasCached = LocalImageCache.safeFileExists(cachedLocal);

                Widget imageChild;
                if (isLocalFile && localFile != null) {
                  imageChild = Image.file(
                    localFile,
                    width: 140,
                    height: 140,
                    cacheWidth: 300,
                    cacheHeight: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 140,
                      height: 140,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  );
                } else if (hasCached && cachedLocal != null) {
                  imageChild = Image.file(
                    cachedLocal,
                    width: 140,
                    height: 140,
                    cacheWidth: 300,
                    cacheHeight: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 140,
                      height: 140,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  );
                } else if (isHttp) {
                  imageChild = Image.network(
                    imgPath,
                    width: 140,
                    height: 140,
                    cacheWidth: 300,
                    cacheHeight: 300,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: 140,
                        height: 140,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 140,
                      height: 140,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  );
                } else {
                  imageChild = Container(
                    width: 140,
                    height: 140,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                }

                return GestureDetector(
                  onTap: () => _openImageDialog(
                    (isLocalFile && localFile != null) ? localFile.path : imgPath,
                    isLocalFile,
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: imageChild,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _infoCard(ApprovalLocalizations a) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(a.vehicleNumberLabel, _vehicleNumber),
          const Divider(),
          _infoRow(a.tireSerialNumberLabel, widget.serialNo),
          const Divider(),
          _infoRow("Brand Number", _brandNo.isNotEmpty ? _brandNo : '—'),
          const Divider(),
          _infoRow(a.wheelPositionLabel, _wheelPosition),
          const Divider(),
          _infoRow(a.lastInspectionLabel, _displayLastInspection()),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        Text(value.isNotEmpty ? value : 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _sectionBox({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _displayRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}