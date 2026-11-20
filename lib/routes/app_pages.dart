import 'package:emtrack/bindings/app_binding.dart';
import 'package:emtrack/create_tyre/create_tyre_screen.dart';
import 'package:emtrack/edit_tyre/edit_tyre_screen.dart';
import 'package:emtrack/inspection/update_hours_view.dart';
import 'package:emtrack/inspection/vehicle_inspe_view.dart';
import 'package:emtrack/user_management/user_management_view.dart';
import 'package:emtrack/views/all_tyres_view.dart';
import 'package:emtrack/views/all_vehicles_list_view.dart';
import 'package:emtrack/views/download_view.dart';
import 'package:emtrack/views/home/home_view.dart';
import 'package:emtrack/views/install_tyre_view.dart';
import 'package:emtrack/views/password_reset_view.dart';
import 'package:emtrack/views/preferences_view.dart';
import 'package:emtrack/views/remove_tyre_view.dart';
import 'package:emtrack/views/vehicle_view.dart';
import 'package:flutter/animation.dart';
import 'package:get/get.dart';
import '../views/splash_view.dart';
import '../views/login_view.dart';

class AppPages {
  static const Transition _transition = Transition.fadeIn;
  static const Curve _curve = Curves.easeOutCubic;
  static const Duration _duration = Duration(milliseconds: 380);

  static const SPLASH = '/';
  static const LOGIN = '/login';
  static const DOWNLOAD = '/download';
  static const HOME = '/home';
  static const CREATE_TYRE = '/create-tyre';
  static const ALL_TYRE_WIEW = '/all-tire-view';
  static const ALL_VEHICLE_WIEW = '/all-vehicle-view';
  static const PREFERENCE = '/change-preference';
  static const USER_MANAGEMENT_VIEW = '/user_management_view';
  static const UPDATE_HOURS = '/update_hours';
  static const EDIT_TIRE_SCREEN = '/edit_tire_screen';
  static const REMOVE_TIRE = '/remove-tyre';
  static const VEHICLE_INSPEC_VIEW = '/vehicle-inspec-view';
  static const INSTALL_TYRE_VIEW = '/install-tyre-view';
  static const VEHICLE_VIEW = '/vehicle-view';
  static const PASSWORD_RESET = '/password-reset';

  static final pages = [
    GetPage(
      name: SPLASH,
      page: () => const SplashView(),
      binding: AppBindings(),
      transition: _transition,
      curve: _curve,
      transitionDuration: _duration,
    ),
    GetPage(
      name: LOGIN,
      page: () => LoginView(),
      binding: AppBindings(),
      transition: _transition,
      curve: _curve,
      transitionDuration: _duration,
    ),
    GetPage(
      name: DOWNLOAD,
      page: () => const DownloadView(),
      binding: AppBindings(),
      transition: _transition,
      curve: _curve,
      transitionDuration: _duration,
    ),
    GetPage(
      name: HOME,
      page: () => HomeView(),
      binding: AppBindings(),
      transition: _transition,
      curve: _curve,
      transitionDuration: _duration,
    ),
    GetPage(
      name: CREATE_TYRE,
      page: () => CreateTyreScreen(),
      binding: AppBindings(),
      transition: _transition,
      curve: _curve,
      transitionDuration: _duration,
    ),
    GetPage(
      name: PREFERENCE,
      page: () => PreferencesView(),
      binding: AppBindings(),
      transition: _transition,
      curve: _curve,
      transitionDuration: _duration,
    ),
    GetPage(
      name: ALL_TYRE_WIEW,
      page: () => AllTyresView(),
      binding: AppBindings(),
      transition: _transition,
      curve: _curve,
      transitionDuration: _duration,
    ),
    GetPage(
      name: ALL_VEHICLE_WIEW,
      page: () => AllVehicleListView(),
      binding: AppBindings(),
      transition: _transition,
      curve: _curve,
      transitionDuration: _duration,
    ),
    GetPage(
      name: USER_MANAGEMENT_VIEW,
      page: () => UserManagementView(),
      binding: AppBindings(),
      transition: _transition,
      curve: _curve,
      transitionDuration: _duration,
    ),
    GetPage(
      name: UPDATE_HOURS,
      page: () => UpdateHoursView(),
      binding: AppBindings(),
      transition: _transition,
      curve: _curve,
      transitionDuration: _duration,
    ),
    GetPage(
      name: EDIT_TIRE_SCREEN,
      page: () => EditTyreScreen(),
      binding: AppBindings(),
      transition: _transition,
      curve: _curve,
      transitionDuration: _duration,
    ),
    GetPage(
      name: REMOVE_TIRE,
      page: () => RemoveTyreView(),
      binding: AppBindings(),
      transition: _transition,
      curve: _curve,
      transitionDuration: _duration,
    ),
    GetPage(
      name: VEHICLE_INSPEC_VIEW,
      page: () => VehicleInspeView(),
      binding: AppBindings(),
      transition: _transition,
      curve: _curve,
      transitionDuration: _duration,
    ),
    GetPage(
      name: INSTALL_TYRE_VIEW,
      page: () => InstallTyreView(),
      binding: AppBindings(),
      transition: _transition,
      curve: _curve,
      transitionDuration: _duration,
    ),
    GetPage(
      name: PASSWORD_RESET,
      page: () => ResetPasswordView(),
      binding: AppBindings(),
      transition: _transition,
      curve: _curve,
      transitionDuration: _duration,
    ),
  ];
}