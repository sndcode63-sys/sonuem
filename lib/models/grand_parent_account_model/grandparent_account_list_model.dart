class GrandparentAccountList {
  final int id;
  final String name;
  final bool isActive;
  final String ownedBy;
  final String createdBy;
  final String updatedBy;
  final String createDate;
  final String updateDate;
  final bool? isApprovalWorkflowEnabled; // Added field

  GrandparentAccountList({
    required this.id,
    required this.name,
    required this.isActive,
    required this.ownedBy,
    required this.createdBy,
    required this.updatedBy,
    required this.createDate,
    required this.updateDate,
    this.isApprovalWorkflowEnabled, // Added to constructor (nullable, so not required)
  });

  factory GrandparentAccountList.fromJson(Map<String, dynamic> json) {
    return GrandparentAccountList(
      id: json['grandParentAccountId'] ?? 0,
      name: json['grandParentAccountName'] ?? '',
      isActive: json['isActive'] ?? false,
      ownedBy: json['ownedBy'] ?? '',
      createdBy: json['createdBy'] ?? '',
      updatedBy: json['updatedBy'] ?? '',
      createDate: json['createdDate'] ?? '',
      updateDate: json['updatedDate'] ?? '',
      isApprovalWorkflowEnabled: json['isApprovalWorkflowEnabled'], // Mapped from JSON
    );
  }
}