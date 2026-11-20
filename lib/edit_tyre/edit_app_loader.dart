import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppLoader {
  static void show() {
    if (Get.isDialogOpen == true) return;

    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Colors.red)),
      barrierDismissible: false,
    );
  }

  static void hide() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }
}
