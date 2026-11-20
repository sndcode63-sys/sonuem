import 'package:hive/hive.dart';


/// Hive TypeId = 1 (apne project me conflict avoid karne ke liye check karo)
@HiveType(typeId: 1)
class InspectionHiveModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String vehicleId;

  @HiveField(2)
  String vehicleNumber;

  @HiveField(3)
  String accountName;

  @HiveField(4)
  String locationName;

  @HiveField(5)
  int parentAccountId;

  @HiveField(6)
  int locationId;

  @HiveField(7)
  String inspectionDate;

  @HiveField(8)
  String approverName;

  @HiveField(9)
  String requestorName;

  @HiveField(10)
  String comments;

  @HiveField(11)
  String status; // 'A' = approved/pending-sync, 'P' = pending, 'R' = rejected

  @HiveField(12)
  bool isSynced; // false = unsynced tab, true = synced history tab

  @HiveField(13)
  String? syncedAt; // jab sync hua, tab ki datetime (nullable)

  @HiveField(14)
  int inspectedTyreCount;

  @HiveField(15)
  int totalTyreCount;

  @HiveField(16)
  String? rejectionReason;

  @HiveField(17)
  String? approverEmail;

  @HiveField(18)
  String action; // 'Inspect' | 'Install' | 'Remove'

  // ── Fix: explicit constructor — HiveObject ke saath zaroori hai ─────────
  InspectionHiveModel({
    required this.id,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.accountName,
    required this.locationName,
    required this.parentAccountId,
    required this.locationId,
    required this.inspectionDate,
    required this.approverName,
    required this.requestorName,
    required this.comments,
    required this.status,
    required this.isSynced,
    this.syncedAt,
    required this.inspectedTyreCount,
    required this.totalTyreCount,
    this.rejectionReason,
    this.approverEmail,
    required this.action,
  });

  /// Map se model banana (API / local save ke liye)
  factory InspectionHiveModel.fromMap(Map<String, dynamic> map) {
    return InspectionHiveModel(
      id:                 map['id']?.toString()             ?? DateTime.now().millisecondsSinceEpoch.toString(),
      vehicleId:          map['vehicleId']?.toString()      ?? '',
      vehicleNumber:      map['vehicleNumber']?.toString()  ?? '',
      accountName:        map['accountName']?.toString()    ?? '',
      locationName:       map['locationName']?.toString()   ?? '',
      parentAccountId:    _toInt(map['parentAccountId']),
      locationId:         _toInt(map['locationId']),
      inspectionDate:     map['inspectionDate']?.toString() ?? DateTime.now().toIso8601String(),
      approverName:       map['approverName']?.toString()   ?? '',
      requestorName:      map['requestorName']?.toString()  ?? '',
      comments:           map['comments']?.toString()       ?? '',
      status:             map['status']?.toString()         ?? 'A',
      isSynced:           map['isSynced'] == true,
      syncedAt:           map['syncedAt']?.toString(),
      inspectedTyreCount: _toInt(map['inspectedTyreCount']),
      totalTyreCount:     _toInt(map['totalTyreCount']),
      rejectionReason:    map['rejectionReason']?.toString(),
      approverEmail:      map['approverEmail']?.toString(),
      action:             map['action']?.toString()         ?? 'Inspect',
    );
  }

  Map<String, dynamic> toMap() => {
    'id':                id,
    'vehicleId':         vehicleId,
    'vehicleNumber':     vehicleNumber,
    'accountName':       accountName,
    'locationName':      locationName,
    'parentAccountId':   parentAccountId,
    'locationId':        locationId,
    'inspectionDate':    inspectionDate,
    'approverName':      approverName,
    'requestorName':     requestorName,
    'comments':          comments,
    'status':            status,
    'isSynced':          isSynced,
    'syncedAt':          syncedAt,
    'inspectedTyreCount':inspectedTyreCount,
    'totalTyreCount':    totalTyreCount,
    'rejectionReason':   rejectionReason,
    'approverEmail':     approverEmail,
    'action':            action,
  };

  static int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is int)  return val;
    return int.tryParse(val.toString()) ?? 0;
  }
}