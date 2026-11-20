class TyreViewModel {
  int? tireId;
  String? tireSerialNo;
  int? vehicleId;
  int? locationId;
  int? parentAccountId;
  String? brandNo;
  DateTime? registeredDate;
  String? mileageType;
  double? currentMiles;
  double? currentHours;
  int? dispositionId;
  int? tireStatusId;
  String? tireStatusName;
  String? dispositionName;
  String? manufacturerName;
  String? sizeName;
  String? typeName;
  String? compoundName;
  String? ratingName;
  String? wheelPosition;
  bool? isMountToRim;
  int? mountedRimId;
  String? mountedRimSerialNo;
  double? originalTread;
  double? purchasedTread;
  double? removeAt;
  double? outsideTread;
  double? middleTread;
  double? insideTread;
  double? averageTreadDepth;
  double? recommendedPressure;
  double? currentTreadDepth;
  double? currentPressure;
  double? percentageWorn;
  int? manufacturerId;
  int? sizeId;
  int? starRatingId;
  int? plyId;
  int? typeId;
  int? indCodeId;
  int? compoundId;
  int? loadRatingId;
  int? speedRatingId;
  double? purchaseCost;
  double? casingValue;
  int? fillTypeId;
  double? fillCost;
  double? repairCost;
  double? retreadCost;
  int? repairCount;
  int? retreadCount;
  double? costAdjustment;
  double? warrantyAdjustment;
  double? soldAmount;
  double? netCost;
  TireGraphData? tireGraphData;
  String? vehicleNumber;
  dynamic tireHistory;
  List<dynamic>? tireHistory1;
  String? createdBy;
  bool? isEditable;
  String? evaluationNo;
  String? lotNo;
  String? poNo;
  String? imagesLocation;

  TyreViewModel({
    this.tireId,
    this.tireSerialNo,
    this.vehicleId,
    this.locationId,
    this.parentAccountId,
    this.brandNo,
    this.registeredDate,
    this.mileageType,
    this.currentMiles,
    this.currentHours,
    this.dispositionId,
    this.tireStatusId,
    this.tireStatusName,
    this.dispositionName,
    this.manufacturerName,
    this.sizeName,
    this.typeName,
    this.compoundName,
    this.ratingName,
    this.wheelPosition,
    this.isMountToRim,
    this.mountedRimId,
    this.mountedRimSerialNo,
    this.originalTread,
    this.purchasedTread,
    this.removeAt,
    this.outsideTread,
    this.middleTread,
    this.insideTread,
    this.averageTreadDepth,
    this.recommendedPressure,
    this.currentTreadDepth,
    this.currentPressure,
    this.percentageWorn,
    this.manufacturerId,
    this.sizeId,
    this.starRatingId,
    this.plyId,
    this.typeId,
    this.indCodeId,
    this.compoundId,
    this.loadRatingId,
    this.speedRatingId,
    this.purchaseCost,
    this.casingValue,
    this.fillTypeId,
    this.fillCost,
    this.repairCost,
    this.retreadCost,
    this.repairCount,
    this.retreadCount,
    this.costAdjustment,
    this.warrantyAdjustment,
    this.soldAmount,
    this.netCost,
    this.tireGraphData,
    this.vehicleNumber,
    this.tireHistory,
    this.tireHistory1,
    this.createdBy,
    this.isEditable,
    this.evaluationNo,
    this.lotNo,
    this.poNo,
    this.imagesLocation,
  });

  factory TyreViewModel.fromJson(Map<String, dynamic> json) {
    double? safeDouble(dynamic v) =>
        v == null ? null : (v as num).toDouble();

    double safeDoubleZero(dynamic v) =>
        v == null ? 0.0 : (v as num).toDouble();

    String? parseBrandNo(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      if (s.isEmpty || s == '0') return null;
      return s;
    }

    return TyreViewModel(
      tireId: json['tireId'],
      tireSerialNo: json['tireSerialNo'],
      vehicleId: json['vehicleId'],
      locationId: json['locationId'],
      parentAccountId: json['parentAccountId'],
      brandNo: parseBrandNo(json['brandNo']),


      registeredDate: json["registeredDate"] != null
          ? _parseDateSafe(json["registeredDate"].toString())
          : null,

      mileageType: json['mileageType'],
      currentMiles: safeDoubleZero(json['currentMiles']),
      currentHours: safeDoubleZero(json['currentHours']),
      dispositionId: json['dispositionId'],
      tireStatusId: json['tireStatusId'],
      tireStatusName: json['tireStatusName']?.toString(),
      dispositionName: json['dispositionName']?.toString(),
      manufacturerName: json['manufacturerName']?.toString(),
      sizeName: json['sizeName']?.toString(),
      typeName: json['typeName']?.toString(),
      compoundName: json['compoundName']?.toString(),
      ratingName: json['ratingName']?.toString(),
      wheelPosition: json['wheelPosition'],
      isMountToRim: json['isMountToRim'] is bool
          ? json['isMountToRim']
          : (json['isMountToRim'] == 1),
      mountedRimId: json['mountedRimId'],
      mountedRimSerialNo: json['mountedRimSerialNo'],
      originalTread: safeDoubleZero(json['originalTread']),
      purchasedTread: safeDoubleZero(json['purchasedTread']),
      removeAt: safeDoubleZero(json['removeAt']),
      outsideTread: safeDouble(json['outsideTread']),
      middleTread: safeDouble(json['middleTread']),
      insideTread: safeDouble(json['insideTread']),
      averageTreadDepth: safeDouble(json['averageTreadDepth']),
      recommendedPressure: safeDouble(json['recommendedPressure']),
      currentTreadDepth: safeDoubleZero(json['currentTreadDepth']),
      currentPressure: safeDouble(json['currentPressure']),
      percentageWorn: safeDoubleZero(json['percentageWorn']).clamp(0.0, 100.0),
      manufacturerId: json['manufacturerId'],
      sizeId: json['sizeId'],
      starRatingId: json['starRatingId'],
      plyId: json['plyId'],
      typeId: json['typeId'],
      indCodeId: json['indCodeId'],
      compoundId: json['compoundId'],
      loadRatingId: json['loadRatingId'],
      speedRatingId: json['speedRatingId'],
      purchaseCost: safeDoubleZero(json['purchaseCost']),
      casingValue: safeDoubleZero(json['casingValue']),
      fillTypeId: json['fillTypeId'],
      fillCost: safeDoubleZero(json['fillCost']),
      repairCost: safeDoubleZero(json['repairCost']),
      retreadCost: safeDoubleZero(json['retreadCost']),
      repairCount: json['repairCount'],
      retreadCount: json['retreadCount'],
      costAdjustment: safeDoubleZero(json['costAdjustment']),
      warrantyAdjustment: safeDouble(json['warrantyAdjustment']),
      soldAmount: safeDoubleZero(json['soldAmount']),
      netCost: safeDoubleZero(json['netCost']),
      tireGraphData: json['tireGraphData'] != null
          ? TireGraphData.fromJson(
          json['tireGraphData'] as Map<String, dynamic>)
          : null,
      vehicleNumber: json['vehicleNumber'],
      tireHistory: json['tireHistory'],
      tireHistory1: List<dynamic>.from(json['tireHistory1'] ?? []),
      createdBy: json['createdBy'],
      isEditable: json['isEditable'],
      evaluationNo: json['evaluationNo'],
      lotNo: json['lotNo'],
      poNo: json['poNo'],
      imagesLocation: json['imagesLocation'],
    );
  }
}

class TireGraphData {
  List<dynamic>? treadDepthList;
  List<dynamic>? pressureList;
  List<dynamic>? costPerHourList;
  List<dynamic>? hoursPerTreadDepthList;
  List<dynamic>? milesPerTreadDepthList;

  TireGraphData({
    this.treadDepthList,
    this.pressureList,
    this.costPerHourList,
    this.hoursPerTreadDepthList,
    this.milesPerTreadDepthList,
  });

  factory TireGraphData.fromJson(Map<String, dynamic>? json) {
    return TireGraphData(
      treadDepthList: List<dynamic>.from(json?['treadDepthList'] ?? []),
      pressureList: List<dynamic>.from(json?['pressureList'] ?? []),
      costPerHourList: List<dynamic>.from(json?['costPerHourList'] ?? []),
      hoursPerTreadDepthList:
      List<dynamic>.from(json?['hoursPerTreadDepthList'] ?? []),
      milesPerTreadDepthList:
      List<dynamic>.from(json?['milesPerTreadDepthList'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "treadDepthList": treadDepthList,
      "pressureList": pressureList,
      "costPerHourList": costPerHourList,
      "hoursPerTreadDepthList": hoursPerTreadDepthList,
      "milesPerTreadDepthList": milesPerTreadDepthList,
    };
  }
}

DateTime? _parseDateSafe(String raw) {
  try {
    final datePart = raw.contains('T') ? raw.split('T')[0] : raw.split(' ')[0];
    final parts    = datePart.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  } catch (_) {
    return null;
  }
}