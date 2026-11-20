class AssignGrandparentModel {
  final int parentAccountId;
  final int grandparentAccountId;
  final int userId;
  final bool isApprovalWorkflowEnabled; // ✅ Added field

  AssignGrandparentModel({
    required this.parentAccountId,
    required this.grandparentAccountId,
    required this.userId,
    required this.isApprovalWorkflowEnabled, // ✅ Added in constructor
  });

  Map<String, dynamic> toJson() {
    return {
      "parentAccountId": parentAccountId,
      "grandparentAccountId": grandparentAccountId,
      "userId": userId, // Note: Make sure backend expects "userId" or "username" as per your API
      "isApprovalWorkflowEnabled": isApprovalWorkflowEnabled, // ✅ Added to JSON payload
    };
  }
}