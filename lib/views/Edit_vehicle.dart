import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:emtrack/color/app_color.dart';
import 'package:emtrack/controllers/selected_account_controller.dart';
import 'package:emtrack/controllers/update_vehicle_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../l10n/app_localizations.dart';
import '../routes/app_pages.dart';
import '../utils/app_dialog.dart';
import '../utils/reusable_dialog.dart';
import '../utils/local_image_cache.dart';
import '../widgets/vehicle_daigram.dart';

class UpdateVehicleView extends StatelessWidget {
  final vc = Get.put(UpdateVehicleController());
  final selectedCtrl = Get.put(SelectedAccountController());

  UpdateVehicleView({super.key});

  InputDecoration _dec({
    required String hint,
    String? errorText,
    Widget? suffixIcon,
    bool hasError = false,
  }) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
      errorText: (errorText != null && errorText.isNotEmpty) ? errorText : null,
      errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: hasError ? Colors.red : Colors.grey),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),

      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
      disabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.editVehicle,
          style: TextStyle(color: AppColors.textWhite, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: AppColors.textWhite),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.selectedParentAccountLocation),
              Obx(
                    () => Text(
                  "${selectedCtrl.parentAccountName.value} - ${selectedCtrl.locationName.value}",
                  style: TextStyle(
                    color: AppColors.buttonDanger,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
        
              const SizedBox(height: 12),
        
              // ── Vehicle ID ──────────────────────────────────────────────────
              _label(t.vehicleId),
              Obx(
                    () => TextField(
                  controller: vc.vehicleNumberCtrl,
                  focusNode: vc.vehicleNumNode,
                  cursorColor: Colors.red,
                  decoration: _dec(
                    hint: '${t.enterPrefix}${t.vehicleNumber}',
                    errorText: vc.vehicleNumberError.value,
                    hasError: vc.vehicleNumberError.value.isNotEmpty,
                  ),
                  onChanged: (v) {
                    vc.vehicleNumber.value = v;
                    vc.clearVehicleNumberError();
                  },
                ),
              ),
        
              const SizedBox(height: 12),
        
              // ── Tracking Method ─────────────────────────────────────────────
              _label(t.trackingMethod),
              Obx(
                    () => Column(
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
                        title: Text(
                          _getTrackingMethodLabel(t, vc.trackingMethodText.value),
                        ),
                        trailing: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.red,
                        ),
                        onTap: () => _showTrackingDialog(t),
                      ),
                    ),
                    if (vc.trackingMethodError.value.isNotEmpty)
                      _errText(vc.trackingMethodError.value),
                  ],
                ),
              ),
        
              const SizedBox(height: 12),
        
              Obx(() {
                final method = vc.trackingMethodText.value;
                if (method != 'Hours' && method != 'Both') {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(t.currentHours),
                    TextField(
                      controller: vc.currentHoursCtrl,
                      cursorColor: Colors.red,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _dec(
                        hint: '0',
                        errorText: vc.currentHoursError.value,
                        hasError: vc.currentHoursError.value.isNotEmpty,
                        suffixIcon: GestureDetector(
                          onTap: () {
                            vc.currentHoursCtrl.clear();
                            vc.currentHours.value = "";
                            vc.currentHoursError.value = t.requiredField;
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.close,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      onChanged: (v) {
                        vc.onCurrentHoursChanged(v);
                        vc.currentHoursError.value =
                        v.trim().isEmpty ? t.requiredField : "";
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }),
        
              // ── Current KM  (Distance / Both) ──────────────────────────────
              Obx(() {
                final method = vc.trackingMethodText.value;
                if (method != 'Distance' && method != 'Both') {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("${t.currentDistance} ${vc.kmMilesLabel.value}"),
                    TextField(
                      controller: vc.currentKmCtrl,
                      cursorColor: Colors.red,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _dec(
                        hint: '0',
                        errorText: vc.currentKmError.value,
                        hasError: vc.currentKmError.value.isNotEmpty,
                        suffixIcon: GestureDetector(
                          onTap: () {
                            vc.currentKmCtrl.clear();
                            vc.currentKm.value = "";
                            vc.currentKmError.value = t.requiredField;
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.close,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      onChanged: (v) {
                        vc.onCurrentKmChanged(v);
                        vc.currentKmError.value =
                        v.trim().isEmpty ? t.requiredField : "";
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }),
        
              // ── Manufacturer ────────────────────────────────────────────────
              _label(t.manufacturer),
              Obx(
                    () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _searchField(
                      context: context,
                      hint: '${t.selectPrefix}${t.manufacturer}',
                      controller: vc.manufacturerCtrl,
                      focusNode: vc.manufNode,
                      enabled: true,
                      hasError: vc.manufacturerError.value.isNotEmpty,
                      onTap: () => _openDialog(
                        context: context,
                        focusNode: vc.manufNode,
                        title: '${t.selectPrefix}${t.manufacturer}',
                        selectedValue: vc.manufacturer,
                        items: vc.manufacturerList,
                        onSelect: (item) {
                          vc.selectManufacturer(item);
                          vc.manufacturerCtrl.text = item.toUpperCase();
                          vc.clearManufacturerError();
                        },
                        t: t,
                      ),
                    ),
                    if (vc.manufacturerError.value.isNotEmpty)
                      _errText(vc.manufacturerError.value),
                  ],
                ),
              ),
        
              const SizedBox(height: 12),
        
              // ── Type ────────────────────────────────────────────────────────
              _label(t.vehicleType),
              Obx(
                    () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _searchField(
                      context: context,
                      hint: '${t.selectPrefix}${t.vehicleType}',
                      controller: vc.typeCtrl,
                      focusNode: vc.typeNode,
                      enabled: vc.manufacturerId.value != 0,
                      hasError: vc.typeError.value.isNotEmpty,
                      onTap: vc.manufacturerId.value != 0
                          ? () => _openDialog(
                        context: context,
                        focusNode: vc.typeNode,
                        title: '${t.selectPrefix}${t.vehicleType}',
                        selectedValue: vc.type,
                        items: vc.typeList,
                        onSelect: (item) {
                          vc.selectType(item);
                          vc.clearTypeError();
                        },
                        t: t,
                      )
                          : null,
                    ),
                    if (vc.typeError.value.isNotEmpty)
                      _errText(vc.typeError.value),
                  ],
                ),
              ),
        
              const SizedBox(height: 12),
        
              // ── Model ───────────────────────────────────────────────────────
              _label(t.model),
              Obx(
                    () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _searchField(
                      context: context,
                      hint: '${t.selectPrefix}${t.model}',
                      controller: vc.modelCtrl,
                      focusNode: vc.modelNode,
                      enabled: true,
                      hasError: vc.modelError.value.isNotEmpty,
                      onTap: () => _openDialog(
                        context: context,
                        focusNode: vc.modelNode,
                        title: '${t.selectPrefix}${t.model}',
                        selectedValue: vc.model,
                        items: vc.modelList,
                        onSelect: (item) {
                          vc.selectModel(item);
                          vc.clearModelError();
                        },
                        t: t,
                      ),
                    ),
                    if (vc.modelError.value.isNotEmpty)
                      _errText(vc.modelError.value),
                  ],
                ),
              ),
        
              const SizedBox(height: 12),
        
              // ── Tyre Size ───────────────────────────────────────────────────
              _label(t.tyreSize),
              Obx(
                    () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _searchField(
                      context: context,
                      hint: '${t.selectPrefix}${t.tyreSize}',
                      controller: vc.tyreSizeCtrl,
                      focusNode: vc.sizeNode,
                      enabled: true,
                      hasError: vc.tyreSizeError.value.isNotEmpty,
                      onTap: () => _openDialog(
                        context: context,
                        focusNode: vc.sizeNode,
                        title: '${t.selectPrefix}${t.tyreSize}',
                        selectedValue: vc.tyreSize,
                        items: vc.tyreSizeList,
                        onSelect: (item) {
                          vc.selectTyreSize(item);
                          vc.clearTyreSizeError();
                        },
                        t: t,
                      ),
                    ),
                    if (vc.tyreSizeError.value.isNotEmpty)
                      _errText(vc.tyreSizeError.value),
                  ],
                ),
              ),
        
              const SizedBox(height: 12),
        
              // ── Removal Tread ───────────────────────────────────────────────
              _label(t.removalTread),
              Obx(
                    () => TextField(
                  controller: vc.removalTreadCtrl,
                  cursorColor: Colors.red,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _dec(
                    hint: t.removalTread,
                    errorText: vc.removalTreadError.value,
                    hasError: vc.removalTreadError.value.isNotEmpty,
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Text(
                            "mm",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            vc.removalTreadCtrl.clear();
                            vc.removalTread.value = "";
                            vc.removalTreadError.value = t.requiredField;
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  onChanged: (v) {
                    vc.removalTread.value = v;
                    vc.removalTreadError.value =
                    v.trim().isEmpty ? t.requiredField : "";
                  },
                ),
              ),
        
              const SizedBox(height: 12),
        
              // ── Comments ────────────────────────────────────────────────────
              _label(t.vehicleComments),
              TextField(
                controller: vc.commentsCtrl,
                cursorColor: Colors.red,
                decoration: _dec(hint: t.commentsHint),
                maxLines: null,
                onChanged: (v) {
                  vc.comments.value = v;
                  vc.clearCommentsError();
                },
              ),

              const SizedBox(height: 16),

              // ─── VEHICLE IMAGES ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.uploadImages,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Colors.red,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () => _showImagePicker(context, vc, t),
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Colors.red,
                      ),
                      label: Text(
                        t.upload,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Obx(() {
                if (vc.vehicleImages.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.uploadedImages, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: vc.vehicleImages.length,
                        itemBuilder: (_, i) {
                          final imageFile = vc.vehicleImages[i];
                          final path = imageFile.path;
                          final isHttp = path.startsWith('http');
                          final cachedLocal = isHttp
                              ? LocalImageCache.resolveSync(path, vehicleId: vc.vehicleId.value.toString())
                              : null;

                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0, top: 8, bottom: 8),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: cachedLocal != null && cachedLocal.existsSync()
                                        ? Image.file(cachedLocal, fit: BoxFit.cover)
                                        : isHttp
                                            ? Image.network(
                                                path,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
                                              )
                                            : Image.file(
                                                imageFile,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
                                              ),
                                  ),
                                ),
                                Positioned(
                                  top: -8,
                                  right: -8,
                                  child: GestureDetector(
                                    onTap: () {
                                      DialogHelper.showConfirm(
                                        title: t.confirmRemove,
                                        message: t.areYouSureRemoveImage,
                                        confirmText: t.yes,
                                        cancelText: t.no,
                                        onConfirm: () => vc.removeVehicleImage(i),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 18),
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
        
              // ── Pressure + Diagram ──────────────────────────────────────────
              Obx(() {
                if (!vc.showPressureSection) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      t.vehicleDiagram,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    IgnorePointer(
                      child: Obx(() {
                        return VehicleDiagram(
                          key: ValueKey(
                            'diagram_${vc.axleConfigValue}_${vc.vehicleId.value}',
                          ),
                          tires: vc.installedTires,
                          vehicleId: vc.vehicleId.value,
                          vehicleNumber: vc.vehicleNumber.value,
                          axleConfig: vc.axleConfigValue,
                          isEditMode: true,
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
        
                    Obx(
                          () => Column(
                        children: List.generate(vc.axlePressures.length, (index) {
                          return _pressureRow(
                            context,
                            "${t.axleLabel} ${index + 1}",
                            index,
                            t,
                          );
                        }),
                      ),
                    ),
                  ],
                );
              }),
        
              const SizedBox(height: 24),
        
              // ── Submit ──────────────────────────────────────────────────────
              Obx(
                    () => InkWell(
                  onTap: vc.isSubmitting.value
                      ? null
                      : () async => await vc.updateForm(t),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: vc.isSubmitting.value
                          ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 10),
                        ],
                      )
                          : Text(
                        t.submit,
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        
              // ── Cancel ──────────────────────────────────────────────────────
              Center(
                child: TextButton(
                  onPressed: () => AppDialog.showConfirmDialog(
                    title: t.cancelRequestTitle,
                    message: t.cancelRequestMessage,
                    okText: t.cancelRequestYes,
                    onOk: () {
                      Get.back();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Get.offAllNamed(AppPages.HOME);
                      });
                    },
                  ),
                  child: Text(
                    t.cancel,
                    style: TextStyle(color: AppColors.buttonDanger),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTrackingMethodLabel(AppLocalizations t, String internalValue) {
    if (internalValue == "Hours") return t.trackingMethodHours;
    if (internalValue == "Distance") return t.trackingMethodDistance;
    if (internalValue == "Both") return t.trackingMethodBoth;
    return internalValue;
  }

  Widget _pressureRow(
      BuildContext context,
      String label,
      int index,
      AppLocalizations t,
      ) {
    final ctrl = vc.getPressureController(index);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(t.recommendedPressureFor(label)),
        const SizedBox(height: 4),
        Container(
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: () => vc.decrementPressure(index),
                  child: Container(
                    color: AppColors.buttonDanger,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.remove,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Obx(() {
                    return IntrinsicWidth(
                      child: TextField(
                        controller: ctrl,
                        textAlign: TextAlign.left,
                        keyboardType: TextInputType.number,
                        cursorColor: Colors.red,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          suffix: Text(
                            ' ${vc.pressureUnit.value}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        onChanged: (v) {
                          final val = double.tryParse(v) ?? 0.0;
                          vc.setPressure(index, val);
                        },                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: () => vc.incrementPressure(index),
                  child: Container(
                    color: AppColors.buttonDanger,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showTrackingDialog(AppLocalizations t) {
    Get.defaultDialog(
      title: t.trackingMethodTitle,
      titleStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      titlePadding: const EdgeInsets.only(top: 16, bottom: 8),
      contentPadding: EdgeInsets.zero,
      radius: 12,
      backgroundColor: Colors.white,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          for (final option in ["Hours", "Distance", "Both"])
            Obx(
                  () => _iosTile(
                text: _getTrackingMethodLabel(t, option),
                selected: vc.trackingMethodText.value == option,
                onTap: () => vc.trackingMethodText.value = option,
              ),
            ),
          const Divider(height: 1),
          SizedBox(
            height: 40,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Get.back(),
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
                Container(width: 1, color: Colors.grey.shade300),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      vc.clearTrackingMethodError();
                      Get.back();
                    },
                    child: Center(
                      child: Text(
                        t.okBtn,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
  }

  Widget _iosTile({
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: selected ? Colors.red : Colors.black,
              ),
            ),
            const Spacer(),
            if (selected) const Icon(Icons.check, color: Colors.red, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 4),
    child: Row(
      children: [
        Text(text),
        const Text(" *", style: TextStyle(color: Colors.red)),
      ],
    ),
  );

  Widget _errText(String msg) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      msg,
      style: const TextStyle(color: Colors.red, fontSize: 12),
    ),
  );

  Widget _searchField({
    required BuildContext context,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool enabled,
    required bool hasError,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AbsorbPointer(
        child: TextFormField(
          focusNode: focusNode,
          readOnly: true,
          enabled: enabled,
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: hasError ? Colors.red : Colors.grey,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            disabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            border: const OutlineInputBorder(),
            suffixIcon: enabled
                ? const Icon(Icons.arrow_drop_down, color: Colors.red)
                : const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  void _openDialog({
    required BuildContext context,
    required FocusNode focusNode,
    required String title,
    required RxString selectedValue,
    required List<String> items,
    required Function(String) onSelect,
    required AppLocalizations t,
  }) {
    final RxList<String> filteredList = items.obs;
    final TextEditingController searchCtrl = TextEditingController();
    final ScrollController scrollCtrl = ScrollController();

    final String matchedInitial = items.firstWhere(
          (item) => item.toUpperCase() == selectedValue.value.toUpperCase(),
      orElse: () => selectedValue.value,
    );
    final RxString tempSelected = matchedInitial.obs;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Scaffold(
        appBar: AppBar(
          title: Text(title),
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: searchCtrl,
                cursorColor: Colors.red,
                decoration: InputDecoration(
                  hintText: '${t.searchHint}...',
                  prefixIcon: const Icon(Icons.search, color: Colors.red),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
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
                  return Center(child: Text(t.noDataAvailable));
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final selectedIndex = filteredList.indexWhere(
                        (item) =>
                    item.toUpperCase() == tempSelected.value.toUpperCase(),
                  );
                  if (selectedIndex != -1 && scrollCtrl.hasClients) {
                    scrollCtrl.jumpTo(selectedIndex * 56.0);
                  }
                });

                return ListView.builder(
                  controller: scrollCtrl,
                  itemCount: filteredList.length,
                  itemBuilder: (_, index) {
                    final item = filteredList[index];
                    return Obx(() {
                      final isSelected =
                          item.toUpperCase() ==
                              tempSelected.value.toUpperCase();
                      return ListTile(
                        tileColor: isSelected
                            ? Colors.red.withValues(alpha: 0.08)
                            : Colors.transparent,
                        title: Text(
                          item,
                          style: TextStyle(
                            color: isSelected ? Colors.red : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
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
              height: 56,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.of(dialogContext).pop(),
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
                        if (tempSelected.value.isNotEmpty) {
                          selectedValue.value = tempSelected.value;
                          onSelect(tempSelected.value);
                          Navigator.of(dialogContext).pop();
                        }
                      },
                      child: Center(
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      FocusScope.of(context).requestFocus(focusNode);
    });
  }

  void _showImagePicker(BuildContext context, UpdateVehicleController vc, AppLocalizations t) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.red),
              title: Text(t.takePhoto),
              onTap: () {
                Navigator.pop(context);
                vc.pickVehicleImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.red),
              title: Text(t.chooseFromGallery),
              onTap: () {
                Navigator.pop(context);
                vc.pickVehicleImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}