import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class DialogHelper {
  static void showConfirm({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmText = "Yes",
    String cancelText = "No",
  }) {
    Get.dialog(
      CupertinoAlertDialog(
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Get.back(),
            child: Text(
              cancelText,
              style: const TextStyle(color: CupertinoColors.systemRed), // ✅ Red
            ),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Get.back();
              onConfirm();
            },
            child: Text(
              confirmText,
              style: const TextStyle(color: CupertinoColors.systemRed), // ✅ Red
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}