import 'package:emtrack/routes/app_pages.dart';
import 'package:emtrack/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/all_tyre_controller.dart';
import '../color/app_color.dart';
import '../controllers/auth_controller.dart';
import '../controllers/preferences_controller.dart';
import '../services/role_service.dart';
import '../utils/app_utils.dart';
import '../utils/local_helper.dart';
import '../l10n/app_localizations.dart';

class AllTyresView extends StatelessWidget {
  AllTyresView({super.key});

  final AllTyreController controller = Get.put(AllTyreController());
  final PreferencesController _preferencesController =
  Get.find<PreferencesController>();
  final AuthController _auth = Get.find<AuthController>();
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    WidgetsBinding.instance.addPostFrameCallback((_) {

      if (controller.tabController != null &&
          controller.tabController!.index != 0) {
        controller.tabController!.animateTo(0);
      }
      controller.searchText.value = '';
      controller.reapplyFilters();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${t.all} ${LocaleHelper.tyreName(context)}",
          style: const TextStyle(color: Colors.black),
        ),

        centerTitle: true,
        leading: const BackButton(color: AppColors.primary),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search
            AppSearchBar(
              onChanged: controller.onSearch,
              hintText:
              '${t.searchHint.replaceAll('...', '')} ${LocaleHelper.tyreName(context)} ',
            ),

            // Tab bar
            TabBar(
              controller: controller.tabController,
              isScrollable: true,
              indicatorColor: AppColors.buttonDanger,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.buttonDanger,
              unselectedLabelColor: AppColors.primary,
              tabs: controller.tabs.map((e) => Tab(text: e)).toList(),
            ),

            Expanded(
              child: TabBarView(
                controller: controller.tabController,
                children: controller.tabs.map((_) {
                  return Obx(() {
                    if (controller.isLoading.value &&
                        controller.allTyres.isEmpty) {
                      return const AppListSkeleton();
                    }

                    // EMPTY CASE
                    if (controller.visibleTyres.isEmpty) {
                      return Center(
                        child: Text(t.noDataAvailable),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => controller.refresh(),
                      color: Colors.red,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: controller.visibleTyres.length,
                        itemBuilder: (_, i) {
                          final tyre = controller.visibleTyres[i];
                          return GestureDetector(
                            onTap: () => controller.openBottomSheet(tyre),
                            child: Card(
                              color: Colors.red.shade50.withAlpha(230),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              shape: RoundedSuperellipseBorder(
                                side: const BorderSide(
                                  color: Colors.red,
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        (tyre.brandNo != null)
                                            ? "${tyre.tireSerialNo ?? '-'} / ${tyre.brandNo}"
                                            : (tyre.tireSerialNo ?? '-'),
                                        style: const TextStyle(
                                          color: AppColors.buttonDanger,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow
                                            .ellipsis,
                                      ),
                                    ),
                                    // if ((tyre.tireId ?? 0) < 0)
                                    //   AppStatusBadge.pendingSync(label: t.pendingSync),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    // --- Vehicle ID ---
                                    Row(
                                      children: [
                                        Text(
                                          '${t.vehicleId}:',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            tyre.vehicleNumber ?? '-',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),

                                    Wrap(
                                      spacing: 10,
                                      runSpacing:
                                      4,
                                      children: [
                                        // Size Section
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${t.tyreSize}: ',
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              tyre.sizeName ?? '-',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Type Section
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${t.vehicleType}: ',
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              tyre.typeName ?? '-',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),

                                    // --- Status ---
                                    Row(
                                      children: [
                                        Text(
                                          '${t.status}: ',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Expanded(
                                          child: Text(
                                            tyre.tireStatusName ?? "-",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: SizedBox(
                                  width:
                                  70,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/svgImage/tire.svg',
                                        height: 24,
                                        colorFilter: const ColorFilter.mode(
                                          Colors.red,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Builder(
                                        builder: (_) {
                                          double tread =
                                              tyre.currentTreadDepth ?? 0;
                                          if (tread == 0) {
                                            final outside =
                                                tyre.outsideTread ?? 0;
                                            final middle = tyre.middleTread ?? 0;
                                            final inside = tyre.insideTread ?? 0;
                                            if (middle > 0) {
                                              tread =
                                                  (outside + middle + inside) / 3;
                                            } else if (outside > 0 ||
                                                inside > 0) {
                                              tread = (outside + inside) / 2;
                                            }
                                          }
                                          final unit =
                                          _preferencesController
                                              .selectedMeasurement
                                              .value ==
                                              "Imperial"
                                              ? "/32"
                                              : "mm";
                                          return FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              "${formatNum(tread)} $unit",
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  });
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Obx(() {
        final role = _auth.userRole.value;
        if (!RoleService.canCreateTire(role)) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => Get.toNamed(AppPages.CREATE_TYRE),
          child: Container(
            margin: const EdgeInsets.only(right: 4, bottom: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [Image.asset('assets/images/NewTire.png', width: 150)],
            ),
          ),
        );
      }),
      //_createTireFAB(),
    );
  }

  Widget _createTireFAB() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow.shade800,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40),
                bottomLeft: Radius.circular(40),
                topRight: Radius.circular(40),
                bottomRight: Radius.circular(0),
              ),
            ),
          ),
          onPressed: () {
            Get.toNamed(AppPages.CREATE_TYRE);
          },
          child: const Text(
            'Create New Tire',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(width: 5),

        FloatingActionButton(
          backgroundColor: Colors.blue.shade900,
          shape: const CircleBorder(),
          onPressed: () {
            Get.toNamed(AppPages.CREATE_TYRE);
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.trip_origin, // tire
                color: Colors.white,
                size: 30,
              ),

              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: const Icon(Icons.add, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}