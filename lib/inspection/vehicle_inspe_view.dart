import 'package:emtrack/inspection/vehicle_inspe_controller.dart';
import 'package:emtrack/routes/app_pages.dart';
import 'package:emtrack/widgets/vehicle_daigram.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../create_tyre/tyre_rotation_controller.dart';
import '../services/role_service.dart';
import '../utils/local_helper.dart';
import '../utils/global_state_referesh.dart';
import '../utils/pending_inspection_guard.dart';
import '../utils/mesurment_helper_class.dart';
import '../utils/reusable_dialog.dart';
import '../utils/local_image_cache.dart';
import '../views/rotate_tyres_view.dart';
import '../l10n/app_localizations.dart';

class VehicleInspeView extends StatefulWidget {
  const VehicleInspeView({super.key});

  @override
  State<VehicleInspeView> createState() => _VehicleInspeViewState();
}

class _VehicleInspeViewState extends State<VehicleInspeView> {
  late VehicleInspeController c;

  void _logView(String msg, [String ansi = '\x1B[36m']) {
    debugPrint('$ansi[VIV_TRACE ${DateTime.now().toIso8601String()}] $msg\x1B[0m');
  }

  @override
  void initState() {
    super.initState();
    _logView('initState() START -> args=${Get.arguments}', '\x1B[32m');

    if (Get.isRegistered<VehicleInspeController>()) {
      _logView('initState() deleting previous VehicleInspeController', '\x1B[33m');
      Get.delete<VehicleInspeController>(force: true);
    }
    c = Get.put(VehicleInspeController());
    _logView('initState() END -> controller registered', '\x1B[32m');
  }

  @override
  void dispose() {
    _logView('dispose() CALLED', '\x1B[31m');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logView('build() START', '\x1B[34m');
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Get.back();
            } else {
              Get.offAllNamed(AppPages.HOME);
            }
          },
        ),
        title: Text(
          t.vehicleInspection,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── PENDING APPROVAL BANNER ───────────────────────────────────
              Obx(() {
                final id = int.tryParse(c.vehicleId.value);
                final pending = id != null &&
                    PendingInspectionGuard.pendingVehicleIds.contains(id);
                if (!pending) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_top_rounded,
                          color: Color(0xFFB45309)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Approval pending — inspection, tyre changes, hours/km update '
                              'and image upload/delete are locked until the approver '
                              'approves or rejects.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF78350F),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // ─── HOUR WARNING ──────────────────────────────────────────────
              Obx(() {
                if (!c.showHourWarning.value) return const SizedBox();
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFD7F2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: c.closeWarning,
                            child: const Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info, size: 30, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                t.hourWarningMsg,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () => c.goToUpdateHours(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              t.updateBtn,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 28),

              // ─── VEHICLE ID ────────────────────────────────────────────────
              Text(
                "${t.vehicleId}:",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: c.vehicleNumberCtrl,
                readOnly: true,
                decoration: _inputDecoration(),
              ),

              const SizedBox(height: 24),

              // ─── HOURS (conditional) ───────────────────────────────────────
              Obx(() {
                if (!c.showHours) return const SizedBox();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.hours,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: c.hoursCtrl,
                      readOnly: true,
                      decoration: _inputDecoration(),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }),

              // ─── KM (conditional) ─────────────────────────
              Obx(() {
                if (!c.showKm) return const SizedBox();

                final currentUnit = MeasurementHelper.distanceLabel;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUnit,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: c.kmDisplayCtrl,
                      readOnly: true,
                      decoration: _inputDecoration(),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }),
              // ─── UPDATE HOURS BUTTON ───────────────────────────────────────
              Builder(
                builder: (context) {
                  final currentUnit = MeasurementHelper.distanceLabel;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Update Hours / $currentUnit", // <-- Dynamic Update Title
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () => c.goToUpdateHours(),
                        icon: const Icon(Icons.sync, color: Colors.red),
                        label: Text(
                          t.updateBtn,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // ─── INSPECTION COMMENTS ──────────────────────────────────────
              const Text(
                'Inspection Comments',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: c.commentsCtrl,
                maxLength: 200,
                readOnly: false,
                maxLines: 3,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: t.commentsHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 1),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                ),
              ),

              // ─── VEHICLE DIAGRAM HEADER ────────────────────────────────────
              Text(
                t.vehicleDiagram,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      " ${t.serialNo} ${LocaleHelper.tyreName(context)}",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.circle, color: Colors.green, size: 10),
                        const SizedBox(width: 4),
                        Text(
                          '${t.inspected} ${LocaleHelper.tyreName(context)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.circle, color: Colors.blue, size: 10),
                        const SizedBox(width: 4),
                        Text(
                          '${t.notInspectedTire} ${LocaleHelper.tyreName(context)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ─── DIAGRAM ──────────────────────────────────────────────────
              Obx(() {
                final response = c.inspectionResponse.value;
                _logView('Obx(VehicleDiagram) -> response=${response != null}, tires=${c.tires.length}, axle=${c.model?.axleConfig}', '\x1B[35m');
                if (response == null) return const Center(child: Text(""));
                // 🔄 Reactively observe active pressure unit so diagram re-renders on PSI/KPA/BAR switch
                if (Get.isRegistered<GlobalPrefsState>()) {
                  Get.find<GlobalPrefsState>().pressure.value;
                }

                return VehicleDiagram(
                  tires: c.tires,
                  vehicleId: int.tryParse(c.vehicleId.value) ?? 0,
                  vehicleNumber: c.vehicleNumberCtrl.text,
                  axleConfig:
                  (c.model?.axleConfig?.trim().isNotEmpty == true)
                      ? c.model!.axleConfig!
                      : "22",
                );
              }),

              const SizedBox(height: 11),

              // ─── COLOR BAR + ROTATE ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        _colorBox('N/I', Colors.grey.shade300),
                        _colorBox('<25', Colors.greenAccent),
                        _colorBox('<50', Colors.yellow),
                        _colorBox('<75', Colors.orange),
                        _colorBox('>75', Colors.redAccent),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tread Depth: (To) Outside (Ti) Inside (Tm) Middle\nPressure (P) ${LocaleHelper.tyreName(context)} Pressure',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 11),
                    Obx(() {
                      final role = Get.isRegistered<AuthController>()
                          ? Get.find<AuthController>().userRole.value
                          : '';
                      if (!RoleService.canEditVehicle(role)) {
                        return const SizedBox.shrink();
                      }
                      return c.tires.isNotEmpty
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () async {
                              final allowed =
                              await PendingInspectionGuard.canProceed(
                                vehicleId: int.tryParse(c.vehicleId.value),
                                vehicleNumber: c.vehicleNumberCtrl.text,
                                action: PendingBlockedAction.rotateTyres,
                              );
                              if (!allowed) return;
                              TyreRotationController.instance
                                  .loadFromInspection();
                              final result = await Get.to(
                                    () => const RotateTyresView(),
                              );
                              if (result == true) {
                                c.tires.refresh();
                              }
                            },
                            icon: const Icon(
                              Icons.sync,
                              color: Colors.red,
                            ),
                            label: Text(
                              'Rotate ${LocaleHelper.tyreName(context)}s',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      )
                          : const SizedBox.shrink();
                    }),
                    const SizedBox(height: 11),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── INSPECTED TYRE IMAGES (with delete option) ────────────────
              Obx(() {
                if (c.inspectedTyreImages.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.uploadedImages,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 250,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: c.inspectedTyreImages.length,
                        itemBuilder: (_, i) {
                          if (i >= c.inspectedTyreImages.length) return const SizedBox.shrink();
                          final item = c.inspectedTyreImages[i];
                          final isHttp = item.pathOrUrl.startsWith('http://') || item.pathOrUrl.startsWith('https://');
                          final cachedLocal = isHttp
                              ? LocalImageCache.resolveSync(item.pathOrUrl, tireId: item.tireId)
                              : null;
                          final hasCachedLocal = LocalImageCache.safeFileExists(cachedLocal);
                          final localFileExists = !isHttp && LocalImageCache.safeFileExists(item.file);

                          Widget imageWidget;
                          if (hasCachedLocal && cachedLocal != null) {
                            imageWidget = Image.file(
                              cachedLocal,
                              fit: BoxFit.cover,
                              cacheWidth: 400,
                              cacheHeight: 400,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                              ),
                            );
                          } else if (isHttp) {
                            imageWidget = Image.network(
                              item.pathOrUrl,
                              fit: BoxFit.cover,
                              cacheWidth: 400,
                              cacheHeight: 400,
                              loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                              ),
                            );
                          } else if (localFileExists) {
                            imageWidget = Image.file(
                              item.file,
                              fit: BoxFit.cover,
                              cacheWidth: 400,
                              cacheHeight: 400,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                              ),
                            );
                          } else {
                            imageWidget = const Center(
                              child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0, top: 8, bottom: 8),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 200,
                                  height: 234,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (item.tireSerial.isNotEmpty || item.wheelPosition.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                                          ),
                                          child: Text(
                                            item.wheelPosition.isNotEmpty && item.tireSerial.isNotEmpty
                                                ? '${item.wheelPosition} • ${item.tireSerial}'
                                                : (item.wheelPosition.isNotEmpty ? item.wheelPosition : item.tireSerial),
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.vertical(
                                            top: item.tireSerial.isNotEmpty || item.wheelPosition.isNotEmpty ? Radius.zero : const Radius.circular(13),
                                            bottom: const Radius.circular(13),
                                          ),
                                          child: imageWidget,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: GestureDetector(
                                    onTap: () {
                                      DialogHelper.showConfirm(
                                        title: t.confirmRemove,
                                        message: t.areYouSureRemoveImage,
                                        confirmText: t.yes,
                                        cancelText: t.no,
                                        onConfirm: () => c.deleteInspectedTyreImage(i),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 18, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }),

              const SizedBox(height: 24),

              // ─── SUBMIT ────────────────────────────────────────────────────
              Builder(
                builder: (context) {
                  final role = Get.isRegistered<AuthController>()
                      ? Get.find<AuthController>().userRole.value
                      : '';
                  if (!RoleService.canEditVehicle(role)) {
                    return Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          t.viewOnlyDisabled,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }
                  return Obx(
                        () => Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: InkWell(
                        onTap: c.isSubmitting.value ? null : c.submit,
                        child: Center(
                          child: c.isSubmitting.value
                              ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : Text(
                            t.submit,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              Center(
                child: TextButton(
                  onPressed: () {
                    DialogHelper.showConfirm(
                      title: t.cancelRequestTitle,
                      message: t.cancelRequestMsg,
                      onConfirm: () {
                        Get.back(closeOverlays: true);
                        Future.delayed(
                          const Duration(milliseconds: 200),
                              () => Get.back(),
                        );
                      },
                    );
                  },
                  child: Text(
                    t.cancel,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _colorBox(String text, Color color) {
    return Expanded(
      child: Container(
        height: 40,
        alignment: Alignment.center,
        color: color,
        child: Text(text),
      ),
    );
  }



  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF3F3F3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }
}
