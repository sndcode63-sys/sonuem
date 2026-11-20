import 'package:emtrack/color/app_color.dart';
import 'package:emtrack/controllers/preferences_controller.dart';
import 'package:emtrack/utils/app_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../l10n/app_localizations.dart';

class PreferencesView extends GetView<PreferencesController> {
  PreferencesView({super.key});

  @override
  final PreferencesController controller = Get.put(PreferencesController());

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        title: Text(
          t.preferences,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildSectionLabel(t.language),
                    const SizedBox(height: 6),
                    _selector(
                      t: t,
                      title: t.language,
                      value: controller.selectedLanguage,
                      items: controller.languages,
                      onSelect: controller.updateLanguage,
                    ),
                    const SizedBox(height: 16),
                    _buildSectionLabel(t.measurementSystem),
                    const SizedBox(height: 6),
                    _selector(
                      t: t,
                      title: t.measurementSystem,
                      value: controller.selectedMeasurement,
                      items: controller.measurementSystems,
                      onSelect: controller.updateMeasurement,
                    ),
                    const SizedBox(height: 16),
                    _buildSectionLabel(t.pressureUnit),
                    const SizedBox(height: 6),
                    _selector(
                      t: t,
                      title: t.pressureUnit,
                      value: controller.selectedPressure,
                      items: controller.pressureUnits,
                      onSelect: controller.updatePressure,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: _secondaryButton(
                            text: t.cancel,
                            onTap: controller.cancelPreferences,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _primaryButton(
                            text: t.updateBtn,
                            onTap: controller.updatePre,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              if (controller.isLoading.value) AppLoader1(isLoading: true),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black54,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _selector({
    required AppLocalizations t,
    required String title,
    required RxString value,
    required List<String> items,
    required Function(String) onSelect,
  }) {
    return Obx(
      () => GestureDetector(
        onTap: () => _showSelectionDialog(
          t: t,
          title: title,
          items: items,
          currentValue: value.value,
          onSelect: onSelect,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value.value.isEmpty
                      ? '${t.selectPrefix} $title'
                      : value.value,
                  style: TextStyle(
                    fontSize: 15,
                    color: value.value.isEmpty
                        ? Colors.grey.shade500
                        : Colors.black87,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSelectionDialog({
    required AppLocalizations t,
    required String title,
    required List<String> items,
    required String currentValue,
    required Function(String) onSelect,
  }) {
    String selectedVal = items.firstWhere(
      (item) => item.trim().toLowerCase() == currentValue.trim().toLowerCase(),
      orElse: () => currentValue.isNotEmpty ? currentValue : (items.isNotEmpty ? items.first : ''),
    );
    final ScrollController scrollCtrl = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedIndex = items.indexWhere(
        (item) => item.trim().toLowerCase() == selectedVal.trim().toLowerCase(),
      );
      if (selectedIndex != -1 && scrollCtrl.hasClients) {
        scrollCtrl.jumpTo(selectedIndex * 52.0);
      }
    });

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            contentPadding: const EdgeInsets.only(top: 12),
            content: SizedBox(
              height: 260,
              width: Get.width * 0.8,
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final e = items[i];
                  final isSelected = selectedVal.trim().toLowerCase() == e.trim().toLowerCase();
                  return InkWell(
                    onTap: () {
                      setDialogState(() {
                        selectedVal = e;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.red.withAlpha(20)
                            : Colors.transparent,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            e,
                            style: TextStyle(
                              fontSize: 15,
                              color: isSelected ? Colors.red : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.w600
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
            actionsPadding: EdgeInsets.zero,
            actions: [
              const Divider(height: 1, thickness: 1),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(t.cancel, style: const TextStyle(fontSize: 15)),
                    ),
                  ),
                  Container(width: 1, height: 48, color: Colors.grey.shade300),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        onSelect(selectedVal);
                        Get.back();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        t.okBtn,
                        style: const TextStyle(
                          fontSize: 15,
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

  Widget _primaryButton({required String text, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _secondaryButton({required String text, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.primary, width: 0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
