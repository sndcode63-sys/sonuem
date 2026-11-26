import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emtrack/services/update_vehicle_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:emtrack/utils/mesurment_helper_class.dart';
import 'package:emtrack/controllers/all_vehicles_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../services/image_upload_service.dart';
import '../utils/image_watermark_helper.dart';
import '../utils/local_image_cache.dart';
import '../models/masterDataMobileModel/tire_size_model.dart';
import '../models/masterDataMobileModel/manufacturer_model.dart';
import '../models/masterDataMobileModel/vehicle_model_item_model.dart';
import '../models/masterDataMobileModel/vehicle_type_model.dart';
import '../models/vehicle_model.dart';
import '../models/all_vehicle_account_model.dart';
import '../routes/app_pages.dart';
import '../services/master_data_service.dart';
import '../services/offline_hive_service.dart';
import '../inspection/vehicle_inspe_service.dart';
import '../inspection/vehicle_inspe_model.dart';
import '../utils/hive_prefe.dart';
import '../l10n/app_localizations.dart';
import '../utils/pending_inspection_guard.dart';

class UpdateVehicleController extends GetxController {
  final UpdateVehicleService _vehicleService = UpdateVehicleService();
  final VehicleInspeService _inspeService = VehicleInspeService();

  RxList<InstalledTire> installedTires = <InstalledTire>[].obs;
  RxBool tiresLoading = false.obs;
  RxBool isSubmitting = false.obs;
  final MasterDataService _masterService = MasterDataService();

  final RxString pressureUnit = 'PSI'.obs;
  final RxString measurementUnit = '/32nds'.obs;
  final RxString kmMilesLabel = 'KM'.obs;

  RxList<File> vehicleImages = <File>[].obs;
  RxBool isUploadingVehicleImages = false.obs;
  final ImagePicker _picker = ImagePicker();

  Future<void> loadVehicleImages(String? imagesLocation) async {
    vehicleImages.clear();
    final Set<String> seen = <String>{};
    if (imagesLocation != null && imagesLocation.trim().isNotEmpty) {
      for (final raw in imagesLocation.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty)) {
        if (!seen.contains(raw)) {
          seen.add(raw);
          final resolved = LocalImageCache.resolveSync(raw, vehicleId: vehicleId.value.toString());
          if (resolved != null && resolved.existsSync()) {
            vehicleImages.add(resolved);
          } else {
            vehicleImages.add(File(raw));
          }
          if (raw.startsWith('http')) {
            LocalImageCache.cacheNetworkImage(raw);
          }
        }
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final sp = prefs.getStringList('vehicle_images_${vehicleId.value}');
      if (sp != null) {
        for (final p in sp) {
          final clean = p.trim();
          if (clean.isNotEmpty && !seen.contains(clean)) {
            seen.add(clean);
            final resolved = LocalImageCache.resolveSync(clean, vehicleId: vehicleId.value.toString());
            if (resolved != null && resolved.existsSync()) {
              vehicleImages.add(resolved);
            } else {
              vehicleImages.add(File(clean));
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> pickVehicleImage(ImageSource source) async {
    debugPrint('\x1B[36m[VEH_IMG_TRACE] pickVehicleImage($source) START\x1B[0m');
    try {
      final picked = await _picker.pickImage(source: source);
      debugPrint('\x1B[36m[VEH_IMG_TRACE] picked=${picked?.path}\x1B[0m');
      if (picked == null) return;
      final file = File(picked.path);
      if (!file.existsSync()) return;

      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'vehicle_images', vehicleId.value.toString()));
      if (!imagesDir.existsSync()) imagesDir.createSync(recursive: true);
      final fileName = 'veh_${vehicleId.value}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final permanentFile = await file.copy(p.join(imagesDir.path, fileName));

      await ImageWatermarkHelper.stampImage(permanentFile);
      vehicleImages.add(permanentFile);
      debugPrint('\x1B[32m[VEH_IMG_TRACE] added permanentFile=${permanentFile.path} total=${vehicleImages.length}\x1B[0m');
      await _syncVehicleImagesToPrefs();
    } catch (e) {
      debugPrint('\x1B[31m[VEH_IMG_TRACE] Error picking vehicle image: $e\x1B[0m');
    }
  }

  Future<void> removeVehicleImage(int index) async {
    if (index >= 0 && index < vehicleImages.length) {
      final file = vehicleImages.removeAt(index);
      try {
        if (file.existsSync() && !file.path.startsWith('http')) {
          file.deleteSync();
        }
      } catch (_) {}
      await _syncVehicleImagesToPrefs();
    }
  }

  Future<void> _syncVehicleImagesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paths = vehicleImages.map((f) => f.path).toList();
      await prefs.setStringList('vehicle_images_${vehicleId.value}', paths);
      if (vehicleNumber.value.isNotEmpty) {
        await prefs.setStringList('vehicle_images_${vehicleNumber.value}', paths);
      }
    } catch (_) {}
  }

  String _fmtPressure(double v) {
    if (v == v.truncateToDouble()) {
      return v.truncate().toString();
    }
    return v.toString();
  }

  final manufacturerCtrl = TextEditingController();
  final typeCtrl = TextEditingController();
  final modelCtrl = TextEditingController();
  final tyreSizeCtrl = TextEditingController();
  final TextEditingController vehicleIdCtrl = TextEditingController();
  final TextEditingController vehicleNumberCtrl = TextEditingController();
  final TextEditingController removalTreadCtrl = TextEditingController();
  final TextEditingController commentsCtrl = TextEditingController();
  final TextEditingController currentHoursCtrl = TextEditingController();
  final TextEditingController currentKmCtrl = TextEditingController(text: "0");

  RxString vehicleNumber = ''.obs;
  RxString trackingMethodText = 'Hours'.obs;
  RxString removalTread = ''.obs;
  RxString currentHours = '0'.obs;
  RxString currentKm = '0'.obs;

  // Raw (server) hours/miles as loaded, kept separately from the display
  // strings above, so a Save without the person editing these fields never
  // re-derives a lossy value from the display text.
  double? _originalRawHours;
  double? _originalRawMiles;
  bool _userEditedHours = false;
  bool _userEditedKm = false;

  void onCurrentHoursChanged(String v) {
    _userEditedHours = true;
    currentHours.value = v;
  }

  void onCurrentKmChanged(String v) {
    _userEditedKm = true;
    currentKm.value = v;
  }

  RxString comments = ''.obs;

  RxString selectedManufecturer = "".obs;
  RxString selectedType = "".obs;
  RxString selectedModel = "".obs;
  RxString selectedTyreSize = "".obs;

  RxInt vehicleId = 0.obs;
  RxList<double> axlePressures = <double>[0.0, 0.0].obs;
  RxInt manufacturerId = 0.obs;
  RxInt typeId = 0.obs;
  RxInt modelId = 0.obs;
  RxInt tireSizeId = 0.obs;
  RxInt locationId = 11711.obs;

  RxString manufacturer = ''.obs;
  RxString type = ''.obs;
  RxString model = ''.obs;
  RxString tyreSize = ''.obs;

  final RxString rxAxleConfig = "22".obs;
  final RxInt rxAxleConfigId = 1.obs;

  String _loadedAxleConfig = "22";
  int _loadedAxleConfigId = 0;

  List<double> _rawPressuresPsi = [];

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

  List<Manufacturer> manufacturers = [];
  List<VehicleType> types = [];
  List<VehicleModelItem> models = [];
  List<TireSize> tireSizes = [];

  RxList<String> manufacturerList = <String>[].obs;
  RxList<String> typeList = <String>[].obs;
  RxList<String> modelList = <String>[].obs;
  RxList<String> tyreSizeList = <String>[].obs;

  bool get showPressureSection => tireSizeId.value != 0;
  int get axleCount => axlePressures.length.clamp(1, 10);
  int get installedTyreCount => axleCount * 2;
  String get axleConfigValue => rxAxleConfig.value;
  int get axleConfigIdValue => rxAxleConfigId.value;

  String get recommendedPressureString {
    if (axlePressures.isEmpty) return "0,0";
    return axlePressures
        .map((p) {
      if (p == p.truncateToDouble()) return p.truncate().toString();
      return p.toString();
    })
        .join(',');
  }

  String _cleanDecimal(dynamic value) {
    if (value == null) return '0';
    final d = double.tryParse(value.toString());
    if (d == null) return value.toString();
    return d == d.truncateToDouble() ? d.truncate().toString() : d.toString();
  }

  @override
  void onInit() {
    super.onInit();

    final int argVehicleId = Get.arguments as int;
    vehicleId.value = argVehicleId;
    vehicleIdCtrl.text = argVehicleId.toString();

    SecureStorage.getLocationId().then((locId) {
      if (locId != null && locId.isNotEmpty) {
        final parsed = int.tryParse(locId);
        if (parsed != null && parsed != 0) {
          locationId.value = parsed;
        }
      }
    });

    removalTreadCtrl.text = removalTread.value;
    ever(removalTread, (v) => removalTreadCtrl.text = v);

    commentsCtrl.text = comments.value;
    ever(comments, (v) => commentsCtrl.text = v);

    currentHoursCtrl.text = currentHours.value;
    ever(currentHours, (v) => currentHoursCtrl.text = v);

    currentKmCtrl.text = currentKm.value;
    ever(currentKm, (v) => currentKmCtrl.text = v);

    _loadPreferences();
    loadMasterData().then((_) => loadVehicleForEdit(argVehicleId));

    ever(manufacturer, (v) => manufacturerCtrl.text = v);
    ever(type, (v) => typeCtrl.text = v);
    ever(model, (v) => modelCtrl.text = v);
    ever(tyreSize, (v) => tyreSizeCtrl.text = v);
  }

  void _loadPreferences() {
    final savedPressure = HivePref.get<String>('pref_pressure');
    if (savedPressure != null && savedPressure.isNotEmpty) {
      pressureUnit.value = savedPressure.toUpperCase();
    }

    // Single source of truth for the KM/Miles label (same as Inspection).
    kmMilesLabel.value = MeasurementHelper.distanceLabel;
  }

  Future<void> loadVehicleForEdit(int vId) async {
    try {
      final vehicle = await _vehicleService.getVehicleById(vId);
      if (vehicle == null) {
        Get.snackbar('Error', 'Vehicle details not found');
        return;
      }

      vehicleId.value = vehicle.vehicleId ?? 0;
      vehicleIdCtrl.text = vehicleId.value.toString();
      manufacturerId.value = vehicle.manufacturerId ?? 0;
      typeId.value = vehicle.typeId ?? 0;
      modelId.value = vehicle.modelId ?? 0;
      tireSizeId.value = vehicle.tireSizeId ?? 0;

      vehicleNumber.value = vehicle.vehicleNumber ?? '';
      trackingMethodText.value = _trackingTextFromValue(vehicle.mileageType);
      removalTread.value = _cleanDecimal(vehicle.removalTread);
      comments.value = vehicle.severityComments ?? '';

      final double rawHours =
          double.tryParse(vehicle.currentHours?.toString() ?? '0') ?? 0.0;
      final rawMiles =
          double.tryParse(vehicle.currentMiles?.toString() ?? '0') ?? 0.0;

      // Vehicle Inspection reads lastRecordedHours/lastRecordedMiles from
      // the Inspection API, so use the same source of truth here.
      double trustedRawHours = rawHours;
      double trustedRawMiles = rawMiles;
      try {
        final inspectionResp = await _inspeService.getInspectionRecord(
          vId.toString(),
        );
        if (inspectionResp != null && inspectionResp.didError == false) {
          final m = inspectionResp.model;
          if (m?.lastRecordedHours != null) {
            trustedRawHours = m!.lastRecordedHours!;
          }
          if (m?.lastRecordedMiles != null) {
            trustedRawMiles = m!.lastRecordedMiles!;
          }
        }
      } catch (_) {
        // fall back silently to the vehicle-detail values above
      }

      currentHours.value = trustedRawHours.round().toString();
      _originalRawHours = trustedRawHours;
      _userEditedHours = false;

      // ✅ FIX: Same as Vehicle Inspection — show the raw value directly,
      // NO KM/Miles conversion. (Earlier code divided by kmPerMile when the
      // label was 'Miles', which made 100 show up as 62.)
      currentKm.value = trustedRawMiles.round().toString();
      _originalRawMiles = trustedRawMiles;
      _userEditedKm = false;

      manufacturer.value = (vehicle.manufacturer ?? '').trim().toUpperCase();
      type.value = (vehicle.typeName ?? '').trim();
      model.value = (vehicle.modelName ?? '').trim();
      tyreSize.value = (vehicle.tireSize ?? '').trim();

      if (manufacturerId.value == 0 && manufacturer.value.isNotEmpty) {
        final m = manufacturers.firstWhereOrNull(
              (e) =>
          e.manufacturerName.trim().toUpperCase() ==
              manufacturer.value.trim().toUpperCase(),
        );
        if (m != null) manufacturerId.value = m.manufacturerId;
      }

      if (manufacturerId.value != 0) {
        final mfgTypeIds = models
            .where((m) => m.vehicleManufacturerId == manufacturerId.value)
            .map((m) => m.vehicleTypeId)
            .toSet();
        typeList.value = types
            .where((t) => mfgTypeIds.contains(t.typeId))
            .map((e) => e.typeName)
            .toSet()
            .toList();
      }

      if (typeId.value == 0 && type.value.isNotEmpty) {
        final t2 = types.firstWhereOrNull(
              (e) =>
          e.typeName.trim().toLowerCase() ==
              type.value.trim().toLowerCase(),
        );
        if (t2 != null) typeId.value = t2.typeId;
      }

      if (manufacturerId.value != 0 && typeId.value != 0) {
        modelList.value = models
            .where(
              (m) =>
          m.vehicleManufacturerId == manufacturerId.value &&
              m.vehicleTypeId == typeId.value,
        )
            .map((e) => e.modelName)
            .toSet()
            .toList();
      } else if (manufacturerId.value != 0) {
        modelList.value = models
            .where((m) => m.vehicleManufacturerId == manufacturerId.value)
            .map((e) => e.modelName)
            .toSet()
            .toList();
      }

      if (modelId.value == 0 && model.value.isNotEmpty) {
        final m2 = models.firstWhereOrNull(
              (e) =>
          e.modelName.trim().toLowerCase() ==
              model.value.trim().toLowerCase(),
        );
        if (m2 != null) modelId.value = m2.modelId;
      }

      if (model.value.isNotEmpty &&
          !modelList.any(
                (e) => e.trim().toLowerCase() == model.value.trim().toLowerCase(),
          )) {
        modelList.add(model.value);
      }

      if (tireSizeId.value == 0 && tyreSize.value.isNotEmpty) {
        final ts = tireSizes.firstWhereOrNull(
              (e) =>
          e.tireSizeName.trim().toLowerCase() ==
              tyreSize.value.trim().toLowerCase(),
        );
        if (ts != null) tireSizeId.value = ts.tireSizeId;
      }

      _loadedAxleConfig = vehicle.axleConfig ?? "22";
      _loadedAxleConfigId = vehicle.axleConfigId ?? 0;
      rxAxleConfig.value = _loadedAxleConfig;
      rxAxleConfigId.value = _loadedAxleConfigId > 0 ? _loadedAxleConfigId : 1;

      final String recPressureStr = vehicle.recommendedPressure ?? "";

      if (recPressureStr.isNotEmpty) {
        final parts = recPressureStr.contains(',')
            ? recPressureStr.split(',')
            : [recPressureStr];
        axlePressures.value = parts
            .map((p) => double.tryParse(p.trim()) ?? 0.0)
            .toList();
        _rawPressuresPsi = List<double>.from(axlePressures);
      } else {
        int neededAxles = _loadedAxleConfig
            .replaceAll(RegExp(r'[^0-9]'), '')
            .length;
        axlePressures.value = List.filled(
          neededAxles > 0 ? neededAxles : 2,
          0.0,
        );
        _rawPressuresPsi = List.filled(axlePressures.length, 0.0);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        vehicleNumberCtrl.text = vehicleNumber.value;
        removalTreadCtrl.text = removalTread.value;
        currentHoursCtrl.text = currentHours.value;
        currentKmCtrl.text = currentKm.value;
        commentsCtrl.text = comments.value;
        manufacturerCtrl.text = manufacturer.value;
        typeCtrl.text = type.value;
        modelCtrl.text = model.value;
        tyreSizeCtrl.text = tyreSize.value;

        for (int i = 0; i < axlePressures.length; i++) {
          final ctrl = getPressureController(i);
          ctrl.text = _fmtPressure(axlePressures[i]);
        }

        axlePressures.refresh();
        update();
      });

      await fetchInstalledTires(vehicleId.value);
      await loadVehicleImages(vehicle.imagesLocation);
    } catch (e) {
      // Catch exceptions safely
    }
  }

  Future<void> updateForm(AppLocalizations t) async {
    if (vehicleId.value == 0) {
      return;
    }
    if (!_validateForm(t)) return;
    isSubmitting.value = true;
    final bool allowed = await PendingInspectionGuard.canProceed(
      vehicleId: vehicleId.value,
      vehicleNumber: vehicleNumber.value,
      action: PendingBlockedAction.editVehicle,
    );
    isSubmitting.value = false;
    if (!allowed) {
      return;
    }

    if (installedTires.isNotEmpty) {
      final cachedJson = OfflineHiveService.getInspectionCache(
        vehicleId.value.toString(),
      );
      if (cachedJson != null) {
        try {
          final decoded = jsonDecode(cachedJson);
          decoded['model']['installedTires'] = installedTires
              .map((e) => e.toJson())
              .toList();
          await OfflineHiveService.saveInspectionCache(
            vehicleId.value.toString(),
            jsonEncode(decoded),
          );
        } catch (_) {}
      }
    }

    final String? parentAccountId = await SecureStorage.getParentAccountId();
    final isOnline = await _isOnline();

    // Load and save both use the raw value (no unit conversion), so what
    // Vehicle Inspection shows is exactly what Edit Vehicle shows and saves.
    double parsedMiles = _originalRawMiles ?? 0.0;
    if ((trackingMethodValue == 2 || trackingMethodValue == 3) &&
        _userEditedKm) {
      parsedMiles = double.tryParse(currentKm.value) ?? 0;
    }

    final double finalHours = _userEditedHours
        ? (double.tryParse(currentHours.value) ?? 0.0)
        : (_originalRawHours ?? (double.tryParse(currentHours.value) ?? 0.0));

    // Update Vehicle never goes to the approval (Temp) API — that happens
    // only on Vehicle Inspection submit. So no "pending" entry is created here.
    isSubmitting.value = true;
    try {
      String resolvedImagesLocation = '';
      final realPhysicalFiles = vehicleImages
          .where((f) => !f.path.startsWith('http') && f.existsSync())
          .toList();
      final existingRemote = vehicleImages
          .map((f) => f.path)
          .where((p) => p.startsWith('http'))
          .toList();

      debugPrint('\x1B[33m[VEH_IMG_TRACE] submit(): isOnline=$isOnline vehicleId=${vehicleId.value} vehicleImages=${vehicleImages.length} realPhysical=${realPhysicalFiles.length} existingRemote=${existingRemote.length}\x1B[0m');

      if (realPhysicalFiles.isNotEmpty && isOnline) {
        final up = await ImageUploadService.uploadVehicleImagesKeepingExisting(
          vehicleId: vehicleId.value,
          newImages: realPhysicalFiles,
          existingUrls: existingRemote,
        );
        debugPrint('\x1B[32m[VEH_IMG_TRACE] uploadVehicleImagesKeepingExisting -> success=${up.success} error=${up.error} urls=${up.urls}\x1B[0m');
        if (up.success && up.urls.isNotEmpty) {
          resolvedImagesLocation = up.urls.toSet().join(',');
        } else {
          resolvedImagesLocation = <String>{
            ...existingRemote,
            ...realPhysicalFiles.map((f) => f.path),
          }.join(',');
        }
      } else {
        // Offline: keep existing remote URLs + local file paths (deduplicated) so sync uploads them later.
        resolvedImagesLocation = <String>{
          ...existingRemote,
          ...realPhysicalFiles.map((f) => f.path),
        }.join(',');
      }
      debugPrint('\x1B[35m[VEH_IMG_TRACE] resolvedImagesLocation="$resolvedImagesLocation"\x1B[0m');

      final vehicle = VehicleModel(
        vehicleId: vehicleId.value,
        locationId: locationId.value,
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
        installedTireCount: installedTires.length,
        currentMiles: parsedMiles,
        currentHours: finalHours.roundToDouble(),
        severityComments: comments.value,
        recommendedPressure: recommendedPressureString,
        updatedDate: DateTime.now(),
        lastUpdatedDate: DateTime.now(),
        imagesLocation: resolvedImagesLocation.isNotEmpty ? resolvedImagesLocation : null,
      );
      if (isOnline) {
        final success = await _vehicleService.updateVehicle(vehicle);
        if (!success) {
          return;
        }
      } else {
        await _vehicleService.updateVehicle(vehicle);
      }

      final distUnit = kmMilesLabel.value;
      HivePref.set('vehicle_dist_unit_${vehicle.vehicleNumber}', distUnit);
      if (vehicle.vehicleId != null) {
        HivePref.set('vehicle_dist_unit_${vehicle.vehicleId}', distUnit);
      }

      if (Get.isRegistered<AllVehicleController>()) {
        final allVehicleCtrl = Get.find<AllVehicleController>();
        final vId = vehicle.vehicleId;
        if (vId != null) {
          final idx = allVehicleCtrl.vehicleList.indexWhere(
                (v) => v.vehicleId == vId,
          );
          if (idx != -1) {
            final old = allVehicleCtrl.vehicleList[idx];
            final patched = AccountVehicleModel(
              vehicleId: vId,
              vehicleNumber: vehicle.vehicleNumber,
              typeName: vehicle.typeName,
              modelName: vehicle.modelName,
              axleConfig: vehicle.axleConfig,
              manufacturerName: vehicle.manufacturer,
              tireCount: old.tireCount,
              locationId: vehicle.locationId,
              assetNumber: old.assetNumber,
              currentHours: vehicle.currentHours,
              currentMiles: vehicle.currentMiles,
              lastRead: old.lastRead,
              isPendingSync: !isOnline,
            );
            allVehicleCtrl.vehicleList[idx] = patched;
            allVehicleCtrl.vehicleList.refresh();

            final fidx = allVehicleCtrl.filteredList.indexWhere(
                  (v) => v.vehicleId == vId,
            );
            if (fidx != -1) {
              allVehicleCtrl.filteredList[fidx] = patched;
              allVehicleCtrl.filteredList.refresh();
            }
          }
        }
        allVehicleCtrl.refreshVehicles();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('vehicle_comment_${vehicleId.value}');
      resetForm();

      Get.offAllNamed(
        AppPages.HOME,
        arguments: {
          "showSuccess": true,
          "module": "vehicle",
          "type": "update",
          "savedOffline": !isOnline,
          "vehicleNo": vehicle.vehicleNumber,
          "vehicleId": vehicle.vehicleId,
        },
      );
    } catch (_) {
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> fetchInstalledTires(int vId) async {
    tiresLoading.value = true;
    try {
      final results = await Connectivity().checkConnectivity();
      final isOnline = results.any((r) => r != ConnectivityResult.none);

      if (isOnline) {
        final response = await _inspeService.getInspectionRecord(
          vId.toString(),
        );
        if (response != null && response.didError == false) {
          installedTires.assignAll(response.model?.installedTires ?? []);
        }
      } else {
        final cachedJson = OfflineHiveService.getInspectionCache(
          vId.toString(),
        );
        if (cachedJson != null) {
          final decoded = jsonDecode(cachedJson);
          final modelData = decoded['model'];
          if (modelData != null && modelData['installedTires'] != null) {
            final List<dynamic> tiresJson = modelData['installedTires'];
            final List<InstalledTire> offlineTires = tiresJson
                .map((t) => InstalledTire.fromJson(t as Map<String, dynamic>))
                .toList();
            installedTires.assignAll(offlineTires);
          }
        } else {
          installedTires.clear();
        }
      }
    } catch (_) {
    } finally {
      tiresLoading.value = false;
      update();
    }
  }

  String _trackingTextFromValue(int? value) {
    switch (value) {
      case 1:
        return 'Hours';
      case 2:
        return 'Distance';
      case 3:
        return 'Both';
      default:
      // Backend sometimes sends mileageType null/empty; default to 'Both'
      // so both fields are visible and the user can correct and save.
        return 'Both';
    }
  }

  Future<void> loadMasterData() async {
    final data = await _masterService.fetchMasterData();

    manufacturers = (data['vehicleManufacturers'] as List)
        .map((e) => Manufacturer.fromJson(e))
        .toList();
    types = (data['vehicleTypes'] as List)
        .map((e) => VehicleType.fromJson(e))
        .toList();
    models = (data['vehicleModels'] as List)
        .map((e) => VehicleModelItem.fromJson(e))
        .toList();
    tireSizes = (data['tireSizes'] as List)
        .map((e) => TireSize.fromJson(e))
        .where((t) => t.tireSizeName.trim().isNotEmpty)
        .toList();

    manufacturerList.value = manufacturers
        .map((e) => e.manufacturerName.toUpperCase())
        .toSet()
        .toList();
    tyreSizeList.value = tireSizes.map((e) => e.tireSizeName).toSet().toList();
    typeList.clear();
    modelList.clear();
  }

  void selectManufacturer(String value) {
    manufacturer.value = value;
    final m = manufacturers.firstWhere(
          (e) => e.manufacturerName.toUpperCase() == value.toUpperCase(),
      orElse: () => manufacturers.first,
    );
    manufacturerId.value = m.manufacturerId;

    final mfgTypeIds = models
        .where((m) => m.vehicleManufacturerId == manufacturerId.value)
        .map((m) => m.vehicleTypeId)
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
      typeId.value = 0;
      modelList.clear();
      model.value = '';
      modelId.value = 0;
      modelCtrl.clear();
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
  }

  String _getTypeNameById(int typeId) {
    final found = types.firstWhereOrNull((t) => t.typeId == typeId);
    return found?.typeName ?? '';
  }

  void selectModel(String value) {
    model.value = value;
    final matched = models.where((e) => e.modelName == value).toList();
    if (matched.isEmpty) {
      modelId.value = 0;
      return;
    }
    modelId.value = matched.first.modelId;
    _refreshAxleFromModel(matched.first);
  }

  Future<void> _refreshAxleFromModel(VehicleModelItem selectedModel) async {
    try {
      if (vehicleId.value != 0) {
        await fetchInstalledTires(vehicleId.value);
      }
      for (int i = 0; i < axlePressures.length; i++) {
        final ctrl = getPressureController(i);
        ctrl.text = _fmtPressure(axlePressures[i]);
      }
      update();
    } catch (_) {}
  }

  void selectTyreSize(String value) {
    tyreSize.value = value;
    final matched = tireSizes.where((e) => e.tireSizeName == value).toList();
    if (matched.isEmpty) {
      tireSizeId.value = 0;
      return;
    }
    tireSizeId.value = matched.first.tireSizeId;
  }

  final List<TextEditingController> _pressureControllers = [];

  TextEditingController getPressureController(int index) {
    while (_pressureControllers.length <= index) {
      _pressureControllers.add(TextEditingController(text: '0'));
    }
    return _pressureControllers[index];
  }

  void setPressure(int index, double value) {
    if (index < axlePressures.length) {
      final v = value < 0 ? 0.0 : value;
      axlePressures[index] = v;
      axlePressures.refresh();

      while (_rawPressuresPsi.length <= index) {
        _rawPressuresPsi.add(0.0);
      }
      _rawPressuresPsi[index] = v;

      final ctrl = getPressureController(index);

      String newText = _fmtPressure(v);

      if (ctrl.text != newText) {
        ctrl.text = newText;
        ctrl.selection = TextSelection.collapsed(offset: newText.length);
      }
    }
  }

  void incrementPressure(int index) {
    if (index < axlePressures.length) {
      // +1 step, no unit conversion
      axlePressures[index] = axlePressures[index] + 1.0;
      axlePressures.refresh();

      while (_rawPressuresPsi.length <= index) {
        _rawPressuresPsi.add(0.0);
      }
      _rawPressuresPsi[index] = axlePressures[index];

      final ctrl = getPressureController(index);
      ctrl.text = _fmtPressure(axlePressures[index]);
      ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
    }
  }

  void decrementPressure(int index) {
    if (index < axlePressures.length && axlePressures[index] > 0) {
      double output = axlePressures[index] - 1.0;
      axlePressures[index] = output < 0 ? 0.0 : output;
      axlePressures.refresh();

      while (_rawPressuresPsi.length <= index) {
        _rawPressuresPsi.add(0.0);
      }
      _rawPressuresPsi[index] = axlePressures[index];

      final ctrl = getPressureController(index);
      ctrl.text = _fmtPressure(axlePressures[index]);
      ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
    }
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

  bool _validateForm(AppLocalizations t) {
    _clearErrors();
    bool isValid = true;

    if (vehicleNumber.value.trim().isEmpty) {
      vehicleNumberError.value = t.requiredField;
      isValid = false;
    }
    if (trackingMethodText.value.trim().isEmpty) {
      trackingMethodError.value = t.requiredField;
      isValid = false;
    }
    if (trackingMethodValue == 1 || trackingMethodValue == 3) {
      if (currentHours.value.trim().isEmpty) {
        currentHoursError.value = t.currentHoursRequired;
        isValid = false;
      } else if (double.tryParse(currentHours.value) == null) {
        currentHoursError.value = t.numericOnly;
        isValid = false;
      }
    }
    if (trackingMethodValue == 2 || trackingMethodValue == 3) {
      if (currentKm.value.trim().isEmpty) {
        currentKmError.value = t.currentKmRequired;
        isValid = false;
      } else if (double.tryParse(currentKm.value) == null) {
        currentKmError.value = t.numericOnly;
        isValid = false;
      }
    }
    if (manufacturer.value.isEmpty || manufacturerId.value == 0) {
      manufacturerError.value = t.requiredField;
      isValid = false;
    }
    if (type.value.isEmpty || typeId.value == 0) {
      typeError.value = t.requiredField;
      isValid = false;
    }
    if (model.value.isEmpty || modelId.value == 0) {
      modelError.value = t.requiredField;
      isValid = false;
    }
    if (tyreSize.value.isEmpty || tireSizeId.value == 0) {
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
    axlePressures.value = [0.0, 0.0];
    _rawPressuresPsi = [];
    _loadedAxleConfig = "22";
    _loadedAxleConfigId = 0;
    rxAxleConfig.value = "22";
    rxAxleConfigId.value = 1;
    installedTires.clear();
    currentHoursCtrl.clear();
    currentKmCtrl.clear();
    for (final ctrl in _pressureControllers) {
      ctrl.text = '0';
    }
  }

  static Future<bool> _isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  final FocusNode vehicleNumNode = FocusNode();
  final FocusNode manufNode = FocusNode();
  final FocusNode typeNode = FocusNode();
  final FocusNode modelNode = FocusNode();
  final FocusNode sizeNode = FocusNode();

  @override
  void onClose() {
    vehicleIdCtrl.dispose();
    manufacturerCtrl.dispose();
    typeCtrl.dispose();
    modelCtrl.dispose();
    tyreSizeCtrl.dispose();
    vehicleNumberCtrl.dispose();
    removalTreadCtrl.dispose();
    commentsCtrl.dispose();
    currentHoursCtrl.dispose();
    currentKmCtrl.dispose();

    vehicleNumNode.dispose();
    manufNode.dispose();
    typeNode.dispose();
    modelNode.dispose();
    sizeNode.dispose();
    for (final ctrl in _pressureControllers) {
      ctrl.dispose();
    }
    super.onClose();
  }
}