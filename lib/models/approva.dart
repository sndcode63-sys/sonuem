import 'package:emtrack/services/api_constants.dart';
import 'package:emtrack/services/api_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class ApprovalWorkflowResult {
  final bool matched;
  final bool isEnabled;
  final bool? rawFlag;
  final String reason;

  const ApprovalWorkflowResult({
    required this.matched,
    required this.isEnabled,
    required this.rawFlag,
    required this.reason,
  });
}

class ApprovalWorkflowService {
  /// Resolves the approval-workflow flag for a single GrandParentAccount by
  /// calling it directly instead of fetching the entire list:
  ///
  ///   GET /api/GrandParentAccount/FindById/{grandParentAccountId}
  ///
  /// This is the per-user login check: for the currently logged-in user we
  /// already know their grandParentAccountId (from UserProfile), so we ask
  /// the server for that ONE record and read `isApprovalWorkflowEnabled`
  /// straight off it — no client-side matching against a full list needed.
  Future<ApprovalWorkflowResult> resolveForGrandParentAccount(
      int? grandParentAccountId,
      ) async {
    if (grandParentAccountId == null) {
      const reason =
          'User profile has no grandParentAccountId (null) — skipping '
          'GrandParentAccount/FindById lookup. Falling back to '
          'approval workflow DISABLED.';
      AppLogger.warn('[ApprovalWorkflowService] $reason');
      return const ApprovalWorkflowResult(
        matched: false,
        isEnabled: false,
        rawFlag: null,
        reason: reason,
      );
    }

    final endpoint =
    ApiConstants.findGrandParentAccountById(grandParentAccountId);

    Map<String, dynamic>? record;
    try {
      debugPrint(
        '🏢 [ApprovalWorkflowService] Fetching GrandParentAccount '
            'GET $endpoint for user\'s approval-workflow status...',
      );

      final response = await ApiService.getApi(endpoint: endpoint);

      // FindById wraps the single record in "model" (see sample response),
      // but be defensive in case it's ever returned raw or under "data".
      if (response is Map) {
        final m = response['model'] ?? response['data'] ?? response;
        if (m is Map) {
          record = Map<String, dynamic>.from(m);
        } else if (m is List && m.isNotEmpty && m.first is Map) {
          record = Map<String, dynamic>.from(m.first as Map);
        }
      }

      debugPrint(
        '🏢 [ApprovalWorkflowService] FindById response for '
            'grandParentAccountId=$grandParentAccountId: $record',
      );
    } catch (e) {
      final reason =
          'GET $endpoint failed ($e) — could not fetch '
          'grandParentAccountId=$grandParentAccountId. Falling '
          'back to approval workflow DISABLED until the next successful check.';
      AppLogger.error('[ApprovalWorkflowService] $reason');
      return ApprovalWorkflowResult(
        matched: false,
        isEnabled: false,
        rawFlag: null,
        reason: reason,
      );
    }

    if (record == null || record.isEmpty) {
      final reason =
          'grandParentAccountId=$grandParentAccountId returned no record '
          'from FindById. Falling back to approval workflow DISABLED.';
      AppLogger.warn('[ApprovalWorkflowService] $reason');
      return ApprovalWorkflowResult(
        matched: false,
        isEnabled: false,
        rawFlag: null,
        reason: reason,
      );
    }

    final rawFlag = record['isApprovalWorkflowEnabled'] as bool?;
    final isEnabled = rawFlag == true;
    final name = record['grandParentAccountName'] ?? record['name'] ?? '';

    final reason = rawFlag == null
        ? 'Fetched grandParentAccountId=$grandParentAccountId '
        '("$name") but isApprovalWorkflowEnabled was null/missing in '
        'the FindById response — treating as DISABLED.'
        : 'Fetched grandParentAccountId=$grandParentAccountId '
        '("$name") — isApprovalWorkflowEnabled=$rawFlag from '
        'FindById response, so approval workflow is '
        '${isEnabled ? "ENABLED" : "DISABLED"} for this account.';

    AppLogger.success('[ApprovalWorkflowService] $reason');

    return ApprovalWorkflowResult(
      matched: true,
      isEnabled: isEnabled,
      rawFlag: rawFlag,
      reason: reason,
    );
  }

  Future<ApprovalWorkflowResult> resolveAndCache(
      int? grandParentAccountId,
      ) async {
    final result = await resolveForGrandParentAccount(grandParentAccountId);

    await SecureStorage.saveApprovalWorkflowStatus(
      isEnabled: result.isEnabled,
      matched: result.matched,
    );

    AppLogger.info(
      '[ApprovalWorkflowService] Cached to SecureStorage -> '
          'approvalWorkflowEnabled=${result.isEnabled}, matched=${result.matched}',
    );

    return result;
  }
}

class AppLogger {
  static const String _reset = '\x1B[0m';
  static const String _bold = '\x1B[1m';

  static const String _green = '\x1B[32m';
  static const String _cyan = '\x1B[36m';
  static const String _yellow = '\x1B[33m';
  static const String _red = '\x1B[31m';

  static void _printBold(String message, String color) {
    // ignore: avoid_print
    print('$_bold$color$message$_reset');
  }

  static void success(String message) => _printBold('✅ $message', _green);
  static void info(String message) => _printBold('ℹ️ $message', _cyan);
  static void warn(String message) => _printBold('⚠️ $message', _yellow);
  static void error(String message) => _printBold('❌ $message', _red);
}