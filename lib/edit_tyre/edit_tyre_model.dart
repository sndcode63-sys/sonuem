class EditTyreModel {
  double? averageTreadDepth;

  String? brandNo; // ✅ FIX Bug1: API returns brandNo as String (e.g. "BRN-001"), not int

  double? casingValue;

  int? compoundId;

  double? costAdjustment;

  double? currentHours;

  double? currentMiles;

  double? currentPressure;

  double? currentTreadDepth;

  int? dispositionId;

  String? evaluationNo;

  int? fillTypeId;

  double? fillCost;

  int? indCodeId;

  double? insideTread;

  bool? isEditable;

  bool? isMountToRim;

  String? imagesLocation;

  String? lotNo;

  int? loadRatingId;

  String? mileageType;

  double? middleTread;

  int? manufacturerId;

  String? mountStatus;

  int? mountedRimId;

  String? mountedRimSerialNo;

  double? netCost;

  int? numberOfRetreads;

  double? originalTread;

  double? outsideTread;

  int? parentAccountId;

  double? percentageWorn;

  int? plyId;

  String? poNo;

  double? purchaseCost;

  double? purchasedTread;

  int? repairCount;

  double? repairCost;

  String? registeredDate;

  double? removeAt;

  int? retreadCount;

  double? retreadCost;

  double? recommendedPressure;

  int? sizeId;

  double? soldAmount;

  int? speedRatingId;

  int? starRatingId;

  int? tireId;

  String? tireSerialNo;

  int? tireStatusId;
  // ✅ FIX Bug3&4: tireStatusName add karo so it gets synced to API and saved offline
  String? tireStatusName;

  int? trackingMethod;

  int? typeId;

  int? vehicleId;

  String? vehicleNumber;

  int? locationId;

  double? warrantyAdjustment;

  String? wheelPosition;
  // EditTyreModel mein add karo
  String? dispositionName;

  // ---------------- CONSTRUCTOR ----------------

  EditTyreModel({
    this.averageTreadDepth,
    this.brandNo,   // ✅ String? — matches API schema
    this.casingValue,
    this.compoundId,
    this.costAdjustment,
    this.currentHours,
    this.currentMiles,
    this.currentPressure,
    this.currentTreadDepth,
    this.dispositionId,
    this.evaluationNo,
    this.fillTypeId,
    this.fillCost,
    this.indCodeId,
    this.insideTread,
    this.isEditable,
    this.isMountToRim,
    this.imagesLocation,
    this.lotNo,
    this.loadRatingId,
    this.mileageType = '1',
    this.middleTread,
    this.manufacturerId,
    this.mountStatus = 'Not Mounted',
    this.mountedRimId,
    this.mountedRimSerialNo,
    this.netCost,
    this.numberOfRetreads = 0,
    this.originalTread,
    this.outsideTread,
    this.parentAccountId,
    this.percentageWorn,
    this.plyId,
    this.poNo,
    this.purchaseCost,
    this.purchasedTread,
    this.repairCount,
    this.repairCost,
    this.registeredDate,
    this.removeAt,
    this.retreadCount,
    this.retreadCost,
    this.recommendedPressure,
    this.sizeId,
    this.soldAmount,
    this.speedRatingId,
    this.starRatingId,
    this.tireId,
    this.tireSerialNo,
    this.tireStatusId,
    this.tireStatusName,
    this.trackingMethod = 0,
    this.typeId,
    this.vehicleId,
    this.vehicleNumber,
    this.locationId,
    this.warrantyAdjustment,
    this.wheelPosition,
    this.dispositionName,
  });

  // ---------------- FROM JSON ----------------

  factory EditTyreModel.fromJson(Map<String, dynamic> json) {
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double safeDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int? parseBrandNo(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }
    return EditTyreModel(
      dispositionName: json['dispositionName']?.toString(),

      averageTreadDepth: safeDouble(json['averageTreadDepth']),
      brandNo: json['brandNo']?.toString(), // ✅ FIX Bug1: keep as String, don't parseInt
      casingValue: safeDouble(json['casingValue']),
      compoundId: safeInt(json['compoundId']),
      costAdjustment: safeDouble(json['costAdjustment']),
      currentHours: safeDouble(json['currentHours']),
      currentMiles: safeDouble(json['currentMiles']),
      currentPressure: safeDouble(json['currentPressure']),
      currentTreadDepth: safeDouble(json['currentTreadDepth']),
      dispositionId: safeInt(json['dispositionId']),
      evaluationNo: json['evaluationNo']?.toString() ?? '',
      fillTypeId: safeInt(json['fillTypeId']),
      fillCost: safeDouble(json['fillCost']),
      indCodeId: safeInt(json['indCodeId']),
      insideTread: safeDouble(json['insideTread']),
      isEditable: json['isEditable'] ?? false,
      isMountToRim: json['isMountToRim'] ?? false,
      imagesLocation: json['imagesLocation']?.toString(),
      lotNo: json['lotNo']?.toString() ?? '',
      loadRatingId: safeInt(json['loadRatingId']),
      mileageType: json['mileageType']?.toString() ?? '1',
      middleTread: safeDouble(json['middleTread']),
      manufacturerId: safeInt(json['manufacturerId']),
      mountStatus: json['mountStatus']?.toString() ?? 'Not Mounted',
      mountedRimId: safeInt(json['mountedRimId']),
      mountedRimSerialNo: json['mountedRimSerialNo']?.toString(),
      netCost: safeDouble(json['netCost']),
      numberOfRetreads: safeInt(json['numberOfRetreads']),
      originalTread: safeDouble(json['originalTread']),
      outsideTread: safeDouble(json['outsideTread']),
      parentAccountId: safeInt(json['parentAccountId']),
      percentageWorn: safeDouble(json['percentageWorn']),
      plyId: safeInt(json['plyId']),
      poNo: json['poNo']?.toString() ?? '',
      purchaseCost: safeDouble(json['purchaseCost']),
      purchasedTread: safeDouble(json['purchasedTread']),
      tireStatusName: json['tireStatusName']?.toString(), // ✅ FIX: Yeh line missing thi
      repairCount: safeInt(json['repairCount']),
      repairCost: safeDouble(json['repairCost']),
      registeredDate: json['registeredDate']?.toString() ?? '',
      removeAt: safeDouble(json['removeAt']),
      retreadCount: safeInt(json['retreadCount']),
      retreadCost: safeDouble(json['retreadCost']),
      recommendedPressure: safeDouble(json['recommendedPressure']),
      sizeId: safeInt(json['sizeId']),
      soldAmount: safeDouble(json['soldAmount']),
      speedRatingId: safeInt(json['speedRatingId']),
      starRatingId: safeInt(json['starRatingId']),
      tireId: safeInt(json['tireId']),
      tireSerialNo: json['tireSerialNo']?.toString() ?? '',
      tireStatusId: safeInt(json['tireStatusId']),
      trackingMethod: safeInt(json['trackingMethod']),
      typeId: safeInt(json['typeId']),
      vehicleId: safeInt(json['vehicleId']),
      vehicleNumber: json['vehicleNumber']?.toString(),
      locationId: safeInt(json['locationId']),
      warrantyAdjustment: safeDouble(json['warrantyAdjustment']),
      wheelPosition: json['wheelPosition']?.toString(),
    );
  }

  // ---------------- TO JSON ----------------

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      // Basic Info
      "tireId": tireId,
      "tireSerialNo": tireSerialNo,
      "brandNo": (brandNo != null && brandNo!.isNotEmpty) ? brandNo : null, // ✅ FIX Bug1: String check
      "registeredDate": registeredDate,
      "evaluationNo": (evaluationNo != null && evaluationNo!.isNotEmpty) ? evaluationNo : null,
      "lotNo": (lotNo != null && lotNo!.isNotEmpty) ? lotNo : null,
      "poNo": (poNo != null && poNo!.isNotEmpty) ? poNo : null,
      "tireStatusId": tireStatusId,
      // ⚠️ tireStatusName & dispositionName = server-computed read-only fields
      // Inhe PUT body mein mat bhejo — API 500 deta hai (unhandled server error)
      "dispositionId": dispositionId,

      // Tracking
      "trackingMethod": trackingMethod,
      "mileageType": mileageType,
      "currentHours": currentHours,
      "currentMiles": currentMiles,
      "currentPressure": currentPressure,   // ✅ FIX: Missing tha — 500 error ka cause

      // Specifications
      "manufacturerId": manufacturerId,
      "sizeId": sizeId,
      "typeId": typeId,
      "starRatingId": (starRatingId != null && starRatingId != 0) ? starRatingId : null,
      // ✅ FIX: plyId aur middleTread toJson mein add kiye
      "plyId": (plyId != null && plyId != 0) ? plyId : null,
      "middleTread": middleTread,
      "indCodeId": (indCodeId != null && indCodeId != 0) ? indCodeId : null,
      "compoundId": (compoundId != null && compoundId != 0) ? compoundId : null,
      "loadRatingId": (loadRatingId != null && loadRatingId != 0) ? loadRatingId : null,
      "speedRatingId": (speedRatingId != null && speedRatingId != 0) ? speedRatingId : null,

      // ✅ Tread Depth (Crucial for Edit)
      // ✅ FIX Bug2: tread fields null nahi bhejo — 0.0 default do
      // Web portal pe removeAt/tread 0 dikhta tha jab null aata tha, API usse ignore karta tha
      "originalTread": originalTread ?? 0.0,
      "removeAt": removeAt ?? 0.0,
      "purchasedTread": purchasedTread ?? 0.0,
      "outsideTread": outsideTread ?? 0.0,
      "insideTread": insideTread ?? 0.0,
      "averageTreadDepth": averageTreadDepth ?? 0.0,
      "currentTreadDepth": currentTreadDepth ?? 0.0,

      // Mounting
      "mountStatus": mountStatus,
      "isMountToRim": isMountToRim,
      "wheelPosition": (wheelPosition != null && wheelPosition!.isNotEmpty && wheelPosition != "N/A")
          ? wheelPosition
          : null,
      "vehicleId": (vehicleId != null && vehicleId != 0) ? vehicleId : null,
      "vehicleNumber": (vehicleNumber != null && vehicleNumber!.isNotEmpty) ? vehicleNumber : null,

      // Financials
      "purchaseCost": purchaseCost,
      "casingValue": casingValue,
      "fillTypeId": (fillTypeId != null && fillTypeId != 0) ? fillTypeId : null,
      "fillCost": fillCost,
      "repairCost": repairCost,
      "retreadCost": retreadCost,
      "warrantyAdjustment": warrantyAdjustment,
      "costAdjustment": costAdjustment,
      "soldAmount": soldAmount,
      "netCost": netCost,

      // Location
      "parentAccountId": parentAccountId,
      "locationId": locationId,
    };

    // Step: Remove nulls so API doesn't get confused
    data.removeWhere((key, value) => value == null);

    return data;
  }}

Map<String, dynamic> _removeNulls(Map<String, dynamic> data) {
  data.removeWhere((key, value) => value == null);
  return data;
}