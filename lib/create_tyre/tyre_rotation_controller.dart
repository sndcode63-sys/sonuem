import 'package:emtrack/inspection/vehicle_inspe_controller.dart';
import 'package:emtrack/inspection/vehicle_inspe_model.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/utils/mesurment_helper_class.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/tyre_data.dart';

class TyreRotationController {
  static final TyreRotationController instance = TyreRotationController._();
  TyreRotationController._();

  TyreData? bufferTyre;
  int? bufferIndex;
  List<TyreData?> tyres = [];

  List<InstalledTire?> _originalTires = [];
  InstalledTire? _bufferOriginalTire;
  String _axleConfig = '';


  Set<int> _pendingInstallTireIds = {};

  /// Notifies any listener (tyre grid, buffer box, etc.) whenever the
  /// tyre/buffer state changes, so all UI pieces stay in sync regardless
  /// of which widget triggered the change.
  final ValueNotifier<int> refreshNotifier = ValueNotifier<int>(0);
  void _notify() => refreshNotifier.value++;

  void loadFromInspection() {
    tyres.clear();
    _originalTires.clear();
    bufferTyre = null;
    bufferIndex = null;
    _bufferOriginalTire = null;
    _pendingInstallTireIds = {};

    if (!Get.isRegistered<VehicleInspeController>()) {
      return;
    }

    final inspeController = Get.find<VehicleInspeController>();
    final tireList = inspeController.tires;


    try {
      final rawVehicleId = inspeController.vehicleId.value;
      final vId = int.tryParse(rawVehicleId) ?? 0;
      if (vId != 0) {
        _pendingInstallTireIds = OfflineHiveService.getPendingInstallTireIds(vId);
      }
    } catch (e) {
      _pendingInstallTireIds = {};
    }

    if (tireList.isEmpty) {
      return;
    }

    _axleConfig = inspeController.model?.axleConfig ?? '';

    int totalSlots = 0;
    for (int i = 0; i < _axleConfig.length; i++) {
      totalSlots += int.tryParse(_axleConfig[i]) ?? 0;
    }

    if (totalSlots == 0) totalSlots = tireList.length;
    if (totalSlots < tireList.length) totalSlots = tireList.length;

    tyres         = List<TyreData?>.filled(totalSlots, null, growable: true);
    _originalTires = List<InstalledTire?>.filled(totalSlots, null, growable: true);

    bool anyMapped = false;
    for (var tire in tireList) {
      final pos = tire.wheelPosition ?? '';
      final idx = _positionToIndex(pos, _axleConfig);
      if (idx >= 0 && idx < totalSlots) {
        tyres[idx]          = _mapTireToTyreData(tire);
        _originalTires[idx] = tire;
        anyMapped = true;
      }
    }

    if (!anyMapped) {
      for (int i = 0; i < tireList.length && i < totalSlots; i++) {
        tyres[i]          = _mapTireToTyreData(tireList[i]);
        _originalTires[i] = tireList[i];
      }
    }


  }

  void applyRotationToInspection() {
    if (!Get.isRegistered<VehicleInspeController>()) {
      return;
    }

    final inspeController = Get.find<VehicleInspeController>();
    final List<InstalledTire> updatedTires = [];

    for (int i = 0; i < _originalTires.length; i++) {
      final tire = _originalTires[i];
      if (tire == null) continue;

      final newPosition = _indexToPosition(i, _axleConfig);

      final updatedTire = InstalledTire(
        tireId:            tire.tireId,
        tireSerialNo:      tire.tireSerialNo,
        wheelPosition:     newPosition,
        currentTreadDepth: tire.currentTreadDepth,
        currentPressure:   tire.currentPressure,
        currentHours:      tire.currentHours,
        currentMiles:      tire.currentMiles,
        outsideTread:      tire.outsideTread,
        middleTread:       tire.middleTread,
        insideTread:       tire.insideTread,
        dispositionId:     tire.dispositionId,
        casingConditionId: tire.casingConditionId,
        wearConditionId:   tire.wearConditionId,
        percentageWorn:    tire.percentageWorn,
        originalTread:     tire.originalTread,
        removeAt:          tire.removeAt,
        sizeName:          tire.sizeName,
        typeName:          tire.typeName,
        manufacturerName:  tire.manufacturerName,
        vehicleId:         tire.vehicleId,
        brandNo:           tire.brandNo,
        removalReasonId:   tire.removalReasonId,
        mountedRimId:      tire.mountedRimId,
        pressureType:      tire.pressureType,
        comments:          tire.comments,
      );

      updatedTires.add(updatedTire);
    }

    inspeController.tires.assignAll(updatedTires);
  }

  String _indexToPosition(int index, String axleConfig) {
    int offset = 0;
    for (int axle = 0; axle < axleConfig.length; axle++) {
      final slots = int.tryParse(axleConfig[axle]) ?? 2;
      if (index < offset + slots) {
        final posInAxle = index - offset;
        if (slots == 4) {
          const sides = ['LO', 'LI', 'RI', 'RO'];
          return '${axle + 1}${sides[posInAxle % 4]}';
        } else {
          final side = (posInAxle % 2 == 0) ? 'L' : 'R';
          return '${axle + 1}$side';
        }
      }
      offset += slots;
    }
    final axleNum = (index ~/ 2) + 1;
    final side    = (index % 2 == 0) ? 'L' : 'R';
    return '$axleNum$side';
  }

  int _positionToIndex(String position, String axleConfig) {
    if (position.isEmpty || position.length < 2) return -1;

    try {
      final axleNum = int.tryParse(
        position.replaceAll(RegExp(r'[^0-9]'), ''),
      ) ?? 1;

      final sidePart = position.replaceAll(RegExp(r'[0-9]'), '').toUpperCase();

      int offset = 0;
      for (int i = 0; i < axleNum - 1 && i < axleConfig.length; i++) {
        offset += int.tryParse(axleConfig[i]) ?? 2;
      }

      final axleSlots = axleNum <= axleConfig.length
          ? (int.tryParse(axleConfig[axleNum - 1]) ?? 2)
          : 2;

      if (axleSlots == 4) {
        switch (sidePart) {
          case 'LO': return offset + 0;
          case 'LI': return offset + 1;
          case 'RI': return offset + 2;
          case 'RO': return offset + 3;
          case 'L':  return offset + 0;
          case 'R':  return offset + 3;
          default:   return offset + 0;
        }
      } else {
        switch (sidePart) {
          case 'L':  return offset + 0;
          case 'R':  return offset + 1;
          default:   return offset + 0;
        }
      }
    } catch (e) {
      return -1;
    }
  }

  String _clean(dynamic val) {
    if (val == null) return '0';
    final d = double.tryParse(val.toString());
    if (d == null) return val.toString();
    if (d == d.truncateToDouble()) return d.toInt().toString();
    final s = d.toStringAsFixed(2);
    return s.contains('.') ? s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '') : s;
  }


  bool hasRotationChanged() {
    if (!Get.isRegistered<VehicleInspeController>()) return false;

    final inspeController = Get.find<VehicleInspeController>();
    final originalTireList = inspeController.tires;

    for (int i = 0; i < _originalTires.length; i++) {
      final tire = _originalTires[i];
      if (tire == null) continue;

      final newPosition = _indexToPosition(i, _axleConfig);

      InstalledTire? originalTire;
      for (final t in originalTireList) {
        if (t.tireId == tire.tireId) {
          originalTire = t;
          break;
        }
      }

      if (originalTire == null) continue;

      if ((originalTire.wheelPosition ?? '') != newPosition) {

        return true;
      }
    }

    return false;
  }

  TyreData _mapTireToTyreData(InstalledTire tire) {
    final worn = tire.percentageWorn ?? 0.0;

    Color percentColor;
    Color borderColor;
    final String percentLabel = '${worn.toStringAsFixed(0)}%';

    if (worn < 25) {
      percentColor = Colors.green;
      borderColor  = Colors.green;
    } else if (worn < 50) {
      percentColor = Colors.yellow.shade700;
      borderColor  = Colors.yellow.shade700;
    } else if (worn < 75) {
      percentColor = const Color(0xFFB57B1C);
      borderColor  = const Color(0xFFB57B1C);
    } else {
      percentColor = Colors.red;
      borderColor  = Colors.red;
    }

    return TyreData(
      serial:       tire.tireSerialNo ?? '',
      brandNo:      tire.brandNo,
      percent:      percentLabel,
      percentColor: percentColor,
      borderColor:  borderColor,
      p:     _clean(tire.currentPressure),
      to:    _clean(tire.outsideTread),
      tm:    _clean(tire.middleTread),   // 👈 ADD THIS LINE
      ti:    _clean(tire.insideTread),

      miles: '${_clean(MeasurementHelper.toDisplayDistance(tire.currentMiles ?? 0))} ${MeasurementHelper.distanceLabel}\n${_clean(tire.currentHours)} hrs',
    );  }


  String get axleConfig => _axleConfig;

  int slotIndexForPosition(String position) =>
      _positionToIndex(position, _axleConfig);


  void moveTyre(int from, int to) {
    if (from >= tyres.length || to >= tyres.length) return;
    tyres[to]          = tyres[from];
    tyres[from]        = null;
    _originalTires[to]   = _originalTires[from];
    _originalTires[from] = null;
    _notify();
  }

  void swapTyres(int from, int to) {
    if (from >= tyres.length || to >= tyres.length) return;
    final temp           = tyres[to];
    tyres[to]            = tyres[from];
    tyres[from]          = temp;
    final tempOrig       = _originalTires[to];
    _originalTires[to]   = _originalTires[from];
    _originalTires[from] = tempOrig;
    _notify();
  }

  void moveToBuffer(int index) {
    if (index >= tyres.length) return;
    bufferTyre            = tyres[index];
    bufferIndex           = index;
    tyres[index]          = null;
    _bufferOriginalTire   = _originalTires[index];
    _originalTires[index] = null;
    _notify();
  }

  void placeFromBuffer(int index) {
    if (bufferTyre == null || index >= tyres.length) return;
    tyres[index]          = bufferTyre;
    bufferTyre            = null;
    bufferIndex           = null;
    _originalTires[index] = _bufferOriginalTire;
    _bufferOriginalTire   = null;
    _notify();
  }

  bool isTirePendingApproval(int index) {
    if (index < 0 || index >= _originalTires.length) return false;
    final tire = _originalTires[index];
    if (tire == null) return false;
    final tId = tire.tireId ?? 0;
    if (tId < 0) return true; // Offline / unsynced tyre
    final isPending = _pendingInstallTireIds.contains(tId);
    return isPending;
  }

  bool isTireOffline(int index) {
    if (index < 0 || index >= _originalTires.length) return false;
    final tire = _originalTires[index];
    if (tire == null) return false;
    final tId = tire.tireId ?? 0;
    return tId < 0;
  }
}