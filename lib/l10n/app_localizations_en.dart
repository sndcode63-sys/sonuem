// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override String get homeTitle => 'Home';
  @override String get greeting => 'Welcome';
  @override String get settings => 'Settings';
  @override String get language => 'Language';
  @override String get measurementSystem => 'Measurement System';
  @override String get pressureUnit => 'Pressure Unit';
  @override String get update => 'Update';
  @override String get cancel => 'Cancel';
  @override String get addTyre => 'Add Tyre';
  @override String get save => 'Save';

  // Screen labels
  @override String get vehicleId => 'Vehicle ID';
  @override String get currentHours => 'Current Hours';
  @override String get currentKm => 'Current {unit}';
  @override String get trackingMethod => 'Tracking Method';
  @override String get manufacturer => 'Manufacturer';
  @override String get vehicleType => 'Type';
  @override String get model => 'Model';
  @override String get tyreSize => 'Tyre Size';
  @override String get removalTread => 'Removal Tread';
  @override String get vehicleComments => 'Vehicle Comments';
  @override String get vehicleDiagram => 'Vehicle Diagram';
  @override String get recommendedPressure => 'Recommended Pressure';
  @override String get submit => 'Submit';
  @override String get createVehicle => 'Create New Vehicle';
  @override String get outsideTread => 'Outside Tread Depth';
  @override String get insideTread => 'Inside Tread Depth';
  @override String get averageTread => 'Average Tread';
  @override String get airPressure => 'Air Pressure';
  @override String get lastRecordedDate => 'Last Recorded Date';
  @override String get lastRecordedHours => 'Last Recorded Hours';
  @override String get updateHours => 'Update Hours';
  @override String get lastRecordedKm => 'Last Recorded {unit}';
  @override String get updateKm => 'Update {unit}';
  @override String get vehicleNumber => 'Vehicle Number';
  @override String get editVehicle => 'Edit Vehicle';

  @override String get selectedParentAccountLocation => 'Selected parent account & Location';
  @override String get loadingMasterData => 'Loading master data...';
  @override String get creatingVehicle => 'Creating vehicle...';
  @override String get trackingMethodTitle => 'Tracking Method';
  @override String get trackingMethodHours => 'Hours';
  @override String get trackingMethodDistance => 'Distance';
  @override String get trackingMethodBoth => 'Both';
  @override String get searchHint => 'Search...';
  @override String get noDataAvailable => 'No data available';
  @override String get noTireInstalled => 'No\nTire\nInstalled';
  @override String get axleLabel => 'Axle';
  @override String get cancelRequestTitle => 'Cancel Request';
  @override String get cancelRequestMessage => 'Are you sure you want to cancel? You will lose unsaved data.';
  @override String get cancelRequestYes => 'Yes';
  @override String get currentDistance => 'Current';
  @override String get enterCurrentDistance => 'Enter current';
  @override String get commentsHint => 'Comments go here. (Max 200 characters)';

  // ================= CREATE TYRE (STEP 1) =================
  @override String get identificationDetails => 'Identification Details';

  @override String get tyreSerialNumber => 'Serial Number';
  @override String get enterTyreSerialNumber => 'Enter tyre serial number';
  @override String get tyreSerialRequired => 'Tyre serial number is required';
  @override String get tyreSerialDuplicate => 'Tyre serial already exists';

  @override String get brandNumber => 'Brand Number';
  @override String get enterBrandNumber => 'Enter brand number';

  @override String get registerDate => 'Register Date';
  @override String get registerDateRequired => 'Register date is required';

  @override String get evaluationNumber => 'Evaluation Number';
  @override String get lotNumber => 'Lot Number';
  @override String get purchaseOrderNumber => 'Purchase Order Number';

  @override String get disposition => 'Disposition';
  @override String get status => 'Status';

  @override String get currentHoursRequired => 'Current hours required';
  @override String get invalidHours => 'Invalid hours';
  @override String get negativeHours => 'Hours cannot be negative';

  @override String get currentKmRequired => 'Current {unit} required';
  @override String get invalidKm => 'Invalid {unit}';
  @override String get negativeKm => '{unit} cannot be negative';

  // ================= CREATE TYRE (STEP 2) =================
  @override String get description => 'Description';

  @override String get selectManufacturer => 'Select Manufacturer';
  @override String get selectTyreSize => 'Select Tyre Size';

  @override String get starRating => 'Star Rating';

  @override String get selectType => 'Select Type';

  @override String get indCode => 'IND Code';
  @override String get compound => 'Compound';
  @override String get loadRating => 'Load Rating';
  @override String get speedRating => 'Speed Rating';

  @override String get requiredField => 'This field is required';

  // ================= BUTTONS =================
  @override String get nextBtn => 'Next';
  @override String get previousBtn => 'Previous';
  @override String get cancelBtn => 'Cancel';
  @override String get okBtn => 'OK';
  @override String get originalTread => "Original Tread";
  @override String get removeAt => "Remove At";
  @override String get purchaseTread => "Purchase Tread";
  @override String get outside => "Outside";
  @override String get inside => "Inside";


  @override String get wornWarning =>
      "Warning, you are decreasing tread on a tire past its set pull point.";
  @override String get enterValidDetails => "Enter valid details.";
  @override String get onlyNumeric => "Only numeric values are allowed.";
  @override String get treadDepth => "Tread Depth";
  @override String get next => "Next";
  @override String get previous => "Previous";

  @override String get viewVehicle => "View Vehicle";
  @override String get costs => "Costs";
  @override String get identification => "Identification";
// Vehicle + Tyre extra keys
  @override String get vehicleViewTitle => "View Vehicle";
  @override String get inspect => "Inspect";
  @override String get error => "Error";
  @override String get noVehicleId => "No Vehicle ID provided";
  @override String get vehicleNotFound => "Vehicle not found";
  @override String get wheelPosition => "Wheel Position";

// Tyre view
  @override String get viewTyre => "View Tyre";
  @override String get purchasedTread => "Purchased Tread";
  @override String get middleTread => "Middle Tread";
  @override String get currentTreadDepth => "Current Tread Depth";
  @override String get percentageWorn => "% Worn";
  @override String get currentPressure => "Current Pressure";
  @override String get fillType => "Fill Type";
  @override String get fillCost => "Fill Cost";
  @override String get repairCost => "Repair Cost";
  @override String get retreadCost => "Retread Cost";
  @override String get warrantyAdjustment => "Warranty Adjustment";
  @override String get costAdjustment => "Cost Adjustment";
  @override String get netCost => "Net Cost";
  @override String get soldAmount => "Sold Amount";

  // ================= HOME / DRAWER =================
  @override String get parentAccount => 'Parent Account';
  @override String get location => 'Location';
  @override String get changeLocationAccount => 'Change Location & Account';

  @override String get mainMenu => 'Main Menu';
  @override String get home => 'Home';
  @override String get create => 'Create';
  @override String get preferences => 'Preferences';
  @override String get user => 'User';
  @override String get logout => 'Logout';

  @override String get createVehicleMenu => 'Create Vehicle';
  @override String get createTyreMenu => 'Create';

  @override String get userManagementList => 'User Management';
  @override String get grandparentAccount => 'Grandparent Account';
  @override String get grandparentAccountView => 'View Grandparent Account';

  @override String get startInspection => 'Start Inspection';

  @override String get totalVehicles => 'Total Vehicles';
  @override String get totalTyres => 'Total Tyres';

  @override String get lastInspection => 'Last Inspection';
  @override String get sync => 'Sync';

  @override String get unsyncInspection => 'Unsynced Inspection';
  @override String get syncInspection => 'Synced Inspection';

  @override String get appVersion => 'App Version';
  @override String get change => 'Change';

  @override String get syncSuccess => 'Sync Successful';
  @override String get syncFailed => 'Sync Failed';

  @override String get noPermissionCreate => 'No permission to create';

  // ================= CREATE TYRE STEP 2 (missing) =================
  @override String get manufacture => 'Manufacture';
  @override String get tireSize => 'Tire Size';
  @override String get searchTireManufacturer => 'Search Tire Manufacturer';
  @override String get chooseManufacturerFirst => 'Choose Manufacturer first';
  @override String get chooseSizeFirst => 'Choose size first';
  @override String get starRatingSelect => 'Select';
  @override String get selectFillType => 'Fill Type';

  // ================= CREATE TYRE STEP 3 (missing) =================
  @override String get treadDepthUnit => 'Tread Depth';
  @override String get originalTreadUnit => 'Original Tread';
  @override String get removeAtUnit => 'Remove At';
  @override String get purchaseTreadUnit => 'Purchase Tread';
  @override String get outsideUnit => 'Outside (a)';
  @override String get insideUnit => 'Inside (c)';
  @override String get enterOriginalTread => 'Enter Original Tread';
  @override String get enterRemoveAt => 'Remove At';
  @override String get enterPurchaseTread => 'Enter Purchase Tread';
  @override String get wornPercent => '% worn';

  // ================= CREATE TYRE STEP 4 (missing) =================
  @override String get tireCosts => 'Tire Costs';
  @override String get purchaseCostA => 'Purchase Cost (a)';
  @override String get casingValueB => 'Casing Value (B)';
  @override String get fillCostC => 'Fill Cost (C)';
  @override String get repairsCostD => 'Repairs Cost (D)';
  @override String get numberOfRetreads => 'Number of Retreads';
  @override String get retreadCostE => 'Retread Cost (E)';
  @override String get warrantyAdjustmentF => 'Warranty Adjustment (F)';
  @override String get costAdjustmentG => 'Cost Adjustment (G)';
  @override String get soldAmountH => 'Sold Amount (H)';
  @override String get netCostFormula => 'Net Cost = (a+d+c+e) - (b+g+h+f)';
  @override String get saveAndClone => 'Save & Clone';
  @override String get enterDisposition => 'Enter Disposition';
  @override String get enterEvaluationNumber => 'Enter Evaluation Number';
  @override String get enterLotNumber => 'Enter Lot Number';
  @override String get enterPurchaseOrderNumber => 'Enter Purchase Order Number';
  @override String get enterCurrentHours => 'Enter Current Hours';
  @override String get enterCurrentKm => 'Enter Current KM';
  @override String get enterValidNumeric => 'Enter a valid numeric value.';
  @override String get hoursNotNegative => 'Current hours cannot be negative.';
  @override String get kmNotNegative => 'Current KM cannot be negative.';
  @override String get serialAlreadyExists => 'This serial number already exists';
  @override String get searchIndCode => 'Search Ind. Code';
  @override String get searchCompound => 'Search Compound';
  @override String get searchLoadRating => 'Search Load Rating';
  @override String get searchSpeedRating => 'Search Speed Rating';
  @override String get selectItem => 'Select';
  @override String get selectPrefix => 'Select ';
  @override String get serialNumber => 'Serial Number';
  @override String get enter => 'Enter';
  @override String get selectedAccountLocation => 'Selected Account & Location';
  @override String get viewInspections => 'View Inspections';
  @override String get view => 'View';
  @override String get vehicle => 'Vehicle';
  @override String get total => 'Total';
  @override String get enterVehicleNumber => 'Enter Vehicle Number';
  @override String get editTyre => 'Edit Tyre';
  @override String get clear => 'CLEAR';
  @override String get set => 'SET';
  @override String get enterValidNumber => 'Enter valid number';
  @override String get allVehicles => 'All Vehicles';
  @override String get searchVehicles => 'Search Vehicles...';
  @override String get filters => 'Filters';
  @override String get applyFilters => 'Apply Filters';
  @override String get clearAllFilters => 'Clear All Filters';
  @override String get pendingSync => 'Pending Sync';
  @override String get make => 'Make';
  @override String get transfer => 'Transfer';
  @override String get delete => 'Delete';
  @override String get own => 'Own';
  @override String get shared => 'Shared';
  @override String get select => 'Select';
  @override String get searchAccount => 'Search account';
  @override String get searchLocation => 'Search location';
  @override String get noAccountsFound => 'No accounts found';
  @override String get noLocationsFound => 'No locations found';
  @override String get inspectTyre => 'Inspect Tyre';
  @override String get installTyre => 'Install Tyre';
  @override String get airPressureType => 'Air Pressure Type';
  @override String get cold => 'Cold';
  @override String get hot => 'Hot';
  @override String get wearCondition => 'Wear Condition';
  @override String get casingCondition => 'Casing Condition';
  @override String get listOfPreviousComments => 'List Of Previous Comments';
  @override String get stillRelevant => 'Still Relevant';
  @override String get uploadImages => 'Upload Images';
  @override String get images => 'Images';
  @override String get confirmRemove => 'Confirm remove';
  @override String get areYouSureRemoveImage => 'Are you sure to remove this image?';
  @override String get removeTire => 'Remove Tire';
  @override String get remove => 'Remove';
  @override String get all => 'All';
  @override String get editBtn => 'Edit';

  @override String get takePhoto => 'Take Photo';
  @override String get chooseFromGallery => 'Choose from Gallery';

  @override String get commentsLabel => 'Comments';
  @override String get yes => 'YES';
  @override String get no => 'NO';
  @override String get upload => 'Upload';
  @override String get install => 'Install';
  @override String get tyreType => 'Type';
  @override String get loading => 'Loading...';
  @override String get syncAll => 'Sync All';
  @override String get updateDisposition => 'Update Disposition *';
  @override String get removalReason => 'Removal Reason';
  @override String get selectDisposition => 'Select Disposition';
  @override String get selectRemovalReason => 'Select Removal Reason';
  @override String get rotatePosition => 'Rotate Position';
  @override String get placementError => 'Please place the tyre in a slot before saving.';
  @override String get rotationSavedOffline => 'Rotation saved locally. Will sync when internet available.';
  @override String get rotationSuccessful => 'Rotation updated and saved successfully.';
  @override String get searchInventory => 'Search Tyre from Inventory';
  @override String get noInventoryFound => 'No Inventory Tyres Found';
  @override String get manufacturerLabel => 'Brand/Manufacturer';
  @override String get unsynced => 'Unsynced';
  @override String get synced => 'Synced';
  @override String get unsyncedPending => 'unsynced inspection(s) pending';
  @override String get offlineSyncMessage => 'Offline — connect internet to sync';
  @override String get confirmDeleteTitle => 'Delete Inspection?';
  @override String get confirmDeleteMessage => 'Permanently delete this inspection?';
  @override String get viewInspection => 'View Inspection';
  @override String get syncing => 'Syncing...';
  @override String get inspected => 'Inspected';
  @override String get deleteInspectionTitle => 'Delete Inspection?';
  @override String get deleteInspectionConfirm => 'Permanently delete inspection for';
  @override String get tyresLabel => 'Tires';
  @override String get userManagement => 'USER MANAGEMENT';
  @override String get createUser => 'Create User';
  @override String get searchUser => 'Search User';
  @override String get deleteUser => 'Delete User';
  @override String get deleteUserConfirm => 'Are you sure you want to delete this user?';
  @override String get username => 'Username';
  @override String get password => 'Password';
  @override String get userRole => 'User Role';
  @override String get loginLabel => 'Login';
  @override String get personalLabel => 'Personal';
  @override String get preferenceLabel => 'Preference';
  @override String get creatingUser => 'Creating user...';
  @override String get grandparentAccountOptions => 'GRANDPARENT ACCOUNT OPTIONS';
  @override String get grandparentAccountInformation => 'GRANDPARENT ACCOUNT INFORMATION';
  @override String get searchGrandparent => 'Search Grandparent';
  @override String get active => 'Active';
  @override String get inactive => 'Inactive';
  @override String get ownedBy => 'Owned By';
  @override String get createAccount => 'Create Account';
  @override String get assignAccount => 'Assign Account';
  @override String get grandparentNameLabel => 'Grandparent Account Name';
  @override String get accountTypeLabel => 'Owned';
  @override String get selectParentAccount => 'Parent Account';
  @override String get selectGrandparentAccount => 'Grandparent Account';
  @override String get assignBtn => 'ASSIGN';
  @override String get firstName => 'First Name';
  @override String get middleName => 'Middle Name';
  @override String get lastName => 'Last Name';
  @override String get phone => 'Phone';
  @override String get country => 'Country';
  @override String get measurement => 'Measurement';
  @override String get id => 'ID';

  @override String get searchVehicleTyre => 'Search Vehicle / Tyre';
  @override String get recentSearch => 'Recent Search';
  @override String get vehicles => 'Vehicles';
  @override String get recentVehicleNotFound => 'No recent vehicle found';
  @override String get recentTyreNotFound => 'No recent tyre found';
  @override String get typeToSearch => 'Type to search';
  @override String get noVehiclesFound => 'No vehicles found for';
  @override String get noTyresFound => 'No tyres found for';
  @override String get createNewVehicle => 'Create New Vehicle';
  @override String get createNewTyre => 'Create New Tyre';
  @override String get confirmRemoveTitle => 'Confirm Remove';
  @override String get confirmRemoveMessage => 'Are you sure you want to remove this item?';
  @override String get updateBtn => 'Update';
  @override String get noRecentVehicleFound => 'No recent vehicle found';
  @override String get noRecentTyreFound => 'No recent tyre found';
  @override String get noVehiclesFoundFor => 'No vehicles found for';
  @override String get noTyresFoundFor => 'No tyres found for';
  @override String get searchPrefix => 'Search';
  @override
  String createNew(String itemName) => 'Create New $itemName';

  @override String get vehicleInspection => 'Vehicle Inspection';
  @override String get hourWarningMsg => "You haven't updated the Hours & Miles and Vehicle.";
  @override String get hours => 'Hours';
  @override String get km => 'KM';
  @override String get updateHoursKm => 'Update Hours / KM';
  @override String get serialNo => 'Serial Number';
  @override String get inspectedTire => 'Inspected Tire';
  @override String get notInspectedTire => 'Not Inspected';
  @override String get rotateTyres => 'Rotate';
  @override String get uploadedImages => 'Uploaded Images';
  @override String get confirmRemoveImg => 'Confirm Remove Image';
  @override String get viewOnlyDisabled => 'View Only — Submission Disabled';
  @override String get cancelRequestMsg => 'Are you sure you want to cancel? You will lose unsaved data.';
  @override String get selectedParentAccount => 'Selected Parent Account';
  @override String get surveyDate => 'Survey Date';
  @override String get selectDate => 'Select Date';
  @override String get updateHoursLabel => 'Update Hours';
  @override String get enterHours => 'Enter Hours';
  @override String get updateKmLabel => 'Update KM';
  @override String get enterKm => 'Enter KM';
  @override String get updateVehicleDataTitle => 'Update Vehicle Data';
  @override String get updateVehicleDataMsg => 'These changes will impact tire hours/KM.\nDo you wish to proceed?';
  @override String get proceed => 'Proceed';
  @override
  String tyreSerialNumbers(String tyreWord) => '$tyreWord Serial Number';
  @override
  String enterItemSerialNumber(String itemName) => 'Enter $itemName Serial Number';
  @override String axleSummary(String c, String n, String t) => '$c - $n $t';

  @override String get numericOnlyError => "Only numeric values are allowed";
  @override String get negativeValueError => "Value cannot be negative";
  @override String get duplicateVehicleError => "Vehicle number is already taken";
  @override String get invalidNumberError => "Must be a valid number";
  @override String get enterPrefix => "Enter ";
  @override String recommendedPressureFor(String axle) => "Recommended Pressure for $axle";
  @override String get numericOnly => "Only numeric values are allowed";

  @override String get inventory => 'Inventory';
  @override String get onHold => 'On Hold';
  @override String get scrap => 'Scrap';
  @override String get repair => 'Repair';
  @override String get retread => 'Retread';
  @override String get edit => 'Edit';
  @override String get clone => 'Clone';
  @override String get ok => 'OK';
}