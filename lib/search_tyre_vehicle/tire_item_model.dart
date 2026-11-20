class TireItem {
  final int tireId;
  final String tireSerialNo;
  final String manufacturerName;
  final String sizeName;
  final String typeName;
  final double currentHours;
  final double currentMiles;
  final double currentTreadDepth;
  final double percentageWorn;
  final String wheelPosition;
  final String dispositionName;
  final String vehicleNumber;
  final int? vehicleId;
  final String? inspectionDate;
  final double? outsideTread;
  final double? middleTread;
  final double? insideTread;
  final double? currentPressure;
  final double? originalTread;
  final double? removeAt;
  final dynamic wearConditionId;
  final dynamic casingConditionId;
  final String? comments;
  final String? imagesLocation;

  /// 🔧 Correlation key (InspectionStatusId) for the SPECIFIC pending
  /// inspection "event" this card represents — same tireId can repeat
  /// across multiple pending inspections, each with its own id, so each
  /// stays a distinct card instead of collapsing into one.
  final int? pendingInspectionId;
  final String? action;
  final String? brandNo;

  TireItem({
    required this.tireId,
    required this.tireSerialNo,
    required this.manufacturerName,
    required this.sizeName,
    required this.typeName,
    required this.currentHours,
    required this.currentMiles,
    required this.currentTreadDepth,
    required this.percentageWorn,
    required this.wheelPosition,
    required this.dispositionName,
    required this.vehicleNumber,
    this.vehicleId,
    this.inspectionDate,
    this.outsideTread,
    this.middleTread,
    this.insideTread,
    this.currentPressure,
    this.originalTread,
    this.removeAt,
    this.wearConditionId,
    this.casingConditionId,
    this.comments,
    this.imagesLocation,
    this.pendingInspectionId,
    this.action,
    this.brandNo,
  });

  factory TireItem.fromJson(Map<String, dynamic> json) {
    return TireItem(
      tireId:            json['tireId'] as int,
      tireSerialNo:      json['tireSerialNo'] as String? ?? '',
      manufacturerName:  json['manufacturerName'] as String? ?? '',
      sizeName:          json['sizeName'] as String? ?? '',
      typeName:          json['typeName'] as String? ?? '',
      currentHours:      json['currentHours'] != null
          ? (json['currentHours'] as num).toDouble() : 0.0,
      currentMiles:      json['currentMiles'] != null
          ? (json['currentMiles'] as num).toDouble() : 0.0,
      currentTreadDepth: json['currentTreadDepth'] != null
          ? (json['currentTreadDepth'] as num).toDouble() : 0.0,
      percentageWorn:    json['percentageWorn'] != null
          ? (json['percentageWorn'] as num).toDouble() : 0.0,
      wheelPosition:     json['wheelPosition'] as String? ?? '',
      dispositionName:   json['dispositionName'] as String? ?? '',
      vehicleNumber:     json['vehicleNumber'] as String? ?? '',
      vehicleId:         json['vehicleId'] as int?,
      inspectionDate:    json['inspectionDate'] as String?,
      outsideTread:      json['outsideTread'] != null
          ? (json['outsideTread'] as num).toDouble() : null,
      middleTread:       json['middleTread'] != null
          ? (json['middleTread'] as num).toDouble() : null,
      insideTread:       json['insideTread'] != null
          ? (json['insideTread'] as num).toDouble() : null,
      currentPressure:   json['currentPressure'] != null
          ? (json['currentPressure'] as num).toDouble() : null,
      originalTread:     json['originalTread'] != null
          ? (json['originalTread'] as num).toDouble() : null,
      removeAt:          json['removeAt'] != null
          ? (json['removeAt'] as num).toDouble() : null,
      wearConditionId:   json['wearConditionId'] ?? json['WearConditionId'],
      casingConditionId: json['casingConditionId'] ?? json['CasingConditionId'],
      comments:          (json['comments'] ?? json['Comments'])?.toString(),
      imagesLocation:    json['imagesLocation'] as String? ?? json['ImagesLocation'] as String?,
      pendingInspectionId: json['pendingInspectionId'] as int?,
      action:            json['action'] as String? ?? json['Action'] as String?,
      brandNo:           (json['brandNo'] ?? json['brandNumber'] ?? json['BrandNo'] ?? json['BrandNumber'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tireId':            tireId,
      'tireSerialNo':      tireSerialNo,
      'brandNo':           brandNo,
      'manufacturerName':  manufacturerName,
      'sizeName':          sizeName,
      'typeName':          typeName,
      'currentHours':      currentHours,
      'currentMiles':      currentMiles,
      'currentTreadDepth': currentTreadDepth,
      'percentageWorn':    percentageWorn,
      'wheelPosition':     wheelPosition,
      'dispositionName':   dispositionName,
      'vehicleNumber':     vehicleNumber,
      'vehicleId':         vehicleId,
      'inspectionDate':    inspectionDate,
      'outsideTread':      outsideTread,
      'middleTread':       middleTread,
      'insideTread':       insideTread,
      'currentPressure':   currentPressure,
      'originalTread':     originalTread,
      'removeAt':          removeAt,
      'wearConditionId':   wearConditionId,
      'casingConditionId': casingConditionId,
      'comments':          comments,
      'imagesLocation':    imagesLocation,
      'pendingInspectionId': pendingInspectionId,
      'action':            action,
    };
  }
}