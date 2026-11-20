class GrandparentAccountModel {
  final String? createdBy;
  final String? createdDate;
  final String grandParentAccountName;
  final bool isActive;
  final String ownedBy;
  final String? updatedBy;
  final String? updatedDate;
  final bool isApprovalWorkflowEnabled; // ✅ Added field

  GrandparentAccountModel({
    this.createdBy,
    this.createdDate,
    required this.grandParentAccountName,
    required this.isActive,
    required this.ownedBy,
    this.updatedBy,
    this.updatedDate,
    required this.isApprovalWorkflowEnabled, // ✅ Added in constructor
  });

  // Factory constructor to create object from JSON
  factory GrandparentAccountModel.fromJson(Map<String, dynamic> json) {
    return GrandparentAccountModel(
      createdBy: json['createdBy'] ?? '',
      createdDate: json['createdDate'],
      grandParentAccountName: json['grandParentAccountName'] ?? '',
      isActive: json['isActive'] ?? false,
      ownedBy: json['ownedBy'] ?? '',
      updatedBy: json['updatedBy'] ?? '',
      updatedDate: json['updatedDate'],
      isApprovalWorkflowEnabled: json['isApprovalWorkflowEnabled'] ?? false, // ✅ Added for JSON mapping
    );
  }

  // Convert object back to JSON
  Map<String, dynamic> toJson() {
    return {
      'createdBy': createdBy,
      'createdDate': createdDate,
      'grandParentAccountName': grandParentAccountName,
      'isActive': isActive,
      'ownedBy': ownedBy,
      'updatedBy': updatedBy,
      'updatedDate': updatedDate,
      'isApprovalWorkflowEnabled': isApprovalWorkflowEnabled, // ✅ Added to payload
    };
  }
}