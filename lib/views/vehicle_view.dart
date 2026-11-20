import 'dart:convert';
import 'package:emtrack/color/app_color.dart';
import 'package:emtrack/controllers/selected_account_controller.dart';
import 'package:emtrack/inspection/vehicle_inspe_controller.dart';
import 'package:emtrack/inspection/vehicle_inspe_view.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/services/update_vehicle_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../l10n/app_localizations.dart';
import '../models/vehicle_model.dart';
import '../utils/hive_prefe.dart';
import '../utils/mesurment_helper_class.dart';
import '../widgets/vehicle_daigram.dart';

class VehicleView extends StatefulWidget {
  const VehicleView({super.key});

  @override
  State<VehicleView> createState() => _VehicleViewState();
}

class _VehicleViewState extends State<VehicleView> {
  final UpdateVehicleService _vehicleService = UpdateVehicleService();
  final selectedCtrl = Get.put(SelectedAccountController());

  VehicleModel? vehicle;
  bool isLoading = true;
  String pressureUnit = 'PSI';
  String measurementUnit = '/32nds';

  String get kmMilesLabel => MeasurementHelper.distanceLabel;

  VehicleInspeController? _inspeController;

  @override
  void initState() {
    super.initState();
    _loadPreferences();

    _loadVehicle();
  }

  void _loadPreferences() {
    final savedPressure = HivePref.get<String>('pref_pressure');
    if (savedPressure != null && savedPressure.isNotEmpty) {
      pressureUnit = savedPressure.toUpperCase();
    }
  }

  String _formatPressure(dynamic rawValue) {
    if (rawValue == null) return '-';
    final d = double.tryParse(rawValue.toString());
    if (d == null) return rawValue.toString();
    if (d == d.truncateToDouble()) return d.truncate().toString();
    return d.toString();
  }

  Future<void> _loadVehicle() async {
    try {
      AppLocalizations? t;
      try {
        t = AppLocalizations.of(Get.context!);
      } catch (_) {
        t = null;
      }

      final int? vehicleId = Get.arguments;

      if (vehicleId == null) {
        if (mounted) setState(() => isLoading = false);
        if (t != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.snackbar(t!.error, t.noVehicleId);
          });
        }
        return;
      }

      // FIX: Only create a fresh VehicleInspeController if one isn't already
      // registered for this vehicle. Force-deleting and re-`Get.put`-ing on
      // every call swaps the observable instance out from under any Obx
      // that is still mounting for the previous frame, which is what was
      // triggering the "improper use of GetX/Obx" crash.
      final bool alreadyRegistered =
      Get.isRegistered<VehicleInspeController>();
      final bool sameVehicle = alreadyRegistered &&
          Get.find<VehicleInspeController>().vehicleId.value ==
              vehicleId.toString();

      if (alreadyRegistered && !sameVehicle) {
        Get.delete<VehicleInspeController>(force: true);
      }

      if (!Get.isRegistered<VehicleInspeController>()) {
        _inspeController = Get.put(VehicleInspeController());
        _inspeController!.vehicleId.value = vehicleId.toString();
      } else {
        _inspeController = Get.find<VehicleInspeController>();
      }

      if (vehicleId < 0) {
        final hiveVehicle = OfflineHiveService.getVehicleById(vehicleId);
        if (hiveVehicle != null && mounted) {
          setState(() {
            vehicle = _hiveToVehicleModel(hiveVehicle);
            isLoading = false;
          });
        } else if (mounted) {
          setState(() => isLoading = false);
          if (t != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Get.snackbar(t!.error, t.noDataAvailable);
            });
          }
        }
        return;
      }

      final cachedJson = OfflineHiveService.getVehicleDetailCache(vehicleId);
      if (cachedJson != null) {
        final parsed = _parseVehicleFromCache(cachedJson);
        if (parsed != null && mounted) {
          setState(() {
            vehicle = parsed;
            isLoading = false;
          });
        }
      }

      // FIX: Removed the duplicate explicit fetchInspectionData() call.
      // VehicleInspeController already triggers this from its own onInit()
      // when Get.put() creates it, so calling it again here was firing the
      // request twice per load (visible in the logs as two back-to-back
      // "fetchInspectionData() CALLED" lines) and mutating the observable
      // response while the Obx below was still mounting for the first
      // frame. If your controller does NOT call it from onInit(), re-add a
      // single call here wrapped in a post-frame callback instead:
      //
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   _inspeController?.fetchInspectionData();
      // });

      try {
        final freshVehicle = await _vehicleService.getVehicleById(vehicleId);
        if (freshVehicle != null && mounted) {
          setState(() {
            vehicle = freshVehicle;
            isLoading = false;
          });
        } else if (vehicle == null && mounted) {
          setState(() => isLoading = false);
          if (t != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Get.snackbar(t!.error, t.vehicleNotFound);
            });
          }
        }
      } catch (e) {
        if (vehicle == null && mounted) {
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      if (mounted && isLoading) {
        setState(() => isLoading = false);
      }
    }
  }

  VehicleModel? _parseVehicleFromCache(String jsonString) {
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return VehicleModel.fromJson(map);
    } catch (e) {
      return null;
    }
  }

  VehicleModel _hiveToVehicleModel(dynamic h) {
    return VehicleModel(
      vehicleId: h.vehicleId,
      vehicleNumber: h.vehicleNumber,
      manufacturer: h.manufacturerName ?? '',
      typeName: h.typeName ?? '',
      modelName: h.modelName ?? '',
      manufacturerId: h.manufacturerId ?? 0,
      modelId: h.modelId ?? 0,
      tireSizeId: h.tireSizeId ?? 0,
      tireSize: h.tireSizeName ?? '',
      axleConfig: h.axleConfig ?? '22',
      axleConfigId: h.axleConfigId ?? 0,
      locationId: h.locationId,
      parentAccountId: h.parentAccountId,
      mileageType: h.trackingMethod ?? 1,
      trackingMethod: h.trackingMethod ?? 1,
      removalTread: h.removalTread ?? h.removalTreadDouble ?? 0,
      currentHours: h.currentHours ?? 0,
      currentMiles: h.currentMiles ?? 0,
      severityComments: h.severityComments ?? '',
      recommendedPressure: h.recommendedPressure ?? '0,0',
      installedTires: [],
      installedTireCount: 0,
    );
  }

  String _clean(dynamic val) {
    if (val == null) return '-';
    final d = double.tryParse(val.toString());
    if (d == null) return val.toString();
    if (d == d.truncateToDouble()) {
      return d.toInt().toString();
    }
    return d.toString();
  }

  String _cleanMiles(dynamic val) {
    if (val == null) return '-';
    final d = double.tryParse(val.toString());
    if (d == null) return val.toString();

    if (MeasurementHelper.isImperial) {
      return d.round().toString();
    }

    final vId = vehicle?.vehicleId ?? _inspeController?.vehicleId.value;
    String srcUnit = vId != null ? (HivePref.get<String>('vehicle_dist_unit_$vId') ?? '') : '';
    if (srcUnit.isEmpty && vehicle?.vehicleNumber != null && vehicle!.vehicleNumber!.isNotEmpty) {
      srcUnit = HivePref.get<String>('vehicle_dist_unit_${vehicle!.vehicleNumber}') ?? '';
    }
    if (srcUnit.isEmpty) {
      final modelMt = _inspeController?.model?.vehicleMileageType?.toString().trim().toLowerCase();
      final vehMt = vehicle?.mileageType?.toString().trim().toLowerCase();
      final mt = (modelMt != null && modelMt.isNotEmpty) ? modelMt : (vehMt ?? '');
      srcUnit = (mt == 'miles') ? 'Miles' : ((mt == 'km') ? 'KM' : MeasurementHelper.distanceLabel);
    }

    final double calculatedValue = MeasurementHelper.toDisplayDistance(d, sourceUnit: srcUnit);
    return calculatedValue.round().toString();
  }

  // ✅ FIX: source of truth = Inspection screen's data (proven correct),
  // with `vehicle!.currentHours`/`currentMiles` only as a fallback while
  // the inspection fetch is still in-flight or if it fails.
  String _displayHours() {
    final model = _inspeController?.model;
    if (model?.lastRecordedHours != null) {
      return _clean(model!.lastRecordedHours);
    }
    return _clean(vehicle?.currentHours);
  }

  String _displayKm() {
    final model = _inspeController?.model;
    if (model?.lastRecordedMiles != null) {
      return _cleanMiles(model!.lastRecordedMiles);
    }
    return _cleanMiles(vehicle?.currentMiles);
  }

  int get parsedVehicleId =>
      int.tryParse(vehicle?.vehicleId.toString() ?? '0') ?? 0;

  int get _safeMileageType {
    final mt = vehicle?.mileageType;
    if (mt == null || mt == 0) return 3;
    return mt;
  }

  String _getTrackingLabel(AppLocalizations t) {
    switch (_safeMileageType) {
      case 1:
        return t.trackingMethodHours;
      case 2:
        return t.trackingMethodDistance;
      case 3:
        return t.trackingMethodBoth;
      default:
        return t.trackingMethodBoth;
    }
  }

  List<String> get _pressureValues {
    final raw = vehicle?.recommendedPressure ?? '';
    if (raw.isEmpty) return [];
    return raw.split(',').map((p) => p.trim()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title:
        Text(t.viewVehicle, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : vehicle == null
            ? Center(child: Text(t.noDataAvailable))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.selectedParentAccountLocation),
              Obx(
                    () => Text(
                  '${selectedCtrl.parentAccountName.value} - ${selectedCtrl.locationName.value}',
                  style: TextStyle(
                    color: AppColors.buttonDanger,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

              _row(t.vehicleId, vehicle!.vehicleNumber ?? '-'),
              _row(t.trackingMethod, _getTrackingLabel(t)),

              if (_safeMileageType == 1 || _safeMileageType == 3)
                _row(t.currentHours, _displayHours()),

              if (_safeMileageType == 2 || _safeMileageType == 3)
                Obx(
                      () => _row(
                    t.currentKm.replaceAll('{unit}', kmMilesLabel),
                    _displayKm(),
                  ),
                ),
              _row(t.manufacturer, vehicle!.manufacturer ?? '-'),
              _row(t.vehicleType, vehicle!.typeName ?? '-'),
              _row(t.model, vehicle!.modelName ?? '-'),
              _row(t.tyreSize, vehicle!.tireSize ?? '-'),
              _row(t.removalTread, _clean(vehicle!.removalTread)),
              _row(t.vehicleComments,
                  vehicle!.severityComments ?? '-'),

              const SizedBox(height: 20),
              Text(t.vehicleDiagram),

              _inspeController == null
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(
                      color: Colors.red),
                ),
              )
                  : Obx(
                // FIX: keying the Obx to the current
                // controller instance forces Flutter to
                // fully unmount/remount this subtree
                // (instead of trying to patch a live
                // subscription) whenever the underlying
                // VehicleInspeController instance changes,
                // which is what was corrupting Obx's
                // internal subscriber bookkeeping and
                // throwing the "improper use of
                // GetX/Obx" error.
                key: ValueKey(_inspeController.hashCode),
                    () {
                  final response = _inspeController!
                      .inspectionResponse.value;
                  if (response == null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20),
                      child: Center(
                        child: Text(
                          t.noDataAvailable,
                          style: const TextStyle(
                              color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  return IgnorePointer(
                    child: VehicleDiagram(
                      tires: _inspeController!.tires,
                      vehicleId: parsedVehicleId,
                      vehicleNumber:
                      vehicle?.vehicleNumber ?? '',
                      axleConfig:
                      vehicle?.axleConfig ?? '22',
                      isEditMode: true,
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              if (_pressureValues.isNotEmpty)
                ...List.generate(
                  _pressureValues.length,
                      (i) => _row(
                    '${t.recommendedPressure} ${t.axleLabel} ${i + 1}',
                    '${_formatPressure(_pressureValues[i])} $pressureUnit',
                  ),
                )
              else
                _row(t.recommendedPressure, '-'),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        width: MediaQuery.of(context).size.width - 24,
        height: 56,
        child: Material(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              if (Get.isRegistered<VehicleInspeController>()) {
                Get.delete<VehicleInspeController>(force: true);
              }
              Get.to(() => VehicleInspeView(), arguments: vehicle?.vehicleId);
            },
            child: Center(
              child: Text(
                t.inspect,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontSize: 20, color: Colors.black87),
          ),
        ],

      ),
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<VehicleInspeController>()) {
      Get.delete<VehicleInspeController>(force: true);
    }
    super.dispose();
  }
}