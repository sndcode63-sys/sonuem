import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:emtrack/services/auth_service.dart';
import 'package:emtrack/services/network_sync_servives.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:emtrack/routes/app_pages.dart';

class AppLifecycleService extends GetxService with WidgetsBindingObserver {



  DateTime? _backgroundedAt;
  bool _isRefreshing = false;


  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _backgroundedAt = DateTime.now();
        break;

      case AppLifecycleState.resumed:
        _onAppResumed();
        break;

      default:
        break;
    }
  }

  void _onAppResumed() {
    final bg = _backgroundedAt;
    if (bg == null) return;

    _backgroundedAt = null;

    _triggerSyncIfNeeded();
  }

  Future<void> _silentRefreshCookie() async {
    if (_isRefreshing) {
      return;
    }
    _isRefreshing = true;

    try {
      final username = await SecureStorage.getUserName();
      final password = await SecureStorage.getPassword();

      if (username == null || username.isEmpty ||
          password == null || password.isEmpty) {

        return;
      }


      final result = await AuthService.login(username, password)
          .timeout(const Duration(seconds: 20));

      if (result != null) {
        await SecureStorage.saveToken(result.token);
      } else {

        _safeGoToLogin();
      }

    } catch (_) {
    } finally {
      _isRefreshing = false;
    }
  }

  void _triggerSyncIfNeeded() {
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        final pending = ManualSyncService.pendingCount();
        if (pending > 0) {
          final _ = await ManualSyncService.syncNow();

        } else {
        }
      } catch (_) {
      }
    });
  }


  void _safeGoToLogin() {
    try {
      final current = Get.currentRoute;
      if (current == AppPages.LOGIN || current == AppPages.SPLASH) return;
    } catch (_) {}
    Get.offAllNamed(AppPages.LOGIN);
  }

  Future<void> forceRefresh() async {
    _isRefreshing = false;
    await _silentRefreshCookie();
  }
}