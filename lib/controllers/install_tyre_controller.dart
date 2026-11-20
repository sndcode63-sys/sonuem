import 'dart:convert';
import 'package:emtrack/inspection/vehicle_inspe_controller.dart';
import 'package:emtrack/controllers/all_vehicles_controller.dart';
import 'package:emtrack/models/all_vehicle_account_model.dart';
import 'package:emtrack/models/install_tyre_model.dart';
import 'package:emtrack/services/inspection_service.dart';
import 'package:emtrack/services/master_data_service.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/pending_inspection_guard.dart';
import 'package:image_picker/image_picker.dart';
import '../models/tyre_model.dart';
import '../services/tyre_service.dart';
import '../utils/mesurment_helper_class.dart';
import '../services/install_tyre_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/network_helper.dart';
import '../utils/secure_storage.dart';
import '../utils/local_helper.dart';
import '../utils/tyre_unit_history.dart';
import 'inspect_tyre_controller.dart';

class InstallTyreController extends GetxController {
  final tyreService = TyreService();
  final picker = ImagePicker();
  final _masterService = MasterDataService();
  final _installService = InstallTyreService();
  final inspectionService = InspectionService();

  final RxString lastInspectionDateStr = 'N/A'.obs;
  final RxString pressureUnit = 'PSI'.obs;
  final RxString measurementUnit = '/32nds'.obs;
  final RxString kmMilesLabel = 'KM'.obs;

  final RxBool isSubmitting = false.obs;
  final RxBool isInitialLoading = false.obs;
  final RxBool isOfflineTyre = false.obs;

  final RxInt noOfTreadDepthReadings = 3.obs;

  bool get isInspectionFlow {
    final rawArgs = Get.arguments;
    if (rawArgs is Map && rawArgs['isInspectionFlow'] == true) return true;
    return Get.isRegistered<VehicleInspeController>();
  }

  Rx<InstallTireModel> model = InstallTireModel().obs;

  final wearConditionsList = <String>[].obs;
  final wearConditionsIdList = <int>[].obs;
  final RxInt selectedWearConditionsId = 0.obs;
  final wearConditionsId = TextEditingController();

  final casingConditionList = <String>[].obs;
  final casingConditionIdList = <int>[].obs;
  final RxInt selectedCasingConditionId = 0.obs;
  final casingConditionsId = TextEditingController();

  final dispositionList = <String>[].obs;
  final dispositionIdList = <int>[].obs;
  final RxInt installedDispositionId = 0.obs;

  RxList<TyreModel> tyreList = <TyreModel>[].obs;
  RxDouble avgTread = 0.0.obs;
  final RxString vehicleNumber = ''.obs;

  double safeOriginalTread = 0.0;
  double safeRemoveAt = 0.0;
  int argManufacturerId = 0;
  int argSizeId = 0;
  int argTypeId = 0;
  String argRegisteredDate = '';
  String argManufacturerName = '';
  String argSizeName = '';
  String argTypeName = '';

  final commentsController = TextEditingController();
  final previousCommentController = TextEditingController();
  final airPressureController = TextEditingController();

  final RxBool stillRelevant = false.obs;

  void previousCommentsOnChange() {
    stillRelevant.value = !stillRelevant.value;
  }

  final outsideTreadController = TextEditingController();
  final middleTreadController = TextEditingController();
  final insideTreadController = TextEditingController();

  String _formatDate(DateTime dt) {
    return LocaleHelper.formatApiDate(dt.toIso8601String());
  }
  String _parseDateStr(String raw) {
    return LocaleHelper.formatApiDate(raw);
  }

  double _sanitizePressure(double? v) {
    if (v == null || v < 0 || v > 500) return 0.0;
    return v;
  }

  String clean(dynamic val) {
    if (val == null) return '';
    final d = double.tryParse(val.toString());
    if (d == null) return val.toString();
    return d == d.truncateToDouble() ? d.toInt().toString() : d.toString();
  }

  String formatPressure(dynamic rawValue) {
    if (rawValue == null) return '-';
    final d = double.tryParse(rawValue.toString());
    if (d == null) return rawValue.toString();
    if (d == d.truncateToDouble()) return d.truncate().toString();
    return d.toString();
  }
  String cleanMiles(dynamic val) {
    if (val == null) return '-';
    final d = double.tryParse(val.toString());
    if (d == null) return val.toString();
    if (d == d.truncateToDouble()) return d.truncate().toString();
    return d.toStringAsFixed(1);
  }

  String getTrackingLabel(String? mileageType) {
    switch (int.tryParse(mileageType ?? '')) {
      case 1:
        return 'Hours';
      case 2:
        return 'Distance';
      case 3:
        return 'Both';
      default:
        return '-';
    }
  }

  @override
  void onInit() {
    super.onInit();
    final rawArgs = Get.arguments;
    final Map args = (rawArgs is Map) ? rawArgs : {};
    resetAndInitWithArgs(args);
  }

  Future<void> resetAndInitWithArgs(Map args) async {
    _loadPreferences();

    // 🧹 Explicitly reset all controllers & model to avoid carry-over
    outsideTreadController.clear();
    middleTreadController.clear();
    insideTreadController.clear();
    airPressureController.clear();
    commentsController.clear();
    previousCommentController.clear();
    stillRelevant.value = false;
    tyreList.clear();
    model.value = InstallTireModel();

    final int vId = args['vehicleId'] ?? 0;
    final String vNumber = args['vehicleNumber'] ?? '';
    final String wheelPos = args['wheelPosition'] ?? '';
    final int tId = args['tireId'] ?? 0;
    final String serialNo = args['serialNo'] ?? '';
    final String inspectionDate = args['inspectionDate'] ?? '';

    // 🧹 Purge any previous inspection cache (photos, hot/cold toggle) for this tyre
    if (tId > 0) {
      await InspectTyreController.purgeTireInspectionCache(tId, serialNo);
    }

    final double argOutsideTread =
        (args['outsideTread'] as num?)?.toDouble() ?? 0.0;
    final double argMiddleTread = (args['middleTread'] as num?)?.toDouble() ?? 0.0;
    final double argInsideTread = (args['insideTread'] as num?)?.toDouble() ?? 0.0;
    final double currentPressure =
        (args['currentPressure'] as num?)?.toDouble() ?? 0.0;

    final double currentTreadDepth =
        (args['currentTreadDepth'] as num?)?.toDouble() ?? argMiddleTread;

    final double currentHours =
        (args['currentHours'] as num?)?.toDouble() ?? 0.0;
    final double argCurrentMiles =
        (args['currentMiles'] as num?)?.toDouble() ?? 0.0;

    final String? distSrc = (tId > 0 ? TyreUnitHistory.getDistanceUnit(tId) : null) ??
        (serialNo.isNotEmpty ? TyreUnitHistory.getDistanceUnit(serialNo) : null);

    final double? rawTo = (tId > 0 ? TyreUnitHistory.getRawOutside(tId) : null) ??
        (serialNo.isNotEmpty ? TyreUnitHistory.getRawOutside(serialNo) : null);
    final double? rawTm = (tId > 0 ? TyreUnitHistory.getRawMiddle(tId) : null) ??
        (serialNo.isNotEmpty ? TyreUnitHistory.getRawMiddle(serialNo) : null);
    final double? rawTi = (tId > 0 ? TyreUnitHistory.getRawInside(tId) : null) ??
        (serialNo.isNotEmpty ? TyreUnitHistory.getRawInside(serialNo) : null);
    final double? rawMiles = (tId > 0 ? TyreUnitHistory.getRawMiles(tId) : null) ??
        (serialNo.isNotEmpty ? TyreUnitHistory.getRawMiles(serialNo) : null);

    final double outsideTread = (argOutsideTread > 0)
        ? argOutsideTread
        : (rawTo != null && rawTo > 0 ? rawTo : 0.0);
    final double middleTread = (argMiddleTread > 0)
        ? argMiddleTread
        : (rawTm != null && rawTm > 0 ? rawTm : 0.0);
    final double insideTread = (argInsideTread > 0)
        ? argInsideTread
        : (rawTi != null && rawTi > 0 ? rawTi : 0.0);
    final double currentMiles = (rawMiles != null && rawMiles > 0)
        ? rawMiles
        : ((argCurrentMiles > 0)
            ? (MeasurementHelper.isImperial ? argCurrentMiles : MeasurementHelper.toDisplayDistance(argCurrentMiles, sourceUnit: distSrc))
            : 0.0);

    final int mileageType = args['mileageType'] ?? 0;

    final String manufacturerName = args['manufacturerName'] ?? '';
    final String sizeName = args['sizeName'] ?? '';
    final String typeName = args['typeName'] ?? '';
    final String brandNo = args['brandNo'] ?? '';
    final String dispositionName = args['dispositionName'] ?? '';
    final int dispositionId = args['dispositionId'] ?? 0;
    final int dispositionGroupId = args['dispositionGroupId'] ?? 0;

    argManufacturerId = args['manufacturerId'] ?? 0;
    argSizeId = args['sizeId'] ?? 0;
    argTypeId = args['typeId'] ?? 0;
    argRegisteredDate = args['registeredDate']?.toString() ?? '';
    argManufacturerName = args['manufacturerName']?.toString() ?? '';
    argSizeName = args['sizeName']?.toString() ?? '';
    argTypeName = args['typeName']?.toString() ?? '';

    final double originalTread =
        (args['originalTread'] as num?)?.toDouble() ?? 0.0;
    final double removeAt = (args['removeAt'] as num?)?.toDouble() ?? 0.0;

    if (originalTread > 0) safeOriginalTread = originalTread;
    if (removeAt > 0) safeRemoveAt = removeAt;

    isOfflineTyre.value =
        args['isOfflineTyre'] ?? (tId <= 0 && serialNo.isNotEmpty);

    final double avgTreadVal = () {
      if (currentTreadDepth > 0) return currentTreadDepth;

      final List<double> available = [];
      if (outsideTread > 0) available.add(outsideTread);
      if (middleTread > 0) available.add(middleTread);
      if (insideTread > 0) available.add(insideTread);

      if (available.isEmpty) return 0.0;

      final sum = available.fold(0.0, (a, b) => a + b);
      return double.parse((sum / available.length).toStringAsFixed(2));
    }();

    vehicleNumber.value = vNumber;

    model.update((m) {
      m!.vehicleId = vId;
      m.wheelPosition = wheelPos;
      m.tireId = tId;
      m.tireSerialNo = serialNo;
      m.outsideTread = outsideTread > 0 ? outsideTread : avgTreadVal;
      m.middleTread = middleTread > 0 ? middleTread : avgTreadVal;
      m.insideTread = insideTread > 0 ? insideTread : avgTreadVal;
      m.currentPressure = currentPressure;
      m.currentTreadDepth = avgTreadVal;
      m.currentHours = currentHours;
      m.currentMiles = currentMiles;
      m.mileageType = mileageType.toString();
      m.brandNo = brandNo;
    });

    outsideTreadController.text = clean(model.value.outsideTread);
    middleTreadController.text = clean(model.value.middleTread);
    insideTreadController.text = clean(model.value.insideTread);
    airPressureController.text = clean(currentPressure);
    commentsController.text = model.value.comments;

    if (tId > 0 || serialNo.isNotEmpty) {
      tyreList.assignAll([
        TyreModel(
          tireId: tId > 0 ? tId : null,
          tireSerialNo: serialNo,
          outsideTread: model.value.outsideTread,
          middleTread: model.value.middleTread,
          insideTread: model.value.insideTread,
          currentPressure: currentPressure,
          currentTreadDepth: avgTreadVal,
          currentHours: currentHours,
          currentMiles: currentMiles,
          manufacturerName: manufacturerName,
          sizeName: sizeName,
          typeName: typeName,
          brandNo: brandNo,
          dispositionName: dispositionName,
          dispositionId: dispositionId,
          dispositionGroupId: dispositionGroupId,
          originalTread: originalTread > 0 ? originalTread : null,
          removeAt: removeAt > 0 ? removeAt : null,
        ),
      ]);
    }

    if (args['inspectionDate'] == null || inspectionDate.isEmpty) {
      lastInspectionDateStr.value = _formatDate(DateTime.now());
    } else {
      lastInspectionDateStr.value = _parseDateStr(inspectionDate);
    }

    noOfTreadDepthReadings.value = SecureStorage.getNoOfTreadDepthReadings();

    loadMasterData();

    final online = await NetworkHelper.hasInternet();
    if (online && tId > 0) {
      _loadTyreFromApi(tId);
    }

    Future.microtask(() => model.refresh());
  }

  void _loadPreferences() {
    pressureUnit.value = MeasurementHelper.pressureLabel;
    measurementUnit.value = MeasurementHelper.treadUnit;
    kmMilesLabel.value = MeasurementHelper.distanceLabel;
  }

  void onAirPressureChanged(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null) model.value.currentPressure = parsed;
  }

  void onOutsideTreadChanged(String value) {
    final val = double.tryParse(value) ?? 0.0;
    model.update((m) {
      m!.outsideTread = val;
      _avg(m);
    });
  }

  void onMiddleTreadChanged(String value) {
    final val = double.tryParse(value) ?? 0.0;
    model.update((m) {
      m!.middleTread = val;
      _avg(m);
    });
  }

  void onInsideTreadChanged(String value) {
    final val = double.tryParse(value) ?? 0.0;
    model.update((m) {
      m!.insideTread = val;
      _avg(m);
    });
  }

  void incAir() {
    model.update((m) {
      m!.currentPressure++;
      airPressureController.text = clean(m.currentPressure);
    });
  }

  void decAir() {
    model.update((m) {
      if (m!.currentPressure > 0) {
        m.currentPressure--;
        airPressureController.text = clean(m.currentPressure);
      }
    });
  }

  void incOutside() => model.update((m) {
    m!.outsideTread++;
    outsideTreadController.text = clean(m.outsideTread);
    _avg(m);
  });

  void decOutside() => model.update((m) {
    if (m!.outsideTread > 0) m.outsideTread--;
    outsideTreadController.text = clean(m.outsideTread);
    _avg(m);
  });

  void incMiddle() => model.update((m) {
    m!.middleTread++;
    middleTreadController.text = clean(m.middleTread);
    _avg(m);
  });

  void decMiddle() => model.update((m) {
    if (m!.middleTread > 0) m.middleTread--;
    middleTreadController.text = clean(m.middleTread);
    _avg(m);
  });

  void incInside() => model.update((m) {
    m!.insideTread++;
    insideTreadController.text = clean(m.insideTread);
    _avg(m);
  });

  void decInside() => model.update((m) {
    if (m!.insideTread > 0) m.insideTread--;
    insideTreadController.text = clean(m.insideTread);
    _avg(m);
  });

  void _avg(InstallTireModel m) {
    final count = noOfTreadDepthReadings.value;
    double avg;
    if (count == 1) {
      avg = m.outsideTread;
    } else if (count == 2) {
      avg = (m.outsideTread + m.insideTread) / 2;
    } else {
      final mid = m.middleTread;
      avg = mid > 0
          ? (m.outsideTread + mid + m.insideTread) / 3
          : (m.outsideTread + m.insideTread) / 2;
    }
    m.currentTreadDepth = double.parse(avg.toStringAsFixed(2));
  }

  Future<void> _loadTyreFromApi(int tireId) async {
    if (tireId <= 0) return;

    final online = await NetworkHelper.hasInternet();
    if (!online) return;

    try {
      final tyres = await tyreService.getTyresById(tireId);
      if (tyres.isEmpty) return;

      final t = tyres.first;
      tyreList
        ..clear()
        ..addAll(tyres);

      final double apiOutside = t.outsideTread ?? 0.0;
      final double apiMiddle = t.middleTread ?? 0.0;
      final double apiInside = t.insideTread ?? 0.0;
      final double apiPressure = t.currentPressure ?? 0.0;
      final double apiHours = t.currentHours ?? 0.0;
      final double apiMiles = t.currentMiles ?? 0.0;

      final String? distSrc = TyreUnitHistory.getDistanceUnit(tireId) ??
          (t.tireSerialNo != null ? TyreUnitHistory.getDistanceUnit(t.tireSerialNo) : null);

      final double? savedTo = TyreUnitHistory.getRawOutside(tireId) ??
          (t.tireSerialNo != null ? TyreUnitHistory.getRawOutside(t.tireSerialNo) : null);
      final double? savedTm = TyreUnitHistory.getRawMiddle(tireId) ??
          (t.tireSerialNo != null ? TyreUnitHistory.getRawMiddle(t.tireSerialNo) : null);
      final double? savedTi = TyreUnitHistory.getRawInside(tireId) ??
          (t.tireSerialNo != null ? TyreUnitHistory.getRawInside(t.tireSerialNo) : null);
      final double? savedMiles = TyreUnitHistory.getRawMiles(tireId) ??
          (t.tireSerialNo != null ? TyreUnitHistory.getRawMiles(t.tireSerialNo) : null);

      final double resolvedOutside = (apiOutside > 0)
          ? apiOutside
          : (savedTo != null && savedTo > 0 ? savedTo : 0.0);
      final double resolvedMiddle = (apiMiddle > 0)
          ? apiMiddle
          : (savedTm != null && savedTm > 0 ? savedTm : 0.0);
      final double resolvedInside = (apiInside > 0)
          ? apiInside
          : (savedTi != null && savedTi > 0 ? savedTi : 0.0);
      final double resolvedMiles = (savedMiles != null && savedMiles > 0)
          ? savedMiles
          : ((apiMiles > 0)
              ? (MeasurementHelper.isImperial ? apiMiles : MeasurementHelper.toDisplayDistance(apiMiles, sourceUnit: distSrc))
              : 0.0);

      model.update((m) {
        if (resolvedOutside > 0) m!.outsideTread = resolvedOutside;
        if (resolvedMiddle > 0) m!.middleTread = resolvedMiddle;
        if (resolvedInside > 0) m!.insideTread = resolvedInside;
        if (apiPressure > 0) m!.currentPressure = apiPressure;
        if (apiHours > 0) m!.currentHours = apiHours;
        if (resolvedMiles > 0) m!.currentMiles = resolvedMiles;
        final mid = m!.middleTread;
        final avg = mid > 0
            ? (m.outsideTread + mid + m.insideTread) / 3
            : (m.outsideTread + m.insideTread) / 2;
        m.currentTreadDepth = double.parse(avg.toStringAsFixed(2));
      });

      outsideTreadController.text = clean(model.value.outsideTread);
      middleTreadController.text = clean(model.value.middleTread);
      insideTreadController.text = clean(model.value.insideTread);

      if (apiPressure > 0) {
        airPressureController.text = clean(model.value.currentPressure);
      }
    } catch (_) {}
  }

  Future<void> loadMasterData() async {
    try {
      final data = await _masterService.fetchMasterData();

      wearConditionsList.assignAll(
        (data['wearConditions'] as List)
            .map((e) => e['wearConditionName'].toString().toUpperCase())
            .toSet()
            .toList(),
      );
      wearConditionsIdList.assignAll(
        (data['wearConditions'] as List)
            .map((e) => e['wearConditionId'] as int)
            .toSet()
            .toList(),
      );

      casingConditionList.assignAll(
        (data['casingCondition'] as List)
            .map((e) => e['casingConditionName'].toString().toUpperCase())
            .toSet()
            .toList(),
      );
      casingConditionIdList.assignAll(
        (data['casingCondition'] as List)
            .map((e) => e['casingConditionId'] as int)
            .toSet()
            .toList(),
      );

      selectedWearConditionsId.value = 0;
      selectedCasingConditionId.value = 0;
      wearConditionsId.clear();
      casingConditionsId.clear();

      dispositionList.assignAll(
        (data['tireDispositions'] as List)
            .map((e) => e['dispositionName'].toString().toUpperCase())
            .toList(),
      );
      dispositionIdList.assignAll(
        (data['tireDispositions'] as List)
            .map((e) => e['dispositionId'] as int)
            .toList(),
      );

      for (var d in data['tireDispositions']) {
        final name = d['dispositionName'].toString().toLowerCase();
        if (name == 'installed' || name == 'mounted') {
          installedDispositionId.value = d['dispositionId'];
          break;
        }
      }
      if (installedDispositionId.value == 0) installedDispositionId.value = 7;
    } catch (e) {
      installedDispositionId.value = 7;
    }
  }

  Future<void> submit() async {
    if (isSubmitting.value) return;
    if (isInitialLoading.value) {
      Get.snackbar(
        'Please Wait',
        'Tyre data still loading, please wait a moment and try again...',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // 🔒 Vehicle ka pichla inspection approval ke liye pending hai to block.
    if (!await PendingInspectionGuard.canProceed(
      vehicleId: model.value.vehicleId,
      vehicleNumber: vehicleNumber.value,
      action: PendingBlockedAction.installTyre,
    )) {
      return;
    }

    isSubmitting.value = true;

    try {
      final m = model.value;

      final int resolvedTireId = m.tireId ?? 0;
      final String resolvedSerial = (m.tireSerialNo ?? '').trim();

      if (resolvedTireId <= 0 && resolvedSerial.isEmpty) {
        Get.snackbar(
          'Error',
          'Tyre data missing. Please go back and select a tyre.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        isSubmitting.value = false;
        return;
      }

      if ((m.wheelPosition ?? '').trim().isEmpty) {
        Get.snackbar(
          'Error',
          'Wheel position missing',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isSubmitting.value = false;
        return;
      }

      final tyreData = tyreList.isNotEmpty ? tyreList.first : null;

      final double actualOutside =
          double.tryParse(outsideTreadController.text) ?? m.outsideTread;
      final double actualInside = noOfTreadDepthReadings.value >= 2
          ? (double.tryParse(insideTreadController.text) ?? m.insideTread)
          : actualOutside;
      final double actualMiddle = noOfTreadDepthReadings.value == 3
          ? (double.tryParse(middleTreadController.text) ?? m.middleTread)
          : double.parse(
              ((actualOutside + actualInside) / 2).toStringAsFixed(2),
            );

      // ✅ FIX: 0 is a valid, real tread-depth reading (fully worn tyre) and
      // must NOT be treated as "missing" and replaced with 1.0 / an average.
      // Previously `actualOutside > 0 ? actualOutside : 1.0` silently turned
      // a genuine 0 entered by the user into 1, which is why Vehicle
      // Inspection later showed 1,1,1 instead of the 0,0,0 that was typed.
      final double finalOutside = actualOutside >= 0 ? actualOutside : 0.0;
      final double finalInside = actualInside >= 0 ? actualInside : finalOutside;
      final double finalMiddle = actualMiddle >= 0
          ? actualMiddle
          : double.parse(((finalOutside + finalInside) / 2).toStringAsFixed(2));

      final String tireSerialNo = resolvedSerial.isNotEmpty
          ? resolvedSerial
          : (tyreData?.tireSerialNo ?? '');

      final String wheelPosition = m.wheelPosition!.trim().toUpperCase();

      final locationIdStr = await SecureStorage.getLocationId();
      final parentAccountIdStr = await SecureStorage.getParentAccountId();
      final int locationId = int.tryParse(locationIdStr ?? '0') ?? 0;
      final int parentAccountId = int.tryParse(parentAccountIdStr ?? '0') ?? 0;

      final double tireHours = m.currentHours ?? 0.0;
      final double tireMiles = m.currentMiles ?? 0.0;

      final now = DateTime.now();

      final double origTread = (tyreData?.originalTread ?? 0) > 0
          ? tyreData!.originalTread!
          : (safeOriginalTread > 0 ? safeOriginalTread : 0.0);
      final double removeAt = (tyreData?.removeAt ?? 0) > 0
          ? tyreData!.removeAt!
          : (safeRemoveAt > 0 ? safeRemoveAt : 0.0);
      final double currTread = (finalOutside > 0 && finalMiddle > 0 && finalInside > 0)
          ? ((finalOutside + finalMiddle + finalInside) / 3)
          : (finalMiddle > 0 ? finalMiddle : finalOutside);

      final treadSrc = TyreUnitHistory.getTreadUnit(resolvedTireId);
      final double dispOrigTread = MeasurementHelper.toDisplayTread(origTread, sourceUnit: treadSrc);
      final double dispRemoveAt = MeasurementHelper.toDisplayTread(removeAt, sourceUnit: treadSrc);
      final double effectiveOrig = dispOrigTread > 0 ? dispOrigTread : currTread;
      final double denominator = (effectiveOrig - dispRemoveAt) > 0
          ? (effectiveOrig - dispRemoveAt)
          : (effectiveOrig > 0 ? effectiveOrig : 1.0);
      final double effectiveRemoveAt = (effectiveOrig - dispRemoveAt) > 0 ? dispRemoveAt : 0.0;

      final double calcPercentWorn = (effectiveOrig > 0 && currTread > 0)
          ? (currTread >= effectiveOrig
              ? 0.0
              : ((1 - (currTread - effectiveRemoveAt) / denominator) * 100).clamp(0.0, 100.0))
          : 0.0;

      final payload = <String, dynamic>{
        'action': 'Install',
        'inspectionDate': now.toIso8601String(),
        'wheelPosition': wheelPosition,
        'tireId': resolvedTireId,
        'currentHours': tireHours,
        'currentTreadDepth': finalMiddle,
        'currentMiles': tireMiles,
        'tireSerialNo': tireSerialNo,
        'vehicleId': m.vehicleId ?? 0,
        'locationId': locationId,
        'parentAccountId': parentAccountId,
        'currentPressure': _sanitizePressure(m.currentPressure),
        'rimDispositionId': 0,
        'pressureType': 'C',
        'casingConditionId': selectedCasingConditionId.value,
        'wearConditionId': selectedWearConditionsId.value,
        'brandNo': tyreData?.brandNo ?? '',
        'comments': stillRelevant.value
            ? previousCommentController.text.trim()
            : commentsController.text.trim(),
        'outsideTread': finalOutside,
        'insideTread': finalInside,
        'middleTread': finalMiddle,
        'dispositionId': installedDispositionId.value != 0 ? installedDispositionId.value : 7,
        'percentageWorn': calcPercentWorn,
        'isOfflineTyre': isOfflineTyre.value,
      };

      if (isInspectionFlow) {
        // 💾 Pre-inspection backup: agar inspection reject hoti hai to tyre
        // original readings (jaise 100, 100, 100) aur inventory state par wapas aayega
        final hiveBackupTyre = resolvedTireId > 0 ? OfflineHiveService.getTyreById(resolvedTireId) : null;
        final double? savedRawOut = (resolvedTireId > 0 ? TyreUnitHistory.getRawOutside(resolvedTireId) : null) ??
            (tireSerialNo.isNotEmpty ? TyreUnitHistory.getRawOutside(tireSerialNo) : null);
        final double? savedRawMid = (resolvedTireId > 0 ? TyreUnitHistory.getRawMiddle(resolvedTireId) : null) ??
            (tireSerialNo.isNotEmpty ? TyreUnitHistory.getRawMiddle(tireSerialNo) : null);
        final double? savedRawIn = (resolvedTireId > 0 ? TyreUnitHistory.getRawInside(resolvedTireId) : null) ??
            (tireSerialNo.isNotEmpty ? TyreUnitHistory.getRawInside(tireSerialNo) : null);

        final hOut = hiveBackupTyre?.outsideTread;
        final hMid = hiveBackupTyre?.middleTread;
        final hDepth = hiveBackupTyre?.currentTreadDepth;
        final hIn = hiveBackupTyre?.insideTread;
        final hPress = hiveBackupTyre?.currentPressure;
        final hMiles = hiveBackupTyre?.currentMiles;
        final hDisp = hiveBackupTyre?.dispositionId;

        final tOut = tyreData?.outsideTread;
        final tMid = tyreData?.middleTread;
        final tDepth = tyreData?.currentTreadDepth;
        final tIn = tyreData?.insideTread;
        final tPress = tyreData?.currentPressure;
        final tMiles = tyreData?.currentMiles;
        final tDisp = tyreData?.dispositionId;

        final origOutside = (hOut != null && hOut > 0)
            ? hOut
            : ((savedRawOut != null && savedRawOut > 0)
                ? savedRawOut
                : ((tOut != null && tOut > 0) ? tOut : finalOutside));

        final origMiddle = (hMid != null && hMid > 0)
            ? hMid
            : ((savedRawMid != null && savedRawMid > 0)
                ? savedRawMid
                : ((tMid != null && tMid > 0)
                    ? tMid
                    : ((hDepth != null && hDepth > 0)
                        ? hDepth
                        : ((tDepth != null && tDepth > 0) ? tDepth : finalMiddle))));

        final origInside = (hIn != null && hIn > 0)
            ? hIn
            : ((savedRawIn != null && savedRawIn > 0)
                ? savedRawIn
                : ((tIn != null && tIn > 0) ? tIn : finalInside));

        final origPress = (hPress != null && hPress > 0)
            ? hPress
            : ((tPress != null && tPress > 0)
                ? tPress
                : _sanitizePressure(m.currentPressure));

        final origM = (hMiles != null && hMiles > 0)
            ? hMiles
            : ((tMiles != null && tMiles > 0) ? tMiles : tireMiles);

        final origWorn = hiveBackupTyre?.percentageWorn ?? tyreData?.percentageWorn;
        final origDisp = (hDisp != null && hDisp > 0)
            ? hDisp
            : (tDisp ?? 8);

        final backupTreadUnit = TyreUnitHistory.getTreadUnit(resolvedTireId) ??
            (tireSerialNo.isNotEmpty ? TyreUnitHistory.getTreadUnit(tireSerialNo) : null) ??
            (MeasurementHelper.isMetric ? 'Metric' : 'Imperial');

        TyreUnitHistory.backupPreInspectionReadings(
          tireId: resolvedTireId,
          outside: origOutside,
          middle: origMiddle,
          inside: origInside,
          pressure: origPress,
          miles: origM,
          percentageWorn: origWorn,
          treadUnit: backupTreadUnit,
          pressureUnit: MeasurementHelper.pressureLabel,
          distanceUnit: MeasurementHelper.distanceLabel,
          dispositionId: origDisp,
          force: true,
        );
        if (tireSerialNo.isNotEmpty) {
          TyreUnitHistory.backupPreInspectionReadings(
            tireId: tireSerialNo,
            outside: origOutside,
            middle: origMiddle,
            inside: origInside,
            pressure: origPress,
            miles: origM,
            percentageWorn: origWorn,
            treadUnit: backupTreadUnit,
            pressureUnit: MeasurementHelper.pressureLabel,
            distanceUnit: MeasurementHelper.distanceLabel,
            dispositionId: origDisp,
            force: true,
          );
        }
      }

      TyreUnitHistory.recordDistanceUnit(
        resolvedTireId,
        MeasurementHelper.isMetric ? 'Metric' : 'Imperial',
      );
      TyreUnitHistory.recordTreadUnit(
        resolvedTireId,
        MeasurementHelper.isMetric ? 'Metric' : 'Imperial',
      );
      TyreUnitHistory.recordPressureUnit(
        resolvedTireId,
        MeasurementHelper.pressureLabel,
      );
      final double pressVal = double.tryParse(airPressureController.text) ?? 0.0;
      TyreUnitHistory.recordRawReadings(
        tireId: resolvedTireId,
        outside: finalOutside,
        middle: finalMiddle,
        inside: finalInside,
        pressure: pressVal,
        miles: tireMiles,
        percentageWorn: calcPercentWorn,
        treadUnit: MeasurementHelper.isMetric ? 'Metric' : 'Imperial',
        pressureUnit: MeasurementHelper.pressureLabel,
        distanceUnit: MeasurementHelper.distanceLabel,
      );
      if (tireSerialNo.isNotEmpty) {
        TyreUnitHistory.recordRawReadings(
          tireId: tireSerialNo,
          outside: finalOutside,
          middle: finalMiddle,
          inside: finalInside,
          pressure: pressVal,
          miles: tireMiles,
          percentageWorn: calcPercentWorn,
          treadUnit: MeasurementHelper.isMetric ? 'Metric' : 'Imperial',
          pressureUnit: MeasurementHelper.pressureLabel,
          distanceUnit: MeasurementHelper.distanceLabel,
        );
      }

      if (isInspectionFlow) {
        _updateDiagram(
          m: m,
          tyreData: tyreData,
          tireSerialNo: tireSerialNo,
          outside: finalOutside,
          inside: finalInside,
          middle: finalMiddle,
          wheelPos: wheelPosition,
          tireHours: tireHours,
          tireMiles: tireMiles,
          installPayload: payload,
        );

        if (resolvedTireId > 0) {
          OfflineHiveService.updateTyreDisposition(
            tireId: resolvedTireId,
            dispositionId: installedDispositionId.value != 0 ? installedDispositionId.value : 7,
            dispositionName: 'Installed',
            wheelPosition: wheelPosition,
            vehicleId: m.vehicleId,
            outsideTread: finalOutside,
            middleTread: finalMiddle,
            insideTread: finalInside,
            currentTreadDepth: finalMiddle,
            currentPressure: pressVal,
            comments: commentsController.text,
          );
        }

        Get.back();
        Get.back();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppSnackbar.success(
            'Tire with Serial No: $tireSerialNo added to inspection.',
            title: 'Tire Added to Inspection',
          );
        });
        return;
      }

      final userRole = await SecureStorage.getUserProfileRole();
      final bool isEmtUser = (userRole ?? '').trim().toUpperCase() == 'EMTUSER';
      final bool isWorkflowEnabled = await SecureStorage.getApprovalWorkflowEnabled();
      bool isApprover = false;
      if (isEmtUser) {
        isApprover = await SecureStorage.getIsApprover();
      }
      final bool shouldUseTempApi = isEmtUser && (!isWorkflowEnabled || !isApprover);

      if (shouldUseTempApi) {
        _updateDiagram(
          m: m,
          tyreData: tyreData,
          tireSerialNo: tireSerialNo,
          outside: finalOutside,
          inside: finalInside,
          middle: finalMiddle,
          wheelPos: wheelPosition,
          tireHours: tireHours,
          tireMiles: tireMiles,
          installPayload: payload,
        );

        if (resolvedTireId != 0) {
          OfflineHiveService.updateTyreDisposition(
            tireId: resolvedTireId,
            dispositionId: installedDispositionId.value != 0 ? installedDispositionId.value : 7,
            dispositionName: 'Installed',
            wheelPosition: wheelPosition,
            vehicleId: m.vehicleId,
            outsideTread: finalOutside,
            middleTread: finalMiddle,
            insideTread: finalInside,
            currentTreadDepth: finalMiddle,
            currentPressure: double.tryParse(airPressureController.text) ?? 0.0,
            comments: stillRelevant.value ? previousCommentController.text.trim() : commentsController.text.trim(),
          );
        }

        await _updateTireCountLocally(m.vehicleId ?? 0);
        PendingInspectionGuard.markPending(m.vehicleId, tireIds: [m.tireId ?? 0]);

        Get.back();
        Get.back();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppSnackbar.success(
            'Tire with Serial No: $tireSerialNo installed on Vehicle ${vehicleNumber.value}. Submit vehicle inspection to send for approval.',
            title: 'Tire Installed Locally',
          );
        });
        return;
      }

      try {
        await _installService.submitInspection(payload);

        lastInspectionDateStr.value = _formatDate(now);

        _updateDiagram(
          m: m,
          tyreData: tyreData,
          tireSerialNo: tireSerialNo,
          outside: finalOutside,
          inside: finalInside,
          middle: finalMiddle,
          wheelPos: wheelPosition,
          tireHours: tireHours,
          tireMiles: tireMiles,
        );

        await _updateTireCountLocally(m.vehicleId ?? 0);
        PendingInspectionGuard.markPending(m.vehicleId, tireIds: [m.tireId ?? 0]);

        Get.back();
        Get.back();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppSnackbar.success(
            'Tire with Serial No: $tireSerialNo Installed successfully on Vehicle $vehicleNumber',
            title: 'Tire Installed Successfully',
          );
        });
      } catch (e) {
        final isOfflineError = e.toString().contains('Saved offline');

        if (isOfflineError) {
          lastInspectionDateStr.value = _formatDate(now);

          _updateDiagram(
            m: m,
            tyreData: tyreData,
            tireSerialNo: tireSerialNo,
            outside: finalOutside,
            inside: finalInside,
            middle: finalMiddle,
            wheelPos: wheelPosition,
            tireHours: tireHours,
            tireMiles: tireMiles,
          );

          await _updateTireCountLocally(m.vehicleId ?? 0);
        PendingInspectionGuard.markPending(m.vehicleId, tireIds: [m.tireId ?? 0]);

          Get.back();
          Get.back();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppSnackbar.offlineSuccess(
              'Tire with Serial No: $tireSerialNo Installed successfully on Vehicle $vehicleNumber',
              title: 'Tire Installed Successfully',
            );
          });
        } else {
          rethrow;
        }
      }
    } catch (e) {
      Get.snackbar(
        'Install Failed',
        'This tire could not be installed. It may already be in use on another vehicle, or a server error occurred.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  void _updateDiagram({
    required InstallTireModel m,
    required TyreModel? tyreData,
    required String tireSerialNo,
    required double outside,
    required double inside,
    required double middle,
    required String wheelPos,
    required double tireHours,
    required double tireMiles,
    Map<String, dynamic>? installPayload,
  }) {
    try {
      final vehicleCtrl = Get.find<VehicleInspeController>();

      final double origTread = (tyreData?.originalTread ?? 0) > 0
          ? tyreData!.originalTread!
          : (safeOriginalTread > 0 ? safeOriginalTread : 0.0);
      final double removeAt = (tyreData?.removeAt ?? 0) > 0
          ? tyreData!.removeAt!
          : (safeRemoveAt > 0 ? safeRemoveAt : 0.0);
      final double currTread = (outside > 0 && middle > 0 && inside > 0)
          ? ((outside + middle + inside) / 3)
          : (middle > 0 ? middle : outside);
      final treadSrc = TyreUnitHistory.getTreadUnit(m.tireId);
      final double dispOrigTread = MeasurementHelper.toDisplayTread(origTread, sourceUnit: treadSrc);
      final double dispRemoveAt = MeasurementHelper.toDisplayTread(removeAt, sourceUnit: treadSrc);
      final double effectiveOrig = dispOrigTread > 0 ? dispOrigTread : currTread;
      final double denominator = (effectiveOrig - dispRemoveAt) > 0
          ? (effectiveOrig - dispRemoveAt)
          : (effectiveOrig > 0 ? effectiveOrig : 1.0);
      final double effectiveRemoveAt = (effectiveOrig - dispRemoveAt) > 0 ? dispRemoveAt : 0.0;
      final double calcPercentWorn = (currTread > 0 && effectiveOrig > 0)
          ? (currTread >= effectiveOrig
              ? 0.0
              : ((1 - (currTread - effectiveRemoveAt) / denominator) * 100).clamp(0.0, 100.0))
          : 0.0;

      final int resolvedSizeId = tyreData?.sizeId ?? (argSizeId > 0 ? argSizeId : 0);
      final int resolvedTypeId = tyreData?.typeId ?? (argTypeId > 0 ? argTypeId : 0);
      final int resolvedMfgId = tyreData?.manufacturerId ?? (argManufacturerId > 0 ? argManufacturerId : 0);

      final String resolvedSizeName = _resolveSizeName(
        resolvedSizeId,
        (tyreData?.sizeName?.isNotEmpty == true)
            ? tyreData!.sizeName
            : argSizeName,
      );
      final String resolvedTypeName = _resolveTypeName(
        resolvedTypeId,
        (tyreData?.typeName?.isNotEmpty == true)
            ? tyreData!.typeName
            : argTypeName,
      );
      final String resolvedMfgName = _resolveManufacturerName(
        resolvedMfgId,
        (tyreData?.manufacturerName?.isNotEmpty == true)
            ? tyreData!.manufacturerName
            : argManufacturerName,
      );

      final localTyre = TyreModel(
        tireId: m.tireId,
        tireSerialNo: tireSerialNo,
        wheelPosition: wheelPos,
        currentTreadDepth: middle,
        outsideTread: outside,
        middleTread: middle,
        insideTread: inside,
        currentPressure: _sanitizePressure(m.currentPressure),
        currentHours: tireHours,
        currentMiles: tireMiles,
        percentageWorn: calcPercentWorn,
        originalTread: origTread,
        sizeId: resolvedSizeId > 0 ? resolvedSizeId : null,
        sizeName: resolvedSizeName,
        typeId: resolvedTypeId > 0 ? resolvedTypeId : null,
        typeName: resolvedTypeName,
        manufacturerId: resolvedMfgId > 0 ? resolvedMfgId : null,
        manufacturerName: resolvedMfgName,
        registeredDate: tyreData?.registeredDate ?? (argRegisteredDate.isNotEmpty ? argRegisteredDate : null),
        brandNo: tyreData?.brandNo ?? '',
        dispositionId: installedDispositionId.value != 0 ? installedDispositionId.value : 7,
        casingConditionId: selectedCasingConditionId.value,
        wearConditionId: selectedWearConditionsId.value,
        comments: stillRelevant.value
            ? previousCommentController.text.trim()
            : commentsController.text.trim(),
      );
      vehicleCtrl.addInstalledTyreLocally(localTyre, installPayload: installPayload);

      final String resolvedComment = stillRelevant.value
          ? previousCommentController.text.trim()
          : commentsController.text.trim();

      final resolvedTireIdVal = m.tireId ?? 0;
      if (resolvedTireIdVal > 0) {
        OfflineHiveService.saveTireDetailCache(
          resolvedTireIdVal,
          jsonEncode({
            'model': {
              'tireId': resolvedTireIdVal,
              'outsideTread': outside,
              'middleTread': middle,
              'insideTread': inside,
              'currentPressure': _sanitizePressure(m.currentPressure),
              'wearConditionId': selectedWearConditionsId.value,
              'casingConditionId': selectedCasingConditionId.value,
              'comments': resolvedComment,
              'wheelPosition': wheelPos,
            },
          }),
        );
      }

      final vId = m.vehicleId ?? 0;
      if (vId != 0 && !isInspectionFlow) {
        final cachePayload = <String, dynamic>{
          'tireId': m.tireId ?? 0,
          'tireSerialNo': tireSerialNo,
          'wheelPosition': wheelPos,
          'outsideTread': outside,
          'middleTread': middle,
          'insideTread': inside,
          'currentTreadDepth': middle,
          'currentPressure': _sanitizePressure(m.currentPressure),
          'currentHours': tireHours,
          'currentMiles': tireMiles,
          'dispositionId': installedDispositionId.value,
          'percentageWorn': calcPercentWorn,
          'brandNo': tyreData?.brandNo ?? '',
          'casingConditionId': selectedCasingConditionId.value,
          'wearConditionId': selectedWearConditionsId.value,
          'comments': resolvedComment,
          'inspectionDate': DateTime.now().toIso8601String(),
          'manufacturerName': tyreData?.manufacturerName ?? '',
          'sizeName': tyreData?.sizeName ?? '',
          'typeName': tyreData?.typeName ?? '',
          'originalTread': tyreData?.originalTread ?? safeOriginalTread,
          'removeAt': safeRemoveAt,
          'isOfflineTyre': isOfflineTyre.value,
        };
        OfflineHiveService.addTireToInspectionCache(
          vId.toString(),
          cachePayload,
        ).catchError((_) {});
      }

      final installTireId = m.tireId ?? 0;
      if (installTireId != 0 && !isInspectionFlow) {
        OfflineHiveService.updateTyreDisposition(
          tireId: installTireId,
          dispositionId: installedDispositionId.value,
          dispositionName: 'Installed',
          wheelPosition: wheelPos,
          vehicleId: m.vehicleId ?? 0,
          outsideTread: outside,
          middleTread: middle,
          insideTread: inside,
          currentTreadDepth: middle,
          currentPressure: _sanitizePressure(m.currentPressure),
          currentHours: tireHours,
          currentMiles: tireMiles,
          wearConditionId: selectedWearConditionsId.value > 0
              ? selectedWearConditionsId.value
              : null,
          casingConditionId: selectedCasingConditionId.value > 0
              ? selectedCasingConditionId.value
              : null,
          comments: commentsController.text.trim().isNotEmpty
              ? commentsController.text.trim()
              : null,
        ).catchError((_) {});
      }
    } catch (_) {}
  }

  Future<void> _updateTireCountLocally(int vehicleId) async {
    if (vehicleId == 0) return;
    try {
      await OfflineHiveService.updateVehicleTireCount(vehicleId, 1);

      if (Get.isRegistered<AllVehicleController>()) {
        final allVehicleCtrl = Get.find<AllVehicleController>();
        final idx = allVehicleCtrl.vehicleList.indexWhere(
          (v) => v.vehicleId == vehicleId,
        );
        if (idx != -1) {
          final old = allVehicleCtrl.vehicleList[idx];
          allVehicleCtrl.vehicleList[idx] = AccountVehicleModel(
            vehicleId: old.vehicleId,
            vehicleNumber: old.vehicleNumber,
            typeName: old.typeName,
            modelName: old.modelName,
            axleConfig: old.axleConfig,
            manufacturerName: old.manufacturerName,
            currentHours: old.currentHours,
            currentMiles: old.currentMiles,
            lastRead: old.lastRead,
            assetNumber: old.assetNumber,
            tireCount: (old.tireCount ?? 0) + 1,
            locationId: old.locationId,
            isPendingSync: old.isPendingSync,
          );
          final updatedVehicle = allVehicleCtrl.vehicleList[idx];
          allVehicleCtrl.vehicleList.refresh();
          final fidx = allVehicleCtrl.filteredList.indexWhere(
            (v) => v.vehicleId == vehicleId,
          );
          if (fidx != -1) {
            allVehicleCtrl.filteredList[fidx] = updatedVehicle;
            allVehicleCtrl.filteredList.refresh();
          }
        }
      }
    } catch (_) {}
  }

  String _resolveSizeName(int sizeId, String? currentName) {
    if (currentName != null && currentName.trim().isNotEmpty) return currentName.trim();
    if (sizeId <= 0) return '';
    try {
      final sizes = OfflineHiveService.getTireSizes();
      for (final s in sizes) {
        final id = s['tireSizeId'] ?? s['sizeId'];
        if (id == sizeId) {
          final name = s['tireSizeName'] ?? s['sizeName'];
          if (name != null && name.toString().trim().isNotEmpty) {
            return name.toString().trim();
          }
        }
      }
    } catch (_) {}
    return '';
  }

  String _resolveTypeName(int typeId, String? currentName) {
    if (currentName != null && currentName.trim().isNotEmpty) return currentName.trim();
    if (typeId <= 0) return '';
    try {
      final types = OfflineHiveService.getTireTypes();
      for (final t in types) {
        final id = t['typeId'] ?? t['tireTypeId'];
        if (id == typeId) {
          final name = t['typeName'] ?? t['tireTypeName'];
          if (name != null && name.toString().trim().isNotEmpty) {
            return name.toString().trim();
          }
        }
      }
    } catch (_) {}
    return '';
  }

  String _resolveManufacturerName(int mfgId, String? currentName) {
    if (currentName != null && currentName.trim().isNotEmpty) return currentName.trim();
    if (mfgId <= 0) return '';
    try {
      final mfgs = OfflineHiveService.getTireManufacturers();
      for (final m in mfgs) {
        final id = m['manufacturerId'] ?? m['id'];
        if (id == mfgId) {
          final name = m['manufacturerName'] ?? m['name'];
          if (name != null && name.toString().trim().isNotEmpty) {
            return name.toString().trim();
          }
        }
      }
    } catch (_) {}
    return '';
  }

  @override
  void onClose() {
    commentsController.dispose();
    previousCommentController.dispose();
    wearConditionsId.dispose();
    casingConditionsId.dispose();
    airPressureController.dispose();
    outsideTreadController.dispose();
    middleTreadController.dispose();
    insideTreadController.dispose();
    super.onClose();
  }
}
