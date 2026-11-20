import 'package:emtrack/routes/app_pages.dart';
import 'package:emtrack/services/api_constants.dart';
import 'package:emtrack/services/api_service.dart';
import 'package:emtrack/user_management/user_management_model.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/country/country_model.dart';

class UserManagementService {
  Future<bool> registerUser(UserManagementModel model) async {
    try {
      // Step 1: Create user account
      final createUserResponse = await ApiService.postApi(
        endpoint: ApiConstants.createUser,
        body: {
          "email": model.email,
          "password": model.password,
          "username": model.username,
        },
      );
      _checkApiError(createUserResponse, "User Creation Failed");

      // Step 2: Create user profile
      final createUserProfileResponse = await ApiService.postApi(
        endpoint: ApiConstants.createUserProfile,
        body: {
          "userId": model.username,
          "firstName": model.firstName,
          "middleName": model.middleName,
          "lastName": model.lastName,
          "userRole": model.role,
          "updatedDate": DateTime.now().toIso8601String(),
          "phoneNumber": model.phone,
          "countryCode": model.country,
          "emailAddress": model.email,
        },
      );
      _checkApiError(createUserProfileResponse, "Profile Creation Failed");

      // Step 3: Create user preferences
      final parentAccountId = await SecureStorage.getParentAccountId();
      final parentAccountName = await SecureStorage.getParentAccountName();
      final locationId = await SecureStorage.getLocationId();
      final locationName = await SecureStorage.getLocationName();

      final createUserPreferenceResponse = await ApiService.postApi(
        endpoint: ApiConstants.createUserPreference,
        body: {
          "lastAccessedAccountId": parentAccountId,
          "lastAccessedAccountName": parentAccountName,
          "lastAccessedLocationId": locationId,
          "lastAccessedLocationName": locationName,
          "logoLocation": '',
          "updatedBy": model.username,
          "updatedDate": DateTime.now().toIso8601String(),
          "userId": model.username,
          "userLanguage": model.language,
          "userMeasurementSystemValue": model.measurement,
          "userPressureUnit": model.pressureUnit,
        },
      );
      _checkApiError(createUserPreferenceResponse, "Preference Creation Failed");

      // Step 4: Assign role
      final assignRoleResponse = await ApiService.postApi(
        endpoint: ApiConstants.assignRole,
        body: {"username": model.username, "roleName": model.role},
      );
      _checkApiError(assignRoleResponse, "Role Assignment Failed");

      Get.snackbar(
        "Success",
        "User Created Successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.offAllNamed(AppPages.HOME);
      return true;
    } catch (e) {
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  void _checkApiError(Map<String, dynamic> response, String defaultMessage) {
    final message = response["message"];
    if (message == null || message.toString().trim().isEmpty) {
      throw Exception(response["errorMessage"] ?? defaultMessage);
    }
  }

  Future<List<CountryModel>> countryList() async {
    final response = await ApiService.getApi(
      endpoint: ApiConstants.getCountryList,
    );
    final model = response['model'];
    if (model != null && model is List && model.isNotEmpty) {
      return model.map<CountryModel>((e) => CountryModel.fromJson(e)).toList();
    }
    throw Exception("Failed to load country list");
  }




  Future<List<String>> getUserRole() async {
    final response = await ApiService.getApi(
      endpoint: ApiConstants.getRoleList,
    );
    if (response != null && response is List && response.isNotEmpty) {
      return List<String>.from(response);
    }
    throw Exception("Failed to load role list");
  }
}