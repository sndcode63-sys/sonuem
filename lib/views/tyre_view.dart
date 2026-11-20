import 'package:emtrack/controllers/preferences_controller.dart';
import 'package:emtrack/controllers/selected_account_controller.dart';
import 'package:emtrack/models/tyre_view_model.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:emtrack/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/tyre_view_controller.dart';
import '../l10n/app_localizations.dart';
import '../utils/local_helper.dart';
import '../utils/mesurment_helper_class.dart';

class TyreView extends StatefulWidget {
  const TyreView({super.key});

  @override
  State<TyreView> createState() => _TyreViewState();
}


class _TyreViewState extends State<TyreView>
    with SingleTickerProviderStateMixin {

  late final TyreViewController controller;
  late final SelectedAccountController selectController;
  late final TabController _tabController;   // ✅ Controller se View mein shift

  @override
  void initState() {
    super.initState();

    // ✅ TabController pehle banao (vsync ready hai), phir GetX controller
    _tabController = TabController(length: 4, vsync: this);

    final int? tireId = Get.arguments is int ? Get.arguments as int : null;
    controller = Get.put(TyreViewController(tireId: tireId));
    selectController = Get.put(SelectedAccountController());

    // ✅ Tab index sync — controller ka RxInt update hoga (optional use)
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        controller.currentTabIndex.value = _tabController.index;
      }
    });

    // ❌ _loadPreferences() hata diya — async gap ki wajah se white/blank flash aata tha.
    // ✅ Ab pressure label seedha MeasurementHelper se sync + reactive milega (niche Obx mein).
  }

  @override
  void dispose() {
    _tabController.dispose(); // ✅ Flutter lifecycle — guaranteed safe
    Get.delete<TyreViewController>(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppAppBar(title: t.viewTyre),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoadingIndicator();
        }

        final tyre = controller.tyre.value;
        if (tyre == null) {
          return Center(child: Text(t.noDataAvailable));
        }

        return Column(
          children: [
            _infoCard(tyre, t),
            _tabBar(t),
            Expanded(
              child: TabBarView(
                controller: _tabController, // ✅ controller.tabController nahi
                children: [
                  _identificationTab(tyre, t),
                  _descriptionTab(tyre, t),
                  _treadDepthTab(tyre, t),
                  _costsTab(tyre, t),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  // ─── Info Card ───────────────────────────────────────────────────────────────
  Widget _infoCard(TyreViewModel tyre, AppLocalizations t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.selectedParentAccountLocation,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Obx(() => Text(
            "${selectController.parentAccountName.value} - ${selectController.locationName.value}",
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
          )),
          const Divider(height: 20),
          Text(t.vehicleNumber,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            tyre.vehicleNumber != null && tyre.vehicleNumber!.isNotEmpty
                ? tyre.vehicleNumber!
                : 'N/A',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ─── Tab Bar ─────────────────────────────────────────────────────────────────
  Widget _tabBar(AppLocalizations t) {
    return TabBar(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      tabAlignment: TabAlignment.start,
      controller: _tabController, // ✅ controller.tabController nahi
      isScrollable: true,
      indicator: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(2),
      ),
      labelColor: Colors.white,
      unselectedLabelColor: Colors.black,
      tabs: [
        Tab(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Text(t.identification))),
        Tab(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Text(t.description))),
        Tab(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Text(t.treadDepth))),
        Tab(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Text(t.costs))),
      ],
    );
  }

  // ─── Row Widget ───────────────────────────────────────────────────────────────
  Widget _row(String title, String value, {String? subvalue, AppLocalizations? t}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              if (subvalue != null)
                Text(
                  "$subvalue${t?.percentageWorn ?? "% Worn"}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Tab 1: Identification ────────────────────────────────────────────────────
  Widget _identificationTab(TyreViewModel tyre, AppLocalizations t) {
    String brandNoDisplay = "-";
    if (tyre.brandNo != null) {
      final val = tyre.brandNo.toString().trim();
      if (val.isNotEmpty && val != "0" && val != "null" && val != "0.0") {
        brandNoDisplay = val;
      }
    }

    final mileage = tyre.mileageType?.toString().toLowerCase() ?? "";
    final bool showHours =
        mileage != "2" && mileage != "distance" && mileage != "miles";
    final bool showKm = mileage == "2" ||
        mileage == "distance" ||
        mileage == "miles" ||
        mileage == "3" ||
        mileage == "both";

    final distanceLabel = MeasurementHelper.distanceLabel;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _row(t.tyreSerialNumber,    tyre.tireSerialNo ?? '-'),
        _row(t.brandNumber,         brandNoDisplay),
        _row(t.registerDate,        LocaleHelper.formatApiDate(tyre.registeredDate?.toString())),
        _row(t.evaluationNumber,    tyre.evaluationNo ?? '-'),
        _row(t.purchaseOrderNumber, tyre.poNo ?? '-'),
        _row(t.lotNumber,           tyre.lotNo ?? '-'),
        _row(t.disposition,         controller.getDispositionName(tyre.dispositionId, fallbackName: tyre.dispositionName)),
        _row(t.status,              controller.getTireStatusName(tyre.tireStatusId, fallbackName: tyre.tireStatusName)),
        _row(t.trackingMethod,      controller.getTrackingMethod(tyre.mileageType)),
        _row(t.wheelPosition,       tyre.wheelPosition ?? '-'),
        if (showHours) _row(t.currentHours,                         _fmt(tyre.currentHours)),
        if (showKm)    _row("${t.currentDistance} $distanceLabel",  _fmt(tyre.currentMiles)),
      ],
    );
  }

  // ─── Tab 2: Description ───────────────────────────────────────────────────────
  Widget _descriptionTab(TyreViewModel tyre, AppLocalizations t) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _row(t.manufacturer, controller.getManufacturerName(tyre.manufacturerId ?? 0, fallbackName: tyre.manufacturerName)),
        _row(t.tyreSize,     controller.getMultiTireSizeNames(tyre.sizeId, fallbackName: tyre.sizeName)),
        _row(t.vehicleType,  controller.getTypeName(tyre.typeId ?? 0, fallbackName: tyre.typeName)),
        _row(
          (tyre.starRatingId != null && tyre.starRatingId! > 0)
              ? t.starRating
              : "Ply Rating",
          (tyre.starRatingId != null && tyre.starRatingId! > 0)
              ? ((tyre.starRatingId! >= 1 && tyre.starRatingId! <= 5)
              ? ["**", "***", "****", "*/**", "***/****"][tyre.starRatingId! - 1]
              : (tyre.ratingName ?? "-"))
              : (tyre.plyId != null && tyre.plyId! > 0 && tyre.plyId != 1123
              ? (controller.getPlyRatingName(tyre.plyId).isNotEmpty &&
              controller.getPlyRatingName(tyre.plyId) != "-"
              ? controller.getPlyRatingName(tyre.plyId)
              : (tyre.ratingName ?? "-"))
              : (tyre.ratingName ?? "-")),
        ),
        _row(t.indCode,     controller.getIndCodeName(tyre.indCodeId ?? 0)),
        _row(t.compound,    controller.getCompoundName(tyre.compoundId ?? 0, fallbackName: tyre.compoundName)),
        _row(t.loadRating,  controller.getLoadRatingName(tyre.loadRatingId ?? 0)),
        _row(t.speedRating, controller.getSpeedRatingName(tyre.speedRatingId ?? 0)),
      ],
    );
  }

  // ─── Tab 3: Tread Depth ───────────────────────────────────────────────────────
  Widget _treadDepthTab(TyreViewModel tyre, AppLocalizations t) {
    // ✅ Remove At — location setting se (web portal → Manage Location)
    //    Same jaise noOfTreadDepthReadings SecureStorage se aata hai
    final locationRemoveAt = SecureStorage.getDefaultRemovalTreadDepth();
    final orig   = tyre.originalTread ?? 0;
    final remove = locationRemoveAt > 0 ? locationRemoveAt : (tyre.removeAt ?? 0);

    // ✅ Imperial → /32, Metric → mm  (same as step3_view & create tyre)
    final pref = Get.find<PreferencesController>();
    final unit = pref.selectedMeasurement.value == 'Imperial' ? '/32' : 'mm';

    // ✅ Pressure unit ab sync + reactive — koi white/blank flash nahi, SecureStorage await ka wait nahi
    final pressureUnitLabel = MeasurementHelper.pressureLabel;

    final treadCount = SecureStorage.getNoOfTreadDepthReadings();

    String wornPct(double? tread) {
      if (orig <= remove) return '0';
      final v   = tread ?? 0;
      final pct = ((1 - (v - remove) / (orig - remove)) * 100).round();
      return pct.toString();
    }

    bool isWarn(double? tread) {
      if (orig <= remove) return false;
      final v   = tread ?? 0;
      final pct = ((1 - (v - remove) / (orig - remove)) * 100).round();
      return pct > 100 || pct < 0;
    }

    Widget rowWithWarn(String label, double? tread) {
      final pct  = wornPct(tread);
      final warn = isWarn(tread);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(label, _fmt(tread), subvalue: pct, t: t),
          if (warn)
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 2),
              child: Text(
                "$pct${t.percentageWorn}",
                style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ✅ Unit label sab tread rows mein
        _row("${t.originalTread} ($unit)",  _fmt(tyre.originalTread)),
        _row("${t.removeAt} ($unit)",       _fmt(remove)),
        _row("${t.purchasedTread} ($unit)", _fmt(tyre.purchasedTread)),

        // ✅ CORRECT LOGIC — same as step3_view.dart & web portal:
        //   Outside → always show (1, 2, 3)
        //   Middle  → only when treadCount == 3
        //   Inside  → only when treadCount == 2 or 3
        // ✅ ?? 0.0 — null = user ne kabhi enter nahi kiya → 0 dikhao
        rowWithWarn("${t.outside} ($unit)", tyre.outsideTread ?? 0.0),

        if (treadCount == 3)
          rowWithWarn("Middle Tread ($unit)", tyre.middleTread ?? 0.0),

        if (treadCount == 2 || treadCount == 3)
          rowWithWarn("${t.inside} ($unit)", tyre.insideTread ?? 0.0),

        _row("${t.currentTreadDepth} ($unit)", _fmt(tyre.currentTreadDepth)),
        _row(t.percentageWorn,    "${_fmt(tyre.percentageWorn)}%"),
        _row("${t.recommendedPressure} ($pressureUnitLabel)", _fmt(tyre.recommendedPressure)),
        _row("${t.currentPressure} ($pressureUnitLabel)",     _fmt(tyre.currentPressure)),
      ],
    );
  }

  // ─── Tab 4: Costs ─────────────────────────────────────────────────────────────
  Widget _costsTab(TyreViewModel tyre, AppLocalizations t) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _row(t.purchaseCostA,      _fmt(tyre.purchaseCost)),
        _row(t.casingValueB,       _fmt(tyre.casingValue)),
        _row(t.fillType,           controller.getFillTypeName(tyre.fillTypeId ?? 0)),
        _row(t.fillCost,           _fmt(tyre.fillCost)),
        _row("Number of Repairs",  (tyre.repairCount ?? 0).toString()),
        _row(t.repairCost,         _fmt(tyre.repairCost)),
        _row(t.numberOfRetreads,   (tyre.retreadCount ?? 0).toString()),
        _row(t.retreadCost,        _fmt(tyre.retreadCost)),
        _row(t.warrantyAdjustment, _fmt(tyre.warrantyAdjustment)),
        _row(t.costAdjustment,     _fmt(tyre.costAdjustment)),
        _row(t.soldAmount,         _fmt(tyre.soldAmount)),
        _row(t.netCost,            _fmt(tyre.netCost)),
      ],
    );
  }

  String _fmt(num? v) {
    if (v == null) return '-';
    if (v % 1 == 0) return v.toInt().toString();
    return double.parse(v.toStringAsFixed(2)).toString();
  }
}