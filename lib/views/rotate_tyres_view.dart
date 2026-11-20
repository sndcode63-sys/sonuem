import 'package:emtrack/color/app_color.dart';
import 'package:emtrack/inspection/vehicle_inspe_controller.dart';
import 'package:emtrack/utils/app_loader.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:emtrack/widgets/vehicle_daigram_Rotate_tyres.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../create_tyre/tyre_rotation_controller.dart';
import '../l10n/app_localizations.dart';
import '../utils/app_snackbar.dart';
import '../utils/local_helper.dart';
import '../utils/reusable_dialog.dart';

class RotateTyresView extends StatefulWidget {
  const RotateTyresView({super.key});

  @override
  State<RotateTyresView> createState() => _RotateTyresViewState();
}

class _RotateTyresViewState extends State<RotateTyresView> {
  String _parentAccountName = '';
  String _vehicleId = '';

  final GlobalKey _bufferAnchorKey = GlobalKey();
  double _bufferTop = 160.0;
  final double _bufferRight = 16.0;

  @override
  void initState() {
    super.initState();
    _loadInfo();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _measureBufferPosition(),
    );
  }

  void _measureBufferPosition() {
    final ctx = _bufferAnchorKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    setState(() {
      _bufferTop = pos.dy;
    });
  }

  Future<void> _loadInfo() async {
    try {
      final inspeController = Get.find<VehicleInspeController>();
      final parentName = await SecureStorage.getParentAccountName();
      final locationName = await SecureStorage.getLocationId();

      setState(() {
        _parentAccountName =
            '${parentName ?? ''}${locationName != null && locationName.isNotEmpty ? '-$locationName' : ''}';
        _vehicleId = inspeController.vehicleNumberCtrl.text.isNotEmpty
            ? inspeController.vehicleNumberCtrl.text
            : inspeController.vehicleId.value;
      });
    } catch (_) {}
  }

  void _showSnackbar({
    required String title,
    required String message,
    Color backgroundColor = Colors.green,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _SnackbarCard(
        title: title,
        message: message,
        backgroundColor: backgroundColor,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () => entry.remove(),
        duration: duration,
      ),
    );
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Rotate ${LocaleHelper.tyresName(context)}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.selectedAccountLocation,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _parentAccountName.isNotEmpty
                              ? _parentAccountName
                              : '—',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                        const Divider(
                          height: 24,
                          color: Colors.black12,
                          thickness: 1.5,
                        ),
                        Text(
                          "${t.vehicleId}:",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _vehicleId.isNotEmpty ? _vehicleId : '—',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  NotificationListener<ScrollNotification>(
                    onNotification: (_) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _measureBufferPosition(),
                      );
                      return false;
                    },
                    child: Center(
                      child: VehicleDiagramRotateTyres(
                        bufferAnchorKey: _bufferAnchorKey,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Color legend
                  Row(
                    children: [
                      _colorBox('N/I', Colors.grey.shade300),
                      _colorBox('<25', Colors.greenAccent),
                      _colorBox('<50', Colors.yellow),
                      _colorBox('<75', Colors.orange),
                      _colorBox('>75', Colors.redAccent),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      "${t.treadDepth}: (To) ${t.outside} (Ti) ${t.inside} (Tm) Middle\n${t.airPressure} (P) ${LocaleHelper.tyreName(context)} ${t.airPressure}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Save button
                  InkWell(
                    onTap: () async {
                      final inspeController =
                          Get.find<VehicleInspeController>();
                      final controller = TyreRotationController.instance;

                      if (controller.bufferTyre != null) {
                        _showSnackbar(
                          title: t.loading,
                          message: t.placementError,
                          backgroundColor: Colors.red,
                        );
                        return;
                      }

                      if (!controller.hasRotationChanged()) {
                        Get.back();
                        return;
                      }

                      if (!mounted) return;

                      final String tyreName = LocaleHelper.tyreName(context);
                      final String vehicleIdCopy = _vehicleId;

                      TyreRotationController.instance
                          .applyRotationToInspection();
                      inspeController.tires.refresh();

                      if (inspeController.shouldUseTempApi.value) {
                        Get.back(result: true);
                        await Future.delayed(const Duration(milliseconds: 300));
                        AppSnackbar.success(
                          vehicleIdCopy.isNotEmpty
                              ? '$tyreName rotation updated on Vehicle $vehicleIdCopy (Draft).'
                              : '$tyreName rotation applied (Draft).',
                          title: '$tyreName Rotation Applied',
                        );
                        return;
                      }

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const AppLoader1(isLoading: true),
                      );

                      bool submitSuccess = false;
                      bool anyOffline = false;

                      try {
                        final rotResult = await inspeController
                            .submitRotationOnly();
                        submitSuccess = rotResult['success'] ?? false;
                        final savedOff = rotResult['savedOffline'] ?? false;
                        if (savedOff) {
                          submitSuccess = true;
                          anyOffline = true;
                        }
                        await inspeController.refreshAfterTireInspection();
                      } catch (_) {}

                      if (mounted) Navigator.of(context).pop();

                      if (submitSuccess) {
                        Get.back(result: true);
                        await Future.delayed(const Duration(milliseconds: 300));
                        if (anyOffline) {
                          AppSnackbar.offlineSuccess(
                            vehicleIdCopy.isNotEmpty
                                ? '$tyreName rotation updated and saved successful on Vehicle $vehicleIdCopy'
                                : '$tyreName rotation successful.',
                            title: '$tyreName Rotation Successful',
                          );
                        } else {
                          AppSnackbar.success(
                            vehicleIdCopy.isNotEmpty
                                ? '$tyreName rotation updated and saved successful on Vehicle $vehicleIdCopy.'
                                : '$tyreName rotation successful.',
                            title: '$tyreName Rotation Successful',
                          );
                        }
                      } else {
                        _showSnackbar(
                          title: t.save,
                          message: t.noDataAvailable,
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.buttonDanger,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          t.save,
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 11),

                  // Cancel button
                  Center(
                    child: TextButton(
                      onPressed: () {
                        DialogHelper.showConfirm(
                          title: t.cancelRequestTitle,
                          message: t.cancelRequestMessage,
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
                        style: TextStyle(
                          color: AppColors.buttonDanger,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 50),
              top: _bufferTop,
              right: _bufferRight,
              child: const RotateBufferBox(),
            ),
          ],
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
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
      ),
    );
  }
}

class _SnackbarCard extends StatefulWidget {
  final String title;
  final String message;
  final Color backgroundColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;
  final Duration duration;

  const _SnackbarCard({
    required this.title,
    required this.message,
    required this.backgroundColor,
    required this.onDismiss,
    required this.duration,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<_SnackbarCard> createState() => _SnackbarCardState();
}

class _SnackbarCardState extends State<_SnackbarCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
        );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() async {
    if (!mounted) return;
    await _animController.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(51),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 40, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        if (widget.actionLabel != null) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {
                                widget.onAction?.call();
                                _dismiss();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withAlpha(64),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                widget.actionLabel!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: _dismiss,
                      child: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
