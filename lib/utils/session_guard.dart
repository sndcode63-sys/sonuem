import 'dart:async';
import 'package:flutter/cupertino.dart';

import 'package:emtrack/services/auth_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:emtrack/routes/app_pages.dart';
import 'package:emtrack/search_tyre_vehicle/Search_vehicle_tyre_controller.dart';
import 'package:emtrack/inspection_approval/search.dart';
import 'package:get/get.dart';

class SessionGuard {

  static bool _isValidating = false;
  static DateTime? _lastValidated;
  static Future<bool> validateSession({
    bool forceRefresh = false,
  }) async {
    if (_isValidating) return true;

    if (!forceRefresh && _lastValidated != null) {
      final elapsed = DateTime.now().difference(_lastValidated!).inMinutes;
      if (elapsed < 5) {
        return true;
      }
    }

    _isValidating = true;
    try {
      final username = await SecureStorage.getUserName();
      final password = await SecureStorage.getPassword();
      final cookie   = await SecureStorage.getCookie();

      if (username == null || username.isEmpty ||
          password == null || password.isEmpty) {
        _goToLogin();
        return false;
      }

      if (cookie == null || cookie.isEmpty) {
        return await _refreshAndValidate(username, password);
      }

      _lastValidated = DateTime.now();
      return true;

    } catch (e) {
      return true;
    } finally {
      _isValidating = false;
    }
  }


  static Future<bool> _refreshAndValidate(
      String username, String password) async {
    try {
      final result = await AuthService.login(username, password)
          .timeout(const Duration(seconds: 15));

      if (result != null) {
        await SecureStorage.saveToken(result.token);
        _lastValidated = DateTime.now();
        return true;
      } else {
        _goToLogin();
        return false;
      }
    } on TimeoutException {
      return true;
    } catch (e) {
      return true;
    }
  }

  static Future<bool> hasValidLocalSession() async {
    final cookie = await SecureStorage.getCookie();
    final user   = await SecureStorage.getUserName();
    final pass   = await SecureStorage.getPassword();

    return cookie != null && cookie.isNotEmpty &&
        user   != null && user.isNotEmpty   &&
        pass   != null && pass.isNotEmpty;
  }


  static Future<void> manualLogout() async {
    _lastValidated = null;

    await SecureStorage.clearToken();
    await SecureStorage.clearCookie();
    await SecureStorage.clearUserName();

    await SecureStorage.clearPassword();
    await SecureStorage.saveUserProfileRole('');
    await SecureStorage.saveUserProfileName('');
    await SecureStorage.saveParentAccount(id: '', name: '');
    await SecureStorage.saveLocation(id: '', name: '');
    // ✅ FIX: multi-select "selected locations" (Home dashboard combined
    // view) ab tak sirf global keys mein save hote the aur logout par
    // clear nahi hote the — isliye purane account ka location, naye
    // account login karne par bhi "selected" dikhta rehta tha. Ab
    // logout par yeh bhi clear karo.
    await SecureStorage.clearSelectedLocations();

    // ✅ FIX: Clear Recent Search cache (Vehicles & Tyres) on logout
    // so previous user's recent search items are never visible to next user/session.
    await SecureStorage.clearVehicle();
    await SecureStorage.clearTyre();

    try {
      if (Get.isRegistered<SearchVehicleTyreController>()) {
        final sc = Get.find<SearchVehicleTyreController>();
        sc.recentVehicles.clear();
        sc.recentTyres.clear();
        sc.updateVisibleList();
      }
    } catch (_) {}

    try {
      if (Get.isRegistered<IWSearchController>(tag: 'iw_search')) {
        final iw = Get.find<IWSearchController>(tag: 'iw_search');
        iw.recentVehicles.clear();
        iw.recentTyres.clear();
      }
    } catch (_) {}

    _goToLogin();
  }

  static void showSessionExpiredDialog({
    String title = "Profile Load Failed",
    String message = "Unable to load user profile from server. Please log in again.",
  }) {
    if (Get.isDialogOpen == true) return;
    Get.dialog(
      CupertinoAlertDialog(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            message,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              Get.back();
              await manualLogout();
              Get.offAllNamed(AppPages.LOGIN);
            },
            child: const Text(
              'Log In Again',
              style: TextStyle(color: CupertinoColors.systemRed),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  static void resetValidationTimer() {
    _lastValidated = DateTime.now();
  }

  static void _goToLogin() {
    try {
      final current = Get.currentRoute;
      if (current == AppPages.LOGIN || current == AppPages.SPLASH) return;
    } catch (_) {}
    Get.offAllNamed(AppPages.LOGIN);
  }
}