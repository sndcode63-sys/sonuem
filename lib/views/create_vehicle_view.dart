import 'package:emtrack/color/app_color.dart';
import 'package:emtrack/controllers/all_vehicles_controller.dart';
import 'package:emtrack/controllers/create_vehicle_controller.dart';
import 'package:emtrack/controllers/selected_account_controller.dart';
import 'package:emtrack/routes/app_pages.dart';
import 'package:emtrack/utils/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:emtrack/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../utils/local_helper.dart';

const _cvShaftColor  = Color(0xFF4A4A5A);
const _cvShaftW      = 8.0;
const _cvCircleD     = 38.0;
const _cvSegH        = 48.0;
const _cvAxleLineH   = _cvShaftW;

// Single tyre preview box
const _cvTyreW  = 64.0;
const _cvTyreH  = 130.0;
const _cvTyreR  = 12.0;

// Dual tyre preview box
const _cvDualW  = 48.0;
const _cvDualH  = 100.0;
const _cvDualR  = 9.0;


class CreateVehicleView extends StatefulWidget {
  const CreateVehicleView({super.key});

  @override
  State<CreateVehicleView> createState() => _CreateVehicleViewState();
}

class _CreateVehicleViewState extends State<CreateVehicleView> {
  final vc = Get.put(VehicleController());

  final allVehicleController = Get.isRegistered<AllVehicleController>()
      ? Get.find<AllVehicleController>()
      : Get.put(AllVehicleController());
  final selectedCtrl = Get.put(SelectedAccountController());

  final FocusNode _hoursFocusNode = FocusNode();
  final FocusNode _kmFocusNode    = FocusNode();

  @override
  void dispose() {
    _hoursFocusNode.dispose();
    _kmFocusNode.dispose();
    super.dispose();
  }

  InputDecoration _redDecoration({
    required String hint,
    String? errorText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
      errorText: errorText?.isNotEmpty == true ? errorText : null,
      errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red, width: 2)),
      errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
      focusedErrorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red, width: 2)),
      disabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: Colors.red,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        textSelectionTheme: const TextSelectionThemeData(cursorColor: Colors.red),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.createVehicle,
              style: TextStyle(color: AppColors.textWhite, fontSize: 18)),
          centerTitle: true,
          backgroundColor: AppColors.primary,
          iconTheme: IconThemeData(color: AppColors.textWhite),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textWhite),
            onPressed: () {
              if (Get.key.currentState?.canPop() == true) {
                Get.back();
              } else {
                Get.offAllNamed(AppPages.HOME);
              }
            },
          ),
        ),
        body: SafeArea(child: _buildForm(context)),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(l10n.selectedParentAccountLocation),
          Obx(() => Text(
            "${selectedCtrl.parentAccountName.value} - ${selectedCtrl.locationName.value}",
            style: TextStyle(
              color: AppColors.buttonDanger,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          )),

          const SizedBox(height: 12),

          _label(l10n.vehicleId),
          Obx(() => TextField(
            cursorColor: Colors.red,
            decoration: _redDecoration(
              hint: '${l10n.enterPrefix}${l10n.vehicleId}',
              errorText: vc.vehicleNumberError.value,
            ),
            onChanged: (v) {
              vc.vehicleNumber.value = v;
              vc.clearVehicleNumberError();
            },
          )),

          const SizedBox(height: 12),

          _label(l10n.trackingMethod),
          Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: vc.trackingMethodError.value.isNotEmpty
                        ? Colors.red
                        : Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListTile(
                  title: Text(_getTrackingMethodLabel(l10n, vc.trackingMethodText.value)),
                  trailing: const Icon(Icons.arrow_drop_down, color: Colors.red),
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    _showTrackingMethodDialog(context, vc);
                  },
                ),
              ),
              if (vc.trackingMethodError.value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(vc.trackingMethodError.value,
                      style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
            ],
          )),

          const SizedBox(height: 12),

          Obx(() {
            final methodId = vc.trackingMethodValue;
            if (methodId != 1 && methodId != 3) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(l10n.currentHours),
                TextField(
                  controller: vc.currentHoursCtrl,
                  cursorColor: Colors.red,
                  keyboardType: TextInputType.number,
                  focusNode: _hoursFocusNode,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d?')),
                  ],
                  decoration: _redDecoration(
                    hint: l10n.currentHours,
                    errorText: vc.currentHoursError.value,
                    suffixIcon: vc.currentHours.value.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () {
                        vc.currentHoursCtrl.clear();
                        vc.currentHours.value = '';
                        vc.currentHoursError.value = l10n.requiredField;
                        _hoursFocusNode.requestFocus();
                      },
                    )
                        : null,
                  ),
                  onChanged: (v) {
                    vc.currentHours.value = v;
                    vc.currentHoursError.value =
                    v.trim().isEmpty ? l10n.requiredField : '';
                  },
                ),
                const SizedBox(height: 12),
              ],
            );
          }),

          Obx(() {
            final methodId = vc.trackingMethodValue;
            if (methodId != 2 && methodId != 3) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => _label("${l10n.currentDistance} ${vc.kmMilesLabel.value}")),
                TextField(
                  controller: vc.currentKmCtrl,
                  cursorColor: Colors.red,
                  keyboardType: TextInputType.number,
                  focusNode: _kmFocusNode,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d?')),
                  ],
                  decoration: _redDecoration(
                    hint: '${l10n.enterCurrentDistance} ${vc.kmMilesLabel.value}',
                    errorText: vc.currentKmError.value,
                    suffixIcon: vc.currentKm.value.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () {
                        vc.currentKmCtrl.clear();
                        vc.currentKm.value = '';
                        vc.currentKmError.value = l10n.requiredField;
                        _kmFocusNode.requestFocus();
                      },
                    )
                        : null,
                  ),
                  onChanged: (v) {
                    vc.currentKm.value = v;
                    vc.currentKmError.value =
                    v.trim().isEmpty ? l10n.requiredField : '';
                  },
                ),
                const SizedBox(height: 12),
              ],
            );
          }),

          _label(l10n.manufacturer),
          Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _searchableField(
                context: context,
                hint: '${l10n.selectPrefix}${l10n.manufacturer}',
                controller: vc.manufacturerCtrl,
                enabled: true,
                hasError: vc.manufacturerError.value.isNotEmpty,
                onTap: () => _openFullScreenDialog(
                  context: context,
                  title: '${l10n.selectPrefix}${l10n.manufacturer}',
                  selectedValue: vc.selectedManufecturer,
                  items: vc.manufacturerList,
                  onSelect: (item) {
                    vc.selectManufacturer(item);
                    vc.clearManufacturerError();
                  },
                ),
              ),
              if (vc.manufacturerError.value.isNotEmpty)
                _errorText(vc.manufacturerError.value),
            ],
          )),

          const SizedBox(height: 12),

          Text("${l10n.vehicleType} *"),
          Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _searchableField(
                context: context,
                hint: '${l10n.selectPrefix}${l10n.vehicleType}',
                controller: vc.typeCtrl,
                enabled: vc.manufacturerId.value != 0,
                hasError: vc.typeError.value.isNotEmpty,
                onTap: vc.manufacturerId.value != 0
                    ? () => _openFullScreenDialog(
                  context: context,
                  title: '${l10n.selectPrefix}${l10n.vehicleType}',
                  selectedValue: vc.selectedType,
                  items: vc.typeList,
                  onSelect: (item) {
                    vc.selectType(item);
                    vc.clearTypeError();
                  },
                )
                    : null,
              ),
              if (vc.typeError.value.isNotEmpty) _errorText(vc.typeError.value),
            ],
          )),

          const SizedBox(height: 12),

          _label(l10n.model),
          Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _searchableField(
                context: context,
                hint: '${l10n.selectPrefix}${l10n.model}',
                controller: vc.modelCtrl,
                enabled: vc.typeId.value != 0,
                hasError: vc.modelError.value.isNotEmpty,
                onTap: vc.typeId.value != 0
                    ? () => _openFullScreenDialog(
                  context: context,
                  title: '${l10n.selectPrefix}${l10n.model}',
                  selectedValue: vc.selectedModel,
                  items: vc.modelList,
                  onSelect: (item) {
                    vc.selectModel(item);
                    vc.clearModelError();
                  },
                )
                    : null,
              ),
              if (vc.modelError.value.isNotEmpty) _errorText(vc.modelError.value),
            ],
          )),

          const SizedBox(height: 12),

          _label(l10n.tyreSize),
          Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _searchableField(
                context: context,
                hint: '${l10n.selectPrefix}${l10n.tyreSize}',
                controller: vc.tyreSizeCtrl,
                enabled: true,
                hasError: vc.tyreSizeError.value.isNotEmpty,
                onTap: () => _openFullScreenDialog(
                  context: context,
                  title: '${l10n.selectPrefix}${l10n.tyreSize}',
                  selectedValue: vc.selectedTyreSize,
                  items: vc.tyreSizeList,
                  onSelect: (item) {
                    vc.selectTyreSize(item);
                    vc.clearTyreSizeError();
                  },
                ),
              ),
              if (vc.tyreSizeError.value.isNotEmpty)
                _errorText(vc.tyreSizeError.value),
            ],
          )),

          const SizedBox(height: 12),

          // ── Removal Tread ───────────────────────────────────────────────
          _label(l10n.removalTread),
          Obx(() => TextField(
            cursorColor: Colors.red,
            decoration: _redDecoration(
              hint: l10n.removalTread,
              errorText: vc.removalTreadError.value,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d?')),
            ],
            onChanged: (v) {
              vc.removalTread.value = v;
              vc.clearRemovalTreadError();
            },
          )),

          const SizedBox(height: 12),

          Text(l10n.vehicleComments),
          TextField(
            cursorColor: Colors.red,
            decoration: _redDecoration(hint: l10n.commentsHint),
            maxLines: null,
            onChanged: (v) => vc.comments.value = v,
          ),

          Obx(() {
            if (!vc.showPressureSection) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(l10n.vehicleDiagram,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                const AxleTyreLayout(),

                const SizedBox(height: 8),
                Obx(() => Column(
                  children: List.generate(
                    vc.axlePressures.length,
                        (i) => _pressureRowDynamic(
                      context,
                      "${l10n.axleLabel} ${i + 1}",
                      i,
                      vc,
                    ),
                  ),
                )),
              ],
            );
          }),

          const SizedBox(height: 24),

          Obx(() => InkWell(
            onTap: vc.isSubmitting.value ? null : () => vc.submitForm(l10n),
            child: Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: vc.isSubmitting.value ? Colors.red : AppColors.buttonDanger,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Center(
                child: vc.isSubmitting.value
                    ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : Text(l10n.submit,
                    style: TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          )),

          Center(
            child: TextButton(
              onPressed: () {
                AppDialog.showConfirmDialog(
                  title: l10n.cancelRequestTitle,
                  message: l10n.cancelRequestMessage,
                  okText: l10n.cancelRequestYes,
                  onOk: () {
                    Get.back(closeOverlays: true);
                    Future.delayed(
                        const Duration(milliseconds: 200), () => Get.back());
                  },
                );
              },
              child: Text(l10n.cancel,
                  style: TextStyle(color: AppColors.buttonDanger)),
            ),
          ),
        ],
      ),
    );
  }


  String _getTrackingMethodLabel(AppLocalizations t, String v) {
    if (v == 'Hours') return t.trackingMethodHours;
    if (v == 'Distance') return t.trackingMethodDistance;
    if (v == 'Both') return t.trackingMethodBoth;
    return v;
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 4),
    child: Row(children: [
      Text(text),
      const Text(' *', style: TextStyle(color: Colors.red)),
    ]),
  );

  Widget _errorText(String msg) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(msg, style: const TextStyle(color: Colors.red, fontSize: 12)),
  );

  Widget _searchableField({
    required BuildContext context,
    required String hint,
    required TextEditingController controller,
    required bool enabled,
    required bool hasError,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: enabled
          ? () {
        FocusManager.instance.primaryFocus?.unfocus();
        if (onTap != null) onTap();
      }
          : null,
      child: AbsorbPointer(
        child: TextFormField(
          readOnly: true,
          enabled: enabled,
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: hasError ? Colors.red : Colors.grey),
            ),
            focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2)),
            errorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red)),
            disabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey)),
            border: const OutlineInputBorder(),
            suffixIcon: enabled
                ? const Icon(Icons.arrow_drop_down, color: Colors.red)
                : const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _pressureRowDynamic(
      BuildContext context, String axleLabel, int index, vc) {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = vc.getPressureController(index);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(l10n.recommendedPressureFor(axleLabel),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
        const SizedBox(height: 8),
        Container(
          height: 55,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
          child: Row(children: [
            Expanded(
              flex: 1,
              child: InkWell(
                onTap: () => vc.decrementPressure(index),
                child: Container(
                  color: AppColors.buttonDanger,
                  alignment: Alignment.center,
                  child: const Icon(Icons.remove, color: Colors.white, size: 30),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IntrinsicWidth(
                    child: TextField(
                      controller: ctrl,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      cursorColor: Colors.red,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        hintText: '0',
                      ),
                      onChanged: (v) => vc.setPressure(index, double.tryParse(v) ?? 0.0),
                    ),
                  ),
                  Text(' ${vc.pressureUnit.value}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              )),
            ),
            Expanded(
              flex: 1,
              child: InkWell(
                onTap: () => vc.incrementPressure(index),
                child: Container(
                  color: AppColors.buttonDanger,
                  alignment: Alignment.center,
                  child: const Icon(Icons.add, color: Colors.white, size: 30),
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  void _showTrackingMethodDialog(BuildContext context, VehicleController vc) {
    final l10n = AppLocalizations.of(context)!;
    final options = [
      (l10n.trackingMethodHours, 'Hours'),
      (l10n.trackingMethodDistance, 'Distance'),
      (l10n.trackingMethodBoth, 'Both'),
    ];

    // Temporary selection — sirf OK dabane par vc mein commit hoga
    final RxString tempSelected = vc.trackingMethodText.value.obs;

    Get.defaultDialog(
      title: l10n.trackingMethodTitle,
      titleStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      titlePadding: const EdgeInsets.only(top: 16, bottom: 8),
      contentPadding: EdgeInsets.zero,
      radius: 12,
      backgroundColor: Colors.white,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          for (final opt in options)
            Obx(() => _iosOptionTile(
              text: opt.$1,
              selected: tempSelected.value == opt.$2,
              onTap: () => tempSelected.value = opt.$2,   // sirf temp update
            )),
          const Divider(height: 1),
          SizedBox(
            height: 40,
            child: Row(children: [
              Expanded(
                child: InkWell(
                  onTap: () => Get.back(),   // Cancel -> kuch bhi commit nahi hota
                  child: Center(
                    child: Text(l10n.cancel,
                        style: const TextStyle(color: Colors.red, fontSize: 16)),
                  ),
                ),
              ),
              Container(width: 1, color: Colors.grey.shade300),
              Expanded(
                child: InkWell(
                  onTap: () {
                    vc.trackingMethodText.value = tempSelected.value;
                    vc.clearTrackingMethodError();
                    Get.back();
                  },
                  child: Center(
                    child: Text(l10n.okBtn,
                        style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
  Widget _iosOptionTile({
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Text(text,
              style: TextStyle(
                  fontSize: 16, color: selected ? Colors.red : Colors.black)),
          const Spacer(),
          if (selected) const Icon(Icons.check, color: Colors.red, size: 20),
        ]),
      ),
    );
  }

  void _openFullScreenDialog({
    required BuildContext context,
    required String title,
    required RxString selectedValue,
    required RxList<String> items,
    required Function(String) onSelect,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final RxList<String> filteredList = <String>[].obs;
    final TextEditingController searchCtrl = TextEditingController();
    final RxString tempSelected = selectedValue.value.obs;
    filteredList.assignAll(items);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Scaffold(
        appBar: AppBar(
          title: Text(title, style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary,
          automaticallyImplyLeading: false,
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchCtrl,
              cursorColor: Colors.red,
              decoration: InputDecoration(
                hintText: '${l10n.searchHint}...',
                prefixIcon: const Icon(Icons.search, color: Colors.red),
                enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2)),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) {
                filteredList.value = items
                    .where((e) => e.toLowerCase().contains(v.toLowerCase()))
                    .toList();
              },
            ),
          ),
          Expanded(
            child: Obx(() {
              if (filteredList.isEmpty) {
                return Center(child: Text(l10n.noDataAvailable));
              }
              return ListView.builder(
                itemCount: filteredList.length,
                itemBuilder: (_, index) {
                  final item = filteredList[index];
                  return Obx(() {
                    final isSelected = tempSelected.value == item;
                    return ListTile(
                      tileColor: isSelected
                          ? Colors.red.withValues(alpha: 0.08)
                          : Colors.transparent,
                      title: Text(item,
                          style: TextStyle(
                              color: isSelected ? Colors.red : Colors.black,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Colors.red)
                          : null,
                      onTap: () => tempSelected.value = item,
                    );
                  });
                },
              );
            }),
          ),
          Container(
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300))),
            child: Row(children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text(l10n.cancel,
                      style:
                      const TextStyle(color: Colors.red, fontSize: 16)),
                ),
              ),
              Container(width: 1, height: 50, color: Colors.grey.shade300),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    if (tempSelected.value.isNotEmpty) {
                      selectedValue.value = tempSelected.value;
                      onSelect(tempSelected.value);
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text(l10n.okBtn,
                      style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}


class AxleTyreLayout extends StatelessWidget {
  const AxleTyreLayout({super.key});

  static List<int> _parseDigits(String config) {
    final digits = config.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return [2, 2];
    return digits.split('').map((c) => int.tryParse(c) ?? 2).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vc = Get.find<VehicleController>();

    return Obx(() {
      final digits    = _parseDigits(vc.axleConfigValue);
      final axleCount = digits.length;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // L / R header
          const _CvLRHeader(),
          const SizedBox(height: 8),

          // Axle rows + shaft segments
          for (int i = 0; i < axleCount; i++) ...[
            _CvAxleRow(axleNo: i + 1, tireCount: digits[i]),
            if (i < axleCount - 1) const _CvShaftSegment(),
          ],
        ],
      );
    });
  }
}


class _CvLRHeader extends StatelessWidget {
  const _CvLRHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 15, fontWeight: FontWeight.w700,
      color: Color(0xFF3B82F6), letterSpacing: 1,
    );
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text('L', style: style), Text('R', style: style)],
      ),
    );
  }
}


class _CvShaftSegment extends StatelessWidget {
  const _CvShaftSegment();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: _cvShaftW, height: _cvSegH,
      decoration: BoxDecoration(
        color: _cvShaftColor,
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}


class _CvAxleRow extends StatelessWidget {
  final int axleNo;
  final int tireCount;   // 2 = single, 4 = dual
  const _CvAxleRow({required this.axleNo, required this.tireCount});

  @override
  Widget build(BuildContext context) {
    final isDual = tireCount == 4;

    Widget left  = isDual
        ? Row(mainAxisSize: MainAxisSize.min, children: [
      _CvTyreBox(label: 'O', dual: true),
      const SizedBox(width: 3),
      _CvTyreBox(label: 'I', dual: true),
    ])
        : _CvTyreBox(label: null, dual: false);

    Widget right = isDual
        ? Row(mainAxisSize: MainAxisSize.min, children: [
      _CvTyreBox(label: 'I', dual: true),
      const SizedBox(width: 3),
      _CvTyreBox(label: 'O', dual: true),
    ])
        : _CvTyreBox(label: null, dual: false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          left,
          const SizedBox(width: 6),
          // left axle bar
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 90),
              height: _cvAxleLineH,
              decoration: BoxDecoration(
                color: _cvShaftColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // axle circle
          Container(
            width: _cvCircleD, height: _cvCircleD,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _cvShaftColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(51),
                  blurRadius: 5, offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '$axleNo',
              style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // right axle bar
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 90),
              height: _cvAxleLineH,
              decoration: BoxDecoration(
                color: _cvShaftColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 6),
          right,
        ],
      ),
    );
  }
}


class _CvTyreBox extends StatelessWidget {
  final String? label;
  final bool dual;
  const _CvTyreBox({this.label, required this.dual});

  @override
  Widget build(BuildContext context) {
    final w = dual ? _cvDualW : _cvTyreW;
    final h = dual ? _cvDualH : _cvTyreH;
    final r = dual ? _cvDualR : _cvTyreR;

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(
          color: Colors.grey.shade400,
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.do_not_disturb_alt_outlined,
            size: dual ? 18 : 22,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 4),
          Text(
            'No ${LocaleHelper.tyreName(context)}\nInstalled',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: dual ? 8 : 9,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade400,
              height: 1.3,
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 2),
            Text(
              label!,
              style: TextStyle(
                fontSize: dual ? 8 : 9,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}