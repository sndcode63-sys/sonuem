import 'local_helper.dart';
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emtrack/inspection_approval/search.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../l10n/app_localizations.dart';
import 'approval_localizations.dart';

enum PendingBlockedAction {
  inspection,
  installTyre,
  updateHours,
  tyreInspection,
  rotateTyres,
  uploadImage,
  deleteImage,
  editTyre,
  cloneTyre,
  editVehicle,
}

class PendingCheckResult {
  final bool hasPending;
  final String? submittedBy;
  final String? submittedDate;

  const PendingCheckResult({
    required this.hasPending,
    this.submittedBy,
    this.submittedDate,
  });

  static const none = PendingCheckResult(hasPending: false);
}

class PendingInspectionGuard {
  PendingInspectionGuard._();

  static const Duration _ttl = Duration(seconds: 30);
  static const Duration _apiTimeout = Duration(seconds: 8);
  static const String _tag = '🔒 [PendingGuard]';

  static final SearchApi _api = SearchApi();

  static final Map<int, PendingCheckResult> _pending = {};
  static final Map<int, PendingCheckResult> _pendingTires = {};
  static DateTime? _fetchedAt;
  static int? _fetchedForAccount;
  static Future<void>? _inFlight;

  static final RxSet<int> pendingVehicleIds = <int>{}.obs;
  static final RxSet<int> pendingTireIds = <int>{}.obs;

  static Future<bool> _isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  static Future<void> prefetch({bool force = false}) async {
    try {
      if (!await SecureStorage.getApprovalWorkflowEnabled()) return;
      await _refreshIfNeeded(force: force);
    } catch (e) {
      debugPrint('$_tag prefetch EXCEPTION (ignored, fail-open) -> $e');
    }
  }

  static Future<void> _refreshIfNeeded({bool force = false}) {
    // Concurrent calls ek hi request share karengi.
    if (_inFlight != null) return _inFlight!;
    _inFlight = _refresh(force: force).whenComplete(() => _inFlight = null);
    return _inFlight!;
  }

  static Future<void> _refresh({required bool force}) async {
    final accountId = int.tryParse(await SecureStorage.getParentAccountId() ?? '');
    if (accountId == null) return;

    final fresh = _fetchedAt != null &&
        _fetchedForAccount == accountId &&
        DateTime.now().difference(_fetchedAt!) < _ttl;
    if (fresh && !force) return;

    if (!await _isOnline()) {
      debugPrint('$_tag offline -> purani/local state use hogi (fail-open)');
      return;
    }

    try {
      final entries =
      await _api.fetchPendingInspections(accountId).timeout(_apiTimeout);

      final Map<int, PendingCheckResult> nextVehicles = {};
      final Map<int, PendingCheckResult> nextTires = {};

      for (final e in entries) {
        // Sirf PENDING (statusId 1 / null). Approved(2)/Rejected(3) ignore.
        final sid = e.status?.statusId;
        if (sid != null && sid != 1) continue;

        final result = PendingCheckResult(
          hasPending: true,
          submittedBy: e.status?.createdBy ?? e.status?.modifiedBy,
          submittedDate: e.status?.createdDate,
        );

        final vIds = <int>{
          if (e.vehicle?.vehicleId != null) e.vehicle!.vehicleId!,
          if (e.tire?.vehicleId != null) e.tire!.vehicleId!,
          for (final t in e.tiresList)
            if (t.vehicleId != null) t.vehicleId!,
        }..removeWhere((id) => id <= 0);

        for (final id in vIds) {
          nextVehicles.putIfAbsent(id, () => result);
        }

        final tIds = <int>{
          if (e.tire?.tireId != null) e.tire!.tireId!,
          for (final t in e.tiresList)
            if (t.tireId != null) t.tireId!,
        }..removeWhere((id) => id <= 0);

        for (final id in tIds) {
          nextTires.putIfAbsent(id, () => result);
        }
      }

      _pending
        ..clear()
        ..addAll(nextVehicles);
      pendingVehicleIds
        ..clear()
        ..addAll(nextVehicles.keys);

      _pendingTires
        ..clear()
        ..addAll(nextTires);
      pendingTireIds
        ..clear()
        ..addAll(nextTires.keys);

      _fetchedAt = DateTime.now();
      _fetchedForAccount = accountId;
      debugPrint('$_tag refreshed -> ${nextVehicles.length} pending vehicle(s), ${nextTires.length} pending tyre(s)');
    } catch (e) {
      // fail-open: API fail/timeout par kaam nahi rukega.
      debugPrint('$_tag fetch FAILED (fail-open) -> $e');
    }
  }

  /// Sync lookup (cache se) — UI banner ke liye.
  static PendingCheckResult peek(int? vehicleId) {
    if (vehicleId == null || vehicleId == 0) return PendingCheckResult.none;
    return _pending[vehicleId] ?? PendingCheckResult.none;
  }

  /// Async check — cache stale ho to pehle refresh karta hai.
  static Future<PendingCheckResult> check(int? vehicleId) async {
    if (vehicleId == null || vehicleId == 0) return PendingCheckResult.none;
    try {
      if (!await SecureStorage.getApprovalWorkflowEnabled()) {
        return PendingCheckResult.none;
      }
      await _refreshIfNeeded();
    } catch (e) {
      debugPrint('$_tag check EXCEPTION (fail-open) -> $e');
    }
    return peek(vehicleId);
  }

  /// Temp API se submit hote hi call karo — server list update hone ka
  /// wait kiye bina vehicle turant lock ho jata hai.
  static void markPending(int? vehicleId, {String? submittedBy, Iterable<int>? tireIds}) {
    if (vehicleId != null && vehicleId != 0) {
      final res = PendingCheckResult(
        hasPending: true,
        submittedBy: submittedBy,
        submittedDate: DateTime.now().toIso8601String(),
      );
      _pending[vehicleId] = res;
      pendingVehicleIds.add(vehicleId);

      final tyres = OfflineHiveService.getTyresByVehicle(vehicleId);
      for (final t in tyres) {
        if (t.tireId > 0) {
          _pendingTires[t.tireId] = res;
          pendingTireIds.add(t.tireId);
        }
      }
    }
    if (tireIds != null) {
      final res = PendingCheckResult(
        hasPending: true,
        submittedBy: submittedBy,
        submittedDate: DateTime.now().toIso8601String(),
      );
      for (final tid in tireIds) {
        if (tid > 0) {
          _pendingTires[tid] = res;
          pendingTireIds.add(tid);
        }
      }
    }
    // Agli baar server se fresh list aaye.
    _fetchedAt = null;
  }

  /// Logout / account change par cache saaf karo.
  static void clear() {
    _pending.clear();
    _pendingTires.clear();
    pendingVehicleIds.clear();
    pendingTireIds.clear();
    _fetchedAt = null;
    _fetchedForAccount = null;
  }

  /// `true` => aage badh sakte ho. Tyre ya uska vehicle pending ho to dialog dikhake `false`.
  static Future<bool> canProceedForTire({
    required int? tireId,
    String? tireSerialNo,
    required PendingBlockedAction action,
  }) async {
    if (tireId == null || tireId <= 0) return true;

    // 📴 Offline unsynced check
    if (OfflineHiveService.hasUnsyncedInspectionSubmitForTire(
        tireId, tireSerialNo: tireSerialNo)) {
      debugPrint('$_tag BLOCKED TIRE (offline, not synced) action=$action tireId=$tireId');
      await PendingApprovalDialog.show(
        tireSerialNo: tireSerialNo,
        action: action,
        offlineUnsynced: true,
      );
      return false;
    }

    // Online check
    try {
      if (!await SecureStorage.getApprovalWorkflowEnabled()) {
        return true;
      }
      await _refreshIfNeeded();
    } catch (e) {
      debugPrint('$_tag check tire EXCEPTION (fail-open) -> $e');
    }

    PendingCheckResult? result = _pendingTires[tireId];

    if (result == null || !result.hasPending) {
      final hiveTyre = OfflineHiveService.getTyreById(tireId);
      if (hiveTyre != null && hiveTyre.vehicleId != null && hiveTyre.vehicleId! > 0) {
        final vResult = _pending[hiveTyre.vehicleId!];
        if (vResult != null && vResult.hasPending) {
          result = vResult;
        }
      }
    }

    if (result != null && result.hasPending) {
      debugPrint('$_tag BLOCKED TIRE action=$action tireId=$tireId');
      await PendingApprovalDialog.show(
        tireSerialNo: tireSerialNo,
        action: action,
        submittedBy: result.submittedBy,
        submittedDate: result.submittedDate,
      );
      return false;
    }

    return true;
  }

  /// `true` => aage badh sakte ho. Pending ho to dialog dikhake `false`.
  static Future<bool> canProceed({
    required int? vehicleId,
    String? vehicleNumber,
    required PendingBlockedAction action,
  }) async {
    // 📴 Offline submit ho chuka hai par abhi sync nahi hua -> block.
    // (Approval workflow ON/OFF se independent, aur negative temp id par bhi.)
    if ((vehicleId != null &&
        OfflineHiveService.hasUnsyncedInspectionSubmitForVehicle(vehicleId, vehicleNumber: vehicleNumber)) ||
        (vehicleNumber != null && vehicleNumber.trim().isNotEmpty &&
        OfflineHiveService.hasUnsyncedInspectionSubmitForVehicle(0, vehicleNumber: vehicleNumber))) {
      debugPrint('$_tag BLOCKED (offline, not synced) action=$action vehicleId=$vehicleId, vehicleNumber=$vehicleNumber');
      await PendingApprovalDialog.show(
        vehicleNumber: vehicleNumber,
        action: action,
        offlineUnsynced: true,
      );
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final keysToCheck = [
        if (vehicleId != null) 'pending_inspection_payload_$vehicleId',
        if (vehicleNumber != null && vehicleNumber.trim().isNotEmpty) 'pending_inspection_payload_${vehicleNumber.trim()}',
      ];
      for (final k in keysToCheck) {
        if (prefs.getString(k) != null) {
          debugPrint('$_tag BLOCKED (local pending payload in prefs: $k) action=$action');
          await PendingApprovalDialog.show(
            vehicleNumber: vehicleNumber,
            action: action,
            offlineUnsynced: true,
          );
          return false;
        }
      }
    } catch (_) {}

    final result = await check(vehicleId);
    if (!result.hasPending) return true;

    debugPrint('$_tag BLOCKED action=$action vehicleId=$vehicleId');
    await PendingApprovalDialog.show(
      vehicleNumber: vehicleNumber,
      action: action,
      submittedBy: result.submittedBy,
      submittedDate: result.submittedDate,
    );
    return false;
  }
}

/// Sundar "Approval Pending" dialog.
class PendingApprovalDialog {
  PendingApprovalDialog._();

  static Future<void> show({
    String? vehicleNumber,
    String? tireSerialNo,
    required PendingBlockedAction action,
    String? submittedBy,
    String? submittedDate,
    bool offlineUnsynced = false,
  }) async {
    await Get.dialog(
      _PendingApprovalCard(
        vehicleNumber: vehicleNumber,
        tireSerialNo: tireSerialNo,
        action: action,
        submittedBy: submittedBy,
        submittedDate: submittedDate,
        offlineUnsynced: offlineUnsynced,
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
    );
  }
}

class _PendingApprovalCard extends StatelessWidget {
  final String? vehicleNumber;
  final String? tireSerialNo;
  final PendingBlockedAction action;
  final String? submittedBy;
  final String? submittedDate;
  final bool offlineUnsynced;

  const _PendingApprovalCard({
    this.vehicleNumber,
    this.tireSerialNo,
    required this.action,
    this.submittedBy,
    this.submittedDate,
    this.offlineUnsynced = false,
  });

  static const _red = Color(0xFFE53935);
  static const _darkRed = Color(0xFFB71C1C);
  static const _amber = Color(0xFFF59E0B);

  String _title(ApprovalLocalizations a) {
    switch (action) {
      case PendingBlockedAction.installTyre:
        return a.cannotInstallTyre;
      case PendingBlockedAction.updateHours:
        return a.cannotUpdateHoursKm;
      case PendingBlockedAction.tyreInspection:
        return a.cannotInspectTyre;
      case PendingBlockedAction.rotateTyres:
        return a.cannotRotateTyres;
      case PendingBlockedAction.uploadImage:
        return a.cannotUploadImage;
      case PendingBlockedAction.deleteImage:
        return a.cannotDeleteImage;
      case PendingBlockedAction.inspection:
        return a.cannotSubmitInspection;
      case PendingBlockedAction.editTyre:
        return a.cannotEditTyre;
      case PendingBlockedAction.cloneTyre:
        return a.cannotCloneTyre;
      case PendingBlockedAction.editVehicle:
        return a.cannotEditVehicle;
    }
  }

  String _message(ApprovalLocalizations a) {
    if (offlineUnsynced) return a.syncPendingActionMsg(_actionDetail(a));
    switch (action) {
      case PendingBlockedAction.installTyre:
        return a.pendingActionUnlockedMsg(a.installTyreAction);
      case PendingBlockedAction.updateHours:
        return a.pendingActionUnlockedMsg(a.updateHoursKmAction);
      case PendingBlockedAction.tyreInspection:
        return a.pendingActionUnlockedMsg(a.inspectTyreAction);
      case PendingBlockedAction.rotateTyres:
        return a.pendingActionUnlockedMsg(a.rotateTyresAction);
      case PendingBlockedAction.uploadImage:
        return a.pendingActionUnlockedMsg(a.uploadImagesAction);
      case PendingBlockedAction.deleteImage:
        return a.pendingActionUnlockedMsg(a.deleteImagesAction);
      case PendingBlockedAction.inspection:
        return a.pendingActionUnlockedMsg(a.submitInspectionAction);
      case PendingBlockedAction.editTyre:
        return a.pendingActionUnlockedMsg(a.editTyreAction);
      case PendingBlockedAction.cloneTyre:
        return a.pendingActionUnlockedMsg(a.cloneTyreAction);
      case PendingBlockedAction.editVehicle:
        return a.pendingActionUnlockedMsg(a.editVehicleAction);
    }
  }

  String _actionDetail(ApprovalLocalizations a) {
    switch (action) {
      case PendingBlockedAction.installTyre:
        return a.installTyreAction;
      case PendingBlockedAction.updateHours:
        return a.updateHoursKmAction;
      case PendingBlockedAction.tyreInspection:
        return a.inspectTyreAction;
      case PendingBlockedAction.rotateTyres:
        return a.rotateTyresAction;
      case PendingBlockedAction.uploadImage:
        return a.uploadImagesAction;
      case PendingBlockedAction.deleteImage:
        return a.deleteImagesAction;
      case PendingBlockedAction.inspection:
        return a.submitInspectionAction;
      case PendingBlockedAction.editTyre:
        return a.editTyreAction;
      case PendingBlockedAction.cloneTyre:
        return a.cloneTyreAction;
      case PendingBlockedAction.editVehicle:
        return a.editVehicleAction;
    }
  }

  String? get _prettyDate {
    if (submittedDate == null || submittedDate!.trim().isEmpty) return null;
    final d = DateTime.tryParse(submittedDate!);
    if (d == null) return null;
    final l = d.toLocal();
    return LocaleHelper.formatLongDateTime(l);
  }

  @override
  Widget build(BuildContext context) {
    final a = ApprovalLocalizations.of(context);
    final t = AppLocalizations.of(context);
    final date = _prettyDate;
    final by = (submittedBy ?? '').trim();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.85, end: 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        builder: (context, v, child) => Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.scale(scale: v, child: child),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ───────── Header ─────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_red, _darkRed],
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Icon(
                              offlineUnsynced
                                  ? Icons.cloud_off_rounded
                                  : Icons.hourglass_top_rounded,
                              size: 36,
                              color: _red,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _title(a),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.circle, size: 8, color: Color(0xFFFFD54F)),
                              const SizedBox(width: 6),
                              Text(
                                offlineUnsynced ? a.syncPending : a.approvalPending,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ───────── Body ─────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
                    child: Column(
                      children: [
                        if ((vehicleNumber ?? '').trim().isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F7),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.local_shipping_rounded,
                                    size: 20,
                                    color: _red,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.vehicle,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF8E8E93),
                                        ),
                                      ),
                                      Text(
                                        vehicleNumber!.trim(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1C1C1E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if ((tireSerialNo ?? '').trim().isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F7),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.album_rounded,
                                    size: 20,
                                    color: _red,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.tyreName(),
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF8E8E93),
                                        ),
                                      ),
                                      Text(
                                        tireSerialNo!.trim(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1C1C1E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          _message(a),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14.5,
                            height: 1.45,
                            color: Color(0xFF3A3A3C),
                          ),
                        ),
                        if (by.isNotEmpty || date != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _amber.withValues(alpha: 0.35)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (by.isNotEmpty)
                                  _infoRow(Icons.person_outline_rounded,
                                      a.submittedBy, by),
                                if (by.isNotEmpty && date != null)
                                  const SizedBox(height: 8),
                                if (date != null)
                                  _infoRow(Icons.schedule_rounded, a.submittedOn,
                                      date),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 16, color: Color(0xFF8E8E93)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                offlineUnsynced
                                    ? a.syncPendingFootnote
                                    : a.pendingLockFootnote,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  height: 1.4,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ───────── Button ─────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          a.okGotIt,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFB45309)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF92400E)),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF78350F),
            ),
          ),
        ),
      ],
    );
  }
}
