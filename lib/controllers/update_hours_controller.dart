import 'dart:convert';
import 'package:emtrack/inspection/vehicle_inspe_controller.dart';
import 'package:emtrack/inspection/vehicle_inspe_model.dart';
import 'package:emtrack/models/update_hours_model.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:emtrack/services/update_hours_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/local_helper.dart';
import '../utils/hive_prefe.dart';
import '../utils/mesurment_helper_class.dart';
import '../utils/tyre_unit_history.dart';

class UpdateHoursController extends GetxController {
  var lastRecordedHours = 0.0.obs;
  var lastRecordedMiles = 0.0.obs;
  var surveyDate = "".obs;
  var vehicleNumber = "".obs;
  var lastRecordedDate = "".obs;
  var vehicleId = 0.obs;
  var loading = false.obs;

  RxString displayLastRecordedKm = '-'.obs;
  String kmMilesLabel = 'KM';
  String? _argDistUnit;

  RxString mileageType = 'Both'.obs;

  RxnString updateHoursError = RxnString();
  RxnString updateKmError = RxnString();

  final updateHoursService = UpdateHoursService();

  TextEditingController updateHoursController = TextEditingController();
  TextEditingController updateKmController = TextEditingController();
  TextEditingController surveyDateController = TextEditingController();
  TextEditingController vehicleIdCtrl = TextEditingController();

  VehicleInspectionModel? vehicleModel;

  bool get showHours =>
      mileageType.value == '1' ||
          mileageType.value == '3' ||
          mileageType.value == 'Hours' ||
          mileageType.value == 'Both';

  bool get showKm =>
      mileageType.value == '2' ||
          mileageType.value == '3' ||
          mileageType.value == 'Distance' ||
          mileageType.value == 'Both';

  String get unitString {
    final type = mileageType.value.toString().trim();
    if (type == 'Miles') {
      return 'Miles';
    }
    return kmMilesLabel;
  }

  bool get isInspectionFlow {
    final rawArgs = Get.arguments;
    if (rawArgs is Map && rawArgs['isInspectionFlow'] == true) return true;
    return Get.isRegistered<VehicleInspeController>();
  }

  @override
  void onInit() {
    super.onInit();
    _loadPreferences();

    final args = Get.arguments;
    String currentDate = LocaleHelper.formatDate(DateTime.now());

    if (args is VehicleInspectionModel) {
      vehicleModel = args;

      vehicleId.value = vehicleModel?.vehicleId ?? 0;
      lastRecordedHours.value = vehicleModel?.lastRecordedHours ?? 0.0;
      lastRecordedMiles.value = vehicleModel?.lastRecordedMiles ?? 0.0;
      lastRecordedDate.value = vehicleModel?.lastRecordedDate ?? '';
      surveyDate.value = currentDate;
      vehicleNumber.value = vehicleModel?.vehicleNumber ?? '';
      final mt1 = vehicleModel?.vehicleMileageType?.toString().trim() ?? '';
      mileageType.value = mt1.isEmpty ? 'Both' : mt1;

      _updateDisplayKm();
      _clearFields(currentDate);
    } else if (args is Map) {
      final int vId = args['vehicleId'] is int
          ? args['vehicleId']
          : (int.tryParse(args['vehicleId']?.toString() ?? '') ?? 0);
      vehicleId.value = vId;
      surveyDate.value = currentDate;
      surveyDateController.text = currentDate;
      vehicleIdCtrl.text = vId.toString();

      final double? argHours = (args['currentHours'] as num?)?.toDouble();
      final double? argKm = (args['currentKm'] as num?)?.toDouble();
      final String? argDistUnit = args['distUnit']?.toString();
      _argDistUnit = (argDistUnit != null && argDistUnit.isNotEmpty) ? argDistUnit : null;
      if (argDistUnit != null && argDistUnit.isNotEmpty) {
        HivePref.set('vehicle_dist_unit_$vId', argDistUnit);
      }

      try {
        if (Get.isRegistered<VehicleInspeController>()) {
          final inspeCtrl = Get.find<VehicleInspeController>();
          vehicleModel = inspeCtrl.model;
          if (vehicleModel != null) {
            final double currentH = argHours ?? (double.tryParse(inspeCtrl.hoursCtrl.text.isNotEmpty ? inspeCtrl.hoursCtrl.text : inspeCtrl.hours.value) ??
                vehicleModel?.lastRecordedHours ??
                0.0);
            final double currentK = argKm ?? (inspeCtrl.serverKm > 0 ? inspeCtrl.serverKm : (vehicleModel?.lastRecordedMiles ?? 0.0));
            lastRecordedHours.value = currentH;
            lastRecordedMiles.value = currentK;
            lastRecordedDate.value = vehicleModel?.lastRecordedDate ?? '';
            vehicleNumber.value = vehicleModel?.vehicleNumber ?? '';
            final mt2 =
                vehicleModel?.vehicleMileageType?.toString().trim() ?? '';
            mileageType.value = mt2.isEmpty ? 'Both' : mt2;
            _updateDisplayKm();
          } else {
            _loadOfflineData(vId);
            if (argHours != null && argHours > 0) lastRecordedHours.value = argHours;
            if (argKm != null && argKm > 0) {
              lastRecordedMiles.value = argKm;
              _updateDisplayKm();
            }
          }
        } else {
          _loadOfflineData(vId);
          if (argHours != null && argHours > 0) lastRecordedHours.value = argHours;
          if (argKm != null && argKm > 0) {
            lastRecordedMiles.value = argKm;
            _updateDisplayKm();
          }
        }
      } catch (e) {
        _loadOfflineData(vId);
        if (argHours != null && argHours > 0) lastRecordedHours.value = argHours;
        if (argKm != null && argKm > 0) {
          lastRecordedMiles.value = argKm;
          _updateDisplayKm();
        }
      }
    } else if (args is int) {
      vehicleId.value = args;
      surveyDate.value = currentDate;
      surveyDateController.text = currentDate;
      vehicleIdCtrl.text = args.toString();

      try {
        if (Get.isRegistered<VehicleInspeController>()) {
          final inspeCtrl = Get.find<VehicleInspeController>();
          vehicleModel = inspeCtrl.model;
          if (vehicleModel != null) {
            lastRecordedHours.value = vehicleModel?.lastRecordedHours ?? 0.0;
            lastRecordedMiles.value = vehicleModel?.lastRecordedMiles ?? 0.0;
            lastRecordedDate.value = vehicleModel?.lastRecordedDate ?? '';
            vehicleNumber.value = vehicleModel?.vehicleNumber ?? '';
            final mt2 = vehicleModel?.vehicleMileageType?.toString().trim() ?? '';
            mileageType.value = mt2.isEmpty ? 'Both' : mt2;
            _updateDisplayKm();
          } else {
            _loadOfflineData(args);
          }
        } else {
          _loadOfflineData(args);
        }
      } catch (e) {
        _loadOfflineData(args);
      }
    }
  }

  void _loadPreferences() {
    final savedMeasurement = HivePref.get<String>('pref_measurement');
    if (savedMeasurement != null && savedMeasurement.isNotEmpty) {
      kmMilesLabel = savedMeasurement.toLowerCase() == 'metric'
          ? 'KM'
          : 'Miles';
    }
  }

  void _updateDisplayKm() {
    final double base = lastRecordedMiles.value;
    if (isInspectionFlow) {
      displayLastRecordedKm.value = base.round().toString();
      return;
    }
    String srcUnit = _argDistUnit ?? (HivePref.get<String>('vehicle_dist_unit_${vehicleId.value}') ?? '');
    if (srcUnit.isEmpty && vehicleNumber.value.isNotEmpty) {
      srcUnit = HivePref.get<String>('vehicle_dist_unit_${vehicleNumber.value}') ?? '';
    }
    if (srcUnit.isEmpty) {
      final mt = mileageType.value.toLowerCase().trim();
      srcUnit = (mt == 'miles' || mt == 'imperial')
          ? 'Miles'
          : ((mt == 'km' || mt == 'metric') ? 'KM' : kmMilesLabel);
    }
    final double calculatedValue = MeasurementHelper.toDisplayDistance(
      base,
      sourceUnit: srcUnit,
    );
    displayLastRecordedKm.value = calculatedValue.round().toString();
  }

  void _clearFields(String currentDate) {
    updateHoursController.clear();
    updateKmController.clear();
    surveyDateController.text = currentDate;
    vehicleIdCtrl.text = vehicleId.value.toString();
  }

  void _loadOfflineData(int vId) {
    final hiveVehicle = OfflineHiveService.getVehicleById(vId);
    if (hiveVehicle != null) {
      vehicleNumber.value = hiveVehicle.vehicleNumber;
      lastRecordedHours.value = hiveVehicle.currentHours ?? 0.0;
      lastRecordedMiles.value = hiveVehicle.currentMiles ?? 0.0;

      final String hDate = hiveVehicle.lastRecordedDate ?? hiveVehicle.savedAt;
      lastRecordedDate.value = hDate;
      final mt3 = hiveVehicle.mileageType?.toString().trim() ?? '';
      mileageType.value = mt3.isEmpty ? 'Both' : mt3;
      _updateDisplayKm();
    } else {
      lastRecordedDate.value = "N/A";
      displayLastRecordedKm.value = '-';
    }
  }

  Future<DateTime?> showCustomDatePicker(
      BuildContext context,
      DateTime initialDate,
      ) async {
    DateTime selectedDate = initialDate;
    return await showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFB71C1C),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${selectedDate.year}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      LocaleHelper.formatPickerHeader(selectedDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    surface: Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                    primary: Color(0xFFD32F2F),
                    onPrimary: Colors.white,
                  ),
                ),
                child: SizedBox(
                  height: 320,
                  child: CalendarDatePicker(
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    onDateChanged: (d) => setState(() => selectedDate = d),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, DateTime(1900)),
                      child: const Text(
                        "CLEAR",
                        style: TextStyle(
                          color: Color(0xFFEF5350),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "CANCEL",
                        style: TextStyle(
                          color: Color(0xFFEF5350),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context, selectedDate),
                      child: const Text(
                        "SET",
                        style: TextStyle(
                          color: Color(0xFFEF5350),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void pickSurveyDate(BuildContext context) async {
    DateTime initialDate =
        LocaleHelper.parseDisplayDate(surveyDate.value) ?? DateTime.now();
    final result = await showCustomDatePicker(context, initialDate);
    if (result != null) {
      if (result.year == 1900) {
        surveyDateController.text = "";
        surveyDate.value = "";
      } else {
        final formatted = LocaleHelper.formatDate(result);
        surveyDateController.text = formatted;
        surveyDate.value = formatted;
      }
    }
  }

  String _buildUpdateSummary() {
    final units = <String>[];
    if (showHours) {
      units.add('Hours');
    }
    if (showKm) {
      units.add(unitString);
    }

    if (units.isEmpty) return 'Update';
    return 'Update ${units.join(' and ')}';
  }
  Future<void> submitUpdateHours() async {
    loading.value = true;
    try {
      final hoursErr = showHours ? validateHours() : null;
      final kmErr = showKm ? validateKm() : null;

      if (hoursErr != null || kmErr != null) {
        updateHoursError.value = hoursErr;
        updateKmError.value = kmErr;
        loading.value = false;
        return;
      }

      if (surveyDate.value.isEmpty || vehicleId.value == 0) {
        Get.snackbar("Error", "Required fields are missing.");
        loading.value = false;
        return;
      }

      final double previousHours = lastRecordedHours.value;
      final double previousDisplayKm =
          double.tryParse(displayLastRecordedKm.value) ?? 0.0;

      final updatedHours = showHours
          ? (double.tryParse(updateHoursController.text) ?? 0.0)
          : previousHours;
      final enteredKmVal = double.tryParse(updateKmController.text) ?? 0.0;
      double finalServerKmValue = lastRecordedMiles.value;

      double hoursDeltaForTires = 0.0;
      if (showHours && updateHoursController.text.trim().isNotEmpty) {
        hoursDeltaForTires = updatedHours - previousHours;
      }

      double kmDeltaForTires = 0.0;
      bool kmWasUpdated = false;
      String effectiveDistUnit = _argDistUnit ?? (HivePref.get<String>('vehicle_dist_unit_${vehicleId.value}') ?? 'KM');
      if (showKm && updateKmController.text.trim().isNotEmpty) {
        kmWasUpdated = true;
        effectiveDistUnit = kmMilesLabel;
        // User ne jo number enter kiya (e.g. 120), wahi raw value preserve karo.
        finalServerKmValue = enteredKmVal;
        final double effectivePrevKm = (previousDisplayKm > 0 && previousDisplayKm <= enteredKmVal)
            ? previousDisplayKm
            : lastRecordedMiles.value;
        kmDeltaForTires = (enteredKmVal > effectivePrevKm)
            ? (enteredKmVal - effectivePrevKm)
            : ((enteredKmVal > lastRecordedMiles.value) ? (enteredKmVal - lastRecordedMiles.value) : 0.0);
        HivePref.set('vehicle_dist_unit_${vehicleId.value}', kmMilesLabel);
        if (vehicleNumber.value.isNotEmpty) {
          HivePref.set('vehicle_dist_unit_${vehicleNumber.value}', kmMilesLabel);
        }
      }

      if (isInspectionFlow) {
        final String updateSummary = _buildUpdateSummary();
        Get.back(
          result: {
            'hours': updatedHours,
            'km': finalServerKmValue,
            'kmWasUpdated': kmWasUpdated,
            'distUnit': effectiveDistUnit,
            'hoursDeltaForTires': hoursDeltaForTires,
            'kmDeltaForTires': kmDeltaForTires,
            'isOffline': false,
          },
        );
        await Future.delayed(const Duration(milliseconds: 350));
        AppSnackbar.success(
          updateSummary,
          title: 'Hours Updated (Draft)',
        );
        return;
      }

      final locationIdStr = await SecureStorage.getLocationId();
      final parentAccountIdStr = await SecureStorage.getParentAccountId();
      final locationId = int.tryParse(locationIdStr ?? '');
      final parentAccountId = int.tryParse(parentAccountIdStr ?? '');

      if (locationId == null || parentAccountId == null) {
        Get.snackbar("Error", "Location or ParentAccount missing");
        loading.value = false;
        return;
      }

      final parsedSurveyDate =
          LocaleHelper.parseDisplayDate(surveyDate.value) ?? DateTime.now();

      final model = UpdateHoursModel(
        action: "UpdateHours",
        inspectionDate: parsedSurveyDate,
        locationId: locationId,
        parentAccountId: parentAccountId,
        vehicleId: vehicleId.value,
        currentHours: updatedHours,
        currentMiles: finalServerKmValue,
        hoursAdjustToTire: 0,
        milesAdjustToTire: 0,
        isMobInstall: true,
      );

      final result = await updateHoursService.submitUpdate(model);
      _updateLocalVehicleData(
        vehicleId.value,
        updatedHours,
        finalServerKmValue,
        hoursDelta: hoursDeltaForTires,
        kmDelta: kmDeltaForTires,
      );

      final bool wasSyncedOnline = result;

      // Generates text like: "Update Hours and Update KM" or "Update Hours" / "Update Miles"
      final String updateSummary = _buildUpdateSummary();

      Get.back(
        result: {
          'hours': updatedHours,
          'km': finalServerKmValue,
          'hoursDeltaForTires': hoursDeltaForTires,
          'kmDeltaForTires': kmDeltaForTires,
          'isOffline': !wasSyncedOnline,
        },
      );

      await Future.delayed(const Duration(milliseconds: 350));

      if (wasSyncedOnline) {
        AppSnackbar.success(
          updateSummary,
          title: 'Updated successfully',
        );
      } else {
        AppSnackbar.offlineSuccess(
          updateSummary,
          title: 'Saved Offline',
        );
      }
    } catch (e) {
      Get.snackbar("Error", "Something went wrong.");
    } finally {
      loading.value = false;
    }
  }

  void _updateLocalVehicleData(
    int vId,
    double hours,
    double km, {
    double hoursDelta = 0.0,
    double kmDelta = 0.0,
  }) {
    lastRecordedHours.value = hours;
    lastRecordedMiles.value = km;
    _updateDisplayKm();
    lastRecordedDate.value = surveyDate.value;

    if (vehicleModel != null) {
      vehicleModel!.lastRecordedHours = hours;
      vehicleModel!.lastRecordedMiles = km;
      try {
        final parsed =
            LocaleHelper.parseDisplayDate(surveyDate.value) ?? DateTime.now();
        vehicleModel!.lastRecordedDate = parsed.toIso8601String();
      } catch (_) {}
    }

    OfflineHiveService.updateVehicleHours(
      vId,
      hours,
      km,
      lastRecordedDate: surveyDate.value,
    );

    if (hoursDelta > 0 || kmDelta > 0) {
      try {
        final offlineTyres = OfflineHiveService.getTyresByVehicle(vId);
        for (final t in offlineTyres) {
          if (hoursDelta > 0) {
            t.currentHours = (t.currentHours ?? 0.0) + hoursDelta;
          }
          if (kmDelta > 0) {
            t.currentMiles = (t.currentMiles ?? 0.0) + kmDelta;
          }
          try {
            t.save();
          } catch (_) {}
          if (t.tireId > 0 && kmDelta > 0) {
            TyreUnitHistory.recordRawReadings(tireId: t.tireId, miles: t.currentMiles);
          }
        }
      } catch (_) {}

      try {
        final cached = OfflineHiveService.getInspectionCache(vId.toString());
        if (cached != null) {
          final jsonData = jsonDecode(cached) as Map<String, dynamic>;
          final m = jsonData['model'] as Map<String, dynamic>?;
          if (m != null) {
            final tList = (m['installedTires'] as List? ?? []);
            for (final ct in tList) {
              if (ct is Map) {
                if (hoursDelta > 0) {
                  ct['currentHours'] =
                      ((ct['currentHours'] as num?)?.toDouble() ?? 0.0) +
                          hoursDelta;
                }
                if (kmDelta > 0) {
                  ct['currentMiles'] =
                      ((ct['currentMiles'] as num?)?.toDouble() ?? 0.0) +
                          kmDelta;
                }
              }
            }
            m['installedTires'] = tList;
            jsonData['model'] = m;
            OfflineHiveService.saveInspectionCache(
              vId.toString(),
              jsonEncode(jsonData),
            );
          }
        }
      } catch (_) {}
    }
  }

  String? validateHours() {
    if (updateHoursController.text.trim().isEmpty) return "Please enter hours";
    final entered = double.tryParse(updateHoursController.text.trim()) ?? 0;
    if (entered <= lastRecordedHours.value) {
      return "Must be greater than last recorded hours (${lastRecordedHours.value.round()})";
    }
    return null;
  }

  String? validateKm() {
    final currentDisplayBase =
        double.tryParse(displayLastRecordedKm.value) ?? 0.0;

    // Support units/graders with 0 previous KM can leave or enter 0.
    final rawText = updateKmController.text.trim();
    if (rawText.isEmpty) {
      if (currentDisplayBase <= 0) return null;
      return "Please enter $unitString";
    }

    final entered = double.tryParse(rawText) ?? 0;
    if (entered < 0) return "$unitString cannot be negative";

    if (currentDisplayBase <= 0 && entered == 0) {
      return null;
    }

    if (entered <= currentDisplayBase) {
      return "Must be greater than last recorded $unitString (${currentDisplayBase.round()})";
    }
    return null;
  }

  String formatDate(String? apiDate) {
    if (apiDate == null || apiDate.isEmpty || apiDate == "N/A") return "N/A";
    try {
      DateTime parsedDate;
      if (apiDate.contains('-') || apiDate.contains('T')) {
        parsedDate = DateTime.parse(apiDate);
      } else {
        parsedDate = LocaleHelper.parseDisplayDate(apiDate) ?? DateTime.now();
      }
      return LocaleHelper.formatDate(parsedDate);
    } catch (e) {
      return apiDate;
    }
  }


  @override
  void onClose() {
    updateHoursController.dispose();
    updateKmController.dispose();
    surveyDateController.dispose();
    vehicleIdCtrl.dispose();
    super.onClose();
  }
}