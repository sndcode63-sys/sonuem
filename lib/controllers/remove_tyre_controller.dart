import 'dart:convert';
import 'package:emtrack/inspection/vehicle_inspe_controller.dart';
import 'package:emtrack/inspection/vehicle_inspe_service.dart';
import 'package:emtrack/inspection/vehicle_inspe_view.dart';
import 'package:emtrack/inspection_approval/search.dart';
import 'package:emtrack/models/masterDataMobileModel/Tire_remove_reason_model.dart';
import 'package:emtrack/models/masterDataMobileModel/tire_desposition_model.dart';
import 'package:emtrack/models/remove_tyre_model.dart';
import 'package:emtrack/models/all_vehicle_account_model.dart';
import 'package:emtrack/models/tyre_model.dart';
import 'package:emtrack/services/inspection_service.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/services/remove_tyre_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/app_snackbar.dart';
import 'all_tyre_controller.dart';
import 'all_vehicles_controller.dart';

class RemoveTyreController extends GetxController {
  final service = RemoveTyreService();
  final _inspectionService = InspectionService();

  RxString vehicleNo = ''.obs;

  Rx<RemoveTyreModel> model = RemoveTyreModel(
    action: 'Remove',
    inspectionDate: DateTime.now().toIso8601String(),
    locationId: 0,
    parentAccountId: 0,
    vehicleId: 0,
    inspectionId: 0,
    tireId: 0,
    currentHours: 0.0,
    currentMiles: 0.0,
    tireSerialNo: '',
    outsideTread: 0.0,
    middleTread: 0.0,
    insideTread: 0.0,
    currentTreadDepth: 0.0,
    currentPressure: 0.0,
    pressureUnitId: 1,
    casingConditionId: 1,
    wearConditionId: 1,
    comments: '',
    removalReasonId: 0,
    dispositionId: 0,
    rimDispositionId: 0,
    wheelPosition: '',
    mountedRimId: 0,
    createdBy: 'mobile',
    pressureType: 'PSI',
    hoursAdjustToTire: 0.0,
    milesAdjustToTire: 0.0,
    isMobInstall: false,
  ).obs;

  RxList<TireRemovalReason> reasons = <TireRemovalReason>[].obs;
  RxList<TireDisposition> dispositions = <TireDisposition>[].obs;

  final Rxn<TireRemovalReason> selectedReason = Rxn<TireRemovalReason>();
  final TextEditingController reasonController = TextEditingController();
  final RxBool isSubmitting = false.obs;

  bool get isInspectionFlow {
    final rawArgs = Get.arguments;
    if (rawArgs is Map && rawArgs['isInspectionFlow'] == true) return true;
    return Get.isRegistered<VehicleInspeController>();
  }

  @override
  void onInit() {
    super.onInit();

    _loadMasterData().then((_) {
      if (model.value.dispositionId == 0 && dispositions.isNotEmpty) {
        final defaultDisp =
            dispositions.firstWhereOrNull((d) => d.dispositionId == 8) ??
                dispositions.first;
        selectDisposition(defaultDisp);
      }
    });

    final args = Get.arguments ?? {};

    vehicleNo.value =
        args['vehicleNo']?.toString() ??
            args['vehicleNumber']?.toString() ??
            args['vehicleId']?.toString() ??
            '';

    int resolvedVehicleId = 0;
    if (args['vehicleId'] is int) {
      resolvedVehicleId = args['vehicleId'];
    } else if (args['vehicleId'] != null) {
      resolvedVehicleId = int.tryParse(args['vehicleId'].toString()) ?? 0;
    }
    if (resolvedVehicleId == 0) {
      try {
        if (Get.isRegistered<VehicleInspeController>()) {
          final vic = Get.find<VehicleInspeController>();
          resolvedVehicleId = vic.model?.vehicleId ?? int.tryParse(vic.vehicleId.value) ?? 0;
        }
      } catch (_) {}
    }

    if (vehicleNo.value.isEmpty || vehicleNo.value == '0') {
      try {
        if (Get.isRegistered<VehicleInspeController>()) {
          final vic = Get.find<VehicleInspeController>();
          final vNum = vic.model?.vehicleNumber ?? vic.vehicleNumberCtrl.text;
          if (vNum.isNotEmpty) vehicleNo.value = vNum;
        }
      } catch (_) {}
    }

    if (resolvedVehicleId == 0 && vehicleNo.value.isNotEmpty) {
      try {
        final allVehs = OfflineHiveService.getAllVehicles();
        final match = allVehs.firstWhereOrNull((v) =>
        v.vehicleNumber.trim().toUpperCase() == vehicleNo.value.trim().toUpperCase());
        if (match != null && match.vehicleId > 0) {
          resolvedVehicleId = match.vehicleId;
        }
      } catch (_) {}
    }

    if (vehicleNo.value.isEmpty && resolvedVehicleId > 0) {
      try {
        final veh = OfflineHiveService.getVehicleById(resolvedVehicleId);
        if (veh != null && veh.vehicleNumber.isNotEmpty) {
          vehicleNo.value = veh.vehicleNumber;
        }
      } catch (_) {}
    }

    model.update((m) {
      m!.vehicleId = resolvedVehicleId;
      m.tireId = args['tireId'] ?? 0;
      m.wheelPosition = args['wheelPosition'] ?? '';
      m.tireSerialNo = args['tireSerialNo'] ?? '';
      m.brandNumber = args['brandNumber'] ?? '';
      m.currentHours = args['currentHours'] ?? 0.0;
      m.currentMiles = args['currentMiles'] ?? 0.0;
      m.outsideTread = args['outsideTread'] ?? 0.0;
      m.middleTread = args['middleTread'] ?? 0.0;
      m.insideTread = args['insideTread'] ?? 0.0;
      m.currentTreadDepth = args['currentTreadDepth'] ?? 0.0;
      m.currentPressure = args['currentPressure'] ?? 0.0;
      m.originalTread = (args['originalTread'] ?? 0.0).toDouble();
      m.removeAt = (args['removeAt'] ?? 0.0).toDouble();
    });
  }

  void selectReason(TireRemovalReason reason) {
    selectedReason.value = reason;
    reasonController.text = reason.reasonName;
    model.update((m) => m!.removalReasonId = reason.reasonId);
  }

  void selectDisposition(TireDisposition disposition) {
    model.update((m) {
      m!.dispositionId = disposition.dispositionId;
      m.dispositionName = disposition.dispositionName;
    });
  }

  Future<void> _loadMasterData() async {
    try {
      final master = await service.getMasterData();
      if (master != null) {
        reasons.assignAll(master.tireRemovalReasons);
        dispositions.assignAll(master.tireDispositions);
      }
    } catch (_) {}
  }

  int _resolveDispositionId(String name) {
    final normalized = name.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');
    if (normalized.contains('scrap')) return 1;
    if (normalized.contains('repair')) return 2;
    if (normalized.contains('retread')) return 3;
    if (normalized.contains('hold')) return 4;
    if (normalized.contains('mount') || normalized.contains('install')) return 7;
    if (normalized.contains('inventory')) return 8;
    return 8;
  }

  void _navigateAfterRemove() {
    final vehicleId = model.value.vehicleId;
    if (vehicleId != 0) {
      if (Get.isRegistered<VehicleInspeController>()) {
        Get.delete<VehicleInspeController>(force: true);
      }
      Get.back();
      Get.off(
            () => VehicleInspeView(),
        arguments: vehicleId,
        preventDuplicates: false,
      );
    } else {
      Get.back();
      Get.back();
    }
  }

  void _safeNavigateBack() {
    if (Get.isDialogOpen ?? false) Get.back();
    if (isInspectionFlow) {
      Get.back();
      Get.back();
    } else {
      _navigateAfterRemove();
    }
  }

  Future<int> _resolveToListTireId(int realTireId) async {
    if (Get.isRegistered<VehicleInspeController>()) {
      final ctrl = Get.find<VehicleInspeController>();
      final directFound = ctrl.tires.any((t) => t.tireId == realTireId);
      if (directFound) return realTireId;
    }

    if (realTireId < 0) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final realId = prefs.getInt('tyre_real_id_$realTireId');
        if (realId != null && realId > 0) {
          return realId;
        }
      } catch (_) {}
    }
    return realTireId;
  }

  Future<void> _removeFromVehicleController() async {
    try {
      if (!Get.isRegistered<VehicleInspeController>()) return;
      final vehicleCtrl = Get.find<VehicleInspeController>();

      final targetTireId = await _resolveToListTireId(model.value.tireId);

      final exists = vehicleCtrl.tires.any((t) => t.tireId == targetTireId);
      if (!exists) {
        return;
      }

      vehicleCtrl.tires.removeWhere((t) => t.tireId == targetTireId);
      vehicleCtrl.inspectionResponse.update((val) {
        val?.model?.installedTires?.removeWhere(
              (t) => t.tireId == targetTireId,
        );
      });
      vehicleCtrl.tires.refresh();
    } catch (_) {}
  }

  Future<void> _removeFromInspectionCache(int vId) async {
    try {
      final cacheKey = vId.toString();
      String? cached = OfflineHiveService.getInspectionCache(cacheKey);
      if (cached == null) return;

      final jsonData = jsonDecode(cached) as Map<String, dynamic>;
      final innerModel = jsonData['model'] as Map<String, dynamic>?;
      if (innerModel == null) return;

      final installedTires = innerModel['installedTires'] as List<dynamic>?;
      if (installedTires == null) return;

      int targetTireId = model.value.tireId;

      final directFound = installedTires.any(
            (t) => t is Map && t['tireId']?.toString() == targetTireId.toString(),
      );

      if (!directFound && targetTireId < 0) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final realId = prefs.getInt('tyre_real_id_$targetTireId');
          if (realId != null && realId > 0) {
            final foundByReal = installedTires.any(
                  (t) => t is Map && t['tireId']?.toString() == realId.toString(),
            );
            if (foundByReal) {
              targetTireId = realId;
            }
          }
        } catch (_) {}
      }

      final finalTargetId = targetTireId;
      installedTires.removeWhere(
            (t) => t is Map && t['tireId']?.toString() == finalTargetId.toString(),
      );
      innerModel['installedTires'] = installedTires;
      jsonData['model'] = innerModel;

      await OfflineHiveService.saveInspectionCache(
        vId.toString(),
        jsonEncode(jsonData),
      );
    } catch (_) {}
  }

  Future<void> _resolveModelIdsForQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final storedTireId = model.value.tireId;
      if (storedTireId < 0) {
        final realTireId = prefs.getInt('tyre_real_id_$storedTireId');
        if (realTireId != null && realTireId > 0) {
          model.update((m) => m!.tireId = realTireId);
        }
      }

      // vehicleId resolve
      final storedVehicleId = model.value.vehicleId;
      if (storedVehicleId < 0) {
        final realVehicleId = prefs.getInt('vehicle_real_id_$storedVehicleId');
        if (realVehicleId != null && realVehicleId > 0) {
          model.update((m) => m!.vehicleId = realVehicleId);
        }
      }
    } catch (_) {}
  }

  void _refreshAllVehicleTireCount(int vehicleId) {
    try {
      if (Get.isRegistered<AllVehicleController>()) {
        final allVehicleCtrl = Get.find<AllVehicleController>();
        final idx = allVehicleCtrl.vehicleList.indexWhere(
              (v) => v.vehicleId == vehicleId,
        );
        if (idx != -1) {
          final v = allVehicleCtrl.vehicleList[idx];
          final updatedCount = ((v.tireCount ?? 1) - 1).clamp(0, 9999);
          allVehicleCtrl.vehicleList[idx] = AccountVehicleModel(
            vehicleId: v.vehicleId,
            vehicleNumber: v.vehicleNumber,
            typeName: v.typeName,
            modelName: v.modelName,
            axleConfig: v.axleConfig,
            manufacturerName: v.manufacturerName,
            tireCount: updatedCount,
            locationId: v.locationId,
            assetNumber: v.assetNumber,
            currentHours: v.currentHours,
            currentMiles: v.currentMiles,
            lastRead: v.lastRead,
            isPendingSync: v.isPendingSync,
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

  Future<void> _refreshAllTyreDisposition({
    required int tireId,
    required int dispositionId,
    required String dispositionName,
  }) async {
    try {
      final resolvedName = dispositionName.isNotEmpty
          ? dispositionName
          : _dispositionIdToName(dispositionId);

      if (!Get.isRegistered<AllTyreController>()) {
        return;
      }
      final allTyreCtrl = Get.find<AllTyreController>();

      final idx = allTyreCtrl.allTyres.indexWhere((t) => t.tireId == tireId);
      if (idx == -1) {
        await OfflineHiveService.updateTyreDisposition(
          tireId: tireId,
          dispositionId: dispositionId,
          dispositionName: resolvedName,
          vehicleId: 0,
          wheelPosition: '',
        );
        return;
      }

      final old = allTyreCtrl.allTyres[idx];
      allTyreCtrl.allTyres[idx] = TyreModel(
        tireId: old.tireId,
        tireSerialNo: old.tireSerialNo,
        brandNo: old.brandNo,
        sizeName: old.sizeName,
        sizeId: old.sizeId,
        typeName: old.typeName,
        typeId: old.typeId,
        tireStatusName: resolvedName,
        vehicleId: null,
        vehicleNumber: null,
        wheelPosition: null,
        dispositionId: dispositionId,
        dispositionName: resolvedName,
        dispositionGroupId: old.dispositionGroupId,
        manufacturerName: old.manufacturerName,
        manufacturerId: old.manufacturerId,
        currentTreadDepth: old.currentTreadDepth,
        outsideTread: old.outsideTread,
        insideTread: old.insideTread,
        currentPressure: old.currentPressure,
        inspectionDate: old.inspectionDate,
        evaluationNo: old.evaluationNo,
        lotNo: old.lotNo,
        poNo: old.poNo,
        mileageType: old.mileageType,
        currentHours: old.currentHours,
        currentMiles: old.currentMiles,
        originalTread: old.originalTread,
        purchasedTread: old.purchasedTread,
        removeAt: old.removeAt,
        starRatingId: old.starRatingId,
        compoundId: old.compoundId,
        loadRatingId: old.loadRatingId,
        speedRatingId: old.speedRatingId,
        fillTypeId: old.fillTypeId,
        purchaseCost: old.purchaseCost,
        casingValue: old.casingValue,
        fillCost: old.fillCost,
        repairCost: old.repairCost,
        retreadCost: old.retreadCost,
        costAdjustment: old.costAdjustment,
        netCost: old.netCost,
      );
      allTyreCtrl.allTyres.refresh();
      allTyreCtrl.reapplyFilters();
    } catch (_) {}
  }

  String _dispositionIdToName(int id) {
    switch (id) {
      case 1:
        return 'Scrap';
      case 2:
        return 'Repair';
      case 3:
        return 'Retread';
      case 4:
        return 'On Hold';
      case 7:
        return 'Installed';
      case 8:
        return 'Inventory';
      default:
        return 'Inventory';
    }
  }

  // SUBMIT
  Future<void> submit() async {
    if (isSubmitting.value) return;

    if (model.value.dispositionId == 0 && model.value.dispositionName.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please select a disposition before submitting.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (model.value.removalReasonId == 0) {
      Get.snackbar(
        'Validation Error',
        'Please select a removal reason before submitting.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (model.value.tireId == 0) {
      Get.snackbar(
        'Error',
        'Invalid tire data. Please go back and try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSubmitting.value = true;
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Colors.red)),
      barrierDismissible: false,
    );

    try {
      final parentAccountIdStr = await SecureStorage.getParentAccountId();
      final locationIdStr = await SecureStorage.getLocationId();
      final parentAccountName = await SecureStorage.getParentAccountName();
      final locationName = await SecureStorage.getLocationName() ?? '';
      final requestorName = await SecureStorage.getUserProfileName() ??
          await SecureStorage.getUserName() ??
          'mobile';
      final grandParentAccountId =
      await SecureStorage.getProfileGrandParentAccountId();

      final m = model.value;
      final int? profileParentId = await SecureStorage.getProfileParentAccountId();
      final int fallbackParentId = int.tryParse(parentAccountIdStr ?? '') ?? 0;
      final int resolvedParentAccountId = (profileParentId != null && profileParentId > 0)
          ? profileParentId
          : fallbackParentId;

      m.parentAccountId = resolvedParentAccountId;
      m.locationId = int.tryParse(locationIdStr ?? '') ?? 0;
      if (m.locationId == 0) {
        try {
          if (Get.isRegistered<VehicleInspeController>()) {
            final vic = Get.find<VehicleInspeController>();
            m.locationId = vic.model?.locationId ?? 0;
          }
        } catch (_) {}
      }

      m.action = 'Remove';
      m.inspectionDate = DateTime.now().toIso8601String();
      m.isMobInstall = true;
      m.createdBy = parentAccountName ?? 'mobile';

      if (m.dispositionId == 0 || m.dispositionId == 7) {
        if (m.dispositionName.isNotEmpty) {
          m.dispositionId = _resolveDispositionId(m.dispositionName);
        }
      }
      if (m.dispositionId == 0) {
        m.dispositionId = 8;
      }
      if (m.dispositionName.isEmpty || m.dispositionName.toLowerCase().contains('mount')) {
        m.dispositionName = _dispositionIdToName(m.dispositionId);
      }

      if (m.vehicleId == 0) {
        try {
          if (Get.isRegistered<VehicleInspeController>()) {
            final vic = Get.find<VehicleInspeController>();
            final vId = vic.model?.vehicleId ?? int.tryParse(vic.vehicleId.value) ?? 0;
            if (vId > 0) {
              m.vehicleId = vId;
            }
          }
        } catch (_) {}
      }

      if (m.vehicleId == 0 && vehicleNo.value.isNotEmpty) {
        try {
          final allVehs = OfflineHiveService.getAllVehicles();
          final match = allVehs.firstWhereOrNull((v) =>
          v.vehicleNumber.trim().toUpperCase() == vehicleNo.value.trim().toUpperCase());
          if (match != null && match.vehicleId > 0) {
            m.vehicleId = match.vehicleId;
          }
        } catch (_) {}
      }

      if (vehicleNo.value.isEmpty && m.vehicleId > 0) {
        try {
          final veh = OfflineHiveService.getVehicleById(m.vehicleId);
          if (veh != null && veh.vehicleNumber.isNotEmpty) {
            vehicleNo.value = veh.vehicleNumber;
          }
        } catch (_) {}
      }

      m.rimDispositionId = m.dispositionId;

      if (m.brandNumber.isEmpty) m.brandNumber = 'N/A';
      if (m.outsideTread == 0.0 && m.insideTread > 0) {
        m.outsideTread = m.insideTread;
      }
      if (m.originalTread == 0.0) m.originalTread = m.outsideTread;

      model.refresh();

      final payload = model.value.toJson();

      // Check approval workflow:
      // - EMTUSER with workflow disabled OR workflow enabled without approver -> TEMP API
      // - EMTUSER with workflow enabled AND approver -> MAIN API
      // - All other roles (Super Admin, Admin, EMTCADMIN, etc.) -> MAIN API
      final userRole = await SecureStorage.getUserProfileRole();
      final bool isEmtUser = (userRole ?? '').trim().toUpperCase() == 'EMTUSER';
      final bool isWorkflowEnabled = await SecureStorage.getApprovalWorkflowEnabled();
      bool isApprover = false;
      if (isEmtUser) {
        isApprover = await SecureStorage.getIsApprover();
      }
      final bool shouldUseTempApi = isEmtUser && (!isWorkflowEnabled || !isApprover);

      if (shouldUseTempApi) {
        // 🔒 APPROVAL FLOW: Tyre removal must be submitted to the temporary approval API
        // (SaveVehicleFootPrintDetails_Temp) with action: "Remove".
        final nowIso = DateTime.now().toIso8601String();

        // Resolve tyre details from cache if available
        int resolvedSizeId = 0;
        String resolvedSizeName = '';
        int resolvedTypeId = 0;
        String resolvedTypeName = '';
        int resolvedMfgId = 0;
        String resolvedMfgName = '';

        try {
          final cachedStr = OfflineHiveService.getTireDetailCache(m.tireId);
          if (cachedStr != null) {
            final decoded = jsonDecode(cachedStr) as Map<String, dynamic>;
            final inner = decoded['model'] as Map<String, dynamic>?;
            if (inner != null) {
              resolvedSizeId = inner['sizeId'] is int ? inner['sizeId'] : int.tryParse(inner['sizeId']?.toString() ?? '') ?? 0;
              resolvedSizeName = inner['sizeName']?.toString() ?? '';
              resolvedTypeId = inner['typeId'] is int ? inner['typeId'] : int.tryParse(inner['typeId']?.toString() ?? '') ?? 0;
              resolvedTypeName = inner['typeName']?.toString() ?? '';
              resolvedMfgId = inner['manufacturerId'] is int ? inner['manufacturerId'] : int.tryParse(inner['manufacturerId']?.toString() ?? '') ?? 0;
              resolvedMfgName = inner['manufacturerName']?.toString() ?? '';
            }
          }
        } catch (_) {}

        if (Get.isRegistered<VehicleInspeController>()) {
          try {
            final vic = Get.find<VehicleInspeController>();
            final existingTire = vic.tires.firstWhereOrNull((t) => t.tireId == m.tireId);
            if (existingTire != null) {
              if (resolvedSizeId == 0) resolvedSizeId = existingTire.sizeId ?? 0;
              if (resolvedSizeName.isEmpty) resolvedSizeName = existingTire.sizeName ?? '';
              if (resolvedTypeId == 0) resolvedTypeId = existingTire.typeId ?? 0;
              if (resolvedTypeName.isEmpty) resolvedTypeName = existingTire.typeName ?? '';
              if (resolvedMfgId == 0) resolvedMfgId = existingTire.manufacturerId ?? 0;
              if (resolvedMfgName.isEmpty) resolvedMfgName = existingTire.manufacturerName ?? '';
            }
          } catch (_) {}
        }

        final Map<String, dynamic> tireRecord = {
          "tireId": m.tireId,
          "locationId": m.locationId,
          "parentAccountId": m.parentAccountId,
          "tireSerialNo": m.tireSerialNo,
          "registeredDate": nowIso,
          "manufacturerId": resolvedMfgId,
          "typeId": resolvedTypeId,
          "sizeId": resolvedSizeId,
          "sizeName": resolvedSizeName,
          "typeName": resolvedTypeName,
          "currentHours": m.currentHours,
          "currentMiles": m.currentMiles,
          "wheelPosition": m.wheelPosition,
          "percentageWorn": 0.0,
          "wearNonSkid": null,
          "currentTreadDepth": m.currentTreadDepth,
          "currentPressure": m.currentPressure,
          "wearConditionId": m.wearConditionId > 0 ? m.wearConditionId : null,
          "casingConditionId": m.casingConditionId > 0 ? m.casingConditionId : null,
          "mountedRimId": m.mountedRimId > 0 ? m.mountedRimId : null,
          "outsideTread": m.outsideTread,
          "middleTread": m.middleTread,
          "insideTread": m.insideTread,
          "originalTread": m.originalTread,
          "removeAt": m.removeAt,
          "comments": m.comments.isNotEmpty ? m.comments : null,
          "inspectionDate": nowIso,
          "imagesLocation": m.imagesLocation.isNotEmpty ? m.imagesLocation : null,
          "brandNo": m.brandNumber,
          "dispositionId": (m.dispositionId != 0 && m.dispositionId != 7) ? m.dispositionId : 8,
          "dispositionName": (m.dispositionName.isNotEmpty && !m.dispositionName.toLowerCase().contains('mount'))
              ? m.dispositionName
              : _dispositionIdToName((m.dispositionId != 0 && m.dispositionId != 7) ? m.dispositionId : 8),
          "rimDispositionId": (m.dispositionId != 0 && m.dispositionId != 7) ? m.dispositionId : 8,
          "createdBy": requestorName,
          "manufacturerName": resolvedMfgName,
          "pressureType": m.pressureType,
          "vehicleId": m.vehicleId,
          "removalReasonId": m.removalReasonId > 0 ? m.removalReasonId : 1,
          "cPtabValue": 0,
          "outsideTabValue": 0,
          "middleTabValue": 0,
          "insideTabValue": 0,
          "vehicleNumber": vehicleNo.value,
          "maxIn": 0,
          "maxMid": 0,
          "maxOut": 0,
          "minTread": 0,
          "action": "Remove",
          "actionType": "Remove",
          "isRemoved": true,
          "IsRemoved": true,
        };

        final Map<String, dynamic> vehicleEntry = {
          "vehicleId": m.vehicleId,
          "vehicleNumber": vehicleNo.value,
          "inspectionDate": nowIso,
          "currentHours": m.currentHours,
          "currentMiles": m.currentMiles,
          "action": "UpdateHoursEditTire",
          "locationId": m.locationId,
          "parentAccountId": m.parentAccountId,
        };

        final Map<String, dynamic> footprintPayload = {
          "inspectionList": [tireRecord],
          "tireList": [tireRecord],
          "vehicleList": [vehicleEntry],
          "Status": {
            "inspectionStatusId": 0,
            "inspectionTypeId": 1,
            "inspectionId": 0,
            "grandParentAccountId": grandParentAccountId ?? 0,
            "statusId": 1, // Pending
            "statusUpdatedBy": "",
            "statusUpdatedDate": "",
            "comments": m.comments,
            "createdBy": requestorName,
            "createdDate": nowIso,
            "modifiedBy": null,
            "modifiedDate": null,
          },
        };

        // ✅ SINGLE-SUBMISSION FIX:
        // Agar Vehicle Inspection screen khuli hai (isi vehicle ki), to remove
        // ko sirf LOCAL stage karo (removedTires / pendingRemovePayloads).
        // Temp API ek hi baar, Vehicle Inspection Submit par jayegi (Remove
        // action ke saath batch me). Warna ek hi remove ke liye 2 temp entries
        // bante the (ek yahan se, ek inspection submit se).
        bool stageOnly = false;
        try {
          if (Get.isRegistered<VehicleInspeController>()) {
            final vic = Get.find<VehicleInspeController>();
            final int vicVehicleId =
                vic.model?.vehicleId ?? int.tryParse(vic.vehicleId.value) ?? 0;
            stageOnly = m.vehicleId > 0 && vicVehicleId == m.vehicleId;
          }
        } catch (_) {}

        InspectionSubmitResult result;
        if (stageOnly) {
          result = InspectionSubmitResult(success: true, offline: false);
        } else {
          final inspeService = VehicleInspeService();
          result =
          await inspeService.submitApprovalFlowInspection(footprintPayload);
        }

        if (!result.offline && !result.success) {
          if (Get.isDialogOpen ?? false) Get.back();
          Get.snackbar(
            'Submission Failed',
            result.errorMessage ?? 'Failed to submit tyre removal for approval.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }

        // Mark tire as recently removed and update caches
        OfflineHiveService.markTireAsRecentlyRemoved(m.tireId);
        await _removeFromVehicleController();
        await _removeFromInspectionCache(m.vehicleId);
        _refreshAllVehicleTireCount(m.vehicleId);

        final resolvedDispName = m.dispositionName.isNotEmpty
            ? m.dispositionName
            : _dispositionIdToName(m.dispositionId);

        await _refreshAllTyreDisposition(
          tireId: m.tireId,
          dispositionId: m.dispositionId,
          dispositionName: resolvedDispName,
        );
        await OfflineHiveService.updateTyreDisposition(
          tireId: m.tireId,
          dispositionId: m.dispositionId,
          dispositionName: resolvedDispName,
          vehicleId: 0,
          wheelPosition: '',
        );

        // Update local SharedPreferences pending tires list so vehicle.dart immediately reflects removal
        // (stageOnly me skip: ye key sirf Vehicle Inspection Submit likhega, warna count double hota hai)
        if (!stageOnly) {
          try {
            final prefs = await SharedPreferences.getInstance();
            final candidateKeys = [
              'pending_inspection_tires_${m.vehicleId}',
              if (vehicleNo.value.isNotEmpty) 'pending_inspection_tires_${vehicleNo.value}',
            ];
            for (final k in candidateKeys) {
              List<dynamic> existingPendingList = [];
              final raw = prefs.getString(k);
              if (raw != null && raw.isNotEmpty) {
                final dec = jsonDecode(raw);
                if (dec is List) existingPendingList = dec;
              }
              existingPendingList.removeWhere(
                    (item) => item is Map && (item['tireId'] == m.tireId || (m.wheelPosition.isNotEmpty && item['wheelPosition'] == m.wheelPosition)),
              );
              existingPendingList.add(tireRecord);
              await prefs.setString(k, jsonEncode(existingPendingList));
            }
          } catch (_) {}
        }

        // If VehicleInspeController is registered, remove it in memory too
        if (Get.isRegistered<VehicleInspeController>()) {
          try {
            final vic = Get.find<VehicleInspeController>();
            vic.removeInstalledTyreLocally(model.value, payload: payload);
          } catch (_) {}
        }

        // Refresh IWSearchController if registered
        try {
          if (Get.isRegistered<IWSearchController>(tag: 'iw_search')) {
            Get.find<IWSearchController>(tag: 'iw_search').refreshData();
          }
        } catch (_) {}

        _safeNavigateBack();

        if (stageOnly) {
          AppSnackbar.success(
            'Tire with Serial No: ${m.tireSerialNo} marked for removal. Submit the vehicle inspection to send it for approval.',
            title: 'Tire Removal Staged',
          );
        } else if (result.offline) {
          AppSnackbar.offlineSuccess(
            'Tire with Serial No: ${m.tireSerialNo} removal saved offline for approval.',
            title: 'Tire Removal Queued',
          );
        } else {
          AppSnackbar.success(
            'Tire with Serial No: ${m.tireSerialNo} submitted for removal approval.',
            title: 'Tire Removal Submitted',
          );
        }
        return;
      }

      bool apiSuccess = false;
      bool savedOffline = false;
      try {
        apiSuccess = await service.submitRemoveTyre(payload);
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('Saved offline') || msg.contains('offline')) {
          savedOffline = true;
        } else {
          if (Get.isDialogOpen ?? false) Get.back();
          Get.snackbar(
            'Error',
            'Remove failed: $e',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
      }

      if (savedOffline) {
        await _resolveModelIdsForQueue();

        final resolvedDispName = model.value.dispositionName.isNotEmpty
            ? model.value.dispositionName
            : _dispositionIdToName(model.value.dispositionId);

        await _removeFromVehicleController();
        if (Get.isRegistered<VehicleInspeController>()) {
          try {
            final vic = Get.find<VehicleInspeController>();
            vic.removeInstalledTyreLocally(model.value, payload: payload);
          } catch (_) {}
        }
        await _removeFromInspectionCache(model.value.vehicleId);
        _refreshAllVehicleTireCount(model.value.vehicleId);
        await _refreshAllTyreDisposition(
          tireId: model.value.tireId,
          dispositionId: model.value.dispositionId,
          dispositionName: resolvedDispName,
        );
        await OfflineHiveService.updateVehicleTireCount(
          model.value.vehicleId,
          -1,
        );
        await OfflineHiveService.updateTyreDisposition(
          tireId: model.value.tireId,
          dispositionId: model.value.dispositionId,
          dispositionName: resolvedDispName,
          vehicleId: 0,
          wheelPosition: '',
        );

        _safeNavigateBack();
        AppSnackbar.offlineSuccess(
          'Tire with Serial No: ${model.value.tireSerialNo} removed successfully from Vehicle ${vehicleNo.value}',
          title: 'Tire Removed Successfully',
        );
        return;
      }

      if (apiSuccess) {
        final serialNo = model.value.tireSerialNo;
        final vehicleId = model.value.vehicleId;
        final vehicleNumber = vehicleNo.value;
        final resolvedDispName = model.value.dispositionName.isNotEmpty
            ? model.value.dispositionName
            : _dispositionIdToName(model.value.dispositionId);

        await _removeFromVehicleController();
        if (Get.isRegistered<VehicleInspeController>()) {
          try {
            final vic = Get.find<VehicleInspeController>();
            vic.removeInstalledTyreLocally(model.value, payload: payload);
          } catch (_) {}
        }
        await _removeFromInspectionCache(vehicleId);
        _refreshAllVehicleTireCount(vehicleId);
        await _refreshAllTyreDisposition(
          tireId: model.value.tireId,
          dispositionId: model.value.dispositionId,
          dispositionName: resolvedDispName,
        );
        await OfflineHiveService.updateVehicleTireCount(
          vehicleId,
          -1,
        );
        await OfflineHiveService.updateTyreDisposition(
          tireId: model.value.tireId,
          dispositionId: model.value.dispositionId,
          dispositionName: resolvedDispName,
          vehicleId: 0,
          wheelPosition: '',
        );

        try {
          if (Get.isRegistered<AllTyreController>()) {
            Get.find<AllTyreController>().reapplyFilters();
          }
        } catch (_) {}

        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(
            'cache_protected_$vehicleId',
            DateTime.now().millisecondsSinceEpoch,
          );
          final candidateKeys = [
            'pending_inspection_tires_$vehicleId',
            if (vehicleNo.value.isNotEmpty) 'pending_inspection_tires_${vehicleNo.value}',
          ];
          for (final k in candidateKeys) {
            final raw = prefs.getString(k);
            if (raw != null && raw.isNotEmpty) {
              final dec = jsonDecode(raw);
              if (dec is List) {
                dec.removeWhere((item) => item is Map && (item['tireId'] == model.value.tireId || (model.value.wheelPosition.isNotEmpty && item['wheelPosition'] == model.value.wheelPosition)));
                await prefs.setString(k, jsonEncode(dec));
              }
            }
          }
        } catch (_) {}

        _safeNavigateBack();
        AppSnackbar.success(
          'Tire with Serial No: Tire $serialNo removed successfully from Vehicle $vehicleNumber\n\nVehicle with ID: Vehicle $vehicleNumber Inspected successfully',
          title: 'Tire Removed Successfully',
        );
      } else {
        final hivePayload = {
          'vehicleId': model.value.vehicleId.toString(),
          'vehicleNumber': vehicleNo.value,
          'accountName': parentAccountName ?? '',
          'locationName': locationName,
          'parentAccountId': model.value.parentAccountId,
          'locationId': model.value.locationId,
          'inspectionDate': DateTime.now().toIso8601String(),
          'approverName': '',
          'requestorName': requestorName,
          'comments': model.value.comments,
          'status': 'A',
          'action': 'Remove',
          'approverEmail': '',
          'inspectedTyreCount': 1,
          'totalTyreCount': 1,
          'isSynced': false,
        };

        await _inspectionService.saveInspectionOffline(hivePayload);
        await _removeFromVehicleController();
        if (Get.isRegistered<VehicleInspeController>()) {
          try {
            final vic = Get.find<VehicleInspeController>();
            vic.removeInstalledTyreLocally(model.value, payload: payload);
          } catch (_) {}
        }
        await _removeFromInspectionCache(model.value.vehicleId);

        _safeNavigateBack();
        Get.snackbar(
          'Saved Offline',
          'Remove saved locally. Will sync when internet available.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        'Error',
        'Check connection and try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    reasonController.dispose();
    super.onClose();
  }
}