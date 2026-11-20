import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../utils/api_logger.dart';
import '../utils/secure_storage.dart';
import '../utils/image_watermark_helper.dart';
import 'api_constants.dart';

/// Result of one CreateImages call (may contain several uploaded files).
class CreateImagesResult {
  final bool success;
  final List<String> urls;
  final String? error;

  const CreateImagesResult({
    required this.success,
    this.urls = const [],
    this.error,
  });

  /// Comma separated blob URLs -> same format the app uses for `imagesLocation`.
  String get joined => urls.join(',');
}

/// Implements the 4 APIs from "EmTrack - CreateImages APIs":
///
///   POST Tire/CreateImages/        tireId        + imgsrc
///   POST Vehicle/CreateImages/     vehicleId     + imgsrc
///   POST Inspection/CreateImages   inspectionId  + imgsrc
///   POST MasterData/CreateImages/  (no id)       + imgsrc
///
/// Rules from the doc:
///  * multipart/form-data
///  * file field name `imgsrc`, filename `{index}_{timestamp}.png`
///  * success -> { didError:false, message:"`<blob url>`" }
///
/// One request is sent per image so every blob URL returned in `message`
/// is captured (the response only carries a single URL).
class ImageUploadService {
  ImageUploadService._();

  // ── Public API ────────────────────────────────────────────

  /// Vehicle Images  ->  Vehicle/CreateImages
  static Future<CreateImagesResult> uploadVehicleImages({
    required int vehicleId,
    required List<File> images,
  }) =>
      _upload(
        apiName: 'Vehicle/CreateImages',
        endpoint: ApiConstants.createVehicleImages,
        idField: 'vehicleId',
        idValue: vehicleId,
        images: images,
      );

  /// Tire Inspection Images  ->  Inspection/CreateImages
  static Future<CreateImagesResult> uploadInspectionImages({
    required int inspectionId,
    required List<File> images,
  }) =>
      _upload(
        apiName: 'Inspection/CreateImages',
        endpoint: ApiConstants.createInspectionImages,
        idField: 'inspectionId',
        idValue: inspectionId,
        images: images,
      );

  /// Tire Images  ->  Tire/CreateImages
  static Future<CreateImagesResult> uploadTireImages({
    required int tireId,
    required List<File> images,
  }) =>
      _upload(
        apiName: 'Tire/CreateImages',
        endpoint: ApiConstants.createTireImages,
        idField: 'tireId',
        idValue: tireId,
        images: images,
      );

  /// Tire Images, but KEEPING the photos the tyre already has on the server.
  ///
  /// Observed behaviour: Tire/CreateImages replaces the tyre's saved photo
  /// list with ONLY the files of the latest upload (3 old + 2 new -> 2 left).
  /// So the existing photos are downloaded and sent again together with the
  /// new ones in the same request; the response then holds all of them.
  /// If an old photo cannot be downloaded, its old URL is still kept in the
  /// returned list.
  static Future<CreateImagesResult> uploadTireImagesKeepingExisting({
    required int tireId,
    required List<File> newImages,
    required List<String> existingUrls,
  }) async {
    final kept = <File>[];
    final notDownloaded = <String>[];
    Directory? tmp;
    try {
      if (existingUrls.isNotEmpty) {
        tmp = await Directory.systemTemp.createTemp('emt_keep_');
        final downloads = await Future.wait(
          existingUrls.asMap().entries.map((entry) async {
            final i = entry.key;
            final u = entry.value;
            try {
              final r = await http.get(Uri.parse(u)).timeout(const Duration(seconds: 8));
              if (r.statusCode == 200 && r.bodyBytes.isNotEmpty) {
                final f = File('${tmp!.path}/old_$i.jpg');
                await f.writeAsBytes(r.bodyBytes);
                return MapEntry(u, f);
              }
            } catch (_) {}
            return MapEntry(u, null);
          }),
        );
        for (final entry in downloads) {
          if (entry.value != null) {
            kept.add(entry.value!);
          } else {
            notDownloaded.add(entry.key);
          }
        }
        ApiLog.info('Tire/CreateImages',
            'existing photos re-sent with new ones: ${kept.length}/${existingUrls.length} downloaded (parallel)');
      }

      final res = await uploadTireImages(
        tireId: tireId,
        images: [...kept, ...newImages],
      );
      if (!res.success) return res;
      return CreateImagesResult(
        success: true,
        urls: [...notDownloaded, ...res.urls],
      );
    } finally {
      try {
        await tmp?.delete(recursive: true);
      } catch (_) {}
    }
  }

  /// Customer Logo  ->  MasterData/CreateImages  (single file, name `0_{ts}.png`)
  static Future<CreateImagesResult> uploadCustomerLogo(File logo) => _upload(
    apiName: 'MasterData/CreateImages',
    endpoint: ApiConstants.createCustomerLogo,
    idField: null,
    idValue: null,
    images: [logo],
  );

  // ── Core ──────────────────────────────────────────────────

  static Future<CreateImagesResult> _upload({
    required String apiName,
    required String endpoint,
    required String? idField,
    required int? idValue,
    required List<File> images,
  }) async {
    if (images.isEmpty) {
      ApiLog.info(apiName, 'ABORT -> no images to upload');
      return const CreateImagesResult(success: false, error: 'No images');
    }
    if (idField != null && (idValue == null || idValue <= 0)) {
      ApiLog.error(apiName,
          'ABORT -> $idField is invalid ($idValue). Server needs a real positive id.');
      return CreateImagesResult(success: false, error: 'Invalid $idField');
    }

    final results = await Connectivity().checkConnectivity();
    if (!results.any((r) => r != ConnectivityResult.none)) {
      ApiLog.error(apiName, 'ABORT -> device is OFFLINE, images stay local');
      return const CreateImagesResult(success: false, error: 'Offline');
    }

    final headers = await SecureStorage.authHeaders();
    headers.remove('Content-Type'); // http sets multipart boundary itself

    final baseQuery = idField != null ? '?$idField=$idValue' : '';
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint$baseQuery');

    final stamp = DateTime.now().millisecondsSinceEpoch;

    // Postman collection: `imgsrc` takes MANY files in ONE request
    // (value "<binary>,<binary>"), so every image is sent in a single
    // multipart call — not one call per image.
    final files = <File>[];
    final names = <String>[];
    for (var i = 0; i < images.length; i++) {
      final f = images[i];
      if (!f.existsSync()) {
        ApiLog.error(apiName, 'SKIP (file missing): ${f.path}');
        continue;
      }
      files.add(f);
      names.add('${files.length - 1}_$stamp.png'); // doc: {index}_{timestamp}.png
    }
    if (files.isEmpty) {
      return const CreateImagesResult(success: false, error: 'File missing');
    }

    await Future.wait(files.map((f) => ImageWatermarkHelper.stampImage(f)));

    try {
      final request = http.MultipartRequest('POST', url)
        ..headers.addAll(headers);
      if (idField != null) request.fields[idField] = idValue.toString();

      for (var i = 0; i < files.length; i++) {
        final ext = files[i].path.split('.').last.toLowerCase();
        request.files.add(await http.MultipartFile.fromPath(
          'imgsrc',
          files[i].path,
          filename: names[i],
          contentType: ext == 'png'
              ? MediaType('image', 'png')
              : MediaType('image', 'jpeg'),
        ));
      }

      ApiLog.request(
        name: '$apiName  (${files.length} image(s) in ONE request)',
        method: 'POST',
        url: url,
        fields: request.fields,
        files: [
          for (var i = 0; i < files.length; i++)
            'imgsrc=${names[i]}  (${files[i].lengthSync()} bytes)'
        ],
      );

      final streamed =
      await request.send().timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamed);

      ApiLog.response(
        name: apiName,
        statusCode: response.statusCode,
        body: response.body,
      );

      if (response.statusCode != 200) {
        return CreateImagesResult(
            success: false, error: 'HTTP ${response.statusCode}');
      }

      String msg = '';
      try {
        final j = jsonDecode(response.body);
        if (j is Map && j['didError'] == true) {
          final err = j['message']?.toString() ?? 'didError=true';
          ApiLog.error(apiName, 'didError=true -> $err');
          return CreateImagesResult(success: false, error: err);
        }
        final m = j is Map ? j['message'] : null;
        msg = m is List ? m.join(',') : (m?.toString() ?? '');
      } catch (_) {
        msg = response.body;
      }

      // `message` may hold one URL or several (comma / space / ; separated)
      final urls = RegExp(r'https?://[^\s,;"\]\[]+')
          .allMatches(msg)
          .map((m) => m.group(0)!)
          .toList();

      if (urls.isEmpty) {
        ApiLog.error(apiName, 'HTTP 200 but no blob URL in "message" (got "$msg")');
        return const CreateImagesResult(
            success: false, error: 'No URL returned');
      }

      // Server returned fewer URLs than files sent (e.g. only the first).
      // Blob name = "<id>_<our filename>" (see doc sample 4975511_0_<ts>.png),
      // so the remaining URLs can be derived from the returned one.
      if (urls.length < files.length) {
        final derived = _deriveMissingUrls(urls, names);
        if (derived.length > urls.length) {
          ApiLog.info(apiName,
              'server returned ${urls.length} URL for ${files.length} files -> derived ${derived.length - urls.length} more from blob naming');
        } else {
          ApiLog.info(apiName,
              'WARNING: server returned ${urls.length} URL for ${files.length} files and naming pattern did not match — cannot derive the rest');
        }
        urls
          ..clear()
          ..addAll(derived);
      }

      for (final u in urls) {
        ApiLog.info(apiName, 'uploaded -> $u');
      }
      return CreateImagesResult(success: true, urls: urls);
    } catch (e) {
      ApiLog.error(apiName, 'EXCEPTION -> $e');
      return CreateImagesResult(success: false, error: e.toString());
    }
  }

  /// Rebuilds URLs for the other uploaded files from one returned URL.
  static List<String> _deriveMissingUrls(
      List<String> returned, List<String> sentNames) {
    final out = <String>[...returned];
    for (final u in returned) {
      final slash = u.lastIndexOf('/');
      if (slash < 0) continue;
      final base = u.substring(0, slash + 1);
      final last = u.substring(slash + 1);
      for (final n in sentNames) {
        if (last.endsWith(n)) {
          final prefix = last.substring(0, last.length - n.length);
          for (final other in sentNames) {
            final cand = '$base$prefix$other';
            if (!out.contains(cand)) out.add(cand);
          }
          return out;
        }
      }
    }
    return out;
  }

  // ── Helpers for the "previous save step" responses ────────

  /// Walks a save-step JSON response and returns every `inspectionId`
  /// it contains, keyed by `tireId` when the same object has one
  /// (key 0 = id without a tire).
  static Map<int, int> extractInspectionIds(String responseBody) {
    final out = <int, int>{};
    int? asInt(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}');

    void walk(dynamic node) {
      if (node is Map) {
        final insp = asInt(node['inspectionId']);
        if (insp != null && insp > 0) {
          out[asInt(node['tireId']) ?? 0] = insp;
        }
        node.values.forEach(walk);
      } else if (node is List) {
        node.forEach(walk);
      }
    }

    try {
      final d = jsonDecode(responseBody);
      walk(d);
      // Some endpoints return the id directly as model / message.
      if (out.isEmpty && d is Map) {
        final m = asInt(d['model']) ?? asInt(d['message']);
        if (m != null && m > 0) out[0] = m;
      }
    } catch (_) {}
    return out;
  }
}