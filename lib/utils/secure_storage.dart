import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static Map<String, String?> _cache = {};
  static bool _cacheLoaded = false;

  static Future<void> loadAll() async {
    try {
      final all = await _storage.readAll();
      _cache = Map<String, String?>.from(all);
      _cacheLoaded = true;
    } catch (e) {
      debugPrint('⚠️ [SecureStorage] loadAll error: $e');
    }
  }

  static String? _get(String key) => _cache[key];

  static Future<void> _write(String key, String value) async {
    _cache[key] = value;
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('⚠️ [SecureStorage] _write error for key $key: $e');
    }
  }

  static Future<void> _delete(String key) async {
    _cache.remove(key);
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('⚠️ [SecureStorage] _delete error for key $key: $e');
    }
  }

  static Future<void> saveLocationForUser({
    required String username,
    required String id,
    required String name,
  }) async {
    await Future.wait([
      _write('location_id_$username',   id),
      _write('location_name_$username', name),
    ]);
  }

  static Future<String?> getLocationIdForUser(String username) async =>
      _get('location_id_$username');

  static Future<String?> getLocationNameForUser(String username) async =>
      _get('location_name_$username');

  static Future<void> saveParentAccountForUser({
    required String username,
    required String id,
    required String name,
  }) async {
    await Future.wait([
      _write('parent_account_id_$username',   id),
      _write('parent_account_name_$username', name),
    ]);
  }

  static Future<String?> getParentAccountIdForUser(String username) async =>
      _get('parent_account_id_$username');

  static Future<String?> getParentAccountNameForUser(String username) async =>
      _get('parent_account_name_$username');

  static const _tokenKey       = 'auth_token';
  static const _cookieKey      = 'auth_cookie';
  static const _accountTypeKey = 'account_type';

  static Future<void> saveToken(String token) => _write(_tokenKey, token);
  static Future<String?> getToken() async => _get(_tokenKey);
  static Future<void> clearToken() => _delete(_tokenKey);


  static Future<void> saveCookie(String cookie) => _write(_cookieKey, cookie);
  static Future<String?> getCookie() async {
    if (!_cacheLoaded) await loadAll();
    return _get(_cookieKey);
  }
  static Future<void> clearCookie() => _delete(_cookieKey);

  // ─── XSRF TOKEN ───
  static Future<void> saveXsrfToken(String token) => _write('xsrf_token', token);
  static Future<String?> getXsrfToken() async => _get('xsrf_token');
  static Future<void> clearXsrfToken() => _delete('xsrf_token');

  // ─── USERNAME ───
  static Future<void> saveUserName(String username) => _write('username', username);
  static Future<String?> getUserName() async => _get('username');
  static Future<void> clearUserName() => _delete('username');

  // ─── PASSWORD ───
  static const _passwordKey = 'auth_password';

  static Future<void> savePassword(String password) => _write(_passwordKey, password);
  static Future<String?> getPassword() async => _get(_passwordKey);
  static Future<void> clearPassword() => _delete(_passwordKey);

  // ─── REMEMBER ME (24 HOUR CREDENTIAL AUTOFILL) ───
  static const _credentialsSavedAtKey = 'credentials_saved_at';
  static const Duration rememberMeDuration = Duration(hours: 24);

  /// Call this right after a successful login to remember the
  /// username & password for the next 24 hours.
  static Future<void> saveRememberedCredentials({
    required String username,
    required String password,
  }) async {
    await Future.wait([
      _write('username', username),
      _write(_passwordKey, password),
      _write(_credentialsSavedAtKey, DateTime.now().millisecondsSinceEpoch.toString()),
    ]);
  }

  /// Returns {'username': ..., 'password': ...} if credentials were saved
  /// within the last 24 hours. If more than 24 hours have passed, the
  /// saved username/password are cleared and null is returned.
  static Future<Map<String, String>?> getRememberedCredentials() async {
    if (!_cacheLoaded) {
      await loadAll();
    }

    final savedAtStr = _get(_credentialsSavedAtKey);
    final username = _get('username');
    final password = _get(_passwordKey);

    if (savedAtStr == null || username == null || password == null) {
      return null;
    }

    final savedAtMillis = int.tryParse(savedAtStr);
    if (savedAtMillis == null) {
      return null;
    }

    final savedAt = DateTime.fromMillisecondsSinceEpoch(savedAtMillis);
    final expired = DateTime.now().difference(savedAt) > rememberMeDuration;

    if (expired) {
      await clearRememberedCredentials();
      return null;
    }

    return {'username': username, 'password': password};
  }

  static Future<void> clearRememberedCredentials() async {
    await Future.wait([
      _delete('username'),
      _delete(_passwordKey),
      _delete(_credentialsSavedAtKey),
    ]);
  }

  // ─── USER PROFILE ───
  static Future<void> saveUserProfileName(String username) =>
      _write('userprofilename', username);
  static Future<String?> getUserProfileName() async => _get('userprofilename');

  static Future<void> saveUserProfileRole(String userRole) =>
      _write('userprofilerole', userRole);
  static Future<String?> getUserProfileRole() async => _get('userprofilerole');

  // ─── IS APPROVER (Inspection Approval Flow) ───
  // Saved right after login (GET /api/UserProfile -> isApprover flag).
  // Used app-wide to decide whether the logged-in user submits an
  // inspection via the temp/approval API or approves it directly.
  static const _isApproverKey = 'userprofile_is_approver';

  static Future<void> saveIsApprover(bool isApprover) =>
      _write(_isApproverKey, isApprover.toString());

  static Future<bool> getIsApprover() async {
    if (!_cacheLoaded) {
      await loadAll();
    }
    final v = _get(_isApproverKey);
    return v?.toLowerCase() == 'true';
  }

  static Future<void> clearIsApprover() => _delete(_isApproverKey);

  // ─── GRAND PARENT ACCOUNT ID (of the logged-in user's own profile) ───
  // From GET /api/UserProfile -> grandParentAccountId. Null/'0' means no
  // grandparent account has been assigned to this user yet.
  static const _profileGrandParentIdKey = 'userprofile_grandparent_account_id';

  static Future<void> saveProfileGrandParentAccountId(int? id) =>
      _write(_profileGrandParentIdKey, (id ?? 0).toString());

  static Future<int?> getProfileGrandParentAccountId() async {
    if (!_cacheLoaded) {
      await loadAll();
    }
    final v = _get(_profileGrandParentIdKey);
    final id = v != null ? int.tryParse(v) : null;
    return (id != null && id > 0) ? id : null;
  }

  // ─── PARENT ACCOUNT ID (of the logged-in user's own profile) ───
  // From GET /api/UserProfile -> parentAccountId. This is the account the
  // logged-in user themself belongs to (as opposed to `parent_account_id`
  // above, which tracks whatever account is currently "selected"/switched
  // to elsewhere in the app, e.g. via Change Account). Screens that need
  // the user's OWN account — like the Inspection Approval pending list —
  // should read this instead of the generic selected-account id.
  static const _profileParentIdKey = 'userprofile_parent_account_id';

  static Future<void> saveProfileParentAccountId(int? id) =>
      _write(_profileParentIdKey, (id ?? 0).toString());

  static Future<int?> getProfileParentAccountId() async {
    if (!_cacheLoaded) {
      await loadAll();
    }
    final v = _get(_profileParentIdKey);
    final id = v != null ? int.tryParse(v) : null;
    return (id != null && id > 0) ? id : null;
  }

  // ─── APPROVAL WORKFLOW STATUS (Grand Parent Account level) ───
  // Resolved right after login by ApprovalWorkflowService, by matching the
  // logged-in user's grandParentAccountId against
  // GET /api/GrandParentAccount/GetAll and reading that account's
  // `isApprovalWorkflowEnabled` field. This is DIFFERENT from `isApprover`
  // above (which is a per-user flag) — this is a per-grandparent-account
  // workflow switch that will decide (in a later step) whether an EMTUSER's
  // inspection submit goes to the main API or the TEMP API.
  static const _approvalWorkflowEnabledKey = 'approval_workflow_enabled';
  static const _approvalWorkflowMatchedKey = 'approval_workflow_gp_matched';

  /// isEnabled: final resolved true/false used by the rest of the app.
  /// matched: whether the user's grandParentAccountId was actually found in
  /// the GetAll list (false means the fallback/default was used).
  static Future<void> saveApprovalWorkflowStatus({
    required bool isEnabled,
    required bool matched,
  }) async {
    await Future.wait([
      _write(_approvalWorkflowEnabledKey, isEnabled.toString()),
      _write(_approvalWorkflowMatchedKey, matched.toString()),
    ]);
  }

  static Future<bool> getApprovalWorkflowEnabled() async {
    if (!_cacheLoaded) {
      await loadAll();
    }
    return _get(_approvalWorkflowEnabledKey)?.toLowerCase() == 'true';
  }

  static Future<bool> getApprovalWorkflowGpMatched() async {
    if (!_cacheLoaded) {
      await loadAll();
    }
    return _get(_approvalWorkflowMatchedKey)?.toLowerCase() == 'true';
  }

  static Future<void> clearApprovalWorkflowStatus() => Future.wait([
    _delete(_approvalWorkflowEnabledKey),
    _delete(_approvalWorkflowMatchedKey),
  ]);

  // ─── LAST INSPECTION ───
  static Future<void> saveLastInspectionDate(String date) =>
      _write('last_inspection_date', date);
  static Future<String?> getLastInspectionDate() async =>
      _get('last_inspection_date');

  // ─── ACCOUNT TYPE ───
  static Future<void> saveAccountType(String type) =>
      _write(_accountTypeKey, type);
  static Future<String> getAccountType() async =>
      _get(_accountTypeKey) ?? 'own';
  static Future<void> clearAccountType() => _delete(_accountTypeKey);

  // ─── PARENT ACCOUNT (global — current session) ───
  static Future<void> saveParentAccount({
    required String id,
    required String name,
  }) async {
    await Future.wait([
      _write('parent_account_id',   id),
      _write('parent_account_name', name),
    ]);
  }

  static Future<String?> getParentAccountName() async =>
      _get('parent_account_name');
  static Future<String?> getParentAccountId() async =>
      _get('parent_account_id');

  // ─── LOCATION (global — current session) ───
  static Future<void> saveLocation({
    required String id,
    required String name,
  }) async {
    await Future.wait([
      _write('location_id',   id),
      _write('location_name', name),
    ]);
  }

  static Future<String?> getLocationName() async => _get('location_name');
  static Future<String?> getLocationId()   async => _get('location_id');

  // ─── CLEAR LOCATION ───
  static Future<void> clearLocation() async {
    await Future.wait([
      _delete('location_id'),
      _delete('location_name'),
    ]);
  }

  // ─── SELECTED LOCATIONS (multi-select — Home dashboard aggregation) ───
  // NOTE: `saveLocation`/`getLocationId` upar single "primary" active
  // location hi hai aur CRUD flows (create/edit tyre, vehicle inspection,
  // etc. — 20+ files) isi par depend karte hain. Unhe touch nahi kiya.
  // Ye naya set SIRF Home screen ke multi-location combined/summed
  // dashboard view ke liye hai.
  static Future<void> saveSelectedLocations({
    required List<String> ids,
    required List<String> names,
  }) async {
    await Future.wait([
      _write('selected_location_ids', ids.join(',')),
      _write('selected_location_names', names.join(',')),
    ]);
  }

  static List<String> getSelectedLocationIds() {
    final raw = _get('selected_location_ids');
    if (raw == null || raw.isEmpty) {
      // Backward-compat: purane sessions jinme multi-select kabhi save
      // nahi hua, unke liye current single active location ko hi
      // ek-item list bana do.
      final single = _get('location_id');
      return (single != null && single.isNotEmpty) ? [single] : [];
    }
    return raw.split(',').where((e) => e.isNotEmpty).toList();
  }

  static List<String> getSelectedLocationNames() {
    final raw = _get('selected_location_names');
    if (raw == null || raw.isEmpty) {
      final single = _get('location_name');
      return (single != null && single.isNotEmpty) ? [single] : [];
    }
    return raw.split(',').where((e) => e.isNotEmpty).toList();
  }

  static Future<void> clearSelectedLocations() async {
    await Future.wait([
      _delete('selected_location_ids'),
      _delete('selected_location_names'),
    ]);
  }

  // ─── LAST ASSIGNED PARENT / GRANDPARENT (Grandparent Assign screen) ───
  // Saved right after a successful "Assign" on the Grandparent Assign
  // screen's Assign Account step. Used to show the assigned Parent +
  // Grandparent account names (in green) against every EMTUSER row in the
  // User Management list, even after an app restart.
  static const _assignedParentNameKey = 'last_assigned_parent_account_name';
  static const _assignedGrandparentNameKey =
      'last_assigned_grandparent_account_name';
  static const _assignedParentIdKey = 'last_assigned_parent_account_id';
  static const _assignedGrandparentIdKey =
      'last_assigned_grandparent_account_id';

  static Future<void> saveAssignedParentAccountName(String name) =>
      _write(_assignedParentNameKey, name);

  static Future<String?> getAssignedParentAccountName() async {
    if (!_cacheLoaded) {
      await loadAll();
    }
    return _get(_assignedParentNameKey);
  }

  static Future<void> saveAssignedGrandparentAccountName(String name) =>
      _write(_assignedGrandparentNameKey, name);

  static Future<String?> getAssignedGrandparentAccountName() async {
    if (!_cacheLoaded) {
      await loadAll();
    }
    return _get(_assignedGrandparentNameKey);
  }

  static Future<void> saveAssignedParentAccountId(int id) =>
      _write(_assignedParentIdKey, id.toString());

  static Future<int?> getAssignedParentAccountId() async {
    if (!_cacheLoaded) {
      await loadAll();
    }
    final v = _get(_assignedParentIdKey);
    return v != null ? int.tryParse(v) : null;
  }

  static Future<void> saveAssignedGrandparentAccountId(int id) =>
      _write(_assignedGrandparentIdKey, id.toString());

  static Future<int?> getAssignedGrandparentAccountId() async {
    if (!_cacheLoaded) {
      await loadAll();
    }
    final v = _get(_assignedGrandparentIdKey);
    return v != null ? int.tryParse(v) : null;
  }

  // ─── CLEAR PARENT ACCOUNT ───  ✅ NEW
  static Future<void> clearParentAccount() async {
    await Future.wait([
      _delete('parent_account_id'),
      _delete('parent_account_name'),
    ]);
  }

  // ─── BOOL ───
  static Future<void> saveBool(String key, bool value) =>
      _write(key, value.toString());

  static Future<bool?> getBool(String key) async {
    final v = _get(key);
    if (v == null) return null;
    return v.toLowerCase() == 'true';
  }

  static Future<void> delete(String key) => _delete(key);

  // ─── AUTH HEADERS ───
  static Future<Map<String, String>> authHeaders() async {
    if (!_cacheLoaded) await loadAll();
    final cookie = _get(_cookieKey);
    return {
      'Content-Type': 'application/json',
      'Accept':       'application/json',
      if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
    };
  }

  // ─── SEARCH VEHICLE / TYRE ───
  static Future<void> saveVehicle(String value) =>
      _write('recent_vehicles', value);
  static Future<String?> getVehicle() async => _get('recent_vehicles');
  static Future<void> clearVehicle() => _delete('recent_vehicles');

  static Future<void> saveTyre(String value) =>
      _write('recent_tyres', value);
  static Future<String?> getTyre() async => _get('recent_tyres');
  static Future<void> clearTyre() => _delete('recent_tyres');

  // ─── LAST VEHICLE / TYRE ───
  static Future<void> saveLastVehicle(String v) => _write('last_vehicle', v);
  static Future<String?> getLastVehicle() async => _get('last_vehicle');
  static Future<void> clearLastVehicle() => _delete('last_vehicle');

  static Future<void> saveLastTyre(String t) => _write('last_tyre', t);
  static Future<String?> getLastTyre() async => _get('last_tyre');
  static Future<void> clearLastTyre() => _delete('last_tyre');

  // ─── CURRENCY ───
  static Future<void> saveCurrency(String currency) =>
      _write('pref_currency', currency);

  static String getCurrency() => _get('pref_currency') ?? '';

  // ─── PREFERENCES ───
  static Future<void> savePreference(String key, String value) =>
      _write('pref_$key', value);

  static Future<String?> getPreference(String key) async =>
      _get('pref_$key');

  static String? getPreferenceSync(String key) => _get('pref_$key');

  static Future<void> clearPreferences() async {
    await Future.wait([
      _delete('pref_language_display'),
      _delete('pref_language_code'),
      _delete('pref_measurement'),
      _delete('pref_pressure'),
      _delete('pref_currency'),
    ]);
  }

  static Future<void> saveDashboardCounts({
    required int vehicleCount,
    required int tyreCount,
  }) async {
    await Future.wait([
      _write('dashboard_vehicle_count', vehicleCount.toString()),
      _write('dashboard_tyre_count',    tyreCount.toString()),
    ]);
  }

  // ─── SYNC TIMESTAMPS (per data-section, used to avoid re-downloading
  // everything on every login) ───
  //
  // Key is prefixed with the username so switching accounts on the same
  // device never reuses another user's "last synced" time.
  static const String _syncPrefix = 'last_sync_';

  static Future<void> saveLastSyncTime(String section, {String? username}) async {
    final user = username ?? await getUserName() ?? 'default';
    await _write(
      '$_syncPrefix${section}_$user',
      DateTime.now().toIso8601String(),
    );
  }

  static Future<DateTime?> getLastSyncTime(String section, {String? username}) async {
    final user = username ?? await getUserName() ?? 'default';
    final raw = _get('$_syncPrefix${section}_$user');
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// True if [section] was synced within [maxAge].
  static Future<bool> isSectionFresh(
      String section, {
        required Duration maxAge,
        String? username,
      }) async {
    final t = await getLastSyncTime(section, username: username);
    if (t == null) return false;
    return DateTime.now().difference(t) < maxAge;
  }

  static const _initialDownloadDoneKey = 'initial_download_done_';

  static Future<void> setInitialDownloadDone(bool done, {String? username}) async {
    final user = username ?? await getUserName() ?? 'default';
    await _write('$_initialDownloadDoneKey$user', done ? 'true' : 'false');
  }

  static Future<bool> isInitialDownloadDone({String? username}) async {
    if (!_cacheLoaded) await loadAll();
    final user = username ?? await getUserName() ?? 'default';
    return _get('$_initialDownloadDoneKey$user') == 'true';
  }

  static const _lastFullDownloadTimeKey = 'last_full_download_time_';

  static Future<void> saveLastFullDownloadTime({String? username, DateTime? time}) async {
    final user = username ?? await getUserName() ?? 'default';
    final dt = time ?? DateTime.now();
    await _write('$_lastFullDownloadTimeKey$user', dt.toIso8601String());
  }

  static Future<DateTime?> getLastFullDownloadTime({String? username}) async {
    if (!_cacheLoaded) await loadAll();
    final user = username ?? await getUserName() ?? 'default';
    final raw = _get('$_lastFullDownloadTimeKey$user');
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static Future<bool> isFullDownloadExpired({String? username}) async {
    final t = await getLastFullDownloadTime(username: username);
    if (t == null) return true;
    return DateTime.now().difference(t).inHours >= 24;
  }

  /// Clears all "last sync" markers for the given user, forcing a full
  /// re-download on next login/refresh. Call this on manual "Sync Now".
  static Future<void> clearAllSyncTimes({String? username}) async {
    final user = username ?? await getUserName() ?? 'default';
    final keys = _cache.keys
        .where((k) => k.startsWith('$_syncPrefix') && k.endsWith('_$user'))
        .toList();
    for (final k in keys) {
      await _delete(k);
    }
  }

  static int? getLastVehicleCount() {
    final v = _get('dashboard_vehicle_count');
    return v != null ? int.tryParse(v) : null;
  }

  static int? getLastTyreCount() {
    final v = _get('dashboard_tyre_count');
    return v != null ? int.tryParse(v) : null;
  }

  static Future<void> saveNoOfTreadDepthReadings(int count) =>
      _write('no_of_tread_depth_readings', count.toString());

  static int getNoOfTreadDepthReadings() {
    final v = _get('no_of_tread_depth_readings');
    return v != null ? (int.tryParse(v) ?? 3) : 3;
  }

  static Future<void> saveDefaultRemovalTreadDepth(double val) =>
      _write('default_removal_tread_depth', val.toString());

  static double getDefaultRemovalTreadDepth() {
    final v = _get('default_removal_tread_depth');
    return v != null ? (double.tryParse(v) ?? 0.0) : 0.0;
  }

  // ─── CLEAR ALL ───
  static Future<void> clearAll() async {
    _cache.clear();
    _cacheLoaded = false;
    await _storage.deleteAll();
  }
}