import 'package:emtrack/color/app_color.dart';
import 'package:flutter/material.dart';
import '../create_tyre/tyre_rotation_controller.dart';
import '../models/tyre_drag_data.dart';
import '../utils/local_helper.dart';

const _kShaftColor   = Color(0xFF4A4A5A);
const _kShaftW       = 8.0;
const _kAxleCircleD  = 44.0;
const _kAxleLineMaxW = 90.0;
const _kAxleGap      = 6.0;
const _kSegH         = 52.0;


const _kDualW  = 68.0;
const _kDualH  = 130.0;
const _kDualR  = 12.0;
const _kDualBW = 3.5;

const _kBufferEmptyH  = 115.0;
const _kBufferFilledH = 170.0;

Color _wornColor(int pct) {
  if (pct >= 75) return const Color(0xFFEF4444);
  if (pct >= 50) return const Color(0xFFF97316);
  if (pct >= 25) return const Color(0xFFEAB308);
  return const Color(0xFF22C55E);
}

//  VehicleDiagramRotateTyres

class VehicleDiagramRotateTyres extends StatefulWidget {
  final GlobalKey? bufferAnchorKey;
  const VehicleDiagramRotateTyres({super.key, this.bufferAnchorKey});

  @override
  State<VehicleDiagramRotateTyres> createState() =>
      _VehicleDiagramRotateTyresState();
}

class _VehicleDiagramRotateTyresState
    extends State<VehicleDiagramRotateTyres> {
  List<int> get _axleDigits {
    final ctrl = TyreRotationController.instance;
    final cfg  = ctrl.axleConfig;
    if (cfg.trim().isEmpty) {
      return List.filled((ctrl.tyres.length / 2).ceil(), 2);
    }
    return cfg
        .split('')
        .where((c) => RegExp(r'[0-9]').hasMatch(c))
        .map((c) => int.tryParse(c) ?? 2)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: TyreRotationController.instance.refreshNotifier,
      builder: (context, _, child) => _buildDiagram(context),
    );
  }

  Widget _buildDiagram(BuildContext context) {
    final digits    = _axleDigits;
    final axleCount = digits.length.clamp(1, 10);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 75),

              SizedBox(
                width: _kDualW,
                child: const Text(
                  'L',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 1,
                  ),
                ),
              ),

              // const SizedBox(width: _kAxleGap),
              // const SizedBox(width: _kAxleLineMaxW),
              const SizedBox(width: _kAxleCircleD),
              // const SizedBox(width: _kAxleLineMaxW),
              const SizedBox(width: _kAxleGap),

              SizedBox(
                width: _kDualW,
                child: const Text(
                  'R',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 1,
                  ),
                ),
              ),

              const SizedBox(width: 10),
              SizedBox(
                width: _kDualW,
                child: const Text('', textAlign: TextAlign.center),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        for (int i = 0; i < axleCount; i++) ...[
          _buildRow(axleIndex: i, tireCount: digits[i]),
          if (i < axleCount - 1) const SizedBox(height: _kSegH),
        ],

        const SizedBox(height: 16),
        const _WornLegend(),
      ],
    );
  }

  Widget _buildRow({required int axleIndex, required int tireCount}) {
    if (tireCount == 4) {
      return _DualAxleRotateRow(
        axleNo: axleIndex + 1,
        onRefresh: () => setState(() {}),
      );
    }
    return _SingleAxleRotateRow(
      axleNo: axleIndex + 1,
      showBuffer: axleIndex == 0,
      onRefresh: () => setState(() {}),
    );
  }
}


//  SINGLE AXLE ROW
class _SingleAxleRotateRow extends StatelessWidget {
  final int axleNo;
  final VoidCallback onRefresh;
  final bool showBuffer;

  const _SingleAxleRotateRow({
    required this.axleNo,
    required this.onRefresh,
    this.showBuffer = false,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = TyreRotationController.instance;
    final iL   = ctrl.slotIndexForPosition('${axleNo}L');
    final iR   = ctrl.slotIndexForPosition('${axleNo}R');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 84),

          // ── LEFT TYRE ──
          _RotateTyreSlot(
            slotIndex: iL,
            width: _kDualW, height: _kDualH,
            radius: _kDualR, borderW: _kDualBW,
            isDual: true, onRefresh: onRefresh,
          ),

          const SizedBox(width: _kAxleGap),
          const _AxleBar(),
          _AxleCircle(axleNo),
          const _AxleBar(),
          const SizedBox(width: _kAxleGap),

          // ── RIGHT TYRE ──
          _RotateTyreSlot(
            slotIndex: iR,
            width: _kDualW, height: _kDualH,
            radius: _kDualR, borderW: _kDualBW,
            isDual: true, onRefresh: onRefresh,
          ),

          // ── BUFFER TRACKING CELL OFFSET ──
          const SizedBox(width: 10),
          SizedBox(
            width: _kDualW,
            height: _kBufferFilledH,
          ),
        ],
      ),
    );
  }
}


//  DUAL AXLE ROW  (4-tyre axle)
class _DualAxleRotateRow extends StatelessWidget {
  final int axleNo;
  final VoidCallback onRefresh;

  const _DualAxleRotateRow({required this.axleNo, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final ctrl = TyreRotationController.instance;
    final iLO  = ctrl.slotIndexForPosition('${axleNo}LO');
    final iLI  = ctrl.slotIndexForPosition('${axleNo}LI');
    final iRI  = ctrl.slotIndexForPosition('${axleNo}RI');
    final iRO  = ctrl.slotIndexForPosition('${axleNo}RO');

    Widget slot(int i) => _RotateTyreSlot(
      slotIndex: i,
      width: _kDualW, height: _kDualH,
      radius: _kDualR, borderW: _kDualBW,
      isDual: true, onRefresh: onRefresh,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 10),
          Row(mainAxisSize: MainAxisSize.min,
              children: [slot(iLO), const SizedBox(width: 3), slot(iLI)]),
          const SizedBox(width: _kAxleGap),
          const _AxleBar(),
          _AxleCircle(axleNo),
          const _AxleBar(),
          const SizedBox(width: _kAxleGap),
          Row(mainAxisSize: MainAxisSize.min,
              children: [slot(iRI), const SizedBox(width: 3), slot(iRO)]),
        ],
      ),
    );
  }
}

void _showCannotRotateDialog(BuildContext context, {required bool isOffline}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cannot Rotate Tyre',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Text(
        isOffline
            ? 'This tyre is offline and has not been synced yet. Please sync the data online before rotating.'
            : "Since approval for this tyre is still pending, it cannot be rotated.",
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

//  RotateTyreSlot
class _RotateTyreSlot extends StatelessWidget {
  final int slotIndex;
  final double width, height, radius, borderW;
  final bool isDual;
  final VoidCallback onRefresh;

  const _RotateTyreSlot({
    required this.slotIndex,
    required this.width, required this.height,
    required this.radius, required this.borderW,
    required this.isDual, required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = TyreRotationController.instance;

    if (slotIndex < 0 || slotIndex >= ctrl.tyres.length) {
      return _EmptyRotateSlot(
          width: width, height: height, radius: radius, hovered: false);
    }

    final data      = ctrl.tyres[slotIndex];
    final isPending = ctrl.isTirePendingApproval(slotIndex);

    return DragTarget<TyreDragData>(
      onWillAcceptWithDetails: (details) {
        final drag = details.data;
        final isDraggedPending =
            drag.slotIndex != -1 &&
                ctrl.isTirePendingApproval(drag.slotIndex);
        if (isDraggedPending) {
          final isOffline = ctrl.isTireOffline(drag.slotIndex);
          _showCannotRotateDialog(context, isOffline: isOffline);
          return false;
        }
        if (isPending) {
          final isOffline = ctrl.isTireOffline(slotIndex);
          _showCannotRotateDialog(context, isOffline: isOffline);
          return false;
        }
        return drag.slotIndex != slotIndex;
      },
      onAcceptWithDetails: (details) {
        final drag = details.data;
        final c = TyreRotationController.instance;
        if (drag.slotIndex == -1) {
          c.placeFromBuffer(slotIndex);
        } else if (c.tyres[slotIndex] != null) {
          c.swapTyres(drag.slotIndex, slotIndex);
        } else {
          c.moveTyre(drag.slotIndex, slotIndex);
        }
        onRefresh();
      },
      builder: (ctx, candidateData, _) {
        final hovered = candidateData.isNotEmpty;
        if (data == null) {
          return _EmptyRotateSlot(
              width: width, height: height, radius: radius, hovered: hovered);
        }
        if (isPending) {
          final isOffline = ctrl.isTireOffline(slotIndex);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showCannotRotateDialog(context, isOffline: isOffline),
            onPanDown: (_) => _showCannotRotateDialog(context, isOffline: isOffline),
            child: _FilledRotateTyre(
              data: data, isPending: isPending, dragging: false,
              width: width, height: height, radius: radius,
              borderW: borderW, isDual: isDual,
            ),
          );
        }
        return Draggable<TyreDragData>(
          data: TyreDragData(diagramIndex: 0, slotIndex: slotIndex),
          maxSimultaneousDrags: 1,
          feedback: Material(
            color: Colors.transparent,
            child: _FilledRotateTyre(
              data: data, isPending: isPending, dragging: true,
              width: width, height: height, radius: radius,
              borderW: borderW, isDual: isDual,
            ),
          ),
          childWhenDragging: _EmptyRotateSlot(
              width: width, height: height, radius: radius,
              hovered: false, placeholder: true),
          child: _FilledRotateTyre(
            data: data, isPending: isPending, dragging: false,
            width: width, height: height, radius: radius,
            borderW: borderW, isDual: isDual,
          ),
        );
      },
    );
  }
}

//  FilledRotateTyre
class _FilledRotateTyre extends StatelessWidget {
  final dynamic data;
  final bool isPending, dragging;
  final double width, height, radius, borderW;
  final bool isDual;

  const _FilledRotateTyre({
    required this.data, required this.isPending, required this.dragging,
    required this.width, required this.height, required this.radius,
    required this.borderW, required this.isDual,
  });

  int get _wornPct {
    final s = (data.percent as String).replaceAll('%', '');
    return int.tryParse(s) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final pct       = _wornPct;
    final bc        = isPending ? Colors.orange.shade600 : _wornColor(pct);
    final bodyColor = dragging
        ? const Color(0xFF1E3A5F)
        : const Color(0xFF1A1A2E);
    final fontSize  = isDual ? 9.0 : 11.0;

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isPending)
            Container(
              margin: const EdgeInsets.only(bottom: 3),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.orange.shade700,
                  borderRadius: BorderRadius.circular(6)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.lock_outline, color: Colors.white, size: 10),
                SizedBox(width: 2),
                Text('Pending',
                    style: TextStyle(color: Colors.white, fontSize: 9)),
              ]),
            )
          else
            const SizedBox.shrink(),
          _SerialBadge(
              serialNo: data.serial as String,
              brandNo: data.brandNo as String?,
              maxWidth: width,
              fontSize: isDual ? 8.0 : 10.0),
          const SizedBox(height: 6),
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                  color: bc, width: isPending ? 3.0 : borderW),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius - borderW),
              child: Stack(children: [
                Container(
                  color: bodyColor,
                  child: CustomPaint(
                      painter: _TyreTexture(),
                      size: Size(width, height)),
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: isDual ? 4 : 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PctChip(
                            pct: pct,
                            color: bc,
                            fontSize: isDual ? 9.0 : 12.0),
                        SizedBox(height: isDual ? 4 : 8),
                        _DataRow(
                            label: 'P',
                            value: data.p as String,
                            fontSize: fontSize),
                        SizedBox(height: isDual ? 2 : 4),
                        _DataRow(
                            label: 'To',
                            value: data.to as String,
                            fontSize: fontSize),
                        SizedBox(height: isDual ? 2 : 4),
                        // ✅ ADDED: Tm (middle tread) row — pehle missing tha,
                        // isliye rotate diagram me sirf P/To/Ti aata tha.
                        // NOTE: `data.tm` field tyre model / TyreDragData me
                        // exist karna chahiye (p/to/ti jaisa hi). Agar
                        // exist nahi karta to model me add karna hoga.
                        _DataRow(
                            label: 'Tm',
                            value: data.tm as String,
                            fontSize: fontSize),
                        SizedBox(height: isDual ? 2 : 4),
                        _DataRow(
                            label: 'Ti',
                            value: data.ti as String,
                            fontSize: fontSize),
                        if (isPending) ...[
                          SizedBox(height: isDual ? 4 : 8),
                          const Icon(Icons.lock,
                              size: 13, color: Colors.white54),
                        ],
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
          SizedBox(height: isDual ? 4 : 6),
          Text(
            data.miles as String,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: isDual ? 8.0 : 10,
                color: Colors.grey.shade600,
                height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _EmptyRotateSlot
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyRotateSlot extends StatelessWidget {
  final double width, height, radius;
  final bool hovered;
  final bool placeholder;

  const _EmptyRotateSlot({
    required this.width, required this.height,
    required this.radius, required this.hovered,
    this.placeholder = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = hovered
        ? Colors.black.withAlpha(166)
        : Colors.black.withAlpha(64);

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 22 + 6),
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: accent, width: 1.8),
              color: hovered
                  ? Colors.black.withValues(alpha: 0.04)
                  : Colors.white,
            ),
            child: Center(
              child: placeholder
                  ? Icon(Icons.swap_vert_rounded, size: 26, color: accent)
                  : Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_circle_outline,
                    size: 28, color: accent),
                const SizedBox(height: 6),
                Text('Drop\nHere',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10,
                        color: accent,
                        height: 1.3)),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          const Text('—\n—',
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.transparent,
                  height: 1.5)),
        ],
      ),
    );
  }
}


//  RotateBufferBox
class RotateBufferBox extends StatefulWidget {
  const RotateBufferBox({super.key});

  @override
  State<RotateBufferBox> createState() => _RotateBufferBoxState();
}

class _RotateBufferBoxState extends State<RotateBufferBox> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: TyreRotationController.instance.refreshNotifier,
      builder: (context, _, child) => _buildBuffer(context),
    );
  }

  Widget _buildBuffer(BuildContext context) {
    final ctrl    = TyreRotationController.instance;
    final tyre    = ctrl.bufferTyre;
    final isEmpty = tyre == null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      width: _kDualW,
      height: isEmpty ? _kBufferEmptyH : _kBufferFilledH,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kDualR),
      ),
      child: DragTarget<TyreDragData>(
        onWillAcceptWithDetails: (details) {
          if (!isEmpty) return false;
          final data = details.data;
          if (data.slotIndex != -1 && ctrl.isTirePendingApproval(data.slotIndex)) {
            final isOffline = ctrl.isTireOffline(data.slotIndex);
            _showCannotRotateDialog(context, isOffline: isOffline);
            return false;
          }
          return true;
        },
        onAcceptWithDetails: (details) {
          final data = details.data;
          if (data.slotIndex == -1) return;
          setState(() => ctrl.moveToBuffer(data.slotIndex));
        },
        builder: (context, candidateData, _) {
          final hovered = candidateData.isNotEmpty;


          if (isEmpty) {
            return Container(
              width: _kDualW,
              height: _kBufferEmptyH,
              decoration: BoxDecoration(
                color: hovered
                    ? AppColors.primary.withValues(alpha: 0.06)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(_kDualR),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_vert_rounded,
                      size: 18,
                      color: AppColors.primary.withValues(alpha: 0.75)),
                  const SizedBox(height: 4),
                  Text(
                    'Rotate\n${LocaleHelper.tyreName(context)}\nPosition',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          }

          // ── FILLED ─────────────────────────────────────────────────────
          final pct = () {
            final s = (tyre.percent).replaceAll('%', '');
            return int.tryParse(s) ?? 0;
          }();
          final wornColor = _wornColor(pct);

          Widget buildContent(bool dragging) {
            return Container(
              width: _kDualW,
              height: _kBufferFilledH,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_kDualR),
                border: Border.all(color: AppColors.primary, width: 1.5),
                color: (hovered && !dragging)
                    ? AppColors.primary.withValues(alpha: 0.04)
                    : Colors.transparent,
              ),
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Serial badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.black87, width: 1),
                    ),
                    child: Text(
                      tyre.serial,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Inner tyre
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius:
                        BorderRadius.circular(_kDualR - 2),
                        border: Border.all(color: wornColor, width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius:
                        BorderRadius.circular(_kDualR - 3.5),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              color: dragging
                                  ? const Color(0xFF1E3A5F)
                                  : const Color(0xFF1A1A2E),
                              child: CustomPaint(
                                  painter: _TyreTexture()),
                            ),
                            Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _PctChip(
                                          pct: pct,
                                          color: wornColor,
                                          fontSize: 9),
                                      const SizedBox(height: 5),
                                      _DataRow(
                                          label: 'P',
                                          value: tyre.p,
                                          fontSize: 8.5),
                                      const SizedBox(height: 3),
                                      _DataRow(
                                          label: 'To',
                                          value: tyre.to,
                                          fontSize: 8.5),
                                      const SizedBox(height: 3),

                                      _DataRow(
                                          label: 'Tm',
                                          value: tyre.tm,
                                          fontSize: 8.5),
                                      const SizedBox(height: 3),
                                      _DataRow(
                                          label: 'Ti',
                                          value: tyre.ti,
                                          fontSize: 8.5),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            );
          }

          return Draggable<TyreDragData>(
            data: TyreDragData(diagramIndex: -1, slotIndex: -1),
            feedback: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: _kDualW,
                height: _kBufferFilledH,
                child: buildContent(true),
              ),
            ),
            onDragEnd: (_) => setState(() {}),
            child: buildContent(false),
          );
        },
      ),
    );
  }
}
//  Shared small widgets
class _WornLegend extends StatelessWidget {
  const _WornLegend();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Color(0xFF22C55E), '< 25%'),
      (Color(0xFFEAB308), '25–50%'),
      (Color(0xFFF97316), '50–75%'),
      (Color(0xFFEF4444), '> 75%'),
    ];
    return Padding(
      padding: const EdgeInsets.only(right: 40.0),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: items
            .map((e) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: e.$1, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(e.$2,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600)),
          ],
        ))
            .toList(),
      ),
    );
  }
}

class _AxleCircle extends StatelessWidget {
  final int axleNo;
  const _AxleCircle(this.axleNo);

  @override
  Widget build(BuildContext context) => Container(
    width: _kAxleCircleD,
    height: _kAxleCircleD,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: _kShaftColor,
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 6,
            offset: const Offset(0, 2))
      ],
    ),
    alignment: Alignment.center,
    child: Text('$axleNo',
        style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700)),
  );
}

class _AxleBar extends StatelessWidget {
  const _AxleBar();

  @override
  Widget build(BuildContext context) => Flexible(
    child: Container(
      constraints:
      const BoxConstraints(maxWidth: _kAxleLineMaxW),
      height: _kShaftW,
      decoration: BoxDecoration(
          color: _kShaftColor,
          borderRadius: BorderRadius.circular(4)),
    ),
  );
}

class _SerialBadge extends StatelessWidget {
  final String serialNo;
  final String? brandNo;
  final double maxWidth;
  final double fontSize;

  const _SerialBadge({
    required this.serialNo,
    this.brandNo,
    required this.maxWidth,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final snText = serialNo.trim().isNotEmpty ? serialNo.trim() : '-';
    final snDisplay = snText.toUpperCase().startsWith('SN:') ||
            snText.toUpperCase().startsWith('SN :')
        ? snText
        : 'SN: $snText';

    final hasBrand = brandNo != null &&
        brandNo!.trim().isNotEmpty &&
        brandNo!.trim().toLowerCase() != 'null';
    final bnRaw = hasBrand ? brandNo!.trim() : '-';
    final bnDisplay = bnRaw.toUpperCase().startsWith('BN:') ||
            bnRaw.toUpperCase().startsWith('BN :')
        ? bnRaw
        : 'BN: $bnRaw';

    return Container(
      width: maxWidth,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black, width: 1)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            snDisplay,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: Colors.black),
          ),
          const SizedBox(height: 1),
          Text(
            bnDisplay,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: Colors.black),
          ),
        ],
      ),
    );
  }
}

class _PctChip extends StatelessWidget {
  final int pct;
  final Color color;
  final double fontSize;

  const _PctChip(
      {required this.pct,
        required this.color,
        required this.fontSize});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
        horizontal: fontSize < 10 ? 6 : 10, vertical: 3),
    decoration: BoxDecoration(
        color: color, borderRadius: BorderRadius.circular(8)),
    child: Text('$pct%',
        textAlign: TextAlign.center,
        style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w700)),
  );
}

class _DataRow extends StatelessWidget {
  final String label, value;
  final double fontSize;

  const _DataRow(
      {required this.label,
        required this.value,
        required this.fontSize});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(label,
          style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w500)),
      const SizedBox(width: 10),
      Text(value,
          style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w600)),
    ],
  );
}

class _TyreTexture extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const step = 10.0;
    for (double d = -size.height;
    d < size.width + size.height;
    d += step) {
      canvas.drawLine(
          Offset(d, 0), Offset(d + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}