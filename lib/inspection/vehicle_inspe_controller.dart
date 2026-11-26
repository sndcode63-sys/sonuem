import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emtrack/inspection/update_hours_view.dart';
import 'package:emtrack/inspection/vehicle_inspe_model.dart';
import 'package:emtrack/inspection/vehicle_inspe_service.dart';
import 'package:emtrack/models/tyre_model.dart';
import 'package:emtrack/models/remove_tyre_model.dart';
import 'package:emtrack/routes/app_pages.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emtrack/services/image_upload_service.dart';
import 'package:emtrack/utils/api_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../utils/mesurment_helper_class.dart';
import '../utils/tyre_unit_history.dart';
import '../utils/global_state_referesh.dart';
import '../utils/hive_prefe.dart';
import '../inspection_approval/search.dart';
import '../utils/pending_inspection_guard.dart';
import '../utils/image_watermark_helper.dart';
import '../utils/local_image_cache.dart';
import '../services/api_constants.dart';

const String _tag = '🔧 [VIC_DEBUG]';

void _vicTrace(String msg, [String ansi = '\x1B[36m']) {
  debugPrint('$ansi[VIC_TRACE ${DateTime.now().toIso8601String()}] $msg\x1B[0m');
}

class InspectedTyreImageItem {
  final int tireId;
  final String tireSerial;
  final String wheelPosition;
  final String pathOrUrl;
  final File file;

  InspectedTyreImageItem({
    required this.tireId,
    required this.tireSerial,
    required this.wheelPosition,
    required this.pathOrUrl,
    required this.file,
  });
}

class VehicleInspeController extends GetxController {
  final VehicleInspeService service = VehicleInspeService();

  RxList<InstalledTire> tires = <InstalledTire>[].obs;
  final List<Map<String, dynamic>> pendingInstallPayloads = [];
  final List<InstalledTire> removedTires = <InstalledTire>[].obs;
  final List<Map<String, dynamic>> pendingRemovePayloads = [];
  VehicleInspectionModel? model;

  RxList<InspectedTyreImageItem> inspectedTyreImages = <InspectedTyreImageItem>[].obs;

  final TextEditingController commentsCtrl = TextEditingController();
  final TextEditingController vehicleNumberCtrl = TextEditingController();
  final TextEditingController vehicleIdCtrl = TextEditingController();
  final TextEditingController hoursCtrl = TextEditingController();
  final TextEditingController kmCtrl = TextEditingController();
  final TextEditingController kmDisplayCtrl = TextEditingController();

  RxString vehicleId = ''.obs;
  RxString hours = ''.obs;

  /// 📅 Update Hours screen me user ne jo Survey Date chuni (ISO). Null ho to
  /// aaj ki date. Vehicle + tyre inspection records isi date ke saath jaate
  /// hain (tyre.dart me "Last Inspection" bhi yahi dikhti hai).
  String? surveyDateIso;
  String get inspectionIso => surveyDateIso ?? DateTime.now().toIso8601String();
  RxString km = ''.obs;
  RxString mileageType = 'Both'.obs;
  RxBool isSubmitting = false.obs;
  RxBool showHourWarning = true.obs;
  RxBool isUploadingImages = false.obs;
  RxBool isLoading = false.obs;
  RxBool isOffline = false.obs;

  double _serverHours = 0.0;
  double _serverKm = 0.0;
  double get serverKm => _serverKm;
  String _serverKmUnit = '';

  RxList<File> uploadedImages = <File>[].obs;
  final ImagePicker _picker = ImagePicker();

  Rxn<VehicleInspectionResponse> inspectionResponse =
  Rxn<VehicleInspectionResponse>();

  String get _prefsKey => 'vehicle_images_${vehicleId.value}';
  String get _prevHoursKey => 'vehicle_prev_hours_${vehicleId.value}';
  String get _prevKmKey => 'vehicle_prev_km_${vehicleId.value}';
  String get _tireDeltaMapKey => 'tire_hours_delta_map_${vehicleId.value}';
  String get _tireMileDeltaMapKey => 'tire_km_delta_map_${vehicleId.value}';
  String get _tireCommentMapKey => 'tire_comment_map_${vehicleId.value}';
  String get _vehicleCommentKey => 'vehicle_comment_${vehicleId.value}';
  String get _vehicleDistUnitKey => 'vehicle_dist_unit_${vehicleId.value}';

  String _resolveVehicleDistUnit() {
    return MeasurementHelper.distanceLabel;
  }

  void syncKmDisplay() {
    if (_serverKm <= 0) return;
    final String txt = _serverKm.round().toString();
    if (kmDisplayCtrl.text != txt) {
      kmDisplayCtrl.text = txt;
    }
  }

  bool get showHours =>
      mileageType.value == '1' ||
          mileageType.value == '3' ||
          mileageType.value == 'Hours' ||
          mileageType.value == 'Both';

  bool get showKm =>
      mileageType.value == '2' ||
          mileageType.value == '3' ||
          mileageType.value == 'Distance' ||
          mileageType.value == 'Both';

  final RxBool shouldUseTempApi = false.obs;
  Worker? _measurementWorker;
  Worker? _pressureWorker;

  @override
  void onInit() {
    super.onInit();
    _vicTrace('onInit() START', '\x1B[32m');
    _checkApprovalWorkflow();
    pendingInstallPayloads.clear();
    removedTires.clear();
    pendingRemovePayloads.clear();
    // 🔧 Preference change se pehle ki unit yaad rakho: jin tyres ki raw history
    // nahi hai unki displayed value isi unit me hoti hai (compounding conversion bug fix).
    _prevPressLabel = MeasurementHelper.pressureLabel;
    _prevMeasureLabel = MeasurementHelper.isMetric ? 'Metric' : 'Imperial';
    if (Get.isRegistered<GlobalPrefsState>()) {
      _measurementWorker = ever(GlobalPrefsState.to.measurement, (_) {
        if (!isClosed) _recomputeDisplayUnits();
      });
      _pressureWorker = ever(GlobalPrefsState.to.pressure, (_) {
        if (!isClosed) _recomputeDisplayUnits();
      });
    }
    debugPrint('$_tag onInit() CALLED');
    final argVehicleId = Get.arguments;
    debugPrint('$_tag onInit(): Get.arguments = $argVehicleId (${argVehicleId.runtimeType})');

    if (argVehicleId == null) {
      debugPrint('$_tag onInit(): argVehicleId is NULL -> returning early, NOTHING will load');
      return;
    }

    int? parsedId;
    if (argVehicleId is int) {
      parsedId = argVehicleId;
    } else if (argVehicleId is String) {
      parsedId = int.tryParse(argVehicleId);
    } else if (argVehicleId is Map) {
      parsedId = int.tryParse(argVehicleId['vehicleId']?.toString() ?? '');
    } else {
      try {
        parsedId = int.tryParse((argVehicleId as dynamic).vehicleId?.toString() ?? '');
      } catch (_) {}
    }
    debugPrint('$_tag onInit(): parsedId = $parsedId');

    if (parsedId == null || parsedId == 0) {
      debugPrint('$_tag onInit(): parsedId is null/0 -> returning early, NOTHING will load');
      return;
    }

    vehicleId.value = parsedId.toString();
    vehicleIdCtrl.text = parsedId.toString();
    debugPrint('$_tag onInit(): vehicleId.value set to ${vehicleId.value}');

    if (parsedId < 0) {
      debugPrint('$_tag onInit(): parsedId < 0 -> OFFLINE/TEMP vehicle, calling _resolveAndFetch()');
      _resolveAndFetch();
    } else {
      debugPrint('$_tag onInit(): parsedId > 0 -> REAL vehicle, calling fetchInspectionData()');
      fetchInspectionData();
    }

    // Skip full-account PendingInspectionGuard.prefetch(force: true) here so opening
    // one vehicle never downloads/parses all pending inspections across the account.
  }

  /// Is vehicle par koi inspection abhi approval ke liye pending hai?
  /// true => dialog dikha diya gaya hai, caller ko turant return karna hai.
  Future<bool> _blockedByPendingApproval(PendingBlockedAction action) async {
    final allowed = await PendingInspectionGuard.canProceed(
      vehicleId: int.tryParse(vehicleId.value),
      vehicleNumber: vehicleNumberCtrl.text,
      action: action,
    );
    return !allowed;
  }

  Future<void> _checkApprovalWorkflow() async {
    try {
      final String? userRole = await SecureStorage.getUserProfileRole();
      final bool isEmtUser = (userRole ?? '').trim().toUpperCase() == 'EMTUSER';
      final bool isWorkflowEnabled = await SecureStorage.getApprovalWorkflowEnabled();
      bool isApprover = false;
      if (isEmtUser) {
        isApprover = await SecureStorage.getIsApprover();
      }
      shouldUseTempApi.value = isEmtUser && (!isWorkflowEnabled || !isApprover);
      debugPrint('$_tag _checkApprovalWorkflow(): shouldUseTempApi=${shouldUseTempApi.value}');
    } catch (e) {
      debugPrint('$_tag _checkApprovalWorkflow() EXCEPTION -> $e');
    }
  }

  Future<void> refreshAfterTireInspection() async {
    debugPrint('$_tag refreshAfterTireInspection(): forcing tires.refresh() (Obx rebuild)');
    tires.refresh();
  }

  Future<void> _resolveAndFetch() async {
    debugPrint('$_tag _resolveAndFetch() CALLED for tempId=${vehicleId.value}');
    try {
      final prefs = await SharedPreferences.getInstance();
      final tempIdStr = vehicleId.value;

      final realIdFromSP = prefs.getInt('vehicle_real_id_$tempIdStr');
      debugPrint('$_tag _resolveAndFetch(): realIdFromSP (SharedPrefs) = $realIdFromSP');
      if (realIdFromSP != null && realIdFromSP > 0) {
        vehicleId.value = realIdFromSP.toString();
        vehicleIdCtrl.text = realIdFromSP.toString();
        debugPrint('$_tag _resolveAndFetch(): RESOLVED temp->real id. vehicleId now = ${vehicleId.value}. Fetching...');
        fetchInspectionData();
        return;
      }

      final vehInBox = OfflineHiveService.getVehicleById(
        int.tryParse(tempIdStr) ?? 0,
      );
      if (vehInBox == null) {
        debugPrint('$_tag _resolveAndFetch(): vehicle NOT found in Hive box for tempId=$tempIdStr');
      } else {
        debugPrint('$_tag _resolveAndFetch(): vehicle FOUND in Hive box (still unresolved/offline)');
      }
    } catch (e) {
      debugPrint('$_tag _resolveAndFetch(): EXCEPTION -> $e');
    }
    debugPrint('$_tag _resolveAndFetch(): falling back to fetchInspectionData() with vehicleId=${vehicleId.value}');
    fetchInspectionData();
  }

  static Future<void> saveLastInspectionDate(String date) async {
    final storage = FlutterSecureStorage();
    await storage.write(key: 'last_inspection_date', value: date);
    debugPrint('$_tag saveLastInspectionDate(): saved -> $date');
  }

  static Future<String?> getLastInspectionDate() async {
    final storage = FlutterSecureStorage();
    final val = await storage.read(key: 'last_inspection_date');
    debugPrint('$_tag getLastInspectionDate(): read -> $val');
    return val;
  }

  String _normalizeImageUrl(String path) {
    final clean = path.trim();
    if (clean.isEmpty || clean.toLowerCase() == 'null') return '';
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }
    if (clean.startsWith('/') || clean.toLowerCase().contains('uploads')) {
      final base = ApiConstants.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
      return '$base${clean.startsWith('/') ? '' : '/'}$clean';
    }
    return clean;
  }

  Future<void> loadInspectedTyreImages() async {
    try {
      final Set<String> seenPaths = <String>{};
      final List<InspectedTyreImageItem> results = [];
      final prefs = await SharedPreferences.getInstance();

      // Safe snapshot of tires to avoid ConcurrentModificationError
      final currentTires = tires.toList();

      // 1. Scan from controller's current tyres
      for (final t in currentTires) {
        final tid = t.tireId;
        final tSerial = t.tireSerialNo ?? '';
        final pos = t.wheelPosition ?? '';

        final rawLoc = t.imagesLocation?.toString().trim() ?? '';
        if (rawLoc.isNotEmpty && rawLoc.toLowerCase() != 'null') {
          for (final p in rawLoc.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty)) {
            final normalized = _normalizeImageUrl(p);
            if (normalized.isNotEmpty && !seenPaths.contains(normalized)) {
              seenPaths.add(normalized);
              final isHttp = normalized.startsWith('http://') || normalized.startsWith('https://');
              final resolved = LocalImageCache.resolveSync(normalized, tireId: tid);
              final hasResolved = LocalImageCache.safeFileExists(resolved);
              final file = (hasResolved && resolved != null) ? resolved : File(normalized);
              final fileExists = LocalImageCache.safeFileExists(file);
              if (isHttp || fileExists) {
                results.add(InspectedTyreImageItem(
                  tireId: tid ?? 0,
                  tireSerial: tSerial,
                  wheelPosition: pos,
                  pathOrUrl: normalized,
                  file: file,
                ));
              }
            }
          }
        }

        if (tid != null && tid > 0) {
          final spList = prefs.getStringList('inspect_tire_images_$tid');
          if (spList != null) {
            for (final p in spList) {
              final clean = p.trim();
              if (clean.isNotEmpty && clean.toLowerCase() != 'null') {
                final normalized = _normalizeImageUrl(clean);
                if (normalized.isNotEmpty && !seenPaths.contains(normalized)) {
                  seenPaths.add(normalized);
                  final isHttp = normalized.startsWith('http://') || normalized.startsWith('https://');
                  final resolved = LocalImageCache.resolveSync(normalized, tireId: tid);
                  final hasResolved = LocalImageCache.safeFileExists(resolved);
                  final file = (hasResolved && resolved != null) ? resolved : File(normalized);
                  final fileExists = LocalImageCache.safeFileExists(file);
                  if (isHttp || fileExists) {
                    results.add(InspectedTyreImageItem(
                      tireId: tid,
                      tireSerial: tSerial,
                      wheelPosition: pos,
                      pathOrUrl: normalized,
                      file: file,
                    ));
                  }
                }
              }
            }
          }
        }
      }

      // 2. Also scan from offline Hive inspection cache
      try {
        final cached = OfflineHiveService.getInspectionCache(vehicleId.value);
        if (cached != null) {
          final decoded = jsonDecode(cached);
          final m = (decoded is Map && decoded['model'] is Map)
              ? decoded['model'] as Map<String, dynamic>
              : (decoded is Map<String, dynamic> ? decoded : null);
          if (m != null) {
            final tList = m['installedTires'] ?? m['tireList'] ?? m['tiresList'];
            if (tList is List) {
              for (final item in tList) {
                if (item is Map<String, dynamic>) {
                  final rawTid = item['tireId'];
                  final int tid = rawTid is num ? rawTid.toInt() : (int.tryParse('$rawTid') ?? 0);
                  final tSerial = item['tireSerialNumber']?.toString() ?? item['serialNumber']?.toString() ?? '';
                  final pos = item['wheelPosition']?.toString() ?? '';
                  final loc = item['imagesLocation']?.toString().trim() ?? '';
                  if (loc.isNotEmpty && loc.toLowerCase() != 'null') {
                    for (final p in loc.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty)) {
                      final normalized = _normalizeImageUrl(p);
                      if (normalized.isNotEmpty && !seenPaths.contains(normalized)) {
                        seenPaths.add(normalized);
                        final isHttp = normalized.startsWith('http://') || normalized.startsWith('https://');
                        final resolved = LocalImageCache.resolveSync(normalized, tireId: tid);
                        final hasResolved = LocalImageCache.safeFileExists(resolved);
                        final file = (hasResolved && resolved != null) ? resolved : File(normalized);
                        final fileExists = LocalImageCache.safeFileExists(file);
                        if (isHttp || fileExists) {
                          results.add(InspectedTyreImageItem(
                            tireId: tid,
                            tireSerial: tSerial,
                            wheelPosition: pos,
                            pathOrUrl: normalized,
                            file: file,
                          ));
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      } catch (_) {}

      inspectedTyreImages.assignAll(results);
      debugPrint('$_tag loadInspectedTyreImages(): loaded ${inspectedTyreImages.length} tyre image(s)');
    } catch (e) {
      debugPrint('$_tag loadInspectedTyreImages() EXCEPTION -> $e');
    }
  }

  Future<void> deleteInspectedTyreImage(int index) async {
    if (index < 0 || index >= inspectedTyreImages.length) return;
    final item = inspectedTyreImages.removeAt(index);
    final tid = item.tireId;
    final path = item.pathOrUrl;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (tid > 0) {
        final list = prefs.getStringList('inspect_tire_images_$tid');
        if (list != null) {
          list.removeWhere((p) => p.trim() == path.trim());
          await prefs.setStringList('inspect_tire_images_$tid', list);
        }
      }

      if (item.file.existsSync() && !path.startsWith('http')) {
        item.file.deleteSync();
      }

      for (final t in tires) {
        if (t.tireId == tid && t.imagesLocation != null) {
          final locs = t.imagesLocation.toString().split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty && e != path.trim())
              .join(',');
          t.imagesLocation = locs.isNotEmpty ? locs : null;
        }
      }

      final cached = OfflineHiveService.getInspectionCache(vehicleId.value);
      if (cached != null) {
        final decoded = jsonDecode(cached) as Map<String, dynamic>;
        final m = (decoded['model'] as Map<String, dynamic>?) ?? decoded;
        final tList = m['installedTires'] ?? m['tireList'] ?? m['tiresList'];
        if (tList is List) {
          for (final tItem in tList) {
            if (tItem is Map<String, dynamic> && (tItem['tireId'] == tid || '${tItem['tireId']}' == '$tid')) {
              final loc = tItem['imagesLocation']?.toString() ?? '';
              final updated = loc.split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty && e != path.trim())
                  .join(',');
              tItem['imagesLocation'] = updated.isNotEmpty ? updated : null;
            }
          }
          await OfflineHiveService.saveInspectionCache(vehicleId.value, jsonEncode(decoded));
        }
      }
    } catch (e) {
      debugPrint('$_tag Error deleting inspected tyre image: $e');
    }
  }

  /// Loads saved local or remote images for this vehicle from SharedPreferences
  Future<void> _loadSavedImages() async {
    await loadInspectedTyreImages();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = [
        _prefsKey,
        'vehicle_images_${vehicleId.value}',
        'pending_images_${vehicleId.value}',
        if (vehicleNumberCtrl.text.isNotEmpty) 'vehicle_images_${vehicleNumberCtrl.text.trim()}',
        if (vehicleNumberCtrl.text.isNotEmpty) 'pending_images_${vehicleNumberCtrl.text.trim()}',
      ];
      for (final k in keys) {
        final list = prefs.getStringList(k);
        if (list != null && list.isNotEmpty) {
          for (final p in list) {
            final path = p.trim();
            if (path.isEmpty) continue;
            final resolved = LocalImageCache.resolveSync(path, vehicleId: vehicleId.value);
            if (resolved != null && resolved.existsSync()) {
              if (!uploadedImages.any((f) => f.path == resolved.path)) {
                uploadedImages.add(resolved);
              }
            } else if (path.startsWith('http')) {
              if (!uploadedImages.any((f) => f.path == path)) {
                uploadedImages.add(File(path));
              }
              LocalImageCache.cacheNetworkImage(path);
            } else if (File(path).existsSync()) {
              if (!uploadedImages.any((f) => f.path == path)) {
                uploadedImages.add(File(path));
              }
            }
          }
        }
      }

      final vFiles = await LocalImageCache.getLocalImagesForVehicle(vehicleId.value);
      for (final vf in vFiles) {
        if (!uploadedImages.any((f) => f.path == vf.path)) {
          uploadedImages.add(vf);
        }
      }
      debugPrint('$_tag _loadSavedImages(): loaded ${uploadedImages.length} image(s)');
    } catch (e) {
      debugPrint('$_tag _loadSavedImages(): EXCEPTION -> $e');
    }
  }

  /// Walks the cached RAW response of GetInspectionRecordForVehicle and
  /// picks every http image URL stored under a key containing "image"
  /// (vehicle level only — anything inside tyre objects is skipped, those
  /// are tyre photos). Every hit is printed in RED with its JSON path.
  void _scanRecordForImages() {
    try {
      final raw = OfflineHiveService.getInspectionCache(vehicleId.value);
      if (raw == null) {
        ApiLog.info('GetInspectionRecordForVehicle', 'no raw response cached to scan');
        return;
      }
      final root = jsonDecode(raw);
      var hits = 0;
      final topKeys = root is Map
          ? [
        ...root.keys,
        if (root['model'] is Map) ...(root['model'] as Map).keys.map((k) => 'model.$k')
      ]
          : [];
      ApiLog.info('GetInspectionRecordForVehicle', 'response keys -> $topKeys');

      void walk(dynamic node, String path) {
        if (node is Map) {
          node.forEach((k, v) {
            final key = k.toString();
            final lower = key.toLowerCase();
            if (lower.contains('tire') || lower.contains('tyre')) return; // tyre photos, not vehicle
            final here = path.isEmpty ? key : '$path.$key';
            if (lower.contains('image') &&
                !lower.contains('count') &&
                (v is String || v is List)) {
              final text = v is List ? v.join(',') : v.toString();
              if (text.contains('http')) {
                hits++;
                ApiLog.info('GetInspectionRecordForVehicle', 'image key "$here" -> $text');
                _applyServerImages(text);
              }
            }
            if (v is Map || v is List) walk(v, here);
          });
        } else if (node is List) {
          for (var i = 0; i < node.length; i++) {
            walk(node[i], '$path[$i]');
          }
        }
      }

      walk(root, '');
      ApiLog.info('GetInspectionRecordForVehicle',
          'deep scan found $hits image field(s); list now has ${uploadedImages.length} image(s)');
    } catch (e) {
      ApiLog.error('GetInspectionRecordForVehicle', 'deep scan EXCEPTION -> $e');
    }
  }

  /// Reads the vehicle photos saved on the server for this vehicle from
  /// GET Inspection/GetAllPendingInspections/{accountId} — exactly where the
  /// approval screen (inspection_approval/vehicle.dart) gets them from.
  Future<void> _fetchPendingVehicleImages() async {
    try {
      final accStr = await SecureStorage.getParentAccountId();
      final accountId = int.tryParse(accStr ?? '0') ?? 0;
      final myVehicleId = int.tryParse(vehicleId.value);
      if (accountId <= 0 || myVehicleId == null) return;

      final data = await service.getPendingInspections(accountId);
      if (data == null) return;

      dynamic pick(Map m, List<String> keys) {
        for (final k in keys) {
          if (m.containsKey(k)) return m[k];
        }
        return null;
      }

      final dynamic list = pick(data, ['model', 'Model', 'inspectionList', 'data']);
      if (list is! List) return;

      var found = 0;
      for (final item in list) {
        if (item is! Map) continue;
        final v = pick(item, ['Vehicle', 'vehicle', 'VehicleDetails']);
        final vehicles = v is List ? v : [v];
        for (final veh in vehicles) {
          if (veh is! Map) continue;
          final vId = int.tryParse('${pick(veh, ['VehicleId', 'vehicleId']) ?? ''}');
          if (vId != myVehicleId) continue;
          final loc = pick(veh, ['ImagesLocation', 'imagesLocation']);
          if (loc != null && loc.toString().trim().isNotEmpty) {
            _applyServerImages(loc);
            found++;
          }
        }
      }
      debugPrint('$_tag _fetchPendingVehicleImages(): matched $found pending record(s) for vehicle $myVehicleId');
    } catch (e) {
      debugPrint('$_tag _fetchPendingVehicleImages() EXCEPTION -> $e');
    }
  }

  /// Fills the image list from the vehicle record's `imagesLocation`
  /// (both server URLs and valid local image paths).
  void _applyServerImages(dynamic raw) {
    final items = (raw ?? '')
        .toString()
        .split(',')
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty);
    for (final rawUrl in items) {
      String u = rawUrl;
      if (!u.startsWith('http') && (u.startsWith('/') || u.toLowerCase().contains('.jpg') || u.toLowerCase().contains('.png') || u.toLowerCase().contains('.jpeg'))) {
        final cleanBase = ApiConstants.baseUrl.endsWith('/') ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1) : ApiConstants.baseUrl;
        final cleanPath = u.startsWith('/') ? u : '/$u';
        if (!u.contains('\\') && !u.startsWith('C:') && !u.startsWith('/data/')) {
          u = '$cleanBase$cleanPath';
        }
      }
      final resolved = LocalImageCache.resolveSync(u, vehicleId: vehicleId.value);
      if (resolved != null && resolved.existsSync()) {
        if (!uploadedImages.any((f) => f.path == resolved.path)) {
          uploadedImages.add(resolved);
        }
      } else if (u.startsWith('http')) {
        if (!uploadedImages.any((f) => f.path == u)) {
          uploadedImages.add(File(u));
        }
        LocalImageCache.cacheNetworkImage(u);
      } else if (File(u).existsSync()) {
        if (!uploadedImages.any((f) => f.path == u)) {
          uploadedImages.add(File(u));
        }
      }
    }
    debugPrint('$_tag _applyServerImages(): ${uploadedImages.length} image(s) in list');
  }

  Future<void> _saveImagePaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paths = uploadedImages.map((f) => f.path).toList();
      await prefs.setStringList(_prefsKey, paths);
      debugPrint('$_tag _saveImagePaths(): saved ${paths.length} path(s)');
    } catch (e) {
      debugPrint('$_tag _saveImagePaths(): EXCEPTION -> $e');
    }
  }




  Future<Map<String, double>> _loadTireHoursDeltaMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_tireDeltaMapKey);
      if (raw == null) {
        debugPrint('$_tag _loadTireHoursDeltaMap(): no data found, returning {}');
        return {};
      }
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final result = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
      debugPrint('$_tag _loadTireHoursDeltaMap(): loaded -> $result');
      return result;
    } catch (e) {
      debugPrint('$_tag _loadTireHoursDeltaMap(): EXCEPTION -> $e');
      return {};
    }
  }

  Future<Map<String, double>> _loadTireKmDeltaMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_tireMileDeltaMapKey);
      if (raw == null) {
        debugPrint('$_tag _loadTireKmDeltaMap(): no data found, returning {}');
        return {};
      }
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final result = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
      debugPrint('$_tag _loadTireKmDeltaMap(): loaded -> $result');
      return result;
    } catch (e) {
      debugPrint('$_tag _loadTireKmDeltaMap(): EXCEPTION -> $e');
      return {};
    }
  }

  Future<Map<String, String>> _loadTireCommentMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_tireCommentMapKey);
      if (raw == null) return {};
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (e) {
      debugPrint('$_tag _loadTireCommentMap(): EXCEPTION -> $e');
      return {};
    }
  }

  Future<void> _saveTireCommentMap(Map<String, String> map) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tireCommentMapKey, jsonEncode(map));
    } catch (e) {
      debugPrint('$_tag _saveTireCommentMap(): EXCEPTION -> $e');
    }
  }

  Future<void> _saveTireHoursDeltaMap(Map<String, double> map) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tireDeltaMapKey, jsonEncode(map));
      debugPrint('$_tag _saveTireHoursDeltaMap(): saved -> $map');
    } catch (e) {
      debugPrint('$_tag _saveTireHoursDeltaMap(): EXCEPTION -> $e');
    }
  }

  Future<void> _saveTireKmDeltaMap(Map<String, double> map) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tireMileDeltaMapKey, jsonEncode(map));
      debugPrint('$_tag _saveTireKmDeltaMap(): saved -> $map');
    } catch (e) {
      debugPrint('$_tag _saveTireKmDeltaMap(): EXCEPTION -> $e');
    }
  }

  /// ⚡ INSTANT LOCAL RENDER: Loads and renders vehicle inspection UI immediately from Hive cache.
  Future<bool> _loadFromInspectionCache(String cachedJson) async {
    try {
      final map = jsonDecode(cachedJson) as Map<String, dynamic>;
      final modelMap = map['model'] as Map<String, dynamic>?;
      if (modelMap == null) return false;

      _serverHours = (modelMap['lastRecordedHours'] as num?)?.toDouble() ?? 0.0;
      _serverKm = (modelMap['lastRecordedMiles'] as num?)?.toDouble() ?? 0.0;
      debugPrint('$_tag _loadFromInspectionCache(): _serverHours=$_serverHours, _serverKm=$_serverKm');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('server_hours_${vehicleId.value}', _serverHours);
      await prefs.setDouble('server_km_${vehicleId.value}', _serverKm);

      hoursCtrl.text = _serverHours.round().toString();

      final mtRaw = modelMap['vehicleMileageType']?.toString().trim() ?? '';
      mileageType.value = mtRaw.isEmpty ? 'Both' : mtRaw;

      _serverKmUnit = _resolveVehicleDistUnit();
      HivePref.set(_vehicleDistUnitKey, _serverKmUnit);
      if (vehicleNumberCtrl.text.trim().isNotEmpty) {
        HivePref.set('vehicle_dist_unit_${vehicleNumberCtrl.text.trim()}', _serverKmUnit);
      }

      kmCtrl.text = _serverKm.round().toString();
      kmDisplayCtrl.text = _serverKm.round().toString();

      hours.value = hoursCtrl.text;
      km.value = kmCtrl.text;

      final cachedResponse = VehicleInspectionResponse.fromJson(map);
      inspectionResponse.value = cachedResponse;
      model = cachedResponse.model;
      // Vehicle images are handled in Edit Vehicle; only load inspected tyre images here.
      await loadInspectedTyreImages();

      if (model != null) {
        final axle = model!.axleConfig?.trim() ?? '';
        if (axle.isEmpty) {
          model!.axleConfig = _resolveFromAxleConfigId(model!.axleConfigId ?? 1);
        }
        vehicleNumberCtrl.text = model!.vehicleNumber.toString();
        final savedComment = await _loadVehicleComment();
        commentsCtrl.text = savedComment.isNotEmpty ? savedComment : (model?.comments ?? "");
      }

      final rawTires = model?.installedTires ?? [];
      final hoursDeltaMap = await _loadTireHoursDeltaMap();
      final kmDeltaMap = await _loadTireKmDeltaMap();
      final commentMap = await _loadTireCommentMap();

      final removedIds = <int>{
        ...removedTires.map((t) => t.tireId).whereType<int>(),
        ...pendingRemovePayloads.map((p) => p['tireId']).whereType<int>(),
        ...OfflineHiveService.getRecentlyRemovedTireIds(),
      };
      final removedPositions = <String>{
        ...removedTires.map((t) => (t.wheelPosition ?? '').trim().toUpperCase()).where((p) => p.isNotEmpty),
        ...pendingRemovePayloads.map((p) => (p['wheelPosition']?.toString() ?? '').trim().toUpperCase()).where((p) => p.isNotEmpty),
      };

      final filteredRawTires = rawTires.where((tire) {
        if (tire.tireId != null && removedIds.contains(tire.tireId)) {
          return false;
        }
        final pos = (tire.wheelPosition ?? '').trim().toUpperCase();
        if (pos.isNotEmpty && removedPositions.contains(pos)) {
          return false;
        }
        return true;
      }).toList();

      for (final tire in filteredRawTires) {
        final key = _tireKey(tire);
        final serverComment = (tire.comments ?? '').trim();
        if (serverComment.isNotEmpty && serverComment.toLowerCase() != 'rotation') {
          commentMap[key] = serverComment;
        }
      }
      await _saveTireCommentMap(commentMap);

      final adjustedTires = filteredRawTires.map((tire) {
        final key = _tireKey(tire);
        final hoursDelta = hoursDeltaMap[key] ?? 0.0;
        final kmDelta = kmDeltaMap[key] ?? 0.0;

        final serverComment = (tire.comments ?? '').trim();
        final finalComment = serverComment.toLowerCase() == 'rotation' ? (commentMap[key] ?? '') : serverComment;

        final origTread = tire.originalTread ?? 0.0;
        final currTread = tire.currentTreadDepth ?? 0.0;
        final removeAt = tire.removeAt ?? 0.0;
        double finalPercent = (tire.percentageWorn ?? 0.0).clamp(0.0, 100.0);
        if (origTread > 0 && currTread > 0) {
          if (currTread >= origTread) {
            finalPercent = 0.0;
          } else {
            final denom = (origTread - removeAt) > 0 ? (origTread - removeAt) : origTread;
            final effRem = (origTread - removeAt) > 0 ? removeAt : 0.0;
            finalPercent = ((1 - (currTread - effRem) / denom) * 100).clamp(0.0, 100.0);
          }
        }

        return InstalledTire(
          tireId: tire.tireId,
          tireSerialNo: tire.tireSerialNo,
          wheelPosition: tire.wheelPosition,
          currentTreadDepth: tire.currentTreadDepth,
          currentPressure: tire.currentPressure,
          currentHours: (tire.currentHours ?? 0.0) + hoursDelta,
          currentMiles: (tire.currentMiles ?? 0.0) + kmDelta,
          outsideTread: tire.outsideTread,
          middleTread: tire.middleTread,
          insideTread: tire.insideTread,
          originalTread: tire.originalTread,
          removeAt: tire.removeAt,
          dispositionId: tire.dispositionId,
          casingConditionId: tire.casingConditionId,
          wearConditionId: tire.wearConditionId,
          percentageWorn: finalPercent,
          sizeName: tire.sizeName,
          typeName: tire.typeName,
          manufacturerName: tire.manufacturerName,
          brandNo: tire.brandNo,
          mountedRimId: tire.mountedRimId,
          pressureType: tire.pressureType,
          vehicleId: tire.vehicleId,
          removalReasonId: tire.removalReasonId,
          comments: finalComment,
          inspectionDate: tire.inspectionDate,
          mileageType: tire.mileageType,
          imagesLocation: tire.imagesLocation,
          locationId: tire.locationId,
          parentAccountId: tire.parentAccountId,
          registeredDate: tire.registeredDate,
          manufacturerId: tire.manufacturerId,
          typeId: tire.typeId,
          sizeId: tire.sizeId,
          wearNonSkid: tire.wearNonSkid,
          createdBy: tire.createdBy,
        );
      }).toList();

      tires.assignAll(_sortedByPosition(adjustedTires));
      debugPrint('$_tag _loadFromInspectionCache(): rendered ${tires.length} tires instantly from cache');
      return true;
    } catch (e) {
      debugPrint('$_tag _loadFromInspectionCache(): PARSE EXCEPTION -> $e');
      return false;
    }
  }

  /// Non-blocking background loader for vehicle images so UI doesn't freeze.
  void _fetchVehicleImagesInBackground(int? myId) {
    Future.microtask(() async {
      try {
        if (isClosed) return;
        if (myId != null &&
            myId > 0 &&
            PendingInspectionGuard.pendingVehicleIds.contains(myId)) {
          await _fetchPendingVehicleImages();
        }
        if (isClosed) return;
        if (!uploadedImages.any((f) => f.path.startsWith('http'))) {
          if (myId != null && myId > 0) {
            final urls = await service.fetchVehicleImagesById(myId);
            if (urls.isNotEmpty && !isClosed) {
              _applyServerImages(urls.join(','));
            }
          }
        }
      } catch (e) {
        debugPrint('$_tag _fetchVehicleImagesInBackground error: $e');
      }
    });
  }

  // FETCH INSPECTION DATA
  Future<void> fetchInspectionData() async {
    _vicTrace('fetchInspectionData() START vehicleId=${vehicleId.value}', '\x1B[36m');
    pendingInstallPayloads.clear();
    debugPrint('$_tag fetchInspectionData() CALLED for vehicleId=${vehicleId.value}');
    if (isClosed) {
      debugPrint('$_tag fetchInspectionData(): controller already CLOSED -> aborting');
      return;
    }

    final currentId = int.tryParse(vehicleId.value);
    if (currentId != null && currentId < 0) {
      final stillTemp = OfflineHiveService.getVehicleById(currentId);
      if (stillTemp == null) {
        debugPrint('$_tag fetchInspectionData(): WARNING temp vehicle $currentId not found in Hive');
      }
    }

    // ⚡ FAST-PATH: Render immediately from cache so vehicle & tyre data show in < 50ms!
    final cachedJson = OfflineHiveService.getInspectionCache(vehicleId.value);
    _vicTrace('fetchInspectionData(): cachedJson=${cachedJson != null ? "${cachedJson.length} chars" : "NULL"}', '\x1B[33m');
    bool loadedFromCache = false;
    if (cachedJson != null) {
      loadedFromCache = await _loadFromInspectionCache(cachedJson);
      _vicTrace('fetchInspectionData(): _loadFromInspectionCache=$loadedFromCache', '\x1B[32m');
      if (loadedFromCache) {
        isLoading.value = false;
        debugPrint('$_tag fetchInspectionData(): loaded instantly from cache, background refresh continuing...');
      }
    }

    if (!loadedFromCache) {
      isLoading.value = true;
    }

    _vicTrace('fetchInspectionData(): calling getInspectionRecord(${vehicleId.value})...', '\x1B[34m');
    debugPrint('$_tag fetchInspectionData(): calling service.getInspectionRecord(${vehicleId.value})');
    final response = await service.getInspectionRecord(vehicleId.value);
    _vicTrace('fetchInspectionData(): getInspectionRecord RETURNED (response=${response != null}, didError=${response?.didError})', '\x1B[34m');
    isLoading.value = false;
    debugPrint('$_tag fetchInspectionData(): response=${response == null ? "NULL" : "received"}, didError=${response?.didError}');

    final online = await _checkOnline();
    isOffline.value = !online;
    debugPrint('$_tag fetchInspectionData(): connectivity check -> online=$online, isOffline.value=${isOffline.value}');

    if (response == null || response.didError == true) {
      if (!loadedFromCache) {
        final cached = OfflineHiveService.getInspectionCache(vehicleId.value);
        if (cached != null) {
          await _loadFromInspectionCache(cached);
        }
      }
      isLoading.value = false;
      return;
    }

    if (response.didError == false) {
      debugPrint('$_tag fetchInspectionData(): API SUCCESS -> using LIVE server response');
      inspectionResponse.value = response;
      model = response.model;

      if (model != null) {
        final axle = model!.axleConfig?.trim() ?? '';
        if (axle.isEmpty) {
          model!.axleConfig = _resolveFromAxleConfigId(model!.axleConfigId ?? 1);
          debugPrint('$_tag fetchInspectionData()[live]: axleConfig empty -> resolved to ${model!.axleConfig}');
        }

        // Vehicle images are handled in Edit Vehicle; skip Vehicle/ListImages & deep scan here.
      }

      if (isClosed) {
        debugPrint('$_tag fetchInspectionData()[live]: controller CLOSED mid-flight -> aborting');
        return;
      }

      vehicleNumberCtrl.text = model!.vehicleNumber.toString();
      final mt = model?.vehicleMileageType?.toString().trim() ?? '';
      mileageType.value = mt.isEmpty ? 'Both' : mt;
      debugPrint('$_tag fetchInspectionData()[live]: vehicleNumber=${model!.vehicleNumber}, mileageType=${mileageType.value}');

      final rawHours = model?.lastRecordedHours;
      hours.value = rawHours != null ? rawHours.round().toString() : "";
      hoursCtrl.text = hours.value;
      _serverHours = rawHours ?? 0.0;

      final rawKm = model?.lastRecordedMiles;
      _serverKm = rawKm ?? 0.0;
      _serverKmUnit = _resolveVehicleDistUnit();
      km.value = _serverKm > 0 ? _serverKm.round().toString() : "";
      kmCtrl.text = km.value;
      kmDisplayCtrl.text = km.value;
      debugPrint('$_tag fetchInspectionData()[live]: rawHours=$rawHours, rawKm=$rawKm -> _serverHours=$_serverHours, _serverKm=$_serverKm ($_serverKmUnit)');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('server_hours_${vehicleId.value}', _serverHours);
      await prefs.setDouble('server_km_${vehicleId.value}', _serverKm);

      if (commentsCtrl.text.trim().isEmpty) {
        commentsCtrl.text = model?.comments ?? "";
      }

      final rawTires = model?.installedTires ?? [];
      debugPrint('$_tag fetchInspectionData()[live]: server rawTires count = ${rawTires.length}');
      final hoursDeltaMap = await _loadTireHoursDeltaMap();
      final kmDeltaMap = await _loadTireKmDeltaMap();
      final commentMap = await _loadTireCommentMap();

      final removedIds = <int>{
        ...removedTires.map((t) => t.tireId).whereType<int>(),
        ...pendingRemovePayloads.map((p) => p['tireId']).whereType<int>(),
        ...OfflineHiveService.getRecentlyRemovedTireIds(),
      };
      final removedPositions = <String>{
        ...removedTires.map((t) => (t.wheelPosition ?? '').trim().toUpperCase()).where((p) => p.isNotEmpty),
        ...pendingRemovePayloads.map((p) => (p['wheelPosition']?.toString() ?? '').trim().toUpperCase()).where((p) => p.isNotEmpty),
      };

      final List<InstalledTire> pendingInstalledTires = [];
      final vIdIntForPending = int.tryParse(vehicleId.value) ?? 0;
      if (online &&
          vIdIntForPending > 0 &&
          PendingInspectionGuard.pendingVehicleIds.contains(vIdIntForPending)) {
        try {
          final parentAccIdStr = await SecureStorage.getParentAccountId();
          final accId = int.tryParse(parentAccIdStr ?? '0') ?? 0;
          if (accId > 0) {
            final pendingData = await service
                .getPendingInspections(accId)
                .timeout(const Duration(seconds: 4), onTimeout: () => null);
            if (pendingData is Map<String, dynamic>) {
              final entries = PendingInspectionEntry.fromModelJson(pendingData);
              final vIdInt = int.tryParse(vehicleId.value) ?? 0;
              final vNum = (model?.vehicleNumber?.toString() ?? '').trim().toUpperCase();
              for (final p in entries) {
                final matchVId = (vIdInt > 0 && p.vehicle?.vehicleId == vIdInt);
                final matchVNum = (vNum.isNotEmpty && p.vehicle?.vehicleNumber?.trim().toUpperCase() == vNum);
                if (matchVId || matchVNum) {
                  final pTires = <PendingInspectionTire>[
                    if (p.tire != null) p.tire!,
                    ...p.tiresList,
                  ];
                  for (final pt in pTires) {
                    final act = (pt.action ?? '').toLowerCase();
                    final dId = pt.dispositionId ?? 0;
                    final dispName = (pt.dispositionName ?? '').toLowerCase();
                    final isRem = act.contains('remove') ||
                        dId == 8 || dId == 1 || dId == 3 || dId == 4 || dId == 6 ||
                        dispName.contains('inventory') ||
                        dispName.contains('remove') ||
                        dispName.contains('scrap') ||
                        dispName.contains('repair') ||
                        (pt.removalReasonId != null && pt.removalReasonId! > 0);
                    if (isRem) {
                      if (pt.tireId != null && pt.tireId! > 0) removedIds.add(pt.tireId!);
                      final pos = (pt.wheelPosition ?? '').trim().toUpperCase();
                      if (pos.isNotEmpty) removedPositions.add(pos);
                    } else if (act.contains('install') || ((dId == 7 || dispName.contains('mount')) && !isRem)) {
                      final pos = (pt.wheelPosition ?? '').trim().toUpperCase();
                      final ptId = pt.tireId ?? 0;
                      if (!rawTires.any((rt) => (ptId > 0 && rt.tireId == ptId) || (pos.isNotEmpty && (rt.wheelPosition ?? '').trim().toUpperCase() == pos))) {
                        pendingInstalledTires.add(InstalledTire(
                          tireId: pt.tireId,
                          tireSerialNo: pt.tireSerialNo,
                          wheelPosition: pt.wheelPosition,
                          currentTreadDepth: pt.currentTreadDepth,
                          currentPressure: pt.currentPressure,
                          currentHours: pt.currentHours,
                          currentMiles: pt.currentMiles ?? 0.0,
                          outsideTread: pt.outsideTread,
                          middleTread: pt.middleTread ?? pt.currentTreadDepth,
                          insideTread: pt.insideTread,
                          dispositionId: pt.dispositionId ?? 7,
                          casingConditionId: pt.casingConditionId,
                          wearConditionId: pt.wearConditionId,
                          percentageWorn: pt.percentageWorn ?? 0.0,
                          sizeName: pt.sizeName,
                          typeName: pt.typeName,
                          manufacturerName: pt.manufacturerName,
                          brandNo: pt.brandNo,
                          vehicleId: pt.vehicleId ?? vIdInt,
                          action: "Install",
                        ));
                      }
                    }
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint('$_tag fetchInspectionData(): error cross-checking pending inspections -> $e');
        }
      }

      final filteredRawTires = rawTires.where((tire) {
        if (tire.tireId != null && removedIds.contains(tire.tireId)) {
          return false;
        }
        final pos = (tire.wheelPosition ?? '').trim().toUpperCase();
        if (pos.isNotEmpty && removedPositions.contains(pos)) {
          return false;
        }
        return true;
      }).toList();

      filteredRawTires.addAll(pendingInstalledTires);

      for (final tire in filteredRawTires) {
        final key = _tireKey(tire);
        final serverComment = (tire.comments ?? '').trim();
        if (serverComment.isNotEmpty && serverComment.toLowerCase() != 'rotation') {
          commentMap[key] = serverComment;
        }
      }
      await _saveTireCommentMap(commentMap);

      final adjustedTires = filteredRawTires.map((tire) {
        final key = _tireKey(tire);
        final hoursDelta = hoursDeltaMap[key] ?? 0.0;
        final kmDelta = kmDeltaMap[key] ?? 0.0;

        final serverComment = (tire.comments ?? '').trim();
        final finalComment = serverComment.toLowerCase() == 'rotation' ? (commentMap[key] ?? '') : serverComment;

        final origTreadO = tire.originalTread ?? 0.0;
        final currTreadO = tire.currentTreadDepth ?? 0.0;
        final removeAtO = tire.removeAt ?? 0.0;
        double finalPercentO = (tire.percentageWorn ?? 0.0).clamp(0.0, 100.0);
        if (origTreadO > 0 && currTreadO > 0) {
          if (currTreadO >= origTreadO) {
            finalPercentO = 0.0;
          } else {
            final denomO = (origTreadO - removeAtO) > 0 ? (origTreadO - removeAtO) : origTreadO;
            final effRemO = (origTreadO - removeAtO) > 0 ? removeAtO : 0.0;
            finalPercentO = ((1 - (currTreadO - effRemO) / denomO) * 100).clamp(0.0, 100.0);
          }
        }

        final int? tId = tire.tireId;
        final double? savedTo = tId != null ? TyreUnitHistory.getRawOutside(tId) : null;
        final double? savedTm = tId != null ? TyreUnitHistory.getRawMiddle(tId) : null;
        final double? savedTi = tId != null ? TyreUnitHistory.getRawInside(tId) : null;
        final double? savedP = tId != null ? TyreUnitHistory.getRawPressure(tId) : null;
        final double? savedMiles = tId != null ? TyreUnitHistory.getRawMiles(tId) : null;
        final double? savedWorn = tId != null ? TyreUnitHistory.getPercentageWorn(tId) : null;

        final treadSrc = tId != null ? TyreUnitHistory.getTreadUnit(tId) : null;
        final pressSrc = tId != null ? TyreUnitHistory.getPressureUnit(tId) : null;
        final distSrc = tId != null ? TyreUnitHistory.getDistanceUnit(tId) : null;

        final String effectiveDistSrc = distSrc ??
            ((mileageType.value.toLowerCase() == 'miles' || (mileageType.value == '2' && !MeasurementHelper.isMetric))
                ? 'Imperial'
                : ((mileageType.value.toLowerCase() == 'km' || (mileageType.value == '2' && MeasurementHelper.isMetric))
                ? 'Metric'
                : (MeasurementHelper.isMetric ? 'Metric' : 'Imperial')));
        if (tId != null && distSrc == null) {
          TyreUnitHistory.recordDistanceUnit(tId, effectiveDistSrc);
        }
        if (tId != null && savedMiles == null && tire.currentMiles != null && tire.currentMiles! > 0) {
          TyreUnitHistory.recordRawReadings(tireId: tId, miles: tire.currentMiles, distanceUnit: effectiveDistSrc);
        }

        final double outT = savedTo ?? MeasurementHelper.toDisplayTread(tire.outsideTread ?? 0.0, sourceUnit: treadSrc);
        final double midT = savedTm ?? MeasurementHelper.toDisplayTread(tire.middleTread ?? 0.0, sourceUnit: treadSrc);
        final double inT = savedTi ?? MeasurementHelper.toDisplayTread(tire.insideTread ?? 0.0, sourceUnit: treadSrc);
        final double currDepth = (outT > 0 && midT > 0 && inT > 0) ? (outT + midT + inT) / 3 : (midT > 0 ? midT : outT);
        final double press = savedP ?? MeasurementHelper.toDisplayPressure(tire.currentPressure ?? 0.0, sourceUnit: pressSrc);
        final double baseMiles = (savedMiles != null && savedMiles > 0)
            ? (savedMiles + kmDelta)
            : ((tire.currentMiles ?? 0.0) + kmDelta);
        final double miles = (MeasurementHelper.isImperial && (savedMiles != null || effectiveDistSrc.toLowerCase() == 'imperial' || effectiveDistSrc.toLowerCase() == 'miles'))
            ? baseMiles
            : MeasurementHelper.toDisplayDistance(baseMiles, sourceUnit: effectiveDistSrc);
        final double worn = (origTreadO > 0 && currDepth > 0)
            ? (currDepth >= origTreadO
                ? 0.0
                : (((origTreadO - removeAtO) > 0)
                    ? ((1 - (currDepth - ((origTreadO - removeAtO) > 0 ? removeAtO : 0.0)) / (origTreadO - removeAtO)) * 100).clamp(0.0, 100.0)
                    : ((1 - currDepth / origTreadO) * 100).clamp(0.0, 100.0)))
            : (savedWorn ?? finalPercentO);

        return InstalledTire(
          tireId: tire.tireId,
          tireSerialNo: tire.tireSerialNo,
          wheelPosition: tire.wheelPosition,
          currentTreadDepth: currDepth,
          currentPressure: press,
          currentHours: (tire.currentHours ?? 0.0) + hoursDelta,
          currentMiles: miles,
          outsideTread: outT,
          middleTread: midT,
          insideTread: inT,
          originalTread: tire.originalTread,
          removeAt: tire.removeAt,
          dispositionId: tire.dispositionId,
          casingConditionId: tire.casingConditionId,
          wearConditionId: tire.wearConditionId,
          percentageWorn: worn,
          sizeName: tire.sizeName,
          typeName: tire.typeName,
          manufacturerName: tire.manufacturerName,
          brandNo: tire.brandNo,
          mountedRimId: tire.mountedRimId,
          pressureType: tire.pressureType,
          vehicleId: tire.vehicleId,
          removalReasonId: tire.removalReasonId,
          comments: finalComment,
          inspectionDate: tire.inspectionDate,
          mileageType: tire.mileageType,
          imagesLocation: tire.imagesLocation,
          locationId: tire.locationId,
          parentAccountId: tire.parentAccountId,
          registeredDate: tire.registeredDate,
          manufacturerId: tire.manufacturerId,
          typeId: tire.typeId,
          sizeId: tire.sizeId,
          wearNonSkid: tire.wearNonSkid,
          createdBy: tire.createdBy,
        );
      }).toList();

      final serverTireIds = adjustedTires.map((t) => t.tireId).toSet();

      if (isClosed) return;
      final localOnlyTires = <InstalledTire>[];
      for (final t in tires) {
        if (t.tireId == null) continue;
        if (removedIds.contains(t.tireId)) continue;
        final pos = (t.wheelPosition ?? '').trim().toUpperCase();
        if (pos.isNotEmpty && removedPositions.contains(pos)) continue;
        if (serverTireIds.contains(t.tireId)) continue;

        if (t.tireId! < 0) {
          final realId = prefs.getInt('tyre_real_id_${t.tireId}');
          if (realId != null && realId > 0 && serverTireIds.contains(realId)) {
            continue;
          }
        }

        final samePositionInServer = adjustedTires.any(
              (s) => s.wheelPosition != null && s.wheelPosition!.isNotEmpty && s.wheelPosition == t.wheelPosition,
        );
        if (samePositionInServer) {
          continue;
        }
        localOnlyTires.add(t);
      }

      // ── Also restore any locally installed / cached tires from Hive cache (when user left screen and returned) ──
      try {
        final cachedJsonForLocal = OfflineHiveService.getInspectionCache(vehicleId.value) ??
            (vehicleNumberCtrl.text.trim().isNotEmpty
                ? OfflineHiveService.getInspectionCache(vehicleNumberCtrl.text.trim())
                : null);
        if (cachedJsonForLocal != null) {
          final cMap = jsonDecode(cachedJsonForLocal) as Map<String, dynamic>;
          final cModel = cMap['model'] as Map<String, dynamic>?;
          final cTiresList = cModel?['installedTires'] as List<dynamic>? ?? [];
          for (final raw in cTiresList) {
            if (raw is! Map) continue;
            final ct = Map<String, dynamic>.from(raw);
            final rawId = ct['tireId'];
            final int? cTireId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
            if (cTireId != null && removedIds.contains(cTireId)) continue;

            final cWheelPos = (ct['wheelPosition']?.toString() ?? '').trim().toUpperCase();
            if (cWheelPos.isNotEmpty && removedPositions.contains(cWheelPos)) continue;

            if (cTireId != null && cTireId > 0 && serverTireIds.contains(cTireId)) {
              continue;
            }
            if (cTireId != null && cTireId < 0) {
              final realId = prefs.getInt('tyre_real_id_$cTireId');
              if (realId != null && realId > 0 && serverTireIds.contains(realId)) {
                continue;
              }
            }

            final samePositionInServer = adjustedTires.any(
                  (s) => (s.wheelPosition ?? '').trim().toUpperCase() == cWheelPos && cWheelPos.isNotEmpty,
            );
            if (samePositionInServer) continue;

            final alreadyInLocal = localOnlyTires.any(
                  (l) => (cTireId != null && l.tireId == cTireId) ||
                  (cWheelPos.isNotEmpty && (l.wheelPosition ?? '').trim().toUpperCase() == cWheelPos),
            );
            if (alreadyInLocal) continue;

            final cAction = ct['action']?.toString() ?? 'Install';
            final localTire = InstalledTire.fromJson(ct)..action = cAction;
            localOnlyTires.add(localTire);
          }
        }
      } catch (e) {
        debugPrint('$_tag fetchInspectionData(): error restoring cached local tires: $e');
      }
      debugPrint('$_tag fetchInspectionData()[live]: localOnlyTires (offline-created or locally installed) count = ${localOnlyTires.length}');

      tires.assignAll(_sortedByPosition([...adjustedTires, ...localOnlyTires]));
      _vicTrace('fetchInspectionData()[live]: tires.assignAll DONE (${tires.length} tires)', '\x1B[35m');
      debugPrint('$_tag fetchInspectionData()[live]: tires list FINAL count = ${tires.length}');
      await loadInspectedTyreImages();
      _vicTrace('fetchInspectionData()[live]: loadInspectedTyreImages DONE (${inspectedTyreImages.length} imgs)', '\x1B[35m');
      await _saveTireHoursDeltaMap({});
      await _saveTireKmDeltaMap({});
      debugPrint('$_tag fetchInspectionData()[live]: delta maps CLEARED (server is now source of truth)');
    }
  }

  String? _prevPressLabel;
  String? _prevMeasureLabel;

  void _recomputeDisplayUnits() {
    syncKmDisplay();

    if (tires.isNotEmpty) {
      final updatedList = tires.map((tire) {
        final tId = tire.tireId;
        final savedMiles = tId != null ? TyreUnitHistory.getRawMiles(tId) : null;
        final distSrc = tId != null ? TyreUnitHistory.getDistanceUnit(tId) : null;
        final String effectiveDistSrc = distSrc ??
            ((mileageType.value.toLowerCase() == 'miles' || mileageType.value == '2')
                ? 'Imperial'
                : ((mileageType.value.toLowerCase() == 'km' || mileageType.value == '1')
                ? 'Metric'
                : 'Imperial'));
        final baseMiles = (savedMiles != null && savedMiles > 0)
            ? savedMiles
            : (tire.currentMiles ?? 0.0);
        final double convertedMiles = (MeasurementHelper.isImperial && (savedMiles != null || effectiveDistSrc.toLowerCase() == 'imperial' || effectiveDistSrc.toLowerCase() == 'miles'))
            ? baseMiles
            : MeasurementHelper.toDisplayDistance(baseMiles, sourceUnit: effectiveDistSrc);

        // 🔧 FIX (vehicle inspection par KPA/PSI galat): tyre inspection screen
        // hamesha ORIGINAL tyre + raw history se ek hi baar convert karti hai.
        // Yaha raw na milne par pehle already-converted `tire.*` ko dobara
        // convert kiya jata tha (compounding). Ab:
        //  - raw (id ya serial se) mile -> raw + uski saved unit se convert
        //  - raw na mile -> `tire.*` ko PICHLI preference unit se naye me convert
        final String? sn = tire.tireSerialNo;
        final bool hasSn = sn != null && sn.isNotEmpty;
        double? rawOf(double? Function(dynamic) g) =>
            (tId != null ? g(tId) : null) ?? (hasSn ? g(sn) : null);
        String? unitOf(String? Function(dynamic) g) =>
            (tId != null ? g(tId) : null) ?? (hasSn ? g(sn) : null);

        final rawTo = rawOf(TyreUnitHistory.getRawOutside);
        final rawTm = rawOf(TyreUnitHistory.getRawMiddle);
        final rawTi = rawOf(TyreUnitHistory.getRawInside);
        final rawPress = rawOf(TyreUnitHistory.getRawPressure);
        final treadSrc = unitOf(TyreUnitHistory.getTreadUnit);
        final pressSrc = unitOf(TyreUnitHistory.getPressureUnit);

        final bool haveTreadRaw = rawTo != null && rawTo > 0 &&
            rawTm != null && rawTm > 0 && rawTi != null && rawTi > 0;
        final bool havePressRaw = rawPress != null && rawPress > 0;

        final baseTo = haveTreadRaw ? rawTo : (tire.outsideTread ?? 0.0);
        final baseTm = haveTreadRaw ? rawTm : (tire.middleTread ?? 0.0);
        final baseTi = haveTreadRaw ? rawTi : (tire.insideTread ?? 0.0);
        final basePress = havePressRaw ? rawPress : (tire.currentPressure ?? 0.0);

        final String? treadFrom = haveTreadRaw ? treadSrc : _prevMeasureLabel;
        final String? pressFrom = havePressRaw ? pressSrc : _prevPressLabel;

        final double convTo = MeasurementHelper.toDisplayTread(baseTo, sourceUnit: treadFrom);
        final double convTm = MeasurementHelper.toDisplayTread(baseTm, sourceUnit: treadFrom);
        final double convTi = MeasurementHelper.toDisplayTread(baseTi, sourceUnit: treadFrom);
        final double convPress = MeasurementHelper.toDisplayPressure(basePress, sourceUnit: pressFrom);
        final double avgTread = (convTo + convTm + convTi) / 3;

        return InstalledTire(
          tireId: tire.tireId,
          tireSerialNo: tire.tireSerialNo,
          wheelPosition: tire.wheelPosition,
          currentTreadDepth: avgTread,
          currentPressure: convPress,
          currentHours: tire.currentHours,
          currentMiles: convertedMiles,
          outsideTread: convTo,
          middleTread: convTm,
          insideTread: convTi,
          originalTread: tire.originalTread,
          removeAt: tire.removeAt,
          dispositionId: tire.dispositionId,
          casingConditionId: tire.casingConditionId,
          wearConditionId: tire.wearConditionId,
          percentageWorn: tire.percentageWorn,
          sizeName: tire.sizeName,
          typeName: tire.typeName,
          manufacturerName: tire.manufacturerName,
          brandNo: tire.brandNo,
          mountedRimId: tire.mountedRimId,
          pressureType: tire.pressureType,
          vehicleId: tire.vehicleId,
          removalReasonId: tire.removalReasonId,
          comments: tire.comments,
          inspectionDate: tire.inspectionDate,
          mileageType: tire.mileageType,
          imagesLocation: tire.imagesLocation,
          locationId: tire.locationId,
          parentAccountId: tire.parentAccountId,
          registeredDate: tire.registeredDate,
          manufacturerId: tire.manufacturerId,
          typeId: tire.typeId,
          sizeId: tire.sizeId,
          wearNonSkid: tire.wearNonSkid,
          createdBy: tire.createdBy,
        );
      }).toList();
      tires.assignAll(updatedList);
      tires.refresh();
    }
    _prevPressLabel = MeasurementHelper.pressureLabel;
    _prevMeasureLabel = MeasurementHelper.isMetric ? 'Metric' : 'Imperial';
  }

  // UPDATE HOURS BACK NAVIGATION HANDLING
  Future<void> goToUpdateHours() async {
    if (await _blockedByPendingApproval(PendingBlockedAction.updateHours)) return;
    final double baseHours = double.tryParse(hoursCtrl.text.isNotEmpty ? hoursCtrl.text : hours.value) ?? _serverHours;
    final double baseKm = _serverKm > 0 ? _serverKm : (double.tryParse(kmCtrl.text) ?? (model?.lastRecordedMiles ?? 0.0));
    final String baseKmUnit = _resolveVehicleDistUnit();
    debugPrint('$_tag goToUpdateHours(): navigating with baseHours=$baseHours, baseKm=$baseKm ($baseKmUnit)');

    final result = await Get.to(
          () => UpdateHoursView(),
      arguments: {
        'vehicleId': int.parse(vehicleId.value),
        'isInspectionFlow': true,
        'currentHours': baseHours,
        'currentKm': baseKm,
        'distUnit': baseKmUnit,
      },
    );
    debugPrint('$_tag goToUpdateHours(): returned result = $result (${result.runtimeType})');

    if (result != null) {
      double? newHours;
      double? newKm;
      double? hoursDeltaForTiresOverride;
      double? kmDeltaForTiresOverride;

      bool kmWasUpdated = false;
      String? returnedDistUnit;
      if (result is Map) {
        final rawHours = result['hours'] ?? result['currentHours'];
        final rawKm = result['km'] ?? result['currentMiles'];
        newHours = (rawHours as num?)?.toDouble();
        newKm = (rawKm as num?)?.toDouble();
        kmWasUpdated = result['kmWasUpdated'] == true;
        returnedDistUnit = result['distUnit']?.toString();
        hoursDeltaForTiresOverride = (result['hoursDeltaForTires'] as num?)?.toDouble();
        kmDeltaForTiresOverride = (result['kmDeltaForTires'] as num?)?.toDouble();
        final sd = result['surveyDate']?.toString().trim();
        if (sd != null && sd.isNotEmpty && DateTime.tryParse(sd) != null) {
          surveyDateIso = sd;
          debugPrint('$_tag goToUpdateHours(): surveyDateIso set -> $surveyDateIso');
        }
      } else if (result is double) {
        newHours = result;
      } else if (result is int) {
        newHours = result.toDouble();
      } else if (result is String) {
        newHours = double.tryParse(result);
      }
      debugPrint('$_tag goToUpdateHours(): parsed -> newHours=$newHours, newKm=$newKm (kmWasUpdated=$kmWasUpdated), hoursDeltaForTiresOverride=$hoursDeltaForTiresOverride, kmDeltaForTiresOverride=$kmDeltaForTiresOverride');

      if (newHours != null) {
        hours.value = newHours.round().toString();
        hoursCtrl.text = newHours.round().toString();
        model?.lastRecordedHours = newHours;
        _serverHours = newHours;
      }
      if (newKm != null && kmWasUpdated) {
        km.value = newKm.round().toString();
        kmCtrl.text = newKm.round().toString();
        model?.lastRecordedMiles = newKm;
        _serverKm = newKm;
        _serverKmUnit = (returnedDistUnit != null && returnedDistUnit.isNotEmpty)
            ? returnedDistUnit
            : MeasurementHelper.distanceLabel;
        HivePref.set(_vehicleDistUnitKey, _serverKmUnit);
        if (vehicleNumberCtrl.text.trim().isNotEmpty) {
          HivePref.set('vehicle_dist_unit_${vehicleNumberCtrl.text.trim()}', _serverKmUnit);
        }
        syncKmDisplay();
      }

      final double hoursDiff = hoursDeltaForTiresOverride != null
          ? (hoursDeltaForTiresOverride > 0 ? hoursDeltaForTiresOverride : 0.0)
          : ((newHours != null && newHours > baseHours) ? (newHours - baseHours) : 0.0);

      // ✅ ROOT-CAUSE FIX: tyre ke currentMiles ko DISPLAY-unit delta se
      // hi update karo (jo UpdateHoursController se 'kmDeltaForTires' ke
      // roop me aata hai — seedha screen par jo farak dikha, e.g. 10).
      final double fallbackKmDiff = (newKm != null && newKm > baseKm) ? (newKm - baseKm) : 0.0;
      final double kmDiff = (kmDeltaForTiresOverride != null && kmDeltaForTiresOverride > 0)
          ? kmDeltaForTiresOverride
          : fallbackKmDiff;

      debugPrint('$_tag goToUpdateHours(): COMPUTED hoursDiff=$hoursDiff, kmDiff=$kmDiff (source=${kmDeltaForTiresOverride != null ? "override" : "fallback"})');

      if (hoursDiff > 0 || kmDiff > 0) {
        debugPrint('$_tag goToUpdateHours(): applying delta to tires...');
        await _applyDeltaToTires(hoursDiff: hoursDiff, kmDiff: kmDiff);
        if (newHours != null) _serverHours = newHours;
        if (newKm != null) _serverKm = newKm;
      } else {
        debugPrint('$_tag goToUpdateHours(): no positive diff -> tires NOT updated');
      }
    } else {
      debugPrint('$_tag goToUpdateHours(): result was NULL -> user likely cancelled, no changes applied');
    }
  }

  String _tireKey(InstalledTire tire) =>
      '${tire.tireId ?? 0}_${tire.wheelPosition ?? ""}';


  List<InstalledTire> _sortedByPosition(List<InstalledTire> list) {
    final sorted = List<InstalledTire>.from(list);
    sorted.sort((a, b) {
      final pa = a.wheelPosition ?? '';
      final pb = b.wheelPosition ?? '';
      final na = int.tryParse(pa.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999;
      final nb = int.tryParse(pb.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999;
      if (na != nb) return na.compareTo(nb);
      return pa.compareTo(pb);
    });
    return sorted;
  }

  String _resolveFromAxleConfigId(int axleConfigId) {
    switch (axleConfigId) {
      case 1:
        return "22";
      case 2:
        return "222";
      case 3:
        return "2222";
      case 4:
        return "22222";
      case 5:
        return "24";
      case 6:
        return "224";
      case 7:
        return "2";
      case 8:
        return "242";
      case 9:
        return "24";
      default:
        return "22";
    }
  }

  String _resolveSizeName(int sizeId, String? currentName) {
    if (currentName != null && currentName.trim().isNotEmpty) return currentName.trim();
    if (sizeId <= 0) return '';
    try {
      final sizes = OfflineHiveService.getTireSizes();
      for (final s in sizes) {
        final id = s['tireSizeId'] ?? s['sizeId'];
        if (id == sizeId) {
          final name = s['tireSizeName'] ?? s['sizeName'];
          if (name != null && name.toString().trim().isNotEmpty) {
            return name.toString().trim();
          }
        }
      }
    } catch (_) {}
    return '';
  }

  String _resolveTypeName(int typeId, String? currentName) {
    if (currentName != null && currentName.trim().isNotEmpty) return currentName.trim();
    if (typeId <= 0) return '';
    try {
      final types = OfflineHiveService.getTireTypes();
      for (final t in types) {
        final id = t['typeId'] ?? t['tireTypeId'];
        if (id == typeId) {
          final name = t['typeName'] ?? t['tireTypeName'];
          if (name != null && name.toString().trim().isNotEmpty) {
            return name.toString().trim();
          }
        }
      }
    } catch (_) {}
    return '';
  }

  String _resolveManufacturerName(int mfgId, String? currentName) {
    if (currentName != null && currentName.trim().isNotEmpty) return currentName.trim();
    if (mfgId <= 0) return '';
    try {
      final mfgs = OfflineHiveService.getTireManufacturers();
      for (final m in mfgs) {
        final id = m['manufacturerId'] ?? m['id'];
        if (id == mfgId) {
          final name = m['manufacturerName'] ?? m['name'];
          if (name != null && name.toString().trim().isNotEmpty) {
            return name.toString().trim();
          }
        }
      }
    } catch (_) {}
    return '';
  }

  void addInstalledTyreLocally(TyreModel tyreModel, {Map<String, dynamic>? installPayload}) {
    debugPrint('$_tag addInstalledTyreLocally(): CALLED for tireId=${tyreModel.tireId}, position=${tyreModel.wheelPosition}');
    try {
      if (installPayload != null) {
        pendingInstallPayloads.removeWhere(
              (p) => p['wheelPosition']?.toString().trim() == tyreModel.wheelPosition?.trim(),
        );
        pendingInstallPayloads.add(installPayload);
        debugPrint('$_tag addInstalledTyreLocally(): stored pending install payload for tireId=${tyreModel.tireId}. pendingInstallPayloads.length=${pendingInstallPayloads.length}');
      }

      tires.removeWhere(
            (t) => t.wheelPosition?.trim() == tyreModel.wheelPosition?.trim(),
      );

      final treadSrc = (tyreModel.tireId != null ? TyreUnitHistory.getTreadUnit(tyreModel.tireId) : null) ??
          (tyreModel.tireSerialNo != null ? TyreUnitHistory.getTreadUnit(tyreModel.tireSerialNo!) : null);
      final double rawOrigT = tyreModel.originalTread ?? 0.0;
      final double rawRemAt = tyreModel.removeAt ?? 0.0;
      final double origT = MeasurementHelper.toDisplayTread(rawOrigT, sourceUnit: treadSrc);
      final double remAt = MeasurementHelper.toDisplayTread(rawRemAt, sourceUnit: treadSrc);
      final double currT = tyreModel.currentTreadDepth ?? 0.0;
      final double effectiveOrig = origT > 0 ? origT : currT;

      double pct;
      if (effectiveOrig > 0 && currT >= effectiveOrig) {
        pct = 0.0;
      } else if (tyreModel.percentageWorn != null && tyreModel.percentageWorn! >= 0) {
        pct = tyreModel.percentageWorn!.clamp(0.0, 100.0);
      } else if (tyreModel.tireId != null && TyreUnitHistory.getPercentageWorn(tyreModel.tireId) != null && TyreUnitHistory.getPercentageWorn(tyreModel.tireId)! >= 0) {
        pct = TyreUnitHistory.getPercentageWorn(tyreModel.tireId)!.clamp(0.0, 100.0);
      } else if (tyreModel.tireSerialNo != null && TyreUnitHistory.getPercentageWorn(tyreModel.tireSerialNo!) != null && TyreUnitHistory.getPercentageWorn(tyreModel.tireSerialNo!)! >= 0) {
        pct = TyreUnitHistory.getPercentageWorn(tyreModel.tireSerialNo!)!.clamp(0.0, 100.0);
      } else {
        final double denom = (effectiveOrig - remAt) > 0 ? (effectiveOrig - remAt) : effectiveOrig;
        final double effRem = (effectiveOrig - remAt) > 0 ? remAt : 0.0;
        pct = (denom > 0 && currT > 0)
            ? ((1 - (currT - effRem) / denom) * 100).clamp(0.0, 100.0)
            : 0.0;
      }

      final String resolvedSize = _resolveSizeName(tyreModel.sizeId ?? 0, tyreModel.sizeName);
      final String resolvedType = _resolveTypeName(tyreModel.typeId ?? 0, tyreModel.typeName);
      final String resolvedMfg = _resolveManufacturerName(tyreModel.manufacturerId ?? 0, tyreModel.manufacturerName);

      final installedTire = InstalledTire(
        tireId: tyreModel.tireId,
        tireSerialNo: tyreModel.tireSerialNo,
        wheelPosition: tyreModel.wheelPosition,
        currentTreadDepth: tyreModel.currentTreadDepth,
        currentPressure: tyreModel.currentPressure,
        currentHours: tyreModel.currentHours,
        currentMiles: tyreModel.currentMiles ?? 0.0,
        outsideTread: tyreModel.outsideTread,
        middleTread: tyreModel.middleTread ?? tyreModel.currentTreadDepth,
        insideTread: tyreModel.insideTread,
        dispositionId: tyreModel.dispositionId,
        casingConditionId: tyreModel.casingConditionId,
        wearConditionId: tyreModel.wearConditionId,
        percentageWorn: pct,
        originalTread: tyreModel.originalTread,
        sizeId: tyreModel.sizeId ?? 0,
        sizeName: resolvedSize,
        typeId: tyreModel.typeId ?? 0,
        typeName: resolvedType,
        manufacturerId: tyreModel.manufacturerId ?? 0,
        manufacturerName: resolvedMfg,
        registeredDate: tyreModel.registeredDate ?? DateTime.now().toIso8601String(),
        removeAt: tyreModel.removeAt,
        brandNo: tyreModel.brandNo,
        comments: tyreModel.comments,
        vehicleId: int.tryParse(vehicleId.value),
        action: "Install",
      );

      final existingIdx = tires.indexWhere(
            (t) => (tyreModel.wheelPosition != null && tyreModel.wheelPosition!.isNotEmpty && t.wheelPosition == tyreModel.wheelPosition) ||
            (t.tireId != null && t.tireId == tyreModel.tireId),
      );
      if (existingIdx != -1) {
        tires[existingIdx] = installedTire;
      } else {
        tires.add(installedTire);
      }
      tires.refresh();
      patchTireInCache(installedTire);
      debugPrint('$_tag addInstalledTyreLocally(): tire UPDATED/ADDED locally. tires.length now = ${tires.length}');
    } catch (e) {
      debugPrint('$_tag addInstalledTyreLocally(): EXCEPTION -> $e');
    }
  }

  void removeInstalledTyreLocally(RemoveTyreModel m, {Map<String, dynamic>? payload}) {
    debugPrint('$_tag removeInstalledTyreLocally(): CALLED for tireId=${m.tireId}, position=${m.wheelPosition}');
    try {
      if (payload != null) {
        pendingRemovePayloads.removeWhere((p) => p['tireId'] == m.tireId);
        pendingRemovePayloads.add(payload);
        debugPrint('$_tag removeInstalledTyreLocally(): stored pending remove payload for tireId=${m.tireId}. pendingRemovePayloads.length=${pendingRemovePayloads.length}');
      }

      final existing = tires.firstWhereOrNull(
            (t) => t.tireId == m.tireId || (m.wheelPosition.isNotEmpty && t.wheelPosition?.trim() == m.wheelPosition.trim()),
      );

      final removedTire = InstalledTire(
        tireId: m.tireId,
        locationId: m.locationId != 0 ? m.locationId : existing?.locationId,
        parentAccountId: m.parentAccountId != 0 ? m.parentAccountId : existing?.parentAccountId,
        tireSerialNo: m.tireSerialNo.isNotEmpty ? m.tireSerialNo : existing?.tireSerialNo,
        brandNo: m.brandNumber.isNotEmpty ? m.brandNumber : existing?.brandNo,
        wheelPosition: m.wheelPosition.isNotEmpty ? m.wheelPosition : existing?.wheelPosition,
        currentHours: m.currentHours > 0 ? m.currentHours : existing?.currentHours,
        currentMiles: m.currentMiles > 0 ? m.currentMiles : existing?.currentMiles,
        outsideTread: m.outsideTread > 0 ? m.outsideTread : existing?.outsideTread,
        middleTread: m.middleTread > 0 ? m.middleTread : existing?.middleTread,
        insideTread: m.insideTread > 0 ? m.insideTread : existing?.insideTread,
        currentTreadDepth: m.currentTreadDepth > 0 ? m.currentTreadDepth : existing?.currentTreadDepth,
        currentPressure: m.currentPressure > 0 ? m.currentPressure : existing?.currentPressure,
        originalTread: m.originalTread > 0 ? m.originalTread : existing?.originalTread,
        removeAt: m.removeAt > 0 ? m.removeAt : existing?.removeAt,
        dispositionId: m.dispositionId != 0 ? m.dispositionId : existing?.dispositionId,
        dispositionName: m.dispositionName.isNotEmpty ? m.dispositionName : (existing?.dispositionName ?? ''),
        removalReasonId: m.removalReasonId != 0 ? m.removalReasonId : existing?.removalReasonId,
        comments: m.comments.isNotEmpty ? m.comments : existing?.comments,
        action: "Remove",
        inspectionDate: DateTime.now().toIso8601String(),
        vehicleId: m.vehicleId != 0 ? m.vehicleId : existing?.vehicleId,
        sizeId: existing?.sizeId,
        sizeName: existing?.sizeName,
        typeId: existing?.typeId,
        typeName: existing?.typeName,
        manufacturerId: existing?.manufacturerId,
        manufacturerName: existing?.manufacturerName,
        imagesLocation: existing?.imagesLocation,
      );

      removedTires.removeWhere((t) => t.tireId == m.tireId);
      removedTires.add(removedTire);

      tires.removeWhere(
            (t) => t.tireId == m.tireId || (m.wheelPosition.isNotEmpty && t.wheelPosition?.trim() == m.wheelPosition.trim()),
      );
      tires.refresh();

      if (m.tireId > 0) {
        OfflineHiveService.markTireAsRecentlyRemoved(m.tireId);
      }
      _removeTireFromInspectionCache(m.tireId);

      debugPrint('$_tag removeInstalledTyreLocally(): tire removed from tires. Remaining tires=${tires.length}, removedTires=${removedTires.length}');
    } catch (e) {
      debugPrint('$_tag removeInstalledTyreLocally() EXCEPTION -> $e');
    }
  }

  Future<void> _removeTireFromInspectionCache(int tireId) async {
    try {
      final cacheKey = vehicleId.value;
      final cached = OfflineHiveService.getInspectionCache(cacheKey);
      if (cached == null) return;
      final map = jsonDecode(cached) as Map<String, dynamic>;
      final modelMap = map['model'] as Map<String, dynamic>?;
      if (modelMap == null) return;
      final installed = modelMap['installedTires'] as List<dynamic>?;
      if (installed == null) return;
      installed.removeWhere((t) => t is Map && (t['tireId'] == tireId || t['tireId']?.toString() == tireId.toString()));
      modelMap['installedTires'] = installed;
      map['model'] = modelMap;
      await OfflineHiveService.saveInspectionCache(cacheKey, jsonEncode(map));
    } catch (_) {}
  }

  String _getTireAction(InstalledTire tire) {
    if (tire.action != null && tire.action!.isNotEmpty) {
      return tire.action!;
    }
    return "Inspect";
  }

  /// Builds a single tire record in the shape expected inside
  /// inspectionList/tireList for SaveVehicleFootPrintDetails_Temp /
  /// SaveVehicleFootPrintDetails, for ONE tire. Called once per tire so we
  /// can batch every installed tyre's record into a single request (see
  /// _buildFootprintDetailsPayload below).
  Map<String, dynamic> _buildTireRecord({
    required InstalledTire tire,
    required String action,
    required int resolvedVehicleIdForInsp,
    required int resolvedTireIdForInsp,
    required double submittedHours,
    required double submittedKm,
    required String resolvedComment,
    required String imagesLocation,
    required int locationIdInt,
    required int parentAccountIdInt,
    required String requestorName,
    required String nowIso,
  }) {
    final String resolvedSize = _resolveSizeName(tire.sizeId ?? 0, tire.sizeName);
    final String resolvedType = _resolveTypeName(tire.typeId ?? 0, tire.typeName);
    final String resolvedMfg = _resolveManufacturerName(tire.manufacturerId ?? 0, tire.manufacturerName);

    String mileageTypeStr = "Hours";
    final rawMt = model?.vehicleMileageType?.toString().trim() ?? "";
    if (rawMt.toLowerCase() == "kilometers" || rawMt.toLowerCase() == "km") {
      mileageTypeStr = "Kilometers";
    } else if (rawMt == "2" || rawMt.toLowerCase() == "miles") {
      mileageTypeStr = MeasurementHelper.isMetric ? "Kilometers" : "Miles";
    } else if (rawMt == "1" || rawMt == "3" || rawMt.toLowerCase() == "hours") {
      mileageTypeStr = "Hours";
    } else if (rawMt.isNotEmpty) {
      mileageTypeStr = rawMt;
    }

    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    final parsedWear = toInt(tire.wearConditionId);
    int? resolvedWearId = (parsedWear != null && parsedWear > 0) ? parsedWear : null;

    final parsedCasing = toInt(tire.casingConditionId);
    int? resolvedCasingId = (parsedCasing != null && parsedCasing > 0) ? parsedCasing : null;

    String finalComment = resolvedComment.trim();
    if (finalComment.isEmpty && tire.comments != null && tire.comments!.trim().isNotEmpty) {
      finalComment = tire.comments!.trim();
    }

    if (resolvedWearId == null || resolvedCasingId == null || finalComment.isEmpty) {
      final cachedStr = OfflineHiveService.getTireDetailCache(resolvedTireIdForInsp);
      if (cachedStr != null) {
        try {
          final decoded = jsonDecode(cachedStr) as Map<String, dynamic>;
          final m = decoded['model'] as Map<String, dynamic>?;
          if (m != null) {
            if (resolvedWearId == null && m['wearConditionId'] != null) {
              final w = toInt(m['wearConditionId']);
              if (w != null && w > 0) resolvedWearId = w;
            }
            if (resolvedCasingId == null && m['casingConditionId'] != null) {
              final c = toInt(m['casingConditionId']);
              if (c != null && c > 0) resolvedCasingId = c;
            }
            if (finalComment.isEmpty && m['comments'] != null) {
              finalComment = m['comments'].toString().trim();
            }
          }
        } catch (_) {}
      }
    }

    if (resolvedWearId == null || resolvedCasingId == null || finalComment.isEmpty) {
      final hiveTyre = OfflineHiveService.getTyreById(resolvedTireIdForInsp);
      if (hiveTyre != null) {
        if (resolvedWearId == null && hiveTyre.wearConditionId != null) {
          final w = toInt(hiveTyre.wearConditionId);
          if (w != null && w > 0) resolvedWearId = w;
        }
        if (resolvedCasingId == null && hiveTyre.casingConditionId != null) {
          final c = toInt(hiveTyre.casingConditionId);
          if (c != null && c > 0) resolvedCasingId = c;
        }
        if (finalComment.isEmpty && hiveTyre.comments != null && hiveTyre.comments!.trim().isNotEmpty) {
          finalComment = hiveTyre.comments!.trim();
        }
      }
    }

    return {
      "tireId": resolvedTireIdForInsp,
      "locationId": locationIdInt,
      "parentAccountId": parentAccountIdInt,
      "tireSerialNo": tire.tireSerialNo ?? "",
      "registeredDate": (tire.registeredDate != null && tire.registeredDate!.isNotEmpty) ? tire.registeredDate : nowIso,
      "manufacturerId": tire.manufacturerId ?? 0,
      "typeId": tire.typeId ?? 0,
      "sizeId": tire.sizeId ?? 0,
      "sizeName": resolvedSize,
      "typeName": resolvedType,
      // 🔧 FIX (approve ke baad tyre hours/miles vehicle jaise ho jaate the):
      // Pehle yahan VEHICLE ke submittedHours/submittedKm tyre record me
      // daale ja rahe the -> vehicle 100/100 aur tyre 50/50 hone par bhi
      // pending payload (aur approve ke baad server) me tyre ka 100/100 ho
      // jaata tha. Tyre ki apni value (jo install/_applyDeltaToTires se
      // maintain hoti hai) ko priority do; sirf tab vehicle value fallback
      // lo jab tyre ki apni value missing/0 ho.
      "currentHours": (tire.currentHours != null && tire.currentHours! > 0)
          ? tire.currentHours
          : submittedHours,
      "currentMiles": (tire.currentMiles != null && tire.currentMiles! > 0)
          ? tire.currentMiles
          : submittedKm,
      "wheelPosition": tire.wheelPosition ?? "",
      "percentageWorn": tire.percentageWorn ?? 0.0,
      "wearNonSkid": (tire.wearNonSkid != null && tire.wearNonSkid! > 0) ? tire.wearNonSkid : null,
      "currentTreadDepth": tire.currentTreadDepth ?? 0.0,
      "currentPressure": tire.currentPressure ?? 0.0,
      "wearConditionId": resolvedWearId,
      "casingConditionId": resolvedCasingId,
      "mountedRimId": (tire.mountedRimId != null && tire.mountedRimId! > 0) ? tire.mountedRimId : null,
      "outsideTread": tire.outsideTread ?? 0.0,
      "middleTread": tire.middleTread ?? 0.0,
      "insideTread": tire.insideTread ?? 0.0,
      "originalTread": tire.originalTread ?? 0.0,
      "removeAt": tire.removeAt ?? 0.0,
      "comments": finalComment.isNotEmpty ? finalComment : null,
      "inspectionDate": nowIso,
      "mileageType": mileageTypeStr,
      "imagesLocation": imagesLocation.trim().isNotEmpty ? imagesLocation.trim() : null,
      "brandNo": tire.brandNo ?? "",
      "dispositionId": () {
        final int resolvedDispId = action == "Remove"
            ? ((tire.dispositionId != null && tire.dispositionId! > 0 && tire.dispositionId != 7 && tire.dispositionId != 5)
            ? tire.dispositionId!
            : 8)
            : (action == "Install"
            ? 7
            : ((tire.dispositionId != null && tire.dispositionId! > 0 && tire.dispositionId != 8) ? tire.dispositionId! : 7));
        return resolvedDispId;
      }(),
      "dispositionName": () {
        if (action == "Remove") {
          final explicit = (tire.dispositionName ?? '').trim();
          if (explicit.isNotEmpty && !explicit.toLowerCase().contains('mount')) {
            return explicit;
          }
          final int dId = (tire.dispositionId != null && tire.dispositionId! > 0 && tire.dispositionId != 7 && tire.dispositionId != 5)
              ? tire.dispositionId!
              : 8;
          switch (dId) {
            case 1:  return "Scrap";
            case 2:  return "Repair";
            case 3:  return "Retread";
            case 4:  return "On Hold";
            case 8:  return "Inventory";
            default: return "Inventory";
          }
        }
        return "Mounted";
      }(),
      "createdBy": requestorName,
      "manufacturerName": resolvedMfg,
      "pressureType": (tire.pressureType != null && tire.pressureType!.isNotEmpty && tire.pressureType != "C") ? tire.pressureType : null,
      "vehicleId": resolvedVehicleIdForInsp > 0 ? resolvedVehicleIdForInsp : (int.tryParse(vehicleId.value) ?? int.tryParse(vehicleIdCtrl.text.trim()) ?? 0),
      "removalReasonId": (tire.removalReasonId != null && tire.removalReasonId! > 0) ? tire.removalReasonId : (action == "Remove" ? 1 : null),
      "cPtabValue": 0,
      "outsideTabValue": 0,
      "middleTabValue": 0,
      "insideTabValue": 0,
      "vehicleNumber": (model?.vehicleNumber?.toString().trim().isNotEmpty == true)
          ? model!.vehicleNumber!.toString().trim()
          : (vehicleNumberCtrl.text.trim().isNotEmpty ? vehicleNumberCtrl.text.trim() : ""),
      "maxIn": 0,
      "maxMid": 0,
      "maxOut": 0,
      "minTread": 0,
      "action": action,
      "actionType": action,
      "isRemoved": action == "Remove",
      "IsRemoved": action == "Remove",
    };
  }

  /// Builds the request body for SaveVehicleFootPrintDetails_Temp /
  /// SaveVehicleFootPrintDetails exactly as specified in the
  /// "Inspection Approval Flow -- API Changes" doc:
  ///   { inspectionList: [...], tireList: [...], vehicleList: [...], Status: {...} }
  ///
  /// IMPORTANT: per the API doc's sample payload, inspectionList/tireList
  /// must carry EVERY installed tyre being inspected on the vehicle in ONE
  /// request (the doc's example has 2 tires for 1 vehicle in a single
  /// call) — not one API call per tire. `tireRecords` must therefore
  /// already contain one entry per installed tyre; callers build that list
  /// via `_buildTireRecord()` for each tire in `tires` before calling this.
  ///
  /// `cPtabValue` / `outsideTabValue` / `middleTabValue` / `insideTabValue` /
  /// `maxIn` / `maxMid` / `maxOut` / `minTread` don't exist anywhere in this
  /// app's tire model today, so they default to 0 — confirm with backend
  /// whether they're required or just echoed back.
  Future<Map<String, dynamic>> _buildFootprintDetailsPayload({
    required List<Map<String, dynamic>> tireRecords,
    required int resolvedVehicleIdForInsp,
    required double submittedHours,
    required double submittedKm,
    required int locationIdInt,
    required int parentAccountIdInt,
    required String requestorName,
    String? imagesLocation,
  }) async {
    final nowIso = inspectionIso;
    final grandParentAccountId =
    await SecureStorage.getProfileGrandParentAccountId();

    final vehicleMap = <String, dynamic>{
      "vehicleId": resolvedVehicleIdForInsp > 0 ? resolvedVehicleIdForInsp : (int.tryParse(vehicleId.value) ?? int.tryParse(vehicleIdCtrl.text.trim()) ?? 0),
      "vehicleNumber": (model?.vehicleNumber?.toString().trim().isNotEmpty == true)
          ? model!.vehicleNumber!.toString().trim()
          : (vehicleNumberCtrl.text.trim().isNotEmpty ? vehicleNumberCtrl.text.trim() : ""),
      "inspectionDate": nowIso,
      "currentHours": submittedHours,
      "currentMiles": submittedKm,
      "action": "UpdateHoursEditTire",
      "locationId": locationIdInt,
      "parentAccountId": parentAccountIdInt,
      if (model?.axleConfig != null && model!.axleConfig!.isNotEmpty) "axleConfig": model!.axleConfig,
      if (model?.axleConfigId != null && model!.axleConfigId! > 0) "axleConfigId": model!.axleConfigId,
      if (model?.tireSize != null && model!.tireSize!.isNotEmpty) "tireSize": model!.tireSize,
      if (model?.tireSizeId != null && model!.tireSizeId! > 0) "tireSizeId": model!.tireSizeId,
      if (model?.vehicleManufacturer != null && model!.vehicleManufacturer!.isNotEmpty) "vehicleManufacturer": model!.vehicleManufacturer,
      if (model?.vehicleType != null && model!.vehicleType!.isNotEmpty) "vehicleType": model!.vehicleType,
      if (model?.vehicleModel != null && model!.vehicleModel!.isNotEmpty) "vehicleModel": model!.vehicleModel,
      "distUnit": _serverKmUnit.isNotEmpty ? _serverKmUnit : (HivePref.get<String>(_vehicleDistUnitKey) ?? MeasurementHelper.distanceLabel),
      "comments": commentsCtrl.text.trim(),
      "severityComments": commentsCtrl.text.trim(),
    };
    if (imagesLocation != null && imagesLocation.trim().isNotEmpty) {
      vehicleMap["imagesLocation"] = imagesLocation.trim();
    }

    return {
      "inspectionList": tireRecords,
      "tireList": tireRecords,
      "vehicleList": [vehicleMap],
      "Status": {
        "inspectionStatusId": 0,
        "inspectionTypeId": 1,
        "inspectionId": 0,
        "grandParentAccountId": grandParentAccountId ?? 0,
        "statusId": 1,
        "statusUpdatedBy": "",
        "statusUpdatedDate": "",
        "comments": commentsCtrl.text.trim(),
        "createdBy": requestorName,
        "createdDate": nowIso,
        "modifiedBy": null,
        "modifiedDate": null,
      },
    };
  }

  // ── Tyre inspection images (Inspection/CreateImages) ──────
  List<File> _localFilesFrom(String? csv) => (csv ?? '')
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty && !e.startsWith('http'))
      .map((e) => File(e))
      .where((f) => LocalImageCache.safeFileExists(f))
      .toList();

  /// Only server URLs are sent in payloads — device file paths are useless
  /// to the backend.
  String _remoteOnly(String? csv) => (csv ?? '')
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.startsWith('http'))
      .join(',');

  /// Takes a comma separated list of tyre image paths/URLs. Local files are
  /// uploaded to Tire/CreateImages (tireId + imgsrc); the result keeps the
  /// already-uploaded URLs and replaces local paths with the new blob URLs.
  /// If upload fails / device offline, only the remote URLs are returned
  /// (device paths are useless to the backend).
  Future<String?> _uploadLocalTyreImages({
    required String? csv,
    required int tireId,
  }) async {
    final remote = _remoteOnly(csv);
    final local = _localFilesFrom(csv);
    if (local.isEmpty) return remote.isEmpty ? csv : remote;

    final res = await ImageUploadService.uploadTireImagesKeepingExisting(
      tireId: tireId,
      newImages: local,
      existingUrls: remote.isEmpty ? <String>[] : remote.split(','),
    );
    if (res.success) {
      final prefs = await SharedPreferences.getInstance();
      final combined = <String>{
        ...res.urls.where((p) => p.startsWith('http')),
      }.toList();
      await prefs.setStringList('inspect_tire_images_$tireId', combined);
      for (var i = 0; i < local.length; i++) {
        if (i < res.urls.length) {
          await LocalImageCache.associate(res.urls[i], local[i].path);
        }
      }
      // result already contains the old photos + the new ones
      return res.joined;
    }
    return remote;
  }

  Future<void> pickImageMobile(ImageSource source) async {
    debugPrint('$_tag pickImageMobile(): CALLED, source=$source');
    if (await _blockedByPendingApproval(PendingBlockedAction.uploadImage)) return;
    try {
      if (!Platform.isAndroid && !Platform.isIOS) return;
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (image != null) {
        final permanentFile = await _copyToPermanentStorage(image.path);
        await ImageWatermarkHelper.stampImage(permanentFile);
        uploadedImages.add(permanentFile);
        await _saveImagePaths();
        debugPrint('$_tag pickImageMobile(): image ADDED -> ${permanentFile.path}. Total images=${uploadedImages.length}');
      } else {
        debugPrint('$_tag pickImageMobile(): user CANCELLED image pick');
      }
    } catch (e) {
      debugPrint('$_tag pickImageMobile(): EXCEPTION -> $e');
    }
  }

  Future<File> _copyToPermanentStorage(String tempPath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(
      p.join(docsDir.path, 'vehicle_inspection_images'),
    );
    if (!imagesDir.existsSync()) {
      imagesDir.createSync(recursive: true);
    }
    final fileName =
        'veh_${vehicleId.value}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final destPath = p.join(imagesDir.path, fileName);
    final copiedFile = await File(tempPath).copy(destPath);
    return copiedFile;
  }

  // REMOVE LOCAL IMAGE
  Future<void> removeUploadedImage(int index) async {
    if (await _blockedByPendingApproval(PendingBlockedAction.deleteImage)) return;
    if (index >= 0 && index < uploadedImages.length) {
      final file = uploadedImages[index];
      uploadedImages.removeAt(index);
      await _saveImagePaths();
      debugPrint('$_tag removeUploadedImage(): removed index=$index -> ${file.path}');
      try {
        if (file.existsSync() && !file.path.startsWith('http')) {
          file.deleteSync();
        }
      } catch (e) {
        debugPrint('$_tag removeUploadedImage(): delete EXCEPTION -> $e');
      }
    }
  }

  Future<void> _clearTireDeltas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tireDeltaMapKey);
      await prefs.remove(_tireMileDeltaMapKey);
      await prefs.remove(_prevHoursKey);
      await prefs.remove(_prevKmKey);
      debugPrint('$_tag _clearTireDeltas(): CLEARED all delta keys for vehicleId=${vehicleId.value}');
    } catch (e) {
      debugPrint('$_tag _clearTireDeltas(): EXCEPTION -> $e');
    }
  }


// SUBMIT
  // 🔒 Single-flight guard: submit() ke andar sabse pehle `await` pending-approval
  // guard (online API, 8s tak) hai, aur `isSubmitting` uske BAAD true hota tha.
  // Us window me button enabled rehta tha -> double tap / slow device par
  // submit() 2 baar chalta tha aur SaveVehicleFootPrintDetails_Temp ka op
  // offline queue me 2 baar add ho jata tha (sync ke baad double inspection).
  // Ab flag sabse pehle, synchronously set hota hai.
  bool _submitInFlight = false;

  Future<void> submit() async {
    if (_submitInFlight) {
      debugPrint('$_tag submit(): IGNORED -> another submit() already in flight');
      return;
    }
    _submitInFlight = true;
    isSubmitting.value = true;
    try {
      await _submitInternal();
    } finally {
      _submitInFlight = false;
      if (!isClosed) {
        isSubmitting.value = false;
      }
    }
  }

  Future<void> _submitInternal() async {
    _vicTrace('submit() START vehicleId=${vehicleId.value} tires=${tires.length}', '\x1B[31m');
    debugPrint('$_tag submit() CALLED for vehicleId=${vehicleId.value}, tires.length=${tires.length}');

    if (await _blockedByPendingApproval(PendingBlockedAction.inspection)) return;

    try {
      isSubmitting.value = true;

      final parentAccountId = await SecureStorage.getParentAccountId();
      final locationId = await SecureStorage.getLocationId();
      final requestorName = await SecureStorage.getUserProfileName() ?? '';

      // ═══════════════════════════════════════════════════════════
      //  APPROVAL-FLOW: Vehicle inspection submissions route to TEMP API
      // ═══════════════════════════════════════════════════════════
      final String? userRole = await SecureStorage.getUserProfileRole();
      final bool isEmtUser = (userRole ?? '').trim().toUpperCase() == 'EMTUSER';
      final bool isWorkflowEnabled = await SecureStorage.getApprovalWorkflowEnabled();
      bool isApprover = false;
      if (isEmtUser) {
        isApprover = await SecureStorage.getIsApprover();
      }
      final bool isTempFlow = isEmtUser && (!isWorkflowEnabled || !isApprover);
      shouldUseTempApi.value = isTempFlow;

      debugPrint('$_tag submit(): userRole=$userRole, isEmtUser=$isEmtUser, isWorkflowEnabled=$isWorkflowEnabled, isApprover=$isApprover, isTempFlow=$isTempFlow');

      if (model == null) {
        debugPrint('$_tag submit(): ABORT -> model is NULL');
        Get.snackbar("Error", "Vehicle data not loaded");
        isSubmitting.value = false;
        return;
      }

      if (tires.isEmpty && removedTires.isEmpty) {
        debugPrint('$_tag submit(): ABORT -> tires list is EMPTY');
        Get.snackbar("Error", "No tires found for this vehicle");
        isSubmitting.value = false;
        return;
      }

      // Vehicle images are only uploaded on Edit Vehicle submit; skip vehicle image upload here.
      const String imagesLocation = '';

      final prefs = await SharedPreferences.getInstance();

      // 🖼️ Persist both local file paths and remote URLs to SharedPreferences
      // so the Pending Approvals screen (IWVehicleInspectionScreen) can load them
      try {
        final List<String> allImagePaths = uploadedImages.map((f) => f.path).toList();
        if (imagesLocation.isNotEmpty) {
          for (final u in imagesLocation.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty)) {
            if (!allImagePaths.contains(u)) allImagePaths.add(u);
          }
        }
        await prefs.setStringList('pending_images_${vehicleId.value}', allImagePaths);
        if (model?.vehicleId != null) {
          await prefs.setStringList('pending_images_${model!.vehicleId}', allImagePaths);
        }
        debugPrint('$_tag submit(): cached ${allImagePaths.length} image path(s) to prefs for vehicleId=${vehicleId.value}');
      } catch (e) {
        debugPrint('$_tag submit(): error saving image paths to prefs: $e');
      }

      final double submittedHours = showHours
          ? (double.tryParse(hoursCtrl.text) ?? 0.0)
          : (model?.lastRecordedHours ?? 0.0);

      final double submittedKm = showKm
          ? (_serverKm > 0 ? _serverKm : (double.tryParse(kmCtrl.text) ?? (model?.lastRecordedMiles ?? 0.0)))
          : (model?.lastRecordedMiles ?? 0.0);

      final double apiKm = submittedKm;
      final String unitToSave = _resolveVehicleDistUnit();
      _serverKmUnit = unitToSave;
      HivePref.set(_vehicleDistUnitKey, unitToSave);
      if (vehicleNumberCtrl.text.trim().isNotEmpty) {
        HivePref.set('vehicle_dist_unit_${vehicleNumberCtrl.text.trim()}', unitToSave);
      }
      try {
        final sp = await SharedPreferences.getInstance();
        await sp.setString(_vehicleDistUnitKey, unitToSave);
        if (vehicleNumberCtrl.text.trim().isNotEmpty) {
          await sp.setString('vehicle_dist_unit_${vehicleNumberCtrl.text.trim()}', unitToSave);
        }
      } catch (_) {}
      debugPrint('$_tag submit(): submittedHours=$submittedHours (showHours=$showHours), submittedKm=$submittedKm (showKm=$showKm), apiKm(sent to backend)=$apiKm, unitToSave=$unitToSave');
      debugPrint('$_tag submit(): _serverHours(before)=$_serverHours, _serverKm(before)=$_serverKm');

      bool anyOffline = false;
      final commentMapToSave = await _loadTireCommentMap();

      // Collected across ALL installed tyres so the TEMP/MAIN footprint API
      // is called exactly ONCE per submit(), with every tyre's record in
      // inspectionList/tireList (per the API doc's sample payload) — instead
      // of firing one API call per tyre with a single-tyre list each time.
      final List<Map<String, dynamic>> footprintTireRecords = [];
      int footprintResolvedVehicleId = 0;
      int footprintLocationId = 0;
      int footprintParentAccountId = 0;
      final String footprintNowIso = inspectionIso;

      final int defaultResolvedVehicleId = await _resolveVehicleId(model?.vehicleId ?? int.tryParse(vehicleId.value) ?? int.tryParse(vehicleIdCtrl.text.trim()) ?? 0);
      final int defaultLocationId = int.tryParse(locationId ?? "0") ?? 0;
      final int defaultParentAccountId = int.tryParse(parentAccountId ?? "0") ?? 0;
      footprintResolvedVehicleId = defaultResolvedVehicleId;
      footprintLocationId = defaultLocationId;
      footprintParentAccountId = defaultParentAccountId;

      // Upload installed tyre images sequentially (1-by-1) to avoid OOM/freeze on submit.
      final Map<int, String?> preUploadedTyreImages = {};
      isUploadingImages.value = true;
      try {
        for (var tire in tires) {
          final String action = _getTireAction(tire);
          if (action == "Inspect" || action == "Install") {
            String? tImgs = tire.imagesLocation?.toString().trim();
            if (tImgs == null || tImgs.isEmpty) {
              if (tire.tireId != null) {
                final localTireImgs = prefs.getStringList('inspect_tire_images_${tire.tireId}');
                if (localTireImgs != null && localTireImgs.isNotEmpty) {
                  tImgs = localTireImgs.join(',');
                }
              }
            }
            if (tImgs != null && tImgs.isNotEmpty) {
              final tId = tire.tireId ?? 0;
              try {
                final resId = await _resolveTyreId(tId);
                final up = await _uploadLocalTyreImages(csv: tImgs, tireId: resId)
                    .timeout(const Duration(seconds: 25), onTimeout: () => null);
                preUploadedTyreImages[tId] = up;
              } catch (e) {
                debugPrint('$_tag submit(): tyre photo upload error (tireId=$tId) -> $e');
              }
            }
          }
        }
      } finally {
        if (!isClosed) {
          isUploadingImages.value = false;
        }
      }

      for (var tire in tires) {
        final String action = _getTireAction(tire);
        debugPrint('$_tag submit(): --- processing tireId=${tire.tireId}, position=${tire.wheelPosition}, action=$action ---');

        final resolvedComment = () {
          final tc = (tire.comments ?? '').trim();
          final isRotation = tc.toLowerCase() == 'rotation';
          if (tc.isNotEmpty && !isRotation) return tc;
          return commentsCtrl.text.trim();
        }();

        final key = _tireKey(tire);
        if (resolvedComment.isNotEmpty &&
            resolvedComment.toLowerCase() != 'rotation') {
          commentMapToSave[key] = resolvedComment;
        }

        final double tireHours = tire.currentHours ?? 0.0;
        final double tireKm = tire.currentMiles ?? 0.0;

        final int resolvedVehicleIdForInsp = defaultResolvedVehicleId;
        final int resolvedTireIdForInsp = await _resolveTyreId(tire.tireId ?? 0);
        debugPrint('$_tag submit(): resolvedVehicleId=$resolvedVehicleIdForInsp, resolvedTireId=$resolvedTireIdForInsp, tireHours=$tireHours, tireKm=$tireKm');

        if (resolvedTireIdForInsp > 0) {
          final curDistUnit = TyreUnitHistory.getDistanceUnit(resolvedTireIdForInsp) ??
              (MeasurementHelper.isMetric ? 'Metric' : 'Imperial');
          final curPressUnit = TyreUnitHistory.getPressureUnit(resolvedTireIdForInsp) ??
              MeasurementHelper.pressureLabel;
          final curTreadUnit = TyreUnitHistory.getTreadUnit(resolvedTireIdForInsp) ??
              (MeasurementHelper.isMetric ? 'Metric' : 'Imperial');
          TyreUnitHistory.recordRawReadings(
            tireId: resolvedTireIdForInsp,
            outside: tire.outsideTread,
            middle: tire.middleTread ?? tire.currentTreadDepth,
            inside: tire.insideTread,
            pressure: tire.currentPressure,
            miles: tire.currentMiles,
            percentageWorn: tire.percentageWorn,
            treadUnit: curTreadUnit,
            pressureUnit: curPressUnit,
            distanceUnit: curDistUnit,
          );
          if (tire.tireSerialNo != null && tire.tireSerialNo!.trim().isNotEmpty) {
            TyreUnitHistory.recordRawReadings(
              tireId: tire.tireSerialNo!.trim(),
              outside: tire.outsideTread,
              middle: tire.middleTread ?? tire.currentTreadDepth,
              inside: tire.insideTread,
              pressure: tire.currentPressure,
              miles: tire.currentMiles,
              percentageWorn: tire.percentageWorn,
              treadUnit: curTreadUnit,
              pressureUnit: curPressUnit,
              distanceUnit: curDistUnit,
            );
          }
        }

        // TEMP API (approval flow) uses the { inspectionList, tireList, vehicleList, Status } contract
        // from the API doc, which expects EVERY installed tyre's record in ONE request.
        debugPrint('$_tag submit(): tireId=${tire.tireId} -> queued into batched footprint payload (action=$action)');
        String? tireImages = preUploadedTyreImages[tire.tireId ?? 0];
        if (tireImages == null || tireImages.isEmpty) {
          tireImages = tire.imagesLocation?.toString().trim();
        }

        footprintTireRecords.add(_buildTireRecord(
          tire: tire,
          action: action,
          resolvedVehicleIdForInsp: resolvedVehicleIdForInsp,
          resolvedTireIdForInsp: resolvedTireIdForInsp,
          submittedHours: submittedHours,
          submittedKm: apiKm,
          resolvedComment: resolvedComment,
          imagesLocation: tireImages ?? '',
          locationIdInt: int.tryParse(locationId ?? "0") ?? 0,
          parentAccountIdInt: int.tryParse(parentAccountId ?? "0") ?? 0,
          requestorName: requestorName,
          nowIso: footprintNowIso,
        ));
        footprintResolvedVehicleId = resolvedVehicleIdForInsp;
        footprintLocationId = int.tryParse(locationId ?? "0") ?? 0;
        footprintParentAccountId = int.tryParse(parentAccountId ?? "0") ?? 0;
      }

      for (final removedTire in removedTires) {
        final int resolvedTireId = await _resolveTyreId(removedTire.tireId ?? 0);
        final key = _tireKey(removedTire);
        final resolvedComment = commentMapToSave[key] ?? (removedTire.comments ?? "").trim();
        debugPrint('$_tag submit(): removed tireId=$resolvedTireId -> action=Remove -> queued into batched footprint payload');
        String? remTireImages = preUploadedTyreImages[removedTire.tireId ?? 0];
        if (remTireImages == null || remTireImages.isEmpty) {
          remTireImages = (removedTire.imagesLocation != null && removedTire.imagesLocation.toString().trim().isNotEmpty)
              ? removedTire.imagesLocation.toString().trim()
              : null;
        }
        footprintTireRecords.add(_buildTireRecord(
          tire: removedTire,
          action: "Remove",
          resolvedVehicleIdForInsp: defaultResolvedVehicleId,
          resolvedTireIdForInsp: resolvedTireId,
          submittedHours: submittedHours,
          submittedKm: apiKm,
          resolvedComment: resolvedComment,
          imagesLocation: remTireImages ?? '',
          locationIdInt: defaultLocationId,
          parentAccountIdInt: defaultParentAccountId,
          requestorName: requestorName,
          nowIso: footprintNowIso,
        ));
      }

      pendingInstallPayloads.clear();
      pendingRemovePayloads.clear();
      removedTires.clear();

      if (footprintTireRecords.isNotEmpty || model?.vehicleId != null) {
        final footprintPayload = await _buildFootprintDetailsPayload(
          tireRecords: footprintTireRecords,
          resolvedVehicleIdForInsp: footprintResolvedVehicleId,
          submittedHours: submittedHours,
          submittedKm: apiKm,
          locationIdInt: footprintLocationId,
          parentAccountIdInt: footprintParentAccountId,
          requestorName: requestorName,
          imagesLocation: null,
        );

        _vicTrace('submit() -> calling footprint API (isTempFlow=$isTempFlow)', '\x1B[33m');
      final InspectionSubmitResult footprintResult = isTempFlow
            ? await service.submitApprovalFlowInspection(footprintPayload)
            : await service.submitDirectInspection(footprintPayload);

        debugPrint('$_tag submit(): batched footprint API (isTempFlow=$isTempFlow) -> tyreCount=${footprintTireRecords.length}, success=${footprintResult.success}, offline=${footprintResult.offline}, error=${footprintResult.errorMessage}');

        if (footprintResult.offline) {

          anyOffline = true;
          debugPrint('$_tag submit(): batched footprint payload SAVED OFFLINE (device has NO connectivity)');
        } else if (!footprintResult.success) {
          debugPrint('$_tag submit(): batched footprint payload FAILED WHILE ONLINE -> ${footprintResult.errorMessage}');
          isSubmitting.value = false;
          isUploadingImages.value = false;
          Get.snackbar(
            "Inspection Failed",
            footprintResult.errorMessage ??
                "Server rejected the inspection. Please try again.",
            duration: const Duration(seconds: 5),
          );
          return;
        }
      }

      await _saveTireCommentMap(commentMapToSave);
      await SecureStorage.saveLastInspectionDate(
        DateTime.now().toIso8601String(),
      );

      if (isTempFlow) {
        PendingInspectionGuard.markPending(
          footprintResolvedVehicleId > 0
              ? footprintResolvedVehicleId
              : int.tryParse(vehicleId.value),
          submittedBy: requestorName,
          tireIds: tires.map((t) => t.tireId).whereType<int>(),
        );
        debugPrint('$_tag submit(): persisting pending payload, tires, and local cache for approval flow');
        try {
          final prefs = await SharedPreferences.getInstance();
          final vIdKey = vehicleId.value;
          final vNumKey = vehicleNumberCtrl.text.trim();

          final footprintMap = await _buildFootprintDetailsPayload(
            tireRecords: footprintTireRecords,
            resolvedVehicleIdForInsp: footprintResolvedVehicleId,
            submittedHours: submittedHours,
            submittedKm: apiKm,
            locationIdInt: footprintLocationId,
            parentAccountIdInt: footprintParentAccountId,
            requestorName: requestorName,
            imagesLocation: null,
          );
          final payloadJson = jsonEncode(footprintMap);
          await prefs.setString('pending_inspection_payload_$vIdKey', payloadJson);
          if (vNumKey.isNotEmpty) {
            await prefs.setString('pending_inspection_payload_$vNumKey', payloadJson);
          }

          // 2. Persist tire records list
          final tireRecordsJson = jsonEncode(footprintTireRecords);
          await prefs.setString('pending_inspection_tires_$vIdKey', tireRecordsJson);
          if (vNumKey.isNotEmpty) {
            await prefs.setString('pending_inspection_tires_$vNumKey', tireRecordsJson);
          }
        } catch (e) {
          debugPrint('$_tag submit(): error saving pending inspection cache: $e');
        }
      } else {
        // Direct inspection succeeded on server -> remove any stale pending entries
        try {
          final prefs = await SharedPreferences.getInstance();
          final vIdKey = vehicleId.value;
          final vNumKey = vehicleNumberCtrl.text.trim();
          await prefs.remove('pending_inspection_payload_$vIdKey');
          await prefs.remove('pending_inspection_payload_$vNumKey');
          await prefs.remove('pending_inspection_tires_$vIdKey');
          await prefs.remove('pending_inspection_tires_$vNumKey');
        } catch (_) {}
      }

      try {
        final vIdKey = vehicleId.value;
        final vNumKey = vehicleNumberCtrl.text.trim();

        final cachedJson = OfflineHiveService.getInspectionCache(vIdKey);
        Map<String, dynamic> cacheMap;
        if (cachedJson != null) {
          cacheMap = jsonDecode(cachedJson) as Map<String, dynamic>;
        } else {
          cacheMap = {
            "didError": false,
            "message": "",
            "model": {
              "vehicleId": int.tryParse(vIdKey) ?? 0,
              "vehicleNumber": vNumKey,
              "axleConfig": model?.axleConfig ?? '22',
              "axleConfigId": model?.axleConfigId ?? 1,
            }
          };
        }
        final modelM = (cacheMap['model'] as Map<String, dynamic>?) ?? {};
        modelM['installedTires'] = tires.map((t) => t.toJson()).toList();
        modelM['lastRecordedHours'] = submittedHours;
        modelM['lastRecordedMiles'] = submittedKm;
        if (model?.axleConfig != null && model!.axleConfig!.isNotEmpty) {
          modelM['axleConfig'] = model!.axleConfig;
        }
        if (model?.axleConfigId != null) {
          modelM['axleConfigId'] = model!.axleConfigId;
        }
        cacheMap['model'] = modelM;
        await OfflineHiveService.saveInspectionCache(vIdKey, jsonEncode(cacheMap));
        if (vNumKey.isNotEmpty) {
          await OfflineHiveService.saveInspectionCache(vNumKey, jsonEncode(cacheMap));
        }

        // 4. Update tire count and vehicle hours in local store
        final vIdInt = int.tryParse(vIdKey) ?? 0;
        if (vIdInt != 0) {
          await OfflineHiveService.updateVehicleTireCount(vIdInt, tires.length);
          await OfflineHiveService.updateVehicleHours(vIdInt, submittedHours, submittedKm);
        }
        debugPrint('$_tag submit(): cached ${tires.length} installed tire(s) and pending payload for vehicle $vIdKey ($vNumKey)');
      } catch (e) {
        debugPrint('$_tag submit(): error saving pending inspection cache: $e');
      }

      await saveVehicleComment(commentsCtrl.text.trim());

      await _clearTireDeltas();

      final String vehicleNo = vehicleNumberCtrl.text;
      final String snackTitle = anyOffline
          ? 'Vehicle Inspection Successful.'
          : (isTempFlow ? 'Inspection Submitted' : 'Vehicle Inspected Successfully');
      final String snackMsg = anyOffline
          ? 'Vehicle $vehicleNo inspected successfully.'
          : (isTempFlow
              ? 'Vehicle $vehicleNo inspection submitted for approval.'
              : 'Vehicle $vehicleNo inspected successfully.');

      if (!isClosed) {
        isSubmitting.value = false;
        isUploadingImages.value = false;
      }

      Get.offAllNamed(
        AppPages.HOME,
        arguments: {
          'triggerSnackbar': true,
          'isOffline': anyOffline,
          'title': snackTitle,
          'message': snackMsg,
        },
      );
    } catch (e, st) {
      debugPrint('$_tag submit(): TOP-LEVEL EXCEPTION -> $e\n$st');
      // FIX: Exception par screen freeze nahi hogi - loading reset + snackbar
      if (!isClosed) {
        isSubmitting.value = false;
        isUploadingImages.value = false;
        try {
          Get.snackbar(
            'Submission Error',
            'Something went wrong. Please try again.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
            snackPosition: SnackPosition.TOP,
          );
        } catch (_) {}
      }
    } finally {
      if (!isClosed) {
        isSubmitting.value = false;
        isUploadingImages.value = false;
      }
      debugPrint('$_tag submit(): FINALLY block -> isSubmitting=false, isUploadingImages=false');
    }
  }
  // Comment SP mein save karo
  Future<void> saveVehicleComment(String comment) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vehicleCommentKey, comment);
    debugPrint('$_tag saveVehicleComment(): saved -> "$comment"');
  }

  // Comment SP se load karo
  Future<String> _loadVehicleComment() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_vehicleCommentKey) ?? '';
    debugPrint('$_tag _loadVehicleComment(): loaded -> "$val"');
    return val;
  }

  Future<Map<String, bool>> submitRotationOnly() async {
    debugPrint('$_tag submitRotationOnly() CALLED for vehicleId=${vehicleId.value}, tires.length=${tires.length}');
    if (shouldUseTempApi.value) {
      debugPrint('$_tag submitRotationOnly(): shouldUseTempApi=true -> SKIP server calls, draft rotation only');
      return {'success': true, 'savedOffline': false};
    }
    try {
      final parentAccountId = await SecureStorage.getParentAccountId();
      final locationId = await SecureStorage.getLocationId();

      if (model == null) {
        debugPrint('$_tag submitRotationOnly(): ABORT -> model is NULL');
        return {'success': false, 'savedOffline': false};
      }
      if (tires.isEmpty) {
        debugPrint('$_tag submitRotationOnly(): ABORT -> tires EMPTY');
        return {'success': false, 'savedOffline': false};
      }

      final now = DateTime.now().toIso8601String();
      final locId = int.tryParse(locationId ?? "0") ?? 0;
      final parentId = int.tryParse(parentAccountId ?? "0") ?? 0;
      final vId = model!.vehicleId ?? 0;

      final double currentHours = showHours
          ? (double.tryParse(hoursCtrl.text) ?? 0.0)
          : (model?.lastRecordedHours ?? 0.0);

      final double currentKm = showKm
          ? (double.tryParse(kmCtrl.text) ?? 0.0)
          : (model?.lastRecordedMiles ?? 0.0);

      final int resolvedVId = await _resolveVehicleId(vId);
      debugPrint('$_tag submitRotationOnly(): resolvedVId=$resolvedVId, currentHours=$currentHours, currentKm=$currentKm');

      final List<int> resolvedTireIds = await Future.wait(
        tires.map((tire) => _resolveTyreId(tire.tireId ?? 0)),
      );

      final seenTireIds = <int>{};
      final uniqueIndexes = <int>[];
      for (int i = 0; i < tires.length; i++) {
        final resolvedId = resolvedTireIds[i];
        if (resolvedId > 0 && !seenTireIds.contains(resolvedId)) {
          seenTireIds.add(resolvedId);
          uniqueIndexes.add(i);
        } else if (resolvedId <= 0) {
          debugPrint('$_tag submitRotationOnly(): SKIP tire index=$i -> unresolved id ($resolvedId)');
        } else {
          debugPrint('$_tag submitRotationOnly(): SKIP tire index=$i -> DUPLICATE resolvedId=$resolvedId');
        }
      }

      final validTires = uniqueIndexes.map((i) => tires[i]).toList();
      final validResolvedIds = uniqueIndexes.map((i) => resolvedTireIds[i]).toList();
      debugPrint('$_tag submitRotationOnly(): validTires count = ${validTires.length} (of ${tires.length} total)');

      if (validTires.isEmpty) {
        debugPrint('$_tag submitRotationOnly(): ABORT -> no valid tires after dedup/resolve');
        return {'success': false, 'savedOffline': false};
      }

      final List<Map<String, dynamic>> removeList = List.generate(
        validTires.length,
            (i) {
          final tire = validTires[i];
          final resolvedTireId = validResolvedIds[i];
          return {
            "action": "Remove",
            "inspectionDate": now,
            "locationId": locId,
            "parentAccountId": parentId,
            "vehicleId": resolvedVId,
            "inspectionId": 0,
            "tireId": resolvedTireId,
            "currentHours": currentHours,
            "currentMiles": currentKm,
            "tireSerialNo": tire.tireSerialNo ?? "",
            "brandNumber": tire.brandNo ?? "",
            "originalTread": tire.originalTread ?? 0.0,
            "removeAt": tire.removeAt ?? 0.0,
            "outsideTread": tire.outsideTread ?? 0.0,
            "middleTread": tire.middleTread ?? 0.0,
            "insideTread": tire.insideTread ?? 0.0,
            "currentTreadDepth": tire.currentTreadDepth ?? 0.0,
            "currentPressure": tire.currentPressure ?? 0.0,
            "pressureUnitId": 1,
            "casingConditionId": tire.casingConditionId ?? 0,
            "wearConditionId": tire.wearConditionId ?? 0,
            "comments": "",
            "removalReasonId": tire.removalReasonId ?? 0,
            "dispositionId": tire.dispositionId ?? 7,
            "rimDispositionId": tire.dispositionId ?? 7,
            "wheelPosition": tire.wheelPosition ?? "",
            "mountedRimId": tire.mountedRimId ?? 0,
            "pressureType": "",
            "hoursAdjustToTire": 0.0,
            "milesAdjustToTire": 0.0,
            "isMobInstall": true,
          };
        },
      );

      bool removeOk = false;
      bool removeSavedOffline = false;
      try {
        debugPrint('$_tag submitRotationOnly(): calling removeTiresForRotation() with ${removeList.length} tire(s)');
        removeOk = await service.removeTiresForRotation(tiresData: removeList);
        if (!removeOk) {
          debugPrint('$_tag submitRotationOnly(): removeTiresForRotation returned FALSE -> treating as SAVED OFFLINE');
          removeSavedOffline = true;
          removeOk = true;
        }
      } catch (e) {
        final isOffline = e.toString().contains('Saved offline');
        debugPrint('$_tag submitRotationOnly(): removeTiresForRotation EXCEPTION -> $e (isOfflineMarker=$isOffline)');
        if (isOffline) {
          removeSavedOffline = true;
          removeOk = true;
        } else {
          return {'success': false, 'savedOffline': false};
        }
      }
      if (!removeOk) {
        debugPrint('$_tag submitRotationOnly(): ABORT -> remove step failed');
        return {'success': false, 'savedOffline': false};
      }

      bool allInstalled = true;
      bool installSavedOffline = false;
      for (int i = 0; i < validTires.length; i++) {
        final tire = validTires[i];
        final resolvedTireId = validResolvedIds[i];
        final installData = {
          "action": "Install",
          "inspectionDate": DateTime.now().toIso8601String(),
          "locationId": locId,
          "parentAccountId": parentId,
          "vehicleId": resolvedVId,
          "inspectionId": 0,
          "tireId": resolvedTireId,
          "currentHours": currentHours,
          "currentMiles": currentKm,
          "tireSerialNo": tire.tireSerialNo ?? "",
          "brandNumber": tire.brandNo ?? "",
          "originalTread": tire.originalTread ?? 0.0,
          "removeAt": tire.removeAt ?? 0.0,
          "outsideTread": tire.outsideTread ?? 0.0,
          "middleTread": tire.middleTread ?? 0.0,
          "insideTread": tire.insideTread ?? 0.0,
          "currentTreadDepth": tire.currentTreadDepth ?? 0.0,
          "currentPressure": tire.currentPressure ?? 0.0,
          "pressureUnitId": 1,
          "casingConditionId": tire.casingConditionId ?? 0,
          "wearConditionId": tire.wearConditionId ?? 0,
          "comments": "Rotation",
          "removalReasonId": 0,
          "dispositionId": tire.dispositionId ?? 7,
          "rimDispositionId": tire.dispositionId ?? 7,
          "wheelPosition": tire.wheelPosition ?? "",
          "mountedRimId": tire.mountedRimId ?? 0,
          "pressureType": "",
          "hoursAdjustToTire": 0.0,
          "milesAdjustToTire": 0.0,
          "isMobInstall": true,
        };

        try {
          debugPrint('$_tag submitRotationOnly(): installing tireId=$resolvedTireId at position=${tire.wheelPosition}');
          final installed = await service.installTireAtPosition(
            tireData: installData,
          );
          if (!installed) {
            debugPrint('$_tag submitRotationOnly(): install returned FALSE for tireId=$resolvedTireId -> SAVED OFFLINE');
            installSavedOffline = true;
          }
        } catch (e) {
          final isOffline = e.toString().contains('Saved offline');
          debugPrint('$_tag submitRotationOnly(): install EXCEPTION tireId=$resolvedTireId -> $e (isOfflineMarker=$isOffline)');
          if (isOffline) {
            installSavedOffline = true;
          } else {
            allInstalled = false;
          }
        }
      }

      final savedOffline = removeSavedOffline || installSavedOffline;
      debugPrint('$_tag submitRotationOnly(): DONE. allInstalled=$allInstalled, savedOffline=$savedOffline');

      if (allInstalled && resolvedVId > 0) {
        _updateRotationInCache(resolvedVId, tiresOverride: validTires);
      }

      return {'success': allInstalled, 'savedOffline': savedOffline};
    } catch (e, st) {
      debugPrint('$_tag submitRotationOnly(): TOP-LEVEL EXCEPTION -> $e\n$st');
      return {'success': false, 'savedOffline': false};
    }
  }

  void _updateRotationInCache(int vehicleId, {List<InstalledTire>? tiresOverride}) {
    try {
      final cached = OfflineHiveService.getInspectionCache(
        vehicleId.toString(),
      );
      if (cached == null) {
        debugPrint('$_tag _updateRotationInCache(): NO cache found for vehicleId=$vehicleId');
        return;
      }

      final jsonData = jsonDecode(cached) as Map<String, dynamic>;
      final model = jsonData['model'] as Map<String, dynamic>?;
      if (model == null) return;

      final tiresToUpdate = tiresOverride ?? tires;
      final cachedTiles = model['installedTires'] as List? ?? [];
      for (final updatedTire in tiresToUpdate) {
        final tireId = updatedTire.tireId ?? 0;
        final newPosition = updatedTire.wheelPosition ?? '';
        for (final cached in cachedTiles) {
          if ((cached as Map)['tireId'] == tireId) {
            cached['wheelPosition'] = newPosition;
            break;
          }
        }
      }
      model['installedTires'] = cachedTiles;
      jsonData['model'] = model;

      OfflineHiveService.saveInspectionCache(
        vehicleId.toString(),
        jsonEncode(jsonData),
      ).catchError((e) {
        debugPrint('$_tag _updateRotationInCache(): saveInspectionCache EXCEPTION -> $e');
      });
      debugPrint('$_tag _updateRotationInCache(): cache updated with ${tiresToUpdate.length} new position(s) for vehicleId=$vehicleId');
    } catch (e) {
      debugPrint('$_tag _updateRotationInCache(): EXCEPTION -> $e');
    }
  }

  Future<void> _applyDeltaToTires({
    required double hoursDiff,
    required double kmDiff,
  }) async {
    debugPrint('$_tag _applyDeltaToTires(): CALLED with hoursDiff=$hoursDiff, kmDiff=$kmDiff, tires.length=${tires.length}');
    final hoursDeltaMap = await _loadTireHoursDeltaMap();
    final kmDeltaMap = await _loadTireKmDeltaMap();

    final updatedTires = tires.map((tire) {
      final key = _tireKey(tire);

      final prevHoursDelta = hoursDeltaMap[key] ?? 0.0;
      final prevKmDelta = kmDeltaMap[key] ?? 0.0;

      final newHoursDelta = prevHoursDelta + hoursDiff;
      final newKmDelta = prevKmDelta + kmDiff;

      hoursDeltaMap[key] = newHoursDelta;
      kmDeltaMap[key] = newKmDelta;

      debugPrint('$_tag _applyDeltaToTires(): tireKey=$key -> hoursDelta $prevHoursDelta -> $newHoursDelta, kmDelta $prevKmDelta -> $newKmDelta');

      final newHours = (tire.currentHours ?? 0.0) + hoursDiff;
      final newMiles = (tire.currentMiles ?? 0.0) + kmDiff;

      if (tire.tireId != null && tire.tireId! > 0) {
        final currentDistUnit = TyreUnitHistory.getDistanceUnit(tire.tireId) ??
            (MeasurementHelper.isMetric ? 'Metric' : 'Imperial');
        TyreUnitHistory.recordRawReadings(
          tireId: tire.tireId,
          miles: newMiles,
          distanceUnit: currentDistUnit,
        );
      }

      return InstalledTire(
        tireId: tire.tireId,
        tireSerialNo: tire.tireSerialNo,
        wheelPosition: tire.wheelPosition,
        currentTreadDepth: tire.currentTreadDepth,
        currentPressure: tire.currentPressure,
        currentHours: newHours,
        currentMiles: newMiles,
        outsideTread: tire.outsideTread,
        middleTread: tire.middleTread,
        insideTread: tire.insideTread,
        originalTread: tire.originalTread,
        removeAt: tire.removeAt,
        dispositionId: tire.dispositionId,
        casingConditionId: tire.casingConditionId,
        wearConditionId: tire.wearConditionId,
        percentageWorn: tire.percentageWorn,
        sizeName: tire.sizeName,
        typeName: tire.typeName,
        manufacturerName: tire.manufacturerName,
        brandNo: tire.brandNo,
        mountedRimId: tire.mountedRimId,
        pressureType: tire.pressureType,
        vehicleId: tire.vehicleId,
        removalReasonId: tire.removalReasonId,
        comments: tire.comments,
        inspectionDate: tire.inspectionDate,
        mileageType: tire.mileageType,
        imagesLocation: tire.imagesLocation,
        locationId: tire.locationId,
        parentAccountId: tire.parentAccountId,
        registeredDate: tire.registeredDate,
        manufacturerId: tire.manufacturerId,
        typeId: tire.typeId,
        sizeId: tire.sizeId,
        wearNonSkid: tire.wearNonSkid,
        createdBy: tire.createdBy,
      );
    }).toList();

    tires.assignAll(_sortedByPosition(updatedTires));

    if (model?.installedTires != null) {
      for (final mTile in model!.installedTires!) {
        for (final ut in updatedTires) {
          if (ut.tireId == mTile.tireId) {
            mTile.currentHours = ut.currentHours;
            mTile.currentMiles = ut.currentMiles;
            break;
          }
        }
      }
    }

    for (final ut in updatedTires) {
      await patchTireInCache(ut);
    }

    await _saveTireHoursDeltaMap(hoursDeltaMap);
    await _saveTireKmDeltaMap(kmDeltaMap);
    debugPrint('$_tag _applyDeltaToTires(): DONE -> deltas persisted to SharedPreferences');
  }

  void closeWarning() {
    showHourWarning.value = false;
    debugPrint('$_tag closeWarning(): showHourWarning set to false');
  }

  Future<bool> _checkOnline() async {
    final results = await Connectivity().checkConnectivity();
    final online = results.any((r) => r != ConnectivityResult.none);
    debugPrint('$_tag _checkOnline(): results=$results -> online=$online');
    return online;
  }


  Future<void> patchTireInCache(InstalledTire updatedTire) async {
    debugPrint('$_tag patchTireInCache(): CALLED for tireId=${updatedTire.tireId}, position=${updatedTire.wheelPosition}');
    try {
      final cached = OfflineHiveService.getInspectionCache(vehicleId.value);
      Map<String, dynamic> jsonData;
      Map<String, dynamic> modelMap;

      if (cached != null) {
        jsonData = jsonDecode(cached) as Map<String, dynamic>;
        modelMap = (jsonData['model'] as Map<String, dynamic>?) ?? {};
      } else {
        jsonData = {'didError': false, 'message': '', 'model': {}};
        modelMap = jsonData['model'] as Map<String, dynamic>;
        modelMap['vehicleId'] = int.tryParse(vehicleId.value) ?? 0;
        modelMap['vehicleNumber'] = vehicleNumberCtrl.text.trim();
        modelMap['axleConfig'] = model?.axleConfig ?? '22';
        modelMap['axleConfigId'] = model?.axleConfigId ?? 1;
      }

      final cachedTireList = (modelMap['installedTires'] as List? ?? [])
          .cast<dynamic>()
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      bool matched = false;
      for (final ct in cachedTireList) {
        final posMatch = ct['wheelPosition']?.toString().trim().toUpperCase() ==
            updatedTire.wheelPosition?.trim().toUpperCase();
        final idMatch = updatedTire.tireId != null &&
            updatedTire.tireId! > 0 &&
            ct['tireId'] == updatedTire.tireId;

        if (posMatch || idMatch) {
          ct['tireId'] = updatedTire.tireId ?? ct['tireId'];
          ct['tireSerialNo'] = updatedTire.tireSerialNo ?? ct['tireSerialNo'];
          ct['wheelPosition'] = updatedTire.wheelPosition ?? ct['wheelPosition'];
          ct['outsideTread'] = updatedTire.outsideTread ?? 0.0;
          ct['insideTread'] = updatedTire.insideTread ?? 0.0;
          ct['middleTread'] = updatedTire.middleTread ?? updatedTire.currentTreadDepth ?? 0.0;
          ct['currentTreadDepth'] = updatedTire.currentTreadDepth ?? 0.0;
          ct['currentPressure'] = updatedTire.currentPressure ?? 0.0;
          ct['wearConditionId'] = updatedTire.wearConditionId ?? 0;
          ct['casingConditionId'] = updatedTire.casingConditionId ?? 0;
          ct['comments'] = updatedTire.comments ?? '';
          ct['currentHours'] = updatedTire.currentHours ?? 0.0;
          ct['currentMiles'] = updatedTire.currentMiles ?? 0.0;
          ct['action'] = updatedTire.action ?? ct['action'] ?? 'Install';
          ct['dispositionId'] = updatedTire.dispositionId ?? ct['dispositionId'] ?? 7;
          ct['percentageWorn'] = updatedTire.percentageWorn ?? ct['percentageWorn'] ?? 0.0;
          if (updatedTire.originalTread != null) ct['originalTread'] = updatedTire.originalTread;
          if (updatedTire.removeAt != null) ct['removeAt'] = updatedTire.removeAt;
          if (updatedTire.brandNo != null && updatedTire.brandNo!.isNotEmpty) ct['brandNo'] = updatedTire.brandNo;
          if (updatedTire.sizeId != null && updatedTire.sizeId! > 0) ct['sizeId'] = updatedTire.sizeId;
          if (updatedTire.typeId != null && updatedTire.typeId! > 0) ct['typeId'] = updatedTire.typeId;
          if (updatedTire.manufacturerId != null && updatedTire.manufacturerId! > 0) ct['manufacturerId'] = updatedTire.manufacturerId;
          if (updatedTire.sizeName != null && updatedTire.sizeName!.isNotEmpty) {
            ct['sizeName'] = updatedTire.sizeName;
          }
          if (updatedTire.typeName != null && updatedTire.typeName!.isNotEmpty) {
            ct['typeName'] = updatedTire.typeName;
          }
          if (updatedTire.manufacturerName != null && updatedTire.manufacturerName!.isNotEmpty) {
            ct['manufacturerName'] = updatedTire.manufacturerName;
          }
          matched = true;
          break;
        }
      }

      if (!matched) {
        cachedTireList.add(updatedTire.toJson());
      }
      debugPrint('$_tag patchTireInCache(): match found in cache = $matched, total tires in cache = ${cachedTireList.length}');

      modelMap['installedTires'] = cachedTireList;
      jsonData['model'] = modelMap;

      final updatedCacheJson = jsonEncode(jsonData);
      await OfflineHiveService.saveInspectionCache(
        vehicleId.value,
        updatedCacheJson,
      );
      if (vehicleNumberCtrl.text.trim().isNotEmpty) {
        await OfflineHiveService.saveInspectionCache(
          vehicleNumberCtrl.text.trim(),
          updatedCacheJson,
        );
      }
      debugPrint('$_tag patchTireInCache(): cache SAVED for vehicleId=${vehicleId.value}');
    } catch (e) {
      debugPrint('$_tag patchTireInCache(): EXCEPTION -> $e');
    }
  }


  Future<int> _resolveTyreId(int tireId) async {
    if (tireId > 0) return tireId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final realId = prefs.getInt('tyre_real_id_$tireId');
      if (realId != null && realId > 0) {
        debugPrint('$_tag _resolveTyreId(): tempId=$tireId RESOLVED -> realId=$realId');
        return realId;
      }
      debugPrint('$_tag _resolveTyreId(): tempId=$tireId NOT YET resolved (still offline)');
    } catch (e) {
      debugPrint('$_tag _resolveTyreId(): EXCEPTION -> $e');
    }
    return tireId;
  }

  Future<int> _resolveVehicleId(int vehId) async {
    int candidate = vehId;
    if (candidate <= 0) {
      candidate = int.tryParse(vehicleId.value) ?? int.tryParse(vehicleIdCtrl.text.trim()) ?? 0;
    }
    if (candidate > 0) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final realId = prefs.getInt('vehicle_real_id_$candidate');
        if (realId != null && realId > 0) {
          debugPrint('$_tag _resolveVehicleId(): tempId=$candidate RESOLVED -> realId=$realId');
          return realId;
        }
        debugPrint('$_tag _resolveVehicleId(): candidate=$candidate used');
      } catch (e) {
        debugPrint('$_tag _resolveVehicleId(): EXCEPTION -> $e');
      }
      return candidate;
    }
    return 0;
  }

  @override
  void onClose() {
    _vicTrace('onClose() DISPOSING vehicleId=${vehicleId.value}', '\x1B[31m');
    _measurementWorker?.dispose();
    _pressureWorker?.dispose();
    pendingInstallPayloads.clear();
    removedTires.clear();
    pendingRemovePayloads.clear();
    debugPrint('$_tag onClose(): controller DISPOSING for vehicleId=${vehicleId.value}');
    commentsCtrl.dispose();
    vehicleNumberCtrl.dispose();
    vehicleIdCtrl.dispose();
    hoursCtrl.dispose();
    kmCtrl.dispose();
    kmDisplayCtrl.dispose();
    super.onClose();


  }
}