import 'dart:io';
import 'package:emtrack/services/api_constants.dart';
import 'package:emtrack/services/global_logout_handler.dart';
import 'package:emtrack/services/network_sync_servives.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/utils/app_lifecycle.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:emtrack/utils/security_guard.dart';
import 'package:emtrack/utils/sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../routes/app_pages.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(_anim);
    _anim.forward();

    _start();
  }

  Future<void> _start() async {
    // 🌐 Proactively trigger network socket lookup so iOS asks for "Allow Wireless Data" on Splash screen!
    _triggerNetworkWarmup();

    final securityResult = await SecurityGuard.runChecks();

    if (securityResult.hasIssues) {
      if (mounted) {
        _showSecurityBlockDialog(securityResult.message);
      }
      return;
    }

    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      _initServices(),
    ]);

    if (mounted) _navigate();
  }

  void _triggerNetworkWarmup() {
    try {
      final uri = Uri.tryParse(ApiConstants.baseUrl);
      final host = uri?.host ?? 'emtrackotrapi-staging.azurewebsites.net';
      InternetAddress.lookup(host).catchError((_) => <InternetAddress>[]);
    } catch (_) {}
  }

  void _showSecurityBlockDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
        },
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.security, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Security Alert',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                SystemNavigator.pop();
              },
              child: const Text(
                'Exit App',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),    );
  }

  Future<void> _initServices() async {
    try {
      await SyncHiveService.init();
      await OfflineHiveService.init();
      await SecureStorage.loadAll();

      ManualSyncService.setup(
        baseUrl: ApiConstants.baseUrl,
        getCookie: SecureStorage.getCookie,
        enableAutoSync: true,
      );

      Get.put(GlobalLogoutHandler(), permanent: true);
      Get.put(AppLifecycleService(), permanent: true);

      _tryStartupSync();
    } catch (_) {}
  }

  void _tryStartupSync() {
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        if (ManualSyncService.pendingCount() <= 0) return;
        if (!await ManualSyncService.isOnline()) return;
        if (ManualSyncService.isSyncing) return;
        await ManualSyncService.syncNow();
      } catch (_) {}
    });
  }

  void _navigate() async {
    final username = await SecureStorage.getUserName();
    final token = await SecureStorage.getToken();

    final loggedIn =
        username != null &&
        username.isNotEmpty &&
        token != null &&
        token.isNotEmpty;

    if (!loggedIn) {
      Get.offAllNamed(AppPages.LOGIN);
      return;
    }

    bool hasData = false;
    try {
      hasData =
          OfflineHiveService.getVehicles().isNotEmpty ||
          OfflineHiveService.getMasterData() != null;
    } catch (_) {}

    Get.offAllNamed(hasData ? AppPages.HOME : AppPages.DOWNLOAD);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo.png', width: 180),
                const SizedBox(height: 15),
                Image.asset('assets/images/apk_logo.png', width: 150),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
