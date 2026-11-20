

class RoleService {
  // ─── Role Constants ───────────────────────────────────────────────────────
  static const String emtSuAdmin  = 'EMTSUADMIN'; // EMTrack Admin
  static const String emtAdmin    = 'EMTADMIN';   // Goodyear Admin
  static const String emtCAdmin   = 'EMTCADMIN';  // Client Admin
  static const String emtUser     = 'EMTUSER';    // Client User
  static const String emtVo       = 'EMTVO';      // Client View Only
  static const String emtAUser    = 'EMTAUSER';   // Super User

  // ─── Admin-level roles (can manage users/accounts at system level) ────────
  static const List<String> _adminRoles = [emtSuAdmin, emtAdmin];

  // ─── Roles that can manage within their own Parent Account ───────────────
  static const List<String> _clientAdminRoles = [emtCAdmin, emtAUser];

  // ─── Roles with full CRUD on owned scope ─────────────────────────────────
  static const List<String> _fullCrudRoles = [
    emtSuAdmin, emtAdmin, emtCAdmin, emtUser, emtAUser
  ];

  // ═════════════════════════════════════════════════════════════════════════
  // ROLE CHECKS
  // ═════════════════════════════════════════════════════════════════════════

  /// Check karo ki role valid hai ya nahi
  static bool isValidRole(String role) =>
      [emtSuAdmin, emtAdmin, emtCAdmin, emtUser, emtVo, emtAUser].contains(role);

  /// EMTrack Admin (highest privilege)
  static bool isEmtSuAdmin(String role) => role == emtSuAdmin;

  /// Goodyear Admin
  static bool isEmtAdmin(String role) => role == emtAdmin;

  /// Client Admin
  static bool isClientAdmin(String role) => role == emtCAdmin;

  /// Super User (EMTAUSER)
  static bool isSuperUser(String role) => role == emtAUser;

  /// Client User
  static bool isClientUser(String role) => role == emtUser;

  /// View Only
  static bool isViewOnly(String role) => role == emtVo;

  // ═════════════════════════════════════════════════════════════════════════
  // ── Admin – Roles MODULE ─────────────────────────────────────────────────
  // ═════════════════════════════════════════════════════════════════════════

  /// Kya role create kar sakta hai?
  /// EMTSUADMIN: For All | EMTADMIN, EMTCADMIN: limited | Others: No
  static bool canCreateRole(String role) =>
      _adminRoles.contains(role) || _clientAdminRoles.contains(role);

  /// Kya role assign kar sakta hai?
  static bool canAssignRole(String role) =>
      _adminRoles.contains(role) || _clientAdminRoles.contains(role);

  /// Kya role edit kar sakta hai?
  static bool canEditRole(String role) =>
      _adminRoles.contains(role) || _clientAdminRoles.contains(role);

  /// Kya role delete kar sakta hai?
  static bool canDeleteRole(String role) =>
      _adminRoles.contains(role) || _clientAdminRoles.contains(role);

  /// Kya User Management section dikhai de?
  static bool canAccessUserManagement(String role) =>
      _adminRoles.contains(role) || _clientAdminRoles.contains(role);

  /// Kya Drawer me User menu aur uske sub-menus dikhai dein? (Only Admin and Super Admin)
  static bool canViewUserDrawerMenu(String role) {
    final r = role.trim().toUpperCase();
    return r == emtSuAdmin ||
        r == emtAdmin ||
        r == emtCAdmin ||
        r == emtAUser ||
        r == 'ADMIN' ||
        r == 'SUPER ADMIN' ||
        r == 'SUPERADMIN';
  }

  // ═════════════════════════════════════════════════════════════════════════
  // ── Admin – Parent Account MODULE ────────────────────────────────────────
  // ═════════════════════════════════════════════════════════════════════════

  /// Kya Parent Account create kar sakta hai?
  /// EMTSUADMIN, EMTADMIN: For All | EMTCADMIN, EMTAUSER: Owned | Others: No
  static bool canCreateParentAccount(String role) =>
      _adminRoles.contains(role) || _clientAdminRoles.contains(role);

  static bool canEditParentAccount(String role) =>
      _adminRoles.contains(role) || _clientAdminRoles.contains(role);

  static bool canAssignParentAccount(String role) =>
      _adminRoles.contains(role) || _clientAdminRoles.contains(role);

  static bool canDeleteParentAccount(String role) =>
      _adminRoles.contains(role) || _clientAdminRoles.contains(role);

  // ═════════════════════════════════════════════════════════════════════════
  // ── Admin – Location MODULE ───────────────────────────────────────────────
  // ═════════════════════════════════════════════════════════════════════════

  static bool canCreateLocation(String role) =>
      _adminRoles.contains(role) || _clientAdminRoles.contains(role);

  static bool canEditLocation(String role) =>
      _adminRoles.contains(role) || _clientAdminRoles.contains(role);

  static bool canAssignLocation(String role) =>
      _adminRoles.contains(role) || _clientAdminRoles.contains(role);

  static bool canDeleteLocation(String role) =>
      _adminRoles.contains(role) || _clientAdminRoles.contains(role);



  static bool canManageVehicleAdminSettings(String role) =>
      role == emtSuAdmin;



  static bool canManageTireAdminSettings(String role) =>
      role == emtSuAdmin;



  static bool canManageRimAdminSettings(String role) =>
      role == emtSuAdmin;



  static bool canManageInspectionRemovalReasons(String role) =>
      role == emtSuAdmin;

  static bool canCreateTire(String role) =>
      _fullCrudRoles.contains(role);

  static bool canCreateVehicle(String role) =>
      _fullCrudRoles.contains(role);

  static bool canCreateRim(String role) =>
      _fullCrudRoles.contains(role);


  static bool canInspectTire(String role) =>
      role != '';

  static bool canViewTire(String role) =>
      role != '';

  static bool canEditTire(String role) =>
      role != emtVo;

  static bool canCloneTire(String role) =>
      _fullCrudRoles.contains(role);

  static bool canTransferTire(String role) =>
      _fullCrudRoles.contains(role);

  static bool canDeleteTire(String role) =>
      _fullCrudRoles.contains(role);

  static bool canInspectVehicle(String role) =>
      role != '';

  static bool canViewVehicle(String role) =>
      role != '';


  static bool canEditVehicle(String role) =>
      role != emtVo;

  static bool canCloneVehicle(String role) =>
      _fullCrudRoles.contains(role);

  static bool canTransferVehicle(String role) =>
      _fullCrudRoles.contains(role);

  static bool canDeleteVehicle(String role) =>
      _fullCrudRoles.contains(role);

  static bool canViewRim(String role) =>
      role != '';

  static bool canEditRim(String role) =>
      role != emtVo;

  static bool canDeleteRim(String role) =>
      _fullCrudRoles.contains(role);

  static bool canViewReports(String role) =>
      role != ''; // Sab


  static bool canManageGrandparentAccount(String role) =>
      role == emtSuAdmin;

  static List<String> assignableRoles(String currentRole) {
    switch (currentRole) {
      case emtSuAdmin:
        return [emtAdmin, emtCAdmin, emtUser, emtVo, emtAUser, emtSuAdmin];
      case emtAdmin:
        return [emtCAdmin, emtUser, emtVo, emtAUser];
      case emtCAdmin:
      case emtAUser:
        return [emtUser, emtVo];
      default:
        return [];
    }
  }


  static String roleDisplayName(String role) {
    switch (role) {
      case emtSuAdmin:  return 'EMTrack Admin';
      case emtAdmin:    return 'Goodyear Admin';
      case emtCAdmin:   return 'Client Admin';
      case emtUser:     return 'Client User';
      case emtVo:       return 'View Only';
      case emtAUser:    return 'Super User';
      default:          return role;
    }
  }
}
