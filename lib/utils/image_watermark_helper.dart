import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart' show DateFormat;

Uint8List _encodeJpgWorker(({Uint8List rgbaBytes, int width, int height}) args) {
  final rawImage = img.Image.fromBytes(
    width: args.width,
    height: args.height,
    bytes: args.rgbaBytes.buffer,
    order: img.ChannelOrder.rgba,
  );
  return Uint8List.fromList(img.encodeJpg(rawImage, quality: 80));
}

/// Helper to permanently stamp CCTV / Timestamp Camera style date & time
/// directly onto image pixels before storage or upload.
/// Resizes camera photos to reasonable dimensions (max 1600px) and compresses to JPEG
/// to prevent multi-megabyte payloads while maintaining sharp, legible quality.
class ImageWatermarkHelper {
  ImageWatermarkHelper._();

  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static const int _maxDimension = 1600;
  static final Set<String> _stampedPaths = <String>{};

  /// Adds a CCTV / Timestamp Camera style date & time directly onto the image pixels,
  /// resizes to max dimension if needed, and encodes as high-efficiency JPEG.
  static Future<File> stampImage(File file, {DateTime? captureTime}) async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    ui.Picture? picture;
    ui.Image? stampedImage;

    try {
      if (_stampedPaths.contains(file.path)) return file;
      if (!await file.exists()) return file;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return file;

      // 1. Probe dimensions from encoded header without decoding full-res pixels into RAM
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final origWidth = descriptor.width;
      final origHeight = descriptor.height;

      int targetW = origWidth;
      int targetH = origHeight;

      if (origWidth > _maxDimension || origHeight > _maxDimension) {
        if (origWidth >= origHeight) {
          targetW = _maxDimension;
          targetH = (origHeight * _maxDimension / origWidth).round();
        } else {
          targetH = _maxDimension;
          targetW = (origWidth * _maxDimension / origHeight).round();
        }
      }

      // 2. Decode directly at target dimensions
      codec = (targetW != origWidth || targetH != origHeight)
          ? await descriptor.instantiateCodec(targetWidth: targetW, targetHeight: targetH)
          : await descriptor.instantiateCodec();
      final frame = await codec.getNextFrame();
      image = frame.image;

      final int width = image.width;
      final int height = image.height;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      );

      // Draw original/downscaled image
      canvas.drawImage(image, Offset.zero, Paint());

      // Free decoded source image before encoding
      image.dispose();
      image = null;

      // Prepare timestamp string
      final time = captureTime ?? DateTime.now();
      final text = _dateFormat.format(time);

      // CCTV style sizing relative to image resolution
      final double fontSize = (width * 0.028).clamp(16.0, 48.0);
      final double paddingH = fontSize * 0.6;
      final double paddingV = fontSize * 0.35;

      final textSpan = TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xFFFFEB3B), // CCTV bright yellow
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          shadows: const [
            Shadow(
              color: Colors.black,
              offset: Offset(1.5, 1.5),
              blurRadius: 3,
            ),
          ],
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();

      final boxWidth = textPainter.width + (paddingH * 2);
      final boxHeight = textPainter.height + (paddingV * 2);

      // Bottom-right corner with margin
      final margin = width * 0.025;
      final boxLeft = width - boxWidth - margin;
      final boxTop = height - boxHeight - margin;

      // Dark background box (CCTV style)
      final bgPaint = Paint()
        ..color = const Color(0xCC000000) // 80% opacity black
        ..style = PaintingStyle.fill;

      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight),
        Radius.circular(fontSize * 0.25),
      );
      canvas.drawRRect(bgRect, bgPaint);

      // Subtle CCTV border
      final borderPaint = Paint()
        ..color = const Color(0x66FFEB3B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRRect(bgRect, borderPaint);

      // Paint text
      textPainter.paint(canvas, Offset(boxLeft + paddingH, boxTop + paddingV));

      picture = recorder.endRecording();
      stampedImage = await picture.toImage(width, height);
      picture.dispose();
      picture = null;

      final byteData = await stampedImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      stampedImage.dispose();
      stampedImage = null;

      if (byteData != null) {
        final rgbaCopy = Uint8List.fromList(
          byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        );
        // Encode JPEG in background isolate so UI thread never freezes
        final jpgBytes = await Isolate.run(
          () => _encodeJpgWorker((rgbaBytes: rgbaCopy, width: width, height: height)),
        );
        await file.writeAsBytes(jpgBytes, flush: true);
        _stampedPaths.add(file.path);
        debugPrint('📸 [Watermark] CCTV timestamp stamped & compressed (JPEG ~80%): $text on ${file.path} (${(jpgBytes.length / 1024).toStringAsFixed(1)} KB)');
      }
      return file;
    } catch (e, st) {
      debugPrint('📸 [Watermark] Error stamping watermark: $e\n$st');
      return file;
    } finally {
      stampedImage?.dispose();
      picture?.dispose();
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
  }
}
