import 'dart:io';
import 'package:flutter/services.dart';


class SecurityGuard {
  static const _channel = MethodChannel('com.example.emtrack/security');

  static const String _expectedSignatureSha256 =
      'REPLACE_WITH_YOUR_RELEASE_CERT_SHA256_FINGERPRINT_64_HEX_CHARS';
  static Future<bool> isDeviceRooted() async {
    try {
      if (Platform.isAndroid) {
        const rootPaths = [
          '/system/app/Superuser.apk',
          '/system/app/SuperSU.apk',
          '/sbin/su',
          '/system/bin/su',
          '/system/xbin/su',
          '/data/local/xbin/su',
          '/data/local/bin/su',
          '/system/sd/xbin/su',
          '/system/bin/failsafe/su',
          '/data/local/su',
          '/su/bin/su',
          '/system/xbin/which',
        ];
        for (final path in rootPaths) {
          if (await File(path).exists()) return true;
        }

        try {
          final result = await Process.run('getprop', ['ro.build.tags']);
          if (result.stdout.toString().contains('test-keys')) return true;
        } catch (_) {}

        const rootPackages = [
          'com.topjohnwu.magisk',
          'com.noshufou.android.su',
          'com.thirdparty.superuser',
          'eu.chainfire.supersu',
          'com.koushikdutta.superuser',
          'com.zachspong.temprootremovejb',
          'com.ramdroid.appquarantine',
        ];
        for (final pkg in rootPackages) {
          try {
            final r = await Process.run('pm', ['list', 'packages', pkg]);
            if (r.stdout.toString().contains(pkg)) return true;
          } catch (_) {}
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }


  static Future<bool> isAppTampered() async {
    if (_expectedSignatureSha256.startsWith('REPLACE_')) {
      return false;
    }

    try {
      if (Platform.isAndroid) {
        final String? actualFingerprint =
        await _channel.invokeMethod<String>('getSignatureFingerprint');

        if (actualFingerprint == null || actualFingerprint.isEmpty) {
          return true;
        }

        final normalised = actualFingerprint
            .toUpperCase()
            .replaceAll(':', '')
            .replaceAll(' ', '');

        return normalised != _expectedSignatureSha256.toUpperCase();
      }
      return false;
    } on MissingPluginException {
      assert(() {
        return true;
      }());
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<SecurityCheckResult> runChecks() async {
    final rooted = await isDeviceRooted();
    final tampered = await isAppTampered();
    return SecurityCheckResult(isRooted: rooted, isTampered: tampered);
  }
}

class SecurityCheckResult {
  final bool isRooted;
  final bool isTampered;

  const SecurityCheckResult({
    required this.isRooted,
    required this.isTampered,
  });

  bool get hasIssues => isRooted || isTampered;

  String get message {
    if (isRooted && isTampered) {
      return 'This device is rooted and the app may have been tampered with. '
          'For security reasons, the app cannot run.';
    } else if (isRooted) {
      return 'This app cannot run on a rooted device for security reasons.';
    } else if (isTampered) {
      return 'App integrity check failed. Please reinstall from the official source.';
    }
    return '';
  }
}