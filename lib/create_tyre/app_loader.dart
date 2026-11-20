import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppLoader {
  static void show() {
    if (Get.isDialogOpen == true) return;

    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: SizedBox(
                width: 45,
                height: 45,
                child: CircularProgressIndicator(
                  color: Colors.red,
                  strokeWidth: 5,
                ),
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(128),
    );
  }

  static void hide() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }
}