class TyreModel {
  final int? tireId;
  final String? tireSerialNo;
  final int? vehicleId;
  final String? vehicleNumber;
  final int? locationId;
  final String? locationName;
  final int? parentAccountId;
  final String? brandNo;
  final int? typeId;
  final int? sizeId;
  final String? sizeName;
  final String? typeName;
  final int? manufacturerId;
  final String? manufacturerName;
  final double? currentHours;
  final double? currentMiles;
  final double? currentTreadDepth;
  final double? averageTreadDepth;
  final double? percentageWorn;
  final double? originalTread;
  final double? purchasedTread;
  final double? removeAt;
  final String? mileageType;
  final int? dispositionId;
  final String? dispositionName;
  final int? tireStatusId;       // ✅ FIX: ADD KARO
  final String? tireStatusName;
  final int? dispositionGroupId;
  final bool? isMountToRim;
  final int? compoundId;
  final String? compoundName;
  final double? recommendedPressure;
  final double? currentPressure;
  final String? wheelPosition;
  final String? lotNo;
  final String? evaluationNo;
  final String? poNo;
  final String? ratingName;
  final int? plyId;
  final int? loadRatingId;
  final int? speedRatingId;
  final int? starRatingId;
  final int? indCodeId;
  final double? costAdjustment;
  final double? warrantyAdjustment;
  final double? soldAmount;
  final double? purchaseCost;
  final double? casingValue;
  final double? fillCost;
  final double? repairCost;
  final double? retreadCost;
  final double? netCost;
  final int? repairCount;
  final int? retreadCount;
  final int? fillTypeId;
  final int? typeOfTire;
  final String? compoundCode;
  final double? outsideTread;
  final double? middleTread;
  final double? insideTread;
  final String? comments;
  final int? casingConditionId;
  final int? wearConditionId;
  final DateTime? inspectionDate;
  final String? registeredDate;

  TyreModel({
    this.tireId,
    this.tireSerialNo,
    this.vehicleId,
    this.vehicleNumber,
    this.locationId,
    this.locationName,
    this.parentAccountId,
    this.brandNo,
    this.typeId,
    this.sizeId,
    this.sizeName,
    this.typeName,
    this.manufacturerId,
    this.manufacturerName,
    this.currentHours,
    this.currentMiles,
    this.currentTreadDepth,
    this.averageTreadDepth,
    this.percentageWorn,
    this.originalTread,
    this.purchasedTread,
    this.removeAt,
    this.mileageType,
    this.dispositionId,
    this.dispositionName,
    this.tireStatusId,       // ✅ FIX: ADD KARO
    this.tireStatusName,
    this.dispositionGroupId,
    this.isMountToRim,
    this.compoundId,
    this.compoundName,
    this.recommendedPressure,
    this.currentPressure,
    this.wheelPosition,
    this.lotNo,
    this.evaluationNo,
    this.poNo,
    this.ratingName,
    this.plyId,
    this.loadRatingId,
    this.speedRatingId,
    this.starRatingId,
    this.indCodeId,
    this.costAdjustment,
    this.warrantyAdjustment,
    this.soldAmount,
    this.purchaseCost,
    this.casingValue,
    this.fillCost,
    this.repairCost,
    this.retreadCost,
    this.netCost,
    this.repairCount,
    this.retreadCount,
    this.fillTypeId,
    this.typeOfTire,
    this.compoundCode,
    this.outsideTread,
    this.middleTread,
    this.insideTread,
    this.comments,
    this.casingConditionId,
    this.wearConditionId,
    this.inspectionDate,
    this.registeredDate,
  });

  factory TyreModel.fromJson(Map<String, dynamic> json) {
    return TyreModel(
      tireId:              _toInt(json['tireId']),
      tireSerialNo:        json['tireSerialNo']?.toString(),
      vehicleId:           _toInt(json['vehicleId']),
      vehicleNumber:       json['vehicleNumber']?.toString(),
      locationId:          _toInt(json['locationId']),
      locationName:        json['locationName']?.toString(),
      parentAccountId:     _toInt(json['parentAccountId']),
      brandNo:             json['brandNo']?.toString(),
      typeId:              _toInt(json['typeId']),
      sizeId:              _toInt(json['sizeId']),
      sizeName:            json['sizeName']?.toString(),
      typeName:            json['typeName']?.toString(),
      manufacturerId:      _toInt(json['manufacturerId']),
      manufacturerName:    json['manufacturerName']?.toString(),
      currentHours:        _toDouble(json['currentHours']),
      currentMiles:        _toDouble(json['currentMiles']),
      currentTreadDepth:   _toDouble(json['currentTreadDepth']),
      averageTreadDepth:   _toDouble(json['averageTreadDepth']),
      percentageWorn:      _toDouble(json['percentageWorn'] ?? json['PercentageWorn'] ?? json['percentWorn'] ?? json['Percentage'])?.clamp(0.0, 100.0),
      originalTread:       _toDouble(json['originalTread']),
      purchasedTread:      _toDouble(json['purchasedTread']),
      removeAt:            _toDouble(json['removeAt']),
      mileageType:         json['mileageType']?.toString(),
      dispositionId:       _toInt(json['dispositionId']),
      dispositionName:     json['dispositionName']?.toString(),
      tireStatusId:        _toInt(json['tireStatusId']),   // ✅ FIX: ADD KARO
      tireStatusName:      json['tireStatusName']?.toString(),
      dispositionGroupId:  _toInt(json['dispositionGroupId']),
      isMountToRim:        json['isMountToRim'] as bool?,
      compoundId:          _toInt(json['compoundId']),
      compoundName:        json['compoundName']?.toString(),
      compoundCode:        json['compoundCode']?.toString(),
      recommendedPressure: _toDouble(json['recommendedPressure']),
      currentPressure:     _toDouble(json['currentPressure']),
      wheelPosition:       json['wheelPosition']?.toString(),
      lotNo:               json['lotNo']?.toString(),
      evaluationNo:        json['evaluationNo']?.toString(),
      poNo:                json['poNo']?.toString(),
      ratingName:          json['ratingName']?.toString(),
      plyId:               _toInt(json['plyId']),
      loadRatingId:        _toInt(json['loadRatingId']),
      speedRatingId:       _toInt(json['speedRatingId']),
      starRatingId:        _toInt(json['starRatingId']),
      indCodeId:           _toInt(json['indCodeId']),
      costAdjustment:      _toDouble(json['costAdjustment']),
      warrantyAdjustment:  _toDouble(json['warrantyAdjustment']),
      soldAmount:          _toDouble(json['soldAmount']),
      purchaseCost:        _toDouble(json['purchaseCost']),
      casingValue:         _toDouble(json['casingValue']),
      fillCost:            _toDouble(json['fillCost']),
      repairCost:          _toDouble(json['repairCost']),
      retreadCost:         _toDouble(json['retreadCost']),
      netCost:             _toDouble(json['netCost']),
      repairCount:         _toInt(json['repairCount']),
      retreadCount:        _toInt(json['retreadCount']),
      fillTypeId:          _toInt(json['fillTypeId']),
      typeOfTire:          _toInt(json['typeOfTire']),
      outsideTread:        _toDouble(json['outsideTread']),
      middleTread:         _toDouble(json['middleTread']),
      insideTread:         _toDouble(json['insideTread']),
      comments:            json['comments']?.toString(),
      casingConditionId:   _toInt(json['casingConditionId']),
      wearConditionId:     _toInt(json['wearConditionId']),
      inspectionDate: json['inspectionDate'] != null
          ? DateTime.tryParse(json['inspectionDate'].toString())
          : null,
      registeredDate: json['registeredDate']?.toString(),
    );
  }

  TyreModel copyWith({
    int? tireId,
    String? tireSerialNo,
    int? vehicleId,
    String? vehicleNumber,
    int? locationId,
    String? locationName,
    int? parentAccountId,
    String? brandNo,
    int? typeId,
    int? sizeId,
    String? sizeName,
    String? typeName,
    int? manufacturerId,
    String? manufacturerName,
    double? currentHours,
    double? currentMiles,
    double? currentTreadDepth,
    double? averageTreadDepth,
    double? percentageWorn,
    double? originalTread,
    double? purchasedTread,
    double? removeAt,
    String? mileageType,
    int? dispositionId,
    String? dispositionName,
    int? tireStatusId,
    String? tireStatusName,
    int? dispositionGroupId,
    bool? isMountToRim,
    int? compoundId,
    String? compoundName,
    double? recommendedPressure,
    double? currentPressure,
    String? wheelPosition,
    String? lotNo,
    String? evaluationNo,
    String? poNo,
    String? ratingName,
    int? plyId,
    int? loadRatingId,
    int? speedRatingId,
    int? starRatingId,
    int? indCodeId,
    double? costAdjustment,
    double? warrantyAdjustment,
    double? soldAmount,
    double? purchaseCost,
    double? casingValue,
    double? fillCost,
    double? repairCost,
    double? retreadCost,
    double? netCost,
    int? repairCount,
    int? retreadCount,
    int? fillTypeId,
    int? typeOfTire,
    String? compoundCode,
    double? outsideTread,
    double? middleTread,
    double? insideTread,
    String? comments,
    int? casingConditionId,
    int? wearConditionId,
    DateTime? inspectionDate,
    String? registeredDate,
    bool clearVehicle = false,
  }) {
    return TyreModel(
      tireId: tireId ?? this.tireId,
      tireSerialNo: tireSerialNo ?? this.tireSerialNo,
      vehicleId: clearVehicle ? null : (vehicleId ?? this.vehicleId),
      vehicleNumber: clearVehicle ? null : (vehicleNumber ?? this.vehicleNumber),
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      parentAccountId: parentAccountId ?? this.parentAccountId,
      brandNo: brandNo ?? this.brandNo,
      typeId: typeId ?? this.typeId,
      sizeId: sizeId ?? this.sizeId,
      sizeName: sizeName ?? this.sizeName,
      typeName: typeName ?? this.typeName,
      manufacturerId: manufacturerId ?? this.manufacturerId,
      manufacturerName: manufacturerName ?? this.manufacturerName,
      currentHours: currentHours ?? this.currentHours,
      currentMiles: currentMiles ?? this.currentMiles,
      currentTreadDepth: currentTreadDepth ?? this.currentTreadDepth,
      averageTreadDepth: averageTreadDepth ?? this.averageTreadDepth,
      percentageWorn: percentageWorn ?? this.percentageWorn,
      originalTread: originalTread ?? this.originalTread,
      purchasedTread: purchasedTread ?? this.purchasedTread,
      removeAt: removeAt ?? this.removeAt,
      mileageType: mileageType ?? this.mileageType,
      dispositionId: dispositionId ?? this.dispositionId,
      dispositionName: dispositionName ?? this.dispositionName,
      tireStatusId: tireStatusId ?? this.tireStatusId,
      tireStatusName: tireStatusName ?? this.tireStatusName,
      dispositionGroupId: dispositionGroupId ?? this.dispositionGroupId,
      isMountToRim: isMountToRim ?? this.isMountToRim,
      compoundId: compoundId ?? this.compoundId,
      compoundName: compoundName ?? this.compoundName,
      recommendedPressure: recommendedPressure ?? this.recommendedPressure,
      currentPressure: currentPressure ?? this.currentPressure,
      wheelPosition: clearVehicle ? null : (wheelPosition ?? this.wheelPosition),
      lotNo: lotNo ?? this.lotNo,
      evaluationNo: evaluationNo ?? this.evaluationNo,
      poNo: poNo ?? this.poNo,
      ratingName: ratingName ?? this.ratingName,
      plyId: plyId ?? this.plyId,
      loadRatingId: loadRatingId ?? this.loadRatingId,
      speedRatingId: speedRatingId ?? this.speedRatingId,
      starRatingId: starRatingId ?? this.starRatingId,
      indCodeId: indCodeId ?? this.indCodeId,
      costAdjustment: costAdjustment ?? this.costAdjustment,
      warrantyAdjustment: warrantyAdjustment ?? this.warrantyAdjustment,
      soldAmount: soldAmount ?? this.soldAmount,
      purchaseCost: purchaseCost ?? this.purchaseCost,
      casingValue: casingValue ?? this.casingValue,
      fillCost: fillCost ?? this.fillCost,
      repairCost: repairCost ?? this.repairCost,
      retreadCost: retreadCost ?? this.retreadCost,
      netCost: netCost ?? this.netCost,
      repairCount: repairCount ?? this.repairCount,
      retreadCount: retreadCount ?? this.retreadCount,
      fillTypeId: fillTypeId ?? this.fillTypeId,
      typeOfTire: typeOfTire ?? this.typeOfTire,
      compoundCode: compoundCode ?? this.compoundCode,
      outsideTread: outsideTread ?? this.outsideTread,
      middleTread: middleTread ?? this.middleTread,
      insideTread: insideTread ?? this.insideTread,
      comments: comments ?? this.comments,
      casingConditionId: casingConditionId ?? this.casingConditionId,
      wearConditionId: wearConditionId ?? this.wearConditionId,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      registeredDate: registeredDate ?? this.registeredDate,
    );
  }
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString());
}