import 'package:emtrack/create_tyre/create_tyre_controller.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../l10n/app_localizations.dart';
import '../utils/local_helper.dart';

class Step4View extends StatelessWidget {
  Step4View({super.key});

  final CreateTyreController c = Get.find<CreateTyreController>();
  final FocusNode _focusNode = FocusNode();

  String get _currencyLabel {
    final curr = SecureStorage.getCurrency();
    return curr.isNotEmpty ? curr : '0';
  }

  InputDecoration _inputDecoration({
    String? hintText,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return InputDecoration(
      hintText: hintText,
      suffixIcon: suffixIcon,
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.withAlpha(102)),
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
    return Column(
      children: [
        Row(
          children: [
            Text("${LocaleHelper.tyreName(context)} ${t.costs}", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 11),

        Row(children: [Text(t.purchaseCostA)]),
        _tf(
          controller: c.purchaseCost,
          focusNode: _focusNode,
          clearIcon: true,
          onChanged: (_) => c.calculateNetCost(),
        ),

        Row(children: [Text(t.casingValueB)]),
        _tf(controller: c.casingValue, onChanged: (_) => c.calculateNetCost()),

        Row(children: [Text(t.selectFillType)]),
        _dropdownTF(
          hintText: t.selectFillType,
          controller: c.fillTypeId,
          onTap: () => _fillTypeDialog(
            context: context,
            title: "Select ${t.selectFillType}",
            list: c.fillTypeList,
            controller: c.fillTypeId,
          ),
        ),

        Row(children: [Text(t.fillCostC)]),
        _tf(
          hintText: "0",
          controller: c.fillCost,
          onChanged: (_) => c.calculateNetCost(),
        ),

        Row(children: [Text(t.repairCost)]),
        _tf(
          hintText: t.repairCost,
          controller: c.repairCost,
          enabled: false,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return t.requiredField;
            if (num.tryParse(v) == null) return t.onlyNumeric;
            return null;
          },
        ),

        Row(children: [Text(t.repairsCostD)]),
        _tf(
          hintText: t.repairsCostD,
          controller: c.repairCost,
          enabled: false,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return t.requiredField;
            if (num.tryParse(v) == null) return t.onlyNumeric;
            return null;
          },
        ),

        Row(children: [Text(t.numberOfRetreads)]),
        _tf(
          hintText: t.numberOfRetreads,
          value: c.numberOfRetreadsVal.value,
          enabled: false,
        ),

        Row(children: [Text(t.retreadCostE)]),
        _tf(
          hintText: t.retreadCostE,
          controller: c.retreadCost,
          enabled: false,
        ),

        Row(children: [Text(t.warrantyAdjustmentF)]),
        _tf(
          hintText: t.warrantyAdjustmentF,
          controller: c.warrantyAdjustment,
          onChanged: (_) => c.calculateNetCost(),
        ),

        Row(children: [Text(t.costAdjustmentG)]),
        _tf(
          hintText: t.costAdjustmentG,
          controller: c.costAdjustment,
          onChanged: (_) => c.calculateNetCost(),
        ),

        Row(children: [Text(t.soldAmountH)]),
        _tf(
          hintText: t.soldAmountH,
          controller: c.soldAmount,
          onChanged: (_) => c.calculateNetCost(),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t.netCost, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              t.netCostFormula,
              style: const TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
          ],
        ),

        _tf(hintText: t.netCost, controller: c.netCost, enabled: false),

        const SizedBox(height: 24),

        _primaryBtn(t.submit, () async {
          if (c.formKey.currentState!.validate()) await c.submitTyre();
        }),
        const SizedBox(height: 12),
        _outlineBtn(t.saveAndClone, () async {
          if (c.formKey.currentState!.validate()) await c.saveAndClone();
        }),
        const SizedBox(height: 12),
        _outlineBtn(t.previousBtn, c.previousStep),
        const SizedBox(height: 12),
        _outlineBtn(t.cancelBtn, c.cancelDialog),
      ],
    );
  }


  Widget _tf({
    String? hintText,
    TextEditingController? controller,
    dynamic value,
    bool enabled = true,
    bool clearIcon = false,
    FocusNode? focusNode,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? value?.toString() : null,
        enabled: enabled,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        focusNode: focusNode,
        validator: validator,
        onChanged: onChanged,
        decoration: _inputDecoration(
          hintText: hintText,
          enabled: enabled,
          suffixIcon: clearIcon && controller != null
              ? IntrinsicWidth(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 25, left: 10),
                  child: Text(
                    _currencyLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, val, _) {
                    if (val.text.trim().isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        controller.clear();
                        onChanged?.call('');
                        focusNode?.requestFocus();
                      },
                    );
                  },
                ),
              ],
            ),
          )
              : Padding(
            padding: const EdgeInsets.only(top: 13),
            child: Text(
              _currencyLabel,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: enabled && !clearIcon ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _dropdownTF({
    required String hintText,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        decoration: _inputDecoration(
          hintText: hintText,
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
      ),
    );
  }

  void _fillTypeDialog({
    required BuildContext context,
    required String title,
    required List<String> list,
    required TextEditingController controller,
  }) {
    final uniqueList = list.toSet().toList();
    String? tempSelected = controller.text.isEmpty ? null : controller.text;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: EdgeInsets.zero,
              titlePadding: const EdgeInsets.symmetric(vertical: 20),
              title: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: Column(
                  children: [
                    const Divider(height: 1, thickness: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: uniqueList.length,
                        itemBuilder: (context, index) {
                          final item = uniqueList[index];
                          final isSelected = tempSelected == item;
                          return InkWell(
                            onTap: () =>
                                setDialogState(() => tempSelected = item),
                            child: Container(
                              color: isSelected
                                  ? Colors.grey.withAlpha(38)
                                  : Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isSelected
                                          ? Colors.red
                                          : Colors.black,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),
                  ],
                ),
              ),
              actionsPadding: EdgeInsets.zero,
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          if (tempSelected != null) {
                            controller.text = tempSelected!;
                            final idx = list.indexOf(tempSelected!);
                            if (idx != -1 && idx < c.fillTypeIdList.length) {
                              c.selectedFillTypeId.value =
                              c.fillTypeIdList[idx];
                            }
                          }
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          "OK",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _primaryBtn(String text, VoidCallback onTap) {
    return Obx(() {
      final busy = c.isSubmitting.value;
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: InkWell(
          onTap: busy ? null : onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.red,
            ),
            child: Center(
              child: busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
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
    });
  }

  Widget _outlineBtn(String text, VoidCallback onTap) {
    return Obx(() {
      final busy = c.isSubmitting.value;
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: InkWell(
          onTap: busy ? null : onTap,
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
    });
  }

  String? _required(String? v) {
    if (v == null || v.trim().isEmpty) return "This field is required";
    if (num.tryParse(v) == null) return "Only numeric values are allowed";
    return null;
  }
}