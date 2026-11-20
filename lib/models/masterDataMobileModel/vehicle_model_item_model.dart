class VehicleModelItem {
  final int modelId;
  final int vehDefId;
  final int vehicleManufacturerId;
  final String modelName;
  final int vehicleTypeId;
  final int configurationId;
  final bool activeFlag;
  final String? updationComments;

  VehicleModelItem({
    required this.modelId,
    required this.vehDefId,
    required this.vehicleManufacturerId,
    required this.modelName,
    required this.vehicleTypeId,
    required this.configurationId,
    required this.activeFlag,
    this.updationComments,
  });

  factory VehicleModelItem.fromJson(Map<String, dynamic> json) {
    return VehicleModelItem(
      modelId: json['modelId'] ?? 0,
      vehDefId: json['vehDefId'] ?? 0,
      vehicleManufacturerId: json['vehicleManufacturerId'] ?? 0,
      modelName: json['modelName'] ?? '',
      vehicleTypeId: json['vehicleTypeId'] ?? 0,
      configurationId: json['configurationId'] ?? 0,
      activeFlag: json['activeFlag'] ?? false,
      updationComments: json['updationComments'],
    );
  }

  // ✅ configurationId se axleConfig resolve karo
  String get axleConfig {
    switch (configurationId) {
      case 1:
        return "22";
      case 2:
        return "222";
      case 3:
        return "2222";
      case 4:
        return "22222";
      case 5:
        return "222222"; // 6 axle
      case 6:
        return "24";
      case 7:
        return "224";
      case 8:
        return "2";
      case 9:
        return "242";
      case 10:
        return "2222222"; // 7 axle (future proof)
      default:
        return "22";
    }
  }

  int get axleConfigId => configurationId;

  // ✅ Axle count
  int get axleCount {
    return axleConfig
        .split('')
        .where((c) => RegExp(r'[0-9]').hasMatch(c))
        .length
        .clamp(1, 10);
  }

  // ✅ Har axle pe kitne tyre
  List<int> get axleDigits {
    return axleConfig
        .split('')
        .where((c) => RegExp(r'[0-9]').hasMatch(c))
        .map((c) => int.tryParse(c) ?? 2)
        .toList();
  }

  // ✅ Total tyre count
  int get totalTyreCount {
    return axleDigits.fold(0, (sum, d) => sum + d);
  }

  Map<String, dynamic> toJson() {
    return {
      'modelId': modelId,
      'vehDefId': vehDefId,
      'vehicleManufacturerId': vehicleManufacturerId,
      'modelName': modelName,
      'vehicleTypeId': vehicleTypeId,
      'configurationId': configurationId,
      'activeFlag': activeFlag,
      'updationComments': updationComments,
    };
  }
}
