import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/global_state_referesh.dart';
import 'package:emtrack/routes/app_pages.dart';
import 'package:emtrack/utils/secure_storage.dart';
import '../models/preferences_model.dart';
import '../services/preferences_service.dart';
import '../services/master_data_service.dart';
import '../services/api_constants.dart';
import '../utils/hive_prefe.dart';
import '../utils/mesurment_helper_class.dart';

class PreferencesController extends GetxController {
  final PreferencesService service = PreferencesService();
  final MasterDataService masterDataService = MasterDataService();

  final RxBool isLoading = false.obs;
  final RxBool isListsLoading = false.obs;

  RxList<String> measurementSystems = <String>[...ApiConstants.measurements].obs;
  RxList<String> pressureUnits = <String>[...ApiConstants.pressureUnits].obs;
  RxList<String> languages = <String>[...ApiConstants.languages].obs;

  RxString selectedLanguage = 'English (US/Canada)'.obs;
  RxString selectedMeasurement = 'Imperial'.obs;
  RxString selectedPressure = 'PSI'.obs;

  static String canonicalMeasurement(String? val) {
    if (val == null) return 'Imperial';
    final s = val.trim().toLowerCase();
    if (s == 'metric') return 'Metric';
    return 'Imperial';
  }

  static String canonicalPressure(String? val) {
    if (val == null) return 'PSI';
    final s = val.trim().toUpperCase();
    if (s == 'BAR') return 'BAR';
    if (s == 'KPA') return 'KPA';
    return 'PSI';
  }

  String get tyreName =>
      selectedLanguage.value == 'English(uk/Australia)' ? 'Tyre' : 'Tire';

  bool get isDayFirst => selectedLanguage.value == 'English(uk/Australia)';

  String formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return isDayFirst ? '$d/$m/$y' : '$m/$d/$y';
  }

  String formatApiDate(String? apiDate) {
    if (apiDate == null || apiDate.isEmpty) return '-';
    try {
      final raw = apiDate.trim();
      final datePart = raw.contains('T')
          ? raw.split('T')[0]
          : raw.split(' ')[0];
      final parts = datePart.split('-');
      if (parts.length < 3) return raw;
      return isDayFirst
          ? '${parts[2]}/${parts[1]}/${parts[0]}'
          : '${parts[1]}/${parts[2]}/${parts[0]}';
    } catch (_) {
      return '-';
    }
  }

  // ─── Language display ↔ code mappers ─────────────────────
  String _mapDisplayToCode(String displayName) {
    const map = {
      'English (US/Canada)': 'en',
      'Español': 'es',
      'English(uk/Australia)': 'en-uk',
      'Deutsche': 'de',
      'Italiano': 'it',
      'français': 'fr',
      '中文': 'zh',
      'русский': 'ru',
      'português': 'pt',
      'polski': 'pl',
      'serbian': 'ser',
      'Arabic': 'ar',
    };
    return map[displayName] ?? 'en';
  }

  String _mapCodeToDisplay(String code) {
    const map = {
      'en': 'English (US/Canada)',
      'en-us': 'English (US/Canada)',
      'enus': 'English (US/Canada)',
      'es': 'Español',
      'en-uk': 'English(uk/Australia)',
      'de': 'Deutsche',
      'it': 'Italiano',
      'fr': 'français',
      'zh': '中文',
      'ru': 'русский',
      'pt': 'português',
      'pl': 'polski',
      'ser': 'serbian',
      'ar': 'Arabic',
    };
    return map[code.toLowerCase()] ?? 'English (US/Canada)';
  }

  Locale _mapDisplayToLocale(String displayName) {
    const map = {
      'English (US/Canada)': Locale('en'),
      'English(uk/Australia)': Locale('en'),
      'Español': Locale('es'),
      'Deutsche': Locale('de'),
      'Italiano': Locale('it'),
      'français': Locale('fr'),
      '中文': Locale('zh'),
      'русский': Locale('ru'),
      'português': Locale('pt'),
      'polski': Locale('pl'),
      'serbian': Locale('en'),
      'Arabic': Locale('ar'),
    };
    return map[displayName] ?? const Locale('en');
  }

  String get kmMilesLabel =>
      selectedMeasurement.value.toLowerCase() == 'metric' ? 'KM' : 'Miles';

  // NOTE: Ye teeno sirf dropdown ki selection (UI) update karte hain.
  // Locale / HivePref / global measurement state tabhi apply hoga jab
  // user "Update" button dabayega (dekho updatePre() neeche).
  void updateLanguage(String value) {
    selectedLanguage.value = value;
  }

  void updateMeasurement(String value) {
    selectedMeasurement.value = value;
  }

  void updatePressure(String value) {
    selectedPressure.value = value;
  }

  void _applyFromHive() {
    String? langDisplay = HivePref.get<String>('pref_language_display');
    String? langCode = HivePref.get<String>('pref_language_code');
    String? measurement = HivePref.get<String>('pref_measurement');
    String? pressure = HivePref.get<String>('pref_pressure');

    if (measurement == null || measurement.isEmpty) {
      final secM = SecureStorage.getPreferenceSync('measurement');
      if (secM != null && secM.isNotEmpty) {
        measurement = secM;
        HivePref.set('pref_measurement', secM);
      }
    }
    if (pressure == null || pressure.isEmpty) {
      final secP = SecureStorage.getPreferenceSync('pressure');
      if (secP != null && secP.isNotEmpty) {
        pressure = secP;
        HivePref.set('pref_pressure', secP);
      }
    }
    if (langDisplay == null || langDisplay.isEmpty) {
      final secL = SecureStorage.getPreferenceSync('language_display');
      if (secL != null && secL.isNotEmpty) {
        langDisplay = secL;
        HivePref.set('pref_language_display', secL);
      }
    }

    final finalLangDisplay = langDisplay;
    final finalLangCode = langCode;
    if (finalLangDisplay != null && finalLangDisplay.isNotEmpty) {
      selectedLanguage.value = finalLangDisplay;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.updateLocale(_mapDisplayToLocale(finalLangDisplay));
      });
    } else if (finalLangCode != null && finalLangCode.isNotEmpty) {
      final display = _mapCodeToDisplay(finalLangCode);
      selectedLanguage.value = display;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.updateLocale(_mapDisplayToLocale(display));
      });
    }

    if (measurement != null && measurement.isNotEmpty) {
      selectedMeasurement.value = canonicalMeasurement(measurement);
    }
    if (pressure != null && pressure.isNotEmpty) {
      selectedPressure.value = canonicalPressure(pressure);
    }
    MeasurementHelper.syncToGlobalState();
  }

  Future<void> syncFromApi() async {
    try {
      final username = await SecureStorage.getUserName();
      if (username == null || username.isEmpty) return;

      final localMeasurement = HivePref.get<String>('pref_measurement') ?? SecureStorage.getPreferenceSync('measurement');
      final localPressure = HivePref.get<String>('pref_pressure') ?? SecureStorage.getPreferenceSync('pressure');
      final localLangDisplay = HivePref.get<String>('pref_language_display') ?? SecureStorage.getPreferenceSync('language_display');
      final localLangCode = HivePref.get<String>('pref_language_code') ?? SecureStorage.getPreferenceSync('language_code');
      final isUserExplicitlySet = HivePref.get<bool>('pref_user_explicitly_set') == true ||
          (localMeasurement != null && localMeasurement.isNotEmpty);

      final prefs = await service.fetchPreferences(username);
      if (prefs == null) {
        return;
      }

      if (isUserExplicitlySet && localMeasurement != null && localMeasurement.isNotEmpty) {
        // ✅ USER RULE: Whatever user selected MUST remain unchanged until user manually changes it.
        // Server defaults MUST NEVER overwrite user's local chosen preferences.
        selectedMeasurement.value = canonicalMeasurement(localMeasurement);
        if (localPressure != null && localPressure.isNotEmpty) {
          selectedPressure.value = canonicalPressure(localPressure);
        }
        if (localLangDisplay != null && localLangDisplay.isNotEmpty) {
          selectedLanguage.value = localLangDisplay;
          final locale = _mapDisplayToLocale(localLangDisplay);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.updateLocale(locale);
          });
        }
        MeasurementHelper.syncToGlobalState();

        // Push user's local preference to server in the background so server stays in sync:
        try {
          final modelToPush = PreferencesModel(
            userId: username,
            updatedBy: username,
            language: localLangCode ?? _mapDisplayToCode(selectedLanguage.value),
            measurementSystem: selectedMeasurement.value,
            pressureUnit: selectedPressure.value,
            logoLocation: '',
            updatedDate: DateTime.now(),
            lastAccessedAccountId: prefs.lastAccessedAccountId,
            lastAccessedLocationId: prefs.lastAccessedLocationId,
            lastAccessedAccountName: prefs.lastAccessedAccountName,
            lastAccessedLocationName: prefs.lastAccessedLocationName,
          );
          service.updatePreferences(modelToPush).catchError((_) => false);
        } catch (_) {}
      } else {
        // Fresh install / first time setup: user hasn't set preferences yet, so take server preferences:
        final langDisplay = _mapCodeToDisplay(prefs.language);
        final canonicalM = canonicalMeasurement(prefs.measurementSystem);
        final canonicalP = canonicalPressure(prefs.pressureUnit);

        HivePref.set('pref_language_display', langDisplay);
        HivePref.set('pref_language_code', prefs.language);
        HivePref.set('pref_measurement', canonicalM);
        HivePref.set('pref_pressure', canonicalP);

        selectedLanguage.value = langDisplay;
        selectedMeasurement.value = canonicalM;
        selectedPressure.value = canonicalP;
        MeasurementHelper.syncToGlobalState();

        final locale = _mapDisplayToLocale(langDisplay);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.updateLocale(locale);
        });
      }


      final webAccountId = prefs.lastAccessedAccountId ?? 0;
      final webLocationId = prefs.lastAccessedLocationId ?? 0;

      if (webAccountId > 0) {
        await SecureStorage.saveParentAccount(
          id: webAccountId.toString(),
          name: prefs.lastAccessedAccountName ?? '',
        );
        if (username.isNotEmpty) {
          await SecureStorage.saveParentAccountForUser(
            username: username,
            id: webAccountId.toString(),
            name: prefs.lastAccessedAccountName ?? '',
          );
        }
      }

      if (webLocationId > 0) {
        await SecureStorage.saveLocation(
          id: webLocationId.toString(),
          name: prefs.lastAccessedLocationName ?? '',
        );
        if (username.isNotEmpty) {
          await SecureStorage.saveLocationForUser(
            username: username,
            id: webLocationId.toString(),
            name: prefs.lastAccessedLocationName ?? '',
          );
        }
      }
    } catch (_) {
    }
  }

  Future<void> _loadMasterLists() async {
    isListsLoading.value = true;
    try {
      final results = await Future.wait([
        masterDataService.fetchLanguageList(),
        masterDataService.fetchMeasurementSystems(),
        masterDataService.fetchPressureUnits(),
      ]);
      languages.assignAll(results[0]);
      measurementSystems.assignAll(results[1]);
      pressureUnits.assignAll(results[2]);
    } catch (e) {
      debugPrint('⚠️ _loadMasterLists error: $e');
      if (languages.isEmpty) {
        languages.assignAll([
          'English (US/Canada)',
          'Español',
          'English(uk/Australia)',
          'Deutsche',
          'Italiano',
          'français',
          '中文',
          'русский',
          'português',
          'polski',
          'serbian',
          'Arabic',
        ]);
      }
      if (measurementSystems.isEmpty) {
        measurementSystems.assignAll(['Metric', 'Imperial']);
      }
      if (pressureUnits.isEmpty) {
        pressureUnits.assignAll(['PSI', 'KPA', 'BAR']);
      }
    } finally {
      isListsLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadMasterLists();
    _applyFromHive();
  }

  Future<void> updatePre() async {
    isLoading.value = true;
    try {
      final username = await SecureStorage.getUserName();
      final currentAccountId =
          int.tryParse(await SecureStorage.getParentAccountId() ?? '') ?? 0;
      final currentLocationId =
          int.tryParse(await SecureStorage.getLocationId() ?? '') ?? 0;
      final currentAccountName = await SecureStorage.getParentAccountName() ?? '';
      final currentLocationName = await SecureStorage.getLocationName() ?? '';

      final model = PreferencesModel(
        userId: username ?? '',
        updatedBy: username ?? '',
        language: _mapDisplayToCode(selectedLanguage.value),
        measurementSystem: selectedMeasurement.value,
        pressureUnit: selectedPressure.value,
        logoLocation: '',
        updatedDate: DateTime.now(),
        lastAccessedAccountId: currentAccountId,
        lastAccessedLocationId: currentLocationId,
        lastAccessedAccountName: currentAccountName,
        lastAccessedLocationName: currentLocationName,
      );

      // 👇 Ab ye sab yahan (Update button dabne par) hi apply hote hain,
      // dropdown selection ke time nahi.
      HivePref.set('pref_user_explicitly_set', true);
      HivePref.set('pref_language_display', selectedLanguage.value);
      HivePref.set('pref_language_code', model.language);
      HivePref.set('pref_measurement', selectedMeasurement.value);
      HivePref.set('pref_pressure', selectedPressure.value);

      // ⚡ FIX (diagram par ~1s delay): pehle global state tab update hota tha
      // jab neeche ki 5 SecureStorage (Keychain) writes `await` ho jaati thi
      // (iOS par slow). Ab Update dabate hi global state turant set hota hai,
      // jisse vehicle inspection / diagram instantly nayi unit me refresh ho.
      if (Get.isRegistered<GlobalPrefsState>()) {
        final g = Get.find<GlobalPrefsState>();
        g.measurement.value = selectedMeasurement.value;
        g.pressure.value = selectedPressure.value;
      }

      await SecureStorage.savePreference('user_explicitly_set', 'true');
      await SecureStorage.savePreference('language_display', selectedLanguage.value);
      await SecureStorage.savePreference('language_code', model.language);
      await SecureStorage.savePreference('measurement', selectedMeasurement.value);
      await SecureStorage.savePreference('pressure', selectedPressure.value);

      MeasurementHelper.syncToGlobalState();

      final locale = _mapDisplayToLocale(selectedLanguage.value);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.updateLocale(locale);
      });

      bool savedToServer = false;
      try {
        await service.updatePreferences(model);
        savedToServer = true;
      } catch (_) {

      }

      if (savedToServer) {
        // AppSnackbar.success(
        //   'User Preference Updated Successfully.',
        //   title: 'Success',
        // );
      } else {
        // AppSnackbar.offlineSuccess(
        //   'Preferences saved locally.',
        //   title: 'Success',
        // );
      }

      Get.offAllNamed(AppPages.DOWNLOAD);

    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  void cancelPreferences() {
    // Unsaved dropdown selection ko discard karke saved value pe wapas laao
    _applyFromHive();
    Get.back();
  }
}