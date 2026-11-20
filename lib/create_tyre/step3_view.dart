import 'package:emtrack/create_tyre/create_tyre_controller.dart';
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
  final CreateTyreController c = Get.find<CreateTyreController>();

  double? outsidePercen;
  double? middlePercent;
  double? insidePercent;
  bool outsideWarn = false;
  bool middleWarn = false;
  bool insideWarn = false;

  final FocusNode _removeAtFocusNode = FocusNode();
  String _removeAtText = "";

  @override
  void initState() {
    super.initState();
    if (c.removeAt.text.isEmpty) c.removeAt.text = "0";
    if (c.middleTread.text.isEmpty) c.middleTread.text = "0";
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
    final outside = double.tryParse(c.outsideTread.text);
    final middle = double.tryParse(c.middleTread.text);
    final inside = double.tryParse(c.insideTread.text);

    if (original == null || removeAt == null) return;
    final denominator = original - removeAt;
    if (denominator == 0) return;

    setState(() {
      // Outside
      if (outside != null) {
        outsidePercen = ((1 - (outside - removeAt) / denominator) * 100)
            .roundToDouble();
        outsideWarn = outsidePercen! > 100 || outsidePercen! < 0;
      } else {
        outsidePercen = 0;
        outsideWarn = false;
      }

      if (middle != null) {
        middlePercent = ((1 - (middle - removeAt) / denominator) * 100)
            .roundToDouble();
        middleWarn = middlePercent! > 100 || middlePercent! < 0;
      } else {
        middlePercent = 0;
        middleWarn = false;
      }

      // Inside
      if (inside != null) {
        insidePercent = ((1 - (inside - removeAt) / denominator) * 100)
            .roundToDouble();
        insideWarn = insidePercent! > 100 || insidePercent! < 0;
      } else {
        insidePercent = 0;
        insideWarn = false;
      }
    });
  }

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
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: borderColor),
      ),
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
              final middle = (treadCount == 3)
                  ? double.tryParse(c.middleTread.text)
                  : null;
              final inside = (treadCount == 2 || treadCount == 3)
                  ? double.tryParse(c.insideTread.text)
                  : null;

              String depthText = "${t.treadDepthUnit}($unit)";
              final validVals = [
                outside,
                middle,
                inside,
              ].whereType<double>().toList();
              if (validVals.isNotEmpty) {
                final avg =
                    validVals.reduce((a, b) => a + b) / validVals.length;
                final avgStr = avg == avg.truncateToDouble()
                    ? avg.toInt().toString()
                    : avg.toStringAsFixed(1);
                depthText = "${t.treadDepthUnit}: $avgStr $unit";
              }
              return Text(
                depthText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              );
            },
          ),
          const SizedBox(height: 11),

          _label("${t.originalTreadUnit} ($unit)", required: true),
          _tf(
            hint: t.enterOriginalTread,
            controller: c.originalTread,
            validator: (v) {
              if (v == null || v.trim().isEmpty)
                return "⚠️ ${t.enterValidDetails}";
              if (num.tryParse(v) == null) return t.onlyNumeric;
              return null;
            },
            onChanged: (_) => _calculate(),
          ),

          //
          // _label("${t.removeAtUnit} ($unit)", required: true),
          // Padding(
          //   padding: const EdgeInsets.only(bottom: 14),
          //   child: TextFormField(
          //     controller: c.removeAt,
          //     focusNode: _removeAtFocusNode,
          //     readOnly: true,
          //     keyboardType: TextInputType.number,
          //     validator: (v) {
          //       if (v == null || v.trim().isEmpty) {
          //         return "⚠️ ${t.enterValidDetails}";
          //       }
          //       if (num.tryParse(v) == null) return t.onlyNumeric;
          //       return null;
          //     },
          //     autovalidateMode: AutovalidateMode.onUserInteraction,
          //     inputFormatters: [_decimalOnlyFormatter()],
          //     onChanged: (_) => _calculate(),
          //     decoration: _inputDecoration(hint: t.removeAt),
          //   ),
          // ),
          _label("${t.purchaseTreadUnit} ($unit)"),
          _tf(
            hint: t.enterPurchaseTread,
            controller: c.purchasedTread,
            onChanged: (_) => _calculate(),
          ),

          _label("${t.outsideUnit} ($unit)", required: true),
          _suffixTF(
            controller: c.outsideTread,
            percent: outsidePercen ?? 0,
            warn: outsideWarn,
            wornLabel: t.wornPercent,
            warningMsg: t.wornWarning,
            validDetails: t.enterValidDetails,
            validator: (v) => _requiredWithWorn(v, t),
            onChanged: (_) => _calculate(),
          ),

          if (c.noOfTreadDepthReadings.value == 3) ...[
            _label("Middle Tread ($unit)", required: true),
            _suffixTF(
              controller: c.middleTread,
              percent: middlePercent ?? 0,
              warn: middleWarn,
              wornLabel: t.wornPercent,
              warningMsg: t.wornWarning,
              validDetails: t.enterValidDetails,
              isRequired: true,
              validator: (v) => _requiredWithWorn(v, t),
              onChanged: (_) => _calculate(),
            ),
          ],

          if (c.noOfTreadDepthReadings.value == 2 ||
              c.noOfTreadDepthReadings.value == 3) ...[
            _label("${t.insideUnit} ($unit)", required: true),
            _suffixTF(
              controller: c.insideTread,
              percent: insidePercent ?? 0,
              warn: insideWarn,
              wornLabel: t.wornPercent,
              warningMsg: t.wornWarning,
              validDetails: t.enterValidDetails,
              validator: (v) => _requiredWithWorn(v, t),
              onChanged: (_) => _calculate(),
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
    required String wornLabel,
    required String warningMsg,
    required String validDetails,
    bool isRequired = true,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    final text = controller.text.trim();
    final isEmpty = text.isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            validator: validator,
            onChanged: (val) {
              onChanged?.call(val);
              _calculate();
            },
            autovalidateMode: AutovalidateMode.always,
            inputFormatters: [_decimalOnlyFormatter()],
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: (isRequired && isEmpty) ? Colors.red : Colors.grey,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              suffixText: !isEmpty
                  ? "${percent.toStringAsFixed(0)}$wornLabel"
                  : null,
              suffixStyle: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          if ((isRequired && isEmpty) || (!isEmpty && warn))
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (warn || (isEmpty && isRequired))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        isEmpty
                            ? "500$wornLabel - $warningMsg"
                            : "${percent.toInt()}$wornLabel - $warningMsg",
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  if (isEmpty && isRequired)
                    Text(
                      "⚠️ $validDetails",
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
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
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
