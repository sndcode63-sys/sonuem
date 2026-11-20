import 'package:emtrack/edit_tyre/edit_tyre_controller.dart';
import 'package:emtrack/utils/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../l10n/app_localizations.dart';
import '../utils/local_helper.dart';

class Step4View extends StatelessWidget {
  Step4View({super.key});

  final EditTyreController c = Get.find<EditTyreController>();
  final FocusNode _focusNode = FocusNode();

  String get _currencyLabel {
    final curr = SecureStorage.getCurrency();
    return curr.isNotEmpty ? curr : '0';
  }

  InputDecoration _dec({
    String? hint,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return InputDecoration(
      hintText: hint,
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
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.4)),
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
          hintText: "0",
          controller: c.purchaseCost,
          focusNode: _focusNode,
          clearIcon: true,
          onChanged: (_) => c.calculateNetCost(),
        ),

        Row(children: [Text(t.casingValueB)]),
        _tf(
          hintText: "0",
          controller: c.casingValue,
          onChanged: (_) => c.calculateNetCost(),
        ),

        Row(children: [Text(t.fillType)]),
        _dropdownTF(
          hintText: t.fillType,
          controller: c.fillTypeId,
          onTap: () {
            _fillTypeDialog(
              context: context,
              title: "${t.selectPrefix}${t.fillType}",
              list: c.fillTypeList.toList(),
              controller: c.fillTypeId,
              selectedId: c.selectedFillTypeId,
              idList: c.fillTypeIdList.toList(),
              t: t,
            );
          },
        ),

        Row(children: [Text(t.fillCostC)]),
        _tf(
          hintText: "0",
          controller: c.fillCost,
          onChanged: (_) => c.calculateNetCost(),
        ),

        Row(children: [Text(t.repairCost)]),
        _tf(hintText: "0", controller: c.repairCost, enabled: false),

        Row(children: [Text(t.repairsCostD)]),
        _tf(
          hintText: "0",
          controller: c.repairCost,
          enabled: false,
        ),

        Row(children: [Text(t.numberOfRetreads)]),
        _tf(
          hintText: "0",
          value: c.numberOfRetreadsVal.value,
          enabled: false,
        ),

        Row(children: [Text(t.retreadCostE)]),
        _tf(
          hintText: "0",
          controller: c.retreadCost,
          enabled: false,
        ),

        Row(children: [Text(t.warrantyAdjustmentF)]),
        _tf(
          hintText: "0",
          controller: c.warrantyAdjustment,
          onChanged: (_) => c.calculateNetCost(),
        ),

        Row(children: [Text(t.costAdjustmentG)]),
        _tf(
          hintText: "0",
          controller: c.costAdjustment,
          onChanged: (_) => c.calculateNetCost(),
        ),

        Row(children: [Text(t.soldAmountH)]),
        _tf(
          hintText: "0",
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
          if (c.formKey.currentState!.validate()) await c.updateTyre();
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
        decoration: _dec(
          hint: hintText,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, val, _) {
                    if (val.text.trim().isEmpty) {
                      return const SizedBox.shrink();
                    }
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
            padding: const EdgeInsets.only(top: 10),
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
        decoration: _dec(
          hint: hintText,
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
    required AppLocalizations t,
    RxInt? selectedId,
    List<int>? idList,
  }) {
    final uniqueList = list.toSet().toList();
    String? tempSelected = controller.text.isEmpty ? null : controller.text;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                              ? Colors.grey.withValues(alpha: 0.15)
                              : Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    child: Text(
                      t.cancel,
                      style: const TextStyle(
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
                        if (selectedId != null && idList != null) {
                          final idx = list.indexOf(tempSelected!);
                          if (idx != -1 && idx < idList.length) {
                            selectedId.value = idList[idx];
                          }
                        }
                      }
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      t.okBtn,
                      style: const TextStyle(
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
        ),
      ),
    );
  }

  Widget _primaryBtn(String text, VoidCallback onTap) => Obx(() {
    final busy = c.isSubmitting.value;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: busy ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          disabledBackgroundColor: Colors.red.withAlpha(180),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
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
    );
  });

  Widget _outlineBtn(String text, VoidCallback onTap) => Obx(() {
    final busy = c.isSubmitting.value;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: busy ? null : onTap,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          side: const BorderSide(color: Colors.grey),
        ),
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.red, fontWeight: FontWeight.bold),
        ),
      ),
    );
  });
}