import 'package:emtrack/utils/hive_prefe.dart';
import 'package:flutter/cupertino.dart';

import '../l10n/app_localizations.dart';

class LocaleHelper {
  static String get _lang =>
      HivePref.get<String>('pref_language_display') ?? '';

  static String get _langCode =>
      (HivePref.get<String>('pref_language_code') ?? '').toLowerCase();

  /// UK/Australia preference => DD/MM/YYYY, baaki sab (US/Canada) => MM/DD/YYYY
  static bool get _isUK =>
      _lang == 'English(uk/Australia)' ||
          (_lang.isEmpty && _langCode == 'en-uk');

  /// Returns Singular: 'Tyre' (UK) or 'Tire' (US/Other)
  static String tyreName(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (_lang.toLowerCase().contains('english')) {
      return _isUK ? 'Tyre' : 'Tire';
    }
    return t.tyresLabel;
  }

  /// Returns Plural: 'Tyres' (UK) or 'Tires' (US/Other)
  static String tyresName(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (_lang.toLowerCase().contains('english')) {
      return _isUK ? 'Tyres' : 'Tires';
    }
    return t.tyresLabel;
  }

  static bool get isDayFirst => _isUK;

  static String formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return _isUK ? '$d/$m/$y' : '$m/$d/$y';
  }

  static String formatApiDate(String? apiDate) {
    if (apiDate == null || apiDate.isEmpty) return '-';
    try {
      final raw      = apiDate.trim();
      final datePart = raw.contains('T') ? raw.split('T')[0] : raw.split(' ')[0];
      final parts    = datePart.split('-');
      if (parts.length < 3) return raw;
      final year  = parts[0];
      final month = parts[1];
      final day   = parts[2];
      return _isUK ? '$day/$month/$year' : '$month/$day/$year';
    } catch (_) {
      return '-';
    }
  }

  static const List<String> _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  /// Date picker header: UK => "Mon, 5 Oct" | US/Canada => "Mon, Oct 5"
  static String formatPickerHeader(DateTime date) {
    final wd = _weekdays[date.weekday - 1];
    final mon = _months[date.month - 1];
    return _isUK ? '$wd, ${date.day} $mon' : '$wd, $mon ${date.day}';
  }

  /// Long readable date: UK => "5 Oct 2026" | US/Canada => "Oct 5, 2026"
  static String formatLongDate(DateTime date) {
    final mon = _months[date.month - 1];
    return _isUK
        ? '${date.day} $mon ${date.year}'
        : '$mon ${date.day}, ${date.year}';
  }

  static String _time12(DateTime l) {
    final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
    final mi = l.minute.toString().padLeft(2, '0');
    final ap = l.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:$mi $ap';
  }

  /// Numeric date + 12h time: UK => "05/10/2026 03:45 PM" | US => "10/05/2026 03:45 PM"
  /// Parse na ho paye to [fallback] (default: raw string) return hota hai.
  static String formatDateTime(String? raw, {String? fallback}) {
    if (raw == null || raw.trim().isEmpty) return fallback ?? '--';
    final dt = DateTime.tryParse(raw.trim());
    if (dt == null) return fallback ?? raw;
    final l = dt.toLocal();
    return '${formatDate(l)} ${_time12(l)}';
  }

  /// Long date + 12h time: UK => "5 Oct 2026, 3:45 PM" | US => "Oct 5, 2026, 3:45 PM"
  static String formatLongDateTime(DateTime l) {
    final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
    final mi = l.minute.toString().padLeft(2, '0');
    final ap = l.hour >= 12 ? 'PM' : 'AM';
    return '${formatLongDate(l)}, $h:$mi $ap';
  }

  static DateTime? parseDisplayDate(String text) {
    try {
      final parts = text.trim().split('/');
      if (parts.length != 3) return null;
      if (_isUK) {
        // DD/MM/YYYY
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      } else {
        // MM/DD/YYYY
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }
    } catch (_) {
      return null;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}