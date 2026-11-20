import 'package:emtrack/color/app_color.dart';
import 'package:emtrack/controllers/download_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DownloadView extends StatelessWidget {
  const DownloadView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(DownloadController());

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFEEEEEE),
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 4,
          automaticallyImplyLeading: false,
          title: Obx(() => Text(
            ctrl.progress.value >= 0.85 ? 'Synchronization in progress...' : 'Downloading...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          )),
        ),        body: SafeArea(
          child: Center(
            child: Obx(() {
              if (ctrl.hasError.value) {
                return _ErrorCard(ctrl: ctrl);
              }
              return _ProgressCard(ctrl: ctrl);
            }),
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final DownloadController ctrl;
  const _ProgressCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(76),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Spinner (Sart me)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
            ),
          ),
          const SizedBox(width: 20),

          // Percentage Text
          Expanded(
            child: Obx(() {
              String displayStatus = ctrl.progress.value >= 0.85
                  ? "Syncing Completed..."
                  : "Download Completed...";

              return Text(
                '${(ctrl.progress.value * 100).toInt()}% $displayStatus',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}// Error Card
class _ErrorCard extends StatelessWidget {
  final DownloadController ctrl;
  const _ErrorCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 52, color: Colors.redAccent),
          const SizedBox(height: 14),
          Obx(() => Text(
                ctrl.errorMessage.value,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.red, fontSize: 14),
              )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: ctrl.retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
