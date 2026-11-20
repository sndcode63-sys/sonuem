class UserProfile {
  String? userId;
  String? firstName;
  String? middleName;
  String? lastName;
  String? userRole;
  String? phoneNumber;
  String? countryCode;
  String? emailAddress;


  int? grandParentAccountId;


  int? parentAccountId;


  bool? isApprover;

  UserProfile({
    this.userId,
    this.firstName,
    this.middleName,
    this.lastName,
    this.userRole,
    this.phoneNumber,
    this.countryCode,
    this.emailAddress,
    this.grandParentAccountId,
    this.parentAccountId,
    this.isApprover,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'],
      firstName: json['firstName'],
      middleName: json['middleName'],
      lastName: json['lastName'],
      userRole: json['userRole'],
      phoneNumber: json['phoneNumber'],
      countryCode: json['countryCode'],
      emailAddress: json['emailAddress'],
      // Backend may send this as `grandParentAccountId` or
      // `GrandParentAccountId` depending on the serializer.
      grandParentAccountId: _parseInt(
        json['grandParentAccountId'] ?? json['GrandParentAccountId'],
      ),
      // Backend may send this as `parentAccountId` or `ParentAccountId`
      // depending on the serializer.
      parentAccountId: _parseInt(
        json['parentAccountId'] ?? json['ParentAccountId'],
      ),
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

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'userRole': userRole,
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'emailAddress': emailAddress,
      'grandParentAccountId': grandParentAccountId,
      'parentAccountId': parentAccountId,
      'isApprover': isApprover ?? false,
    };
  }
}