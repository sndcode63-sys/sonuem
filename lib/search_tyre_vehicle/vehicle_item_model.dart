class VehicleItem {
  final int? vehicleId;
  final String? vehicleNumber;
  final int? parentAccountId;
  final String? manufacturer;
  final String? typeName;
  final String? modelName;
  final String? tireSize;
  final String? mileageType;
  final double? currentHours;
  final double? currentMiles;
  final double? removalTread;
  final String? severityComments;
  final String? vehicleIcon;
  final String? imagesLocation;

  final int? pendingInspectionId;

  VehicleItem({
    this.vehicleId,
    this.vehicleNumber,
    this.parentAccountId,
    this.manufacturer,
    this.typeName,
    this.modelName,
    this.tireSize,
    this.mileageType,
    this.currentHours,
    this.currentMiles,
    this.removalTread,
    this.severityComments,
    this.vehicleIcon,
    this.imagesLocation,
    this.pendingInspectionId,
  });

  /// ================= FROM JSON =================
  factory VehicleItem.fromJson(Map<String, dynamic> json) {
    return VehicleItem(
      vehicleId: json['vehicleId'] as int?,
      vehicleNumber: json['vehicleNumber'] as String?,
      parentAccountId: json['parentAccountId'] as int?,
      manufacturer: json['manufacturer'] as String?,
      typeName: json['typeName'] as String?,
      modelName: json['modelName'] as String?,
      tireSize: json['tireSize'] as String?,
      mileageType: json['mileageType'] as String?,
      currentHours: json['currentHours'] != null
          ? (json['currentHours'] as num).toDouble()
          : null,
      currentMiles: json['currentMiles'] != null
          ? (json['currentMiles'] as num).toDouble()
          : null,
      removalTread: json['removalTread'] != null
          ? (json['removalTread'] as num).toDouble()
          : null,
      severityComments: json['severityComments'] as String? ?? '',
      vehicleIcon: json['vehicleIcon'] as String? ?? '',
      imagesLocation: json['imagesLocation'] as String? ?? json['ImagesLocation'] as String?,
      pendingInspectionId: json['pendingInspectionId'] as int?,
    );
  }

  /// ================= TO JSON =================
  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'vehicleNumber': vehicleNumber,
      'parentAccountId': parentAccountId,
      'manufacturer': manufacturer,
      'typeName': typeName,
      'modelName': modelName,
      'tireSize': tireSize,
      'mileageType': mileageType,
      'currentHours': currentHours,
      'currentMiles': currentMiles,
      'removalTread': removalTread,
      'severityComments': severityComments,
      'vehicleIcon': vehicleIcon,
      'imagesLocation': imagesLocation,
      'pendingInspectionId': pendingInspectionId,
    };
  }
}