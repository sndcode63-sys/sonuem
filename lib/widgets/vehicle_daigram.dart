import 'package:emtrack/controllers/home_controller.dart';
import 'package:emtrack/inspection/vehicle_inspe_controller.dart';
import 'package:emtrack/inspection/vehicle_inspe_model.dart';
import 'package:emtrack/services/role_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:emtrack/views/inspect_tyre_view.dart';
import 'package:emtrack/views/search_install_view.dart';
import '../controllers/inspect_tyre_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/local_helper.dart';
import '../utils/mesurment_helper_class.dart';
import '../utils/pending_inspection_guard.dart';
import '../utils/tyre_unit_history.dart';

const _kShaftColor = Color(0xFF4A4A5A);
const _kShaftW = 8.0;
const _kAxleCircleD = 44.0;
const _kAxleLineMaxW = 90.0;
const _kAxleGap = 6.0;
const _kSegH = 52.0;

const _kTyreW = 88.0;
const _kTyreH = 170.0;
const _kTyreR = 16.0;
const _kBorderW = 4.5;

const _kDualW = 68.0;
const _kDualH = 130.0;
const _kDualR = 12.0;
const _kDualBW = 3.5;


//  Helpers
Color _wornColor(int pct) {
  if (pct >= 75) return const Color(0xFFEF4444);
  if (pct >= 50) return const Color(0xFFF97316);
  if (pct >= 25) return const Color(0xFFEAB308);
  return const Color(0xFF22C55E);
}



double _canonicalPressure(double v) =>
    MeasurementHelper.toDisplayPressure(v, sourceUnit: 'PSI');

String _canonicalTread(dynamic val) {
  if (val == null) return '';
  final d = double.tryParse(val.toString());
  if (d == null) return val.toString();
  return _fmt(MeasurementHelper.toDisplayTread(d, sourceUnit: 'Metric'));
}

/// Approval (pending) me distance canonical KM hoti hai (200 Miles -> 322 KM).
/// Ise user ki current preference (KM/Miles) me convert karke dikhao.
String _canonicalDistance(dynamic val, {dynamic tireId}) {
  if (val == null) return '';
  final d = double.tryParse(val.toString());
  if (d == null) return val.toString();
  final rawMiles = tireId != null ? TyreUnitHistory.getRawMiles(tireId) : null;
  final savedUnit = tireId != null ? TyreUnitHistory.getDistanceUnit(tireId) : null;
  final base = (rawMiles != null && rawMiles > 0) ? rawMiles : d;
  final String effUnit = (savedUnit != null && savedUnit.isNotEmpty)
      ? savedUnit
      : (MeasurementHelper.isImperial ? 'Imperial' : 'Metric');
  return _fmt(MeasurementHelper.toDisplayDistance(base, sourceUnit: effUnit));
}

double _convertPressure(double value, dynamic tireId) {
  final savedUnit = tireId != null ? TyreUnitHistory.getPressureUnit(tireId) : null;
  final String sourceUnit = (savedUnit != null && savedUnit.isNotEmpty) ? savedUnit : 'PSI';
  return MeasurementHelper.toDisplayPressure(value, sourceUnit: sourceUnit);
}

double? _rawBasedPressure(InstalledTire tire) {
  final id = tire.tireId;
  final sn = tire.tireSerialNo;
  final bool hasSn = sn != null && sn.isNotEmpty;
  final double? raw = (id != null ? TyreUnitHistory.getRawPressure(id) : null) ??
      (hasSn ? TyreUnitHistory.getRawPressure(sn) : null);
  if (raw == null || raw <= 0) return null;
  final String unit = (id != null ? TyreUnitHistory.getPressureUnit(id) : null) ??
      (hasSn ? TyreUnitHistory.getPressureUnit(sn) : null) ??
      'PSI';
  return MeasurementHelper.toDisplayPressure(raw, sourceUnit: unit);
}


String _fmt(dynamic val, {String? unitType}) {
  if (val == null) return '';
  final d = double.tryParse(val.toString());
  if (d == null) return val.toString();
  return d.round().toString();
}


String _fmtDistance(dynamic val, {dynamic tireId, String? tireMileageType}) {
  if (val == null) return '';
  final d = double.tryParse(val.toString());
  if (d == null) return val.toString();

  final double? rawMiles = tireId != null ? TyreUnitHistory.getRawMiles(tireId) : null;
  final double baseDistance = (rawMiles != null && rawMiles > 0) ? rawMiles : d;

  String? savedUnit = tireId != null ? TyreUnitHistory.getDistanceUnit(tireId) : null;
  if (savedUnit == null && tireMileageType != null && tireMileageType.isNotEmpty) {
    final tmt = tireMileageType.toLowerCase().trim();
    if (tmt == 'miles' || tmt == 'imperial') {
      savedUnit = 'Imperial';
    } else if (tmt == 'km' || tmt == 'kilometers' || tmt == 'metric') {
      savedUnit = 'Metric';
    }
  }
  final String effUnit = (savedUnit != null && savedUnit.isNotEmpty)
      ? savedUnit
      : (MeasurementHelper.isImperial ? 'Imperial' : 'Metric');
  final display = MeasurementHelper.toDisplayDistance(
    baseDistance,
    sourceUnit: effUnit,
  );
  return _fmt(display);
}


String _fmtTread(dynamic val, {String? mileageType, dynamic tireId, String? serialNo, String? treadType}) {
  if (val == null) return '';
  final d = double.tryParse(val.toString());
  if (d == null) return val.toString();

  // If raw readings are cached locally for this tyre, convert from their recorded unit to active unit
  if (tireId != null || (serialNo != null && serialNo.isNotEmpty)) {
    double? raw;
    if (treadType == 'outside') {
      raw = (tireId != null ? TyreUnitHistory.getRawOutside(tireId) : null) ??
          (serialNo != null ? TyreUnitHistory.getRawOutside(serialNo) : null);
    } else if (treadType == 'middle') {
      raw = (tireId != null ? TyreUnitHistory.getRawMiddle(tireId) : null) ??
          (serialNo != null ? TyreUnitHistory.getRawMiddle(serialNo) : null);
    } else if (treadType == 'inside') {
      raw = (tireId != null ? TyreUnitHistory.getRawInside(tireId) : null) ??
          (serialNo != null ? TyreUnitHistory.getRawInside(serialNo) : null);
    }
    if (raw != null && raw > 0) {
      final savedUnit = (tireId != null ? TyreUnitHistory.getTreadUnit(tireId) : null) ??
          (serialNo != null ? TyreUnitHistory.getTreadUnit(serialNo) : null) ??
          mileageType;
      final converted = MeasurementHelper.toDisplayTread(raw, sourceUnit: savedUnit);
      return _fmt(converted);
    }
  }

  // If savedUnit matches active unit (or neither is cross-converted), display as-is
  final bool isMetric = MeasurementHelper.isMetric;
  final bool wasSavedMetric = mileageType?.toLowerCase() == 'metric' || mileageType?.toLowerCase() == 'km';
  final bool wasSavedImperial = mileageType?.toLowerCase() == 'imperial' || mileageType == '/32nds' || mileageType?.toLowerCase() == 'miles';
  if ((isMetric && wasSavedMetric) || (!isMetric && wasSavedImperial)) {
    return _fmt(d);
  }

  final displayValue = MeasurementHelper.toDisplayTread(
    d,
    sourceUnit: mileageType,
  );
  return _fmt(displayValue);
}

//  VehicleDiagram
class VehicleDiagram extends StatefulWidget {
  final RxList<InstalledTire> tires;
  final int vehicleId;
  final String vehicleNumber;
  final String axleConfig;
  final bool isEditMode;

  /// true = pressure/tread canonical (PSI/mm) hain -> preference me convert.
  final bool canonicalPressureTread;
  final bool pressureAsIs;
  final void Function(InstalledTire)? onTireTap; // 🔥 Added named parameter

  const VehicleDiagram({
    super.key,
    required this.tires,
    required this.vehicleId,
    required this.vehicleNumber,
    this.axleConfig = '22',
    this.isEditMode = false,
    this.canonicalPressureTread = false,
    this.pressureAsIs = false,
    this.onTireTap, // 🔥 Added here
  });

  @override
  State<VehicleDiagram> createState() => _VehicleDiagramState();
}

class _VehicleDiagramState extends State<VehicleDiagram> {
  String? _userRole;
  int _noOfTreadDepthReadings = 3;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _noOfTreadDepthReadings = SecureStorage.getNoOfTreadDepthReadings();
  }

  Future<void> _loadUserRole() async {
    final role = await SecureStorage.getUserProfileRole();
    if (mounted) setState(() => _userRole = role ?? '');
  }

  bool get _canInstall {
    if (_userRole == null) return true;
    if (_userRole!.isEmpty) return true;
    return _userRole != RoleService.emtVo;
  }

  bool get _canInspect {
    if (_userRole == null) return true;
    if (_userRole!.isEmpty) return true;
    return _userRole != RoleService.emtVo;
  }

  List<int> get _axleDigits {
    final safe = widget.axleConfig.trim().isNotEmpty ? widget.axleConfig : '22';
    return safe
        .split('')
        .where((c) => RegExp(r'[0-9]').hasMatch(c))
        .map((c) => int.tryParse(c) ?? 2)
        .toList();
  }

  Future<void> _goInspect(InstalledTire tire) async {
    if (widget.onTireTap != null) {
      widget.onTireTap!(tire);
      return;
    }
    // 🔒 Vehicle ka pichla inspection approval ke liye pending hai to
    // tyre inspect nahi hoga (approval screen apna onTireTap use karti hai,
    // isliye wo upar hi return ho chuki hai — approver block nahi hota).
    final allowed = await PendingInspectionGuard.canProceed(
      vehicleId: widget.vehicleId,
      vehicleNumber: widget.vehicleNumber,
      action: PendingBlockedAction.tyreInspection,
    );
    if (!allowed) return;

    if (Get.isRegistered<InspectTyreController>()) {
      Get.delete<InspectTyreController>(force: true);
    }
    final result = await Get.to(() => InspectTyreView(tire: tire), arguments: tire);
    if (Get.isRegistered<VehicleInspeController>()) {
      Get.find<VehicleInspeController>().tires.refresh();
      Get.find<VehicleInspeController>().loadInspectedTyreImages();
    }
    if (result == true) {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().refreshCounts();
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<InspectTyreController>()) {
        Get.delete<InspectTyreController>(force: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tires = widget.tires.toList();
      final digits = _axleDigits;
      final axleCount = digits.length.clamp(1, 10);

      InstalledTire? find(String pos) =>
          tires.firstWhereOrNull((t) => t.wheelPosition == pos);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _LRHeader(),
          const SizedBox(height: 8),
          for (int i = 0; i < axleCount; i++) ...[
            _buildRow(
              axleNo: i + 1,
              tireCount: digits[i],
              find: find,
              noOfTreadDepthReadings: _noOfTreadDepthReadings,
            ),
            if (i < axleCount - 1) const _ShaftSegment(),
          ],
          const SizedBox(height: 16),
          const _WornLegend(),
        ],
      );
    });
  }

  Widget _buildRow({
    required int axleNo,
    required int tireCount,
    required InstalledTire? Function(String) find,
    required int noOfTreadDepthReadings,
  }) {
    if (tireCount == 4) {
      return _DualAxleRow(
        axleNo: axleNo,
        find: find,
        canInstall: _canInstall,
        canInspect: _canInspect,
        userRole: _userRole,
        vehicleId: widget.vehicleId,
        vehicleNumber: widget.vehicleNumber,
        onInspect: _goInspect,
        isEditMode: widget.isEditMode,
        noOfTreadDepthReadings: noOfTreadDepthReadings,
        canonicalPressureTread: widget.canonicalPressureTread,
        pressureAsIs: widget.pressureAsIs,
      );
    }
    return _SingleAxleRow(
      axleNo: axleNo,
      find: find,
      canInstall: _canInstall,
      canInspect: _canInspect,
      userRole: _userRole,
      vehicleId: widget.vehicleId,
      vehicleNumber: widget.vehicleNumber,
      onInspect: _goInspect,
      isEditMode: widget.isEditMode,
      noOfTreadDepthReadings: noOfTreadDepthReadings,
      canonicalPressureTread: widget.canonicalPressureTread,
      pressureAsIs: widget.pressureAsIs,
    );
  }
}

//  L / R header

class _LRHeader extends StatelessWidget {
  const _LRHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: Colors.black,
      letterSpacing: 1,
    );
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('L', style: style),
          Text('R', style: style),
        ],
      ),
    );
  }
}

//  Vertical shaft segment

class _ShaftSegment extends StatelessWidget {
  const _ShaftSegment();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: _kShaftW,
        height: _kSegH,
        decoration: BoxDecoration(
          color: _kShaftColor,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

//  Worn % legend
class _WornLegend extends StatelessWidget {
  const _WornLegend();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Color(0xFF22C55E), '< 25%'),
      (Color(0xFFEAB308), '25–50%'),
      (Color(0xFFF97316), '50–75%'),
      (Color(0xFFEF4444), '> 75%'),
    ];
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: items
          .map(
            (e) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: e.$1,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              e.$2,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      )
          .toList(),
    );
  }
}

//  Axle circle
class _AxleCircle extends StatelessWidget {
  final int axleNo;
  const _AxleCircle(this.axleNo);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kAxleCircleD,
      height: _kAxleCircleD,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _kShaftColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$axleNo',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

//  Horizontal axle bar
class _AxleBar extends StatelessWidget {
  const _AxleBar();

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        constraints: const BoxConstraints(maxWidth: _kAxleLineMaxW),
        height: _kShaftW,
        decoration: BoxDecoration(
          color: _kShaftColor,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}


//  SINGLE AXLE ROW
class _SingleAxleRow extends StatelessWidget {
  final int axleNo;
  final InstalledTire? Function(String) find;
  final bool canInstall, canInspect;
  final String? userRole;
  final int vehicleId;
  final String vehicleNumber;
  final Future<void> Function(InstalledTire) onInspect;
  final bool isEditMode;
  final int noOfTreadDepthReadings;
  final bool canonicalPressureTread;
  final bool pressureAsIs;

  const _SingleAxleRow({
    required this.axleNo,
    required this.find,
    required this.canInstall,
    required this.canInspect,
    required this.userRole,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.onInspect,
    this.isEditMode = false,
    this.noOfTreadDepthReadings = 3,
    this.canonicalPressureTread = false,
    this.pressureAsIs = false,
  });

  @override
  Widget build(BuildContext context) {
    final L = find('${axleNo}L');
    final R = find('${axleNo}R');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          L != null
              ? _FilledTyre(
            tire: L,
            canInspect: canInspect,
            userRole: userRole,
            onTap: () => onInspect(L),
            noOfTreadDepthReadings: noOfTreadDepthReadings,
            isEditMode: isEditMode,
            canonicalPressureTread: canonicalPressureTread,
            pressureAsIs: pressureAsIs,
          )
              : _EmptyTyre(
            position: '${axleNo}L',
            canInstall: canInstall,
            userRole: userRole,
            vehicleId: vehicleId,
            vehicleNumber: vehicleNumber,
            isEditMode: isEditMode,
          ),
          const SizedBox(width: _kAxleGap),
          const _AxleBar(),
          _AxleCircle(axleNo),
          const _AxleBar(),
          const SizedBox(width: _kAxleGap),
          R != null
              ? _FilledTyre(
            tire: R,
            canInspect: canInspect,
            userRole: userRole,
            onTap: () => onInspect(R),
            noOfTreadDepthReadings: noOfTreadDepthReadings,
            isEditMode: isEditMode,
            canonicalPressureTread: canonicalPressureTread,
            pressureAsIs: pressureAsIs,
          )
              : _EmptyTyre(
            position: '${axleNo}R',
            canInstall: canInstall,
            userRole: userRole,
            vehicleId: vehicleId,
            vehicleNumber: vehicleNumber,
            isEditMode: isEditMode,
          ),
        ],
      ),
    );
  }
}


//  DUAL AXLE ROW

class _DualAxleRow extends StatelessWidget {
  final int axleNo;
  final InstalledTire? Function(String) find;
  final bool canInstall, canInspect;
  final String? userRole;
  final int vehicleId;
  final String vehicleNumber;
  final Future<void> Function(InstalledTire) onInspect;
  final bool isEditMode;
  final int noOfTreadDepthReadings;
  final bool canonicalPressureTread;
  final bool pressureAsIs;

  const _DualAxleRow({
    required this.axleNo,
    required this.find,
    required this.canInstall,
    required this.canInspect,
    required this.userRole,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.onInspect,
    this.isEditMode = false,
    this.noOfTreadDepthReadings = 3,
    this.canonicalPressureTread = false,
    this.pressureAsIs = false,
  });

  @override
  Widget build(BuildContext context) {
    final LO = find('${axleNo}LO');
    final LI = find('${axleNo}LI');
    final RI = find('${axleNo}RI');
    final RO = find('${axleNo}RO');

    Widget dualSlot(String pos, InstalledTire? t) => t != null
        ? _FilledTyreDual(
      tire: t,
      canInspect: canInspect,
      userRole: userRole,
      onTap: () => onInspect(t),
      noOfTreadDepthReadings: noOfTreadDepthReadings,
      isEditMode: isEditMode,
      canonicalPressureTread: canonicalPressureTread,
      pressureAsIs: pressureAsIs,
    )
        : _EmptyTyreDual(
      position: pos,
      canInstall: canInstall,
      userRole: userRole,
      vehicleId: vehicleId,
      vehicleNumber: vehicleNumber,
      isEditMode: isEditMode,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              dualSlot('${axleNo}LO', LO),
              const SizedBox(width: 3),
              dualSlot('${axleNo}LI', LI),
            ],
          ),
          const SizedBox(width: _kAxleGap),
          const _AxleBar(),
          _AxleCircle(axleNo),
          const _AxleBar(),
          const SizedBox(width: _kAxleGap),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              dualSlot('${axleNo}RI', RI),
              const SizedBox(width: 3),
              dualSlot('${axleNo}RO', RO),
            ],
          ),
        ],
      ),
    );
  }
}

//  FILLED TYRE — single

class _FilledTyre extends StatelessWidget {
  final InstalledTire tire;
  final bool canInspect;
  final String? userRole;
  final VoidCallback onTap;
  final int noOfTreadDepthReadings;
  final bool isEditMode;
  final bool canonicalPressureTread;
  final bool pressureAsIs;

  const _FilledTyre({
    required this.tire,
    required this.canInspect,
    required this.userRole,
    required this.onTap,
    this.noOfTreadDepthReadings = 3,
    this.isEditMode = false,
    this.canonicalPressureTread = false,
    this.pressureAsIs = false,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      int pct = 0;
      final treadSrc = (tire.tireId != null ? TyreUnitHistory.getTreadUnit(tire.tireId) : null) ??
          (tire.tireSerialNo != null ? TyreUnitHistory.getTreadUnit(tire.tireSerialNo!) : null);
      final double rawOrig = tire.originalTread ?? 0.0;
      final double rawRem = tire.removeAt ?? 0.0;
      final double curr = tire.middleTread ?? tire.currentTreadDepth ?? tire.outsideTread ?? 0.0;
      final double orig = MeasurementHelper.toDisplayTread(rawOrig, sourceUnit: treadSrc);
      final double rem = MeasurementHelper.toDisplayTread(rawRem, sourceUnit: treadSrc);

      if (orig > 0 && curr > 0) {
        if (curr >= orig) {
          pct = 0;
        } else {
          final double denom = (orig - rem) > 0 ? (orig - rem) : orig;
          final double effRem = (orig - rem) > 0 ? rem : 0.0;
          pct = ((1 - (curr - effRem) / denom) * 100).round().clamp(0, 100);
        }
      } else if (tire.percentageWorn != null && tire.percentageWorn! >= 0) {
        pct = tire.percentageWorn!.round().clamp(0, 100);
      } else if (tire.tireId != null && TyreUnitHistory.getPercentageWorn(tire.tireId) != null && TyreUnitHistory.getPercentageWorn(tire.tireId)! >= 0) {
        pct = TyreUnitHistory.getPercentageWorn(tire.tireId)!.round().clamp(0, 100);
      } else if (tire.tireSerialNo != null && TyreUnitHistory.getPercentageWorn(tire.tireSerialNo!) != null && TyreUnitHistory.getPercentageWorn(tire.tireSerialNo!)! >= 0) {
        pct = TyreUnitHistory.getPercentageWorn(tire.tireSerialNo!)!.round().clamp(0, 100);
      }
      final bc = _wornColor(pct);
      final locked = userRole != null && !canInspect;
      final distLabel = MeasurementHelper.distanceLabel;

      final String activeUnit = MeasurementHelper.pressureLabel;

      final bool canonical = canonicalPressureTread;
      double convertedPressure = canonical
          ? _canonicalPressure(tire.currentPressure ?? 0.0)
          : (pressureAsIs
              ? (tire.currentPressure ?? 0.0)
              : (_rawBasedPressure(tire) ??
                  _convertPressure(
                    tire.currentPressure ?? 0.0,
                    tire.tireId,
                  )));

      final showOutside = true;
      final showMiddle = noOfTreadDepthReadings == 3;
      final showInside =
          noOfTreadDepthReadings == 2 || noOfTreadDepthReadings == 3;

      return GestureDetector(
        onTap: canInspect ? onTap : null,
        child: SizedBox(
          width: _kTyreW,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _SerialBadge(
                serialNo: tire.tireSerialNo ?? '',
                brandNo: tire.brandNo,
                maxWidth: _kTyreW,
                fontSize: 10,
              ),
              const SizedBox(height: 6),
              Container(
                width: _kTyreW,
                height: _kTyreH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_kTyreR),
                  border: Border.all(color: bc, width: _kBorderW),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_kTyreR - _kBorderW),
                  child: Stack(
                    children: [
                      Container(
                        color: const Color(0xFF1A1A2E),
                        child: CustomPaint(
                          painter: _TyreTexture(),
                          size: const Size(_kTyreW, _kTyreH),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _PctChip(pct: pct, color: bc, fontSize: 12),
                              const SizedBox(height: 8),
                              _DataRow(
                                label: 'P',
                                value: _fmt(
                                  convertedPressure,
                                  unitType: activeUnit,
                                ),
                                fontSize: 11,
                              ),
                              const SizedBox(height: 4),
                              if (showOutside)
                                _DataRow(
                                  label: 'To',
                                  value: canonical
                                      ? _canonicalTread(tire.outsideTread)
                                      : _fmtTread(
                                    tire.outsideTread,
                                    mileageType: TyreUnitHistory.getTreadUnit(tire.tireId),
                                    tireId: tire.tireId,
                                    serialNo: tire.tireSerialNo,
                                    treadType: 'outside',
                                  ),
                                  fontSize: 11,
                                ),
                              if (showMiddle)
                                _DataRow(
                                  label: 'Tm',
                                  value: canonical
                                      ? _canonicalTread(tire.middleTread)
                                      : _fmtTread(
                                    tire.middleTread,
                                    mileageType: TyreUnitHistory.getTreadUnit(tire.tireId),
                                    tireId: tire.tireId,
                                    serialNo: tire.tireSerialNo,
                                    treadType: 'middle',
                                  ),
                                  fontSize: 11,
                                ),
                              if (showInside) ...[
                                const SizedBox(height: 4),
                                _DataRow(
                                  label: 'Ti',
                                  value: canonical
                                      ? _canonicalTread(tire.insideTread)
                                      : _fmtTread(
                                    tire.insideTread,
                                    mileageType: TyreUnitHistory.getTreadUnit(tire.tireId),
                                    tireId: tire.tireId,
                                    serialNo: tire.tireSerialNo,
                                    treadType: 'inside',
                                  ),
                                  fontSize: 11,
                                ),
                              ],
                              if (locked) ...[
                                const SizedBox(height: 8),
                                const Icon(
                                  Icons.lock,
                                  size: 13,
                                  color: Colors.white54,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${canonicalPressureTread ? _canonicalDistance(tire.currentMiles, tireId: tire.tireId) : _fmtDistance(tire.currentMiles, tireId: tire.tireId, tireMileageType: tire.mileageType)} $distLabel\n${_fmt(tire.currentHours)} hrs',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

//  FILLED TYRE — dual

class _FilledTyreDual extends StatelessWidget {
  final InstalledTire tire;
  final bool canInspect;
  final String? userRole;
  final VoidCallback onTap;
  final int noOfTreadDepthReadings;
  final bool isEditMode;
  final bool canonicalPressureTread;
  final bool pressureAsIs;

  const _FilledTyreDual({
    required this.tire,
    required this.canInspect,
    required this.userRole,
    required this.onTap,
    this.noOfTreadDepthReadings = 3,
    this.isEditMode = false,
    this.canonicalPressureTread = false,
    this.pressureAsIs = false,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      int pct = 0;
      final treadSrc = (tire.tireId != null ? TyreUnitHistory.getTreadUnit(tire.tireId) : null) ??
          (tire.tireSerialNo != null ? TyreUnitHistory.getTreadUnit(tire.tireSerialNo!) : null);
      final double rawOrig = tire.originalTread ?? 0.0;
      final double rawRem = tire.removeAt ?? 0.0;
      final double curr = tire.middleTread ?? tire.currentTreadDepth ?? tire.outsideTread ?? 0.0;
      final double orig = MeasurementHelper.toDisplayTread(rawOrig, sourceUnit: treadSrc);
      final double rem = MeasurementHelper.toDisplayTread(rawRem, sourceUnit: treadSrc);

      if (orig > 0 && curr > 0) {
        if (curr >= orig) {
          pct = 0;
        } else {
          final double denom = (orig - rem) > 0 ? (orig - rem) : orig;
          final double effRem = (orig - rem) > 0 ? rem : 0.0;
          pct = ((1 - (curr - effRem) / denom) * 100).round().clamp(0, 100);
        }
      } else if (tire.percentageWorn != null && tire.percentageWorn! >= 0) {
        pct = tire.percentageWorn!.round().clamp(0, 100);
      } else if (tire.tireId != null && TyreUnitHistory.getPercentageWorn(tire.tireId) != null && TyreUnitHistory.getPercentageWorn(tire.tireId)! >= 0) {
        pct = TyreUnitHistory.getPercentageWorn(tire.tireId)!.round().clamp(0, 100);
      } else if (tire.tireSerialNo != null && TyreUnitHistory.getPercentageWorn(tire.tireSerialNo!) != null && TyreUnitHistory.getPercentageWorn(tire.tireSerialNo!)! >= 0) {
        pct = TyreUnitHistory.getPercentageWorn(tire.tireSerialNo!)!.round().clamp(0, 100);
      }
      final bc = _wornColor(pct);
      final locked = userRole != null && !canInspect;
      final label = MeasurementHelper.distanceLabel;

      final String activeUnit = MeasurementHelper.pressureLabel;

      final bool canonical = canonicalPressureTread;
      double convertedPressure = canonical
          ? _canonicalPressure(tire.currentPressure ?? 0.0)
          : (pressureAsIs
              ? (tire.currentPressure ?? 0.0)
              : (_rawBasedPressure(tire) ??
                  _convertPressure(
                    tire.currentPressure ?? 0.0,
                    tire.tireId,
                  )));

      final showOutside =
          noOfTreadDepthReadings == 2 || noOfTreadDepthReadings == 3;
      final showMiddle =
          noOfTreadDepthReadings == 1 || noOfTreadDepthReadings == 3;
      final showInside =
          noOfTreadDepthReadings == 2 || noOfTreadDepthReadings == 3;

      return GestureDetector(
        onTap: canInspect ? onTap : null,
        child: SizedBox(
          width: _kDualW,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _SerialBadge(
                serialNo: tire.tireSerialNo ?? '',
                brandNo: tire.brandNo,
                maxWidth: _kDualW,
                fontSize: 8,
              ),
              const SizedBox(height: 4),
              Container(
                width: _kDualW,
                height: _kDualH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_kDualR),
                  border: Border.all(color: bc, width: _kDualBW),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_kDualR - _kDualBW),
                  child: Stack(
                    children: [
                      Container(
                        color: const Color(0xFF1A1A2E),
                        child: CustomPaint(
                          painter: _TyreTexture(),
                          size: const Size(_kDualW, _kDualH),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _PctChip(pct: pct, color: bc, fontSize: 9),
                              const SizedBox(height: 5),
                              _DataRow(
                                label: 'P',
                                value: _fmt(
                                  convertedPressure,
                                  unitType: activeUnit,
                                ),
                                fontSize: 9,
                              ),
                              if (showOutside) ...[
                                const SizedBox(height: 3),
                                _DataRow(
                                  label: 'To',
                                  value: canonical
                                      ? _canonicalTread(tire.outsideTread)
                                      : _fmtTread(
                                    tire.outsideTread,
                                    mileageType: TyreUnitHistory.getTreadUnit(tire.tireId),
                                    tireId: tire.tireId,
                                    serialNo: tire.tireSerialNo,
                                    treadType: 'outside',
                                  ),
                                  fontSize: 9,
                                ),
                              ],
                              if (showMiddle) ...[
                                const SizedBox(height: 3),
                                _DataRow(
                                  label: 'Tm',
                                  value: canonical
                                      ? _canonicalTread(tire.middleTread)
                                      : _fmtTread(
                                    tire.middleTread,
                                    mileageType: TyreUnitHistory.getTreadUnit(tire.tireId),
                                    tireId: tire.tireId,
                                    serialNo: tire.tireSerialNo,
                                    treadType: 'middle',
                                  ),
                                  fontSize: 9,
                                ),
                              ],
                              if (showInside) ...[
                                const SizedBox(height: 3),
                                _DataRow(
                                  label: 'Ti',
                                  value: canonical
                                      ? _canonicalTread(tire.insideTread)
                                      : _fmtTread(
                                    tire.insideTread,
                                    mileageType: TyreUnitHistory.getTreadUnit(tire.tireId),
                                    tireId: tire.tireId,
                                    serialNo: tire.tireSerialNo,
                                    treadType: 'inside',
                                  ),
                                  fontSize: 9,
                                ),
                              ],
                              if (locked) ...[
                                const SizedBox(height: 4),
                                const Icon(
                                  Icons.lock,
                                  size: 10,
                                  color: Colors.white54,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${canonicalPressureTread ? _canonicalDistance(tire.currentMiles, tireId: tire.tireId) : _fmtDistance(tire.currentMiles, tireId: tire.tireId, tireMileageType: tire.mileageType)} $label\n${_fmt(tire.currentHours)} hrs',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8.5,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

//  EMPTY TYRE
class _EmptyTyre extends StatelessWidget {
  final String position;
  final bool canInstall;
  final String? userRole;
  final int vehicleId;
  final String vehicleNumber;
  final bool isEditMode;

  const _EmptyTyre({
    required this.position,
    required this.canInstall,
    required this.userRole,
    required this.vehicleId,
    required this.vehicleNumber,
    this.isEditMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final locked = userRole != null && !canInstall;
    final accentColor = isEditMode
        ? Colors.grey.shade400
        : (canInstall ? Colors.black.withValues(alpha: 0.55) : Colors.grey.shade300);

    return GestureDetector(
      onTap: (!isEditMode && canInstall)
          ? () async {
        final allowed = await PendingInspectionGuard.canProceed(
          vehicleId: vehicleId,
          vehicleNumber: vehicleNumber,
          action: PendingBlockedAction.installTyre,
        );
        if (!allowed) return;
        Get.to(
              () => SearchInstallView(),
          arguments: {
            'vehicleNumber': vehicleNumber,
            'vehicleId': vehicleId,
            'wheelPosition': position,
            'isInspectionFlow': true,
          },
        );
      }
          : null,
      child: SizedBox(
        width: _kTyreW,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 32,
              child: Center(
                child: Text(
                  position,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: _kTyreW,
              height: _kTyreH,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_kTyreR),
                border: Border.all(color: accentColor, width: 1.8),
                color: isEditMode ? Colors.grey.shade100 : Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          isEditMode
                              ? Icons.do_not_disturb_alt_outlined
                              : (locked
                              ? Icons.lock_outline
                              : Icons.add_circle_outline),
                          size: 28,
                          color: accentColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isEditMode
                              ? 'No ${LocaleHelper.tyreName(context)}\nInstalled'
                              : (locked ? 'Locked' : ''),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '— mi\n— h',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.transparent,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTyreDual extends StatelessWidget {
  final String position;
  final bool canInstall;
  final String? userRole;
  final int vehicleId;
  final String vehicleNumber;
  final bool isEditMode;

  const _EmptyTyreDual({
    required this.position,
    required this.canInstall,
    required this.userRole,
    required this.vehicleId,
    required this.vehicleNumber,
    this.isEditMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final locked = userRole != null && !canInstall;
    final accentColor = isEditMode
        ? Colors.grey.shade400
        : Colors.black.withValues(alpha: 0.55);

    return GestureDetector(
      onTap: (!isEditMode && canInstall)
          ? () async {
        final allowed = await PendingInspectionGuard.canProceed(
          vehicleId: vehicleId,
          vehicleNumber: vehicleNumber,
          action: PendingBlockedAction.installTyre,
        );
        if (!allowed) return;
        Get.to(
              () => SearchInstallView(),
          arguments: {
            'vehicleNumber': vehicleNumber,
            'vehicleId': vehicleId,
            'wheelPosition': position,
            'isInspectionFlow': true,
          },
        );
      }
          : null,
      child: SizedBox(
        width: _kDualW,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 28,
              child: Center(
                child: Text(
                  position,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: _kDualW,
              height: _kDualH,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_kDualR),
                border: Border.all(color: accentColor, width: 1.5),
                color: isEditMode
                    ? Colors.grey.shade100
                    : accentColor.withValues(alpha: 0.05),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          isEditMode
                              ? Icons.do_not_disturb_alt_outlined
                              : (locked
                              ? Icons.lock_outline
                              : Icons.add_circle_outline),
                          size: 20,
                          color: accentColor,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isEditMode
                              ? 'No ${LocaleHelper.tyreName(context)}\nInstalled'
                              : (locked ? 'Locked' : ''),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '— mi\n— h',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 8.5,
                color: Colors.transparent,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SerialBadge extends StatelessWidget {
  final String serialNo;
  final String? brandNo;
  final double maxWidth;
  final double fontSize;
  const _SerialBadge({
    required this.serialNo,
    this.brandNo,
    required this.maxWidth,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final snText = serialNo.trim().isNotEmpty ? serialNo.trim() : '-';
    final snDisplay = snText.toUpperCase().startsWith('SN:') ||
            snText.toUpperCase().startsWith('SN :')
        ? snText
        : 'SN: $snText';

    final hasBrand = brandNo != null &&
        brandNo!.trim().isNotEmpty &&
        brandNo!.trim().toLowerCase() != 'null';
    final bnRaw = hasBrand ? brandNo!.trim() : '-';
    final bnDisplay = bnRaw.toUpperCase().startsWith('BN:') ||
            bnRaw.toUpperCase().startsWith('BN :')
        ? bnRaw
        : 'BN: $bnRaw';

    return Container(
      width: maxWidth,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            snDisplay,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            bnDisplay,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _PctChip extends StatelessWidget {
  final int pct;
  final Color color;
  final double fontSize;
  const _PctChip({
    required this.pct,
    required this.color,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize < 10 ? 6 : 10,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$pct%',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

//  DATA ROW WITHOUT UNIT TEXT
class _DataRow extends StatelessWidget {
  final String label, value;
  final double fontSize;

  const _DataRow({
    required this.label,
    required this.value,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),

        Flexible(
          child: Text(
            value,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _TyreTexture extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const step = 10.0;
    for (double d = -size.height; d < size.width + size.height; d += step) {
      canvas.drawLine(
        Offset(d, 0),
        Offset(d + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}