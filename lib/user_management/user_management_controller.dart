import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emtrack/user_management/user_management_list_controller.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../services/api_constants.dart';
import '../services/offline_hive_service.dart';
import '../services/role_service.dart';

class UserManagementController extends GetxController {
  final loginFormKey = GlobalKey<FormState>();
  final personalFormKey = GlobalKey<FormState>();
  final preferenceFormKey = GlobalKey<FormState>();

  final currentStep = 0.obs;
  final int totalSteps = 3;

  final isLoading = false.obs;

  final firstNameFocus = FocusNode();
  final middleNameFocus = FocusNode();


  final usernameC = TextEditingController();
  final passwordC = TextEditingController();
  final emailC = TextEditingController();
  final firstNameC = TextEditingController();
  final middleNameC = TextEditingController();
  final lastNameC = TextEditingController();
  final phoneC = TextEditingController();

  final role = ''.obs;
  final country = ''.obs;
  final language = ''.obs;
  final measurement = ''.obs;
  final pressureUnit = ''.obs;

  final RxList<String> roles = <String>[].obs;
  final RxList<String> countries = <String>[].obs;

  final RxList<String> languages = <String>[].obs;
  final RxList<String> measurements = <String>[].obs;
  final RxList<String> pressureUnits = <String>[].obs;


  final Map<String, String> _countryCodeMap = {};

  @override
  void onInit() {
    super.onInit();
    _loadRoles();
    _loadCountries();
    _loadPreferenceLists();
  }

  void _loadPreferenceLists() {
    languages.assignAll([
      'English (US/Canada)',
      'Español',
      'English(uk/Australia)',
      'Deutsche',
      'Italiano',
      'français',
      '中文',
      'русский',
      'português',
      'polski',
      'serbian',
    ]);
    measurements.assignAll(['Metric', 'Imperial']);
    pressureUnits.assignAll(['PSI', 'KPA', 'BAR']);
  }

  Future<void> _loadRoles() async {
    try {
      final cookie = await SecureStorage.getCookie();
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getRoleList}'),
        headers: {'Content-Type': 'application/json', 'Cookie': cookie ?? ''},
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List raw = [];
        if (decoded is List)
          raw = decoded;
        else if (decoded['model'] is List)
          raw = decoded['model'];
        else if (decoded['data'] is List)
          raw = decoded['data'];

        final allRoles = raw
            .map<String>((r) {
          if (r is String) return r;
          return r['roleName']?.toString() ??
              r['name']?.toString() ??
              r.toString();
        })
            .where((s) => s.isNotEmpty)
            .toList();

        final currentRole = await SecureStorage.getUserProfileRole() ?? '';
        final allowedRoles = RoleService.assignableRoles(currentRole);
        roles.value = allowedRoles.isNotEmpty
            ? allRoles.where((r) => allowedRoles.contains(r)).toList()
            : allRoles;
      }
    } catch (e) {
      Get.snackbar(
        'Network Error',
        'Please check your network connection',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      final currentRole = await SecureStorage.getUserProfileRole() ?? '';
      final fallbackAll = [
        'EMTADMIN',
        'EMTUSER',
        'EMTAUSER',
        'EMTCADMIN',
        'EMTVO',
        'EMTSUADMIN',
      ];
      final allowedRoles = RoleService.assignableRoles(currentRole);
      roles.value = allowedRoles.isNotEmpty
          ? fallbackAll.where((r) => allowedRoles.contains(r)).toList()
          : fallbackAll;
    }
  }

  Future<void> _loadCountries() async {
    try {
      final cookie = await SecureStorage.getCookie();
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getAllCountryName}'),
        headers: {'Content-Type': 'application/json', 'Cookie': cookie ?? ''},
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List raw = [];
        if (decoded is List)
          raw = decoded;
        else if (decoded['model'] is List)
          raw = decoded['model'];
        else if (decoded['data'] is List)
          raw = decoded['data'];

        _countryCodeMap.clear();
        countries.value = [];
        for (final c in raw) {
          final name =
              c['countryName']?.toString() ?? c['name']?.toString() ?? '';
          final code =
              c['countryCode']?.toString() ??
                  c['code']?.toString() ??
                  c['countryId']?.toString() ??
                  '';
          if (name.isNotEmpty) {
            countries.add(name);
            _countryCodeMap[name] = code;
          }
        }
      }
    } catch (e) {
      Get.snackbar(
        'Network Error',
        'Please check your network connection',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      countries.value = ['India', 'USA', 'UK', 'Australia'];
      _countryCodeMap.addAll({
        'India': 'IN',
        'USA': 'US',
        'UK': 'GB',
        'Australia': 'AU',
      });
    }
  }

  void next() {
    if (currentStep.value < totalSteps - 1) currentStep.value++;
  }

  void previous() {
    if (currentStep.value > 0) currentStep.value--;
  }

  /// Genuine device-connectivity check (jaisa vehicle inspection flow
  /// me `_isOnline()` use hota hai) — sirf "no network" case ko
  /// "offline" maana jata hai, server-side errors ko nahi.
  Future<bool> _isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<void> submit() async {
    isLoading.value = true;
    try {
      final username = usernameC.text.trim();

      // ── OFFLINE: device ke paas genuinely network nahi hai -> user
      // creation (create user + profile + role + preference, saara
      // 4-step chain) ek single pending-operation ke roop me Hive me
      // queue kar do. Jaise hi connectivity wapas aayegi, auto-sync
      // (ManualSyncService) isko backend par chala dega.
      if (!await _isOnline()) {
        await _saveUserOffline(username);
        isLoading.value = false;

        Get.back();

        try {
          Get.find<UserManagementListController>().fetchUsers();
        } catch (_) {}

        Get.snackbar(
          'Saved Offline',
          'No internet connection. This user will be created automatically once you are back online.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      final userId = await _createUser(username);
      if (userId == null) {
        isLoading.value = false;
        return;
      }

      final profileOk = await _createUserProfile(userId, username);
      if (!profileOk) {
        isLoading.value = false;
        return;
      }

      final roleOk = await _assignRole(username);
      if (!roleOk) {
        isLoading.value = false;
        return;
      }

      await _createUserPreference(userId);

      isLoading.value = false;

      Get.back();

      try {
        Get.find<UserManagementListController>().fetchUsers();
      } catch (_) {}

      Get.snackbar(
        'Success',
        'User created successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Network Error',
        'Please check your network connection',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Poora "create user" 4-step payload (createUser + profile + role +
  /// preference) ek hi pending-operation me bundle karke Hive me save
  /// karta hai. Sync ke time `ManualSyncService` isi payload se saare
  /// 4 steps sequentially chalata hai (network_sync_servives.dart me
  /// `opType == 'createUser'` case dekho).
  Future<void> _saveUserOffline(String username) async {
    final parentAccountId = await SecureStorage.getParentAccountId();
    final locationId = await SecureStorage.getLocationId();
    final parentAccountName = await SecureStorage.getParentAccountName();
    final locationName = await SecureStorage.getLocationName();
    final countryCode = _countryCodeMap[country.value] ?? country.value;

    final payload = <String, dynamic>{
      // step 1: CreateUser
      'username': username,
      'password': passwordC.text.trim(),
      'email': emailC.text.trim(),
      // step 2: CreateUserProfile
      'firstName': firstNameC.text.trim(),
      'middleName': middleNameC.text.trim(),
      'lastName': lastNameC.text.trim(),
      'phoneNumber': phoneC.text.trim(),
      'countryCode': countryCode,
      'userRole': role.value,
      // step 3: AssignRole
      'roleName': role.value,
      // step 4: CreateUserPreference
      'userLanguage': language.value,
      'userMeasurementSystemValue': measurement.value,
      'userPressureUnit': pressureUnit.value,
      'lastAccessedAccountId': int.tryParse(parentAccountId ?? '0') ?? 0,
      'lastAccessedLocationId': int.tryParse(locationId ?? '0') ?? 0,
      'lastAccessedAccountName': parentAccountName ?? '',
      'lastAccessedLocationName': locationName ?? '',
    };

    await OfflineHiveService.addPendingOperation(
      opType: 'createUser',
      payload: payload,
      endpoint: ApiConstants.createUser,
      httpMethod: 'POST',
    );
  }

  Future<String?> _createUser(String username) async {
    try {
      final cookie = await SecureStorage.getCookie();
      final body = {
        "username": username,
        "password": passwordC.text.trim(),
        "email": emailC.text.trim(),
      };

      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createUser}'),
        headers: {'Content-Type': 'application/json', 'Cookie': cookie ?? ''},
        body: jsonEncode(body),
      );



      if (res.statusCode == 200 || res.statusCode == 201) {
        final decoded = jsonDecode(res.body);
        if (decoded is String) return decoded;
        if (decoded['model'] != null) return decoded['model'].toString();
        if (decoded['userId'] != null) return decoded['userId'].toString();
        if (decoded['id'] != null) return decoded['id'].toString();
        if (decoded['message'] != null &&
            decoded['message'].toString().contains('created successfully')) {
          return username;
        }
      }

      try {
        final decoded = jsonDecode(res.body);
        String errorMsg = 'Create user failed';
        if (decoded['errors'] is List && decoded['errors'].isNotEmpty) {
          errorMsg =
              decoded['errors'][0]['description']?.toString() ?? errorMsg;
        } else if (decoded['errorMessage'] != null) {
          errorMsg = decoded['errorMessage'].toString();
        } else if (decoded['message'] != null) {
          errorMsg = decoded['message'].toString();
        }
        Get.snackbar(
          'Error',
          errorMsg,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      } catch (_) {
        _showError('Create user failed (${res.statusCode})', res.body);
      }
      return null;
    } catch (e) {
      Get.snackbar(
        'Network Error',
        'Please check your network connection',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  Future<bool> _createUserProfile(String userId, String username) async {
    try {
      final cookie = await SecureStorage.getCookie();
      final countryCode = _countryCodeMap[country.value] ?? country.value;

      final body = {
        "userId": userId,
        "firstName": firstNameC.text.trim(),
        "middleName": middleNameC.text.trim(),
        "lastName": lastNameC.text.trim(),
        "emailAddress": emailC.text.trim(),
        "phoneNumber": phoneC.text.trim(),
        "countryCode": countryCode,
        "userRole": role.value,
        "updatedDate": DateTime.now().toIso8601String(),
      };

      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createUserProfile}'),
        headers: {'Content-Type': 'application/json', 'Cookie': cookie ?? ''},
        body: jsonEncode(body),
      );


      if (res.statusCode == 200 || res.statusCode == 201) return true;
      _showError('Create profile failed (${res.statusCode})', res.body);
      return false;
    } catch (e) {
      Get.snackbar(
        'Network Error',
        'Please check your network connection',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<bool> _assignRole(String username) async {
    try {
      final cookie = await SecureStorage.getCookie();
      final body = {"roleName": role.value, "username": username};

      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.assignRole}'),
        headers: {'Content-Type': 'application/json', 'Cookie': cookie ?? ''},
        body: jsonEncode(body),
      );


      if (res.statusCode == 200 || res.statusCode == 201) return true;
      _showError('Assign role failed (${res.statusCode})', res.body);
      return false;
    } catch (e) {
      Get.snackbar(
        'Network Error',
        'Please check your network connection',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }


  Future<void> _createUserPreference(String userId) async {
    try {
      final cookie = await SecureStorage.getCookie();
      final parentAccountId = await SecureStorage.getParentAccountId();
      final locationId = await SecureStorage.getLocationId();
      final parentAccountName = await SecureStorage.getParentAccountName();
      final locationName = await SecureStorage.getLocationName();

      final body = {
        "userId": userId,
        "userLanguage": language.value,
        "userMeasurementSystemValue": measurement.value,
        "userPressureUnit": pressureUnit.value,
        "logoLocation": "",
        "updatedBy": usernameC.text.trim(),
        "updatedDate": DateTime.now().toIso8601String(),
        "lastAccessedAccountId": int.tryParse(parentAccountId ?? '0') ?? 0,
        "lastAccessedLocationId": int.tryParse(locationId ?? '0') ?? 0,
        "lastAccessedAccountName": parentAccountName ?? "",
        "lastAccessedLocationName": locationName ?? "",
      };

      final res = await http.post(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.createUserPreference}',
        ),
        headers: {'Content-Type': 'application/json', 'Cookie': cookie ?? ''},
        body: jsonEncode(body),
      );


    } catch (e) {
    }
  }

  void _showError(String title, String msg) {
    String display = msg;
    try {
      final decoded = jsonDecode(msg);
      display =
          decoded['errorMessage']?.toString() ??
              decoded['message']?.toString() ??
              msg;
    } catch (_) {}
    Get.snackbar(
      title,
      display.length > 120 ? '${display.substring(0, 120)}...' : display,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void onClose() {
    usernameC.dispose();
    passwordC.dispose();
    emailC.dispose();
    firstNameC.dispose();
    middleNameC.dispose();
    lastNameC.dispose();
    phoneC.dispose();
    firstNameFocus.dispose();
    middleNameFocus.dispose();
    super.onClose();
  }
}