import 'package:hive_flutter/hive_flutter.dart';
import '../models/inspection_hive_model.g.dart';
import '../models/inspection_hive_models.dart';

class SyncHiveService {
  static const String _inspectionBoxName = 'inspectionBox';

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(InspectionHiveModelAdapter());
    }
    if (!Hive.isBoxOpen(_inspectionBoxName)) {
      await Hive.openBox<InspectionHiveModel>(_inspectionBoxName);
    }
  }

  static Box<InspectionHiveModel> get _box =>
      Hive.box<InspectionHiveModel>(_inspectionBoxName);


  static Future<String> saveUnsyncedInspection(
      Map<String, dynamic> data) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    data['id']       = id;
    data['isSynced'] = false;
    data['syncedAt'] = null;

    final model = InspectionHiveModel.fromMap(data);
    await _box.put(id, model);
    return id;
  }

  static List<InspectionHiveModel> getUnsyncedList() {
    return _box.values.where((e) => !e.isSynced).toList()
      ..sort((a, b) => b.inspectionDate.compareTo(a.inspectionDate));
  }

  static List<InspectionHiveModel> getSyncedList() {
    return _box.values.where((e) => e.isSynced).toList()
      ..sort((a, b) => (b.syncedAt ?? '').compareTo(a.syncedAt ?? ''));
  }

  static int unsyncedCount()    => getUnsyncedList().length;
  static int syncedCount()      => getSyncedList().length;
  static int pendingCount()     => _box.values.where((e) => e.status == 'P').length;
  static int approvedCount()    => _box.values.where((e) => e.status == 'A' && !e.isSynced).length;
  static int rejectedCount()    => _box.values.where((e) => e.status == 'R').length;

  static String? lastSyncedDate() {
    final synced = getSyncedList();
    if (synced.isEmpty) return null;
    return synced.first.syncedAt;
  }

  static Future<void> markAsSynced(String id) async {
    final model = _box.get(id);
    if (model == null) {
      return;
    }
    model.isSynced = true;
    model.syncedAt = DateTime.now().toIso8601String();
    await model.save();
  }

  static Future<void> deleteInspection(String id) async {
    await _box.delete(id);
  }

  static Future<void> updateStatus(String id, String newStatus,
      {String? rejectionReason}) async {
    final model = _box.get(id);
    if (model == null) return;
    model.status = newStatus;
    if (rejectionReason != null) model.rejectionReason = rejectionReason;
    await model.save();
  }


  static Future<void> clearAll() async {
    await _box.clear();
  }

  static Future<void> close() async {
    if (Hive.isBoxOpen(_inspectionBoxName)) {
      await _box.close();
    }
  }
}