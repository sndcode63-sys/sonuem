class ApiConstants {
    static const String baseUrl =
        // "https://emtrackotrapi.azurewebsites.net";
        // "https://emtrackotrapi-dev.azurewebsites.net";

    "https://emtrackotrapi-staging.azurewebsites.net";

    // ================= AUTH =================
    static const String login  = "/Auth/Login";
    static const String logout = "/Auth/LogOut";
    static const String installTire = "/api/Inspection/InstallTire";

    // UserManagement
    static const String deleteUser    = '/UserManagement/DeleteUser';
    static const String getAllUserList = '/api/UserProfile/GetAllUsers';
    static const String updateUserProfile = "/api/UserProfile/Update";


    static const List<String> languages = [
        'English (US/Canada)',
        'English(uk/Australia)',
        'Español',
        'Deutsche',
        'Italiano',
        'français',
        '中文',
        'русский',
        'português',
        'polski',
        'Arabic',
        'serbian',
    ];

    static const List<String> measurements  = ['Metric', 'Imperial'];
    static const List<String> pressureUnits = ['PSI', 'KPA', 'BAR'];

    // MasterData
    static const String getMasterDataMobile = '/api/MasterData/GetMasterDataMobile';
    static const String getLanguageList     = '/api/MasterData/GetLanguageFileContent';

    // Status Master (Inspection Approval Flow — Step 2)
    static const String getAllStatus = '/api/MasterData/GetAllStatus';

    // ================= INSPECTION =================
    static const String inspectTire          = "/api/Inspection/InspectTire";
    static const String removeTire           = "/api/Inspection/RemoveTire";
    // ---- CreateImages APIs (multipart/form-data, field: imgsrc) ----
    // Per "EmTrack - CreateImages APIs" doc:
    //   Tire/CreateImages        -> tireId       (tire create / edit)
    //   Vehicle/CreateImages     -> vehicleId    (vehicle create / update / vehicle inspection screen)
    //   Inspection/CreateImages  -> inspectionId (tyre inspection / tyre removal)
    //   MasterData/CreateImages  -> (no id)      (customer logo)
    static const String createTireImages       = "/api/Tire/CreateImages";
    static const String createVehicleImages    = "/api/Vehicle/CreateImages";
    static const String createInspectionImages = "/api/Inspection/CreateImages";
    static const String createCustomerLogo     = "/api/MasterData/CreateImages";
    static const String listInspectionImages = "/api/Inspection/ListImages";

    // Inspection Approval Flow (Step 3 & 5) ----------------------------
    // Non-Approver (isApprover = false/null) submits inspection here ->
    // goes into "Pending" state, waits for an Approver.
    static const String saveVehicleFootPrintDetailsTemp =
        "/api/Inspection/SaveVehicleFootPrintDetails_Temp";
    // Approver (isApprover = true) submits/approves/rejects here directly.
    static const String saveVehicleFootPrintDetails =
        "/api/Inspection/SaveVehicleFootPrintDetails";

    // Inspection Approval Flow (Step 4) — Approver's pending list
    static String getAllPendingInspections(int accountId) =>
        "/api/Inspection/GetAllPendingInspections/$accountId";

    // ================= TYRE =================
    static const String createTyre        = "/api/Tire";
    static const String getTyreById       = "/api/Tire/GetById/";

    static const String getTyresByAccount = "/api/Tire/GetTiresByAccount";

    // ================= VEHICLE =================
    static const String createVehicle = "/api/Vehicle/Create";

    static String getVehicleByUser(
        int parentAccountId, {
            int pageNumber = 0,
            int timeStamp = 0,
        }) {
        return "/api/Vehicle/GetVehicleByUser/$parentAccountId/$pageNumber?timeStamp=$timeStamp";
    }

    static String getVehicleByAccount(int parentAccountId) {
        return "/api/ParentAccount/GetDetailsByAccount/$parentAccountId";
    }

    // ================= MASTER DATA =================
    static const String getAllCountryName       = "/api/MasterData/GetCountryList";
    static const String masterData              = "/api/MasterData/GetMasterDataMobile";
    static const String grandParentAccountGetAll = "/api/GrandParentAccount/GetAll";

    // ================= USER =================
    static const String updatePreferences  = "/api/UserPreferences/Update";
    static const String updateLastAccessed = "/api/UserPreferences/UpdateLastAccessed";

    // ================= USER MANAGEMENT =================
    static const String createUser           = "/UserManagement/CreateUser";
    static const String createUserProfile    = "/api/UserProfile/CreateUserProfile";
    static const String createUserPreference = "/api/UserPreferences/CreateUserPreference";
    static const String assignRole           = "/Role/AssignRole";

    // Reset Password
    static const String sendPasswordToken = "/UserManagement/SendPasswordResetCode";
    static const String resetPassword     = "/UserManagement/PasswordResetWToken";

    // Grand Parent
    static const String createGrandParentAccount = "/api/GrandParentAccount/Create";
    static const String updateGrandParentAccount = "/api/ParentAccount/UpdateGrandParentAccount";

    /// Updates the GrandParentAccount entity itself (name/owner/isActive/
    /// isApprovalWorkflowEnabled etc.). This is the PUT endpoint used to
    /// enable/disable the "Eligible for Inspection" workflow on a
    /// grandparent account:
    ///   PUT /api/GrandParentAccount/Update
    /// NOTE: this is DIFFERENT from `updateGrandParentAccount` above, which
    /// hits /api/ParentAccount/UpdateGrandParentAccount (parent<->grandparent
    /// relationship assignment on the create-account screen). Don't confuse
    /// the two.
    static const String updateGrandParentAccountWorkflow = "/api/GrandParentAccount/Update";

    /// Fetch a single GrandParentAccount by id — used to get the full record
    /// (name/ownedBy/createdBy/createdDate/etc.) before calling Update above,
    /// since Update expects the full object, not just the changed field.
    static String findGrandParentAccountById(int grandParentAccountId) =>
        "/api/GrandParentAccount/GPFindById/$grandParentAccountId";

    /// User Management list ke "Assign Grandparent Account" (person_add icon)
    /// action ke liye — user ko directly grandparent account assign karta hai.
    /// PUT body: { "username": "<string>", "grandParentAccountId": <long> }
    static const String assignGrandParentAccountToUser = "/api/UserProfile/AssignGrandParentAccount";

    // Account Lists
    static const String getParentAccountList    = "/api/ParentAccount/GetAccountList";
    static const String getGrandparentAccountList = "/api/GrandParentAccount/GetAll";

    static const String getCountryList = "/api/MasterData/GetCountryList/";
    static const String getRoleList    = "/Role/GetRoles";
    static const String getUserProfile = "/api/UserProfile";
}