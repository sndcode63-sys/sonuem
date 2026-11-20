import 'package:emtrack/controllers/install_tyre_controller.dart';
import 'package:emtrack/controllers/selected_account_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../utils/local_helper.dart';
import '../utils/reusable_dialog.dart';
import '../l10n/app_localizations.dart';

class InstallTyreView extends StatefulWidget {
  const InstallTyreView({super.key});

  @override
  State<InstallTyreView> createState() => _InstallTyreViewState();
}

class _InstallTyreViewState extends State<InstallTyreView> {
  late final InstallTyreController controller;
  late final SelectedAccountController selectedCtrl;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<InstallTyreController>()) {
      controller = Get.find<InstallTyreController>();
    } else {
      controller = Get.put(InstallTyreController());
    }
    selectedCtrl = Get.isRegistered<SelectedAccountController>()
        ? Get.find<SelectedAccountController>()
        : Get.put(SelectedAccountController());

    final rawArgs = Get.arguments;
    if (rawArgs is Map) {
      controller.resetAndInitWithArgs(rawArgs);
    }
  }

  String _clean(dynamic val) {
    if (val == null) return '';
    final d = double.tryParse(val.toString());
    if (d == null) return val.toString();
    if (d == d.truncateToDouble()) {
      return d.toInt().toString();
    } else {
      return d.toStringAsFixed(2).replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "");
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.black,
        title: Text(
          "${t.install} ${LocaleHelper.tyreName(context)}",
          style: const TextStyle(color: Colors.white),
        ),
        leading: const BackButton(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            final m = controller.model.value;
            final tyreData = controller.tyreList.isNotEmpty
                ? controller.tyreList.first
                : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── INFO CARD ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 253),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${t.selectedAccountLocation}:",
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${selectedCtrl.parentAccountName.value} - ${selectedCtrl.locationName.value}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Divider(),

                      Text("${t.vehicleId}:"),
                      Text(
                        "${controller.vehicleNumber}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Divider(),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.tyreSerialNumber,
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                tyreData?.tireSerialNo ?? m.tireSerialNo ?? '-',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "Brand No",
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                (tyreData?.brandNo != null && tyreData!.brandNo!.trim().isNotEmpty && tyreData.brandNo!.trim().toLowerCase() != 'null')
                                    ? tyreData.brandNo!
                                    : ((m.brandNo != null && m.brandNo!.trim().isNotEmpty) ? m.brandNo! : '-'),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(),

                      Text(
                        "${t.wheelPosition}:",
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        "${m.wheelPosition}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Divider(),

                      Text(
                        "${t.lastInspection}:",
                        style: const TextStyle(fontSize: 12),
                      ),
                      Obx(
                        () => Text(
                          controller.lastInspectionDateStr.value,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Divider(),

                      if (m.mileageType == 1 || m.mileageType == 3) ...[
                        Text(
                          t.currentHours,
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          _clean(m.currentHours),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Divider(),
                      ],


                      if (m.mileageType == 2 || m.mileageType == 3) ...[
                        Obx(
                          () => Text(
                            // VehicleView: t.currentKm.replaceAll('{unit}', kmMilesLabel)
                            t.currentKm.replaceAll(
                              '{unit}',
                              controller.kmMilesLabel.value,
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Obx(
                          () => Text(
                            controller.cleanMiles(m.currentMiles),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Divider(),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),


                Obx(
                  () => _counterWithTextField(
                    title: "${t.outside} ${t.treadDepth}",
                    unit: controller.measurementUnit.value == 'mm'
                        ? 'mm'
                        : '/32nds',
                    textCtrl: controller.outsideTreadController,
                    onChanged: controller.onOutsideTreadChanged,
                    onMinus: controller.decOutside,
                    onPlus: controller.incOutside,
                  ),
                ),
                const SizedBox(height: 16),

                if (controller.noOfTreadDepthReadings.value == 3) ...[
                  Obx(
                    () => _counterWithTextField(
                      title: "Middle ${t.treadDepth}",
                      unit: controller.measurementUnit.value == 'mm'
                          ? 'mm'
                          : '/32nds',
                      textCtrl: controller.middleTreadController,
                      onChanged: controller.onMiddleTreadChanged,
                      onMinus: controller.decMiddle,
                      onPlus: controller.incMiddle,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // INSIDE — count 2 ya 3 par
                if (controller.noOfTreadDepthReadings.value == 2 ||
                    controller.noOfTreadDepthReadings.value == 3) ...[
                  Obx(
                    () => _counterWithTextField(
                      title: "${t.inside} ${t.treadDepth}",
                      unit: controller.measurementUnit.value == 'mm'
                          ? 'mm'
                          : '/32nds',
                      textCtrl: controller.insideTreadController,
                      onChanged: controller.onInsideTreadChanged,
                      onMinus: controller.decInside,
                      onPlus: controller.incInside,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.averageTread),
                      const SizedBox(height: 6),
                      Container(
                        height: 48,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: const Color(0xffF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _clean(controller.model.value.currentTreadDepth),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              controller.measurementUnit.value == 'mm'
                                  ? 'mm'
                                  : '/32nds',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),


                Obx(
                  () => _counterWithTextField(
                    title:
                        "${t.airPressure} (${controller.pressureUnit.value}):",
                    unit: controller.pressureUnit.value,
                    textCtrl: controller.airPressureController,
                    onChanged: controller.onAirPressureChanged,
                    onMinus: controller.decAir,
                    onPlus: controller.incAir,
                  ),
                ),

                const SizedBox(height: 16),

                searchDropdownDialog(
                  hintText: t.wearCondition,
                  controller: controller.wearConditionsId,
                  nameList: controller.wearConditionsList,
                  idList: controller.wearConditionsIdList,
                  selectedId: controller.selectedWearConditionsId,
                  context: context,
                  t: t,
                ),

                searchDropdownDialog(
                  hintText: t.casingCondition,
                  controller: controller.casingConditionsId,
                  nameList: controller.casingConditionList,
                  idList: controller.casingConditionIdList,
                  selectedId: controller.selectedCasingConditionId,
                  context: context,
                  t: t,
                ),

                const SizedBox(height: 12),

                _textBox(
                  t.listOfPreviousComments,
                  controller.previousCommentController,
                  enabled: false,
                ),

                const SizedBox(height: 12),

                Obx(
                  () => Row(
                    children: [
                      Checkbox(
                        value: controller.stillRelevant.value,
                        activeColor: Colors.red,
                        onChanged: (_) => controller.previousCommentsOnChange(),
                      ),
                      Text(t.stillRelevant),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _textBox(
                  t.commentsLabel,
                  controller.commentsController,
                  onChanged: (v) =>
                      controller.model.update((m) => m!.comments = v),
                ),

                const SizedBox(height: 25),

                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 32,
                        height: 54,
                        child: Obx(
                          () => ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              disabledBackgroundColor: Colors.red.withAlpha(
                                153,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: controller.isSubmitting.value
                                ? null
                                : controller.submit,
                            child: controller.isSubmitting.value
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Text(
                                    t.install,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
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
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _counterWithTextField({
    required String title,
    required String unit,
    required TextEditingController textCtrl,
    required Function(String) onChanged,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 6),
        Row(
          children: [
            _redBtn("-", onMinus),
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        textAlign: TextAlign.center,
                        onChanged: onChanged,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        unit,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _redBtn("+", onPlus),
          ],
        ),
      ],
    );
  }

  Widget searchDropdownDialog({
    required String hintText,
    required TextEditingController controller,
    required List<String> nameList,
    required List<int> idList,
    required RxInt selectedId,
    required BuildContext context,
    required AppLocalizations t,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: controller.text.isNotEmpty
                  ? Colors.red
                  : Colors.grey.shade400,
              width: controller.text.isNotEmpty ? 1.5 : 1,
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          errorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
        ),
        onTap: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) {
              List<String> filteredList = List.from(nameList);
              TextEditingController searchController = TextEditingController();
              String? tempSelectedName = controller.text.isEmpty
                  ? null
                  : controller.text;
              int? tempSelectedId = selectedId.value == 0
                  ? null
                  : selectedId.value;

              return StatefulBuilder(
                builder: (context, setState) {
                  return Scaffold(
                    appBar: AppBar(
                      title: Text("${t.selectPrefix} $hintText"),
                      automaticallyImplyLeading: false,
                    ),
                    body: SafeArea(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                hintText: "${t.searchHint}...",
                                prefixIcon: const Icon(Icons.search),
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  filteredList = nameList
                                      .where(
                                        (item) => item.toLowerCase().contains(
                                          value.toLowerCase(),
                                        ),
                                      )
                                      .toList();
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: filteredList.isEmpty
                                ? Center(child: Text(t.noDataAvailable))
                                : ListView.builder(
                                    itemCount: filteredList.length,
                                    itemBuilder: (context, index) {
                                      final item = filteredList[index];
                                      final originalIndex = nameList.indexOf(
                                        item,
                                      );
                                      final isSelected =
                                          tempSelectedName == item;

                                      return ListTile(
                                        title: Text(
                                          item,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: isSelected
                                                ? Colors.red
                                                : Colors.black,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        trailing: isSelected
                                            ? const Icon(
                                                Icons.check,
                                                color: Colors.red,
                                              )
                                            : null,
                                        onTap: () {
                                          setState(() {
                                            tempSelectedName = item;
                                            tempSelectedId =
                                                idList[originalIndex];
                                          });
                                        },
                                      );
                                    },
                                  ),
                          ),
                          Container(
                            height: 60,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => Navigator.pop(context),
                                    child: Center(
                                      child: Text(
                                        t.cancel,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(width: 0.5, color: Colors.grey),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      if (tempSelectedName != null &&
                                          tempSelectedId != null) {
                                        controller.text = tempSelectedName!;
                                        selectedId.value = tempSelectedId!;
                                      }
                                      Navigator.pop(context);
                                    },
                                    child: Center(
                                      child: Text(
                                        t.okBtn,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _redBtn(String t, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 44,
        color: Colors.red,
        alignment: Alignment.center,
        child: Text(
          t,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }

  Widget _textBox(
    String label,
    TextEditingController controller, {
    bool enabled = true,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextField(
          enabled: enabled,
          controller: controller,
          maxLines: 3,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
        ),
      ],
    );
  }
}
