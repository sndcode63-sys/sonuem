class UserlListModel {
  final String? userId;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? userRole;
  final DateTime? updatedDate;
  final String? phoneNumber;
  final String? countryCode;
  final String? emailAddress;
  final int? grandParentAccountId;
  final bool? isDeleted;

  /// Inspection Approval Flow — whether this user is an Approver.
  /// Mirrors UserProfile.isApprover but for OTHER users, as returned by
  /// GET /api/UserProfile/GetAllUsers (User Management list).
  final bool? isApprover;

  /// `true` sirf offline-created (abhi tak sync na hue) users ke liye —
  /// yeh row Hive ke pending-operation se aayi hai, backend par abhi
  /// real record nahi bana. Sync ho jaane ke baad agli `fetchUsers()`
  /// call me yeh normal (server) user ban jayega aur flag khud-ba-khud
  /// hat jayega.
  final bool isPendingSync;

  UserlListModel({
    this.userId,
    this.firstName,
    this.middleName,
    this.lastName,
    this.userRole,
    this.updatedDate,
    this.phoneNumber,
    this.countryCode,
    this.emailAddress,
    this.grandParentAccountId,
    this.isDeleted,
    this.isApprover,
    this.isPendingSync = false,
  });

  factory UserlListModel.fromJson(Map<String, dynamic> json) {
    return UserlListModel(
      userId: json['userId'],
      firstName: json['firstName'],
      middleName: json['middleName'],
      lastName: json['lastName'],
      userRole: json['userRole'],
      updatedDate: json['updatedDate'] != null
          ? DateTime.parse(json['updatedDate'])
          : null,
      phoneNumber: json['phoneNumber'],
      countryCode: json['countryCode'],
      emailAddress: json['emailAddress'],
      grandParentAccountId: json['grandParentAccountId'],
      isDeleted: json['isDeleted'],
      isApprover: _parseBool(json['isApprover'] ?? json['IsApprover']),
    );
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return null;
  }

  UserlListModel copyWith({
    int? grandParentAccountId,
    bool? isApprover,
  }) {
    return UserlListModel(
      userId: userId,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      userRole: userRole,
      updatedDate: updatedDate,
      phoneNumber: phoneNumber,
      countryCode: countryCode,
      emailAddress: emailAddress,
      grandParentAccountId: grandParentAccountId ?? this.grandParentAccountId,
      isDeleted: isDeleted,
      isApprover: isApprover ?? this.isApprover,
      isPendingSync: isPendingSync,
    );
  }

  /// Builds a placeholder row for a `createUser` op still sitting in the
  /// offline pending-operations queue (not yet synced to the server).
  factory UserlListModel.fromPendingPayload(Map<String, dynamic> p) {
    return UserlListModel(
      userId: p['username']?.toString(),
      firstName: p['firstName']?.toString(),
      middleName: p['middleName']?.toString(),
      lastName: p['lastName']?.toString(),
      userRole: p['userRole']?.toString(),
      phoneNumber: p['phoneNumber']?.toString(),
      countryCode: p['countryCode']?.toString(),
      emailAddress: p['email']?.toString(),
      isDeleted: false,
      isApprover: false,
      isPendingSync: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'userRole': userRole,
      'updatedDate': updatedDate?.toIso8601String(),
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'emailAddress': emailAddress,
      'grandParentAccountId': grandParentAccountId,
      'isDeleted': isDeleted,
      'isApprover': isApprover ?? false,
      'isPendingSync': isPendingSync,
    };
  }
}
