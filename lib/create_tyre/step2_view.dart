import 'package:emtrack/create_tyre/create_tyre_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../l10n/app_localizations.dart';

class Step2View extends StatefulWidget {
  const Step2View({super.key});

  @override
  State<Step2View> createState() => _Step2ViewState();
}

class _Step2ViewState extends State<Step2View> {
  final CreateTyreController c = Get.find<CreateTyreController>();

  static const List<String> _starOptions = [
    "**",
    "***",
    "****",
    "*/**",
    "***/****",
  ];

  static InputDecoration _dec({String? hint, Widget? prefix, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefix,
      suffixIcon: suffix,
      border: const OutlineInputBorder(),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 1.5),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.description,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 20),

        _label(t.manufacture, required: true),
        Obx(
              () => _searchDropdown(
            hintText: t.searchTireManufacturer,
            controller: c.manufacturerId,
            nameList: c.manufacturerList.toList(),
            idList: c.manufacturerIdList.toList(),
            selectedId: c.selectedManufacturerId,
            validator: (v) =>
            (v == null || v.trim().isEmpty) ? "⚠️ ${t.enterValidDetails}" : null,
            context: context,
            onChanged: (id, name) async {
              c.filterTireSizesByManufacturer(id);
            },
          ),
        ),

        _label(t.tireSize, required: true),
        Obx(
              () => _searchDropdown(
            hintText: t.chooseManufacturerFirst,
            controller: c.sizeId,
            nameList: c.tireSizeList.toList(),
            idList: c.tireSizeIdList.toList(),
            selectedId: c.selectedSizeId,
            validator: (v) =>
            (v == null || v.trim().isEmpty) ? "⚠️ ${t.enterValidDetails}" : null,
            context: context,
            toUpperCase: true,
            onChanged: (id, name) async {
              await c.getTireTypes(id);
            },
          ),
        ),

        Obx(() {
          if (c.selectedSizeId.value == 0) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(c.ratingLabel.value),
              c.showStarRating.value
                  ? _starRatingField(context, t)
                  : _plyRatingDropdown(context, t),
              const SizedBox(height: 14),
            ],
          );
        }),

        _label(t.selectType, required: true),
        Obx(
              () => _searchDropdown(
            hintText: t.chooseSizeFirst,
            controller: c.typeId,
            nameList: c.typeList.toList(),
            idList: c.typeIdList.toList(),
            selectedId: c.selectedTypeId,
            validator: (v) => (v == null || v.trim().isEmpty) ? "⚠️ ${t.enterValidDetails}" : null,
            context: context,
            toUpperCase: true,
          ),
        ),

        _label(t.indCode),
        Obx(
              () => _searchDropdown(
            hintText: t.searchIndCode,
            controller: c.indCodeId,
            nameList: c.indCodeList.toList(),
            idList: c.indCodeIdList.toList(),
            selectedId: c.selectedIndCodeId,
            context: context,
          ),
        ),

        _label(t.compound),
        Obx(
              () => _searchDropdown(
            hintText: t.searchCompound,
            controller: c.compoundId,
            nameList: c.compoundList.toList(),
            idList: c.compoundIdList.toList(),
            selectedId: c.selectedCompoundId,
            context: context,
          ),
        ),

        _label(t.loadRating),
        Obx(
              () => _searchDropdown(
            hintText: t.searchLoadRating,
            controller: c.loadRatingId,
            nameList: c.loadRatingList.toList(),
            idList: c.loadRatingIdList.toList(),
            selectedId: c.selectedLoadRatingId,
            context: context,
          ),
        ),

        _label(t.speedRating),
        Obx(
              () => _searchDropdown(
            hintText: t.searchSpeedRating,
            controller: c.speedRatingId,
            nameList: c.speedRatingList.toList(),
            idList: c.speedRatingIdList.toList(),
            selectedId: c.selectedSpeedRatingId,
            context: context,
          ),
        ),

        const SizedBox(height: 24),
        _primaryBtn(t.nextBtn, () {
          final valid = c.formKey.currentState?.validate() ?? false;
          if (valid) c.nextStep();
        }),
        const SizedBox(height: 12),
        _outlineBtn(t.previousBtn, c.previousStep),
        const SizedBox(height: 12),
        _outlineBtn(t.cancelBtn, c.cancelDialog),
      ],
    );
  }

  Widget _starRatingField(BuildContext context, AppLocalizations t) {
    return Obx(() {
      final enabled = c.isStarEnabled.value;
      final currentVal = c.starRating.value;
      final String displayText = (currentVal >= 1 && currentVal <= 5)
          ? _starOptions[currentVal - 1]
          : t.starRatingSelect;

      return InkWell(
        onTap: enabled ? () => _starDialog(context, t) : null,
        child: InputDecorator(
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade50,
            suffixIcon: Icon(
              Icons.arrow_drop_down,
              color: enabled ? Colors.red : Colors.grey,
            ),
            border: const OutlineInputBorder(),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
          child: Text(
            displayText,
            style: TextStyle(
              color: currentVal == 0 ? Colors.grey : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
    });
  }

  void _starDialog(BuildContext context, AppLocalizations t) {
    int tempIndex = (c.starRating.value >= 1 && c.starRating.value <= 5)
        ? c.starRating.value - 1
        : -1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: EdgeInsets.zero,
            titlePadding: const EdgeInsets.symmetric(vertical: 20),
            title: Text(
              t.starRating,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(height: 1),
                SizedBox(
                  width: double.maxFinite,
                  height: 280,
                  child: ListView.builder(
                    itemCount: _starOptions.length,
                    itemBuilder: (context, index) {
                      final item = _starOptions[index];
                      final isSelected = tempIndex == index;
                      return InkWell(
                        onTap: () => setDialogState(() => tempIndex = index),
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
                                  fontSize: 18,
                                  color: isSelected ? Colors.red : Colors.black,
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
                const Divider(height: 1),
              ],
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        t.cancelBtn,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        if (tempIndex != -1) c.setStarRating(tempIndex + 1);
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        t.okBtn,
                        style: const TextStyle(
                          color: Colors.red,
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
    );
  }

  Widget _plyRatingDropdown(BuildContext context, AppLocalizations t) {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: _searchDropdown(
          hintText: "Select Ply Rating",
          controller: c.plyRatingId,
          nameList: c.plyRatingList.toList(),
          idList: c.plyRatingIdList.toList(),
          selectedId: c.selectedPlyRatingId,
          context: context,
        ),
      );
    });
  }

  Widget _searchDropdown({
    required String hintText,
    required TextEditingController controller,
    required List<String> nameList,
    required List<int> idList,
    required RxInt selectedId,
    required BuildContext context,
    String? Function(String?)? validator,
    Future<void> Function(int id, String name)? onChanged, // ✅ async
    bool toUpperCase = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: _dec(hint: hintText, prefix: const Icon(Icons.search)),
        onTap: () => _showPickerDialog(
          context: context,
          hintText: hintText,
          displayList: toUpperCase
              ? nameList.map((e) => e.toUpperCase()).toList()
              : nameList,
          originalNameList: nameList,
          idList: idList,
          controller: controller,
          selectedId: selectedId,
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _showPickerDialog({
    required BuildContext context,
    required String hintText,
    required List<String> displayList,
    required List<String> originalNameList,
    required List<int> idList,
    required TextEditingController controller,
    required RxInt selectedId,
    Future<void> Function(int id, String name)? onChanged,
  }) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        String query = "";
        String? tempName = controller.text.trim().isEmpty
            ? null
            : controller.text.trim();
        int? tempId = selectedId.value == 0 ? null : selectedId.value;

        return StatefulBuilder(
          builder: (ctx, ss) {
            final filtered = displayList
                .where((e) => e.toLowerCase().contains(query.toLowerCase()))
                .toList();

            return Scaffold(
              appBar: AppBar(
                title: Text("${t.selectPrefix}$hintText"),
                automaticallyImplyLeading: false,
              ),
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      decoration: _dec(
                        hint: t.searchHint,
                        prefix: const Icon(Icons.search),
                      ),
                      onChanged: (v) => ss(() => query = v),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final item = filtered[i];
                        final isSelected = tempName == item;
                        return ListTile(
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
                          onTap: () => ss(() {
                            tempName = item;
                            final origIdx = displayList.indexOf(item);
                            if (origIdx != -1 && origIdx < idList.length) {
                              tempId = idList[origIdx];
                            }
                          }),
                        );
                      },
                    ),
                  ),
                  Container(
                    height: 60,
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => Navigator.pop(ctx),
                            child: Center(
                              child: Text(
                                t.cancelBtn,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(width: 1, color: Colors.grey),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              if (tempName != null && tempId != null) {
                                controller.text = tempName ?? '';
                                selectedId.value = tempId ?? 0;
                                await onChanged?.call(
                                    tempId ?? 0, tempName ?? '');
                              }
                              Navigator.pop(ctx);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                c.formKey.currentState?.validate();
                              });
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
            );
          },
        );
      },
    );
  }

  Widget _label(String text, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 4, top: 10),
    child: Row(
      children: [
        Text(text),
        if (required) const Text(" *", style: TextStyle(color: Colors.red)),
      ],
    ),
  );

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
}