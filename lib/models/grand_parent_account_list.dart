class GrandparentAccountList {
  final int id;
  final String name;
  final bool isActive;
  final String ownedBy;
  final String createdBy;
  final String updatedBy;
  final String createDate;
  final String updateDate;


  final bool? isApprovalWorkflowEnabled;

  GrandparentAccountList({
    required this.id,
    required this.name,
    required this.isActive,
    required this.ownedBy,
    required this.createdBy,
    required this.updatedBy,
    required this.createDate,
    required this.updateDate,
    this.isApprovalWorkflowEnabled,
  });

  factory GrandparentAccountList.fromJson(Map<String, dynamic> json) {
    return GrandparentAccountList(
      id: _parseInt(json['grandParentAccountId']) ?? 0,
      name: json['grandParentAccountName'] ?? '',
      isActive: json['isActive'] ?? false,
      ownedBy: json['ownedBy'] ?? '',
      createdBy: json['createdBy'] ?? '',
      updatedBy: json['updatedBy'] ?? '',
      createDate: json['createdDate'] ?? '',
      updateDate: json['updatedDate'] ?? '',
      // Backend may send this as `isApprovalWorkflowEnabled` or
      // `IsApprovalWorkflowEnabled` depending on the serializer. This is the
      // real field confirmed from the live API response — kept as-is.
      isApprovalWorkflowEnabled: _parseBool(
        json['isApprovalWorkflowEnabled'] ?? json['IsApprovalWorkflowEnabled'],
      ),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      if (value.isEmpty) return null;
      return value.toLowerCase() == 'true' || value == '1';
    }
    return null;
  }
}