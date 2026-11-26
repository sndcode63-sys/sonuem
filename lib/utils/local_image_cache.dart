import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'hive_prefe.dart';

class LocalImageCache {
  LocalImageCache._();

  static Directory? _docsDir;
  static Directory? _inspectImagesDir;
  static Directory? _vehicleImagesDir;
  static Directory? _cacheDir;
  static final Map<String, String> _memoryMap = {};

  static Future<void> init() async {
    try {
      _docsDir = await getApplicationDocumentsDirectory();
      _inspectImagesDir = Directory(p.join(_docsDir!.path, 'inspect_images'));
      if (!_inspectImagesDir!.existsSync()) {
        _inspectImagesDir!.createSync(recursive: true);
      }
      _vehicleImagesDir = Directory(p.join(_docsDir!.path, 'vehicle_inspection_images'));
      if (!_vehicleImagesDir!.existsSync()) {
        _vehicleImagesDir!.createSync(recursive: true);
      }
      _cacheDir = Directory(p.join(_docsDir!.path, 'image_cache'));
      if (!_cacheDir!.existsSync()) {
        _cacheDir!.createSync(recursive: true);
      }
    } catch (e) {
      debugPrint('[LocalImageCache] init error: $e');
    }
  }

  static Future<void> _ensureDirs() async {
    if (_docsDir == null) {
      await init();
    }
  }

  /// Maps a remote URL to a local file path so offline mode can find it instantly.
  static Future<void> associate(String url, String localPath) async {
    if (url.isEmpty || localPath.isEmpty) return;
    _memoryMap[url] = localPath;
    try {
      final key = 'local_img_cache_${url.hashCode.abs()}';
      HivePref.box.put(key, localPath);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, localPath);
    } catch (_) {}
  }

  /// Safe check if a File object exists and has non-zero size without throwing FileSystemException.
  static bool safeFileExists(File? file) {
    if (file == null) return false;
    try {
      return file.existsSync() && file.lengthSync() > 0;
    } catch (_) {
      return false;
    }
  }

  /// Safe check if a file path exists and is not an HTTP URL.
  static bool safePathExists(String? path) {
    if (path == null || path.trim().isEmpty) return false;
    final clean = path.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) return false;
    try {
      final f = File(clean);
      return f.existsSync() && f.lengthSync() > 0;
    } catch (_) {
      return false;
    }
  }

  /// Synchronous resolver: checks if a local file exists for the given URL or path.
  /// If it's a local file that exists, returns it.
  /// If it's an HTTP URL, checks memory map, Hive, disk cache, tyre and vehicle inspect_images.
  static File? resolveSync(String? pathOrUrl, {dynamic tireId, dynamic vehicleId}) {
    if (pathOrUrl == null || pathOrUrl.trim().isEmpty) return null;
    final clean = pathOrUrl.trim();

    // 1. Direct local file path
    if (!clean.startsWith('http')) {
      try {
        final f = File(clean);
        if (f.existsSync() && f.lengthSync() > 0) return f;
      } catch (_) {}
    }

    // 2. Memory mapping
    if (_memoryMap.containsKey(clean)) {
      try {
        final f = File(_memoryMap[clean]!);
        if (f.existsSync() && f.lengthSync() > 0) return f;
      } catch (_) {}
    }

    // 3. Hive mapping
    try {
      if (Hive.isBoxOpen('preferencesBox')) {
        final key = 'local_img_cache_${clean.hashCode.abs()}';
        final mapped = Hive.box('preferencesBox').get(key) as String?;
        if (mapped != null && mapped.isNotEmpty) {
          final f = File(mapped);
          if (f.existsSync() && f.lengthSync() > 0) return f;
        }
      }
    } catch (_) {}

    // 4. Downloaded image cache directory
    if (_cacheDir != null && clean.startsWith('http')) {
      try {
        final cacheName = 'cache_${clean.hashCode.abs()}.jpg';
        final f = File(p.join(_cacheDir!.path, cacheName));
        if (f.existsSync() && f.lengthSync() > 0) return f;
      } catch (_) {}
    }

    // 5. Tire specific local images in inspect_images directory
    if (tireId != null && _inspectImagesDir != null) {
      try {
        if (_inspectImagesDir!.existsSync()) {
          final cleanBase = p.basename(clean);
          if (cleanBase.isNotEmpty && !clean.startsWith('http')) {
            final candidate = File(p.join(_inspectImagesDir!.path, cleanBase));
            if (candidate.existsSync() && candidate.lengthSync() > 0) {
              return candidate;
            }
          }
        }
      } catch (_) {}
    }

    // 6. Vehicle specific local images in vehicle_inspection_images directory
    if (vehicleId != null && _vehicleImagesDir != null) {
      try {
        if (_vehicleImagesDir!.existsSync()) {
          final cleanBase = p.basename(clean);
          if (cleanBase.isNotEmpty && !clean.startsWith('http')) {
            final candidate = File(p.join(_vehicleImagesDir!.path, cleanBase));
            if (candidate.existsSync() && candidate.lengthSync() > 0) {
              return candidate;
            }
          }
        }
      } catch (_) {}
    }

    return null;
  }

  /// Asynchronous resolver: returns the local File if available, or attempts to download
  /// and cache if online.
  static Future<File?> resolveLocalFile(String? pathOrUrl, {dynamic tireId, dynamic vehicleId}) async {
    await _ensureDirs();
    final syncResolved = resolveSync(pathOrUrl, tireId: tireId, vehicleId: vehicleId);
    if (syncResolved != null) return syncResolved;

    if (pathOrUrl != null && pathOrUrl.startsWith('http')) {
      final downloaded = await cacheNetworkImage(pathOrUrl);
      if (downloaded != null && downloaded.existsSync()) return downloaded;
    }

    // Check temp IDs associated with real tireId
    if (tireId != null && _inspectImagesDir != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final tidInt = int.tryParse(tireId.toString());
        if (tidInt != null && tidInt > 0) {
          for (final k in prefs.getKeys()) {
            if (k.startsWith('tyre_real_id_') && prefs.getInt(k) == tidInt) {
              final tempId = k.replaceFirst('tyre_real_id_', '');
              final files = _inspectImagesDir!.listSync().whereType<File>();
              for (final f in files) {
                final bn = p.basename(f.path);
                if (bn.startsWith('tire_${tempId}_') && f.existsSync()) {
                  return f;
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    // Check vehicle images
    if (vehicleId != null && _vehicleImagesDir != null && _vehicleImagesDir!.existsSync()) {
      try {
        final vFiles = await getLocalImagesForVehicle(vehicleId);
        if (vFiles.isNotEmpty) return vFiles.first;
      } catch (_) {}
    }

    return null;
  }

  /// Downloads an HTTP image and caches it locally so it works offline later.
  static Future<File?> cacheNetworkImage(String url) async {
    if (!url.startsWith('http')) return null;
    await _ensureDirs();
    if (_cacheDir == null) return null;

    final cacheName = 'cache_${url.hashCode.abs()}.jpg';
    final targetFile = File(p.join(_cacheDir!.path, cacheName));
    if (targetFile.existsSync() && targetFile.lengthSync() > 0) {
      return targetFile;
    }

    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        await targetFile.writeAsBytes(res.bodyBytes);
        await associate(url, targetFile.path);
        return targetFile;
      }
    } catch (_) {}
    return null;
  }

  /// Returns all local images stored on this device for a given tyre ID.
  static Future<List<File>> getLocalImagesForTire(dynamic tireId) async {
    await _ensureDirs();
    final results = <File>[];
    if (tireId == null || _inspectImagesDir == null || !_inspectImagesDir!.existsSync()) {
      return results;
    }

    final tidStr = tireId.toString();
    try {
      final files = _inspectImagesDir!.listSync().whereType<File>();
      for (final f in files) {
        final bn = p.basename(f.path);
        if (bn.startsWith('tire_${tidStr}_') && f.existsSync()) {
          results.add(f);
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final tidInt = int.tryParse(tidStr);
      if (tidInt != null && tidInt > 0) {
        for (final k in prefs.getKeys()) {
          if (k.startsWith('tyre_real_id_') && prefs.getInt(k) == tidInt) {
            final tempId = k.replaceFirst('tyre_real_id_', '');
            for (final f in files) {
              final bn = p.basename(f.path);
              if (bn.startsWith('tire_${tempId}_') && f.existsSync()) {
                if (!results.any((r) => r.path == f.path)) {
                  results.add(f);
                }
              }
            }
          }
        }
      }
    } catch (_) {}
    return results;
  }

  /// Returns all local images stored on this device for a given vehicle ID.
  static Future<List<File>> getLocalImagesForVehicle(dynamic vehicleId) async {
    await _ensureDirs();
    final results = <File>[];
    if (vehicleId == null || _vehicleImagesDir == null || !_vehicleImagesDir!.existsSync()) {
      return results;
    }

    final vidStr = vehicleId.toString();
    try {
      final files = _vehicleImagesDir!.listSync().whereType<File>();
      for (final f in files) {
        final bn = p.basename(f.path);
        if (bn.startsWith('veh_${vidStr}_') && f.existsSync()) {
          results.add(f);
        }
      }
    } catch (_) {}
    return results;
  }

  /// Clears all local images stored on this device for a given tyre ID.
  static Future<void> clearLocalImagesForTire(dynamic tireId) async {
    await _ensureDirs();
    if (tireId == null || _inspectImagesDir == null || !_inspectImagesDir!.existsSync()) {
      return;
    }

    final tidStr = tireId.toString();
    try {
      final files = _inspectImagesDir!.listSync().whereType<File>();
      final toDelete = <File>[];
      for (final f in files) {
        final bn = p.basename(f.path);
        if (bn.startsWith('tire_${tidStr}_')) {
          toDelete.add(f);
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final tidInt = int.tryParse(tidStr);
      if (tidInt != null && tidInt > 0) {
        for (final k in prefs.getKeys()) {
          if (k.startsWith('tyre_real_id_') && prefs.getInt(k) == tidInt) {
            final tempId = k.replaceFirst('tyre_real_id_', '');
            for (final f in files) {
              final bn = p.basename(f.path);
              if (bn.startsWith('tire_${tempId}_')) {
                if (!toDelete.any((d) => d.path == f.path)) {
                  toDelete.add(f);
                }
              }
            }
          }
        }
      }

      for (final f in toDelete) {
        try {
          if (f.existsSync()) {
            f.deleteSync();
          }
          _memoryMap.removeWhere((_, v) => v == f.path);
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Clears all local images stored on this device for a given vehicle ID.
  static Future<void> clearLocalImagesForVehicle(dynamic vehicleId) async {
    await _ensureDirs();
    if (vehicleId == null || _vehicleImagesDir == null || !_vehicleImagesDir!.existsSync()) {
      return;
    }

    final vidStr = vehicleId.toString();
    try {
      final files = _vehicleImagesDir!.listSync().whereType<File>();
      for (final f in files) {
        final bn = p.basename(f.path);
        if (bn.startsWith('veh_${vidStr}_')) {
          try {
            if (f.existsSync()) {
              f.deleteSync();
            }
            _memoryMap.removeWhere((_, v) => v == f.path);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}
