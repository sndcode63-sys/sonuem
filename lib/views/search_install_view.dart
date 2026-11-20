import 'package:emtrack/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import '../color/app_color.dart';
import '../controllers/install_tyre_controller.dart';
import '../controllers/preferences_controller.dart';
import '../controllers/search_install_tire_controller.dart';
import '../create_tyre/create_tyre_screen.dart';
import '../l10n/app_localizations.dart';
import '../models/tyre_model.dart';
import '../routes/app_pages.dart';
import '../utils/local_helper.dart';

class SearchInstallView extends StatefulWidget {
  const SearchInstallView({super.key});

  @override
  State<SearchInstallView> createState() => _SearchInstallViewState();
}

class _SearchInstallViewState extends State<SearchInstallView> with RouteAware {
  late final int vehicleId;
  late final String vehicleNumber;
  late final String wheelPosition;
  late final SearchInstallTireController controller;


  PreferencesController get _prefs {
    if (Get.isRegistered<PreferencesController>()) {
      return Get.find<PreferencesController>();
    }
    return Get.put(PreferencesController());
  }

  @override
  void initState() {
    super.initState();
    vehicleId = Get.arguments["vehicleId"];
    vehicleNumber = Get.arguments['vehicleNumber'];
    wheelPosition = Get.arguments["wheelPosition"];
    controller = Get.put(SearchInstallTireController());
  }

  @override
  void didPopNext() {
    controller.fetchInventoryTyres();
  }

  String clean(dynamic val) {
    if (val == null) return '-';
    final d = double.tryParse(val.toString());
    if (d == null) return val.toString();
    return d == d.truncateToDouble() ? d.toInt().toString() : d.toString();
  }

  void _goToInstallView({
    required int tireId,
    required String serialNo,
    required TyreModel tyre,
  }) {
    if (tireId <= 0 && serialNo.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Tyre data incomplete. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    if (Get.isRegistered<InstallTyreController>()) {
      Get.delete<InstallTyreController>(force: true);
    }

    final String inspectionDate = tyre.inspectionDate != null
        ? tyre.inspectionDate!.toIso8601String()
        : '';
    final bool isOfflineTyre = tireId <= 0;

    Get.toNamed(
      AppPages.INSTALL_TYRE_VIEW,
      arguments: {
        'vehicleId': vehicleId,
        'vehicleNumber': vehicleNumber,
        'wheelPosition': wheelPosition,
        'tireId': tireId,
        'serialNo': serialNo,
        'inspectionDate': inspectionDate,
        'outsideTread': tyre.outsideTread ?? 0.0,
        'middleTread': tyre.middleTread ?? 0.0,
        'insideTread': tyre.insideTread ?? 0.0,
        'currentPressure': tyre.currentPressure ?? 0.0,
        'currentTreadDepth': 0.0,
        'currentHours': tyre.currentHours ?? 0.0,
        'currentMiles': tyre.currentMiles ?? 0.0,
        'manufacturerName': tyre.manufacturerName ?? '',
        'sizeName': tyre.sizeName ?? '',
        'typeName': tyre.typeName ?? '',
        'brandNo': tyre.brandNo ?? '',
        'dispositionName': tyre.dispositionName ?? '',
        'dispositionId': tyre.dispositionId ?? 0,
        'dispositionGroupId': tyre.dispositionGroupId ?? 0,
        'isOfflineTyre': isOfflineTyre,
        'originalTread': tyre.originalTread ?? 0.0,
        'removeAt': tyre.removeAt ?? 0.0,
        'percentageWorn': tyre.percentageWorn ?? 0.0,
        'isInspectionFlow': true,
      },
    )?.then((_) async {
      // Install screen se wapas aane par list turant refresh karo.
      // (didPopNext yahan kabhi call nahi hota tha kyunki RouteObserver
      // kahin register nahi hai, isliye offline install ke baad bhi
      // installed tyre list me dikhta rehta tha.)
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) controller.fetchInventoryTyres();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "${t.searchHint}, ${t.install} & ${t.inspect} ${LocaleHelper.tyreName(context)}",
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── INFO CARD ───
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 5),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${t.vehicleId}:"),
                  Text(
                    vehicleNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Text(
                    "${t.wheelPosition}:",
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    wheelPosition,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // ─── SEARCH FIELD ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextFormField(
                onChanged: controller.onSearch,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: t.searchInventory,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 1),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ─── TYRE LIST ───
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.allTyres.isEmpty) {
                  return const AppLoadingIndicator();
                }

                if (controller.visibleTyres.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 80,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          t.noInventoryFound,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: controller.visibleTyres.length,
                  itemBuilder: (_, i) {
                    final tyre = controller.visibleTyres[i];

                    return GestureDetector(
                      onTap: () => _goToInstallView(
                        tireId: tyre.tireId ?? 0,
                        serialNo: tyre.tireSerialNo ?? '',
                        tyre: tyre,
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text(
                            (tyre.brandNo != null && tyre.brandNo!.isNotEmpty)
                                ? "${tyre.tireSerialNo ?? '-'} / ${tyre.brandNo}"
                                : "${tyre.tireSerialNo ?? '-'}",
                            style: const TextStyle(
                              color: AppColors.buttonDanger,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${t.status}: ${tyre.tireStatusName ?? tyre.dispositionName ?? '-'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${t.tyreSize}: ${tyre.sizeName ?? '-'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if ((tyre.manufacturerName ?? '').isNotEmpty)
                                Text(
                                  '${t.manufacturer}: ${tyre.manufacturerName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              Text(
                                '${t.treadDepth}: ${_getTreadDepth(tyre)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: _tyreValueBadge(tyre),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildFAB(),
    );
  }

  // ─── TYRE ICON + TREAD VALUE BADGE (jaise AllTyresView mein hai) ──────────
  Widget _tyreValueBadge(TyreModel tyre) {
    final unit =
    _prefs.selectedMeasurement.value == "Imperial" ? "/32" : "mm";

    return SizedBox(
      width: 70,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/svgImage/tire.svg',
            height: 24,
            colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "${_getTreadDepth(tyre)} $unit",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () => Get.to(() => CreateTyreScreen()),
          child: Image.asset('assets/images/NewTire.png', width: 150),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  String _getTreadDepth(TyreModel tyre) {
    final outside = tyre.outsideTread ?? 0.0;
    final middle = tyre.middleTread ?? 0.0;
    final inside = tyre.insideTread ?? 0.0;

    if (outside > 0 && middle > 0 && inside > 0) {
      final avg = (outside + middle + inside) / 3;
      return avg == avg.truncateToDouble()
          ? avg.toInt().toString()
          : avg.toStringAsFixed(1);
    }

    if (middle > 0 && outside > 0) {
      final avg = (outside + middle) / 2;
      return avg == avg.truncateToDouble()
          ? avg.toInt().toString()
          : avg.toStringAsFixed(1);
    }
    if (middle > 0 && inside > 0) {
      final avg = (middle + inside) / 2;
      return avg == avg.truncateToDouble()
          ? avg.toInt().toString()
          : avg.toStringAsFixed(1);
    }

    if (outside > 0 && inside > 0) {
      final avg = (outside + inside) / 2;
      return avg == avg.truncateToDouble()
          ? avg.toInt().toString()
          : avg.toStringAsFixed(1);
    }

    if (middle > 0) return clean(middle);
    if (outside > 0) return clean(outside);
    if (inside > 0) return clean(inside);

    final ctd = tyre.currentTreadDepth ?? 0.0;
    if (ctd > 0) return clean(ctd);

    return '-';
  }
}