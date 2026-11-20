import 'package:emtrack/services/api_constants.dart';
import 'package:emtrack/services/api_service.dart';
import 'package:flutter/cupertino.dart';
import 'user_list_model.dart';

class UserManagementListService {
  Future<List<UserlListModel>> getUsers() async {
    try {
      final response = await ApiService.getApi(
        endpoint: ApiConstants.getAllUserList,
      );

      List raw = [];
      if (response is List) {
        raw = response;
      } else if (response['model'] is List) {
        raw = response['model'];
      } else if (response['data'] is List) {
        raw = response['data'];
      }

      if (raw.isNotEmpty) {
        return raw.map((e) => UserlListModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching users: $e");
      throw Exception("Failed to load users");
    }
  }
  Future<void> deleteUser(String username) async {
    try {
      final response = await ApiService.deleteApi(
        endpoint: ApiConstants.deleteUser,
        body: {
          "username": username,

        },
      );

      final message = response["message"];
      if (message == null || message.toString().trim().isEmpty) {
        throw Exception(response["errorMessage"] ?? "Delete Failed");
      }
    } catch (e) {
      debugPrint("Error deleting user: $e");
      rethrow;
    }
  }

  /// Set/unset a user as an Approver (Inspection Approval Flow).
  ///
  /// Fired when the "Approve for Inspection" checkbox is toggled for an
  /// EMTUSER in the User Management list under a Parent Account. Persists
  /// `isApprover` for that user via the dedicated user-update endpoint:
  ///
  ///   PUT /api/UserProfile/Update
  ///
  /// NOTE: this endpoint returns 405 Method Not Allowed on POST — the
  /// backend expects PUT for "Update" style routes (POST is reserved for
  /// Create). This is the same user record identified by `userId`, so the
  /// full profile is sent back with only `isApprover` flipped (checked =
  /// true, unchecked = false).
  Future<bool> updateApproverStatus(UserlListModel user, bool isApprover) async {
    final url = '${ApiConstants.baseUrl}${ApiConstants.updateUserProfile}';

    debugPrint(
      '🔲 [UserManagementListService] Checkbox toggled -> calling Update API\n'
          '   userId     : ${user.userId}\n'
          '   isApprover : $isApprover\n'
          '   endpoint   : PUT $url',
    );

    final body = {
      "userId": user.userId,
      "firstName": user.firstName,
      "middleName": user.middleName,
      "lastName": user.lastName,
      "userRole": user.userRole,
      "phoneNumber": user.phoneNumber,
      "countryCode": user.countryCode,
      "emailAddress": user.emailAddress,
      "grandParentAccountId": user.grandParentAccountId,
      "updatedDate": DateTime.now().toIso8601String(),
      "isApprover": isApprover,
    };

    try {
      final response = await ApiService.putApi(
        endpoint: ApiConstants.updateUserProfile,
        body: body,
      );

      debugPrint(
        '⬅️ [UserManagementListService] Update API response for '
            'userId=${user.userId}: $response',
      );

      // Many "Update" endpoints reply 200 with either an empty body, the
      // updated object, or a { message: ... } wrapper — unlike Create/
      // Delete, absence of "message" alone doesn't mean failure here.
      // Only treat it as a failure when the response explicitly carries
      // an error indicator.
      final errorMessage = response["errorMessage"] ?? response["error"];
      final hasErrorMessage =
          errorMessage != null && errorMessage.toString().trim().isNotEmpty;

      if (hasErrorMessage) {
        debugPrint(
          '❌ [UserManagementListService] Update API failed for '
              'userId=${user.userId} (isApprover=$isApprover): $errorMessage',
        );
        return false;
      }

      debugPrint(
        '✅ [UserManagementListService] userId=${user.userId} isApprover '
            'set to $isApprover successfully via Update API',
      );
      return true;
    } catch (e) {
      debugPrint(
        '❌ [UserManagementListService] Update API error for '
            'userId=${user.userId} (isApprover=$isApprover) at $url -> $e',
      );
      return false;
    }
  }
}