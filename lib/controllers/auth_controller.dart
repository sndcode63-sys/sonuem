import 'package:emtrack/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:emtrack/models/role/profile_model.dart';
import 'package:emtrack/models/user_models.dart';
import 'package:get/get.dart';
import 'package:emtrack/routes/app_pages.dart';
import '../controllers/preferences_controller.dart';
import '../controllers/home_controller.dart';
import '../models/approva.dart';
import '../services/auth_service.dart';
import '../services/change_account_service.dart';
import '../utils/diolog_helper.dart';
import '../utils/secure_storage.dart';
import '../utils/session_guard.dart';

class AuthController extends GetxController {
  final isLoading = false.obs;
  final showPassword = false.obs;
  final user = Rxn<UserModel>();
  final errorMessage = ''.obs;

  RxString userRole = ''.obs;
  RxString userName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadLocalUser();
  }

  Future<void> loadLocalUser() async {
    // 🔧 FIX: iOS par cache load hone se pehle role '' padh liya jata tha
    // (drawer Create + Inspection flow section nahi dikhta tha).
    await SecureStorage.ensureLoaded();
    userRole.value = await SecureStorage.getUserProfileRole() ?? '';
    userName.value = await SecureStorage.getUserProfileName() ?? '';
    isApprover.value = await SecureStorage.getIsApprover();

    final gpId = await SecureStorage.getProfileGrandParentAccountId();
    hasGrandParentAccount.value = gpId != null;

    isApprovalWorkflowEnabled.value =
    await SecureStorage.getApprovalWorkflowEnabled();
    approvalWorkflowGpMatched.value =
    await SecureStorage.getApprovalWorkflowGpMatched();
  }


  Future<Map<String, String>?> getRememberedCredentials() {
    return SecureStorage.getRememberedCredentials();
  }

  Future<UserModel?> login(String username, String password) async {
    try {
      LoadingHelper.showLoading();
      errorMessage.value = '';

      final UserModel? loggedUser = await AuthService.login(username, password);

      if (loggedUser == null) {
        LoadingHelper.hideLoading();
        AppSnackbar.error('Invalid username or password', title: 'Login Failed');
        return null;
      }

      await SecureStorage.saveRememberedCredentials(
        username: username,
        password: password,
      );

      await SecureStorage.saveToken(loggedUser.token);

      await SecureStorage.saveParentAccount(id: '', name: '');
      await SecureStorage.saveLocation(id: '', name: '');

      await SecureStorage.clearSelectedLocations();

      // Parallelize profile & preference sync with timeout so login screen doesn't freeze
      // 🔧 FIX (iOS: login ke baad user name/location nahi aata): pehle 4s ka
      // timeout tha aur profile call fail/slow hone par chup-chaap skip ho jata
      // tha. Ab profile 2 baar retry hota hai aur timeout bada hai.
      await Future.wait([
        _getUserProfileWithRetry(),
        _syncUserPreferences(),
      ]).timeout(const Duration(seconds: 22)).catchError((e) {
        debugPrint('⚠️ [AuthController] profile/preferences sync timeout/error: $e');
        return [];
      });

      await _restoreLastLocationForUser(username);
      _refreshTreadDepthSettings();

      if (Get.isRegistered<HomeController>()) {
        Get.delete<HomeController>();
      }

      SessionGuard.resetValidationTimer();
      LoadingHelper.hideLoading();

      Get.offAllNamed(AppPages.DOWNLOAD);

      return loggedUser;
    } catch (e) {
      debugPrint('❌ [LOGIN EXCEPTION] $e');
      LoadingHelper.hideLoading();
      AppSnackbar.error(
        'Unable to connect to server. Please check your internet connection.',
        title: 'Connection Error',
      );
      return null;
    }
  }

  Future<void> _restoreLastLocationForUser(String username) async {
    await SecureStorage.loadAll();
    final currentParentId = await SecureStorage.getParentAccountId();
    final currentLocationId = await SecureStorage.getLocationId();
    final serverAlreadyRestored =
        (currentParentId != null && currentParentId.isNotEmpty) ||
            (currentLocationId != null && currentLocationId.isNotEmpty);

    if (serverAlreadyRestored) {
      return;
    }

    // Fallback: local per-user cache
    final lastLocId = await SecureStorage.getLocationIdForUser(username);
    final lastLocName = await SecureStorage.getLocationNameForUser(username);
    final lastParentId = await SecureStorage.getParentAccountIdForUser(username);
    final lastParentName = await SecureStorage.getParentAccountNameForUser(username);

    if (lastLocId != null && lastLocId.isNotEmpty) {
      await SecureStorage.saveLocation(
          id: lastLocId, name: lastLocName ?? '');
    }

    if (lastParentId != null && lastParentId.isNotEmpty) {
      await SecureStorage.saveParentAccount(
          id: lastParentId, name: lastParentName ?? '');
    }
  }

  Future<void> _syncUserPreferences() async {
    try {
      final PreferencesController prefCtrl =
      Get.isRegistered<PreferencesController>()
          ? Get.find<PreferencesController>()
          : Get.put(PreferencesController());
      await prefCtrl.syncFromApi();
    } catch (_) {
    }
  }


  RxBool isApprover = false.obs;


  RxBool hasGrandParentAccount = false.obs;

  // ─── APPROVAL WORKFLOW (Grand Parent Account level) ───
  // Resolved at login by matching the user's grandParentAccountId against
  // GET /api/GrandParentAccount/GetAll -> isApprovalWorkflowEnabled.
  // Exposed here (in addition to SecureStorage) so Home/Approval UI can
  // later react to it with Obx without re-reading storage.
  // NOTE: only the login-time resolve+cache+log is wired up right now —
  // using this to switch the actual submit API / UI visibility is a
  // separate step, not done yet.
  final _workflowService = ApprovalWorkflowService();
  RxBool isApprovalWorkflowEnabled = false.obs;
  RxBool approvalWorkflowGpMatched = false.obs;

  Future<UserProfile?> _getUserProfileWithRetry({int attempts = 2}) async {
    for (var i = 1; i <= attempts; i++) {
      final p = await getUserProfile();
      if (p != null) return p;
      debugPrint('⚠️ [AuthController] getUserProfile attempt $i/$attempts returned null');
      if (i < attempts) await Future.delayed(Duration(milliseconds: 700 * i));
    }
    return null;
  }

  Future<UserProfile?> getUserProfile() async {
    try {
      final UserProfile? userData = await AuthService.getUserprofile();
      if (userData == null) return null;

      await SecureStorage.saveUserProfileRole(userData.userRole ?? '');
      await SecureStorage.saveUserProfileName(
          '${userData.firstName ?? ''} ${userData.lastName ?? ''}'.trim());

      final bool approverFlag = userData.isApprover ?? false;
      await SecureStorage.saveIsApprover(approverFlag);
      debugPrint(
        '✅ [AuthController] Saved isApprover=$approverFlag to SecureStorage '
            'for userId=${userData.userId}',
      );

      await SecureStorage.saveProfileGrandParentAccountId(
        userData.grandParentAccountId,
      );

      hasGrandParentAccount.value = userData.grandParentAccountId != null;

      debugPrint(
        '✅ [AuthController] Saved grandParentAccountId='
            '${userData.grandParentAccountId} to SecureStorage for '
            'userId=${userData.userId}'
            '${userData.grandParentAccountId == null ? '  (⚠️ backend returned null — no grandparent account assigned to this user yet)' : ''}',
      );


      await SecureStorage.saveProfileParentAccountId(
        userData.parentAccountId,
      );
      debugPrint(
        '✅ [AuthController] Saved parentAccountId(from UserProfile)='
            '${userData.parentAccountId} to SecureStorage for '
            'userId=${userData.userId}'
            '${userData.parentAccountId == null ? '  (⚠️ backend returned null — UserProfile has no parentAccountId)' : ''}',
      );

      final accountId = await SecureStorage.getParentAccountId();
      final accountName = await SecureStorage.getParentAccountName();
      final grandParentAccountId = userData.grandParentAccountId;

      AppLogger.success(
        '[AuthController] LOGIN SAVED -> userId=${userData.userId} | '
            'accountId(parentAccountId)=${accountId ?? "null"} | '
            'accountName=${accountName ?? "null"} | '
            'grandParentAccountId=${grandParentAccountId ?? "null"}',
      );

      if (accountId == null || accountId.isEmpty) {
        AppLogger.warn(
          '[AuthController] accountId is empty right after login — it will '
              'be set shortly by _setupDefaultAccountAndLocation() / '
              '_syncUserPreferences() during the download step.',
        );
      }

      await _resolveApprovalWorkflowStatus(
        grandParentAccountId: grandParentAccountId,
        userId: userData.userId,
        userRole: userData.userRole,
      );

      userRole.value = userData.userRole ?? '';
      userName.value =
          '${userData.firstName ?? ''} ${userData.lastName ?? ''}'.trim();
      isApprover.value = approverFlag;

      return userData;
    } catch (e) {
      errorMessage.value = 'Failed to load profile';
      debugPrint('❌ [AuthController] getUserProfile failed: $e');
      return null;
    }
  }


  Future<void> _resolveApprovalWorkflowStatus({
    required int? grandParentAccountId,
    required String? userId,
    required String? userRole,
  }) async {
    try {
      AppLogger.info(
        '[AuthController] Resolving approval-workflow status for '
            'userId=$userId | userRole=${userRole ?? "null"} | '
            'grandParentAccountId=${grandParentAccountId ?? "null"} ...',
      );

      final result = await _workflowService.resolveAndCache(
        grandParentAccountId,
      );

      isApprovalWorkflowEnabled.value = result.isEnabled;
      approvalWorkflowGpMatched.value = result.matched;

      AppLogger.success(
        '[AuthController] APPROVAL WORKFLOW RESOLVED -> '
            'userId=$userId | grandParentAccountId=${grandParentAccountId ?? "null"} | '
            'matched=${result.matched} | rawFlag=${result.rawFlag} | '
            'workflowEnabled=${result.isEnabled} | reason: ${result.reason}',
      );
    } catch (e) {

      isApprovalWorkflowEnabled.value = false;
      approvalWorkflowGpMatched.value = false;
      await SecureStorage.saveApprovalWorkflowStatus(
        isEnabled: false,
        matched: false,
      );
      AppLogger.error(
        '[AuthController] Unexpected error resolving approval-workflow '
            'status for userId=$userId: $e — defaulting to DISABLED.',
      );
    }
  }

  Future<void> _refreshTreadDepthSettings() async {
    try {
      final locationId = await SecureStorage.getLocationId();
      if (locationId != null && locationId.isNotEmpty) {
        final id = int.tryParse(locationId);
        if (id != null && id > 0) {
          final svc = ChangeAccountService();
          await svc.fetchAndSaveNoOfTreadDepthReadings(id);
        }
      }
    } catch (_) {
    }
  }

  Future<void> logout() async {
    user.value = null;
    await SessionGuard.manualLogout();
  }
}