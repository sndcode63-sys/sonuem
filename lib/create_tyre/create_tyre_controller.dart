import 'dart:async';
import 'dart:convert';
import 'package:emtrack/create_tyre/app_loader.dart';
import 'package:emtrack/create_tyre/create_tyre_model.dart';
import 'package:emtrack/create_tyre/create_tyre_service.dart';
import 'package:emtrack/models/view_tyre_response.dart' as viewtyre;
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/services/master_data_service.dart';
import 'package:emtrack/controllers/home_controller.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:emtrack/services/change_account_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/preferences_controller.dart';
import '../models/tyre_model.dart';
import '../routes/app_pages.dart';
import '../services/tyre_service.dart';
import '../utils/app_dialog.dart';
import '../controllers/all_tyre_controller.dart';
import '../utils/app_snackbar.dart';
import '../utils/local_helper.dart';
import '../utils/mesurment_helper_class.dart';
import '../utils/network_helper.dart';
import '../utils/tyre_unit_history.dart';
import '../utils/pending_inspection_guard.dart';

class CreateTyreController extends GetxController {

  final RxInt currentStep = 0.obs;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final RxBool isSubmitting = false.obs;
  final MasterDataService _masterService = MasterDataService();
  final ScrollController pageScrollController = ScrollController();
  RxString tireSerialNoError = ''.obs;

  final Map<String, int> manufacturerMap = {};
  RxString get measurementUnit {
    final pref = Get.find<PreferencesController>();
    return (pref.selectedMeasurement.value == "Imperial" ? "/32" : "mm").obs;
  }

  final distLabel = MeasurementHelper.distanceLabel;


  final statusIdList = <int>[].obs;
  final manufacturerIdList = <int>[].obs;
  final tireSizeIdList = <int>[].obs;
  final typeIdList = <int>[].obs;
  final indCodeIdList = <int>[].obs;
  final compoundIdList = <int>[].obs;
  final loadRatingIdList = <int>[].obs;
  final speedRatingIdList = <int>[].obs;
  final fillTypeIdList = <int>[].obs;

  final middleTread = TextEditingController(text: "0");

  final RxInt noOfTreadDepthReadings = 3.obs;

  final RxInt selectedStatusId = 0.obs;
  final RxInt selectedManufacturerId = 0.obs;
  final RxInt selectedSizeId = 0.obs;
  final RxInt selectedTypeId = 0.obs;
  final RxInt selectedIndCodeId = 0.obs;
  final RxInt selectedCompoundId = 0.obs;
  final RxInt selectedLoadRatingId = 0.obs;
  final RxInt selectedSpeedRatingId = 0.obs;
  final RxInt selectedFillTypeId = 0.obs;

  final tireStatusId = TextEditingController();

  // STEP 1
  final statusList = <String>[].obs;
  String? registeredDateApi;
  RxString selectedstatus = "".obs;
  RxString selectedTrackingMethod = "Hours".obs;

  // STEP 2
  final manufacturerList = <String>[].obs;
  final tireSizeList = <String>[].obs;
  final typeList = <String>[].obs;
  final indCodeList = <String>[].obs;
  final compoundList = <String>[].obs;
  final loadRatingList = <String>[].obs;
  final speedRatingList = <String>[].obs;

  List allTireSizes = [];
  List allTypeList = [];
  final isPageLoading = true.obs;

  // STEP 4
  final fillTypeList = <String>[].obs;

  String formatNum(num? v) {
    if (v == null) return "0";
    return v % 1 == 0 ? v.toInt().toString() : v.toString();
  }

  void setStatusList(List<String> list) {
    statusList.assignAll(list);
    if (statusList.isNotEmpty) {
      selectedstatus.value = statusList.last;
    }
  }

  void nextStep() {
    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (currentStep.value == 0 && tireSerialNoError.value.isNotEmpty) return;

    if (currentStep.value < 3) currentStep.value++;
  }
  void previousStep() {
    if (currentStep.value > 0) currentStep.value--;
  }

  final CreateTyreModel model = CreateTyreModel();

  // ================= STEP 1 =================
  final tireSerialNo = TextEditingController();
  final brandNo = TextEditingController();
  final registeredDate = TextEditingController();
  final evaluationNo = TextEditingController();
  final lotNo = TextEditingController();
  final poNo = TextEditingController();
  final dispositionText = "Inventory".obs;
  final trackingMethodText = "Hours".obs;
  final currentHours = TextEditingController();
  // Current KM field
  final currentKm = TextEditingController();

  // ================= STEP 2 =================
  final RxInt starRating = 0.obs;
  final manufacturerId = TextEditingController();
  final sizeId = TextEditingController();
  final starRatingId = TextEditingController();
  final typeId = TextEditingController();
  final indCodeId = TextEditingController();
  final compoundId = TextEditingController();
  final loadRatingId = TextEditingController();
  final speedRatingId = TextEditingController();

  // ================= STEP 3 =================
  final originalTread = TextEditingController();
  final removeAt = TextEditingController(text: "0");
  final purchasedTread = TextEditingController();
  final outsideTread = TextEditingController(text: "0");
  final insideTread = TextEditingController(text: "0");

  // ================= STEP 4 =================
  final purchaseCost = TextEditingController(text: "0");
  final casingValue = TextEditingController(text: "0");
  final fillTypeId = TextEditingController();
  final fillCost = TextEditingController(text: "0");
  final repairCost = TextEditingController(text: "0");
  final retreadCost = TextEditingController(text: "0");
  final numberOfRetreadsVal = 0.obs;
  final warrantyAdjustment = TextEditingController(text: "0");
  final costAdjustment = TextEditingController(text: "0");
  final soldAmount = TextEditingController(text: "0");
  final netCost = TextEditingController(text: "0");
  int? tireId;

  final RxBool isStarEnabled = false.obs;
  final RxBool autoValidateFields = false.obs;


  final RxBool showStarRating = true.obs;
  final RxString ratingLabel = "Star Rating".obs;

  // Ply Rating dropdown
  final plyRatingList = <String>[].obs;
  final plyRatingIdList = <int>[].obs;
  final RxInt selectedPlyRatingId = 0.obs;
  final plyRatingId = TextEditingController();

  void checkStarEnable() {
    isStarEnabled.value =
        manufacturerId.text.trim().isNotEmpty &&
            sizeId.text.trim().isNotEmpty &&
            selectedSizeId.value > 0;
    update();
  }

  @override
  void onInit() {
    super.onInit();
    _initScreen();
  }

  Future<void> _initScreen() async {
    try {
      isPageLoading.value = true;
      await loadMasterData();
      noOfTreadDepthReadings.value = SecureStorage.getNoOfTreadDepthReadings();
      try {
        final locationIdStr = await SecureStorage.getLocationId();
        final locationId = int.tryParse(locationIdStr ?? '');
        if (locationId != null && locationId > 0) {
          final fresh = await ChangeAccountService()
              .fetchAndSaveNoOfTreadDepthReadings(locationId);
          noOfTreadDepthReadings.value = fresh;
        }
      } catch (_) {
      }

      final arg = Get.arguments;

      if (arg is Map) {
        final id = arg['tireId'];
        final cloneModel = arg['cloneModel'];

        if (cloneModel != null || (id != null && id is int)) {
          final int? cId = id is int ? id : (cloneModel is TyreModel ? cloneModel.tireId : null);
          final String? sn = cloneModel is TyreModel ? cloneModel.tireSerialNo : null;
          if (cId != null && cId > 0) {
            final allowed = await PendingInspectionGuard.canProceedForTire(
              tireId: cId,
              tireSerialNo: sn,
              action: PendingBlockedAction.cloneTyre,
            );
            if (!allowed) {
              Get.back();
              return;
            }
          }
        }

        if (id is int && id < 0 && cloneModel != null) {

          final hiveModel = OfflineHiveService.getTyreById(id);
          if (hiveModel != null) {
            final fullModel = TyreModel(
              tireId: hiveModel.tireId,
              tireSerialNo: hiveModel.serialNumber,
              brandNo: hiveModel.brandNo,
              sizeName: hiveModel.tireSizeName,
              sizeId: hiveModel.tireSizeId,
              typeName: hiveModel.tireTypeName ?? hiveModel.typeName,
              typeId: hiveModel.tireTypeId,
              tireStatusName:
              hiveModel.tireStatusName ?? hiveModel.dispositionName,
              manufacturerName: hiveModel.manufacturerName,
              manufacturerId: hiveModel.manufacturerId,
              dispositionId: hiveModel.dispositionId,
              dispositionName: hiveModel.dispositionName,
              outsideTread: hiveModel.outsideTread,
              insideTread: hiveModel.insideTread,
              currentTreadDepth: hiveModel.currentTreadDepth,
              currentPressure: hiveModel.currentPressure,
              originalTread: hiveModel.originalTread,
              purchasedTread: hiveModel.purchasedTread,
              removeAt: hiveModel.removeAt,
              currentHours: hiveModel.currentHours,
              currentMiles: hiveModel.currentMiles,
              mileageType: hiveModel.mileageType,
              starRatingId: hiveModel.starRatingId,
              plyId: hiveModel.plyId,
              middleTread: hiveModel.middleTread,
              compoundId: hiveModel.compoundId,
              loadRatingId: hiveModel.loadRatingId,
              speedRatingId: hiveModel.speedRatingId,
              fillTypeId: hiveModel.fillTypeId,
              purchaseCost: hiveModel.purchaseCost,
              casingValue: hiveModel.casingValue,
              fillCost: hiveModel.fillCost,
              repairCost: hiveModel.repairCost,
              retreadCost: hiveModel.retreadCost,
              costAdjustment: hiveModel.costAdjustment,
              warrantyAdjustment: hiveModel.warrantyAdjustment,
              soldAmount: hiveModel.soldAmount,
              netCost: hiveModel.netCost,
              evaluationNo: hiveModel.evaluationNo,
              lotNo: hiveModel.lotNo,
              poNo: hiveModel.poNo,
              indCodeId: hiveModel.indCodeId,
              inspectionDate: null,
            );
            await _assignCloneFromTyreModel(fullModel);
          } else {
            await _assignCloneFromTyreModel(cloneModel);
          }
          _setDefaultsAfterClone();
        } else if (id is int && id > 0) {
          tireId = id;
          final online = await NetworkHelper.hasInternet();

          if (online) {
            await loadTyreForClone(tireId!);
          } else {
            final detailJson = OfflineHiveService.getTireDetailCache(id);
            if (detailJson != null) {
              try {

                final jsonMap = jsonDecode(detailJson);
                final model = jsonMap['model'] as Map<String, dynamic>;
                final vm = viewtyre.ViewModel.fromJson(model);
                await _assignCloneData(vm);
              } catch (e) {

                if (cloneModel != null) {
                  await _assignCloneFromTyreModel(cloneModel);
                } else {
                  _setDefaultValues();
                }
              }
            } else if (cloneModel != null) {

              await _assignCloneFromTyreModel(cloneModel);
            } else {
              _setDefaultValues();
            }
          }
          _setDefaultsAfterClone();
        } else {
          _setDefaultValues();
        }
      } else if (arg is int && arg > 0) {
        tireId = arg;
        final online = await NetworkHelper.hasInternet();

        if (online) {
          await loadTyreForClone(tireId!);
        } else {
          final detailJson = OfflineHiveService.getTireDetailCache(arg);
          if (detailJson != null) {
            try {
              final jsonMap = jsonDecode(detailJson);
              final model = jsonMap['model'] as Map<String, dynamic>;
              await _assignCloneData(viewtyre.ViewModel.fromJson(model));
            } catch (e) {
              _setDefaultValues();
            }
          } else {
            _setDefaultValues();
          }
        }
        _setDefaultsAfterClone();
      } else {
        _setDefaultValues();
      }
    } catch (e) {
      _setDefaultValues();
    } finally {
      isPageLoading.value = false;
    }
  }

  void _setDefaultValues() {
    manufacturerId.addListener(checkStarEnable);
    sizeId.addListener(checkStarEnable);

    final now = DateTime.now();
    registeredDate.text = LocaleHelper.formatDate(now);
    registeredDateApi =
    "${now.year}-${now.month.toString().padLeft(2, '0')}"
        "-${now.day.toString().padLeft(2, '0')}T00:00:00";

    model.dispositionId = 8;
    dispositionText.value = "Inventory";
    model.tireStatusId = 7;
    model.trackingMethod = "Hours";
    trackingMethodText.value = "Hours";
    selectedTrackingMethod.value = "Hours";
    model.mountStatus = "Not Mounted";
    model.isMountToRim = false;
    model.numberOfRetreads = 0;
    numberOfRetreadsVal.value = 0;
    currentHours.text = "0";
    currentKm.text = "0";
  }

  void _setDefaultsAfterClone() {
    manufacturerId.addListener(checkStarEnable);
    sizeId.addListener(checkStarEnable);

    model.dispositionId = 8;
    dispositionText.value = "Inventory";
    model.mountStatus = "Not Mounted";
    model.isMountToRim = false;
    model.numberOfRetreads = 0;
    numberOfRetreadsVal.value = 0;

    if (currentHours.text.isEmpty) currentHours.text = "0";
    if (currentKm.text.isEmpty) currentKm.text = "0";

    if (removeAt.text.isEmpty || removeAt.text == "0") {
      final locDefault = SecureStorage.getDefaultRemovalTreadDepth();
      if (locDefault > 0) {
        removeAt.text = locDefault == locDefault.truncateToDouble()
            ? locDefault.toInt().toString()
            : locDefault.toString();
      } else {
        removeAt.text = "0";
      }
    }

    if (registeredDate.text.isEmpty) {
      final now = DateTime.now();
      registeredDate.text =
      "${now.day.toString().padLeft(2, '0')}/"
          "${now.month.toString().padLeft(2, '0')}/"
          "${now.year}";
      registeredDateApi =
      "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}T00:00:00";
    }
    if (trackingMethodText.value.isEmpty) trackingMethodText.value = "Hours";
  }

  void calculateNetCost() {
    double a = double.tryParse(purchaseCost.text) ?? 0;
    double b = double.tryParse(casingValue.text) ?? 0;
    double c = double.tryParse(fillCost.text) ?? 0;
    double d = double.tryParse(repairCost.text) ?? 0;
    double e = double.tryParse(retreadCost.text) ?? 0;
    double f =
        double.tryParse(warrantyAdjustment.text) ?? 0;
    double g = double.tryParse(costAdjustment.text) ?? 0;
    double h = double.tryParse(soldAmount.text) ?? 0;


    double totalAdded = a + d + c + e;
    double totalSubtracted = b + g + h + f;

    double result = totalAdded - totalSubtracted;

    // UI Update
    netCost.text = formatNum(result);
  }

  Future<void> bindToModel() async {
    // Basic Info
    model.tireStatusId = selectedStatusId.value > 0 ? selectedStatusId.value : 7;
    model.tireSerialNo = tireSerialNo.text.trim();
    model.brandNo = brandNo.text.trim().isEmpty ? null : brandNo.text.trim();
    model.registeredDate = registeredDateApi != null ? DateTime.parse(registeredDateApi!) : DateTime.now();
    model.evaluationNo = evaluationNo.text.trim().isEmpty ? null : evaluationNo.text.trim();
    model.lotNo = lotNo.text.trim().isEmpty ? null : lotNo.text.trim();
    model.poNo = poNo.text.trim().isEmpty ? null : poNo.text.trim();

    // 2. Tracking Method & Values
    final method = selectedTrackingMethod.value;
    if (method == "Hours") {
      model.currentHours = double.tryParse(currentHours.text) ?? 0;
      model.currentMiles = 0;
      model.mileageType = "1";
    } else if (method == "Distance") {
      model.currentHours = 0;
      model.currentMiles = double.tryParse(currentKm.text) ?? 0;
      model.mileageType = "2";
    } else {
      model.currentHours = double.tryParse(currentHours.text) ?? 0;
      model.currentMiles = double.tryParse(currentKm.text) ?? 0;
      model.mileageType = "3";
    }

    // 3. Master Data IDs
    model.manufacturerId = selectedManufacturerId.value;
    model.sizeId = selectedSizeId.value;
    model.starRatingId = showStarRating.value ? starRating.value : 0;
    model.plyId = showStarRating.value ? 1123 : (selectedPlyRatingId.value > 0 ? selectedPlyRatingId.value : 1123);
    model.typeId = selectedTypeId.value;
    model.indCodeId = selectedIndCodeId.value;
    model.compoundId = selectedCompoundId.value;
    model.loadRatingId = selectedLoadRatingId.value;
    model.speedRatingId = selectedSpeedRatingId.value;
    model.fillTypeId = selectedFillTypeId.value;

    // 4. TREAD DATA (FORCE CAPTURE ALL 6 FIELDS)
    final double original = double.tryParse(originalTread.text) ?? 0;
    final double purchased = double.tryParse(purchasedTread.text) ?? 0;
    final double rAt = double.tryParse(removeAt.text) ?? 0;
    final double outside = double.tryParse(outsideTread.text) ?? 0;
    final double middle = double.tryParse(middleTread.text) ?? 0;
    final double inside = double.tryParse(insideTread.text) ?? 0;

    model.originalTread = original;
    model.purchasedTread = purchased;
    model.removeAt = rAt;

    // 5. % WORN & AVERAGE
    final int treadCount = noOfTreadDepthReadings.value;
    double avgTread;
    if (treadCount == 1) {

      model.outsideTread = outside;
      model.middleTread  = 0;
      model.insideTread  = 0;
      avgTread = outside;
    } else if (treadCount == 2) {

      model.outsideTread = outside;
      model.middleTread  = 0;
      model.insideTread  = inside;
      avgTread = (outside + inside) / 2;
    } else {
      model.outsideTread = outside;
      model.middleTread  = middle;
      model.insideTread  = inside;
      avgTread = (outside + middle + inside) / 3;
    }

    final double denom = (original - rAt);
    double percent = 0;
    if (denom > 0 && avgTread > 0) {
      if (avgTread >= original) {
        percent = 0;
      } else {
        percent = (1 - (avgTread - rAt) / denom) * 100;
      }
    } else {
      percent = 0;
    }

    model.averageTreadDepth = avgTread;
    model.currentTreadDepth = avgTread;
    model.percentageWorn = percent.clamp(0, 100);

    // 6. Costs & Storage
    model.purchaseCost = double.tryParse(purchaseCost.text) ?? 0;
    model.casingValue = double.tryParse(casingValue.text) ?? 0;
    model.fillCost = double.tryParse(fillCost.text) ?? 0;
    model.repairCost = double.tryParse(repairCost.text) ?? 0;
    model.retreadCost = double.tryParse(retreadCost.text) ?? 0;
    model.warrantyAdjustment = double.tryParse(warrantyAdjustment.text) ?? 0;
    model.costAdjustment = double.tryParse(costAdjustment.text) ?? 0;
    model.soldAmount = double.tryParse(soldAmount.text) ?? 0;
    model.netCost = double.tryParse(netCost.text) ?? 0;

    final parentId = await SecureStorage.getParentAccountId();
    model.parentAccountId = int.tryParse(parentId ?? "0") ?? 0;
    final storedLocation = await SecureStorage.getLocationId();
    model.locationId = int.tryParse(storedLocation ?? "0") ?? 0;
    model.createdBy = await SecureStorage.getUserName() ?? "User";
  }

  Future<void> submitTyre() async {
    if (isSubmitting.value) return;
    if (!formKey.currentState!.validate()) return;

    try {
      isSubmitting.value = true;
      AppLoader.show();
      final String? parentAccountId = await SecureStorage.getParentAccountId();
      if (parentAccountId == null || parentAccountId.isEmpty) {
        AppLoader.hide();
        Get.snackbar("Error", "PARENT Account not selected.");
        return;
      }

      await bindToModel();
      model.parentAccountId = int.parse(parentAccountId);
      final String serial = tireSerialNo.text.trim();

      TyreUnitHistory.recordRawReadings(
        tireId: serial,
        outside: model.outsideTread,
        middle: model.middleTread,
        inside: model.insideTread,
        miles: model.currentMiles,
        percentageWorn: model.percentageWorn,
        treadUnit: MeasurementHelper.isMetric ? 'Metric' : 'Imperial',
        distanceUnit: distLabel,
      );

      final ctx = Get.context;
      AppLoader.hide();

      final bool savedOnline = await CreateTyreService.saveTyre(
        model,
        manufacturerName: manufacturerId.text.trim().isNotEmpty ? manufacturerId.text.trim() : null,
        tireSizeName: sizeId.text.trim().isNotEmpty ? sizeId.text.trim() : null,
        tireStatusName: selectedstatus.value.isNotEmpty ? selectedstatus.value : null,
        tireTypeName: typeId.text.trim().isNotEmpty ? typeId.text.trim() : null,
      );

      final cachedTyre = SecureStorage.getLastTyreCount() ?? 0;
      final cachedVehicle = SecureStorage.getLastVehicleCount() ?? 0;
      if (savedOnline) {
        // Online save
        await SecureStorage.saveDashboardCounts(
          vehicleCount: cachedVehicle,
          tyreCount: cachedTyre + 1,
        );
      }

      // Snackbar
      if (ctx != null) {
        final tyreName = LocaleHelper.tyreName(ctx);
        if (savedOnline) {
          AppSnackbar.success(
            "$tyreName with serial no: $serial created successfully.",
            title: "New $tyreName Created Successfully",
          );
        } else {
          AppSnackbar.offlineSuccess(
            "$tyreName with serial no: $serial created successfully.",

            title: "New $tyreName created successfully.",
          );
        }
      }

      Get.offAllNamed(AppPages.HOME, arguments: {"refreshOnly": true});

      unawaited(_postSaveRefresh());
    } catch (e) {
      AppLoader.hide();
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> _postSaveRefresh() async {
    try {
      if (Get.isRegistered<AllTyreController>()) {
        await Get.find<AllTyreController>().refresh();
      }
    } catch (_) {
    }
  }

  Future<void> finishSaveAndNotify(String serial, String parentAccountId) async {
    try {
      final bool savedOnline = await CreateTyreService.saveTyre(
        model,
        manufacturerName: manufacturerId.text.trim().isNotEmpty ? manufacturerId.text.trim() : null,
        tireSizeName: sizeId.text.trim().isNotEmpty ? sizeId.text.trim() : null,
        tireStatusName: selectedstatus.value.isNotEmpty ? selectedstatus.value : null,
        tireTypeName: typeId.text.trim().isNotEmpty ? typeId.text.trim() : null,
      );

      if (!savedOnline) {
        final ctx = Get.context;
        if (ctx != null) {
          final tyreName = LocaleHelper.tyreName(ctx);
          AppSnackbar.offlineSuccess(
            "$tyreName with serial no: $serial created successfully.",
            title: "$tyreName cloned successfully.",
          );
        }
      }

      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().incrementTyreCount();
      }
      if (Get.isRegistered<AllTyreController>()) {
        unawaited(Get.find<AllTyreController>().refresh());
      }
    } catch (_) {
    }
  }

  Future<void> saveAndClone() async {
    if (isSubmitting.value) return;
    if (!formKey.currentState!.validate()) return;

    try {
      isSubmitting.value = true;
      AppLoader.show();
      final String? parentAccountId = await SecureStorage.getParentAccountId();
      if (parentAccountId == null || parentAccountId.isEmpty) {
        AppLoader.hide();
        Get.snackbar("Error", "PARENT Account not selected.");
        return;
      }

      await bindToModel();
      model.parentAccountId = int.parse(parentAccountId);
      final String serial = tireSerialNo.text.trim();

      TyreUnitHistory.recordRawReadings(
        tireId: serial,
        outside: model.outsideTread,
        middle: model.middleTread,
        inside: model.insideTread,
        miles: model.currentMiles,
        percentageWorn: model.percentageWorn,
        treadUnit: MeasurementHelper.isMetric ? 'Metric' : 'Imperial',
        distanceUnit: distLabel,
      );

      AppLoader.hide();

      tireSerialNo.clear();
      brandNo.clear();
      autoValidateFields.value = true;
      tireSerialNoError.value = 'Tire serial number is required.';
      currentStep.value = 0;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pageScrollController.hasClients) {
          pageScrollController.animateTo(0,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut);
        }
      });

      unawaited(_finishCloneNotify(serial, parentAccountId));
    } catch (e) {
      AppLoader.hide();
      Get.snackbar("Error", e.toString(),
          backgroundColor: Colors.red.withAlpha(204),
          colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }
  Future<void> _finishCloneNotify(String serial, String parentAccountId) async {
    try {
      final bool savedOnline = await CreateTyreService.saveTyre(
        model,
        manufacturerName: manufacturerId.text.trim().isNotEmpty ? manufacturerId.text.trim() : null,
        tireSizeName: sizeId.text.trim().isNotEmpty ? sizeId.text.trim() : null,
        tireStatusName: selectedstatus.value.isNotEmpty ? selectedstatus.value : null,
        tireTypeName: typeId.text.trim().isNotEmpty ? typeId.text.trim() : null,
      );

      final ctx = Get.context;
      if (ctx != null) {
        final tyreName = LocaleHelper.tyreName(ctx);

        if (savedOnline) {
          AppSnackbar.success(
            "$tyreName with Serial no: $serial created successfully.",
            title: "$tyreName Cloned Successfully",
          );
        } else {
          AppSnackbar.offlineSuccess(
            "$tyreName with serial no. $serial created successfully",
            title: "$tyreName cloned successfully.",
          );
        }
      }

      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().incrementTyreCount();
      }
      if (Get.isRegistered<AllTyreController>()) {
        unawaited(Get.find<AllTyreController>().refresh());
      }
    } catch (e) {
    }
  }
  void cancelDialog() {
    AppDialog.showConfirmDialog(
      title: 'Cancel Request',
      message:
      'Are you sure you want to cancel? You will \n lose unsaved data.',
      onOk: () {
        Get.back();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offAllNamed(AppPages.HOME);
        });
      },
    );
  }

  Future<void> loadMasterData() async {
    try {
      final data = await _masterService.fetchMasterData();

      allTireSizes = data['tireSizes'];
      allTypeList = data['tireTypes'];

      final rawStatuses = (data['tireStatus'] as List);
      statusList.assignAll(
        rawStatuses.map((e) => e['statusName'].toString()).toList(),
      );
      statusIdList.assignAll(
        rawStatuses.map((e) => e['statusId'] as int).toList(),
      );
      if (statusList.isNotEmpty && selectedstatus.value.isEmpty) {
        selectedstatus.value = statusList.last;
        selectedStatusId.value = statusIdList.last;
      }

      manufacturerList.assignAll(
        (data['tireManufacturers'] as List)
            .map((e) => e['manufacturerName'].toString().toUpperCase())
            .toSet()
            .toList(),
      );
      manufacturerIdList.assignAll(
        (data['tireManufacturers'] as List)
            .map((e) => e['manufacturerId'] as int)
            .toSet()
            .toList(),
      );

      indCodeList.assignAll(
        (data['tireIndCodes'] as List)
            .map((e) => e['codeName'].toString())
            .toSet()
            .toList(),
      );
      indCodeIdList.assignAll(
        (data['tireIndCodes'] as List)
            .map((e) => e['codeId'] as int)
            .toSet()
            .toList(),
      );

      compoundList.assignAll(
        (data['tireCompounds'] as List)
            .map((e) => e['compoundName'].toString())
            .toSet()
            .toList(),
      );
      compoundIdList.assignAll(
        (data['tireCompounds'] as List)
            .map((e) => e['compoundId'] as int)
            .toSet()
            .toList(),
      );

      loadRatingList.assignAll(
        (data['tireLoadRatings'] as List)
            .map((e) => e['ratingName'].toString())
            .toSet()
            .toList(),
      );
      loadRatingIdList.assignAll(
        (data['tireLoadRatings'] as List)
            .map((e) => e['ratingId'] as int)
            .toSet()
            .toList(),
      );

      speedRatingList.assignAll(
        (data['tireSpeedRatings'] as List)
            .map((e) => e['speedRatingName'].toString())
            .toSet()
            .toList(),
      );
      speedRatingIdList.assignAll(
        (data['tireSpeedRatings'] as List)
            .map((e) => e['speedRatingId'] as int)
            .toSet()
            .toList(),
      );

      fillTypeList.assignAll(
        (data['tireFillTypes'] as List)
            .map((e) => e['fillTypeName'].toString())
            .toSet()
            .toList(),
      );
      fillTypeIdList.assignAll(
        (data['tireFillTypes'] as List)
            .map((e) => e['fillTypeId'] as int)
            .toSet()
            .toList(),
      );

      final plyRaw = (data['plyRating'] as List? ?? []);
      plyRatingList.assignAll(
        plyRaw.map((e) => e['ratingName'].toString()).toList(),
      );
      plyRatingIdList.assignAll(
        plyRaw.map((e) => (e['ratingId'] as num).toInt()).toList(),
      );
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  void filterTireSizesByManufacturer(int mfgId) {
    final filtered = allTireSizes
        .where((e) => e['tireManufacturerId'] == mfgId)
        .toList();
    tireSizeList.assignAll(
      filtered.map((e) => e['tireSizeName'].toString()).toList(),
    );
    tireSizeIdList.assignAll(
      filtered.map((e) => e['tireSizeId'] as int).toList(),
    );

    sizeId.clear();
    selectedSizeId.value = 0;
    typeList.clear();
    typeIdList.clear();
    typeId.clear();
    selectedTypeId.value = 0;
    starRating.value = 0;
    isStarEnabled.value = false;
    _applyStarPlyToggle(null);
  }


  void _applyStarPlyToggle(String? sizeName) {
    if (sizeName != null && sizeName.toUpperCase().contains("R")) {
      showStarRating.value = true;
      ratingLabel.value = "Star Rating";
      // Ply clear karo
      plyRatingId.clear();
      selectedPlyRatingId.value = 0;
    } else {
      showStarRating.value = false;
      ratingLabel.value = "Ply Rating";
      // Star clear karo
      starRating.value = 0;
      starRatingId.clear();
    }
    update();
  }

  Future<void> getTireTypes(int tireSizeId) async {
    typeList.clear();
    typeIdList.clear();
    typeId.clear();
    selectedTypeId.value = 0;

    if (tireSizeId == 0) {
      _applyStarPlyToggle(null);
      return;
    }

    Map<String, dynamic>? sizeEntry;
    try {
      sizeEntry = allTireSizes.firstWhere(
            (e) => e['tireSizeId'] == tireSizeId,
      ) as Map<String, dynamic>?;
    } catch (_) {
      sizeEntry = null;
    }

    final String? sizeName = sizeEntry?['tireSizeName']?.toString();
    _applyStarPlyToggle(sizeName);

    final filtered = allTypeList
        .where((e) => e["tireSizeId"] == tireSizeId)
        .toList();

    typeList.assignAll(filtered.map((e) => e['typeName'].toString()).toList());
    typeIdList.assignAll(filtered.map((e) => e['typeId'] as int).toList());

  }
  void setStarRating(int value) {
    starRating.value = value;
    starRatingId.text = value.toString();
    update();
  }

  @override
  void onClose() {
    manufacturerId.dispose();
    sizeId.dispose();
    starRatingId.dispose();
    plyRatingId.dispose();
    currentHours.dispose();
    currentKm.dispose();
    middleTread.dispose();
    super.onClose();
  }

  Future<void> loadTyreForClone(int tyreId) async {
    try {
      final allowed = await PendingInspectionGuard.canProceedForTire(
        tireId: tyreId,
        action: PendingBlockedAction.cloneTyre,
      );
      if (!allowed) {
        Get.back();
        return;
      }
      final tyre = await TyreService().cloneTyresById(tyreId);
      await _assignCloneData(tyre);
      autoValidateFields.value = true;
      tireSerialNoError.value = "Tire serial number is required.";
    } catch (_) {
    }
  }
  Future<void> _assignCloneData(viewtyre.ViewModel tyre) async {

    filterTireSizesByManufacturer(tyre.manufacturerId ?? 0);

    await getTireTypes(tyre.sizeId ?? 0);

    model.vehicleId = tyre.vehicleId;
    model.vehicleNumber = tyre.vehicleNumber;

    tireSerialNo.clear();
    brandNo.clear();

    evaluationNo.text = tyre.evaluationNo ?? '';
    lotNo.text = tyre.lotNo ?? '';
    poNo.text = tyre.poNo ?? '';

    currentHours.text = formatNum(tyre.currentHours);
    currentKm.text = formatNum(tyre.currentMiles);

    final int tc = noOfTreadDepthReadings.value;
    outsideTread.text = formatNum(tyre.outsideTread);
    middleTread.text  = tc == 3 ? formatNum(tyre.middleTread) : "0";
    insideTread.text  = (tc == 2 || tc == 3) ? formatNum(tyre.insideTread) : "0";

    try {
      final raw = tyre.registeredDate.toString();
      DateTime? parsedDate =
          LocaleHelper.parseDisplayDate(raw) ?? DateTime.tryParse(raw);
      if (parsedDate != null) {
        registeredDate.text = LocaleHelper.formatDate(parsedDate);
        registeredDateApi =
        "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}"
            "-${parsedDate.day.toString().padLeft(2, '0')}T00:00:00";
      } else {
        throw Exception("Date parse failed");
      }
    } catch (_) {
      final now = DateTime.now();
      registeredDate.text = LocaleHelper.formatDate(now);
      registeredDateApi =
      "${now.year}-${now.month.toString().padLeft(2, '0')}"
          "-${now.day.toString().padLeft(2, '0')}T00:00:00";
    }

    // ── Tracking Method ───────────────────────────────────────────
    final mileage = tyre.mileageType?.toString() ?? "1";
    switch (mileage) {
      case "2":
      case "distance":
        selectedTrackingMethod.value = "Distance";
        trackingMethodText.value = "Distance";
        break;
      case "3":
      case "both":
        selectedTrackingMethod.value = "Both";
        trackingMethodText.value = "Both";
        break;
      default:
        selectedTrackingMethod.value = "Hours";
        trackingMethodText.value = "Hours";
    }

    setDropdownById(
      id: tyre.tireStatusId,
      idList: statusIdList,
      nameList: statusList,
      controller: tireStatusId,
      selectedId: selectedStatusId,
    );
    if (tireStatusId.text.isNotEmpty) selectedstatus.value = tireStatusId.text;

    setDropdownById(
      id: tyre.manufacturerId,
      idList: manufacturerIdList.toList(),
      nameList: manufacturerList.toList(),
      controller: manufacturerId,
      selectedId: selectedManufacturerId,
    );


    setDropdownById(
      id: tyre.sizeId,
      idList: tireSizeIdList.toList(),
      nameList: tireSizeList.toList(),
      controller: sizeId,
      selectedId: selectedSizeId,
    );

    checkStarEnable();
    isStarEnabled.value =
        manufacturerId.text.trim().isNotEmpty && sizeId.text.trim().isNotEmpty;

    if (showStarRating.value) {
      final resolvedStarId = tyre.starRatingId ?? 0;
      starRating.value = resolvedStarId;
      starRatingId.text = resolvedStarId > 0 ? resolvedStarId.toString() : '';
      plyRatingId.clear();
      selectedPlyRatingId.value = 0;
    } else {
      final resolvedPlyId = tyre.plyId ?? 0;
      setDropdownById(
        id: resolvedPlyId > 0 ? resolvedPlyId : null,
        idList: plyRatingIdList.toList(),
        nameList: plyRatingList.toList(),
        controller: plyRatingId,
        selectedId: selectedPlyRatingId,
      );
      starRating.value = 0;
      starRatingId.clear();
    }

    setDropdownById(
      id: tyre.indCodeId,
      idList: indCodeIdList.toList(),
      nameList: indCodeList.toList(),
      controller: indCodeId,
      selectedId: selectedIndCodeId,
    );

    setDropdownById(
      id: tyre.compoundId,
      idList: compoundIdList.toList(),
      nameList: compoundList.toList(),
      controller: compoundId,
      selectedId: selectedCompoundId,
    );

    setDropdownById(
      id: tyre.loadRatingId,
      idList: loadRatingIdList.toList(),
      nameList: loadRatingList.toList(),
      controller: loadRatingId,
      selectedId: selectedLoadRatingId,
    );

    setDropdownById(
      id: tyre.speedRatingId,
      idList: speedRatingIdList.toList(),
      nameList: speedRatingList.toList(),
      controller: speedRatingId,
      selectedId: selectedSpeedRatingId,
    );

    setDropdownById(
      id: tyre.typeId,
      idList: typeIdList.toList(),
      nameList: typeList.toList(),
      controller: typeId,
      selectedId: selectedTypeId,
    );

    // ── Tread
    originalTread.text = formatNum(tyre.originalTread);
    purchasedTread.text = formatNum(tyre.purchasedTread);
    removeAt.text = (tyre.removeAt != null) ? formatNum(tyre.removeAt) : "0";
    outsideTread.text = formatNum(tyre.outsideTread);
    insideTread.text = formatNum(tyre.insideTread);

    // ── Cost
    purchaseCost.text = formatNum(tyre.purchaseCost);
    casingValue.text = formatNum(tyre.casingValue);

    setDropdownById(
      id: tyre.fillTypeId,
      idList: fillTypeIdList.toList(),
      nameList: fillTypeList.toList(),
      controller: fillTypeId,
      selectedId: selectedFillTypeId,
    );

    fillCost.text = formatNum(tyre.fillCost);
    repairCost.text = formatNum(tyre.repairCost);
    retreadCost.text = formatNum(tyre.retreadCost);
    warrantyAdjustment.text = formatNum(tyre.warrantyAdjustment);
    costAdjustment.text = formatNum(tyre.costAdjustment);
    soldAmount.text = formatNum(tyre.soldAmount);
    netCost.text = formatNum(tyre.netCost);

    update();
  }
  Future<void> _assignCloneFromTyreModel(TyreModel tyre) async {
    try {

      tireSerialNo.clear();
      brandNo.clear();

      final mfgName = (tyre.manufacturerName ?? '').toUpperCase().trim();
      if (mfgName.isNotEmpty) {
        final mfgIndex = manufacturerList.indexWhere(
              (m) => m.toUpperCase().trim() == mfgName,
        );
        if (mfgIndex != -1) {
          manufacturerId.text = manufacturerList[mfgIndex];
          selectedManufacturerId.value = manufacturerIdList[mfgIndex];
          filterTireSizesByManufacturer(manufacturerIdList[mfgIndex]);
        } else {
        }
      }

      final sizeName = (tyre.sizeName ?? '').trim();
      if (sizeName.isNotEmpty) {
        final sizeIndex = tireSizeList.indexWhere(
              (s) => s.trim().toLowerCase() == sizeName.toLowerCase(),
        );
        if (sizeIndex != -1) {
          sizeId.text = tireSizeList[sizeIndex];
          selectedSizeId.value = tireSizeIdList[sizeIndex];
          await getTireTypes(tireSizeIdList[sizeIndex]);
        } else {
        }
      }

      if (showStarRating.value) {
        final sId = tyre.starRatingId ?? 0;
        if (sId > 0 && sId <= 5) {
          starRating.value = sId;
          starRatingId.text = sId.toString();
        } else {
          starRating.value = 0;
          starRatingId.clear();
        }
        isStarEnabled.value = true;
        plyRatingId.clear();
        selectedPlyRatingId.value = 0;
      } else {

        final resolvedPlyId = (tyre.plyId != null && tyre.plyId! > 0) ? tyre.plyId : tyre.starRatingId;
        setDropdownById(
          id: resolvedPlyId,
          idList: plyRatingIdList.toList(),
          nameList: plyRatingList.toList(),
          controller: plyRatingId,
          selectedId: selectedPlyRatingId,
        );
        starRating.value = 0;
        starRatingId.clear();
      }

      final typeName = (tyre.typeName ?? '').trim();
      if (typeName.isNotEmpty) {
        final typeIndex = typeList.indexWhere(
              (tp) => tp.trim().toLowerCase() == typeName.toLowerCase(),
        );
        if (typeIndex != -1) {
          typeId.text = typeList[typeIndex];
          selectedTypeId.value = typeIdList[typeIndex];
        } else {
        }
      }

      final statusName = (tyre.tireStatusName ?? '').trim();
      if (statusName.isNotEmpty) {
        final statusIndex = statusList.indexWhere(
              (s) => s.trim().toLowerCase() == statusName.toLowerCase(),
        );
        if (statusIndex != -1) {
          tireStatusId.text = statusList[statusIndex];
          selectedstatus.value = statusList[statusIndex];
          selectedStatusId.value = statusIdList[statusIndex];
        } else {
        }
      }

      evaluationNo.text = tyre.evaluationNo ?? '';
      lotNo.text = tyre.lotNo ?? '';
      poNo.text = tyre.poNo ?? '';

      final mileage = (tyre.mileageType ?? '').toLowerCase();
      if (mileage == '2' || mileage == 'distance') {
        selectedTrackingMethod.value = 'Distance';
        trackingMethodText.value = 'Distance';
      } else if (mileage == '3' || mileage == 'both') {
        selectedTrackingMethod.value = 'Both';
        trackingMethodText.value = 'Both';
      } else {
        selectedTrackingMethod.value = 'Hours';
        trackingMethodText.value = 'Hours';
      }
      currentHours.text = formatNum(tyre.currentHours);
      currentKm.text = formatNum(tyre.currentMiles);

      setDropdownById(
        id: tyre.indCodeId,
        idList: indCodeIdList.toList(),
        nameList: indCodeList.toList(),
        controller: indCodeId,
        selectedId: selectedIndCodeId,
      );

      setDropdownById(
        id: tyre.compoundId,
        idList: compoundIdList.toList(),
        nameList: compoundList.toList(),
        controller: compoundId,
        selectedId: selectedCompoundId,
      );

      setDropdownById(
        id: tyre.loadRatingId,
        idList: loadRatingIdList.toList(),
        nameList: loadRatingList.toList(),
        controller: loadRatingId,
        selectedId: selectedLoadRatingId,
      );

      setDropdownById(
        id: tyre.speedRatingId,
        idList: speedRatingIdList.toList(),
        nameList: speedRatingList.toList(),
        controller: speedRatingId,
        selectedId: selectedSpeedRatingId,
      );

      setDropdownById(
        id: tyre.fillTypeId,
        idList: fillTypeIdList.toList(),
        nameList: fillTypeList.toList(),
        controller: fillTypeId,
        selectedId: selectedFillTypeId,
      );

      outsideTread.text = formatNum(tyre.outsideTread);
      middleTread.text = formatNum(tyre.middleTread ?? 0);
      insideTread.text = formatNum(tyre.insideTread);
      final avg = ((tyre.outsideTread ?? 0) + (tyre.middleTread ?? 0) + (tyre.insideTread ?? 0)) / 3;
      originalTread.text = formatNum(
        tyre.originalTread ?? tyre.currentTreadDepth ?? avg,
      );
      purchasedTread.text = formatNum(
        tyre.purchasedTread ?? tyre.currentTreadDepth ?? avg,
      );
      removeAt.text = (tyre.removeAt != null) ? formatNum(tyre.removeAt) : "0";

      purchaseCost.text = formatNum(tyre.purchaseCost);
      casingValue.text = formatNum(tyre.casingValue);
      fillCost.text = formatNum(tyre.fillCost);
      repairCost.text = formatNum(tyre.repairCost);
      retreadCost.text = formatNum(tyre.retreadCost);
      warrantyAdjustment.text = formatNum(tyre.warrantyAdjustment);
      costAdjustment.text = formatNum(tyre.costAdjustment);
      soldAmount.text = formatNum(tyre.soldAmount);
      netCost.text = formatNum(tyre.netCost);

      final now = DateTime.now();
      registeredDate.text = LocaleHelper.formatDate(now);
      registeredDateApi =
      "${now.year}-${now.month.toString().padLeft(2, '0')}"
          "-${now.day.toString().padLeft(2, '0')}T00:00:00";

      checkStarEnable();
      autoValidateFields.value = true;
      tireSerialNoError.value = "Tire serial number is required.";
      update();
    } catch (e) {
    }
  }
  void setDropdownById({
    required int? id,
    required List<int> idList,
    required List<String> nameList,
    required TextEditingController controller,
    RxInt? selectedId,
  }) {
    if (id == null || id == 0) {
      controller.clear();
      if (selectedId != null) selectedId.value = 0;
      return;
    }
    final index = idList.indexOf(id);
    if (index == -1) {
      controller.clear();
      return;
    }
    if (index >= nameList.length) {
      controller.clear();
      if (selectedId != null) selectedId.value = 0;
      return;
    }
    controller.text = nameList[index];
    if (selectedId != null) selectedId.value = idList[index];
  }
}