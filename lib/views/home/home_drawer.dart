import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emtrack/color/app_color.dart';
import 'package:emtrack/routes/app_pages.dart';
import 'package:emtrack/search_tyre_vehicle/search_vehicle_tyre_view.dart';
import 'package:emtrack/user_management/user_management_list_view.dart';
import 'package:emtrack/views/change_account_view.dart';
import 'package:emtrack/views/create_vehicle_view.dart';
import 'package:emtrack/views/grand_parent_account_view/grand_parent_account_view.dart';
import 'package:emtrack/views/grand_parent_account_view/grandparent_account_list_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/download_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../services/role_service.dart';
import '../../utils/local_helper.dart';

class HomeDrawer extends StatelessWidget {
  final HomeController hc = Get.find<HomeController>();
  final AuthController auth = Get.find<AuthController>();

  HomeDrawer({super.key});

  Future<void> _checkNetworkAndNavigate(VoidCallback onValid) async {
    final results = await Connectivity().checkConnectivity();
    final isOnline = results.any((r) => r != ConnectivityResult.none);

    if (!isOnline) {
      Get.snackbar(
        "Error",
        "Failed to load users. Please check your network.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(
          Icons.wifi_off,
          color: Colors.white,
        ),
        duration: const Duration(seconds: 4),
      );
      return;
    }
    onValid();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      hc.closeCreateMenu();
      hc.closeUserMenu();
    });

    return Obx(() {
      final data = hc.homeData.value;
      final String role = auth.userRole.value;

      return Material(
        color: AppColors.primary,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CLOSE ICON + LOGO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Image.asset('assets/images/logo.png', width: 120),
                ],
              ),
              const SizedBox(height: 6),

              // USER INFO
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade800,
                    backgroundImage: hc.imageUrl.isNotEmpty
                        ? NetworkImage(hc.imageUrl)
                        : null,
                    child: hc.imageUrl.isEmpty
                        ? const Icon(Icons.person, color: Colors.white, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hc.username.value,
                        style: TextStyle(
                          color: AppColors.drawerHighlight,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          RoleService.roleDisplayName(role),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Text(
                '${t.parentAccount}:',
                style: TextStyle(color: AppColors.drawerHighlight),
              ),
              const SizedBox(height: 6),
              Text(
                data?.parentAccount ?? hc.selectedParentAccountName.value,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                '${t.location}:',
                style: TextStyle(color: AppColors.drawerHighlight),
              ),
              const SizedBox(height: 6),
              Text(
                data?.location ?? hc.selectedLocationName.value,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              // CHANGE ACCOUNT BUTTON
              InkWell(
                onTap: () => Get.to(() => ChangeAccountView()),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.buttonDanger,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.place, color: Colors.white),
                      Text(
                        ' ${t.changeLocationAccount}',
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              //MENU AREA
              Expanded(
                child: Obx(() {
                  // CREATE SUB MENU
                  if (hc.isCreateOpen.value) {
                    return ListView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        DrawerItem(
                          '← ${t.mainMenu}',
                          color: AppColors.drawermenu,
                          onTap: hc.closeCreateMenu,
                        ),
                        if (RoleService.canCreateVehicle(role))
                          DrawerItem(
                            t.createVehicleMenu,
                            color: AppColors.textWhite,
                            onTap: () {
                              Navigator.of(context).pop();
                              Get.to(() => const CreateVehicleView());
                            },
                          ),
                        if (RoleService.canCreateTire(role))
                          DrawerItem(
                            "${t.create} ${LocaleHelper.tyreName(context)}",
                            color: AppColors.textWhite,
                            onTap: () {
                              Navigator.of(context).pop();
                              Get.toNamed(AppPages.CREATE_TYRE);
                            },
                          ),
                        if (!RoleService.canCreateVehicle(role) &&
                            !RoleService.canCreateTire(role))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              t.noPermissionCreate,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    );
                  }

                  /// USER / ADMIN SUB MENU (Visible only for admin and super admin)
                  if (hc.isUserOpen.value && RoleService.canViewUserDrawerMenu(role)) {
                    return ListView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        DrawerItem(
                          '← ${t.mainMenu}',
                          color: AppColors.drawermenu,
                          onTap: hc.closeUserMenu,
                        ),
                        DrawerItem(
                          t.userManagementList,
                          color: AppColors.textWhite,
                          onTap: () => _checkNetworkAndNavigate(() {
                            Navigator.of(context).pop();
                            Get.to(() => UserManagementListView());
                          }),
                        ),
                        DrawerItem(
                          "${t.create} ${t.grandparentAccount}",
                          color: AppColors.textWhite,
                          onTap: () => _checkNetworkAndNavigate(() {
                            Navigator.of(context).pop();
                            Get.to(() => GrandparentAccountView());
                          }),
                        ),
                        DrawerItem(
                          t.grandparentAccountView,
                          color: AppColors.textWhite,
                          onTap: () => _checkNetworkAndNavigate(() {
                            Navigator.of(context).pop();
                            Get.to(() => GrandparentAccountListView());
                          }),
                        ),
                      ],
                    );
                  }

                  /// MAIN MENU
                  return ListView(
                    children: [
                      DrawerItem(
                        t.home,
                        color: AppColors.textWhite,
                        onTap: () => Get.back(),
                      ),
                      if (RoleService.canCreateVehicle(role) ||
                          RoleService.canCreateTire(role))
                        DrawerItem(
                          '${t.create} >',
                          color: AppColors.textWhite,
                          onTap: hc.openCreateMenu,
                        ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          t.startInspection,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          Get.back();
                          Get.to(() => SearchVehicleTyreView());
                        },
                      ),

                      /// PREFERENCES
                      DrawerItem(
                        t.preferences,
                        color: AppColors.textWhite,
                        onTap: () {
                          Get.back();
                          Get.toNamed(AppPages.PREFERENCE);
                        },
                      ),

                      // User Management Menu Item (Visible only for admin and super admin)
                      if (RoleService.canViewUserDrawerMenu(role))
                        DrawerItem(
                          '${t.user} >',
                          color: AppColors.textWhite,
                          onTap: hc.openUserMenu,
                        ),

                      // All Sync Menu Item (Red text above Logout)
                      DrawerItem(
                        'All Sync',
                        color: Colors.redAccent,
                        onTap: () {
                          Navigator.of(context).pop();
                          _showAllSyncDialog(t);
                        },
                      ),

                      DrawerItem(
                        t.logout,
                        color: AppColors.textWhite,
                        onTap: () => _showLogoutDialog(t),
                      ),
                    ],
                  );
                }),
              ),

              const SizedBox(height: 12),
              Text(
                '${t.appVersion}: ${data?.appVersion ?? '14'}',
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Image.asset('assets/images/apk_logo.png', width: 40),
                  const SizedBox(width: 8),
                  const Text(
                    '@2025 The Yokohama Rubber Co., Ltd.',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showLogoutDialog(AppLocalizations t) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 10,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.logout,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Are you sure you want to logout?",
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      t.cancel,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      auth.logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonDanger,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      t.okBtn,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _showAllSyncDialog(AppLocalizations t) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 10,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "All Sync",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Do you want to re-download all data? This may take a few minutes.",
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      t.cancel,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      if (Get.isRegistered<DownloadController>()) {
                        Get.delete<DownloadController>();
                      }
                      Get.offAllNamed(
                        AppPages.DOWNLOAD,
                        arguments: {'force': true},
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      t.okBtn,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}

class DrawerItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const DrawerItem(this.title, {this.color, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: TextStyle(color: color, fontSize: 18)),
      onTap: onTap,
    );
  }
}