import 'dart:io';
import 'package:emtrack/controllers/inspect_tyre_controller.dart';
import 'package:emtrack/controllers/selected_account_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../inspection/vehicle_inspe_controller.dart';
import '../inspection/vehicle_inspe_model.dart';
import '../l10n/app_localizations.dart';
import '../utils/local_helper.dart';
import '../utils/reusable_dialog.dart';
import '../utils/local_image_cache.dart';

class InspectTyreView extends StatelessWidget {
  InspectTyreView({super.key, InstalledTire? tire})
      : controller = _createController(tire);

  final InspectTyreController controller;
  final SelectedAccountController selectedCtrl =
      Get.isRegistered<SelectedAccountController>()
          ? Get.find<SelectedAccountController>()
          : Get.put(SelectedAccountController());

  static InspectTyreController _createController(InstalledTire? tire) {
    // Tyre explicitly mila hai -> purana (stale) controller hata do taaki
    // naye tyre ke saath fresh onInit chale.
    if (tire != null && Get.isRegistered<InspectTyreController>()) {
      Get.delete<InspectTyreController>(force: true);
    }
    return Get.put(InspectTyreController(initialTire: tire));
  }

  String _clean(dynamic val) {
    if (val == null) return '';
    final d = double.tryParse(val.toString());

    if (d == null) return val.toString();
    return d == d.truncateToDouble() ? d.toInt().toString() : d.toString();
  }

  String _getVehicleId() {
    try {
      if (Get.isRegistered<VehicleInspeController>()) {
        final text = Get.find<VehicleInspeController>().vehicleNumberCtrl.text;
        if (text.isNotEmpty) return text;
      }
    } catch (_) {}

    final vNumFromSearch = controller.tire.brandNo;
    if (vNumFromSearch != null && vNumFromSearch.isNotEmpty) {
      return vNumFromSearch;
    }

    final vId = controller.tire.vehicleId;
    if (vId != null && vId > 0) return vId.toString();

    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (!controller.hasTire) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, dynamic result) {
        if (!controller.isSubmittedSuccessfully) {
          controller.discardUnsubmittedImages();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.black,
          title: Text(
            "${t.inspect} ${LocaleHelper.tyreName(context)}",
            style: const TextStyle(color: Colors.white),
          ),
          leading: BackButton(
            color: Colors.white,
            onPressed: () {
              controller.discardUnsubmittedImages();
              Get.back();
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Obx(() {
              final m = controller.model.value;
              final tire = controller.tire;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          t.selectedParentAccountLocation,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Obx(
                              () => Text(
                            "${selectedCtrl.parentAccountName.value} - ${selectedCtrl.locationName.value}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Divider(),
                        Text(
                          "${t.vehicleId}:",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(_getVehicleId()),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  " ${LocaleHelper.tyreName(context)} ${t.serialNumber}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  tire.tireSerialNo ?? '-',
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
                                  (tire.brandNo != null && tire.brandNo!.trim().isNotEmpty && tire.brandNo!.trim().toLowerCase() != 'null')
                                      ? tire.brandNo!
                                      : ((controller.model.value.brandNo != null && controller.model.value.brandNo!.trim().isNotEmpty)
                                          ? controller.model.value.brandNo!
                                          : '-'),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(),
                        Text(
                          t.wheelPosition,
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          tire.wheelPosition ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Divider(),
                        Text(
                          t.lastInspection,
                          style: const TextStyle(fontSize: 12),
                        ),
                        Obx(
                              () => Text(
                            controller.lastInspectionDateStr.value,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Obx(
                        () => _counterWithTextField(
                      title: "${t.outside} ${t.treadDepth}:",
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
                        title: "Middle ${t.treadDepth}:",
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

                  if (controller.noOfTreadDepthReadings.value == 2 ||
                      controller.noOfTreadDepthReadings.value == 3) ...[
                    Obx(
                          () => _counterWithTextField(
                        title: "${t.inside} ${t.treadDepth}:",
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
                        Text("${t.averageTread}:"),
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
                                m.averageTread.isNotEmpty ? m.averageTread : "",
                                style:
                                const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                controller.measurementUnit.value == 'mm'
                                    ? 'mm'
                                    : '/32nds',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Column(
                  //   crossAxisAlignment: CrossAxisAlignment.start,
                  //   children: [
                  //     Text(t.removeAtUnit),
                  //     const SizedBox(height: 6),
                  //     Container(
                  //       height: 48,
                  //       width: double.infinity,
                  //       padding: const EdgeInsets.symmetric(horizontal: 12),
                  //       alignment: Alignment.centerLeft,
                  //       decoration: BoxDecoration(
                  //         color: const Color(0xffF5F5F5),
                  //         borderRadius: BorderRadius.circular(8),
                  //         border: Border.all(color: Colors.grey.shade300),
                  //       ),
                  //       child: Text(
                  //         controller.tire.removeAt != null
                  //             ? controller.tire.removeAt!
                  //             .toStringAsFixed(2)
                  //             .replaceAll(RegExp(r'\.?0+$'), '')
                  //             : "0",
                  //         style: const TextStyle(fontWeight: FontWeight.bold),
                  //       ),
                  //     ),
                  //   ],
                  // ),

                  Text("${t.airPressureType}:"),
                  const SizedBox(height: 8),
                  Obx(
                        () => Row(
                      children: [
                        Text(
                          t.cold,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: !controller.isHotPressure.value
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => controller.toggleHotCold(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 52,
                            height: 28,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: controller.isHotPressure.value
                                  ? Colors.red
                                  : Colors.grey.shade400,
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 250),
                              alignment: controller.isHotPressure.value
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.all(3),
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          t.hot,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: controller.isHotPressure.value
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Obx(
                        () => _counterWithTextField(
                      title: "${t.airPressure} (${controller.pressureUnit.value}):",
                      unit: controller.pressureUnit.value,
                      textCtrl: controller.airPressureController,
                      onChanged: controller.onAirPressureChanged,
                      onMinus: controller.decAir,
                      onPlus: controller.incAir,
                      showUnitSuffix: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  searchDropdownDialog(
                    hintText: t.wearCondition,
                    controller: controller.wearConditionsId,
                    list: controller.wearConditionsList,
                    context: context,
                    selectedId: controller.selectedWearConditionsId,
                    idList: controller.wearConditionsIdList.toList(),
                    t: t,
                  ),

                  searchDropdownDialog(
                    hintText: t.casingCondition,
                    controller: controller.casingConditionsId,
                    list: controller.casingConditionList,
                    context: context,
                    selectedId: controller.selectedCasingConditionId,
                    idList: controller.casingConditionIdList.toList(),
                    t: t,
                  ),

                  const SizedBox(height: 12),

                  _textBox(
                    t.listOfPreviousComments,
                    controller.previousCommentsCtrl,
                    enabled: false,
                  ),

                  const SizedBox(height: 12),

                  Obx(() => Row(
                    children: [
                      Checkbox(
                        value: controller.stillRelevant.value,
                        activeColor: Colors.red,
                        onChanged: (_) => controller.previousCommentsOnChange(),
                      ),
                      Text(t.stillRelevant),
                    ],
                  )),
                  const SizedBox(height: 12),

                  _textBox(
                    t.commentsLabel,
                    controller.commentCtrl,
                    enabled: true,
                    onChanged: (v) =>
                        controller.model.update((m) => m!.comments = v),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t.uploadImages),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _showImageSourceDialog(context, controller, t),
                          icon: const Icon(Icons.camera_alt, color: Colors.red),
                          label: Text(t.upload),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Obx(() {
                    if (controller.localImages.isEmpty) return const SizedBox();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.images,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 250,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: controller.localImages.length,
                            itemBuilder: (_, i) {
                              final imageFile = controller.localImages[i];
                              final isNetworkImage =
                              imageFile.path.startsWith('http');

                              return Padding(
                                padding: const EdgeInsets.only(
                                    right: 10, top: 12, left: 4),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.red, width: 2),
                                        borderRadius: BorderRadius.circular(14),
                                        color: Colors.white,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: isNetworkImage
                                            ? (LocalImageCache.resolveSync(imageFile.path, tireId: controller.tire.tireId) != null
                                                ? Image.file(
                                                    LocalImageCache.resolveSync(imageFile.path, tireId: controller.tire.tireId)!,
                                                    width: 230,
                                                    height: 250,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Image.network(
                                                    imageFile.path,
                                                    width: 230,
                                                    height: 250,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) =>
                                                        const Icon(
                                                            Icons.broken_image,
                                                            size: 50),
                                                  ))
                                            : Image.file(
                                                imageFile,
                                                width: 230,
                                                height: 250,
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                    ),
                                    if (!isNetworkImage)
                                      Positioned(
                                        top: -10,
                                        right: -10,
                                        child: GestureDetector(
                                          onTap: () {
                                            DialogHelper.showConfirm(
                                              title: t.confirmRemove,
                                              message: t.areYouSureRemoveImage,
                                              confirmText: t.yes,
                                              cancelText: t.no,
                                              onConfirm: () => controller
                                                  .removeLocalImage(i),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.delete,
                                                size: 18, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 12),

                  _actionCard('${t.remove} ${LocaleHelper.tyreName(context)}', t.remove, Icons.delete, () {
                    Get.toNamed(
                      '/remove-tyre',
                      arguments: {
                        "vehicleId": tire.vehicleId,
                        "vehicleNo": _getVehicleId(),
                        "tireId": tire.tireId,
                        "wheelPosition": tire.wheelPosition ?? "",
                        "tireSerialNo": tire.tireSerialNo ?? "",
                        "currentHours": tire.currentHours ?? 0.0,
                        "currentMiles": tire.currentMiles ?? 0.0,
                        "outsideTread": tire.outsideTread ?? 0.0,
                        "middleTread": tire.middleTread ?? 0.0,
                        "insideTread": tire.insideTread ?? 0.0,
                        "currentTreadDepth": tire.currentTreadDepth ?? 0.0,
                        "currentPressure": tire.currentPressure ?? 0.0,
                        "originalTread": tire.originalTread ?? 0.0,
                        "removeAt": tire.removeAt ?? 0.0,
                      },
                    );
                  }),
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
                                disabledBackgroundColor: Colors.red,
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
                                t.submit,
                                style:
                                const TextStyle(color: Colors.white),
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
                                controller.discardUnsubmittedImages();
                                Get.back();
                                Get.back();
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
    bool showUnitSuffix = false,
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
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textCtrl,
                        onTap: () {
                          textCtrl.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: textCtrl.text.length,
                          );
                        },
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ],
                        textAlign: TextAlign.center,
                        onChanged: onChanged,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
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

  Widget _redBtn(String t, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 48,
        color: Colors.red,
        alignment: Alignment.center,
        child: Text(
          t,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _textBox(
      String label,
      TextEditingController ctrl, {
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
          controller: ctrl,
          maxLines: 3,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionCard(
      String title,
      String btn,
      IconData icon,
      VoidCallback onTap,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, color: Colors.red),
            label: Text(btn),
          ),
        ],
      ),
    );
  }

  Widget searchDropdownDialog({
    required String hintText,
    required TextEditingController controller,
    required List<String> list,
    required BuildContext context,
    required AppLocalizations t,
    RxInt? selectedId,
    List<int>? idList,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GetBuilder<InspectTyreController>(
        builder: (c) {
          return TextFormField(
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
            ),
            onTap: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) {
                  List<String> filteredList = List.from(list);
                  TextEditingController searchController =
                  TextEditingController();
                  String? selectedValue =
                  controller.text.isEmpty ? null : controller.text;

                  return StatefulBuilder(
                    builder: (context, setState) {
                      return Scaffold(
                        appBar: AppBar(
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                          title: Text("${t.selectPrefix}$hintText"),
                          elevation: 1,
                        ),
                        body: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: TextField(
                                controller: searchController,
                                decoration: InputDecoration(
                                  hintText: "${t.searchHint}...",
                                  prefixIcon: const Icon(Icons.search),
                                  border: const OutlineInputBorder(),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.red, width: 2),
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    filteredList = value.isEmpty
                                        ? List.from(list)
                                        : list
                                        .where((item) => item
                                        .toLowerCase()
                                        .contains(value.toLowerCase()))
                                        .toList();
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: filteredList.isEmpty
                                  ? Center(child: Text(t.noDataAvailable))
                                  : ListView.separated(
                                itemCount: filteredList.length,
                                separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = filteredList[index];
                                  final isSelected =
                                      selectedValue == item;
                                  return ListTile(
                                    title: Text(
                                      item,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.red
                                            : Colors.black,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? const Icon(Icons.check,
                                        color: Colors.red)
                                        : null,
                                    onTap: () => setState(
                                            () => selectedValue = item),
                                  );
                                },
                              ),
                            ),
                            Container(
                              height: 56,
                              decoration: const BoxDecoration(
                                border: Border(
                                    top: BorderSide(color: Colors.grey)),
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
                                              color: Colors.red, fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(width: 0.5, color: Colors.grey),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        if (selectedValue != null) {
                                          final index =
                                          list.indexOf(selectedValue!);
                                          controller.text = selectedValue!;
                                          if (selectedId != null &&
                                              idList != null &&
                                              index >= 0 &&
                                              index < idList.length) {
                                            selectedId.value = idList[index];
                                          }
                                        }
                                        Navigator.pop(context);
                                      },
                                      child: const Center(
                                        child: Text(
                                          "OK",
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
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
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showImageSourceDialog(
      BuildContext context,
      InspectTyreController c,

      AppLocalizations t,
      ) {
    Get.bottomSheet(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(

        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      SafeArea(
        bottom: true,
        top: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              ListTile(
                title: Center(
                  child: Text(t.takePhoto,
                      style: const TextStyle(color: Colors.black)),
                ),
                onTap: () {
                  Get.back();
                  c.pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                title: Center(
                  child: Text(t.chooseFromGallery,
                      style: const TextStyle(color: Colors.black)),
                ),
                onTap: () {
                  Get.back();
                  c.pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                title: Center(
                  child: Text(t.cancel,
                      style: const TextStyle(color: Colors.black)),
                ),
                onTap: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
