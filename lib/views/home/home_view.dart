import 'package:emtrack/color/app_color.dart';
import 'package:emtrack/controllers/auth_controller.dart';
import 'package:emtrack/inspection/vehicle_inspe_view.dart';
import 'package:emtrack/l10n/app_localizations.dart';
import 'package:emtrack/routes/app_pages.dart';
import 'package:emtrack/search_tyre_vehicle/search_vehicle_tyre_view.dart';
import 'package:emtrack/views/all_vehicles_list_view.dart';
import 'package:emtrack/views/change_account_view.dart';
import 'package:emtrack/views/view_inspection_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import '../../inspection_approval/iw.dart';
import '../../utils/app_snackbar.dart';
import '../../utils/local_helper.dart';
import '../../utils/secure_storage.dart';
import '../../utils/approval_localizations.dart';
import 'home_drawer.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final HomeController ctrl = Get.put(HomeController());
  final auth = Get.put(AuthController());

  // ── Double back press to exit ──
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    Future.delayed(Duration.zero, () async {
      final args = Get.arguments;
      if (args == null) return;

      if (args["refreshOnly"] == true) {
        ctrl.refreshCounts();
        ctrl.fetchHome(showLoader: false);
        return;
      }

      if (args["triggerSnackbar"] == true) {
        final bool isOffline = args["isOffline"] == true;
        final String title = args["title"] ?? "";
        final String message = args["message"] ?? "";

        Future.delayed(const Duration(milliseconds: 600), () {
          if (!Get.isSnackbarOpen) {
            if (isOffline) {
              AppSnackbar.offlineSuccess(message, title: title);
            } else {
              AppSnackbar.success(message, title: title);
            }
          }
        });

        ctrl.refreshCounts();
        if (!isOffline) {
          try {
            await ctrl.fetchHome();
          } catch (_) {}
        }
        return;
      }

      // ── 2. Purana Logic (For Vehicle Redirects & Legacy Support) ────
      if (args["showSuccess"] == true) {
        if (!mounted) return;
        final bool isTyre = args["module"] == "tyre";
        final bool isUpdate = args["type"] == "update";
        final String serialNo = (args["serialNo"] ?? '-').toString();
        final String vehicleNo = (args["vehicleNo"] ?? '-').toString();

        String title = isTyre
            ? (isUpdate
            ? "${LocaleHelper.tyreName(context)} Updated"
            : "New ${LocaleHelper.tyreName(context)} Created")
            : (isUpdate ? "Vehicle Updated" : "New Vehicle Created");

        String message = "";
        if (isTyre) {
          message =
          "${LocaleHelper.tyreName(context)} with Serial No: $serialNo "
              "${isUpdate ? 'updated' : 'created'} successfully.";
        } else {
          message = isUpdate
              ? "Vehicle: $vehicleNo updated successfully."
              : "Vehicle: $vehicleNo created successfully.";

          final int? vehicleId = args["vehicleId"] is int
              ? args["vehicleId"] as int
              : int.tryParse(args["vehicleId"]?.toString() ?? '');

          if (vehicleId != null) {
            message += "\nRedirecting on Vehicle Inspection.";
          }
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (!Get.isSnackbarOpen) {
              // Note: Agar yahan "savedOffline" flag ke base par logic hai,
              // toh bas woh line nahi aayegi, snackbar type wahi rahega.
              if (args["savedOffline"] == true) {
                AppSnackbar.offlineSuccess(message, title: title);
              } else {
                AppSnackbar.success(message, title: title);
              }
            }
          });
        });

        final int? vehicleId = isTyre
            ? null
            : (args["vehicleId"] is int
            ? args["vehicleId"] as int
            : int.tryParse(args["vehicleId"]?.toString() ?? ''));

        if (!isTyre && vehicleId != null) {
          Future.delayed(const Duration(seconds: 3), () {
            if (Get.currentRoute.contains('home') || Get.currentRoute == '/') {
              Get.offAll(() => const VehicleInspeView(), arguments: vehicleId);
            }
          });
        }

        ctrl.refreshCounts();
      }
    });
  }

  String _formatLastInspection(String? raw, AppLocalizations t) {
    if (raw == null || raw.isEmpty) return t.noDataAvailable;

    return LocaleHelper.formatDateTime(raw, fallback: raw);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ctrl.refreshCounts();
  }

  String _getLocationText() {
    final account = ctrl.homeData.value?.parentAccount.isNotEmpty == true
        ? ctrl.homeData.value!.parentAccount
        : ctrl.selectedParentAccountName.value;

    // ✅ Multi-location: agar ek se zyada locations selected hain to
    // "Loc1 +2 more" jaisa combined text dikhao; single location ho to
    // pehle jaisa hi behavior.
    String location;
    final names = ctrl.selectedLocationNames;
    if (names.length > 1) {
      location = "${names.first} +${names.length - 1} more";
    } else if (names.length == 1 && names.first.isNotEmpty) {
      location = names.first;
    } else {
      location = ctrl.homeData.value?.location.isNotEmpty == true
          ? ctrl.homeData.value!.location
          : ctrl.selectedLocationName.value;
    }

    return "${account.isNotEmpty ? account : '--'} - ${location.isNotEmpty ? location : '--'}";
  }

  Future<void> _handleBackPress() async {
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;

      Get.snackbar(
        '',
        'Press Again to exit',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        borderRadius: 8,
        titleText: const SizedBox.shrink(),
        messageText: const Text(
          'Press Again to exit',
          style: TextStyle(color: Colors.white, fontSize: 13),
        ),
        animationDuration: const Duration(milliseconds: 200),
      );
      return;
    }

    await SystemNavigator.pop(animated: true);
  }
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final a = ApprovalLocalizations.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBackPress();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset('assets/images/apk_logo.png', width: 80),
              const SizedBox(width: 8),
              Image.asset('assets/images/logo.png', width: 120),
            ],
          ),
        ),
        drawer: Drawer(
          backgroundColor: Colors.black,
          child: SafeArea(child: HomeDrawer()),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  await ctrl.refreshHome();
                  ctrl.refreshCounts();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Obx(
                        () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF474747),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/map.png'),
                              fit: BoxFit.fitWidth,
                              opacity: 0.22,
                              alignment: Alignment.centerRight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${t.greeting} ${ctrl.username.value},",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.selectedAccountLocation,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                _getLocationText(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () async {
                                      final updated = await Get.to(
                                            () => ChangeAccountView(),
                                      );
                                      if (updated == true) {
                                        await ctrl.refreshCountsFromHive();
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        t.change,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () =>
                                    Get.to(() => SearchVehicleTyreView()),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    border: Border.all(color: Colors.white),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.search,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          '${t.searchHint.replaceAll('...', '')} ${t.vehicle} / ${LocaleHelper.tyreName(context)}',
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _DashboardCard(
                                      svgPath:
                                      'assets/svgImage/total-tires-icon.svg',
                                      label:
                                      "${t.total} ${LocaleHelper.tyreName(context)}",
                                      valueWidget: Text(
                                        ctrl.tyreCount.value.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      onTap: () =>
                                          Get.toNamed(AppPages.ALL_TYRE_WIEW),
                                      viewText: t.view,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _DashboardCard(
                                      svgPath: 'assets/svgImage/vehicle-icon.svg',
                                      label: "${t.total} ${t.vehicle}",
                                      valueWidget: Text(
                                        ctrl.vehicleCount.value.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      onTap: () =>
                                          Get.to(() => AllVehicleListView()),
                                      viewText: t.view,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      t.lastInspection,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _formatLastInspection(
                                        ctrl.lastInspection,
                                        t,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Obx(() {
                                final syncing = ctrl.isSyncing.value;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    border: Border.all(
                                      color: const Color(0xFFCC0000),
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Icons.sync,
                                        color: Color(0xFFCC0000),
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Sync',
                                        style: TextStyle(
                                          color: Color(0xFFCC0000),
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              })
                            ],
                          ),
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFEAEAEA),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                          child: Text(
                            t.viewInspections,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    await Get.to(
                                          () => const ViewInspectionPage(),
                                      arguments: 0,
                                    );
                                    ctrl.refreshCounts();
                                  },
                                  child: Obx(
                                        () => _InspectionCountCard(
                                      label: t.unsyncInspection,
                                      count: ctrl.unsyncedInspectionCount.value
                                          .toString(),
                                      viewText: t.view,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    await Get.to(
                                          () => const ViewInspectionPage(),
                                      arguments: 1,
                                    );
                                    ctrl.refreshCounts();
                                  },
                                  child: Obx(
                                        () => _InspectionCountCard(
                                      label: t.syncInspection,
                                      count: ctrl.syncedInspectionCount.value
                                          .toString(),
                                      viewText: t.view,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        Obx(() {
                          final bool isWorkflowEnabled = auth.isApprovalWorkflowEnabled.value;
                          final role = auth.userRole.value.trim().toUpperCase();

                          bool showSection = false;

                          if (isWorkflowEnabled) {
                            if (role == 'EMTUSER') {
                              showSection = true;
                            } else {
                              showSection = auth.hasGrandParentAccount.value;
                            }
                          } else {
                            showSection = false;
                          }

                          if (!showSection) {
                            return const SizedBox.shrink();
                          }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      a.vehiclesTiresInspections,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: inspectionCard(
                                            title: a.vehicleInspection,
                                            count: ctrl.vehicleInspectionCount.value,
                                            viewText: a.viewAction,
                                            onView: () => Get.to(
                                                  () => const IWSearchScreen(initialTab: 0),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: inspectionCard(
                                            title: a.tireInspection,
                                            count: ctrl.tireInspectionCount.value,
                                            viewText: a.viewAction,
                                            onView: () => Get.to(
                                                  () => const IWSearchScreen(initialTab: 1),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
              Obx(() {
                if (!ctrl.isLoading.value) return const SizedBox.shrink();
                return Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.6),
                      child: Center(
                        child: Image.asset(
                          'assets/images/emtrack_loader.gif',
                          width: 120,
                          height: 120,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          bottom: true,
          child: InkWell(
            onTap: () async {
              await Get.to(() => SearchVehicleTyreView());
              ctrl.refreshCounts();
            },
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 20,
                right: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Image.asset('assets/images/Start-Insp.png', height: 47),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget inspectionCard({
    required String title,
    required int count,
    required String viewText,
    required VoidCallback onView,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onView,
            child: Text(
              viewText,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String svgPath;
  final String label;
  final Widget valueWidget;
  final VoidCallback onTap;
  final String viewText;
  const _DashboardCard({
    required this.svgPath,
    required this.label,
    required this.valueWidget,
    required this.onTap,
    required this.viewText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  svgPath,
                  width: 28,
                  height: 28,
                  colorFilter: const ColorFilter.mode(
                    Colors.red,
                    BlendMode.srcIn,
                  ),
                  placeholderBuilder: (_) =>
                  const Icon(Icons.circle, color: Colors.red, size: 28),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      valueWidget,
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    viewText,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.red, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InspectionCountCard extends StatelessWidget {
  final String label;
  final String count;
  final String viewText;

  const _InspectionCountCard({
    required this.label,
    required this.count,
    required this.viewText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCC0000), width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            count,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  viewText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFCC0000),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFCC0000),
                  size: 14,
                ),
              ],
            ),
          ),
        ],
      ),

    );
  }
}
