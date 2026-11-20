class VehicleInspectionResponse {
  String? message;
  bool? didError;
  String? errorMessage;
  int? httpStatusCode;
  VehicleInspectionModel? model;

  VehicleInspectionResponse({
    this.message,
    this.didError,
    this.errorMessage,
    this.httpStatusCode,
    this.model,
  });

  factory VehicleInspectionResponse.fromJson(Map<String, dynamic> json) {
    return VehicleInspectionResponse(
      message: json['message'],
      didError: json['didError'],
      errorMessage: json['errorMessage'],
      httpStatusCode: json['httpStatusCode'],
      model: json['model'] != null
          ? VehicleInspectionModel.fromJson(json['model'])
          : null,
    );
  }

  // ✅ Added toJson
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'didError': didError,
      'errorMessage': errorMessage,
      'httpStatusCode': httpStatusCode,
      'model': model?.toJson(),
    };
  }
}

class VehicleInspectionModel {
  int? vehicleId;
  int? locationId;
  String? vehicleNumber;
  String? vehicleManufacturer;
  String? vehicleType;
  String? vehicleModel;
  String? vehicleMileageType;
  String? axleConfig;
  int? axleConfigId;
  String? tireSize;
  int? tireSizeId;
  double? lastRecordedHours;
  double? lastRecordedMiles;
  String? lastRecordedDate;
  String? comments;
  List<InstalledTire>? installedTires;
  List<dynamic>? installedRims;
  String? lastUpdatedDate;
  bool? hasMultipleTireSizes;
  dynamic multipleTireSizeIds;
  String? multipleTireSizeNames;
  dynamic imagesLocation;

  VehicleInspectionModel({
    this.vehicleId,
    this.locationId,
    this.vehicleNumber,
    this.vehicleManufacturer,
    this.vehicleType,
    this.vehicleModel,
    this.vehicleMileageType,
    this.axleConfig,
    this.axleConfigId,
    this.tireSize,
    this.tireSizeId,
    this.lastRecordedHours,
    this.lastRecordedMiles,
    this.lastRecordedDate,
    this.comments,
    this.installedTires,
    this.installedRims,
    this.lastUpdatedDate,
    this.hasMultipleTireSizes,
    this.multipleTireSizeIds,
    this.multipleTireSizeNames,
    this.imagesLocation,
  });

  factory VehicleInspectionModel.fromJson(Map<String, dynamic> json) {
    return VehicleInspectionModel(
      vehicleId: json['vehicleId'],
      locationId: json['locationId'],
      vehicleNumber: json['vehicleNumber'],
      vehicleManufacturer: json['vehicleManufacturer'],
      vehicleType: json['vehicleType'],
      vehicleModel: json['vehicleModel'],
      vehicleMileageType: json['vehicleMileageType'],
      axleConfig: json['axleConfig'],
      axleConfigId: json['axleConfigId'] != null
          ? int.tryParse(json['axleConfigId'].toString())
          : null,
      tireSize: json['tireSize'],
      tireSizeId: json['tireSizeId'],
      lastRecordedHours: (json['lastRecordedHours'] as num?)?.toDouble(),
      lastRecordedMiles: (json['lastRecordedMiles'] as num?)?.toDouble(),
      lastRecordedDate: json['lastRecordedDate'],
      comments: json['comments'],
      installedTires: json['installedTires'] != null
          ? List<InstalledTire>.from(
        json['installedTires'].map((x) => InstalledTire.fromJson(x)),
      )
          : [],
      installedRims: json['installedRims'],
      lastUpdatedDate: json['lastUpdatedDate'],
      hasMultipleTireSizes: json['hasMultipleTireSizes'],
      multipleTireSizeIds: json['multipleTireSizeIds'],
      multipleTireSizeNames: json['multipleTireSizeNames'],
      imagesLocation: json['imagesLocation'] ?? json['ImagesLocation'],
    );
  }

  // ✅ Added toJson
  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'locationId': locationId,
      'vehicleNumber': vehicleNumber,
      'vehicleManufacturer': vehicleManufacturer,
      'vehicleType': vehicleType,
      'vehicleModel': vehicleModel,
      'vehicleMileageType': vehicleMileageType,
      'axleConfig': axleConfig,
      'axleConfigId': axleConfigId,
      'tireSize': tireSize,
      'tireSizeId': tireSizeId,
      'lastRecordedHours': lastRecordedHours,
      'lastRecordedMiles': lastRecordedMiles,
      'lastRecordedDate': lastRecordedDate,
      'comments': comments,
      'installedTires': installedTires?.map((x) => x.toJson()).toList(),
      'installedRims': installedRims,
      'lastUpdatedDate': lastUpdatedDate,
      'hasMultipleTireSizes': hasMultipleTireSizes,
      'multipleTireSizeIds': multipleTireSizeIds,
      'multipleTireSizeNames': multipleTireSizeNames,
      'imagesLocation': imagesLocation,
    };
  }
}

class InstalledTire {
  int? tireId;
  int? locationId;
  int? parentAccountId;
  String? tireSerialNo;
  String? registeredDate;
  int? manufacturerId;
  int? typeId;
  int? sizeId;
  String? sizeName;
  String? typeName;
  double? currentHours;
  double? currentMiles;
  String? wheelPosition;
  double? percentageWorn;
  dynamic wearNonSkid;
  double? currentTreadDepth;
  double? currentPressure;
  dynamic wearConditionId;
  dynamic casingConditionId;
  dynamic mountedRimId;
  double? outsideTread;
  double? middleTread;
  double? insideTread;
  double? originalTread;
  double? removeAt;
  String? comments;
  String? inspectionDate;
  String? mileageType;
  dynamic imagesLocation;
  String? brandNo;
  int? dispositionId;
  String? dispositionName;
  String? createdBy;
  String? manufacturerName;
  dynamic pressureType;
  int? vehicleId;
  String? vehicleNumber;
  dynamic removalReasonId;
  bool isFromSearch;
  String? action;

  InstalledTire({
    this.tireId,
    this.locationId,
    this.parentAccountId,
    this.tireSerialNo,
    this.registeredDate,
    this.manufacturerId,
    this.typeId,
    this.sizeId,
    this.sizeName,
    this.typeName,
    this.currentHours,
    this.currentMiles,
    this.wheelPosition,
    this.percentageWorn,
    this.wearNonSkid,
    this.currentTreadDepth,
    this.currentPressure,
    this.wearConditionId,
    this.casingConditionId,
    this.mountedRimId,
    this.outsideTread,
    this.middleTread,
    this.insideTread,
    this.originalTread,
    this.removeAt,
    this.comments,
    this.inspectionDate,
    this.mileageType,
    this.imagesLocation,
    this.brandNo,
    this.dispositionId,
    this.dispositionName,
    this.createdBy,
    this.manufacturerName,
    this.pressureType,
    this.vehicleId,
    this.vehicleNumber,
    this.removalReasonId,
    this.isFromSearch = false, // ✅ default false
    this.action,
  });

  factory InstalledTire.fromJson(Map<String, dynamic> json) {
    final double origTread = (json['originalTread'] as num?)?.toDouble() ?? 0.0;
    final double removeAt   = (json['removeAt']       as num?)?.toDouble() ?? 0.0;
    final double currTread  = (json['currentTreadDepth'] as num?)?.toDouble() ?? 0.0;
    final num? rawPercent = (json['percentageWorn'] ??
            json['PercentageWorn'] ??
            json['percentWorn'] ??
            json['Percentage']) as num?;
    double resolvedPercent = 0.0;
    if (rawPercent != null && rawPercent >= 0) {
      resolvedPercent = rawPercent.toDouble().clamp(0.0, 100.0);
    } else if (origTread > 0 && currTread > 0) {
      final double denominator = (origTread - removeAt) > 0 ? (origTread - removeAt) : origTread;
      final double effRemoveAt = (origTread - removeAt) > 0 ? removeAt : 0.0;
      resolvedPercent = ((1 - (currTread - effRemoveAt) / denominator) * 100)
          .clamp(0.0, 100.0);
    }

    return InstalledTire(
      tireId: json['tireId'],
      locationId: json['locationId'],
      parentAccountId: json['parentAccountId'],
      tireSerialNo: json['tireSerialNo'],
      registeredDate: json['registeredDate'],
      manufacturerId: json['manufacturerId'],
      typeId: json['typeId'],
      sizeId: json['sizeId'],
      sizeName: json['sizeName'],
      typeName: json['typeName'],
      currentHours: (json['currentHours'] as num?)?.toDouble(),
      currentMiles: (json['currentMiles'] as num?)?.toDouble(),
      wheelPosition: json['wheelPosition'],
      percentageWorn: resolvedPercent,
      wearNonSkid: json['wearNonSkid'],
      currentTreadDepth: (json['currentTreadDepth'] as num?)?.toDouble(),
      currentPressure: (json['currentPressure'] as num?)?.toDouble(),
      wearConditionId: json['wearConditionId'],
      casingConditionId: json['casingConditionId'],
      mountedRimId: json['mountedRimId'],
      outsideTread: (json['outsideTread'] as num?)?.toDouble(),
      middleTread: (json['middleTread'] as num?)?.toDouble(),
      insideTread: (json['insideTread'] as num?)?.toDouble(),
      originalTread: (json['originalTread'] as num?)?.toDouble(),
      removeAt: (json['removeAt'] as num?)?.toDouble(),
      comments: json['comments'],
      inspectionDate: json['inspectionDate'],
      mileageType: json['mileageType'],
      imagesLocation: json['imagesLocation'],
      brandNo: (json['brandNo'] ?? json['brandNumber'] ?? json['BrandNo'] ?? json['BrandNumber'])?.toString(),
      dispositionId: json['dispositionId'],
      dispositionName: json['dispositionName'],
      createdBy: json['createdBy'],
      manufacturerName: json['manufacturerName'],
      pressureType: json['pressureType'],
      vehicleId: json['vehicleId'],
      vehicleNumber: json['vehicleNumber'],
      removalReasonId: json['removalReasonId'],
      action: json['action'],
    );
  }

  // ✅ Full toJson method for InstalledTire
  Map<String, dynamic> toJson() {
    return {
      'tireId': tireId,
      'locationId': locationId,
      'parentAccountId': parentAccountId,
      'tireSerialNo': tireSerialNo,
      'registeredDate': registeredDate,
      'manufacturerId': manufacturerId,
      'typeId': typeId,
      'sizeId': sizeId,
      'sizeName': sizeName,
      'typeName': typeName,
      'currentHours': currentHours,
      'currentMiles': currentMiles,
      'wheelPosition': wheelPosition,
      'percentageWorn': percentageWorn,
      'wearNonSkid': wearNonSkid,
      'currentTreadDepth': currentTreadDepth,
      'currentPressure': currentPressure,
      'wearConditionId': wearConditionId,
      'casingConditionId': casingConditionId,
      'mountedRimId': mountedRimId,
      'outsideTread': outsideTread,
      'middleTread': middleTread,
      'insideTread': insideTread,
      'originalTread': originalTread,
      'removeAt': removeAt,
      'comments': comments,
      'inspectionDate': inspectionDate,
      'mileageType': mileageType,
      'imagesLocation': imagesLocation,
      'brandNo': brandNo,
      'dispositionId': dispositionId,
      'dispositionName': dispositionName,
      'createdBy': createdBy,
      'manufacturerName': manufacturerName,
      'pressureType': pressureType,
      'vehicleId': vehicleId,
      'vehicleNumber': vehicleNumber,
      'removalReasonId': removalReasonId,
      'action': action,
    };
  }

  // ✅ FIX: copyWith — edit tyre ke baad hours/miles update karne ke liye
  InstalledTire copyWith({
    double? currentHours,
    double? currentMiles,
    double? currentTreadDepth,
    double? currentPressure,
    double? outsideTread,
    double? middleTread,
    double? insideTread,
    double? percentageWorn,
    String? tireSerialNo,
    String? brandNo,
    String? manufacturerName,
    String? sizeName,
    String? typeName,
    String? comments,
    int? dispositionId,
    String? dispositionName,
    String? action,
  }) {
    return InstalledTire(
      tireId: tireId,
      locationId: locationId,
      parentAccountId: parentAccountId,
      tireSerialNo: tireSerialNo ?? this.tireSerialNo,
      registeredDate: registeredDate,
      manufacturerId: manufacturerId,
      typeId: typeId,
      sizeId: sizeId,
      sizeName: sizeName ?? this.sizeName,
      typeName: typeName ?? this.typeName,
      currentHours: currentHours ?? this.currentHours,
      currentMiles: currentMiles ?? this.currentMiles,
      wheelPosition: wheelPosition,
      percentageWorn: percentageWorn ?? this.percentageWorn,
      wearNonSkid: wearNonSkid,
      currentTreadDepth: currentTreadDepth ?? this.currentTreadDepth,
      currentPressure: currentPressure ?? this.currentPressure,
      wearConditionId: wearConditionId,
      casingConditionId: casingConditionId,
      mountedRimId: mountedRimId,
      outsideTread: outsideTread ?? this.outsideTread,
      middleTread: middleTread ?? this.middleTread,
      insideTread: insideTread ?? this.insideTread,
      originalTread: originalTread,
      removeAt: removeAt,
      comments: comments ?? this.comments,
      inspectionDate: inspectionDate,
      mileageType: mileageType,
      imagesLocation: imagesLocation,
      brandNo: brandNo ?? this.brandNo,
      dispositionId: dispositionId ?? this.dispositionId,
      dispositionName: dispositionName ?? this.dispositionName,
      createdBy: createdBy,
      manufacturerName: manufacturerName ?? this.manufacturerName,
      pressureType: pressureType,
      vehicleId: vehicleId,
      vehicleNumber: vehicleNumber,
      removalReasonId: removalReasonId,
      action: action ?? this.action,
    );
  }
}