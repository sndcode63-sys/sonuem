import 'package:emtrack/edit_tyre/edit_tyre_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../l10n/app_localizations.dart';

class Step3View extends StatefulWidget {
  const Step3View({super.key});

  @override
  State<Step3View> createState() => _Step3ViewState();
}

class _Step3ViewState extends State<Step3View> {
  final EditTyreController c = Get.find<EditTyreController>();

  double? outsidePercen;
  double? insidePercent;
  double? middlePercent;
  bool outsideWarn = false;
  bool insideWarn = false;
  bool middleWarn = false;

  final FocusNode _removeAtFocusNode = FocusNode();
  String _removeAtText = "";

  @override
  void initState() {
    super.initState();
    if (c.removeAt.text.isEmpty) c.removeAt.text = "0";
    _removeAtText = c.removeAt.text;
    c.removeAt.addListener(_onRemoveAtChanged);
    _calculate();
  }

  void _onRemoveAtChanged() {
    if (_removeAtText != c.removeAt.text) {
      setState(() => _removeAtText = c.removeAt.text);
    }
  }

  @override
  void dispose() {
    c.removeAt.removeListener(_onRemoveAtChanged);
    _removeAtFocusNode.dispose();
    super.dispose();
  }

  void _calculate() {
    final original = double.tryParse(c.originalTread.text);
    final removeAt = double.tryParse(c.removeAt.text);
    final outside  = double.tryParse(c.outsideTread.text);
    final middle   = double.tryParse(c.middleTread.text);
    final inside   = double.tryParse(c.insideTread.text);

    if (original == null || removeAt == null) return;
    final denominator = original - removeAt;
    if (denominator == 0) return;

    setState(() {
      if (outside != null) {
        outsidePercen = (original > 0 && outside >= original)
            ? 0.0
            : ((1 - (outside - removeAt) / denominator) * 100)
                .roundToDouble()
                .clamp(0.0, 100.0);
        outsideWarn = outsidePercen! > 100 || outsidePercen! < 0;
      } else {
        outsidePercen = 0;
        outsideWarn = false;
      }

      if (middle != null) {
        middlePercent = (original > 0 && middle >= original)
            ? 0.0
            : ((1 - (middle - removeAt) / denominator) * 100)
                .roundToDouble()
                .clamp(0.0, 100.0);
        middleWarn = middlePercent! > 100 || middlePercent! < 0;
      } else {
        middlePercent = 0;
        middleWarn = false;
      }

      if (inside != null) {
        insidePercent = (original > 0 && inside >= original)
            ? 0.0
            : ((1 - (inside - removeAt) / denominator) * 100)
                .roundToDouble()
                .clamp(0.0, 100.0);
        insideWarn = insidePercent! > 100 || insidePercent! < 0;
      } else {
        insidePercent = 0;
        insideWarn = false;
      }
    });
  }

  // ✅ Localized Required Validator
  String? _requiredWithWorn(String? v, AppLocalizations t) {
    if (v == null || v.trim().isEmpty) return null;
    if (num.tryParse(v) == null) return t.onlyNumeric;
    return null;
  }

  InputDecoration _inputDecoration({
    String? hint,
    Widget? suffixIcon,
    String? suffixText,
    TextStyle? suffixStyle,
    bool warn = false,
  }) {
    final borderColor = warn ? Colors.red : Colors.grey;
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      suffixStyle: suffixStyle,
      border: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.orange),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Obx(() {
      final unit = c.measurementUnit.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Builder(
            builder: (_) {
              final treadCount = c.noOfTreadDepthReadings.value;
              final outside = double.tryParse(c.outsideTread.text);
              final middle  = (treadCount == 3)
                  ? double.tryParse(c.middleTread.text)  : null;
              final inside  = (treadCount == 2 || treadCount == 3)
                  ? double.tryParse(c.insideTread.text)  : null;

              String depthText = "${t.treadDepth}($unit)";
              final validVals = [outside, middle, inside].whereType<double>().toList();
              if (validVals.isNotEmpty) {
                final avg = validVals.reduce((a, b) => a + b) / validVals.length;
                final avgStr = avg == avg.truncateToDouble()
                    ? avg.toInt().toString()
                    : avg.toStringAsFixed(1);
                depthText = "${t.treadDepth}: $avgStr $unit";
              }
              return Text(depthText,
                  style: const TextStyle(fontWeight: FontWeight.bold));
            },
          ),
          const SizedBox(height: 11),
          _label("${t.originalTread} ($unit)", required: true),
          _tf(
            hint: "${t.enter} ${t.originalTread}",
            controller: c.originalTread,
            validator: (v) => _required(v, t),
            onChanged: (_) => _calculate(),
          ),

          // _label("${t.removeAt} ($unit)", required: true),
          // Padding(
          //   padding: const EdgeInsets.only(bottom: 14),
          //   child: TextFormField(
          //     controller: c.removeAt,
          //     focusNode: _removeAtFocusNode,
          //     readOnly: true, /
          //     keyboardType: TextInputType.number,
          //     validator: (v) => _required(v, t),
          //     autovalidateMode: AutovalidateMode.onUserInteraction,
          //     inputFormatters: [_decimalOnlyFormatter()],
          //     onChanged: (_) => _calculate(),
          //     decoration: _inputDecoration(
          //       hint: t.removeAt,
          //       suffixIcon: null,
          //     ),
          //   ),
          // ),

          _label("${t.purchaseTread} ($unit)"),
          _tf(
            hint: "${t.enter} ${t.purchaseTread}",
            controller: c.purchasedTread,
            onChanged: (_) => _calculate(),
          ),

          _label("${t.outside} ($unit) (a)", required: true),
          _suffixTF(
            controller: c.outsideTread,
            percent: outsidePercen ?? 0,
            warn: outsideWarn,
            validator: (v) => _requiredWithWorn(v, t),
            onChanged: (_) => _calculate(),
            t: t,
          ),

          if (c.noOfTreadDepthReadings.value == 3) ...[
            _label("${t.middleTread} ($unit) (b)", required: true),
            _suffixTF(
              controller: c.middleTread,
              percent: middlePercent ?? 0,
              warn: middleWarn,
              validator: (v) => _requiredWithWorn(v, t),
              onChanged: (_) => _calculate(),
              t: t,
            ),
          ],

          if (c.noOfTreadDepthReadings.value == 2 ||
              c.noOfTreadDepthReadings.value == 3) ...[
            _label("${t.inside} ($unit) (c)", required: true),
            _suffixTF(
              controller: c.insideTread,
              percent: insidePercent ?? 0,
              warn: insideWarn,
              validator: (v) => _requiredWithWorn(v, t),
              onChanged: (_) => _calculate(),
              t: t,
            ),
          ],


          const SizedBox(height: 24),

          _primaryBtn(t.nextBtn, () {
            final valid = c.formKey.currentState?.validate() ?? false;
            if (valid) c.nextStep();
          }),
          const SizedBox(height: 12),
          _outlineBtn(t.previousBtn, c.previousStep),
          const SizedBox(height: 12),
          _outlineBtn(t.cancelBtn, c.cancelDialog),
        ],
      );
    });
  }

  Widget _tf({
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        validator: validator,
        onChanged: onChanged,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        inputFormatters: [_decimalOnlyFormatter()],
        decoration: _inputDecoration(hint: hint),
      ),
    );
  }

  Widget _suffixTF({
    required TextEditingController controller,
    required double percent,
    required bool warn,
    required AppLocalizations t,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    final isEmpty = controller.text.trim().isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            validator: validator,
            onChanged: onChanged,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            inputFormatters: [_decimalOnlyFormatter()],
            decoration: _inputDecoration(
              warn: warn || isEmpty,
              suffixText: (warn || isEmpty) ? null : "${percent.toStringAsFixed(0)}${t.wornPercent}",
              suffixStyle: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          if (warn || isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                isEmpty
                    ? "0${t.wornPercent} - ${t.wornWarning}"
                    : "${percent.toInt()}${t.wornPercent} - ${t.wornWarning}",
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          if (isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "⚠️ ${t.enterValidDetails}",
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  TextInputFormatter _decimalOnlyFormatter() {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      final text = newValue.text;
      if (text.contains(',')) return oldValue;
      if (text.isEmpty) return newValue;
      if (!RegExp(r'^\d*\.?\d*$').hasMatch(text)) return oldValue;
      if ('.'.allMatches(text).length > 1) return oldValue;
      return newValue;
    });
  }

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(text),
          if (required) const Text(" *", style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  String? _required(String? v, AppLocalizations t) {
    if (v == null || v.trim().isEmpty) return "⚠️ ${t.enterValidDetails}";
    if (num.tryParse(v) == null) return t.onlyNumeric;
    return null;
  }

  Widget _primaryBtn(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.red,
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _outlineBtn(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey, width: 1),
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}