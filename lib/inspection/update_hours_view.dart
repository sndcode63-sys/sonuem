import 'package:emtrack/color/app_color.dart';
import 'package:emtrack/controllers/selected_account_controller.dart';
import 'package:emtrack/controllers/update_hours_controller.dart';
import 'package:emtrack/utils/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../l10n/app_localizations.dart';

class UpdateHoursView extends StatelessWidget {
  UpdateHoursView({super.key});

  final UpdateHoursController updatectrl = Get.put(UpdateHoursController());
  final SelectedAccountController selectedCtrl = Get.put(
    SelectedAccountController(),
  );

  InputDecoration _fieldDecoration({String? hint, String? errorText}) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText?.isNotEmpty == true ? errorText : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          t.updateHours,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            _label(t.selectedParentAccount),
            const SizedBox(height: 4),
            Obx(
                  () => Text(
                "${selectedCtrl.parentAccountName.value} - ${selectedCtrl.locationName.value}",
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 20),

            _label(t.vehicleId),
            const SizedBox(height: 4),
            Obx(
                  () => Text(
                updatectrl.vehicleNumber.value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 24),

            _label(t.lastRecordedDate),
            const SizedBox(height: 10),
            Obx(() => _disabledField(updatectrl.formatDate(updatectrl.lastRecordedDate.value))),

            const SizedBox(height: 20),

            // ─── Survey Date ────────────────────────────────────────────
            _requiredLabel(t.surveyDate), // ✅ Localized
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => updatectrl.pickSurveyDate(context),
              child: AbsorbPointer(
                child: TextField(
                  controller: updatectrl.surveyDateController,
                  decoration: InputDecoration(
                    hintText: t.selectDate, // ✅ Localized
                    suffixIcon: const Icon(
                      Icons.calendar_month,
                      color: Colors.red,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ─── HOURS SECTION (Hours ya Both) ──────────────────────────
            Obx(() {
              if (!updatectrl.showHours) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Last Recorded Hours
                  _label(t.lastRecordedHours), // ✅ Localized
                  const SizedBox(height: 10),
                  Obx(
                        () => _disabledField(
                      updatectrl.lastRecordedHours.value.toInt().toString(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Update Hours
                  _requiredLabel(t.updateHoursLabel), // ✅ Localized
                  const SizedBox(height: 10),
                  Obx(() {
                    final String? errorMsg = updatectrl.updateHoursError.value;
                    final bool hasError = errorMsg != null && errorMsg.isNotEmpty;

                    return TextField(
                      controller: updatectrl.updateHoursController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (v) {
                        updatectrl.updateHoursError.value = updatectrl.validateHours();
                      },
                      decoration: _fieldDecoration(
                        hint: t.enterHours,
                        errorText: hasError ? errorMsg : null,
                      ).copyWith(

                        focusedErrorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),

                        errorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 1),
                        ),

                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),
                ],
              );
            }),

            // ─── KM SECTION (Distance ya Both) ─────────────────────────
            Obx(() {
              if (!updatectrl.showKm) return const SizedBox.shrink();

              final currentUnit = updatectrl.unitString;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Last Recorded Unit Title
                  _label("Last Recorded $currentUnit"),

                  const SizedBox(height: 10),
                  Obx(
                    // ✅ Fixed: VehicleView ke `_cleanMiles` ki tarah dynamic localization preference matching display logic lagaya hai
                        () => _disabledField(
                      updatectrl.displayLastRecordedKm.value,
                    ),
                  ),

                  const SizedBox(height: 20),

                  _requiredLabel("Update $currentUnit"),

                  const SizedBox(height: 10),
                  TextField(
                    controller: updatectrl.updateKmController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (v) {
                      updatectrl.updateKmError.value = updatectrl.validateKm();
                    },
                    decoration: _fieldDecoration(
                      hint: "Enter $currentUnit",
                      errorText: updatectrl.updateKmError.value,
                    ).copyWith(
                      focusedErrorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                      errorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: updatectrl.updateKmError.value != null ? Colors.red : Colors.red,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }),


            const SizedBox(height: 12),

            // ─── Update Button ──────────────────────────────────────────
            Obx(
                  () => SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonDanger,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: updatectrl.loading.value
                      ? null
                      : () {
                    // ✅ Dono validate karo
                    final hoursErr = updatectrl.showHours
                        ? updatectrl.validateHours()
                        : null;
                    final kmErr = updatectrl.showKm
                        ? updatectrl.validateKm()
                        : null;

                    updatectrl.updateHoursError.value = hoursErr;
                    updatectrl.updateKmError.value = kmErr;

                    if (hoursErr != null || kmErr != null) return;

                    FocusManager.instance.primaryFocus?.unfocus();

                    AppDialog.showConfirmDialog(
                      title: t.updateVehicleDataTitle, // ✅ Localized
                      message: t.updateVehicleDataMsg, // ✅ Localized
                      okText: t.proceed, // ✅ Localized
                      cancelText: t.cancel, // ✅ Localized
                      onOk: () => updatectrl.submitUpdateHours(),
                    );
                  },
                  child: updatectrl.loading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    t.updateBtn, // ✅ Localized
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ─── Cancel ─────────────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Text(
                  t.cancel, // ✅ Localized
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: const TextStyle(color: Colors.black54, fontSize: 13));

  Widget _requiredLabel(String text) => RichText(
    text: TextSpan(
      text: text,
      style: const TextStyle(color: Colors.black, fontSize: 13),
      children: const [
        TextSpan(
          text: " *",
          style: TextStyle(color: Colors.red),
        ),
      ],
    ),
  );

  Widget _disabledField([String? value]) => Container(
    height: 50,
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Text(
      value ?? "",
      style: const TextStyle(
        color: Colors.black54,
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
    ),
  );
}