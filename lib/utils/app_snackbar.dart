import 'package:flutter/material.dart';
import 'package:get/get.dart';

class _NetworkOffIcon extends StatelessWidget {
  const _NetworkOffIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: CustomPaint(painter: const _NetworkOffPainter()),
    );
  }
}

class _NetworkOffPainter extends CustomPainter {
  const _NetworkOffPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    /// Bar 1 — short, faint
    canvas.drawRRect(
      RRect.fromLTRBR(
        w * 0.04, h * 0.60, w * 0.22, h * 0.95,
        const Radius.circular(3),
      ),
      Paint()
        ..color = Colors.white.withAlpha(115)
        ..style = PaintingStyle.fill,
    );

    /// Bar 2 — medium
    canvas.drawRRect(
      RRect.fromLTRBR(
        w * 0.28, h * 0.40, w * 0.46, h * 0.95,
        const Radius.circular(3),
      ),
      Paint()
        ..color = Colors.white.withAlpha(166)
        ..style = PaintingStyle.fill,
    );

    /// Bar 3 — tall, full white
    canvas.drawRRect(
      RRect.fromLTRBR(
        w * 0.52, h * 0.15, w * 0.70, h * 0.95,
        const Radius.circular(3),
      ),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    /// Yellow circle — bottom right
    final Offset center = Offset(w * 0.80, h * 0.75);
    final double radius = w * 0.20;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFF9C12E)
        ..style = PaintingStyle.fill,
    );

    /// White diagonal slash inside circle
    canvas.drawLine(
      Offset(center.dx - radius * 0.65, center.dy - radius * 0.65),
      Offset(center.dx + radius * 0.65, center.dy + radius * 0.65),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}

class AppSnackbar {
  static void success(String message, {String title = "Success"}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  static void offlineSuccess(String message, {String title = "Success"}) {
    Get.snackbar(
      "",
      "",
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF0AA52F),
      borderRadius: 12,
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.zero,
      duration: const Duration(seconds: 5),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      titleText: const SizedBox.shrink(),
      messageText: Stack(
        children: [
          /// MAIN CONTENT
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// LEFT — text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Will be synced when you are back online.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                /// RIGHT — Custom icon (replaces Image.asset networkOff.png)
                const Padding(
                  padding: EdgeInsets.only(top: 70),
                  child: _NetworkOffIcon(),
                ),
              ],
            ),
          ),

          /// CLOSE X — top right
          Positioned(
            top: 8,
            right: 10,
            child: GestureDetector(
              onTap: () {
                if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
              },
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void error(String message, {String title = "Error"}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  static void info(String message, {String title = "Info"}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.info, color: Colors.white),
    );
  }
}

// Purana warning function as it is
void warning1(String message, {String title = "Saved Offline"}) {
  Get.snackbar(
    title,
    message,
    backgroundColor: Colors.orange,
    colorText: Colors.white,
    snackPosition: SnackPosition.TOP,
    margin: const EdgeInsets.all(10),
    borderRadius: 8,
    duration: const Duration(seconds: 4),
    icon: const Icon(Icons.cloud_off, color: Colors.white),
  );
}