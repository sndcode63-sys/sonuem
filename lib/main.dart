import 'package:emtrack/bindings/app_binding.dart';
import 'package:emtrack/l10n/app_localizations.dart';
import 'package:emtrack/utils/hive_prefe.dart';
import 'package:emtrack/utils/local_image_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'routes/app_pages.dart';
import 'package:hive_flutter/hive_flutter.dart';

Locale _localeFromCode(String? code) {
  if (code == null || code.isEmpty) return const Locale('en');
  const supported = {'en','es','de','fr','it','pt','ru','zh','ar','pl'};
  final normalized = code.toLowerCase().split('-').first;
  return supported.contains(normalized) ? Locale(normalized) : const Locale('en');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await Hive.initFlutter();
  await Hive.openBox('preferencesBox');
  await LocalImageCache.init();

  final savedCode = HivePref.get<String>('pref_language_code');
  final initialLocale = _localeFromCode(savedCode);

  runApp(YokohamaApp(initialLocale: initialLocale));
}

class YokohamaApp extends StatelessWidget {
  final Locale initialLocale;
  const YokohamaApp({super.key, required this.initialLocale});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'EMTrack Mobile',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child ?? const SizedBox(),
        );
      },
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Colors.red,
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red, primary: Colors.red),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.red,
          selectionHandleColor: Colors.red,
          selectionColor: Colors.red,
        ),
      ),
      locale: initialLocale,
      fallbackLocale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: AppPages.SPLASH,
      initialBinding: AppBindings(),
      getPages: AppPages.pages,
    );
  }
}