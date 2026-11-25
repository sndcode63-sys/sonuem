import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:emtrack/controllers/all_vehicles_controller.dart';
import 'package:emtrack/inspection/vehicle_inspe_controller.dart';
import 'package:emtrack/inspection/vehicle_inspe_model.dart';
import 'package:emtrack/models/inspect_tyre_model.dart';
import 'package:emtrack/models/tyre_model.dart';
import 'package:emtrack/services/inspect_tyre_service.dart';
import 'package:emtrack/services/master_data_service.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:emtrack/views/remove_tyre_view.dart';
import 'package:emtrack/inspection/vehicle_inspe_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/pending_inspection_guard.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_snackbar.dart';
import '../utils/hive_prefe.dart';
import '../utils/local_helper.dart';
import '../utils/tyre_unit_history.dart';
import '../utils/mesurment_helper_class.dart';
import '../utils/image_watermark_helper.dart';
import '../utils/global_state_referesh.dart';
import '../utils/local_image_cache.dart';

class InspectTyreController extends GetxController {
  /// Tyre jo view ne seedha pass kiya. Get.arguments par dependent nahi rehna
  /// kyunki dialog/snackbar/route change ke baad Get.arguments null ho sakta hai
  /// aur tab `tire` initialize nahi hota (LateInitializationError).
  final InstalledTire? _initialTire;
  InspectTyreController({InstalledTire? initialTire}) : _initialTire = initialTire;

  /// false => tyre resolve nahi hua; view ko build nahi karna chahiye.
  bool hasTire = false;

  final InspectTyreService service = InspectTyreService();
  final MasterDataService _masterService = MasterDataService();
  final commentCtrl = TextEditingController();
  final previousCommentsCtrl = TextEditingController();

  final RxBool stillRelevant = false.obs;
  void previousCommentsOnChange() {
    stillRelevant.value = !stillRelevant.value;
    if (stillRelevant.value) {
      commentCtrl.text = previousCommentsCtrl.text;
    } else {
      commentCtrl.clear();
    }
  }

  final RxList<InstalledTire> tires = <InstalledTire>[].obs;
  final picker = ImagePicker();

  late InstalledTire tire;
  final RxBool isSubmitting = false.obs;

  // ✅ Same pattern as InstallTyreController / RemoveTyreController: when
  // this screen is opened from inside an active Vehicle Inspection (the
  // diagram), we're in "draft" mode — changes should be staged locally and
  // sent once, in a single batched call, when the whole vehicle inspection
  // is submitted. Only when opened stand-alone (e.g. from the vehicle's own
  // tyre view, outside of an inspection) should it hit the server right away.
  bool get isInspectionFlow => Get.isRegistered<VehicleInspeController>();

  final RxInt noOfTreadDepthReadings = 3.obs;

  final airPressureController = TextEditingController();

  final outsideTreadController = TextEditingController();
  final middleTreadController = TextEditingController();
  final insideTreadController = TextEditingController();

  final RxBool isHotPressure = false.obs;

  final RxString pressureUnit = 'PSI'.obs;
  final RxString measurementUnit = '/32nds'.obs;
  final RxString kmMilesLabel = 'KM'.obs;

  final wearConditionsId = TextEditingController();
  final wearConditionsList = <String>[].obs;
  final wearConditionsIdList = <int>[].obs;
  final selectedWearConditionsId = 0.obs;

  final casingConditionsId = TextEditingController();
  final casingConditionList = <String>[].obs;
  final casingConditionIdList = <int>[].obs;
  final selectedCasingConditionId = 0.obs;

  Rx<InspectTyreModel> model = InspectTyreModel().obs;
  Rx<TyreModel?> tyreData = Rx<TyreModel?>(null);
  final RxString lastInspectionDateStr = 'N/A'.obs;

  RxList<File> localImages = <File>[].obs;
  RxBool isUploadingImages = false.obs;

  bool isSubmittedSuccessfully = false;
  final List<String> _sessionPickedImages = [];

  bool _isDisposed = false;

  bool _userEditedTread = false;
  bool _userEditedPressure = false;

  String get _prefsKey => 'inspect_tire_images_${tire.tireId ?? 0}';
  String get _hotColdKey => 'inspect_tire_hotcold_${tire.tireId ?? 0}';
  String get _commentKey => 'inspect_tire_comment_${tire.tireId ?? 0}';
  String get _stillRelevantKey =>
      'inspect_tire_still_relevant_${tire.tireId ?? 0}';

  String _conditionKey(int tireId) => 'tire_conditions_$tireId';

  /// Purges all cached inspection data (disk photos, SharedPreferences keys for
  /// hot/cold, images, comments, conditions, and Hive detail cache) for a tyre.
  static Future<void> purgeTireInspectionCache(int tireId, [String? serialNo]) async {
    try {
      // 1. Delete physical cached images on disk
      await LocalImageCache.clearLocalImagesForTire(tireId);

      // 2. Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('inspect_tire_images_$tireId');
      await prefs.remove('inspect_tire_hotcold_$tireId');
      await prefs.remove('inspect_tire_comment_$tireId');
      await prefs.remove('inspect_tire_still_relevant_$tireId');
      await prefs.remove('tire_conditions_$tireId');

      if (serialNo != null && serialNo.trim().isNotEmpty) {
        final cleanSerial = serialNo.trim();
        await prefs.remove('inspect_tire_images_$cleanSerial');
        await prefs.remove('inspect_tire_hotcold_$cleanSerial');
        await prefs.remove('inspect_tire_comment_$cleanSerial');
        await prefs.remove('inspect_tire_still_relevant_$cleanSerial');
        await prefs.remove('tire_conditions_$cleanSerial');
      }

      // Check temp ID mappings
      for (final k in prefs.getKeys().toList()) {
        if (k.startsWith('tyre_real_id_') && prefs.getInt(k) == tireId) {
          final tempId = k.replaceFirst('tyre_real_id_', '');
          await prefs.remove('inspect_tire_images_$tempId');
          await prefs.remove('inspect_tire_hotcold_$tempId');
          await prefs.remove('inspect_tire_comment_$tempId');
          await prefs.remove('inspect_tire_still_relevant_$tempId');
          await prefs.remove('tire_conditions_$tempId');
          await prefs.remove(k);
        }
      }

      // 3. Clear Hive tire detail cache
      await OfflineHiveService.clearTireDetailCache(tireId);
    } catch (e) {
      debugPrint('⚠️ [InspectTyreController] purgeTireInspectionCache error: $e');
    }
  }

  void discardUnsubmittedImages() {
    if (isSubmittedSuccessfully) return;
    for (final path in _sessionPickedImages) {
      try {
        final f = File(path);
        if (f.existsSync()) {
          f.deleteSync();
        }
      } catch (_) {}
    }
    _sessionPickedImages.clear();
    _loadSavedImages();
  }

  Future<void> _saveConditionIds({
    required int tireId,
    required int wearId,
    required int casingId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _conditionKey(tireId),
        jsonEncode({'wearId': wearId, 'casingId': casingId}),
      );
    } catch (_) {}
  }

  Future<Map<String, int>> _loadConditionIds(int tireId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_conditionKey(tireId));
      if (raw == null) return {'wearId': 0, 'casingId': 0};
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        'wearId': (decoded['wearId'] as num?)?.toInt() ?? 0,
        'casingId': (decoded['casingId'] as num?)?.toInt() ?? 0,
      };
    } catch (e) {
      return {'wearId': 0, 'casingId': 0};
    }
  }

  double convertFromPsi(double value, String targetUnit) => value;
  double convertToPsi(double value, String currentUnit) => value;

  String clean(dynamic val) {
    if (val == null) return '';
    final d = double.tryParse(val.toString());
    if (d == null) return val.toString();
    return d.round().toString();
  }


  String cleanPressure(dynamic val) {
    if (val == null) return '';
    final d = double.tryParse(val.toString());
    if (d == null) return val.toString();
    return d.round().toString();
  }
  String _displayDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return LocaleHelper.formatDateTime(DateTime.now().toIso8601String());
    }
    return LocaleHelper.formatDateTime(raw);
  }

  // COMMENT PERSISTENCE
  Future<String> _loadPersistedComment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_commentKey)) {
        return prefs.getString(_commentKey) ?? '';
      }
      final realId = tire.tireId;
      if (realId != null && realId > 0) {
        for (final key in prefs.getKeys()) {
          if (!key.startsWith('inspect_tire_comment_-')) continue;
          final tempIdStr = key.replaceFirst('inspect_tire_comment_', '');
          final tempId = int.tryParse(tempIdStr);
          if (tempId == null || tempId >= 0) continue;
          final mapped = prefs.getInt('tyre_real_id_$tempId');
          if (mapped == realId) {
            final val = prefs.getString(key) ?? '';
            if (val.isNotEmpty) {
              await prefs.setString(_commentKey, val);
            }
            return val;
          }
        }
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  Future<void> _savePersistedComment(String comment) async {
    try {
      final cleaned = comment.trim();
      if (cleaned.isEmpty || cleaned.toLowerCase() == 'rotation') return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_commentKey, cleaned);
    } catch (_) {}
  }

  Future<void> _saveStillRelevant(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_stillRelevantKey, value);
    } catch (_) {}
  }

  Future<bool> _loadStillRelevant() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_stillRelevantKey)) {
        return prefs.getBool(_stillRelevantKey) ?? false;
      }
      final realId = tire.tireId;
      if (realId != null && realId > 0) {
        for (final key in prefs.getKeys()) {
          if (!key.startsWith('inspect_tire_still_relevant_-')) continue;
          final tempIdStr = key.replaceFirst(
            'inspect_tire_still_relevant_',
            '',
          );
          final tempId = int.tryParse(tempIdStr);
          if (tempId == null || tempId >= 0) continue;
          final mapped = prefs.getInt('tyre_real_id_$tempId');
          if (mapped == realId) {
            final val = prefs.getBool(key) ?? false;
            await prefs.setBool(_stillRelevantKey, val);
            return val;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  String _resolveComment({
    required String? tireComment,
    required String? apiComment,
    required String persistedComment,
  }) {
    if (persistedComment.isNotEmpty &&
        persistedComment.toLowerCase() != 'rotation') {
      return persistedComment;
    }
    final api = (apiComment ?? '').trim();
    if (api.isNotEmpty && api.toLowerCase() != 'rotation') return api;
    final tc = (tireComment ?? '').trim();
    if (tc.isNotEmpty && tc.toLowerCase() != 'rotation') return tc;
    return '';
  }

  // onInit
  @override
  void onInit() async {
    super.onInit();
    // 🔑 Sabse pehle tyre resolve karo (kisi bhi await/throw se pehle).
    final dynamic args = Get.arguments;
    final InstalledTire? resolved =
        _initialTire ?? (args is InstalledTire ? args : null);
    if (resolved == null) {
      debugPrint('❌ [InspectTyre] tyre nahi mila (initialTire=null, Get.arguments=${args?.runtimeType}) -> screen band');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.key.currentState?.canPop() ?? false) Get.back();
      });
      return;
    }
    tire = resolved;
    hasTire = true;
    _userEditedTread = false;
    _userEditedPressure = false;
    noOfTreadDepthReadings.value = SecureStorage.getNoOfTreadDepthReadings();
    if (Get.isRegistered<GlobalPrefsState>()) {
      ever(GlobalPrefsState.to.measurement, (_) {
        _recomputeDisplayUnits();
      });
      ever(GlobalPrefsState.to.pressure, (_) {
        _recomputeDisplayUnits();
      });
    }
    await _migrateTempIdKeysIfNeeded();
    final bool isInventoryTyre = (tire.dispositionId == 8) ||
        (tire.dispositionName?.trim().toLowerCase() == 'inventory') ||
        (tire.vehicleId == null || tire.vehicleId == 0);
    if (isInventoryTyre && (tire.tireId ?? 0) > 0) {
      await purgeTireInspectionCache(tire.tireId!, tire.tireSerialNo);
      isHotPressure.value = false;
      localImages.clear();
    }
    _loadPreferences();
    await _loadHotColdPref();
    await _setInitialValuesFromTire();
    await loadMasterData();
    await loadTireData();
    if (!isInventoryTyre) {
      await _loadSavedImages();
    }
    _preselectConditions();

    _recoverLostImage();
  }

  Future<void> _recoverLostImage() async {
    if (!Platform.isAndroid) return;
    try {
      final LostDataResponse response = await picker.retrieveLostData();
      if (response.isEmpty) return;

      if (response.file != null) {
        final permanentFile = await _copyToPermanentStorage(
          response.file!.path,
        );
        if (permanentFile != null && permanentFile.existsSync()) {
          await ImageWatermarkHelper.stampImage(permanentFile);
          localImages.add(permanentFile);
          _sessionPickedImages.add(permanentFile.path);
        }
      }
    } catch (_) {
    }
  }

  Future<void> _migrateTempIdKeysIfNeeded() async {
    try {
      final tempId = tire.tireId;
      if (tempId == null || tempId >= 0) return;

      final prefs = await SharedPreferences.getInstance();
      final realId = prefs.getInt('tyre_real_id_$tempId');
      if (realId == null || realId <= 0) return;
      tire = InstalledTire(
        tireId: realId,
        tireSerialNo: tire.tireSerialNo,
        wheelPosition: tire.wheelPosition,
        vehicleId: tire.vehicleId,
        currentHours: tire.currentHours,
        currentMiles: tire.currentMiles,
        currentTreadDepth: tire.currentTreadDepth,
        percentageWorn: tire.percentageWorn,
        outsideTread: tire.outsideTread,
        middleTread: tire.middleTread,
        insideTread: tire.insideTread,
        currentPressure: tire.currentPressure,
        originalTread: tire.originalTread,
        removeAt: tire.removeAt,
        wearConditionId: tire.wearConditionId,
        casingConditionId: tire.casingConditionId,
        comments: tire.comments,
        brandNo: tire.brandNo,
        inspectionDate: tire.inspectionDate,
        isFromSearch: tire.isFromSearch,
        sizeName: tire.sizeName,
        typeName: tire.typeName,
        manufacturerName: tire.manufacturerName,
        dispositionId: tire.dispositionId,
        imagesLocation: tire.imagesLocation,
        locationId: tire.locationId,
        parentAccountId: tire.parentAccountId,
        mileageType: tire.mileageType,
        registeredDate: tire.registeredDate,
        manufacturerId: tire.manufacturerId,
        typeId: tire.typeId,
        sizeId: tire.sizeId,
        mountedRimId: tire.mountedRimId,
        pressureType: tire.pressureType,
        wearNonSkid: tire.wearNonSkid,
        removalReasonId: tire.removalReasonId,
        createdBy: tire.createdBy,
      );
      final tempCommentKey = 'inspect_tire_comment_$tempId';
      final tempHotColdKey = 'inspect_tire_hotcold_$tempId';
      final tempImagesKey = 'inspect_tire_images_$tempId';
      final tempStillRelKey = 'inspect_tire_still_relevant_$tempId';

      final realCommentKey = 'inspect_tire_comment_$realId';
      final realHotColdKey = 'inspect_tire_hotcold_$realId';
      final realImagesKey = 'inspect_tire_images_$realId';
      final realStillRelKey = 'inspect_tire_still_relevant_$realId';

      // Comment migrate
      if (!prefs.containsKey(realCommentKey)) {
        final oldComment = prefs.getString(tempCommentKey);
        if (oldComment != null && oldComment.isNotEmpty) {
          await prefs.setString(realCommentKey, oldComment);
        }
      }
      // HotCold migrate
      if (!prefs.containsKey(realHotColdKey)) {
        final oldHot = prefs.getBool(tempHotColdKey);
        if (oldHot != null) {
          await prefs.setBool(realHotColdKey, oldHot);
        }
      }
      // stillRelevant migrate
      if (!prefs.containsKey(realStillRelKey)) {
        final oldStillRel = prefs.getBool(tempStillRelKey);
        if (oldStillRel != null) {
          await prefs.setBool(realStillRelKey, oldStillRel);
        }
      }
      // Images migrate
      if (!prefs.containsKey(realImagesKey)) {
        final oldImages = prefs.getStringList(tempImagesKey);
        if (oldImages != null && oldImages.isNotEmpty) {
          await prefs.setStringList(realImagesKey, oldImages);
        }
      }

      if (tire.vehicleId != null && tire.vehicleId! < 0) {
        final realVehicleId = prefs.getInt('vehicle_real_id_${tire.vehicleId}');
        if (realVehicleId != null && realVehicleId > 0) {
          tire = InstalledTire(
            tireId: realId,
            tireSerialNo: tire.tireSerialNo,
            wheelPosition: tire.wheelPosition,
            vehicleId: realVehicleId,
            currentHours: tire.currentHours,
            currentMiles: tire.currentMiles,
            currentTreadDepth: tire.currentTreadDepth,
            percentageWorn: tire.percentageWorn,
            outsideTread: tire.outsideTread,
            middleTread: tire.middleTread,
            insideTread: tire.insideTread,
            currentPressure: tire.currentPressure,
            originalTread: tire.originalTread,
            removeAt: tire.removeAt,
            wearConditionId: tire.wearConditionId,
            casingConditionId: tire.casingConditionId,
            comments: tire.comments,
            brandNo: tire.brandNo,
            inspectionDate: tire.inspectionDate,
            isFromSearch: tire.isFromSearch,
            sizeName: tire.sizeName,
            typeName: tire.typeName,
            manufacturerName: tire.manufacturerName,
            dispositionId: tire.dispositionId,
            imagesLocation: tire.imagesLocation,
            locationId: tire.locationId,
            parentAccountId: tire.parentAccountId,
            mileageType: tire.mileageType,
            registeredDate: tire.registeredDate,
            manufacturerId: tire.manufacturerId,
            typeId: tire.typeId,
            sizeId: tire.sizeId,
            mountedRimId: tire.mountedRimId,
            pressureType: tire.pressureType,
            wearNonSkid: tire.wearNonSkid,
            removalReasonId: tire.removalReasonId,
            createdBy: tire.createdBy,
          );
        }
      }
    } catch (_) {}
  }

  void _loadPreferences() {
    final savedPressure = HivePref.get<String>('pref_pressure');
    if (savedPressure != null && savedPressure.isNotEmpty) {
      pressureUnit.value = savedPressure.toUpperCase();
    }
    final savedMeasurement = HivePref.get<String>('pref_measurement');
    if (savedMeasurement != null && savedMeasurement.isNotEmpty) {
      measurementUnit.value = savedMeasurement.toLowerCase() == 'metric'
          ? 'mm'
          : '/32nds';
      kmMilesLabel.value = savedMeasurement.toLowerCase() == 'metric'
          ? 'KM'
          : 'Miles';
    }
  }

  void _recomputeDisplayUnits() {
    _loadPreferences();
    if (!_userEditedTread) {
      final treadSrc = TyreUnitHistory.getTreadUnit(tire.tireId);
      final rawOutside = TyreUnitHistory.getRawOutside(tire.tireId) ?? tire.outsideTread ?? 0.0;
      final rawMiddle = TyreUnitHistory.getRawMiddle(tire.tireId) ?? tire.middleTread ?? 0.0;
      final rawInside = TyreUnitHistory.getRawInside(tire.tireId) ?? tire.insideTread ?? 0.0;

      final double displayOutside = MeasurementHelper.toDisplayTread(rawOutside, sourceUnit: treadSrc);
      final double displayMiddle = MeasurementHelper.toDisplayTread(rawMiddle, sourceUnit: treadSrc);
      final double displayInside = MeasurementHelper.toDisplayTread(rawInside, sourceUnit: treadSrc);

      model.update((m) {
        if (m != null) {
          m.outsideTread = displayOutside;
          m.middleTread = displayMiddle;
          m.insideTread = displayInside;
          _calcAverage(m);
        }
      });

      outsideTreadController.text = clean(displayOutside);
      middleTreadController.text = clean(displayMiddle);
      insideTreadController.text = clean(displayInside);
    }

    if (!_userEditedPressure) {
      final pressureSrc = TyreUnitHistory.getPressureUnit(tire.tireId);
      final rawPress = TyreUnitHistory.getRawPressure(tire.tireId) ?? tire.currentPressure ?? 0.0;
      final double displayPressure = tire.isFromSearch
          ? rawPress
          : MeasurementHelper.toDisplayPressure(rawPress, sourceUnit: pressureSrc);

      model.update((m) {
        if (m != null) {
          m.airPressure = displayPressure;
          m.currentPressure = displayPressure;
        }
      });
      airPressureController.text = cleanPressure(displayPressure);
    }
    update();
  }

  // setInitialValuesFromTire
  Future<void> _setInitialValuesFromTire() async {
    final persistedComment = await _loadPersistedComment();
    final savedStillRelevant = await _loadStillRelevant();

    final rawTireComment = (tire.comments ?? '').trim();
    final tireComment = rawTireComment.toLowerCase() == 'rotation'
        ? ''
        : rawTireComment;

    final resolvedComment = _resolveComment(
      tireComment: tireComment,
      apiComment: null,
      persistedComment: persistedComment,
    );

    commentCtrl.addListener(() {
      model.update((m) => m!.comments = commentCtrl.text);
    });

    previousCommentsCtrl.text = resolvedComment;
    stillRelevant.value = savedStillRelevant;
    if (savedStillRelevant) {
      commentCtrl.text = resolvedComment;
    } else {
      commentCtrl.text = '';
    }

    final treadSrc = TyreUnitHistory.getTreadUnit(tire.tireId);
    final pressureSrc = TyreUnitHistory.getPressureUnit(tire.tireId);

    final double displayOutside = MeasurementHelper.toDisplayTread(
      tire.outsideTread ?? 0.0,
      sourceUnit: treadSrc,
    );
    final double displayMiddle = MeasurementHelper.toDisplayTread(
      tire.middleTread ?? 0.0,
      sourceUnit: treadSrc,
    );
    final double displayInside = MeasurementHelper.toDisplayTread(
      tire.insideTread ?? 0.0,
      sourceUnit: treadSrc,
    );
    // ✅ ROOT-CAUSE FIX: Search screen (SearchVehicleTyreController) ka
    // backend endpoint currentPressure ko ALREADY current-preference unit
    // (jaise PSI) me convert karke bhejta hai — Vehicle Diagram wale
    // endpoint jaisa RAW/original-unit value nahi bhejta. Agar hum us
    // already-converted value ko dobara MeasurementHelper se convert
    // karte hain (BAR history maan ke), toh double-conversion ho jaata
    // hai (100 -> 1450 -> 21036). Isliye jab tyre search se aaya ho,
    // seedha as-is value use karo, dobara convert mat karo.
    final double displayPressure = tire.isFromSearch
        ? (tire.currentPressure ?? 0.0)
        : MeasurementHelper.toDisplayPressure(
      tire.currentPressure ?? 0.0,
      sourceUnit: pressureSrc,
    );

    model.update((m) {
      m!.outsideTread = displayOutside;
      m.middleTread = displayMiddle;
      m.insideTread = displayInside;
      m.airPressure = displayPressure;
      m.currentPressure = displayPressure;
      m.wheelPosition = tire.wheelPosition;
      m.tireSerialNo = tire.tireSerialNo;
      m.vehicleId = tire.vehicleId;
      m.currentHours = tire.currentHours;
      m.currentMiles = tire.currentMiles;
      m.originalTread = tire.originalTread;
      m.removeAt = tire.removeAt;
      m.comments = resolvedComment;
      _calcAverage(m);
    });

    outsideTreadController.text = clean(displayOutside);
    middleTreadController.text = clean(displayMiddle);
    insideTreadController.text = clean(displayInside);

    airPressureController.text = cleanPressure(displayPressure);

    if (tire.wearConditionId != null && tire.wearConditionId! > 0) {
      selectedWearConditionsId.value = tire.wearConditionId!;
    } else {
      selectedWearConditionsId.value = 0;
      wearConditionsId.clear();
    }

    if (tire.casingConditionId != null && tire.casingConditionId! > 0) {
      selectedCasingConditionId.value = tire.casingConditionId!;
    } else {
      selectedCasingConditionId.value = 0;
      casingConditionsId.clear();
    }

    lastInspectionDateStr.value = _displayDate(tire.inspectionDate);
  }

  // preselectConditions
  void _preselectConditions() {
    if (_isDisposed) return;
    if (selectedWearConditionsId.value > 0 && wearConditionsIdList.isNotEmpty) {
      final idx = wearConditionsIdList.indexOf(selectedWearConditionsId.value);
      if (idx >= 0 && idx < wearConditionsList.length) {
        wearConditionsId.text = wearConditionsList[idx];
      } else {
        wearConditionsId.clear();
      }
    } else {
      wearConditionsId.clear();
    }

    if (selectedCasingConditionId.value > 0 &&
        casingConditionIdList.isNotEmpty) {
      final idx = casingConditionIdList.indexOf(
        selectedCasingConditionId.value,
      );
      if (idx >= 0 && idx < casingConditionList.length) {
        casingConditionsId.text = casingConditionList[idx];
      } else {
        casingConditionsId.clear();
      }
    } else {
      casingConditionsId.clear();
    }

    update();
  }

  // loadMasterData
  Future<void> loadMasterData() async {
    try {
      final data = await _masterService.fetchMasterData();

      wearConditionsList.assignAll(
        (data['wearConditions'] as List)
            .map((e) => e['wearConditionName'].toString())
            .toList(),
      );
      wearConditionsIdList.assignAll(
        (data['wearConditions'] as List)
            .map((e) => e['wearConditionId'] as int)
            .toList(),
      );
      casingConditionList.assignAll(
        (data['casingCondition'] as List)
            .map((e) => e['casingConditionName'].toString())
            .toList(),
      );
      casingConditionIdList.assignAll(
        (data['casingCondition'] as List)
            .map((e) => e['casingConditionId'] as int)
            .toList(),
      );

      if (selectedWearConditionsId.value == 0 &&
          (tire.wearConditionId ?? 0) > 0) {
        selectedWearConditionsId.value = tire.wearConditionId!;
      }
      if (selectedCasingConditionId.value == 0 &&
          (tire.casingConditionId ?? 0) > 0) {
        selectedCasingConditionId.value = tire.casingConditionId!;
      }

      _preselectConditions();
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  // loadTireData
  Future<void> loadTireData() async {
    if (_isDisposed) return;

    lastInspectionDateStr.value = _displayDate(tire.inspectionDate);

    if (tire.tireId != null && tire.tireId != 0) {
      final saved = await _loadConditionIds(tire.tireId!);

      final treadSrc = TyreUnitHistory.getTreadUnit(tire.tireId);
      final pressureSrc = TyreUnitHistory.getPressureUnit(tire.tireId);

      final argOutside = MeasurementHelper.toDisplayTread(
        tire.outsideTread ?? 0.0,
        sourceUnit: treadSrc,
      );
      final argMiddle = MeasurementHelper.toDisplayTread(
        tire.middleTread ?? 0.0,
        sourceUnit: treadSrc,
      );
      final argInside = MeasurementHelper.toDisplayTread(
        tire.insideTread ?? 0.0,
        sourceUnit: treadSrc,
      );
      // ✅ Same root-cause fix as _setInitialValuesFromTire — search se
      // aayi value already display-unit me converted hoti hai, dobara
      // convert mat karo.
      final argPressure = tire.isFromSearch
          ? (tire.currentPressure ?? 0.0)
          : MeasurementHelper.toDisplayPressure(
        tire.currentPressure ?? 0.0,
        sourceUnit: pressureSrc,
      );

      try {
        final data = await service.getTireById(tire.tireId!);
        if (_isDisposed) return;
        final apiModel = InspectTyreModel.fromJson(data);

        // Server / cached images (skip if inventory tyre being installed fresh)
        final bool isInventoryTyre = (tire.dispositionId == 8) ||
            (tire.dispositionName?.trim().toLowerCase() == 'inventory') ||
            (tire.vehicleId == null || tire.vehicleId == 0);
        if (!isInventoryTyre) {
          for (final u in (apiModel.imagesLocation ?? '')
              .toString()
              .split(',')
              .map((String e) => e.trim())
              .where((String e) => e.isNotEmpty)) {
            final resolved = await LocalImageCache.resolveLocalFile(u, tireId: tire.tireId);
            if (resolved != null && resolved.existsSync()) {
              if (!localImages.any((f) => f.path == resolved.path)) {
                localImages.add(resolved);
              }
            } else {
              _injectRemoteImageUrl(u);
              if (u.startsWith('http')) {
                LocalImageCache.cacheNetworkImage(u);
              }
            }
          }
        }

        model.update((m) {

          final apiOutside = MeasurementHelper.toDisplayTread(
            apiModel.outsideTread,
            sourceUnit: treadSrc,
          );
          final apiMiddle = MeasurementHelper.toDisplayTread(
            apiModel.middleTread,
            sourceUnit: treadSrc,
          );
          final apiInside = MeasurementHelper.toDisplayTread(
            apiModel.insideTread,
            sourceUnit: treadSrc,
          );

          if (!_userEditedTread) {
            m!.outsideTread = argOutside > 0 ? argOutside : apiOutside;
            m.middleTread = argMiddle > 0 ? argMiddle : apiMiddle;
            m.insideTread = argInside > 0 ? argInside : apiInside;
          }
          // ✅ Vehicle diagram wale logic jaisa: seedha tire.currentPressure
          // (argPressure) use karo. Pehle yaha `apiPressure > argPressure`
          // (max) le liya jaata tha, jisse agar API se raw/unconverted
          // ya galat-scale wali value aa jaaye (jaise 21036), toh wahi
          // dikhne lag jaati thi bajaye sahi 1450 ke. Ab dono screens
          // (diagram + inspect tyre) hamesha same value dikhayenge.
          m!.airPressure = argPressure;
          m.currentPressure = m.airPressure!;
          // Debug reference only, kabhi UI me use mat karna:
          // apiPressure = $apiPressure

          selectedWearConditionsId.value = saved['wearId']! > 0
              ? saved['wearId']!
              : (apiModel.wearConditionId ?? tire.wearConditionId ?? 0);
          selectedCasingConditionId.value = saved['casingId']! > 0
              ? saved['casingId']!
              : (apiModel.casingConditionId ?? tire.casingConditionId ?? 0);

          _calcAverage(m);
        });

        if (!_userEditedTread) {
          outsideTreadController.text = clean(model.value.outsideTread);
          middleTreadController.text = clean(model.value.middleTread);
          insideTreadController.text = clean(model.value.insideTread);
        }

        double apiDisplayValue = convertFromPsi(
          model.value.airPressure ?? 0.0,
          pressureUnit.value,
        );

        airPressureController.text = cleanPressure(apiDisplayValue);
      } catch (e) {
        final hiveTyre = (tire.tireId != null && tire.tireId! > 0)
            ? OfflineHiveService.getTyreById(tire.tireId!)
            : null;

        model.update((m) {
          if (hiveTyre != null) {
            final hiveOutside = MeasurementHelper.toDisplayTread(
              hiveTyre.outsideTread ?? 0.0,
              sourceUnit: treadSrc,
            );
            final hiveMiddle = MeasurementHelper.toDisplayTread(
              hiveTyre.middleTread ?? 0.0,
              sourceUnit: treadSrc,
            );
            final hiveInside = MeasurementHelper.toDisplayTread(
              hiveTyre.insideTread ?? 0.0,
              sourceUnit: treadSrc,
            );

            if (!_userEditedTread) {
              m!.outsideTread = argOutside > 0 ? argOutside : hiveOutside;
              m.middleTread = argMiddle > 0 ? argMiddle : hiveMiddle;
              m.insideTread = argInside > 0 ? argInside : hiveInside;
            }
            // ✅ Same fix: diagram wale logic jaisa seedha argPressure use karo.
            m!.airPressure = argPressure;
            m.currentPressure = m.airPressure!;
          } else {
            if (!_userEditedTread) {
              m!.outsideTread = argOutside;
              m.middleTread = argMiddle;
              m.insideTread = argInside;
            }
            m!.airPressure = argPressure;
            m.currentPressure = argPressure;
          }
          _calcAverage(m);
        });

        if (!_userEditedTread) {
          outsideTreadController.text = clean(model.value.outsideTread);
          middleTreadController.text = clean(model.value.middleTread);
          insideTreadController.text = clean(model.value.insideTread);
        }

        if (model.value.airPressure != null && model.value.airPressure! > 0) {
          double localDisplayValue = convertFromPsi(
            model.value.airPressure!,
            pressureUnit.value,
          );

          airPressureController.text = cleanPressure(localDisplayValue);
        }
      }
    }
    _preselectConditions();
  }

  void _injectRemoteImageUrl(String url) {
    final remoteFile = File(url);
    if (!localImages.any((f) => f.path == url)) {
      localImages.add(remoteFile);
    }
  }

  // IMAGE helpers
  Future<void> _loadSavedImages() async {
    try {
      final tId = tire.tireId;
      final prefs = await SharedPreferences.getInstance();
      final Set<String> candidates = {};

      if (tire.imagesLocation != null && tire.imagesLocation.toString().trim().isNotEmpty) {
        for (final p in tire.imagesLocation.toString().split(',')) {
          final t = p.trim();
          if (t.isNotEmpty) candidates.add(t);
        }
      }

      if (tId != null) {
        final sp = prefs.getStringList('inspect_tire_images_$tId');
        if (sp != null) candidates.addAll(sp);

        for (final k in prefs.getKeys()) {
          if (k.startsWith('tyre_real_id_') && prefs.getInt(k) == tId) {
            final tempId = k.replaceFirst('tyre_real_id_', '');
            final tempSp = prefs.getStringList('inspect_tire_images_$tempId');
            if (tempSp != null) candidates.addAll(tempSp);
          }
        }
      }

      if (tId != null && tId > 0) {
        final cached = OfflineHiveService.getTireDetailCache(tId);
        if (cached != null) {
          try {
            final decoded = jsonDecode(cached) as Map<String, dynamic>;
            final innerModel = decoded['model'] as Map<String, dynamic>?;
            final loc = innerModel?['imagesLocation']?.toString();
            if (loc != null && loc.trim().isNotEmpty) {
              for (final p in loc.split(',')) {
                final t = p.trim();
                if (t.isNotEmpty) candidates.add(t);
              }
            }
          } catch (_) {}
        }
      }

      if (tId != null) {
        final diskFiles = await LocalImageCache.getLocalImagesForTire(tId);
        for (final f in diskFiles) {
          candidates.add(f.path);
        }
      }

      for (final c in candidates) {
        final resolved = await LocalImageCache.resolveLocalFile(c, tireId: tId);
        if (resolved != null && resolved.existsSync()) {
          if (!localImages.any((f) => f.path == resolved.path)) {
            localImages.add(resolved);
          }
        } else if (c.startsWith('http')) {
          if (!localImages.any((f) => f.path == c)) {
            localImages.add(File(c));
          }
          LocalImageCache.cacheNetworkImage(c);
        } else if (File(c).existsSync()) {
          if (!localImages.any((f) => f.path == c)) {
            localImages.add(File(c));
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _saveImagePaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paths = localImages.map((f) => f.path).toList();
      await prefs.setStringList(_prefsKey, paths);
      final tId = tire.tireId;
      if (tId != null) {
        await prefs.setStringList('inspect_tire_images_$tId', paths);
      }
    } catch (_) {}
  }
  void onAirPressureChanged(String value) {
    _userEditedPressure = true;
    final parsed = double.tryParse(value);
    if (parsed != null) {
      model.value.airPressure = parsed;
      model.value.currentPressure = parsed;
    }
  }

  void incAir() {
    _userEditedPressure = true;
    double step = 1.0;
    double newVal = (model.value.airPressure ?? 0.0) + step;
    model.update((m) {
      m!.airPressure = newVal;
      m.currentPressure = newVal;
    });
    airPressureController.text = cleanPressure(newVal);
  }

  void decAir() {
    _userEditedPressure = true;
    double step = 1.0;
    double newVal = ((model.value.airPressure ?? 0.0) - step).clamp(
      0.0,
      double.infinity,
    );
    model.update((m) {
      m!.airPressure = newVal;
      m.currentPressure = newVal;
    });
    airPressureController.text = cleanPressure(newVal);
  }

  void onOutsideTreadChanged(String value) {
    _userEditedTread = true;
    final val = double.tryParse(value) ?? 0.0;
    model.update((m) {
      m!.outsideTread = val;
      _calcAverage(m);
    });
  }

  void onMiddleTreadChanged(String value) {
    _userEditedTread = true;
    final val = double.tryParse(value) ?? 0.0;
    model.update((m) {
      m!.middleTread = val;
      _calcAverage(m);
    });
  }

  void onInsideTreadChanged(String value) {
    _userEditedTread = true;
    final val = double.tryParse(value) ?? 0.0;
    model.update((m) {
      m!.insideTread = val;
      _calcAverage(m);
    });
  }

  void incOutside() {
    _userEditedTread = true; // ✅ user edit flag
    model.update((m) {
      m!.outsideTread++;
      outsideTreadController.text = clean(m.outsideTread);
      _calcAverage(m);
    });
  }

  void decOutside() {
    _userEditedTread = true;
    model.update((m) {
      if (m!.outsideTread > 0) m.outsideTread--;
      outsideTreadController.text = clean(m.outsideTread);
      _calcAverage(m);
    });
  }

  void incMiddle() {
    _userEditedTread = true; // ✅ user edit flag
    model.update((m) {
      m!.middleTread++;
      middleTreadController.text = clean(m.middleTread);
      _calcAverage(m);
    });
  }

  void decMiddle() {
    _userEditedTread = true;
    model.update((m) {
      if (m!.middleTread > 0) m.middleTread--;
      middleTreadController.text = clean(m.middleTread);
      _calcAverage(m);
    });
  }

  void incInside() {
    _userEditedTread = true;
    model.update((m) {
      m!.insideTread++;
      insideTreadController.text = clean(m.insideTread);
      _calcAverage(m);
    });
  }

  void decInside() {
    _userEditedTread = true;
    model.update((m) {
      if (m!.insideTread > 0) m.insideTread--;
      insideTreadController.text = clean(m.insideTread);
      _calcAverage(m);
    });
  }

  void _calcAverage(InspectTyreModel m) {
    final int readingCount = noOfTreadDepthReadings.value;
    double avg;

    if (readingCount == 1) {
      avg = m.outsideTread;
    } else if (readingCount == 2) {
      avg = (m.outsideTread + m.insideTread) / 2;
    } else {
      final mid = m.middleTread;
      avg = mid > 0
          ? (m.outsideTread + mid + m.insideTread) / 3
          : (m.outsideTread + m.insideTread) / 2;
    }

    String formatted = avg.toStringAsFixed(2);
    m.averageTread = formatted.replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "");
    m.currentTreadDepth = avg;

    final treadSrc = TyreUnitHistory.getTreadUnit(tire.tireId);
    final removeAt = MeasurementHelper.toDisplayTread(
      tire.removeAt ?? 0.0,
      sourceUnit: treadSrc,
    );
    final origTread = MeasurementHelper.toDisplayTread(
      tire.originalTread ?? 0.0,
      sourceUnit: treadSrc,
    );
    final denominator = (origTread - removeAt) > 0
        ? (origTread - removeAt)
        : (origTread > 0 ? origTread : 1.0);
    final effRemoveAt = (origTread - removeAt) > 0 ? removeAt : 0.0;

    if (denominator != 0) {
      if (readingCount == 1) {
        final usd = (origTread > 0 && m.outsideTread >= origTread)
            ? 0.0
            : ((1 - (m.outsideTread - effRemoveAt) / denominator) * 100)
                .roundToDouble();
        m.percentageWorn = usd.clamp(0.0, 100.0);
      } else if (readingCount == 2) {
        final usd1 = (origTread > 0 && m.outsideTread >= origTread)
            ? 0.0
            : ((1 - (m.outsideTread - effRemoveAt) / denominator) * 100)
                .roundToDouble();
        final usd2 = (origTread > 0 && m.insideTread >= origTread)
            ? 0.0
            : ((1 - (m.insideTread - effRemoveAt) / denominator) * 100)
                .roundToDouble();
        m.percentageWorn = ((usd1 + usd2) / 2).clamp(0.0, 100.0);
      } else {
        final usd1 = (origTread > 0 && m.outsideTread >= origTread)
            ? 0.0
            : ((1 - (m.outsideTread - effRemoveAt) / denominator) * 100)
                .roundToDouble();
        final usd2 = (origTread > 0 && m.insideTread >= origTread)
            ? 0.0
            : ((1 - (m.insideTread - effRemoveAt) / denominator) * 100)
                .roundToDouble();
        final usd3 = (origTread > 0 && m.middleTread >= origTread)
            ? 0.0
            : ((1 - (m.middleTread - effRemoveAt) / denominator) * 100)
                .roundToDouble();
        m.percentageWorn = ((usd1 + usd2 + usd3) / 3).clamp(0.0, 100.0);
      }
    }
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final img = await picker
          .pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
      )
          .timeout(const Duration(minutes: 5));

      if (img != null) {
        isUploadingImages.value = true;

        final permanentFile = await _copyToPermanentStorage(img.path);

        if (permanentFile != null && permanentFile.existsSync()) {
          await ImageWatermarkHelper.stampImage(permanentFile);
          localImages.add(permanentFile);
          _sessionPickedImages.add(permanentFile.path);
        }
      }
    } catch (e) {
      Get.snackbar(
        'Image Error',
        'Failed to capture photo. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
    } finally {
      isUploadingImages.value = false;
    }
  }

  Future<File?> _copyToPermanentStorage(String tempPath) async {
    try {
      if (tempPath.isEmpty) return null;

      final file = File(tempPath);
      if (!file.existsSync()) return null;

      final docsDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(docsDir.path, 'inspect_images'));

      if (!imagesDir.existsSync()) {
        imagesDir.createSync(recursive: true);
      }

      final tireId = tire.tireId ?? 0;
      final fileName =
          'tire_${tireId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final destPath = p.join(imagesDir.path, fileName);

      final copiedFile = await file.copy(destPath);
      return copiedFile;
    } catch (e) {
      return null;
    }
  }

  Future<void> removeLocalImage(int index) async {
    if (index >= 0 && index < localImages.length) {
      final file = localImages[index];
      localImages.removeAt(index);
      _sessionPickedImages.remove(file.path);
      if (isSubmittedSuccessfully) {
        await _saveImagePaths();
      }
      try {
        if (file.existsSync() && !file.path.startsWith('http')) {
          file.deleteSync();
        }
      } catch (_) {}
    }
  }

  void removeTyre(int tireId) {
    model.value = InspectTyreModel(tireId: tireId);
    Get.to(
          () => RemoveTyreView(),
      arguments: {
        'vehicleId': tire.vehicleId ?? 0,
        'vehicleNo': tire.vehicleNumber ?? tire.vehicleId?.toString() ?? '',
        'vehicleNumber': tire.vehicleNumber ?? tire.vehicleId?.toString() ?? '',
        'tireId': tire.tireId ?? tireId,
        'wheelPosition': tire.wheelPosition ?? '',
        'tireSerialNo': tire.tireSerialNo ?? '',
        'brandNumber': '',
        'currentHours': (tire.currentHours ?? 0).toDouble(),
        'currentMiles': (tire.currentMiles ?? 0).toDouble(),
        'outsideTread': (tire.outsideTread ?? 0).toDouble(),
        'middleTread': (tire.middleTread ?? 0).toDouble(),
        'insideTread': (tire.insideTread ?? 0).toDouble(),
        'currentTreadDepth': (tire.currentTreadDepth ?? 0).toDouble(),
        'currentPressure': (tire.currentPressure ?? 0).toDouble(),
        'originalTread': (tire.originalTread ?? 0).toDouble(),
        'removeAt': (tire.removeAt ?? 0).toDouble(),
      },
    );
  }

  // SUBMIT
  Future<void> submit() async {
    if (isSubmitting.value) return;

    // 🔒 Vehicle ka pichla inspection approval ke liye pending hai to block.
    if (!await PendingInspectionGuard.canProceed(
      vehicleId: tire.vehicleId,
      vehicleNumber: tire.vehicleNumber,
      action: PendingBlockedAction.tyreInspection,
    )) {
      return;
    }

    try {
      isSubmitting.value = true;

      String displayVehicleNo = 'N/A';
      try {
        if (Get.isRegistered<VehicleInspeController>()) {
          final text =
              Get.find<VehicleInspeController>().vehicleNumberCtrl.text;
          if (text.isNotEmpty) displayVehicleNo = text;
        } else if (tire.brandNo != null && tire.brandNo!.isNotEmpty) {
          displayVehicleNo = tire.brandNo!;
        }
      } catch (_) {}

      final parentAccountIdStr = await SecureStorage.getParentAccountId();
      final locationIdStr = await SecureStorage.getLocationId();
      final parentAccountId = int.tryParse(parentAccountIdStr ?? '') ?? 0;
      final locationId = int.tryParse(locationIdStr ?? '') ?? 0;
      final locationName = await SecureStorage.getLocationName() ?? '';
      final requestorName = await SecureStorage.getUserProfileName() ?? '';
      final accountName = await SecureStorage.getParentAccountName() ?? '';

      final int? resolvedTireId = (tire.tireId != null && tire.tireId != 0)
          ? tire.tireId
          : (model.value.tireId != null && model.value.tireId != 0
          ? model.value.tireId
          : null);

      if (resolvedTireId == null || resolvedTireId == 0) {
        Get.snackbar(
          'Error',
          'Tire ID missing.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      String imagesLocation = '';
      final realPhysicalFiles = localImages
          .where((f) => !f.path.startsWith('http'))
          .toList();
      // Photos must be uploaded BEFORE the save so their server URLs are
      // part of the tyre record (`imagesLocation`). The approval screens
      // (inspection_approval/tyre.dart) read the photos back from that
      // record — e.g. after the app is re-installed. Upload response
      // carries the blob URL in `message` (CreateImages doc).
      if (realPhysicalFiles.isNotEmpty) {
        // The server replaces the tyre's photo list with the files of the
        // latest upload, so the photos already on the server are re-sent
        // together with the new ones -> nothing gets lost.
        final existingRemote = localImages
            .where((f) => f.path.startsWith('http'))
            .map((f) => f.path)
            .toList();
        final up = await service.uploadTireImagesKeepingExisting(
          newImages: realPhysicalFiles,
          existingUrls: existingRemote,
          tireId: resolvedTireId,
        );
        if (up.isNotEmpty) {
          imagesLocation = up;
          final upUrls = up.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          for (var i = 0; i < realPhysicalFiles.length; i++) {
            if (i < upUrls.length) {
              await LocalImageCache.associate(upUrls[i], realPhysicalFiles[i].path);
            }
          }
          localImages.removeWhere((f) => realPhysicalFiles.any((rf) => rf.path == f.path));
          for (final u in upUrls) {
            if (!localImages.any((f) => f.path == u)) {
              localImages.add(File(u));
            }
          }
        }
      }
      if (imagesLocation.isEmpty && realPhysicalFiles.isNotEmpty) {
        imagesLocation = realPhysicalFiles.map((f) => f.path).join(',');
      }
      if (imagesLocation.isEmpty && localImages.isNotEmpty) {
        imagesLocation = localImages.map((f) => f.path).join(',');
      }
      if (imagesLocation.isNotEmpty) {
        // Strict deduplication of URLs
        final uniqueLocs = imagesLocation
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .join(',');
        imagesLocation = uniqueLocs;
        tire.imagesLocation = imagesLocation;
        model.value.imagesLocation = imagesLocation;
      }

      // ✅ FIX: if the user never touched the tread/pressure fields (just
      // switched unit preference back and forth, or submitted for some
      // other change like a comment/photo), DON'T re-save the current
      // *display-unit* value as a new raw baseline — that's what caused
      // 100 -> 126 -> 101 style drift. Instead keep sending the tyre's
      // original raw values untouched, so the stored raw + its original
      // unit never change unless the person actually edits that field.
      final double outside =
      _userEditedTread ? model.value.outsideTread : (tire.outsideTread ?? model.value.outsideTread);
      final double inside =
      _userEditedTread ? model.value.insideTread : (tire.insideTread ?? model.value.insideTread);
      final double middle =
      _userEditedTread ? model.value.middleTread : (tire.middleTread ?? model.value.middleTread);

      // Validate tread depth against previous depth to prevent server rejection:
      // "Outside tread (X) cannot exceed previous depth (Y). A tyre cannot gain tread."
      final double prevOutside = (tire.outsideTread ?? 0.0).toDouble();
      final double prevMiddle = (tire.middleTread ?? 0.0).toDouble();
      final double prevInside = (tire.insideTread ?? 0.0).toDouble();
      final bool isNewTyre = tire.dispositionId == 7 || (tire.tireId != null && tire.tireId! < 0);

      if (!isNewTyre && _userEditedTread) {
        if (prevOutside > 0 && outside > prevOutside) {
          Get.snackbar(
            'Invalid Tread Depth',
            'Outside tread (${clean(outside)}) cannot exceed previous depth (${clean(prevOutside)}). A tyre cannot gain tread.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
          return;
        }
        if (prevMiddle > 0 && middle > prevMiddle) {
          Get.snackbar(
            'Invalid Tread Depth',
            'Middle tread (${clean(middle)}) cannot exceed previous depth (${clean(prevMiddle)}). A tyre cannot gain tread.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
          return;
        }
        if (prevInside > 0 && inside > prevInside) {
          Get.snackbar(
            'Invalid Tread Depth',
            'Inside tread (${clean(inside)}) cannot exceed previous depth (${clean(prevInside)}). A tyre cannot gain tread.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
          return;
        }
      }



      final double pressure = _userEditedPressure
          ? (model.value.airPressure ?? 0.0)
          : (tire.currentPressure ?? model.value.airPressure ?? 0.0);
      final treadCount = noOfTreadDepthReadings.value;

      final double avgTread = treadCount == 1
          ? outside.toDouble()
          : treadCount == 2
          ? (outside + inside) / 2
          : (middle > 0
          ? (outside + inside + middle) / 3
          : (outside + inside) / 2);

      await _saveHotColdPref();

      String vehicleNumber = '';
      try {
        if (Get.isRegistered<VehicleInspeController>()) {
          vehicleNumber =
              Get.find<VehicleInspeController>().vehicleNumberCtrl.text;
        }
      } catch (_) {}

      int? resolvedVehicleId = tire.vehicleId ?? model.value.vehicleId;
      if (resolvedVehicleId == null || resolvedVehicleId == 0) {
        try {
          if (Get.isRegistered<VehicleInspeController>()) {
            final vIdStr = Get.find<VehicleInspeController>().vehicleId.value;
            resolvedVehicleId = int.tryParse(vIdStr);
          }
        } catch (_) {}
      }

      if (resolvedVehicleId == null || resolvedVehicleId == 0) {
        try {
          if (resolvedTireId > 0) {
            final hiveTyre = OfflineHiveService.getTyreById(resolvedTireId);
            if (hiveTyre?.vehicleId != null && hiveTyre!.vehicleId! > 0) {
              resolvedVehicleId = hiveTyre.vehicleId;
            } else {
              final keys = OfflineHiveService.listInspectionCacheKeys();
              for (final key in keys) {
                final cached = OfflineHiveService.getInspectionCache(key);
                if (cached == null) continue;
                try {
                  final jd = jsonDecode(cached) as Map<String, dynamic>;
                  final tires =
                  (jd['model'] as Map?)?.entries
                      .firstWhere(
                        (e) => e.key == 'installedTires',
                    orElse: () => const MapEntry('', null),
                  )
                      .value
                  as List?;
                  if (tires != null &&
                      tires.any(
                            (t) =>
                        t is Map &&
                            t['tireId']?.toString() ==
                                resolvedTireId.toString(),
                      )) {
                    resolvedVehicleId = int.tryParse(key);
                    break;
                  }
                } catch (_) {}
              }
            }
          }
        } catch (_) {}
      }

      final finalComment = stillRelevant.value
          ? previousCommentsCtrl.text.trim()
          : commentCtrl.text.trim();
      await _savePersistedComment(finalComment);
      await _saveStillRelevant(stillRelevant.value);

      final payload = {
        'action': 'Inspect',
        'inspectionDate': DateTime.now().toIso8601String(),
        'locationId': locationId,
        'parentAccountId': parentAccountId,
        'vehicleId': resolvedVehicleId,
        'vehicleNumber': vehicleNumber,
        'locationName': locationName,
        'accountName': accountName,
        'requestorName': requestorName,
        'inspectedTyreCount': 1,
        'totalTyreCount': 1,
        'tireId': resolvedTireId,
        'currentHours': (tire.currentHours ?? 0).toDouble(),
        'currentMiles': (tire.currentMiles ?? 0).toDouble(),
        // only server URLs go to the backend; local device paths are
        // uploaded separately via Inspection/CreateImages after the save.
        'imagesLocation': (imagesLocation.isNotEmpty
            ? imagesLocation
            : (tire.imagesLocation ?? '').toString())
            .split(',')
            .map((String e) => e.trim())
            .where((String e) => e.startsWith('http'))
            .join(','),
        'tireSerialNo': tire.tireSerialNo ?? '',
        'brandNo': tire.brandNo ?? '',
        'outsideTread': outside.toDouble(),
        'middleTread': middle.toDouble(),
        'insideTread': inside.toDouble(),
        'currentTreadDepth': avgTread.toDouble(),
        'currentPressure': pressure,
        'casingConditionId': selectedCasingConditionId.value,
        'wearConditionId': selectedWearConditionsId.value,
        'comments': finalComment,
        'dispositionId': tire.dispositionId ?? 0,
        'rimDispositionId': 0,
        'wheelPosition': tire.wheelPosition ?? '',
        'percentageWorn':
        model.value.percentageWorn,
        'originalTread': tire.originalTread ?? 0.0,
        'removeAt': tire.removeAt ?? 0.0,
        'pressureType': isHotPressure.value ? 'H' : 'C',
      };

      Future<void> patchInspectionCache() async {
        if (resolvedVehicleId == null || resolvedVehicleId == 0) return;
        try {
          final cachedJson = OfflineHiveService.getInspectionCache(
            resolvedVehicleId.toString(),
          );
          if (cachedJson == null) return;
          final jsonData = jsonDecode(cachedJson) as Map<String, dynamic>;
          final modelMap = jsonData['model'] as Map<String, dynamic>?;
          if (modelMap == null) return;
          final tireList = modelMap['installedTires'] as List? ?? [];
          for (final t in tireList) {
            final ct = t as Map<String, dynamic>;
            if (ct['tireId'] == resolvedTireId) {
              ct['outsideTread'] = outside.toDouble();
              ct['middleTread'] = middle.toDouble();
              ct['insideTread'] = inside.toDouble();
              ct['currentTreadDepth'] = avgTread.toDouble();
              ct['currentPressure'] = pressure;
              ct['wearConditionId'] = selectedWearConditionsId.value;
              ct['casingConditionId'] = selectedCasingConditionId.value;
              ct['comments'] = finalComment;
              ct['inspectionDate'] = DateTime.now().toIso8601String();
              ct['pressureType'] = isHotPressure.value ? 'H' : 'C';
              if (imagesLocation.isNotEmpty) {
                ct['imagesLocation'] = imagesLocation;
              }
              break;
            }
          }
          modelMap['installedTires'] = tireList;
          jsonData['model'] = modelMap;
          await OfflineHiveService.saveInspectionCache(
            resolvedVehicleId.toString(),
            jsonEncode(jsonData),
          );
        } catch (_) {}
      }

      // 💾 Backup pre-inspection readings taaki reject hone par wapas restore ho sake
      TyreUnitHistory.backupPreInspectionReadings(
        tireId: resolvedTireId,
        outside: tire.outsideTread,
        middle: tire.middleTread ?? tire.currentTreadDepth,
        inside: tire.insideTread,
        pressure: tire.currentPressure,
        miles: tire.currentMiles,
        percentageWorn: tire.percentageWorn,
        treadUnit: TyreUnitHistory.getTreadUnit(resolvedTireId) ?? (MeasurementHelper.isMetric ? 'Metric' : 'Imperial'),
        dispositionId: tire.dispositionId,
      );
      if (tire.tireSerialNo != null && tire.tireSerialNo!.isNotEmpty) {
        TyreUnitHistory.backupPreInspectionReadings(
          tireId: tire.tireSerialNo!,
          outside: tire.outsideTread,
          middle: tire.middleTread ?? tire.currentTreadDepth,
          inside: tire.insideTread,
          pressure: tire.currentPressure,
          miles: tire.currentMiles,
          percentageWorn: tire.percentageWorn,
          treadUnit: TyreUnitHistory.getTreadUnit(tire.tireSerialNo!) ?? (MeasurementHelper.isMetric ? 'Metric' : 'Imperial'),
          dispositionId: tire.dispositionId,
        );
      }

      // ✅ FIX: only re-baseline the "saved-in" unit to the CURRENT
      // preference when the person actually edited that field. If they
      // didn't touch tread/pressure at all, keep the previously recorded
      // source unit so future conversions keep round-tripping against the
      // real original value instead of a rounded display value.
      if (_userEditedTread) {
        TyreUnitHistory.recordTreadUnit(
          resolvedTireId,
          MeasurementHelper.isMetric ? 'Metric' : 'Imperial',
        );
      }
      if (_userEditedPressure) {
        TyreUnitHistory.recordPressureUnit(
          resolvedTireId,
          MeasurementHelper.pressureLabel,
        );
      }
      TyreUnitHistory.recordRawReadings(
        tireId: resolvedTireId,
        outside: outside.toDouble(),
        middle: middle.toDouble(),
        inside: inside.toDouble(),
        pressure: pressure,
        miles: (tire.currentMiles ?? 0).toDouble(),
        percentageWorn: model.value.percentageWorn,
        treadUnit: MeasurementHelper.isMetric ? 'Metric' : 'Imperial',
        pressureUnit: MeasurementHelper.pressureLabel,
        distanceUnit: MeasurementHelper.distanceLabel,
      );

      // ✅ DRAFT MODE (EMT user, inside an active Vehicle Inspection): don't
      // call the tyre-inspection API right now. Just stage the readings
      // locally on the vehicle's diagram/tires list — exactly like Install
      // and Remove already do — so the Vehicle Inspection's own submit()
      // picks this tyre up (via _getTireAction -> "Inspect") and sends it
      // as part of the single batched footprint call when the user finally
      // submits the whole inspection.
      if (isInspectionFlow) {
        try {
          await _saveConditionIds(
            tireId: resolvedTireId,
            wearId: selectedWearConditionsId.value,
            casingId: selectedCasingConditionId.value,
          );

          await OfflineHiveService.updateTyreInBox(resolvedTireId, {
            'outsideTread': outside.toDouble(),
            'middleTread': middle.toDouble(),
            'insideTread': inside.toDouble(),
            'currentPressure': pressure,
            'wearConditionId': selectedWearConditionsId.value,
            'casingConditionId': selectedCasingConditionId.value,
            'comments': finalComment,
            'inspectionDate': DateTime.now().toIso8601String(),
            if (imagesLocation.isNotEmpty) 'imagesLocation': imagesLocation,
          });

          await _updateTireDetailCache(
            tireId: resolvedTireId,
            outsideTread: outside.toDouble(),
            middleTread: middle.toDouble(),
            insideTread: inside.toDouble(),
            currentPressure: pressure,
            wearConditionId: selectedWearConditionsId.value,
            casingConditionId: selectedCasingConditionId.value,
            comments: finalComment,
            imagesLocation: imagesLocation,
          );

          await patchInspectionCache();

          _updateParentTireLocally(
            wheelPosition: tire.wheelPosition ?? '',
            outsideTread: outside.toDouble(),
            middleTread: middle.toDouble(),
            insideTread: inside.toDouble(),
            currentTreadDepth: avgTread.toDouble(),
            currentPressure: pressure,
            wear: selectedWearConditionsId.value,
            casing: selectedCasingConditionId.value,
            comments: finalComment,
            imagesLocation: imagesLocation,
            pressureType: isHotPressure.value ? 'H' : 'C',
          );

          lastInspectionDateStr.value = LocaleHelper.formatDateTime(
            DateTime.now().toIso8601String(),
          );
        } catch (_) {}

        isSubmittedSuccessfully = true;
        await _saveImagePaths();

        Get.back(result: true);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppSnackbar.success(
            'Tire Serial: ${tire.tireSerialNo} added to inspection.',
            title: 'Tire Added to Inspection',
          );
        });
        return;
      }

      try {
        await service.submitInspection(payload);

        await _saveConditionIds(
          tireId: resolvedTireId,
          wearId: selectedWearConditionsId.value,
          casingId: selectedCasingConditionId.value,
        );

        await OfflineHiveService.updateTyreInBox(resolvedTireId, {
          'outsideTread': outside.toDouble(),
          'middleTread': middle.toDouble(),
          'insideTread': inside.toDouble(),
          'currentPressure': pressure,
          'wearConditionId': selectedWearConditionsId.value,
          'casingConditionId': selectedCasingConditionId.value,
          'comments': finalComment,
          'inspectionDate': DateTime.now().toIso8601String(),
          if (imagesLocation.isNotEmpty) 'imagesLocation': imagesLocation,
        });

        await _updateTireDetailCache(
          tireId: resolvedTireId,
          outsideTread: outside.toDouble(),
          middleTread: middle.toDouble(),
          insideTread: inside.toDouble(),
          currentPressure: pressure,
          wearConditionId: selectedWearConditionsId.value,
          casingConditionId: selectedCasingConditionId.value,
          comments: finalComment,
          imagesLocation: imagesLocation,
        );

        await patchInspectionCache();

        _updateParentTireLocally(
          wheelPosition: tire.wheelPosition ?? '',
          outsideTread: outside.toDouble(),
          middleTread: middle.toDouble(),
          insideTread: inside.toDouble(),
          currentTreadDepth: avgTread.toDouble(),
          currentPressure: pressure,
          wear: selectedWearConditionsId.value,
          casing: selectedCasingConditionId.value,
          comments: finalComment,
          imagesLocation: imagesLocation,
          pressureType: isHotPressure.value ? 'H' : 'C',
        );

        lastInspectionDateStr.value = LocaleHelper.formatDateTime(
          DateTime.now().toIso8601String(),
        );
        await SecureStorage.saveLastInspectionDate(
          DateTime.now().toIso8601String(),
        );

        if (resolvedVehicleId != null && resolvedVehicleId != 0) {
          await OfflineHiveService.updateTireInInspectionCache(
            resolvedVehicleId.toString(),
            {
              'tireId': resolvedTireId,
              'wheelPosition': tire.wheelPosition ?? '',
              'inspectionDate': DateTime.now().toIso8601String(),
            },
          );
        }

        if (Get.isRegistered<AllVehicleController>()) {
          await Get.find<AllVehicleController>().refreshVehicles();
        }

        isSubmittedSuccessfully = true;
        await _saveImagePaths();

        if (tire.isFromSearch &&
            resolvedVehicleId != null &&
            resolvedVehicleId != 0) {
          if (Get.isRegistered<VehicleInspeController>()) {
            Get.delete<VehicleInspeController>(force: true);
          }
          Get.off(
                () => VehicleInspeView(),
            arguments: resolvedVehicleId,
            preventDuplicates: false,
          );
        } else {
          Get.back(result: true);
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppSnackbar.success(
            'Tire Serial: ${tire.tireSerialNo} inspected successfully on Vehicle $displayVehicleNo',
            title: 'Inspection Successful',
          );
        });
      } catch (e) {
        await _saveConditionIds(
          tireId: resolvedTireId,
          wearId: selectedWearConditionsId.value,
          casingId: selectedCasingConditionId.value,
        );

        await OfflineHiveService.updateTyreInBox(resolvedTireId, {
          'outsideTread': outside.toDouble(),
          'middleTread': middle.toDouble(),
          'insideTread': inside.toDouble(),
          'currentPressure': pressure,
          'wearConditionId': selectedWearConditionsId.value,
          'casingConditionId': selectedCasingConditionId.value,
          'comments': finalComment,
          'inspectionDate': DateTime.now().toIso8601String(),
          if (imagesLocation.isNotEmpty) 'imagesLocation': imagesLocation,
        });

        await _updateTireDetailCache(
          tireId: resolvedTireId,
          outsideTread: outside.toDouble(),
          middleTread: middle.toDouble(),
          insideTread: inside.toDouble(),
          currentPressure: pressure,
          wearConditionId: selectedWearConditionsId.value,
          casingConditionId: selectedCasingConditionId.value,
          comments: finalComment,
          imagesLocation: imagesLocation,
        );

        await patchInspectionCache();

        _updateParentTireLocally(
          wheelPosition: tire.wheelPosition ?? '',
          outsideTread: outside.toDouble(),
          middleTread: middle.toDouble(),
          insideTread: inside.toDouble(),
          currentTreadDepth: avgTread.toDouble(),
          currentPressure: pressure,
          wear: selectedWearConditionsId.value,
          casing: selectedCasingConditionId.value,
          comments: finalComment,
          imagesLocation: imagesLocation,
          pressureType: isHotPressure.value ? 'H' : 'C',
        );

        isSubmittedSuccessfully = true;
        await _saveImagePaths();

        await SecureStorage.saveLastInspectionDate(
          DateTime.now().toIso8601String(),
        );

        if (resolvedVehicleId != null && resolvedVehicleId != 0) {
          await OfflineHiveService.updateTireInInspectionCache(
            resolvedVehicleId.toString(),
            {
              'tireId': resolvedTireId,
              'wheelPosition': tire.wheelPosition ?? '',
              'inspectionDate': DateTime.now().toIso8601String(),
              'pressureType': isHotPressure.value ? 'H' : 'C',
            },
          );
        }

        lastInspectionDateStr.value = LocaleHelper.formatDateTime(
          DateTime.now().toIso8601String(),
        );

        if (tire.isFromSearch &&
            resolvedVehicleId != null &&
            resolvedVehicleId != 0) {
          Get.off(
                () => VehicleInspeView(),
            arguments: resolvedVehicleId,
            preventDuplicates: false,
          );
        } else {
          Get.back(result: true);
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (e.toString().contains('Saved offline')) {
            AppSnackbar.offlineSuccess(
              'Tire Serial: ${tire.tireSerialNo} inspected successfully on Vehicle $displayVehicleNo',
              title: 'Inspection Successful',
            );
          } else {
            Get.snackbar(
              'Sync Note',
              'Data updated locally. Server sync will retry.',
            );
          }
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  // updateParentTireLocally
  void _updateParentTireLocally({
    required String wheelPosition,
    required double outsideTread,
    required double middleTread,
    required double insideTread,
    required double currentTreadDepth,
    required double currentPressure,
    int? wear,
    int? casing,
    String? comments,
    String? imagesLocation,
    String? pressureType,
  }) {
    try {
      if (!Get.isRegistered<VehicleInspeController>()) return;

      final vehicleCtrl = Get.find<VehicleInspeController>();
      final idx = vehicleCtrl.tires.indexWhere(
            (t) => t.wheelPosition == wheelPosition,
      );

      if (idx == -1) return;

      final existing = vehicleCtrl.tires[idx];

      // ✅ FIX: Use the exact percentageWorn computed on the inspect screen.
      // 0.0 is a valid, real wear percentage (new/full-tread tyre) and must NOT
      // be replaced with an old tyre's 90% wear.
      double computedPercent = model.value.percentageWorn;
      final double existingOrig = existing.originalTread ?? 0.0;
      if (existingOrig > 0 && currentTreadDepth >= existingOrig) {
        computedPercent = 0.0;
      } else if (computedPercent < 0 && existing.percentageWorn != null && existing.percentageWorn! >= 0) {
        computedPercent = existing.percentageWorn!;
      }

      final updated = InstalledTire(
        tireId: existing.tireId,
        tireSerialNo: existing.tireSerialNo,
        wheelPosition: existing.wheelPosition,
        vehicleId: existing.vehicleId,
        outsideTread: outsideTread,
        middleTread: middleTread,
        insideTread: insideTread,
        currentTreadDepth: currentTreadDepth,
        currentPressure: currentPressure,
        wearConditionId: (wear != null && wear > 0) ? wear : existing.wearConditionId,
        casingConditionId: (casing != null && casing > 0) ? casing : existing.casingConditionId,
        comments: (comments != null && comments.trim().isNotEmpty) ? comments.trim() : existing.comments,
        currentHours: existing.currentHours,
        currentMiles: existing.currentMiles,
        brandNo: existing.brandNo,
        sizeName: existing.sizeName,
        typeName: existing.typeName,
        manufacturerName: existing.manufacturerName,
        mountedRimId: existing.mountedRimId,
        percentageWorn: computedPercent,
        originalTread: existing.originalTread,
        removeAt: existing.removeAt,
        dispositionId: existing.dispositionId,
        removalReasonId: existing.removalReasonId,
        pressureType: pressureType ?? existing.pressureType,
        locationId: existing.locationId,
        parentAccountId: existing.parentAccountId,
        mileageType: existing.mileageType,
        imagesLocation: imagesLocation != null && imagesLocation.isNotEmpty
            ? imagesLocation
            : existing.imagesLocation,
        inspectionDate: DateTime.now().toIso8601String(),
        registeredDate: existing.registeredDate,
        manufacturerId: existing.manufacturerId,
        typeId: existing.typeId,
        sizeId: existing.sizeId,
        wearNonSkid: existing.wearNonSkid,
        createdBy: existing.createdBy,
      );

      vehicleCtrl.tires[idx] = updated;
      vehicleCtrl.tires.refresh();
      vehicleCtrl.patchTireInCache(updated);
    } catch (_) {}
  }

  // HOT / COLD
  Future<void> toggleHotCold() async {
    isHotPressure.value = !isHotPressure.value;
    await _saveHotColdPref();
  }

  Future<void> _saveHotColdPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hotColdKey, isHotPressure.value);
    } catch (_) {}
  }

  Future<void> _updateTireDetailCache({
    required int tireId,
    required double outsideTread,
    required double insideTread,
    required double currentPressure,
    required int wearConditionId,
    required int casingConditionId,
    double middleTread = 0.0,
    String? comments,
    String? imagesLocation,
  }) async {
    try {
      final cached = OfflineHiveService.getTireDetailCache(tireId);
      if (cached == null) return;

      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      final innerModel = decoded['model'] as Map<String, dynamic>?;
      if (innerModel == null) return;

      innerModel['outsideTread'] = outsideTread;
      innerModel['middleTread'] = middleTread;
      innerModel['insideTread'] = insideTread;
      innerModel['airPressure'] = currentPressure;
      innerModel['currentPressure'] = currentPressure;
      innerModel['wearConditionId'] = wearConditionId;
      innerModel['casingConditionId'] = casingConditionId;
      innerModel['pressureType'] = isHotPressure.value ? 'H' : 'C';
      if (comments != null) innerModel['comments'] = comments;
      if (imagesLocation != null && imagesLocation.isNotEmpty) {
        innerModel['imagesLocation'] = imagesLocation;
      }
      decoded['model'] = innerModel;

      await OfflineHiveService.saveTireDetailCache(tireId, jsonEncode(decoded));
    } catch (_) {}
  }

  Future<void> _loadHotColdPref() async {
    try {
      final bool isInventoryTyre = (tire.dispositionId == 8) ||
          (tire.dispositionName?.trim().toLowerCase() == 'inventory') ||
          (tire.vehicleId == null || tire.vehicleId == 0);
      if (isInventoryTyre) {
        isHotPressure.value = false;
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_hotColdKey)) {
        isHotPressure.value = prefs.getBool(_hotColdKey) ?? false;
        return;
      }
      final realId = tire.tireId;
      if (realId != null && realId > 0) {
        for (final key in prefs.getKeys()) {
          if (!key.startsWith('inspect_tire_hotcold_-')) continue;
          final tempIdStr = key.replaceFirst('inspect_tire_hotcold_', '');
          final tempId = int.tryParse(tempIdStr);
          if (tempId == null || tempId >= 0) continue;
          final mapped = prefs.getInt('tyre_real_id_$tempId');
          if (mapped == realId) {
            final val = prefs.getBool(key);
            if (val != null) {
              isHotPressure.value = val;
              await prefs.setBool(_hotColdKey, val);
            }
            break;
          }
        }
      }
    } catch (_) {}
  }

  @override
  void onClose() {
    _isDisposed = true;
    if (!isSubmittedSuccessfully) {
      discardUnsubmittedImages();
    }
    airPressureController.dispose();
    outsideTreadController.dispose();
    middleTreadController.dispose();
    insideTreadController.dispose();
    commentCtrl.dispose();
    wearConditionsId.dispose();
    casingConditionsId.dispose();
    previousCommentsCtrl.dispose();
    super.onClose();
  }
}