import 'package:emtrack/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/all_tyre_controller.dart';
import '../l10n/app_localizations.dart';
import '../utils/local_helper.dart';
import 'create_tyre_controller.dart';

class Step1View extends StatefulWidget {
  const Step1View({super.key});

  @override
  State<Step1View> createState() => _Step1ViewState();
}

class _Step1ViewState extends State<Step1View> {
  late final CreateTyreController c;
  final FocusNode _hoursFocusNode = FocusNode();
  final FocusNode _kmFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    c = Get.find<CreateTyreController>();
  }

  @override
  void dispose() {
    _hoursFocusNode.dispose();
    _kmFocusNode.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    String? hintText,
    Widget? suffixIcon,
    String? errorText,
    String? suffixText,
    TextStyle? suffixStyle,
  }) {
    return InputDecoration(
      hintText: hintText,
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      suffixStyle: suffixStyle,
      errorText: errorText,
      border: const OutlineInputBorder(),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 1.5),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Obx(() {
      return Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
                Text(
                  t.identificationDetails,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Text(t.tyreSerialNumbers(LocaleHelper.tyreName(context))),
                    const Text("*", style: TextStyle(color: Colors.red)),
                  ],
                ),
                Obx(
                      () => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TextFormField(
                      controller: c.tireSerialNo,
                      autovalidateMode: c.autoValidateFields.value
                          ? AutovalidateMode.always
                          : AutovalidateMode.onUserInteraction,
                      decoration: _inputDecoration(
                        hintText: t.enterItemSerialNumber(
                          LocaleHelper.tyreName(context),
                        ),
                        errorText: c.tireSerialNoError.value.isNotEmpty
                            ? c.tireSerialNoError.value
                            : null,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return t.tyreSerialRequired;
                        }
                        return null;
                      },
                      onChanged: (v) {
                        c.tireSerialNoError.value = '';
                        c.autoValidateFields.value = false;

                        if (v.trim().isEmpty) return;

                        if (Get.isRegistered<AllTyreController>()) {
                          final allTyres =
                              Get.find<AllTyreController>().allTyres;
                          final isDuplicate = allTyres.any(
                                (tyre) =>
                            tyre.tireSerialNo?.toLowerCase().trim() ==
                                v.trim().toLowerCase(),
                          );
                          if (isDuplicate) {
                            c.tireSerialNoError.value = t.serialAlreadyExists;
                            c.autoValidateFields.value = true;
                          }
                        }
                      },
                    ),
                  ),
                ),

                Row(children: [Text(t.enterBrandNumber)]),
                _tf(label: t.enterBrandNumber, controller: c.brandNo),

                Row(
                  children: [
                    Text(t.registerDate),
                    const Text("*", style: TextStyle(color: Colors.red)),
                  ],
                ),
                _tf(
                  label: t.registerDate,
                  controller: c.registeredDate,
                  onTap: () => pickDate(context),
                  validator: (v) {
                    if (v == null || v.isEmpty) return t.registerDateRequired;
                    return null;
                  },
                ),

                Row(children: [Text(t.evaluationNumber)]),
                _tf(label: t.enterEvaluationNumber, controller: c.evaluationNo),

                Row(children: [Text(t.lotNumber)]),
                _tf(label: t.enterLotNumber, controller: c.lotNo),

                Row(children: [Text(t.purchaseOrderNumber)]),
                _tf(label: t.enterPurchaseOrderNumber, controller: c.poNo),

                Row(
                  children: [
                    Text(t.disposition),
                    const Text("*", style: TextStyle(color: Colors.red)),
                  ],
                ),
                _tf(
                  label: t.enterDisposition,
                  value: c.dispositionText.value,
                  enabled: false,
                ),

                Row(children: [Text(t.status)]),
                _dropdownTFStatus(
                  label: t.status,
                  value: c.selectedstatus.value,
                  items: c.statusList,
                ),

                Row(children: [Text(t.trackingMethod)]),
                Obx(() {
                  return _dropdownTFTracking(
                    label: t.trackingMethod,
                    currentValue: c.trackingMethodText.value,
                    items: [
                      t.trackingMethodHours,
                      t.trackingMethodDistance,
                      t.trackingMethodBoth,
                    ],
                  );
                }),

                Obx(() {
                  final method = c.trackingMethodText.value;
                  if (method == t.trackingMethodDistance) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(t.currentHours),
                          const Text("*", style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: TextFormField(
                          controller: c.currentHours,
                          focusNode: _hoursFocusNode,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (v) {
                            if (c.trackingMethodText.value ==
                                t.trackingMethodDistance) {
                              return null;
                            }
                            if (v == null || v.trim().isEmpty) {
                              return t.currentHoursRequired;
                            }
                            final parsed = double.tryParse(v);
                            if (parsed == null) return t.enterValidNumeric;
                            if (parsed < 0) return t.hoursNotNegative;
                            return null;
                          },
                          decoration: _inputDecoration(
                            hintText: t.enterCurrentHours,
                            suffixIcon:
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: c.currentHours,
                              builder: (context, value, _) {
                                if (value.text.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    c.currentHours.clear();
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(_hoursFocusNode);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),

                Obx(() {
                  final method = c.trackingMethodText.value;
                  if (method == t.trackingMethodHours) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "${t.currentKm.replaceAll('{unit}', c.distLabel)} ",
                          ),
                          const Text("*", style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: TextFormField(
                          controller: c.currentKm,
                          focusNode: _kmFocusNode,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (v) {
                            if (c.trackingMethodText.value ==
                                t.trackingMethodHours) {
                              return null;
                            }
                            if (v == null || v.trim().isEmpty) {
                              return t.currentKmRequired.replaceAll(
                                '{unit}',
                                c.distLabel,
                              );
                            }
                            final parsed = double.tryParse(v);
                            if (parsed == null) return t.enterValidNumeric;
                            if (parsed < 0) return t.kmNotNegative;
                            return null;
                          },
                          decoration: _inputDecoration(
                            hintText: "Enter Current ${c.distLabel}",
                            suffixIcon:
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: c.currentKm,
                              builder: (context, value, _) {
                                if (value.text.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    c.currentKm.clear();
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(_kmFocusNode);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 24),
                _primaryBtn(t.nextBtn, () => c.nextStep()),
                const SizedBox(height: 12),
                _outlineBtn(t.cancelBtn, c.cancelDialog),
                const SizedBox(height: 40),
              ],
            ),
          ),

          if (c.isPageLoading.value)
            Positioned.fill(
              child: Container(
                color: Colors.white.withAlpha(128),
                child: const AppLoadingIndicator(),
              ),
            ),
        ],
      );
    });
  }

  Widget _tf({
    required String label,
    TextEditingController? controller,
    String? value,
    bool enabled = true,
    String? Function(String?)? validator,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? value : null,
        enabled: enabled,
        readOnly: onTap != null,
        onTap: onTap != null
            ? () {
          FocusManager.instance.primaryFocus?.unfocus();
          onTap();
        }
            : null,
        validator: validator,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: label,
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 1.5),
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          disabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          errorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
      ),
    );
  }

  Future<String?> _showSelectionDialog({
    required String label,
    required List<String> items,
    required RxString selectedValue,
  }) async {
    String tempSelected = selectedValue.value;
    return await Get.dialog<String>(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: EdgeInsets.zero,
            titlePadding: const EdgeInsets.symmetric(vertical: 20),
            title: Text(
              label,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 1, thickness: 1),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = item == tempSelected;
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isSelected
                                        ? Colors.red
                                        : Colors.black87,
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
                      onPressed: () => Get.back(),
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
                  Container(width: 1, height: 50, color: Colors.grey.shade300),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        selectedValue.value = tempSelected;
                        Get.back(result: tempSelected);
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
      ),
      barrierDismissible: false,
    );
  }

  Widget _dropdownTFTracking({
    required String label,
    required String currentValue,
    required List<String> items,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () async {
          FocusManager.instance.primaryFocus?.unfocus();

          final res = await _showTrackingDialog(
            label: label,
            items: items,
            currentValue: currentValue,
          );
          if (res != null) {
            c.trackingMethodText.value = res;
            c.selectedTrackingMethod.value = res;
          }
        },
        child: AbsorbPointer(
          child: TextFormField(
            key: ValueKey(currentValue),
            initialValue: currentValue,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: label,
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 1.5),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _showTrackingDialog({
    required String label,
    required List<String> items,
    required String currentValue,
  }) async {
    String tempSelected = currentValue;
    return await Get.dialog<String>(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: EdgeInsets.zero,
            titlePadding: const EdgeInsets.symmetric(vertical: 20),
            title: Text(
              label,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 1, thickness: 1),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = item == tempSelected;
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isSelected
                                        ? Colors.red
                                        : Colors.black87,
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
                      onPressed: () => Get.back(),
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
                  Container(width: 1, height: 50, color: Colors.grey.shade300),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(result: tempSelected),
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
      ),
      barrierDismissible: false,
    );
  }

  Widget _dropdownTFStatus({
    required String label,
    dynamic value,
    required List<String> items,
  }) {
    return Obx(() {
      final displayValue = c.selectedstatus.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: GestureDetector(
          onTap: () async {
            FocusManager.instance.primaryFocus?.unfocus();

            await _showSelectionDialog(
              selectedValue: c.selectedstatus,
              label: label,
              items: items,
            );
            final idx = c.statusList.indexOf(c.selectedstatus.value);
            if (idx != -1 && idx < c.statusIdList.length) {
              c.selectedStatusId.value = c.statusIdList[idx];
            }
          },
          child: AbsorbPointer(
            child: TextFormField(
              key: ValueKey(displayValue),
              initialValue: displayValue,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: label,
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 1.5),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                suffixIcon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _primaryBtn(String text, VoidCallback onTap) => SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );

  Widget _outlineBtn(String text, VoidCallback onTap) => SizedBox(
    width: double.infinity,
    height: 48,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: Colors.grey),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ),
    ),
  );

  Future<void> pickDate(BuildContext context) async {
    DateTime initialDate =
        LocaleHelper.parseDisplayDate(c.registeredDate.text) ?? DateTime.now();
    final result = await showCustomDarkDatePicker(context, initialDate);
    if (result != null) {
      if (result.year == 1900) {
        c.registeredDate.clear();
        c.registeredDateApi = null;
      } else {
        c.registeredDate.text = LocaleHelper.formatDate(result);
        c.registeredDateApi =
        "${result.year}-${result.month.toString().padLeft(2, '0')}"
            "-${result.day.toString().padLeft(2, '0')}T00:00:00";
      }
    }
  }

  Future<DateTime?> showCustomDarkDatePicker(
      BuildContext context,
      DateTime initialDate,
      ) async {
    DateTime selectedDate = initialDate;
    return await showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFB71C1C),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${selectedDate.year}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      LocaleHelper.formatPickerHeader(selectedDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    surface: Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                    primary: Color(0xFFD32F2F),
                    onPrimary: Colors.white,
                  ),
                  datePickerTheme: DatePickerThemeData(
                    todayBorder: BorderSide.none,
                    todayBackgroundColor: WidgetStateProperty.resolveWith((
                        states,
                        ) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFFD32F2F);
                      }
                      return Colors.transparent;
                    }),
                    todayForegroundColor: WidgetStateProperty.resolveWith((
                        states,
                        ) {
                      return Colors.white;
                    }),
                  ),
                  dividerColor: Colors.transparent,
                ),
                child: SizedBox(
                  height: 320,
                  child: CalendarDatePicker(
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    onDateChanged: (d) => setState(() => selectedDate = d),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, DateTime(1900)),
                      child: const Text(
                        "CLEAR",
                        style: TextStyle(
                          color: Color(0xFFEF5350),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "CANCEL",
                        style: TextStyle(
                          color: Color(0xFFEF5350),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, selectedDate),
                      child: const Text(
                        "SET",
                        style: TextStyle(
                          color: Color(0xFFEF5350),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDayName(int day) =>
      ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][day - 1];

  String _getMonthName(int month) => [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ][month - 1];
}
