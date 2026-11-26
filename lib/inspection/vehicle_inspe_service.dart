import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emtrack/inspection/vehicle_inspe_model.dart';
import 'package:emtrack/services/api_constants.dart';
import 'package:emtrack/services/image_upload_service.dart';
import 'package:emtrack/utils/api_logger.dart';
import 'package:emtrack/services/offline_hive_service.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Result of a TEMP / DIRECT footprint-details submission.
///
/// `offline == true`  -> device genuinely has NO connectivity right now.
///                       This is the ONLY case that gets queued into the
///                       Hive pending-operations table for later sync.
/// `offline == false` -> network WAS available. Either the request
///                       succeeded (`success == true`) or the server/API
///                       itself rejected/failed the call (`success ==
///                       false`, with `errorMessage` describing why).
///                       This case is NEVER written to Hive — it is a
///                       real failure that must be surfaced to the user,
///                       not silently treated as "saved offline".
class InspectionSubmitResult {
  final bool success;
  final bool offline;
  final String? errorMessage;

  /// Raw body of the save step (used to read `inspectionId`s for the
  /// Inspection/CreateImages call that must happen AFTER the save).
  final String? responseBody;

  InspectionSubmitResult({
    required this.success,
    required this.offline,
    this.errorMessage,
    this.responseBody,
  });
}

class VehicleInspeService {

  static const String _imgTag = '📸 [IMG_DEBUG]';

  /// Android logcat truncates a single debugPrint line at ~1000 chars, so
  /// long JSON payloads/responses (multiple tyres batched together) look
  /// like they got "cut off" even though the full data was actually
  /// sent/received. This prints long strings in safe chunks so the FULL
  /// body is visible in the console instead of just the first ~1000 chars.
  void _debugPrintLong(String tag, String label, String content) {
    final preview = content.length > 500 ? '${content.substring(0, 500)}...' : content;
    debugPrint('$tag $label (length=${content.length} chars): $preview');
  }

  Future<bool> submitInspection({required Map<String, dynamic> vehicleData}) async {
    final isOnline = await _isOnline();

    final url = Uri.parse("${ApiConstants.baseUrl}/api/Inspection/UpdateInspection/");

    // 🔍 Yahin URL print hoga jab NORMAL/OLD API hit hogi (non-EMTUSER roles)
    debugPrint('📤 [VIC_DEBUG] 🟦 NORMAL API TRIGGERED (Old Flow)');
    debugPrint('📤 [VIC_DEBUG] URL -> $url');
    debugPrint('📤 [VIC_DEBUG] PAYLOAD -> ${jsonEncode(vehicleData)}');

    if (isOnline) {
      try {
        final ok = await _callUpdateInspection(vehicleData);
        debugPrint('📥 [VIC_DEBUG] Normal Inspection call -> ok=$ok');
        if (ok) return true;
      } catch (e) {
        debugPrint('❌ [VIC_DEBUG] submitInspection EXCEPTION -> $e');
      }
    } else {
      debugPrint('📤 [VIC_DEBUG] submitInspection(): device OFFLINE -> queuing directly');
    }


    await OfflineHiveService.addPendingOperation(
      opType: 'vehicleInspect',
      payload: vehicleData,
      endpoint: '/api/Inspection/UpdateInspection/',
      httpMethod: 'PUT',
    );

    final vehicleId = vehicleData['vehicleId'];
    if (vehicleId != null) {
      await OfflineHiveService.updateTireInInspectionCache(
        vehicleId.toString(),
        vehicleData,
      );
    }

    return false;
  }

  // ═══════════════════════════════════════════════════════════
  //  2. INSPECTION APPROVAL FLOW: NON-APPROVER (TEMP API)
  //
  //  ROOT-CAUSE FIX: pehle yeh function sirf `bool` return karta tha,
  //  aur agar HTTP call fail hoti thi (chahe device online ho ya na ho),
  //  dono cases me seedha OfflineHiveService.addPendingOperation() call
  //  ho jata tha -> matlab EMTUSER jab bhi submit karta tha aur server ne
  //  koi bhi error diya (400/401/500, ya JSON parse fail, ya sirf
  //  timeout), app usko "saved offline, will sync later" bata deta tha —
  //  bhale hi network pura ON tha. Ab hum device connectivity aur
  //  server/API failure ko ALAG treat karte hain:
  //
  //   - isOnline == false  -> genuinely offline -> Hive me queue hoga
  //     (jaisa pehle hota tha, yeh case as-is rakha hai)
  //   - isOnline == true   -> Hive me KABHI queue NAHI hoga. Agar
  //     request fail/exception/non-200/didError:true ho jaye, seedha
  //     real error ke saath false success return hota hai, taaki
  //     controller UI par asli error dikha sake aur user retry kar sake.
  // ═══════════════════════════════════════════════════════════
  Future<InspectionSubmitResult> submitApprovalFlowInspection(
      Map<String, dynamic> body) async {
    final isOnline = await _isOnline();

    final url = Uri.parse(
      "${ApiConstants.baseUrl}/api/Inspection/SaveVehicleFootPrintDetails_Temp",
    );

    final requestBodyJson = jsonEncode(body);
    final tireListLen = (body['tireList'] as List?)?.length ?? 0;
    debugPrint('📤 [VIC_DEBUG] 🟨 TEMP API TRIGGERED (Approval Flow) -> tireList has $tireListLen tyre(s)');
    debugPrint('📤 [VIC_DEBUG] URL -> $url');
    _debugPrintLong('📤 [VIC_DEBUG]', 'PAYLOAD ->', requestBodyJson);

    if (!isOnline) {
      debugPrint('📤 [VIC_DEBUG] submitApprovalFlowInspection(): device GENUINELY OFFLINE -> queuing to Hive');
      await OfflineHiveService.addPendingOperation(
        opType: 'vehicleInspectApprovalTemp',
        payload: body,
        endpoint: '/api/Inspection/SaveVehicleFootPrintDetails_Temp',
        httpMethod: 'PUT',
      );
      return InspectionSubmitResult(success: false, offline: true);
    }

    try {
      final headers = await SecureStorage.authHeaders();

      // 🔧 FIX: 405 Method Not Allowed fix karne ke liye POST ko PUT kiya hai
      ApiLog.request(name: 'Inspection/SaveVehicleFootPrintDetails_Temp (approval flow)', method: 'PUT', url: url, body: requestBodyJson);
      final response = await http
          .put(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 60));
      ApiLog.response(name: 'Inspection/SaveVehicleFootPrintDetails_Temp', statusCode: response.statusCode, body: response.body);

      debugPrint('📥 [VIC_DEBUG] Temp Inspection Response: HTTP ${response.statusCode}');
      _debugPrintLong('📥 [VIC_DEBUG]', 'RESPONSE BODY ->', response.body);

      if (response.statusCode == 200) {
        // HTTP 200 ho sakta hai lekin body me didError:true ho -> woh bhi
        // asli failure hai, isko silent success mat maano.
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['didError'] == true) {
            final msg = decoded['errorMessage']?.toString() ??
                'Server rejected the inspection.';
            debugPrint('❌ [VIC_DEBUG] submitApprovalFlowInspection: HTTP 200 but didError=true -> $msg');
            return InspectionSubmitResult(
              success: false,
              offline: false,
              errorMessage: msg,
            );
          }
        } catch (_) {
          // body JSON nahi hai ya empty hai -> plain 200 = success maano
        }
        return InspectionSubmitResult(success: true, offline: false, responseBody: response.body);
      }

      final errorMsg =
          'Server returned HTTP ${response.statusCode}: ${response.body}';
      debugPrint('❌ [VIC_DEBUG] submitApprovalFlowInspection: FAILED while ONLINE -> $errorMsg');
      return InspectionSubmitResult(
        success: false,
        offline: false,
        errorMessage: errorMsg,
      );
    } catch (e) {
      debugPrint('❌ [VIC_DEBUG] submitApprovalFlowInspection EXCEPTION while ONLINE -> $e');
      return InspectionSubmitResult(
        success: false,
        offline: false,
        errorMessage: 'Request failed: $e',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  3. DIRECT INSPECTION: APPROVER (MAIN API)
  //  Same fix as submitApprovalFlowInspection above: Hive queue ONLY
  //  when device is genuinely offline; online-but-failed is a real error.
  // ═══════════════════════════════════════════════════════════
  Future<InspectionSubmitResult> submitDirectInspection(
      Map<String, dynamic> body) async {
    final isOnline = await _isOnline();

    final url = Uri.parse(
      "${ApiConstants.baseUrl}/api/Inspection/SaveVehicleFootPrintDetails",
    );

    final requestBodyJson = jsonEncode(body);
    final tireListLen = (body['tireList'] as List?)?.length ?? 0;
    debugPrint('📤 [VIC_DEBUG] 🟩 MAIN API TRIGGERED (Direct Submission) -> tireList has $tireListLen tyre(s)');
    debugPrint('📤 [VIC_DEBUG] URL -> $url');
    _debugPrintLong('📤 [VIC_DEBUG]', 'PAYLOAD ->', requestBodyJson);

    if (!isOnline) {
      debugPrint('📤 [VIC_DEBUG] submitDirectInspection(): device GENUINELY OFFLINE -> queuing to Hive');
      await OfflineHiveService.addPendingOperation(
        opType: 'vehicleInspectDirect',
        payload: body,
        endpoint: '/api/Inspection/SaveVehicleFootPrintDetails',
        httpMethod: 'PUT',
      );
      return InspectionSubmitResult(success: false, offline: true);
    }

    try {
      final headers = await SecureStorage.authHeaders();

      ApiLog.request(name: 'Inspection/SaveVehicleFootPrintDetails (direct)', method: 'PUT', url: url, body: requestBodyJson);
      final response = await http
          .put(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));
      ApiLog.response(name: 'Inspection/SaveVehicleFootPrintDetails', statusCode: response.statusCode, body: response.body);

      debugPrint('📥 [VIC_DEBUG] Direct Inspection Response: HTTP ${response.statusCode}');
      _debugPrintLong('📥 [VIC_DEBUG]', 'RESPONSE BODY ->', response.body);

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['didError'] == true) {
            final msg = decoded['errorMessage']?.toString() ??
                'Server rejected the inspection.';
            debugPrint('❌ [VIC_DEBUG] submitDirectInspection: HTTP 200 but didError=true -> $msg');
            return InspectionSubmitResult(
              success: false,
              offline: false,
              errorMessage: msg,
            );
          }
        } catch (_) {}
        return InspectionSubmitResult(success: true, offline: false, responseBody: response.body);
      }

      final errorMsg =
          'Server returned HTTP ${response.statusCode}: ${response.body}';
      debugPrint('❌ [VIC_DEBUG] submitDirectInspection: FAILED while ONLINE -> $errorMsg');
      return InspectionSubmitResult(
        success: false,
        offline: false,
        errorMessage: errorMsg,
      );
    } catch (e) {
      debugPrint('❌ [VIC_DEBUG] submitDirectInspection EXCEPTION while ONLINE -> $e');
      return InspectionSubmitResult(
        success: false,
        offline: false,
        errorMessage: 'Request failed: $e',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  4. GET ALL PENDING INSPECTIONS FOR APPROVER
  // ═══════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> getPendingInspections(int accountId) async {
    final isOnline = await _isOnline();
    if (!isOnline) return null;

    try {
      final headers = await SecureStorage.authHeaders();
      final url = Uri.parse(
        "${ApiConstants.baseUrl}/api/Inspection/GetAllPendingInspections/$accountId",
      );

      debugPrint('🔍 [VIC_DEBUG] Fetching Pending Inspections for Account: $accountId');
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ [VIC_DEBUG] Pending Inspections fetched successfully');
        return data;
      } else {
        debugPrint('⚠️ [VIC_DEBUG] Pending Inspections failed: HTTP ${response.statusCode} -> ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ [VIC_DEBUG] getPendingInspections EXCEPTION -> $e');
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════
  //  5. APPROVE / REJECT DECISION SUBMISSION
  // ═══════════════════════════════════════════════════════════
  Future<bool> submitApprovalDecision({
    required List<Map<String, dynamic>> tireDataList,
    required Map<String, dynamic> vehicleListEntry,
    required String approverName,
    required String remarks,
    required bool isApproved,
    required int inspectionId,
  }) async {
    final isOnline = await _isOnline();
    if (!isOnline) {
      Get.snackbar("Network Offline", "Internet connection required to approve/reject inspection.");
      return false;
    }

    final grandParentId = await SecureStorage.getProfileGrandParentAccountId() ?? 0;

    // 🔧 FIX (500 on approve): offline-created vehicle/tyre ke NEGATIVE temp ids
    // server ko jaate the -> backend 500. Yahan sab ko real id se replace karte
    // hain (createVehicle/createTyre sync ke waqt prefs me map save hota hai).
    // Agar koi id abhi tak resolve nahi hui to request bhejte hi nahi.
    final prefs = await SharedPreferences.getInstance();
    int? realIdOrNull(dynamic raw, {required bool vehicle}) {
      final id = raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '');
      if (id == null) return null;
      if (id >= 0) return id;
      final real = prefs.getInt(vehicle ? 'vehicle_real_id_$id' : 'tyre_real_id_$id');
      return (real != null && real > 0) ? real : null;
    }

    final Map<String, dynamic> resolvedVehicleEntry =
    Map<String, dynamic>.from(vehicleListEntry);
    if (resolvedVehicleEntry['vehicleId'] != null) {
      final rv = realIdOrNull(resolvedVehicleEntry['vehicleId'], vehicle: true);
      if (rv == null) {
        Get.snackbar(
          "Sync Pending",
          "Ye vehicle abhi server par sync nahi hua hai. Pehle Sync complete karein, phir approve karein.",
        );
        debugPrint('❌ [VIC_DEBUG] submitApprovalDecision: vehicleId ${resolvedVehicleEntry['vehicleId']} unresolved temp id -> aborting (no API call)');
        return false;
      }
      resolvedVehicleEntry['vehicleId'] = rv;
    }

    final List<Map<String, dynamic>> resolvedTireDataList = [];
    for (final tire in tireDataList) {
      final t = Map<String, dynamic>.from(tire);
      if (t['vehicleId'] != null) {
        final rv = realIdOrNull(t['vehicleId'], vehicle: true);
        if (rv != null) t['vehicleId'] = rv;
      }
      if (t['tireId'] != null) {
        final rt = realIdOrNull(t['tireId'], vehicle: false);
        if (rt == null) {
          Get.snackbar(
            "Sync Pending",
            "Tyre ${t['tireSerialNo'] ?? ''} abhi server par sync nahi hua hai. Pehle Sync complete karein, phir approve karein.",
          );
          debugPrint('❌ [VIC_DEBUG] submitApprovalDecision: tireId ${t['tireId']} unresolved temp id -> aborting (no API call)');
          return false;
        }
        t['tireId'] = rt;
      }
      resolvedTireDataList.add(t);
    }

    final String nowIso = DateTime.now().toIso8601String();
    final List<Map<String, dynamic>> sanitizedTireDataList = resolvedTireDataList.map((tire) {
      final Map<String, dynamic> t = Map<String, dynamic>.from(tire);
      if (t['inspectionDate'] == null || (t['inspectionDate'] as String?)?.isEmpty == true) {
        t['inspectionDate'] = nowIso;
      }
      if (t['registeredDate'] == null || (t['registeredDate'] as String?)?.isEmpty == true) {
        t['registeredDate'] = nowIso;
      }
      if (t['action'] == null || (t['action'] as String?)?.isEmpty == true) {
        t['action'] = 'Inspect';
      }
      return t;
    }).toList();

    final Map<String, dynamic> statusPayload = {
      "inspectionStatusId": inspectionId,
      "inspectionTypeId": 1,
      "inspectionId": 0,
      "grandParentAccountId": grandParentId,
      "statusId": isApproved ? 2 : 3,
      "statusUpdatedBy": approverName,
      "statusUpdatedDate": nowIso,
      "comments": remarks,
      "modifiedBy": approverName,
      "modifiedDate": nowIso,
    };

    final Map<String, dynamic> requestPayload = {
      "inspectionList": sanitizedTireDataList,
      "tireList": sanitizedTireDataList,
      "vehicleList": [resolvedVehicleEntry],
      "Status": statusPayload,
    };

    try {
      final headers = await SecureStorage.authHeaders();
      final url = Uri.parse("${ApiConstants.baseUrl}/api/Inspection/SaveVehicleFootPrintDetails");

      debugPrint(
        '📤 [VIC_DEBUG] Submitting Approval Decision '
            '(Inspection ID: $inspectionId, Approved: $isApproved, '
            'By: $approverName, Remarks: "$remarks")...',
      );
      debugPrint('📤 [VIC_DEBUG] Full Payload -> ${jsonEncode(requestPayload)}');

      final response = await http
          .put(url, headers: headers, body: jsonEncode(requestPayload))
          .timeout(const Duration(seconds: 25));

      debugPrint('📥 [VIC_DEBUG] Decision Response: HTTP ${response.statusCode} -> ${response.body}');

      if (response.statusCode == 405) {
        debugPrint(
          '❌ [VIC_DEBUG] 405 Method Not Allowed on $url\n'
              '   -> Request method sent: POST\n'
              '   -> Server "Allow" header: ${response.headers['allow'] ?? '(not returned)'}\n'
              '   -> All response headers: ${response.headers}\n'
              '   -> This is a SERVER-SIDE routing response, not a client bug. '
              'Share this log with the backend team to confirm the route '
              'accepts POST for SaveVehicleFootPrintDetails.',
        );
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json["didError"] == true) {
          Get.snackbar("Error", json["errorMessage"] ?? "Failed to save inspection approval.");
          return false;
        }
        return true;
      } else if (response.statusCode == 405) {
        Get.snackbar(
          "Server Error (405)",
          "The approval API rejected this request method. This is a backend "
              "configuration issue, not an app bug — please share the app logs "
              "with the backend team.",
        );
      } else if (response.statusCode == 400) {
        debugPrint('❌ [VIC_DEBUG] 400 Bad Request — field validation errors:\n${response.body}');
        String friendlyMsg = "The server rejected some field(s) in the request.";
        try {
          final errJson = jsonDecode(response.body);
          if (errJson is Map) {
            friendlyMsg = errJson.entries
                .map((e) => "${e.key}: ${(e.value is List) ? (e.value as List).join('; ') : e.value}")
                .join('\n');
          }
        } catch (_) {}
        Get.snackbar("Validation Error (400)", friendlyMsg);
      } else {
        debugPrint('❌ [VIC_DEBUG] submitApprovalDecision HTTP ${response.statusCode} BODY -> ${response.body}');
        final body = response.body;
        String msg = "Server returned HTTP ${response.statusCode} while saving the decision.";
        if (body.contains('DbUpdateConcurrencyException')) {
          msg = "Is inspection (InspectionStatusId=$inspectionId) ka pending record server par nahi mila - "
              "ya to pehle hi approve/reject ho chuka hai ya galat Inspection ID hai. "
              "Pending list refresh karke dobara try karein.";
        } else if (body.contains('FOREIGN KEY') || body.contains('FK_')) {
          msg = "Server ne kisi master data (size/type/manufacturer/location) ko invalid bataya. "
              "Tyre/vehicle ka master data check karein.";
        }
        Get.snackbar("Error (${response.statusCode})", msg);
      }
    } catch (e) {
      debugPrint('❌ [VIC_DEBUG] submitApprovalDecision EXCEPTION -> $e');
    }
    return false;
  }

  // ═══════════════════════════════════════════════════════════
  //  6. UPDATE INSPECTION (HELPER)
  // ═══════════════════════════════════════════════════════════
  Future<bool> _callUpdateInspection(Map<String, dynamic> data) async {
    final headers = await SecureStorage.authHeaders();
    final url = Uri.parse("${ApiConstants.baseUrl}/api/Inspection/UpdateInspection/");

    final response = await http
        .put(url, headers: headers, body: jsonEncode(data))
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) return true;
    throw Exception("UpdateInspection failed (${response.statusCode}): ${response.body}");
  }

  // ═══════════════════════════════════════════════════════════
  //  7. TIRE REMOVAL / INSTALLATION ROTATION
  // ═══════════════════════════════════════════════════════════
  Future<bool> removeTiresForRotation({required List<Map<String, dynamic>> tiresData}) async {
    final isOnline = await _isOnline();

    if (isOnline) {
      try {
        final headers = await SecureStorage.authHeaders();
        final url = Uri.parse("${ApiConstants.baseUrl}/api/Inspection/RemoveTire");

        final response = await http
            .put(url, headers: headers, body: jsonEncode(tiresData))
            .timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) return true;
      } catch (_) {}
    }

    for (final tire in tiresData) {
      await OfflineHiveService.addPendingOperation(
        opType: 'rotateTireRemove',
        payload: tire,
        endpoint: '/api/Inspection/RemoveTire',
        httpMethod: 'PUT',
      );
    }
    return false;
  }

  Future<bool> installTireAtPosition({required Map<String, dynamic> tireData}) async {
    final isOnline = await _isOnline();

    if (isOnline) {
      try {
        final headers = await SecureStorage.authHeaders();
        final url = Uri.parse("${ApiConstants.baseUrl}/api/Inspection/InstallTire");

        final response = await http
            .put(url, headers: headers, body: jsonEncode(tireData))
            .timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) return true;
      } catch (_) {}
    }

    await OfflineHiveService.addPendingOperation(
      opType: 'rotateTireInstall',
      payload: tireData,
      endpoint: '/api/Inspection/InstallTire',
      httpMethod: 'PUT',
    );
    return false;
  }

  // ═══════════════════════════════════════════════════════════
  //  8. UPLOAD & FETCH IMAGES
  // ═══════════════════════════════════════════════════════════
  //
  // Vehicle inspection screen photos go to  POST Vehicle/CreateImages
  // (vehicleId + imgsrc), as per "EmTrack - CreateImages APIs" doc.
  // Success response: { didError:false, message:"<blob url>" } — the URL
  // is read straight from `message` (see ImageUploadService).
  Future<String> uploadInspectionImages({
    required List<File> images,
    required String vehicleId,
  }) async {
    // Vehicle inspection screen photos -> POST Vehicle/CreateImages
    // (vehicleId + imgsrc). The response `message` already holds the blob
    // URL, so the old ListImages before/after diff is no longer needed.
    int? vId = int.tryParse(vehicleId);
    if (vId != null && vId < 0) {
      // offline-created vehicle -> use real id if it has been synced
      vId = await _resolveRealVehicleId(vehicleId);
    }
    if (vId == null || vId <= 0) {
      ApiLog.error('Vehicle/CreateImages',
          'ABORT -> vehicleId "$vehicleId" is not a real server id yet');
      return '';
    }

    final result = await ImageUploadService.uploadVehicleImages(
      vehicleId: vId,
      images: images,
    );
    return result.joined;
  }

  /// Images of ONE vehicle that are still on the server after the inspection
  /// was approved (it is no longer in the pending list then).
  /// Tries Vehicle/ListImages then Inspection/ListImages (?vehicleId=) and
  /// keeps ONLY blobs named "`<vehicleId>`_..." (blob naming from the
  /// CreateImages doc: `4975511_0_<ts>.png`), so other vehicles' / tyres'
  /// photos can never leak in.
  Future<List<String>> fetchVehicleImagesById(int vehicleId) async {
    final headers = await SecureStorage.authHeaders();
    for (final path in const [
      '/api/Vehicle/ListImages',
      '/api/Inspection/ListImages',
    ]) {
      try {
        final url = Uri.parse('${ApiConstants.baseUrl}$path?vehicleId=$vehicleId');
        ApiLog.request(name: path.replaceFirst('/api/', ''), method: 'GET', url: url);
        final response =
        await http.get(url, headers: headers).timeout(const Duration(seconds: 20));
        ApiLog.response(
          name: path.replaceFirst('/api/', ''),
          statusCode: response.statusCode,
          body: response.body.length > 600
              ? '${response.body.substring(0, 600)}…(${response.body.length} chars)'
              : response.body,
        );
        if (response.statusCode != 200) continue;

        String msg = response.body;
        try {
          final j = jsonDecode(response.body);
          final m = j is Map ? j['message'] : j;
          msg = m is List ? m.join(',') : (m?.toString() ?? '');
        } catch (_) {}

        final prefix = '/${vehicleId}_';
        final urls = RegExp(r'https?://[^\s,;"\]\[]+')
            .allMatches(msg)
            .map((m) => m.group(0)!)
            .where((u) => u.contains(prefix))
            .toSet()
            .toList();
        ApiLog.info(path, 'blobs named "$prefix..." -> ${urls.length}');
        if (urls.isNotEmpty) return urls;
      } catch (e) {
        ApiLog.error(path, 'EXCEPTION -> $e');
      }
    }
    return [];
  }

  Future<List<String>> fetchInspectionImages(String vehicleId) async {
    debugPrint('$_imgTag fetchInspectionImages() CALLED -> vehicleId=$vehicleId');
    try {
      final headers = await SecureStorage.authHeaders();
      final url = Uri.parse("${ApiConstants.baseUrl}/api/Inspection/ListImages?vehicleId=$vehicleId");
      debugPrint('$_imgTag GET -> $url');

      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 20));
      debugPrint('$_imgTag RESPONSE <- HTTP ${response.statusCode}');
      debugPrint('$_imgTag RESPONSE body -> "${response.body}"');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['message'] is String) {
          final msg = (data['message'] as String).trim();
          if (msg.isEmpty) {
            debugPrint('$_imgTag ListImages: message field is EMPTY -> no images on server for this vehicleId');
            return [];
          }
          final urls = msg.split(',').map((e) => e.trim()).where((e) => e.startsWith('http')).toList();
          debugPrint('$_imgTag ListImages: parsed ${urls.length} url(s) -> $urls');
          return urls;
        }
        debugPrint('$_imgTag ListImages: unexpected response shape -> $data');
      } else {
        debugPrint('$_imgTag ListImages FAILED -> HTTP ${response.statusCode}');
      }
      return [];
    } catch (e, st) {
      debugPrint('$_imgTag ❌ fetchInspectionImages EXCEPTION -> $e\n$st');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  9. GET VEHICLE INSPECTION RECORD
  // ═══════════════════════════════════════════════════════════
  Future<VehicleInspectionResponse?> getInspectionRecord(String vehicleId) async {
    final int? vIdInt = int.tryParse(vehicleId);
    if (vIdInt != null && vIdInt < 0) {
      final realId = await _resolveRealVehicleId(vehicleId);
      if (realId != null) {
        return getInspectionRecord(realId.toString());
      }
      return _buildOfflineInspectionResponse(vIdInt);
    }

    final isOnline = await _isOnline();

    if (isOnline) {
      try {
        final headers = await SecureStorage.authHeaders();
        final url = Uri.parse("${ApiConstants.baseUrl}/api/Inspection/GetInspectionRecordForVehicle/$vehicleId");
        final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body);
          if (jsonData["didError"] == true) {
            Get.snackbar("Backend Error", jsonData["errorMessage"] ?? "Unknown error");
            return null;
          }

          final prefs = await SharedPreferences.getInstance();
          final protectedAt = prefs.getInt('cache_protected_$vehicleId');
          final isProtected = protectedAt != null &&
              (DateTime.now().millisecondsSinceEpoch - protectedAt) < 300000;

          if (isProtected) {
            final cached = OfflineHiveService.getInspectionCache(vehicleId);
            if (cached != null) {
              return VehicleInspectionResponse.fromJson(jsonDecode(cached));
            }
            return VehicleInspectionResponse.fromJson(jsonData);
          }

          await OfflineHiveService.saveInspectionCache(vehicleId, response.body);
          return VehicleInspectionResponse.fromJson(jsonData);
        }
        debugPrint('🔧 [VIC_DEBUG] getInspectionRecord($vehicleId): HTTP ${response.statusCode}');
        return null;
      } catch (e) {
        debugPrint('🔧 [VIC_DEBUG] getInspectionRecord($vehicleId) EXCEPTION -> $e');
      }
    }

    final cached = OfflineHiveService.getInspectionCache(vehicleId);
    if (cached != null) {
      try {
        final jsonData = jsonDecode(cached);
        return VehicleInspectionResponse.fromJson(jsonData);
      } catch (e) {
        return null;
      }
    }

    final fallbackInt = int.tryParse(vehicleId);
    if (fallbackInt != null) {
      return _buildOfflineInspectionResponse(fallbackInt);
    }
    return null;
  }

  Future<bool> updateHours(String vehicleId, String hours) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  // ── Helpers ───────────────────────────────────────────────
  Future<int?> _resolveRealVehicleId(String tempId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('vehicle_real_id_$tempId');
    } catch (e) {
      return null;
    }
  }

  VehicleInspectionResponse? _buildOfflineInspectionResponse(int vehicleId) {
    final h = OfflineHiveService.getVehicleById(vehicleId);
    if (h == null) return null;

    List<InstalledTire> cachedTires = [];
    final cachedJson = OfflineHiveService.getInspectionCache(vehicleId.toString());
    if (cachedJson != null) {
      try {
        final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
        final model = decoded['model'] as Map<String, dynamic>?;
        final rawTires = model?['installedTires'] as List<dynamic>? ?? [];
        cachedTires = rawTires
            .whereType<Map<String, dynamic>>()
            .map((t) => InstalledTire.fromJson(t))
            .toList();
      } catch (_) {}
    }

    final int trackingVal = h.trackingMethod ?? int.tryParse(h.mileageType ?? '3') ?? 3;
    String vehicleMileageType;
    switch (trackingVal) {
      case 1:
        vehicleMileageType = 'Hours';
        break;
      case 2:
        vehicleMileageType = 'Distance';
        break;
      default:
        vehicleMileageType = h.mileageType ?? 'Both';
    }

    final model = VehicleInspectionModel(
      vehicleId: vehicleId,
      vehicleNumber: h.vehicleNumber,
      vehicleType: h.typeName ?? '',
      vehicleModel: h.modelName ?? '',
      axleConfig: h.axleConfig ?? '22',
      vehicleManufacturer: h.manufacturerName ?? '',
      tireSize: h.tireSizeName ?? '',
      tireSizeId: h.tireSizeId,
      installedTires: cachedTires,
      lastRecordedHours: h.currentHours,
      lastRecordedMiles: h.currentMiles,
      vehicleMileageType: vehicleMileageType,
      comments: h.severityComments ?? '',
    );

    return VehicleInspectionResponse(
      didError: false,
      message: 'Offline vehicle',
      model: model,
    );
  }

  static Future<bool> _isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}