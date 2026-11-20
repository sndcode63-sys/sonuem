import 'dart:async';
import 'package:emtrack/l10n/pl.dart';
import 'package:emtrack/l10n/sa.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

import '../utils/local_helper.dart';
import 'app_language_es.dart';
import 'app_localization_it.dart';
import 'app_localization_pt.dart';
import 'app_localization_ru.dart';
import 'app_localizations_en.dart';
import 'cn.dart';
import 'de.dart';
import 'fr.dart';


abstract class AppLocalizations {
  AppLocalizations(this.localeName);
  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  // All languages (Hindi removed)
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('de'),
    Locale('fr'),
    Locale('it'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
    Locale('ar'),
    Locale('pl'),
  ];

  String get homeTitle;
  String get greeting;
  String get settings;
  String get language;
  String get measurementSystem;
  String get pressureUnit;
  String get update;
  String get cancel;
  String get addTyre;
  String get save;

  // Screen labels
  String get vehicleId;
  String get currentHours;
  String get currentKm;
  String get trackingMethod;
  String get manufacturer;
  String get vehicleType;
  String get model;
  String get tyreSize;
  String get removalTread;
  String get vehicleComments;
  String get vehicleDiagram;
  String get recommendedPressure;
  String get submit;
  String get createVehicle;
  String get outsideTread;
  String get insideTread;
  String get averageTread;
  String get airPressure;
  String get lastRecordedDate;
  String get lastRecordedHours;
  String get updateHours;
  String get lastRecordedKm;
  String get updateKm;
  String get vehicleNumber;
  String get editVehicle;

  // CreateVehicle screen
  String get selectedParentAccountLocation;
  String get loadingMasterData;
  String get creatingVehicle;
  String get trackingMethodTitle;
  String get trackingMethodHours;
  String get trackingMethodDistance;
  String get trackingMethodBoth;
  String get searchHint;
  String get noDataAvailable;
  String get noTireInstalled;
  String get axleLabel;
  String get cancelRequestTitle;
  String get cancelRequestMessage;
  String get cancelRequestYes;
  String get currentDistance;
  String get enterCurrentDistance;
  String get commentsHint;


  // ================= CREATE TYRE (STEP 1) =================
  String get identificationDetails;

  String get tyreSerialNumber;
  String get enterTyreSerialNumber;
  String get tyreSerialRequired;
  String get tyreSerialDuplicate;

  String get brandNumber;
  String get enterBrandNumber;

  String get registerDate;
  String get registerDateRequired;

  String get evaluationNumber;
  String get lotNumber;
  String get purchaseOrderNumber;

  String get disposition;
  String get status;

  String get currentHoursRequired;
  String get invalidHours;
  String get negativeHours;

  String get currentKmRequired;
  String get invalidKm;
  String get negativeKm;

// ================= CREATE TYRE (STEP 2) =================
  String get description;

  String get selectManufacturer;
  String get selectTyreSize;

  String get starRating;

  String get selectType;

  String get indCode;
  String get compound;
  String get loadRating;
  String get speedRating;

  String get requiredField;

// ================= BUTTONS =================
  String get nextBtn;
  String get previousBtn;
  String get cancelBtn;
  String get okBtn;

  String get originalTread;
  String get removeAt;
  String get purchaseTread;
  String get outside;
  String get inside;



  String get wornWarning;
  String get enterValidDetails;
  String get onlyNumeric;
  String get treadDepth;


  String get next;
  String get previous;

// ================= VEHICLE VIEW =================
  String get vehicleViewTitle;
  String get viewVehicle;
  String get inspect;
  String get error;
  String get noVehicleId;
  String get vehicleNotFound;
  String get wheelPosition;
  String get costs;
// ================= TYRE VIEW =================
  String get viewTyre;
  String get identification;
  String get purchasedTread;
  String get middleTread;
  String get currentTreadDepth;
  String get percentageWorn;
  String get currentPressure;
  String get fillType;
  String get fillCost;
  String get repairCost;
  String get retreadCost;
  String get warrantyAdjustment;
  String get costAdjustment;
  String get netCost;
  String get soldAmount;

  // ================= HOME / DRAWER =================
  String get parentAccount;
  String get location;
  String get changeLocationAccount;

  String get mainMenu;
  String get home;
  String get create;
  String get preferences;
  String get user;
  String get logout;

  String get createVehicleMenu;
  String get createTyreMenu;

  String get userManagementList;
  String get grandparentAccount;
  String get grandparentAccountView;

  String get startInspection;

  String get totalVehicles;
  String get totalTyres;

  String get lastInspection;
  String get sync;

  String get unsyncInspection;
  String get syncInspection;

  String get appVersion;
  String get change;

  String get syncSuccess;
  String get syncFailed;

  String get noPermissionCreate;

  // ================= CREATE TYRE STEP 2 (missing) =================
  String get manufacture;
  String get tireSize;
  String get searchTireManufacturer;
  String get chooseManufacturerFirst;
  String get chooseSizeFirst;
  String get starRatingSelect;
  String get selectFillType;

  // ================= CREATE TYRE STEP 3 (missing) =================
  String get treadDepthUnit; // "Tread Depth(%unit%)"
  String get originalTreadUnit; // "Original Tread (%unit%)"
  String get removeAtUnit; // "Remove At (%unit%)"
  String get purchaseTreadUnit; // "Purchase Tread (%unit%)"
  String get outsideUnit; // "Outside (%unit%) (a)"
  String get insideUnit; // "Inside (%unit%) (c)"
  String get enterOriginalTread;
  String get enterRemoveAt;
  String get enterPurchaseTread;
  String get wornPercent; // "%d% worn"

  // ================= CREATE TYRE STEP 4 (missing) =================
  String get tireCosts;
  String get purchaseCostA;
  String get casingValueB;
  String get fillCostC;
  String get repairsCostD;
  String get numberOfRetreads;
  String get retreadCostE;
  String get warrantyAdjustmentF;
  String get costAdjustmentG;
  String get soldAmountH;
  String get netCostFormula;
  String get saveAndClone;
  String get enterDisposition;
  String get enterEvaluationNumber;
  String get enterLotNumber;
  String get enterPurchaseOrderNumber;
  String get enterCurrentHours;
  String get enterCurrentKm;
  String get enterValidNumeric;
  String get hoursNotNegative;
  String get kmNotNegative;
  String get serialAlreadyExists;
  String get searchIndCode;
  String get searchCompound;
  String get searchLoadRating;
  String get searchSpeedRating;
  String get selectItem; // "Select"
  String get selectPrefix; // "Select "
  String get serialNumber;
  String get enter;
  String get selectedAccountLocation;
  String get viewInspections;
  String get view;
  String get vehicle;
  String get total;
  String get enterVehicleNumber;
  String get editTyre;
  String get clear;
  String get set;
  String get enterValidNumber;
  String get allVehicles;
  String get searchVehicles;
  String get filters;
  String get applyFilters;
  String get clearAllFilters;
  String get pendingSync;
  String get make;
  String get transfer;
  String get delete;
  String get own;
  String get shared;
  String get select;
  String get searchAccount;
  String get searchLocation;
  String get noAccountsFound;
  String get noLocationsFound;
  String get inspectTyre;
  String get installTyre;
  String get airPressureType;
  String get cold;
  String get hot;
  String get wearCondition;
  String get casingCondition;
  String get listOfPreviousComments;
  String get stillRelevant;
  String get uploadImages;
  String get images;
  String get confirmRemove;
  String get areYouSureRemoveImage;
  String get removeTire;
  String get remove;
  String get all;
  String get editBtn;
  String get takePhoto;
  String get chooseFromGallery;
  String get commentsLabel;
  String get yes;
  String get no;
  String get upload;
  String get install;
  String get tyreType;
  // Common Buttons & Labels
  String get loading;
  String get syncAll;


  // Remove Tyre Screen
  String get updateDisposition;
  String get removalReason;
  String get selectDisposition;
  String get selectRemovalReason;

  // Rotate Tyres Screen
  String get rotatePosition;
  String get placementError;
  String get rotationSavedOffline;
  String get rotationSuccessful;

  // Search & Install Screen
  String get searchInventory;
  String get noInventoryFound;
  String get manufacturerLabel;

  // View Inspection Screen
  String get unsynced;
  String get synced;
  String get unsyncedPending;
  String get offlineSyncMessage;
  String get confirmDeleteTitle;
  String get confirmDeleteMessage;

  String get viewInspection;
  String get syncing;
  String get inspected;
  String get deleteInspectionTitle;
  String get deleteInspectionConfirm;
  String get tyresLabel;


  String get userManagement;
  String get createUser;
  String get searchUser;
  String get deleteUser;
  String get deleteUserConfirm;
  String get username;
  String get password;
  String get userRole;
  String get loginLabel;
  String get personalLabel;
  String get preferenceLabel;
  String get creatingUser;

  // Grandparent Account
  String get grandparentAccountOptions;
  String get grandparentAccountInformation;
  String get searchGrandparent;
  String get active;
  String get inactive;
  String get ownedBy;
  String get createAccount;
  String get assignAccount;
  String get grandparentNameLabel;
  String get accountTypeLabel;
  String get selectParentAccount;
  String get selectGrandparentAccount;
  String get assignBtn;

  // Common / Reusable
  String get firstName;
  String get middleName;
  String get lastName;
  String get phone;
  String get country;
  String get measurement;
  String get id;



  String get searchVehicleTyre;
  String get recentSearch;
  String get vehicles;
  String get recentVehicleNotFound;
  String get recentTyreNotFound;
  String get typeToSearch;
  String get noVehiclesFound;
  String get noTyresFound;
  String get createNewVehicle;
  String get createNewTyre;
  String get confirmRemoveTitle;
  String get confirmRemoveMessage;


  // Preferences Screen
  String get updateBtn;
  String createNew(String itemName);

  String get vehicleInspection;
  String get hourWarningMsg;

  String get hours;
  String get km;
  String get updateHoursKm;

  String get serialNo => "Serial No";

  String get inspectedTire => "Inspected";

  String get notInspectedTire => "Not Inspected";
  String get rotateTyres => 'Rotate ${LocaleHelper.tyreName(Get.context!)}s';
  String get uploadedImages;
  String get confirmRemoveImg;
  String get viewOnlyDisabled;

  String get cancelRequestMsg;

  // Update Hours Screen
  String get selectedParentAccount;
  String get surveyDate;
  String get selectDate;
  String get updateHoursLabel;
  String get enterHours;
  String get updateKmLabel;
  String get enterKm;
  String get updateVehicleDataTitle;
  String get updateVehicleDataMsg;
  String get proceed;


  String get noRecentVehicleFound;
  String get noRecentTyreFound;
  String get noVehiclesFoundFor;
  String get noTyresFoundFor;
  String get searchPrefix;
  String tyreSerialNumbers(String tyreWord);
  String enterItemSerialNumber(String itemName);
  String axleSummary(String config, String count, String tyreWord);

  String get numericOnlyError;
  String get negativeValueError;
  String get duplicateVehicleError;
  String get invalidNumberError;
  String get enterPrefix;
  String recommendedPressureFor(String axle);
  String get numericOnly; // ✅ Ye line add karein

// Tabs
  String get inventory;
  String get onHold;
  String get scrap;
  String get repair;
  String get retread;

  // Actions
  String get edit; // Agar editBtn use nahi karna toh
  String get clone; // "Clone" short text

  String get ok;



}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(
        lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => [
    'en','es','de','fr','it','pt','ru','zh','ar','pl'
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'de': return AppLocalizationsDe();
    case 'fr': return AppLocalizationsFr();
    case 'it': return AppLocalizationsIt();
    case 'pt': return AppLocalizationsPt();
    case 'ru': return AppLocalizationsRu();
    case 'zh': return AppLocalizationsZh();
    case 'ar': return AppLocalizationsAr();
    case 'pl': return AppLocalizationsPl();
    default: return AppLocalizationsEn();
  }
}