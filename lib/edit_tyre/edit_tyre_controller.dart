import 'package:emtrack/edit_tyre/edit_tyre_model.dart';
import 'package:emtrack/edit_tyre/edit_tyre_service.dart';
import 'package:emtrack/routes/app_pages.dart';
import 'package:emtrack/services/master_data_service.dart';
import 'package:emtrack/services/change_account_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:emtrack/views/home/home_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/all_tyre_controller.dart';
import '../controllers/preferences_controller.dart';
import '../models/tyre_model.dart';
import '../utils/app_dialog.dart';
import '../utils/app_snackbar.dart';
import '../utils/local_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/mesurment_helper_class.dart';
import '../inspection/vehicle_inspe_controller.dart';
import '../utils/pending_inspection_guard.dart';
import '../utils/tyre_unit_history.dart';

class EditTyreController extends GetxController {
  final RxInt currentStep = 0.obs;
  final RxBool isSubmitting = false.obs;
  int? tireId;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final MasterDataService _masterService = MasterDataService();

  var tireStatusName = "".obs;
  RxString selectedTrackingMethod = "Hours".obs;
  RxString get measurementUnit {
    final pref = Get.find<PreferencesController>();
    return (pref.selectedMeasurement.value == "Imperial" ? "/32" : "mm").obs;
  }

  final distLabel = MeasurementHelper.distanceLabel;

  // STEP 3
  final middleTread = TextEditingController(text: "0");

  final RxInt noOfTreadDepthReadings = 3.obs;

  RxList<String> statusList = <String>[].obs;
  RxList<int> statusIdList = <int>[].obs;
  RxInt selectedstatus = 0.obs;
  String? registeredDateApi;
  final RxBool isPageLoading = false.obs;

  final manufacturerList = <String>[].obs;
  final manufacturerIdList = <int>[].obs;
  final tireSizeList = <String>[].obs;
  final tireSizeIdList = <int>[].obs;
  final typeList = <String>[].obs;
  final typeIdList = <int>[].obs;
  final indCodeList = <String>[].obs;
  final indCodeIdList = <int>[].obs;
  final compoundList = <String>[].obs;
  final compoundIdList = <int>[].obs;
  final loadRatingList = <String>[].obs;
  final loadRatingIdList = <int>[].obs;
  final speedRatingList = <String>[].obs;
  final speedRatingIdList = <int>[].obs;
  final fillTypeList = <String>[].obs;
  final fillTypeIdList = <int>[].obs;

  List allTireSizes = [];
  List allTypeList = [];

  final dispositionList = <String>[].obs;
  final dispositionIdList = <int>[].obs;

  String formatNum(num? v) {
    if (v == null) return "0";
    return v % 1 == 0 ? v.toInt().toString() : v.toString();
  }

  void setStatusList(List<String> list, List<int> idList) {
    statusList.assignAll(list);
    statusIdList.assignAll(idList);
  }
  void nextStep() {
    if (!formKey.currentState!.validate()) {
      Get.snackbar(
        "Invalid Step",
        "Please fill required fields",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (currentStep.value < 3) currentStep.value++;
  }

  void previousStep() {
    if (currentStep.value > 0) currentStep.value--;
  }

  final EditTyreModel model = EditTyreModel();

  // STEP 1
  final tireSerialNo = TextEditingController();
  final brandNo = TextEditingController();
  final registeredDate = TextEditingController();
  final evaluationNo = TextEditingController();
  final lotNo = TextEditingController();
  final poNo = TextEditingController();
  final dispositionText = "Inventory".obs;
  final tireStatusId = TextEditingController();
  final trackingMethodText = "Hours".obs;
  final currentHours = TextEditingController(text: "0");
  final TenderNum = TextEditingController(text: "0");
  final currentKm = TextEditingController(text: "0");

  // STEP 2
  final RxInt starRating = 0.obs;
  final manufacturerId = TextEditingController(text: '');
  final sizeId = TextEditingController(text: '');
  final starRatingId = TextEditingController(text: '');
  final typeId = TextEditingController(text: '');
  final indCodeId = TextEditingController(text: '');
  final compoundId = TextEditingController(text: '');
  final loadRatingId = TextEditingController(text: '');
  final speedRatingId = TextEditingController(text: '');

  // Star vs Ply Rating toggle
  final RxBool showStarRating = true.obs;
  final RxString ratingLabel = "Star Rating".obs;
  final plyRatingList = <String>[].obs;
  final plyRatingIdList = <int>[].obs;
  final RxInt selectedPlyRatingId = 0.obs;
  final plyRatingId = TextEditingController();

  // STEP 3
  final originalTread = TextEditingController();
  final removeAt = TextEditingController(text: "0");
  final purchasedTread = TextEditingController();
  final outsideTread = TextEditingController(text: "0");
  final insideTread = TextEditingController(text: "0");

  // STEP 4
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

  final RxInt selectedManufacturerId = 0.obs;
  final RxInt selectedSizeId = 0.obs;
  final RxInt selectedTypeId = 0.obs;
  final RxInt selectedLoadRatingId = 0.obs;
  final RxInt selectedSpeedRatingId = 0.obs;
  final RxInt selectedIndCodeId = 0.obs;
  final RxInt selectedCompoundId = 0.obs;
  final RxInt selectedFillTypeId = 0.obs;
  final RxInt selectedDispositionId = 0.obs;

  final RxBool isStarEnabled = true.obs;

  void checkStarEnable() {
    isStarEnabled.value = true;
    update();
  }

  @override
  void onInit() {
    super.onInit();
    _initController();
  }

  Future<void> _initController() async {
    final arg = Get.arguments as int?;
    tireId = arg;

    if (tireId != null && tireId! > 0) {
      final allowed = await PendingInspectionGuard.canProceedForTire(
        tireId: tireId,
        action: PendingBlockedAction.editTyre,
      );
      if (!allowed) {
        Get.back();
        return;
      }
    }

    isPageLoading.value = true;

    noOfTreadDepthReadings.value = SecureStorage.getNoOfTreadDepthReadings();


    _refreshTreadDepthFromApi();

    await loadMasterData();
    await loadTyreDetails();
    manufacturerId.addListener(checkStarEnable);
    sizeId.addListener(checkStarEnable);

    if (registeredDate.text.isEmpty) {
      final now = DateTime.now();
      registeredDate.text = LocaleHelper.formatDate(now);
      registeredDateApi =
      "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}T00:00:00";
    }

    if (model.dispositionId == null || model.dispositionId == 0) {
      model.dispositionId = 8;
      selectedDispositionId.value = 8;
      dispositionText.value = _getDispositionName(8);
    }

    if (model.mountStatus == null || model.mountStatus!.isEmpty) {
      model.mountStatus = "Not Mounted";
    }
    model.isMountToRim = model.isMountToRim ?? false;
    model.numberOfRetreads = model.numberOfRetreads ?? 0;
    numberOfRetreadsVal.value = model.numberOfRetreads ?? 0;
    update();
  }

  // ✅ FIX: Background mein latest noOfTreadDepthReadings API se refresh karo
  // Taki web portal pe change kiya hua setting edit tyre step3 mein instantly dikhe
  void _refreshTreadDepthFromApi() {
    Future(() async {
      try {
        final locationId = await SecureStorage.getLocationId();
        if (locationId != null && locationId.isNotEmpty) {
          final id = int.tryParse(locationId);
          if (id != null && id > 0) {
            final svc = ChangeAccountService();
            final fresh = await svc.fetchAndSaveNoOfTreadDepthReadings(id);
            noOfTreadDepthReadings.value = fresh;
          }
        }
      } catch (_) {
      }
    });
  }

  Future<void> loadTyreDetails() async {
    try {
      isPageLoading.value = true;

      final tyre = await EditTyreService.getTyreById(tireId!);

      model.vehicleId = tyre.vehicleId;
      model.vehicleNumber = tyre.vehicleNumber;

      final int tc = noOfTreadDepthReadings.value;
      outsideTread.text = formatNum(tyre.outsideTread);  // Outside always show
      middleTread.text  = tc == 3 ? formatNum(tyre.middleTread) : "0";   // Middle sirf count=3
      insideTread.text  = (tc == 2 || tc == 3) ? formatNum(tyre.insideTread) : "0"; // Inside count=2,3

      model.dispositionId = tyre.dispositionId ?? 8;
      selectedDispositionId.value = tyre.dispositionId ?? 8;
      dispositionText.value = _getDispositionName(tyre.dispositionId ?? 8);
      model.mountStatus = tyre.mountStatus ?? 'Not Mounted';
      model.wheelPosition = tyre.wheelPosition;
      model.isMountToRim = tyre.isMountToRim ?? false;
      model.numberOfRetreads = tyre.numberOfRetreads ?? 0;
      model.mountedRimId = tyre.mountedRimId ?? 0;
      model.mountedRimSerialNo = tyre.mountedRimSerialNo;

      selectedManufacturerId.value = tyre.manufacturerId ?? 0;
      selectedSizeId.value = tyre.sizeId ?? 0;
      selectedTypeId.value = tyre.typeId ?? 0;
      selectedCompoundId.value = tyre.compoundId ?? 0;
      selectedFillTypeId.value = tyre.fillTypeId ?? 0;

      if (tyre.manufacturerId != null && tyre.manufacturerId! > 0) {
        filterTireSizesByManufacturer(tyre.manufacturerId!);
      }
      if (tyre.sizeId != null && tyre.sizeId! > 0) {
        await getTireTypes(tyre.sizeId!);
      }

      tireSerialNo.text = tyre.tireSerialNo ?? '';
      brandNo.text = tyre.brandNo ?? '';
      evaluationNo.text = tyre.evaluationNo?.toString() ?? '';
      lotNo.text = tyre.lotNo?.toString() ?? '';
      poNo.text = tyre.poNo?.toString() ?? '';
      currentHours.text = formatNum(tyre.currentHours);
      currentKm.text = formatNum(tyre.currentMiles);

      final mileage = tyre.mileageType?.toString().toLowerCase().trim() ?? "1";
      switch (mileage) {
        case "1":
        case "hours":
          selectedTrackingMethod.value = "Hours";
          trackingMethodText.value = "Hours";
          break;
        case "2":
        case "distance":
        case "miles":
        case "km":
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

      try {
        final raw = tyre.registeredDate.toString();
        final datePart = raw.contains('T')
            ? raw.split('T')[0]
            : raw.split(' ')[0];
        final parts = datePart.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        final date = DateTime(year, month, day);
        registeredDate.text = LocaleHelper.formatDate(date);
        registeredDateApi =
        "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}T00:00:00";
      } catch (_) {
        final now = DateTime.now();
        registeredDate.text = LocaleHelper.formatDate(now);
        registeredDateApi =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}T00:00:00";
      }

      // ─── ✅ OFFLINE STATUS INDEX PRE-FILL CORRECTION ───
// ─── ✅ OFFLINE STATUS INDEX PRE-FILL CORRECTION ───
      if (tyre.tireStatusId != null) {
        final targetStatusId = int.tryParse(tyre.tireStatusId.toString()) ?? 0;
        if (targetStatusId > 0) {
          if (statusIdList.contains(targetStatusId)) {
            // ✅ ID match mila — directly set karo
            selectedstatus.value = targetStatusId;
            setDropdownById(
              id: targetStatusId,
              idList: statusIdList,
              nameList: statusList,
              controller: tireStatusId,
            );
          } else if (tyre.tireStatusName != null &&
              tyre.tireStatusName!.isNotEmpty) {
            // ✅ ID list mein nahi — name se fallback try karo
            final matchedIdx = statusList.indexWhere(
                  (s) =>
              s.toLowerCase().trim() ==
                  tyre.tireStatusName!.toLowerCase().trim(),
            );
            if (matchedIdx != -1) {
              selectedstatus.value = statusIdList[matchedIdx];
              tireStatusId.text = statusList[matchedIdx];
            }
          }
        }
      } else if (tyre.tireStatusName != null &&
          tyre.tireStatusName!.isNotEmpty) {
        // ✅ ID null hai — sirf name se try karo
        final matchedIdx = statusList.indexWhere(
              (s) =>
          s.toLowerCase().trim() ==
              tyre.tireStatusName!.toLowerCase().trim(),
        );
        if (matchedIdx != -1) {
          selectedstatus.value = statusIdList[matchedIdx];
          tireStatusId.text = statusList[matchedIdx];
        }
      }
      else if (tyre.tireStatusName != null &&
          tyre.tireStatusName!.isNotEmpty) {
        final matchedIdx = statusList.indexWhere(
              (s) =>
          s.toLowerCase().trim() ==
              tyre.tireStatusName!.toLowerCase().trim(),
        );
        if (matchedIdx != -1) {
          selectedstatus.value = statusIdList[matchedIdx];
          tireStatusId.text = statusList[matchedIdx];
        }
      }

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

      // ─── ✅ OFFLINE STAR RATING CRITICAL INJECTOR FIXED ───
      int parsedStarRatingId =
          int.tryParse(tyre.starRatingId?.toString() ?? '0') ?? 0;
      final int parsedPlyId = int.tryParse(tyre.plyId?.toString() ?? '0') ?? 0;

      // Safe size identification check fallback structure from local state lists
      String currentSizeName = '';
      if (selectedSizeId.value > 0) {
        final index = tireSizeIdList.indexOf(selectedSizeId.value);
        if (index != -1) currentSizeName = tireSizeList[index];
      }

      // 🔥 CRITICAL CACHE INTERACTION BOUNDARY FIXED:
      // Model me sizeName defined nahi tha, isliye sizeId lookup se text map kiya hai.
      bool isRadialSize = currentSizeName.toUpperCase().contains('R');

      if (parsedStarRatingId > 0 || (isRadialSize && parsedPlyId == 0)) {
        showStarRating.value = true;
        ratingLabel.value = "Star Rating";

        // Validation check for strict UI options index mapping array boundaries [1 to 5]
        if (parsedStarRatingId <= 0 || parsedStarRatingId > 5) {
          parsedStarRatingId =
          1; // Default fallback to first option '**' instead of keeping it empty
        }

        starRating.value = parsedStarRatingId;
        starRatingId.text = parsedStarRatingId.toString();
        plyRatingId.clear();
        selectedPlyRatingId.value = 0;

      } else if (parsedPlyId > 0 && parsedPlyId != 1123) {
        showStarRating.value = false;
        ratingLabel.value = "Ply Rating";
        starRating.value = 0;
        starRatingId.clear();

        final targetPlyId = parsedPlyId;
        if (plyRatingIdList.contains(targetPlyId)) {
          setDropdownById(
            id: targetPlyId,
            idList: plyRatingIdList.toList(),
            nameList: plyRatingList.toList(),
            controller: plyRatingId,
            selectedId: selectedPlyRatingId,
          );
        }
      } else {
        // Ultimate safe tracking option layout boundary logic
        Map<String, dynamic>? sizeEntry;
        try {
          sizeEntry =
          allTireSizes.firstWhere(
                (e) => e['tireSizeId'] == (tyre.sizeId ?? 0),
          )
          as Map<String, dynamic>?;
        } catch (_) {
          sizeEntry = null;
        }
        _applyStarPlyToggle(
          sizeEntry?['tireSizeName']?.toString() ?? currentSizeName,
        );
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

      originalTread.text = formatNum(tyre.originalTread);
      purchasedTread.text = formatNum(tyre.purchasedTread);
      removeAt.text = formatNum(tyre.removeAt);

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

      isPageLoading.value = false;
      update();
    } catch (e) {
      isPageLoading.value = false;
      Get.snackbar("Error", e.toString());
    }
  }

  String _getDispositionName(int? dispositionId) {
    if (dispositionIdList.isNotEmpty) {
      final index = dispositionIdList.indexOf(dispositionId ?? 0);
      if (index != -1) return dispositionList[index];
    }
    const Map<int, String> dispositionMap = {
      1: "Scrap",
      2: "Repair",
      3: "Retread",
      4: "On Hold",
      5: "Mounted",
      6: "Sold",
      7: "Installed",
      8: "Inventory",
    };
    return dispositionMap[dispositionId] ?? "Inventory";
  }

  void calculateNetCost() {
    double a = double.tryParse(purchaseCost.text) ?? 0;
    double b = double.tryParse(casingValue.text) ?? 0;
    double c = double.tryParse(fillCost.text) ?? 0;
    double d = double.tryParse(repairCost.text) ?? 0;
    double e = double.tryParse(retreadCost.text) ?? 0;
    double f = double.tryParse(warrantyAdjustment.text) ?? 0;
    double g = double.tryParse(costAdjustment.text) ?? 0;
    double h = double.tryParse(soldAmount.text) ?? 0;
    netCost.text = formatNum(a - b + c + d + e + f - g - h);
  }

  void bindToModel() {
    // --- Step 1 ---
    model.tireStatusId = selectedstatus.value;
    // ✅ FIX Bug3&4: Resolve tireStatusName from statusList so it gets saved to cache and API
    final statusIdx = statusIdList.indexOf(selectedstatus.value);
    model.tireStatusName = (statusIdx != -1 && statusIdx < statusList.length)
        ? statusList[statusIdx]
        : tireStatusName.value.isNotEmpty
        ? tireStatusName.value
        : null;
    model.tireSerialNo = tireSerialNo.text.trim();
    model.brandNo = brandNo.text.trim().isEmpty
        ? null
        : brandNo.text.trim(); // ✅ FIX Bug1: String nahi int
    model.registeredDate = registeredDateApi.toString();
    model.evaluationNo = evaluationNo.text.trim();
    model.lotNo = lotNo.text.trim();
    model.poNo = poNo.text.trim();

    model.dispositionId = selectedDispositionId.value != 0
        ? selectedDispositionId.value
        : model.dispositionId;

    // --- Step 2 ---
    switch (selectedTrackingMethod.value.toLowerCase()) {
      case "hours":
        model.trackingMethod = 1;
        model.mileageType = "1";
        model.currentHours = double.tryParse(currentHours.text) ?? 0;
        model.currentMiles = 0;
        break;
      case "distance":
        model.trackingMethod = 2;
        model.mileageType = "2";
        model.currentHours = 0;
        model.currentMiles = double.tryParse(currentKm.text) ?? 0;
        break;
      case "both":
        model.trackingMethod = 3;
        model.mileageType = "3";
        model.currentHours = double.tryParse(currentHours.text) ?? 0;
        model.currentMiles = double.tryParse(currentKm.text) ?? 0;
        break;
    }

    model.manufacturerId = selectedManufacturerId.value;
    model.sizeId = selectedSizeId.value;
    model.starRatingId = showStarRating.value ? starRating.value : 0;
    model.plyId = showStarRating.value
        ? 0
        : (selectedPlyRatingId.value > 0 ? selectedPlyRatingId.value : 0);
    model.typeId = selectedTypeId.value;
    model.indCodeId = selectedIndCodeId.value;
    model.compoundId = selectedCompoundId.value;
    model.loadRatingId = selectedLoadRatingId.value;
    model.speedRatingId = selectedSpeedRatingId.value;
    model.fillTypeId = selectedFillTypeId.value;

    // --- Step 3: Tread Depth ---
    final outTread = double.tryParse(outsideTread.text) ?? 0;
    final insTread = double.tryParse(insideTread.text) ?? 0;
    final midTread = double.tryParse(middleTread.text) ?? 0;

    model.originalTread = double.tryParse(originalTread.text) ?? 0;
    model.removeAt = double.tryParse(removeAt.text) ?? 0;
    model.purchasedTread = double.tryParse(purchasedTread.text) ?? 0;

    // ✅ noOfTreadDepthReadings ke hisaab se model tread values set karo
    final int treadCount = noOfTreadDepthReadings.value;
    double average;
    if (treadCount == 1) {
      // count=1: sirf Outside field show hoti hai
      // ✅ middle/inside user ne enter nahi kiya — 0 bhejo
      model.outsideTread = outTread;
      model.middleTread  = 0;
      model.insideTread  = 0;
      average = outTread;
    } else if (treadCount == 2) {
      // count=2: Outside + Inside show hoti hai, Middle hidden
      // ✅ middleTread = 0 bhejo (user ne enter nahi kiya)
      model.outsideTread = outTread;
      model.middleTread  = 0;
      model.insideTread  = insTread;
      average = (outTread + insTread) / 2;
    } else {
      model.outsideTread = outTread;
      model.middleTread  = midTread;
      model.insideTread  = insTread;
      average = (outTread + midTread + insTread) / 3;
    }

    model.averageTreadDepth = average;
    model.currentTreadDepth = average;

    // --- Step 4: Financials ---
    model.purchaseCost = double.tryParse(purchaseCost.text) ?? 0;
    model.casingValue = double.tryParse(casingValue.text) ?? 0;
    model.fillCost = double.tryParse(fillCost.text) ?? 0;
    model.repairCost = double.tryParse(repairCost.text) ?? 0;
    model.retreadCost = double.tryParse(retreadCost.text) ?? 0;
    model.warrantyAdjustment = double.tryParse(warrantyAdjustment.text) ?? 0;
    model.costAdjustment = double.tryParse(costAdjustment.text) ?? 0;
    model.soldAmount = double.tryParse(soldAmount.text) ?? 0;
    model.netCost = double.tryParse(netCost.text) ?? 0;
  }

  Future<void> updateTyre() async {
    if (isSubmitting.value) return;
    if (!formKey.currentState!.validate()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          "Invalid Form",
          "Please fix errors",
          snackPosition: SnackPosition.BOTTOM,
        );
      });
      return;
    }

    try {
      isSubmitting.value = true;

      final String? parentAccountId = await SecureStorage.getParentAccountId();
      final String? locationId = await SecureStorage.getLocationId();

      if (parentAccountId == null || parentAccountId.isEmpty) {
        isSubmitting.value = false;
        Get.snackbar(
          "Error",
          "Parent Account not selected",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      if (locationId == null || locationId.isEmpty) {
        isSubmitting.value = false;
        Get.snackbar(
          "Error",
          "Location not selected",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      bindToModel();
      model.parentAccountId = int.parse(parentAccountId);
      model.locationId = int.parse(locationId);
      model.isEditable = true;
      model.tireId = tireId;

      // 🔥 CRITICAL OFFLINE RESOLUTION INTERCEPTOR LOCK FOR VEHICLE RELATIONSHIPS
      if (model.vehicleId != null &&
          model.vehicleId!.toString().startsWith('-')) {
        final prefs = await SharedPreferences.getInstance();
        final realVId = prefs.getInt('vehicle_real_id_${model.vehicleId}');
        if (realVId != null && realVId > 0) {
          model.vehicleId = realVId;

        }
      }

      final bool savedOnline = await EditTyreService.updateTyre(model);
      final bool savedOffline = !savedOnline;

      final double currentOut = double.tryParse(outsideTread.text) ?? model.outsideTread ?? 0.0;
      final double currentMid = double.tryParse(middleTread.text) ?? model.middleTread ?? 0.0;
      final double currentIn = double.tryParse(insideTread.text) ?? model.insideTread ?? 0.0;
      final double currentPress = model.currentPressure ?? 0.0;
      final double currentM = double.tryParse(currentKm.text) ?? model.currentMiles ?? 0.0;
      final String currentUnit = MeasurementHelper.isMetric ? 'Metric' : 'Imperial';
      final String sn = tireSerialNo.text.trim();

      if (tireId != null && tireId! > 0) {
        TyreUnitHistory.recordRawReadings(
          tireId: tireId!,
          outside: currentOut,
          middle: currentMid,
          inside: currentIn,
          pressure: currentPress,
          miles: currentM,
          percentageWorn: model.percentageWorn,
          treadUnit: currentUnit,
          pressureUnit: MeasurementHelper.pressureLabel,
          distanceUnit: MeasurementHelper.distanceLabel,
        );
      }
      if (sn.isNotEmpty) {
        TyreUnitHistory.recordRawReadings(
          tireId: sn,
          outside: currentOut,
          middle: currentMid,
          inside: currentIn,
          pressure: currentPress,
          miles: currentM,
          percentageWorn: model.percentageWorn,
          treadUnit: currentUnit,
          pressureUnit: MeasurementHelper.pressureLabel,
          distanceUnit: MeasurementHelper.distanceLabel,
        );
      }

      try {
        if (Get.isRegistered<AllTyreController>()) {
          final allTyreCtrl = Get.find<AllTyreController>();
          final idx = allTyreCtrl.allTyres.indexWhere(
                (t) => t.tireId == tireId,
          );
          if (idx != -1) {
            final old = allTyreCtrl.allTyres[idx];

            final midTreadVal = double.tryParse(middleTread.text) ?? 0;
            final outTreadVal =
                double.tryParse(outsideTread.text) ?? old.outsideTread ?? 0;
            final insTreadVal =
                double.tryParse(insideTread.text) ?? old.insideTread ?? 0;
            // ✅ noOfTreadDepthReadings ke hisaab se avg compute
            final int treadCnt = noOfTreadDepthReadings.value;
            final double midForAvg = treadCnt == 3 ? midTreadVal : 0;
            final double avgTread = treadCnt == 1
                ? outTreadVal
                : treadCnt == 2
                ? (outTreadVal + insTreadVal) / 2
                : (outTreadVal + midTreadVal + insTreadVal) / 3;

            allTyreCtrl.allTyres[idx] = TyreModel(
              tireId: old.tireId,
              tireSerialNo: tireSerialNo.text,
              brandNo: brandNo.text.isEmpty ? old.brandNo : brandNo.text,
              sizeName: sizeId.text.isEmpty ? old.sizeName : sizeId.text,
              sizeId: selectedSizeId.value > 0
                  ? selectedSizeId.value
                  : old.sizeId,
              typeName: typeId.text.isEmpty ? old.typeName : typeId.text,
              typeId: selectedTypeId.value > 0
                  ? selectedTypeId.value
                  : old.typeId,
              tireStatusName: () {
                if (selectedstatus.value > 0) {
                  final idx = statusIdList.indexOf(selectedstatus.value);
                  if (idx != -1 && idx < statusList.length) {
                    return statusList[idx];
                  }
                }
                return tireStatusId.text.isEmpty
                    ? old.tireStatusName
                    : tireStatusId.text;
              }(),
              vehicleId:
              model.vehicleId ??
                  old.vehicleId,
              vehicleNumber: old.vehicleNumber,
              wheelPosition: old.wheelPosition,
              dispositionId: selectedDispositionId.value > 0
                  ? selectedDispositionId.value
                  : old.dispositionId,
              dispositionName: old.dispositionName,
              dispositionGroupId: old.dispositionGroupId,
              manufacturerName: manufacturerId.text.isEmpty
                  ? old.manufacturerName
                  : manufacturerId.text,
              manufacturerId: selectedManufacturerId.value > 0
                  ? selectedManufacturerId.value
                  : old.manufacturerId,
              currentTreadDepth: avgTread,
              outsideTread: outTreadVal,
              middleTread: midForAvg,
              insideTread: insTreadVal,
              currentPressure: old.currentPressure,
              inspectionDate: old.inspectionDate,
              evaluationNo: evaluationNo.text.isEmpty
                  ? old.evaluationNo
                  : evaluationNo.text,
              lotNo: lotNo.text.isEmpty ? old.lotNo : lotNo.text,
              poNo: poNo.text.isEmpty ? old.poNo : poNo.text,
              mileageType: old.mileageType,
              currentHours:
              double.tryParse(currentHours.text) ?? old.currentHours,
              currentMiles: double.tryParse(currentKm.text) ?? old.currentMiles,
              originalTread:
              double.tryParse(originalTread.text) ?? old.originalTread,
              purchasedTread:
              double.tryParse(purchasedTread.text) ?? old.purchasedTread,
              removeAt: double.tryParse(removeAt.text) ?? old.removeAt,
              starRatingId: showStarRating.value
                  ? (starRating.value > 0 ? starRating.value : old.starRatingId)
                  : 0,
              plyId: showStarRating.value
                  ? 0
                  : (selectedPlyRatingId.value > 0
                  ? selectedPlyRatingId.value
                  : old.plyId),
              compoundId: selectedCompoundId.value > 0
                  ? selectedCompoundId.value
                  : old.compoundId,
              loadRatingId: selectedLoadRatingId.value > 0
                  ? selectedLoadRatingId.value
                  : old.loadRatingId,
              speedRatingId: selectedSpeedRatingId.value > 0
                  ? selectedSpeedRatingId.value
                  : old.speedRatingId,
              fillTypeId: selectedFillTypeId.value > 0
                  ? selectedFillTypeId.value
                  : old.fillTypeId,
              purchaseCost:
              double.tryParse(purchaseCost.text) ?? old.purchaseCost,
              casingValue: double.tryParse(casingValue.text) ?? old.casingValue,
              fillCost: double.tryParse(fillCost.text) ?? old.fillCost,
              repairCost: double.tryParse(repairCost.text) ?? old.repairCost,
              retreadCost: double.tryParse(retreadCost.text) ?? old.retreadCost,
              costAdjustment:
              double.tryParse(costAdjustment.text) ?? old.costAdjustment,
              netCost: double.tryParse(netCost.text) ?? old.netCost,
            );
            allTyreCtrl.allTyres.refresh();
            allTyreCtrl.reapplyFilters();
          }
        }
      } catch (_) {
      }


      try {
        if (Get.isRegistered<VehicleInspeController>()) {
          final vehicleCtrl = Get.find<VehicleInspeController>();
          final updatedHours = double.tryParse(currentHours.text) ?? 0.0;
          final updatedMiles = double.tryParse(currentKm.text) ?? 0.0;

          final tireIdx = vehicleCtrl.tires.indexWhere(
                (t) => t.tireId == tireId,
          );
          if (tireIdx != -1) {
            final old = vehicleCtrl.tires[tireIdx];
            vehicleCtrl.tires[tireIdx] = old.copyWith(
              currentHours: updatedHours,
              currentMiles: updatedMiles,
            );
            vehicleCtrl.tires.refresh();
          }
        }
      } catch (_) {
      }

      isSubmitting.value = false;

      String title = "Tyre Updated Successfully";
      String message =
          "Tyre with serial no: ${tireSerialNo.text} updated successfully.";

      Get.offAll(
            () => HomeView(),
        arguments: {
          "showSuccess": true,
          "serialNo": tireSerialNo.text,
          "module": "tyre",
          "type": "update",
          "savedOffline": savedOffline,
        },
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (savedOffline) {
          AppSnackbar.offlineSuccess(
            message,
            title: title,
          );
        } else {
          AppSnackbar.success(message, title: title);
        }
      });
    } catch (e) {
      isSubmitting.value = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          "Update Error",
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
      });
    }
  }

  void cancelDialog() {
    AppDialog.showConfirmDialog(
      title: "Cancel Request",
      message: "Are you sure you want to cancel? You will\n lose unsaved data.",
      okText: "Yes",
      onOk: () {
        Get.back(closeOverlays: true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offAllNamed(AppPages.HOME);
        });
      },
    );
  }

  Future<void> loadMasterData() async {
    try {
      final data = await _masterService.fetchMasterData();
      allTireSizes = data['tireSizes'] as List;
      allTypeList = data['tireTypes'] as List;

      final statusRaw = (data['tireStatus'] as List);
      List<String> names = [];
      List<int> ids = [];
      for (var e in statusRaw) {
        names.add(e['statusName']?.toString() ?? '');
        ids.add(int.tryParse(e['statusId'].toString()) ?? 0);
      }
      setStatusList(names, ids);

      final manufRaw = (data['tireManufacturers'] as List);
      manufacturerList.assignAll(
        manufRaw.map((e) => e['manufacturerName'].toString().toUpperCase()),
      );
      manufacturerIdList.assignAll(
        manufRaw.map((e) => (e['manufacturerId'] as num).toInt()),
      );

      final sizeRaw = (data['tireSizes'] as List);
      tireSizeList.assignAll(sizeRaw.map((e) => e['tireSizeName'].toString()));
      tireSizeIdList.assignAll(
        sizeRaw.map((e) => (e['tireSizeId'] as num).toInt()),
      );

      final typeRaw = (data['tireTypes'] as List);
      typeList.assignAll(typeRaw.map((e) => e['typeName'].toString()));
      typeIdList.assignAll(typeRaw.map((e) => (e['typeId'] as num).toInt()));

      final indRaw = (data['tireIndCodes'] as List);
      indCodeList.assignAll(indRaw.map((e) => e['codeName'].toString()));
      indCodeIdList.assignAll(indRaw.map((e) => (e['codeId'] as num).toInt()));

      final compRaw = (data['tireCompounds'] as List);
      compoundList.assignAll(compRaw.map((e) => e['compoundName'].toString()));
      compoundIdList.assignAll(
        compRaw.map((e) => (e['compoundId'] as num).toInt()),
      );

      final loadRaw = (data['tireLoadRatings'] as List);
      loadRatingList.assignAll(loadRaw.map((e) => e['ratingName'].toString()));
      loadRatingIdList.assignAll(
        loadRaw.map((e) => (e['ratingId'] as num).toInt()),
      );

      final speedRaw = (data['tireSpeedRatings'] as List);
      speedRatingList.assignAll(
        speedRaw.map((e) => e['speedRatingName'].toString()),
      );
      speedRatingIdList.assignAll(
        speedRaw.map((e) => (e['speedRatingId'] as num).toInt()),
      );

      final fillRaw = (data['tireFillTypes'] as List);
      fillTypeList.assignAll(fillRaw.map((e) => e['fillTypeName'].toString()));
      fillTypeIdList.assignAll(
        fillRaw.map((e) => (e['fillTypeId'] as num).toInt()),
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

  void _applyStarPlyToggle(String? sizeName) {
    if (sizeName != null && sizeName.toUpperCase().contains("R")) {
      showStarRating.value = true;
      ratingLabel.value = "Star Rating";
      plyRatingId.clear();
      selectedPlyRatingId.value = 0;
    } else {
      showStarRating.value = false;
      ratingLabel.value = "Ply Rating";
      starRating.value = 0;
      starRatingId.clear();
    }
    update();
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
    typeList.clear();
    typeIdList.clear();
    _applyStarPlyToggle(null);
    update();
  }

  Future<void> getTireTypes(int tireSizeId) async {
    final filtered = allTypeList
        .where((e) => e["tireSizeId"] == tireSizeId)
        .toList();
    typeList.assignAll(filtered.map((e) => e['typeName'].toString()).toList());
    typeIdList.assignAll(filtered.map((e) => e['typeId'] as int).toList());

    Map<String, dynamic>? sizeEntry;
    try {
      sizeEntry =
      allTireSizes.firstWhere((e) => e['tireSizeId'] == tireSizeId)
      as Map<String, dynamic>?;
    } catch (_) {
      sizeEntry = null;
    }
    _applyStarPlyToggle(sizeEntry?['tireSizeName']?.toString());
    update();
  }

  void setStarRating(int value) {
    starRating.value = value;
    starRatingId.text = value.toString();
    update();
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
    if (index == -1 || index >= nameList.length) {
      controller.clear();
      return;
    }
    controller.text = nameList[index];
    if (selectedId != null) selectedId.value = idList[index];
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
}