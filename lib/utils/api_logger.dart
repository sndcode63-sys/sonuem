import 'package:flutter/foundation.dart';

/// Terminal logger: API calls are printed in RED so they are easy to spot
/// in the `flutter run` / VS Code / Android Studio console.
///
/// Every physical line gets its own colour start + reset code, so colours
/// survive debugPrint's line wrapping and logcat chunking.
class ApiLog {
  static const String _red = '\x1B[31m';
  static const String _boldRed = '\x1B[1;31m';
  static const String _reset = '\x1B[0m';

  static void _print(String text, {bool bold = false}) {
    final color = bold ? _boldRed : _red;
    const chunk = 700;
    for (final line in text.split('\n')) {
      if (line.length <= chunk) {
        debugPrint('$color$line$_reset');
        continue;
      }
      for (var i = 0; i < line.length; i += chunk) {
        final end = (i + chunk < line.length) ? i + chunk : line.length;
        debugPrint('$color${line.substring(i, end)}$_reset');
      }
    }
  }

  /// Banner shown right before an API is hit.
  static void request({
    required String name,
    required String method,
    required Uri url,
    Map<String, dynamic>? fields,
    List<String>? files,
    String? body,
  }) {
    _print('════════════════════════════════════════════════════════', bold: true);
    _print('🌐 API CALL  ➜  $name', bold: true);
    _print('   $method  $url');
    if (fields != null && fields.isNotEmpty) _print('   fields : $fields');
    if (files != null && files.isNotEmpty) _print('   files  : $files');
    if (body != null && body.isNotEmpty) _print('   body   : $body');
  }

  static void response({
    required String name,
    required int statusCode,
    required String body,
  }) {
    final ok = statusCode >= 200 && statusCode < 300;
    _print('${ok ? '✅' : '❌'} API RESPONSE ← $name  (HTTP $statusCode)', bold: true);
    _print('   body: ${body.isEmpty ? '<empty>' : body}');
    _print('════════════════════════════════════════════════════════', bold: true);
  }

  static void info(String name, String message) =>
      _print('ℹ️  [$name] $message');

  static void error(String name, String message) {
    _print('❌ [$name] $message', bold: true);
    _print('════════════════════════════════════════════════════════', bold: true);
  }
}
