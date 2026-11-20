import 'package:emtrack/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../l10n/app_localizations.dart';
import '../utils/local_helper.dart';
import 'edit_tyre_controller.dart';

class Step1View extends StatefulWidget {
  const Step1View({super.key});

  @override
  State<Step1View> createState() => _Step1ViewState();
}

class _Step1ViewState extends State<Step1View> {
  late final EditTyreController c;
  final FocusNode _hoursFocusNode = FocusNode();
  final FocusNode _kmFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    c = Get.find<EditTyreController>();
  }

  @override
  void dispose() {
    _hoursFocusNode.dispose();
    _kmFocusNode.dispose();
    super.dispose();
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

  String _getTrackingLabel(AppLocalizations t, String val) {
    if (val == "Hours") return t.trackingMethodHours;
    if (val == "Distance") return t.trackingMethodDistance;
    if (val == "Both") return t.trackingMethodBoth;
    return val;
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
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Text(
                      "${LocaleHelper.tyreName(context)} ${t.serialNumber} ",
                    ),
                    const Text("*", style: TextStyle(color: Colors.red)),
                  ],
                ),
                _tf(
                  hint:
                  "${t.enter} ${LocaleHelper.tyreName(context)} ${t.serialNumber}",
                  controller: c.tireSerialNo,
                ),

                Row(children: [Text("${t.enter} ${t.brandNumber} ")]),
                _tf(hint: "${t.enter} ${t.brandNumber}", controller: c.brandNo),

                Row(
                  children: [
                    Text("${t.registerDate} "),
                    const Text("*", style: TextStyle(color: Colors.red)),
                  ],
                ),
                _tf(
                  hint: t.registerDate,
                  controller: c.registeredDate,
                  onTap: () => pickDate(context),
                ),

                Row(children: [Text("${t.enter} ${t.evaluationNumber} ")]),
                _tf(
                  hint: "${t.enter} ${t.evaluationNumber}",
                  controller: c.evaluationNo,
                ),

                Row(children: [Text("${t.enter} ${t.lotNumber} ")]),
                _tf(hint: "${t.enter} ${t.lotNumber}", controller: c.lotNo),

                Row(children: [Text("${t.enter} ${t.purchaseOrderNumber}")]),
                _tf(
                  hint: "${t.enter} ${t.purchaseOrderNumber}",
                  controller: c.poNo,
                ),

                Row(
                  children: [
                    Text("${t.disposition} "),
                    const Text("*", style: TextStyle(color: Colors.red)),
                  ],
                ),
                _tf(
                  hint: "${t.enter} ${t.disposition}",
                  value: c.dispositionText.value,
                  enabled: false,
                ),

                Row(
                  children: [
                    Text(
                      "${t.status} ",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                _dropdownTFStatus(
                  label: "${LocaleHelper.tyreName(context)} ${t.status}",
                  controller: c.tireStatusId,
                  items: c.statusList,
                  ids: c.statusIdList.toList(),
                  t: t,
                ),

                Row(children: [Text("${t.trackingMethod} ")]),
                Obx(() {
                  return _dropdownTFTracking(
                    label: t.trackingMethod,
                    currentValue: _getTrackingLabel(
                      t,
                      c.trackingMethodText.value,
                    ),
                    items: [
                      t.trackingMethodHours,
                      t.trackingMethodDistance,
                      t.trackingMethodBoth,
                    ],
                    t: t,
                  );
                }),

                // ✅ Current Hours
                Obx(() {
                  final method = c.trackingMethodText.value;
                  if (method == "Distance") return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text("${t.currentHours} "),
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
                              RegExp(r'^-?\d*\.?\d{0,1}'),
                            ),
                          ],
                          validator: (value) {
                            if (c.trackingMethodText.value == "Distance") {
                              return null;
                            }
                            if (value == null || value.isEmpty) {
                              return t.enterValidDetails;
                            }
                            if (!RegExp(r'^-?\d+(\.\d{1,2})?$').hasMatch(value)) {
                              return t.enterValidNumber;
                            }
                            return null;
                          },
                          decoration: _dec(
                            hint: "${t.enter} ${t.currentHours}",
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
                                    c.formKey.currentState?.validate();
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
                  if (method == "Hours") return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text("${t.currentDistance} ${c.distLabel} "),
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
                              RegExp(r'^-?\d*\.?\d{0,1}'),
                            ),
                          ],
                          validator: (value) {
                            if (c.trackingMethodText.value == "Hours") {
                              return null;
                            }
                            if (value == null || value.isEmpty) {
                              return t.enterValidDetails;
                            }
                            if (!RegExp(r'^-?\d+(\.\d{1,2})?$').hasMatch(value)) {
                              return t.enterValidNumber;
                            }
                            return null;
                          },
                          decoration: _dec(
                            hint: "${t.enter} ${t.currentDistance}",
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
                                    c.formKey.currentState?.validate();
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
    required String hint,
    TextEditingController? controller,
    dynamic value,
    bool enabled = true,
    String? Function(String?)? validator,
    VoidCallback? onTap,
  }) {
    final TextEditingController ec =
        controller ?? TextEditingController(text: value?.toString() ?? "");
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ec,
        enabled: enabled,
        readOnly: onTap != null,
        onTap: onTap,
        validator: validator,
        decoration: _dec(hint: hint, enabled: enabled),
      ),
    );
  }

  Widget _dropdownTFTracking({
    required String label,
    required String currentValue,
    required List<String> items,
    required AppLocalizations t,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () async {
          final res = await _showTrackingDialog(
            label: label,
            items: items,
            currentValue: currentValue,
            t: t,
          );
          if (res != null) {
            if (res == t.trackingMethodHours)
              c.trackingMethodText.value = "Hours";
            else if (res == t.trackingMethodDistance)
              c.trackingMethodText.value = "Distance";
            else if (res == t.trackingMethodBoth)
              c.trackingMethodText.value = "Both";

            c.selectedTrackingMethod.value = c.trackingMethodText.value;
          }
        },
        child: AbsorbPointer(
          child: TextFormField(
            key: ValueKey(currentValue),
            initialValue: currentValue,
            decoration: _dec(
              hint: label,
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
    required AppLocalizations t,
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
                children: [
                  const Divider(height: 1, thickness: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = item == tempSelected;
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
                  Container(width: 1, height: 50, color: Colors.grey.shade300),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(result: tempSelected),
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
          );
        },
      ),
      barrierDismissible: false,
    );
  }

  Widget _dropdownTFStatus({
    required String label,
    required AppLocalizations t,
    TextEditingController? controller,
    required List<String> items,
    required List<int> ids,
  }) {
    final TextEditingController ec = controller ?? TextEditingController();
    if (c.selectedstatus.value != 0 && ec.text.isEmpty) {
      final index = ids.indexOf(c.selectedstatus.value);
      if (index != -1) ec.text = items[index];
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () async {
          await _showStatusDialog(
            label: label,
            items: items,
            ids: ids,
            selectedId: c.selectedstatus,
            textController: ec,
            t: t,
          );
        },
        child: AbsorbPointer(
          child: TextFormField(
            controller: ec,
            decoration: _dec(
              hint: label,
              suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showStatusDialog({
    required String label,
    required List<String> items,
    required List<int> ids,
    required RxInt selectedId,
    required TextEditingController textController,
    required AppLocalizations t,
  }) async {
    int tempSelected = selectedId.value;
    await Get.dialog(
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
                children: [
                  const Divider(height: 1, thickness: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final isSelected = ids[index] == tempSelected;
                        return InkWell(
                          onTap: () =>
                              setDialogState(() => tempSelected = ids[index]),
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
                                  items[index],
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
                  Container(width: 1, height: 50, color: Colors.grey.shade300),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        selectedId.value = tempSelected;
                        final idx = ids.indexOf(tempSelected);
                        if (idx != -1) textController.text = items[idx];
                        Get.back();
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
          );
        },
      ),
      barrierDismissible: false,
    );
  }

  Future<void> pickDate(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    DateTime initialDate = DateTime.now();
    if (c.registeredDate.text.isNotEmpty) {
      initialDate =
          LocaleHelper.parseDisplayDate(c.registeredDate.text) ??
              DateTime.now();
    }

    final result = await showCustomDarkDatePicker(context, initialDate, t);
    if (result != null) {
      if (result.year == 1900) {
        c.registeredDate.clear();
        c.registeredDateApi = null;
      } else {
        c.registeredDate.text = LocaleHelper.formatDate(result);
        c.registeredDateApi =
        "${result.year}-${result.month.toString().padLeft(2, '0')}-${result.day.toString().padLeft(2, '0')}T00:00:00";
      }
    }
  }

  Future<DateTime?> showCustomDarkDatePicker(
      BuildContext context,
      DateTime initialDate,
      AppLocalizations t,
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
              // Header Section
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

              // Calendar Section
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

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, DateTime(1900)),
                      child: Text(
                        t.clear,
                        style: const TextStyle(
                          color: Color(0xFFEF5350),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        t.cancel.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFEF5350),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, selectedDate),
                      child: Text(
                        t.set,
                        style: const TextStyle(
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

  Widget _primaryBtn(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _outlineBtn(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: const BorderSide(color: Colors.grey),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
