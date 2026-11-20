import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emtrack/l10n/app_localizations.dart';
import 'package:emtrack/routes/app_pages.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:emtrack/utils/hive_prefe.dart';
import 'package:emtrack/utils/mesurment_helper_class.dart';
import 'package:emtrack/controllers/all_vehicles_controller.dart';
import 'package:emtrack/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../inspection/vehicle_inspe_service.dart';
import '../utils/app_snackbar.dart';
import '../models/masterDataMobileModel/tire_size_model.dart';
import '../models/masterDataMobileModel/manufacturer_model.dart';
import '../models/masterDataMobileModel/vehicle_model_item_model.dart';
import '../models/masterDataMobileModel/vehicle_type_model.dart';
import '../models/vehicle_model.dart';
import '../services/master_data_service.dart';
import '../services/create_vehicle_service.dart';

class VehicleController extends GetxController {
  final VehicleService _vehicleService = VehicleService();
  final MasterDataService _masterService = MasterDataService();


  final manufacturerCtrl = TextEditingController();
  final typeCtrl = TextEditingController();
  final modelCtrl = TextEditingController();
  final tyreSizeCtrl = TextEditingController();
  TextEditingController currentHoursCtrl = TextEditingController(text: "0");
  TextEditingController currentKmCtrl = TextEditingController(text: "0");

  RxBool isLoadingMasterData = true.obs;
  RxBool isSubmitting = false.obs;

  final RxString _selectedAxleConfigNameRx = "".obs;
  String get axleConfigValue => _selectedAxleConfigNameRx.value.isNotEmpty
      ? _selectedAxleConfigNameRx.value
      : "22";

  // Dynamic preferences
  final RxString pressureUnit = 'PSI'.obs;
  final RxString measurementUnit = '/32nds'.obs;
  final RxString kmMilesLabel = 'KM'.obs;

  final List<TextEditingController> _pressureControllers = [];

  TextEditingController getPressureController(int index) {
    while (_pressureControllers.length <= index) {
      _pressureControllers.add(TextEditingController(text: '0'));
    }
    return _pressureControllers[index];
  }

  /* ---------------- BASIC ---------------- */
  RxString vehicleNumber = ''.obs;
  RxString trackingMethodText = 'Hours'.obs;
  RxString removalTread = ''.obs;
  RxString currentHours = '0'.obs;
  RxString currentKm = '0'.obs;
  RxString comments = ''.obs;

  RxString selectedManufecturer = "".obs;
  RxString selectedType = "".obs;
  RxString selectedModel = "".obs;
  RxString selectedTyreSize = "".obs;

  RxList<double> axlePressures = <double>[0.0, 0.0].obs;


  RxInt manufacturerId = 0.obs;
  RxInt typeId = 0.obs;
  RxInt modelId = 0.obs;
  RxInt tireSizeId = 0.obs;
  RxInt locationId = 11711.obs;

  /* ---------------- DISPLAY ---------------- */
  RxString manufacturer = ''.obs;
  RxString type = ''.obs;
  RxString model = ''.obs;
  RxString tyreSize = ''.obs;

  /* ---------------- ERROR MESSAGES ---------------- */
  RxString vehicleNumberError = ''.obs;
  RxString trackingMethodError = ''.obs;
  RxString manufacturerError = ''.obs;
  RxString typeError = ''.obs;
  RxString modelError = ''.obs;
  RxString tyreSizeError = ''.obs;
  RxString removalTreadError = ''.obs;
  RxString currentHoursError = ''.obs;
  RxString currentKmError = ''.obs;
  RxString commentsError = ''.obs;

  /* ---------------- MASTER DATA ---------------- */
  List<Manufacturer> manufacturers = [];
  List<VehicleType> types = [];
  List<VehicleModelItem> models = [];
  List<TireSize> tireSizes = [];
  List<Map<String, dynamic>> axleConfigs = [];

  int _selectedConfigurationId = 0;
  String _selectedAxleConfigName = "";

  /* ---------------- DROPDOWN LISTS ---------------- */
  RxList<String> manufacturerList = <String>[].obs;
  RxList<String> typeList = <String>[].obs;
  RxList<String> modelList = <String>[].obs;
  RxList<String> tyreSizeList = <String>[].obs;

  /* ---------------- VISIBILITY ---------------- */
  bool get showPressureSection => tireSizeId.value != 0;

  @override
  void onInit() {
    super.onInit();
    _loadPreferences();
    loadMasterData();
    ever(manufacturer, (v) => manufacturerCtrl.text = v);
    ever(type, (v) => typeCtrl.text = v);
    ever(model, (v) => modelCtrl.text = v);
    ever(tyreSize, (v) => tyreSizeCtrl.text = v);
  }

  void _loadPreferences() {
    final savedPressure = HivePref.get<String>('pref_pressure');
    final savedMeasurement = HivePref.get<String>('pref_measurement');
    if (savedPressure != null && savedPressure.isNotEmpty) {
      pressureUnit.value = savedPressure.toUpperCase();
    }
    if (savedMeasurement != null && savedMeasurement.isNotEmpty) {
      kmMilesLabel.value = savedMeasurement.toLowerCase() == 'metric'
          ? 'KM'
          : 'Miles';
    }
  }

  /* ---------------- LOAD DATA ---------------- */
  Future<void> loadMasterData() async {
    try {
      isLoadingMasterData.value = true;

      final data = await _masterService.fetchMasterData();

      manufacturers = (data['vehicleManufacturers'] as List).map((e) {
        final m = Manufacturer.fromJson(e);
        return Manufacturer(
          manufacturerId: m.manufacturerId,
          manufacturerName: m.manufacturerName.toUpperCase(),
          activeFlag: false,
        );
      }).toList();

      types = (data['vehicleTypes'] as List)
          .map((e) => VehicleType.fromJson(e))
          .toList();

      if (types.isNotEmpty) {}

      models = (data['vehicleModels'] as List)
          .map((e) => VehicleModelItem.fromJson(e))
          .toList();

      if (models.isNotEmpty) {}

      final bellModels = models
          .where((m) => m.vehicleManufacturerId == 5)
          .toList();
      if (bellModels.isNotEmpty) {}

      tireSizes = (data['tireSizes'] as List)
          .map((e) => TireSize.fromJson(e))
          .where((t) => t.tireSizeName.trim().isNotEmpty)
          .toList();

      if (data['axleConfigs'] != null) {
        axleConfigs = (data['axleConfigs'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      manufacturerList.value = manufacturers
          .map((e) => e.manufacturerName)
          .toList();
      tyreSizeList.value = tireSizes
          .map((e) => e.tireSizeName)
          .toSet()
          .toList();
      modelList.clear();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load master data. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoadingMasterData.value = false;
    }
  }

  void incrementPressure(int axleIndex) {
    if (axleIndex < axlePressures.length) {
      // Old app jaise: integer increment, no unit conversion
      axlePressures[axleIndex] = axlePressures[axleIndex] + 1.0;
      axlePressures.refresh();
      getPressureController(axleIndex).text = axlePressures[axleIndex]
          .toStringAsFixed(0);
    }
  }

  void decrementPressure(int axleIndex) {
    if (axleIndex < axlePressures.length && axlePressures[axleIndex] > 0) {
      axlePressures[axleIndex] = axlePressures[axleIndex] - 1.0;
      axlePressures.refresh();
      getPressureController(axleIndex).text = axlePressures[axleIndex]
          .toStringAsFixed(0);
    }
  }

  void setPressure(int axleIndex, double value) {
    if (axleIndex < axlePressures.length) {
      final v = value < 0 ? 0.0 : value;
      axlePressures[axleIndex] = v;
      axlePressures.refresh();
      final ctrl = getPressureController(axleIndex);
      ctrl.text = v == v.truncateToDouble()
          ? v.truncate().toString()
          : v.toString();
      ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
    }
  }

  /* ---------------- MANUFACTURER ---------------- */
  void selectManufacturer(String value) {
    manufacturer.value = value;
    final m = manufacturers.firstWhere(
          (e) => e.manufacturerName == value,
      orElse: () => manufacturers.first,
    );
    manufacturerId.value = m.manufacturerId;

    final mfgTypeIds = models
        .where((model) => model.vehicleManufacturerId == m.manufacturerId)
        .map((model) => model.vehicleTypeId)
        .toSet();
    typeList.value = types
        .where((t) => mfgTypeIds.contains(t.typeId))
        .map((e) => e.typeName)
        .toSet()
        .toList();

    type.value = '';
    typeId.value = 0;
    typeCtrl.clear();
    model.value = '';
    modelId.value = 0;
    modelCtrl.clear();
    modelList.clear();
    _selectedConfigurationId = 0;
    _selectedAxleConfigName = "";
    _resetPressures();
  }

  void selectType(String value) {
    type.value = value;

    final matchedTypeId = models
        .where(
          (m) =>
      m.vehicleManufacturerId == manufacturerId.value &&
          _getTypeNameById(m.vehicleTypeId) == value,
    )
        .map((m) => m.vehicleTypeId)
        .toSet()
        .firstOrNull;

    if (matchedTypeId == null) {
      return;
    }

    typeId.value = matchedTypeId;
    modelList.value = models
        .where(
          (m) =>
      m.vehicleManufacturerId == manufacturerId.value &&
          m.vehicleTypeId == matchedTypeId,
    )
        .map((e) => e.modelName)
        .toSet()
        .toList();

    model.value = '';
    modelId.value = 0;
    modelCtrl.clear();
    _selectedConfigurationId = 0;
    _selectedAxleConfigName = "";
    _resetPressures();
  }

  String _getTypeNameById(int typeId) {
    final found = types.firstWhereOrNull((t) => t.typeId == typeId);
    return found?.typeName ?? '';
  }

  void selectModel(String value) {
    model.value = value;
    final matched = models
        .where(
          (e) =>
      e.modelName == value &&
          e.vehicleManufacturerId == manufacturerId.value &&
          e.vehicleTypeId == typeId.value,
    )
        .toList();

    if (matched.isEmpty) {
      modelId.value = 0;
      _selectedConfigurationId = 0;
      _selectedAxleConfigName = "";
      Get.snackbar('Error', 'Selected model not found');
      return;
    }

    final sel = matched.first;
    modelId.value = sel.modelId;
    _selectedConfigurationId = sel.configurationId;

    if (axleConfigs.isNotEmpty) {
      final cfg = axleConfigs.firstWhereOrNull(
            (c) => (c['configurationId'] as int?) == _selectedConfigurationId,
      );
      _selectedAxleConfigNameRx.value = cfg?['configurationName'] ?? "22";
    } else {
      _selectedAxleConfigName = "22";
    }

    _resetPressures();
  }

  /* ---------------- TYRE SIZE ---------------- */
  void selectTyreSize(String value) {
    tyreSize.value = value;
    final matched = tireSizes.where((e) => e.tireSizeName == value).toList();
    if (matched.isEmpty) {
      tireSizeId.value = 0;
      Get.snackbar('Error', 'Selected tyre size not found');
      return;
    }
    tireSizeId.value = matched.first.tireSizeId;
  }

  int get trackingMethodValue {
    switch (trackingMethodText.value) {
      case 'Hours':
        return 1;
      case 'Distance':
        return 2;
      case 'Both':
        return 3;
      default:
        return 1;
    }
  }

  int get axleConfigIdValue =>
      _selectedConfigurationId > 0 ? _selectedConfigurationId : 1;

  int get installedTyreCount {
    if (_selectedAxleConfigName.isEmpty) return 4;
    return _selectedAxleConfigName
        .split('')
        .where((c) => RegExp(r'[0-9]').hasMatch(c))
        .fold(0, (sum, c) => sum + (int.tryParse(c) ?? 0));
  }

  String get recommendedPressureString {
    if (axlePressures.isEmpty) return "0,0";
    return axlePressures
        .map((p) {
      if (p == p.truncateToDouble()) return p.truncate().toString();
      return p.toString();
    })
        .join(',');
  }

  void _resetPressures() {
    final config = axleConfigValue;
    final int axleCount = config.replaceAll(RegExp(r'[^0-9]'), '').length;
    final count = axleCount > 0 ? axleCount : 2;
    axlePressures.value = List.filled(count, 0.0);
    for (int i = 0; i < count; i++) {
      getPressureController(i).text = '0';
    }
  }

  /* ---------------- SUBMIT ---------------- */
  Future<void> submitForm(AppLocalizations l10n) async {
    if (!_validateForm(l10n)) return;

    try {
      isSubmitting.value = true;

      final String? parentAccountId = await SecureStorage.getParentAccountId();
      final String? locId = await SecureStorage.getLocationId();

      double parsedMiles = 0;
      if (trackingMethodValue == 2 || trackingMethodValue == 3) {
        parsedMiles = double.tryParse(currentKm.value) ?? 0;
      }

      final vehicle = VehicleModel(
        locationId: int.parse(locId.toString()),
        manufacturerId: manufacturerId.value,
        modelId: modelId.value,
        parentAccountId: int.parse(parentAccountId.toString()),
        registeredDate: DateTime.now(),
        tireSizeId: tireSizeId.value,
        typeId: typeId.value,
        vehicleNumber: vehicleNumber.value,
        mileageType: trackingMethodValue,
        trackingMethod: trackingMethodValue,
        removalTread: double.parse(removalTread.value),
        manufacturer: manufacturer.value,
        typeName: type.value,
        modelName: model.value,
        hoursDate: DateTime.now(),
        vehjsonFootprint: '{}',
        tireSize: tyreSize.value,
        axleConfig: axleConfigValue,
        axleConfigId: axleConfigIdValue,
        areaOfOperation: '',
        modifications: '',
        imagesLocation: '',
        installedTireCount: 0,
        installedTires: [],
        currentMiles: parsedMiles,
        currentHours: double.tryParse(currentHours.value) ?? 0,
        averageLoadingReqId: 0,
        averageLoadingReq: '',
        speedId: 0,
        speed: '',
        cutting: '',
        cuttingId: 0,
        severityComments: comments.value,
        recommendedPressure: recommendedPressureString,
        createdBy: parentAccountId,
        createdDate: DateTime.now(),
        updatedBy: parentAccountId,
        updatedDate: DateTime.now(),
        lastUpdatedDate: DateTime.now(),
      );

      final String? userRole = await SecureStorage.getUserProfileRole();
      final bool isEmtUser = (userRole ?? '').trim().toUpperCase() == 'EMTUSER';
      final bool isWorkflowEnabled = await SecureStorage.getApprovalWorkflowEnabled();
      bool isApprover = false;
      if (isEmtUser) {
        isApprover = await SecureStorage.getIsApprover();
      }
      final bool shouldUseTempApi = isEmtUser && (!isWorkflowEnabled || !isApprover);

      int? vehicleId = await _vehicleService.createVehicle(vehicle);

      if (vehicleId == null) {
        Get.snackbar('Error', 'VEHICLE creation failed');
        return;
      }

      final distUnit = kmMilesLabel.value.isNotEmpty ? kmMilesLabel.value : (MeasurementHelper.isMetric ? 'KM' : 'Miles');
      HivePref.set('vehicle_dist_unit_${vehicle.vehicleNumber}', distUnit);
      HivePref.set('vehicle_dist_unit_$vehicleId', distUnit);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('vehicle_dist_unit_${vehicle.vehicleNumber}', distUnit);
        await prefs.setString('vehicle_dist_unit_$vehicleId', distUnit);
      } catch (_) {}

      final bool savedOffline = vehicleId < 0;

      // Determine mileage type string
      String mileageTypeStr = (trackingMethodValue == 1)
          ? 'Hours'
          : (trackingMethodValue == 3
              ? 'Both'
              : (distUnit.toLowerCase() == 'miles' ? 'Miles' : 'KM'));

      final nowIso = DateTime.now().toIso8601String();

      // Seed initial inspection cache so Vehicle Diagram renders axle configuration
      final inspectionCache = {
        "didError": false,
        "message": "",
        "model": {
          "vehicleId": vehicleId,
          "vehicleNumber": vehicle.vehicleNumber,
          "vehicleManufacturer": vehicle.manufacturer,
          "vehicleType": vehicle.typeName,
          "vehicleModel": vehicle.modelName,
          "vehicleMileageType": mileageTypeStr,
          "axleConfig": vehicle.axleConfig,
          "axleConfigId": vehicle.axleConfigId,
          "tireSize": vehicle.tireSize,
          "tireSizeId": vehicle.tireSizeId,
          "lastRecordedHours": vehicle.currentHours,
          "lastRecordedMiles": vehicle.currentMiles,
          "lastRecordedDate": nowIso,
          "comments": vehicle.severityComments,
          "locationId": vehicle.locationId,
          "parentAccountId": vehicle.parentAccountId,
          "installedTires": <Map<String, dynamic>>[],
        }
      };
      await OfflineHiveService.saveInspectionCache(
        vehicleId.toString(),
        jsonEncode(inspectionCache),
      );

      // Sirf vehicle create karne se approval/pending entry NAHI banni
      // chahiye (online ho ya offline). Vehicle tabhi Pending (temp) me
      // jayega jab uski Vehicle Inspection submit hogi
      // (VehicleInspeController.submit). Purana behaviour wapas chahiye
      // to is flag ko true kar do.
      const bool kSubmitVehicleCreateForApproval = false;

      if (shouldUseTempApi && kSubmitVehicleCreateForApproval) {
        if (savedOffline) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'pending_vehicle_create_$vehicleId',
            jsonEncode(vehicle.toJson()),
          );
        }

        final requestorName = await SecureStorage.getUserProfileName() ??
            await SecureStorage.getUserName() ??
            'mobile';
        final grandParentAccountId =
            await SecureStorage.getProfileGrandParentAccountId();

        final Map<String, dynamic> vehicleEntry = {
          "vehicleId": vehicleId,
          "vehicleNumber": vehicle.vehicleNumber,
          "inspectionDate": nowIso,
          "currentHours": double.tryParse(currentHours.value) ?? 0,
          "currentMiles": parsedMiles,
          "action": "UpdateHoursEditTire",
          "locationId": int.tryParse(locId.toString()) ?? 0,
          "parentAccountId": int.tryParse(parentAccountId.toString()) ?? 0,
          if (vehicle.axleConfig != null && vehicle.axleConfig.toString().isNotEmpty) "axleConfig": vehicle.axleConfig,
          if (vehicle.axleConfigId != null) "axleConfigId": vehicle.axleConfigId,
          if (vehicle.axleConfigId != null) "axleConfigurationId": vehicle.axleConfigId,
          if (vehicle.tireSize != null && vehicle.tireSize.toString().isNotEmpty) "tireSize": vehicle.tireSize,
          if (vehicle.tireSizeId != null) "tireSizeId": vehicle.tireSizeId,
          if (vehicle.manufacturer != null && vehicle.manufacturer.toString().isNotEmpty) "vehicleManufacturer": vehicle.manufacturer,
          if (vehicle.typeName != null && vehicle.typeName.toString().isNotEmpty) "vehicleType": vehicle.typeName,
          if (vehicle.modelName != null && vehicle.modelName.toString().isNotEmpty) "vehicleModel": vehicle.modelName,
        };

        final Map<String, dynamic> footprintPayload = {
          "inspectionList": <Map<String, dynamic>>[],
          "tireList": <Map<String, dynamic>>[],
          "vehicleList": [vehicleEntry],
          "Status": {
            "inspectionStatusId": 0,
            "inspectionTypeId": 1,
            "inspectionId": 0,
            "grandParentAccountId": grandParentAccountId ?? 0,
            "statusId": 1, // Pending
            "statusUpdatedBy": "",
            "statusUpdatedDate": "",
            "comments": comments.value,
            "createdBy": requestorName,
            "createdDate": nowIso,
            "modifiedBy": null,
            "modifiedDate": null,
          },
        };

        final VehicleInspeService inspeService = VehicleInspeService();
        final InspectionSubmitResult footprintResult =
            await inspeService.submitApprovalFlowInspection(footprintPayload);

        if (Get.isRegistered<HomeController>()) {
          await Get.find<HomeController>().incrementVehicleCount();
        }

        if (Get.isRegistered<AllVehicleController>()) {
          Get.find<AllVehicleController>().refreshVehicles();
        }

        final String vehicleNoToSend = vehicleNumber.value;
        resetForm();

        Get.offAllNamed(
          AppPages.HOME,
          arguments: {
            "showSuccess": true,
            "type": "submit",
            "module": "vehicle",
            "vehicleNo": vehicleNoToSend,
            "vehicleId": vehicleId,
            "savedOffline": footprintResult.offline || savedOffline,
            "isPendingApproval": true,
          },
        );

        if (footprintResult.offline || savedOffline) {
          AppSnackbar.offlineSuccess(
            'Vehicle $vehicleNoToSend submitted for approval (Offline).',
            title: 'Submitted for Approval',
          );
        } else {
          AppSnackbar.success(
            'Vehicle $vehicleNoToSend submitted for approval.',
            title: 'Submitted for Approval',
          );
        }
        return;
      }

      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().incrementVehicleCount();
      }

      if (Get.isRegistered<AllVehicleController>()) {
        Get.find<AllVehicleController>().refreshVehicles();
      }

      final String vehicleNoToSend = vehicleNumber.value;
      resetForm();

      Get.offAllNamed(
        AppPages.HOME,
        arguments: {
          "showSuccess": true,
          "type": "submit",
          "module": "vehicle",
          "vehicleNo": vehicleNoToSend,
          "vehicleId": vehicleId,
          "savedOffline": savedOffline,
        },
      );
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong. Please try again.');
    } finally {
      isSubmitting.value = false;
    }
  }

  /* ---------------- VALIDATION (LOCALIZED) ---------------- */
  bool _validateForm(AppLocalizations t) {
    _clearErrors();
    bool isValid = true;

    if (vehicleNumber.value.trim().isEmpty) {
      vehicleNumberError.value = t.requiredField;
      isValid = false;
    } else if (Get.isRegistered<AllVehicleController>()) {
      final isDuplicate = Get.find<AllVehicleController>().vehicleList.any(
            (v) =>
        v.vehicleNumber!.toLowerCase() ==
            vehicleNumber.value.trim().toLowerCase(),
      );
      if (isDuplicate) {
        vehicleNumberError.value = t.duplicateVehicleError;
        isValid = false;
      }
    }

    if (trackingMethodText.value.trim().isEmpty) {
      trackingMethodError.value = t.requiredField;
      isValid = false;
    }

    if (trackingMethodValue == 1 || trackingMethodValue == 3) {
      if (currentHours.value.trim().isEmpty) {
        currentHoursError.value = t.requiredField;
        isValid = false;
      } else if (double.tryParse(currentHours.value) == null) {
        currentHoursError.value = t.numericOnly;
        isValid = false;
      } else if (double.parse(currentHours.value) < 0) {
        currentHoursError.value = t.negativeValueError;
        isValid = false;
      }
    }

    if (trackingMethodValue == 2 || trackingMethodValue == 3) {
      if (currentKm.value.trim().isEmpty) {
        currentKmError.value = t.requiredField;
        isValid = false;
      } else if (double.tryParse(currentKm.value) == null) {
        currentKmError.value = t.numericOnly;
        isValid = false;
      } else if (double.parse(currentKm.value) < 0) {
        currentKmError.value = t.negativeValueError;
        isValid = false;
      }
    }

    if (manufacturerId.value == 0) {
      manufacturerError.value = t.requiredField;
      isValid = false;
    }
    if (typeId.value == 0) {
      typeError.value = t.requiredField;
      isValid = false;
    }
    if (modelId.value == 0) {
      modelError.value = t.requiredField;
      isValid = false;
    }
    if (tireSizeId.value == 0) {
      tyreSizeError.value = t.requiredField;
      isValid = false;
    }

    if (removalTread.value.trim().isEmpty) {
      removalTreadError.value = t.requiredField;
      isValid = false;
    } else if (double.tryParse(removalTread.value) == null) {
      removalTreadError.value = t.numericOnly;
      isValid = false;
    }

    return isValid;
  }

  void _clearErrors() {
    vehicleNumberError.value = '';
    trackingMethodError.value = '';
    manufacturerError.value = '';
    typeError.value = '';
    modelError.value = '';
    tyreSizeError.value = '';
    removalTreadError.value = '';
    commentsError.value = '';
    currentHoursError.value = '';
    currentKmError.value = '';
  }

  void clearVehicleNumberError() => vehicleNumberError.value = '';
  void clearTrackingMethodError() => trackingMethodError.value = '';
  void clearManufacturerError() => manufacturerError.value = '';
  void clearTypeError() => typeError.value = '';
  void clearModelError() => modelError.value = '';
  void clearTyreSizeError() => tyreSizeError.value = '';
  void clearRemovalTreadError() => removalTreadError.value = '';
  void clearCommentsError() => commentsError.value = '';
  void clearCurrentHoursError() => currentHoursError.value = '';
  void clearCurrentKmError() => currentKmError.value = '';

  /* ---------------- RESET ---------------- */
  void resetForm() {
    vehicleNumber.value = '';
    manufacturer.value = '';
    type.value = '';
    model.value = '';
    tyreSize.value = '';
    removalTread.value = '';
    comments.value = '';
    currentHours.value = '0';
    currentKm.value = '0';
    manufacturerId.value = 0;
    typeId.value = 0;
    modelId.value = 0;
    tireSizeId.value = 0;
    _selectedConfigurationId = 0;
    _selectedAxleConfigNameRx.value = "";
    axlePressures.value = [0.0, 0.0];
    currentHoursCtrl.clear();
    currentKmCtrl.clear();
  }
}