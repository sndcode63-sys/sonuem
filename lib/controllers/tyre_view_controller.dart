import 'package:emtrack/models/masterDataMobileModel/master_model.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:get/get.dart';
import '../models/tyre_view_model.dart';
import '../services/tyre_view_service.dart';
import '../models/tyre_model.dart';
import '../utils/mesurment_helper_class.dart';

class TyreViewController extends GetxController {
  final TyreViewService _service = TyreViewService();

  bool _disposed = false;

  RxBool isLoading = true.obs;
  Rx<TyreViewModel?> tyre = Rx<TyreViewModel?>(null);
  Rx<MasterModel?> masterData = Rx<MasterModel?>(null);

  final RxInt currentTabIndex = 0.obs;

  final RxInt noOfTreadDepthReadings = 3.obs;

  final distLabel = MeasurementHelper.distanceLabel;
  final int? tireId;

  TyreViewController({this.tireId});

  void _safeSetTyre(TyreViewModel? value) {
    if (_disposed) return;
    tyre.value = value;
  }

  void _safeSetMaster(MasterModel? value) {
    if (_disposed) return;
    masterData.value = value;
  }

  void _safeSetLoading(bool value) {
    if (_disposed) return;
    isLoading.value = value;
  }

  @override
  void onInit() {
    super.onInit();

    noOfTreadDepthReadings.value = SecureStorage.getNoOfTreadDepthReadings();

    final dynamic args = Get.arguments;

    if (args != null && args is TyreModel) {
      _loadInstantFromModel(args);
      return;
    }

    if (tireId != null && tireId! > 0) {
      fetchData(tireId!);
      return;
    }

    if (tireId != null && tireId! < 0) {
      _loadOfflineTyre(tireId!);
      return;
    }

    if (args != null && args is int) {
      if (args > 0) {
        fetchData(args);
      } else {
        _loadOfflineTyre(args);
      }
      return;
    }

    _safeSetLoading(false);
  }

  void _loadInstantFromModel(TyreModel m) {
    _safeSetTyre(TyreViewModel(
      tireId:             m.tireId,
      tireSerialNo:       m.tireSerialNo ?? '-',
      brandNo:            m.brandNo,
      manufacturerName:   m.manufacturerName,
      manufacturerId:     m.manufacturerId,
      sizeName:           m.sizeName,
      sizeId:             m.sizeId,
      typeName:           m.typeName,
      typeId:             m.typeId,
      tireStatusName:     m.tireStatusName,
      vehicleId:          m.vehicleId,
      vehicleNumber:      m.vehicleNumber,
      wheelPosition:      m.wheelPosition,
      outsideTread:       m.outsideTread,
      middleTread:        m.middleTread,
      insideTread:        m.insideTread,
      currentTreadDepth:  m.currentTreadDepth,
      currentPressure:    m.currentPressure,
      currentHours:       m.currentHours,
      currentMiles:       m.currentMiles,
      dispositionId:      m.dispositionId,
      dispositionName:    m.dispositionName,
      starRatingId:       m.starRatingId,
      plyId:              m.plyId,
      ratingName:         m.ratingName,
      compoundId:         m.compoundId,
      compoundName:       m.compoundName,
      indCodeId:          m.indCodeId,
      loadRatingId:       m.loadRatingId,
      speedRatingId:      m.speedRatingId,
      originalTread:      m.originalTread,
      purchasedTread:     m.purchasedTread,
      removeAt:           m.removeAt,
      percentageWorn:     m.percentageWorn,
      averageTreadDepth:  m.averageTreadDepth,
      warrantyAdjustment: m.warrantyAdjustment,
      costAdjustment:     m.costAdjustment,
      soldAmount:         m.soldAmount,
    ));
    _safeSetLoading(false);

    if (m.tireId != null && m.tireId! > 0) {
      _service.fetchTyreDetailsById(m.tireId!).then((fullDetail) {
        if (_disposed) return;
        _safeSetTyre(fullDetail);
      }).catchError((e) {
     });

      _service.fetchMasterData().then((md) {
        if (_disposed) return;
        _safeSetMaster(md);
      }).catchError((e) {
      });
    }
  }

  Future<void> fetchData(int tireId) async {
    try {
      final hiveTyre = OfflineHiveService.getTyreById(tireId);
      if (hiveTyre != null) {
        _safeSetTyre(_fromHive(hiveTyre));
        _safeSetLoading(false);
      }
    } catch (_) {
    }

    try {
      final results = await Future.wait([
        _service.fetchTyreDetailsById(tireId),
        _service.fetchMasterData(),
      ]);
      if (_disposed) return;
      _safeSetTyre(results[0] as TyreViewModel);
      _safeSetMaster(results[1] as MasterModel);
    } finally {
      _safeSetLoading(false);
    }
  }

  void _loadOfflineTyre(int tireId) {
    _safeSetLoading(true);
    try {
      final hiveTyre = OfflineHiveService.getTyreById(tireId);
      if (hiveTyre != null) {
        _safeSetTyre(_fromHive(hiveTyre));
        _loadMasterDataOffline();
      }
    } finally {
      _safeSetLoading(false);
    }
  }

  Future<void> _loadMasterDataOffline() async {
    try {
      final md = await _service.fetchMasterData();
      _safeSetMaster(md);
    } catch (_) {
    }
  }

  TyreViewModel _fromHive(dynamic h) {
    return TyreViewModel(
      tireId:             h.tireId,
      tireSerialNo:       h.serialNumber ?? '-',
      manufacturerName:   h.manufacturerName,
      manufacturerId:     h.manufacturerId,
      sizeName:           h.tireSizeName,
      sizeId:             h.tireSizeId,
      typeName:           h.tireTypeName ?? h.typeName,
      typeId:             h.tireTypeId,
      dispositionId:      h.dispositionId,
      dispositionName:    h.dispositionName,
      vehicleId:          h.vehicleId,
      wheelPosition:      h.wheelPosition,
      outsideTread:       h.outsideTread,
      middleTread:        h.middleTread,
      insideTread:        h.insideTread,
      currentTreadDepth:  h.currentTreadDepth,
      currentPressure:    h.currentPressure,
      currentHours:       h.currentHours,
      currentMiles:       h.currentMiles,
      brandNo:            h.brandNo,
      registeredDate:     h.registeredDate != null
          ? DateTime.tryParse(h.registeredDate!) : null,
      mileageType:        h.mileageType,
      tireStatusId:       h.tireStatusId,
      originalTread:      h.originalTread,
      purchasedTread:     h.purchasedTread,
      removeAt:           h.removeAt,
      starRatingId:       h.starRatingId,
      plyId:              h.plyId,
      indCodeId:          h.indCodeId,
      compoundId:         h.compoundId,
      loadRatingId:       h.loadRatingId,
      speedRatingId:      h.speedRatingId,
      purchaseCost:       h.purchaseCost,
      casingValue:        h.casingValue,
      fillTypeId:         h.fillTypeId,
      fillCost:           h.fillCost,
      repairCost:         h.repairCost,
      retreadCost:        h.retreadCost,
      warrantyAdjustment: h.warrantyAdjustment,
      costAdjustment:     h.costAdjustment,
      soldAmount:         h.soldAmount,
      netCost:            h.netCost,
      evaluationNo:       h.evaluationNo,
      lotNo:              h.lotNo,
      poNo:               h.poNo,
      percentageWorn:     h.percentageWorn,
      averageTreadDepth:  h.averageTreadDepth,
    );
  }


  String getTireStatusName(int? id, {String? fallbackName}) {
    if (masterData.value != null && id != null && id != 0) {
      try {
        final match = masterData.value!.tireStatus.where((e) => e.statusId == id);
        if (match.isNotEmpty) return match.first.statusName.toString();
      } catch (_) {}
    }
    return fallbackName?.isNotEmpty == true ? fallbackName! : "-";
  }

  String getManufacturerName(int id, {String? fallbackName}) {
    if (masterData.value != null && id != 0) {
      try {
        final m = masterData.value!.tireManufacturers.firstWhere((e) => e.manufacturerId == id);
        return m.manufacturerName;
      } catch (_) {}
    }
    return fallbackName?.isNotEmpty == true ? fallbackName! : "-";
  }

  String getTireSizeName(int id, {String? fallbackName}) {
    if (masterData.value != null && id != 0) {
      try {
        final t = masterData.value!.tireSizes.firstWhere((e) => e.tireSizeId == id);
        return t.tireSizeName;
      } catch (_) {}
    }
    return fallbackName?.isNotEmpty == true ? fallbackName! : "-";
  }

  String getStarRatingName(int? id, {String? fallbackName}) {
    if (masterData.value != null && id != null && id != 0) {
      final match = masterData.value!.starRating.where((e) => e.ratingId == id);
      if (match.isNotEmpty) return match.first.ratingName;
    }
    return fallbackName?.isNotEmpty == true ? fallbackName! : "-";
  }

  String getPlyRatingName(int? id, {String? fallbackName}) {
    if (id == null || id == 0 || id == 1123) {
      return fallbackName?.isNotEmpty == true ? fallbackName! : "-";
    }
    if (masterData.value != null) {
      final match = masterData.value!.plyRating.where((e) => e.ratingId == id);
      if (match.isNotEmpty) return match.first.ratingName;
    }
    return fallbackName?.isNotEmpty == true ? fallbackName! : "-";
  }

  String getTypeName(int id, {String? fallbackName}) {
    if (masterData.value != null && id != 0) {
      final match = masterData.value!.tireTypes.where((e) => e.typeId == id);
      if (match.isNotEmpty) return match.first.typeName;
    }
    return fallbackName?.isNotEmpty == true ? fallbackName! : "-";
  }

  String getIndCodeName(int id, {String? fallbackName}) {
    if (masterData.value != null && id != 0) {
      final match = masterData.value!.tireIndCodes.where((e) => e.codeId == id);
      if (match.isNotEmpty) return match.first.codeName;
    }
    return fallbackName?.isNotEmpty == true ? fallbackName! : "-";
  }

  String getCompoundName(int? id, {String? fallbackName}) {
    if (masterData.value != null && id != null && id != 0) {
      final match = masterData.value!.tireCompounds.where((e) => e.compoundId == id);
      if (match.isNotEmpty) return match.first.compoundName;
    }
    return fallbackName?.isNotEmpty == true ? fallbackName! : "-";
  }

  String getLoadRatingName(int? id, {String? fallbackName}) {
    if (masterData.value != null && id != null && id != 0) {
      final match = masterData.value!.tireLoadRatings.where((e) => e.ratingId == id);
      if (match.isNotEmpty) return match.first.ratingName;
    }
    return fallbackName?.isNotEmpty == true ? fallbackName! : "-";
  }

  String getFillTypeName(int? id, {String? fallbackName}) {
    if (masterData.value != null && id != null && id != 0) {
      final match = masterData.value!.tireFillTypes.where((e) => e.fillTypeId == id);
      if (match.isNotEmpty) return match.first.fillTypeName;
    }
    return fallbackName?.isNotEmpty == true ? fallbackName! : "-";
  }

  String getDispositionName(int? id, {String? fallbackName}) {
    if (masterData.value != null && id != null && id != 0) {
      final match = masterData.value!.tireDispositions.where((e) => e.dispositionId == id);
      if (match.isNotEmpty) return match.first.dispositionName.toString();
    }
    return fallbackName?.isNotEmpty == true ? fallbackName! : "-";
  }

  String getSpeedRatingName(int? id, {String? fallbackName}) {
    if (masterData.value != null && id != null && id != 0) {
      try {
        final match = masterData.value!.tireSpeedRatings.where((e) => e.speedRatingId == id);
        if (match.isNotEmpty) return match.first.speedRatingName;
      } catch (_) {}
    }
    return fallbackName?.isNotEmpty == true ? fallbackName! : "-";
  }

  String getTrackingMethod(String? mileageType) {
    if (mileageType == null || mileageType.isEmpty) return "-";
    switch (mileageType.toLowerCase()) {
      case "hours":
      case "1":
        return "Hours";
      case "distance":
      case "miles":
      case "2":
        return "Distance";
      case "both":
      case "3":
        return "Both";
      default:
        return mileageType;
    }
  }

  String getMultiTireSizeNames(dynamic idOrIds, {String? fallbackName}) {
    if (masterData.value == null) return fallbackName ?? "-";
    List<int> ids = [];
    if (idOrIds is List<int>) {
      ids = idOrIds;
    } else if (idOrIds is int && idOrIds != 0) {
      ids = [idOrIds];
    } else if (idOrIds is String && idOrIds.isNotEmpty) {
      ids = idOrIds
          .split(',')
          .map((e) => int.tryParse(e.trim()) ?? 0)
          .where((id) => id != 0)
          .toList();
    }
    if (ids.isEmpty) return fallbackName ?? "-";
    final names = <String>[];
    for (var id in ids) {
      try {
        final t = masterData.value!.tireSizes.firstWhere((e) => e.tireSizeId == id);
        names.add(t.tireSizeName);
      } catch (_) {}
    }
    return names.isNotEmpty ? names.join(", ") : (fallbackName ?? "-");
  }

  @override
  void onClose() {
    _disposed = true;
    super.onClose();
  }
}