import 'package:emtrack/edit_tyre/edit_tyre_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../l10n/app_localizations.dart';

class Step2View extends StatefulWidget {
  const Step2View({super.key});

  @override
  State<Step2View> createState() => _Step2ViewState();
}

class _Step2ViewState extends State<Step2View> {
  final EditTyreController c = Get.find<EditTyreController>();

  static InputDecoration _dec({String? hint, Widget? prefix, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefix,
      suffixIcon: suffix,
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 2),
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
            Text(t.description, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Text(t.manufacture),
            const Text(" *", style: TextStyle(color: Colors.red)),
          ],
        ),
        _searchDropdownDialog(
          hintText: t.manufacture,
          controller: c.manufacturerId,
          listGetter: () => c.manufacturerList.toList(),
          context: context,
          selectedId: c.selectedManufacturerId,
          idListGetter: () => c.manufacturerIdList.toList(),
          t: t, // Pass localization
          onChanged: (id, name) {
            c.filterTireSizesByManufacturer(id);
            c.sizeId.clear();
            c.selectedSizeId.value = 0;
            c.typeId.clear();
            c.selectedTypeId.value = 0;
            c.typeList.clear();
            c.typeIdList.clear();
          },
        ),

        Row(
          children: [
            Text(t.tireSize),
            const Text(" *", style: TextStyle(color: Colors.red)),
          ],
        ),
        _searchDropdownDialog(
          hintText: t.tireSize,
          controller: c.sizeId,
          listGetter: () => c.tireSizeList.toList(),
          context: context,
          selectedId: c.selectedSizeId,
          idListGetter: () => c.tireSizeIdList.toList(),
          t: t,
          onChanged: (id, name) async {
            await c.getTireTypes(id);
            c.typeId.clear();
            c.selectedTypeId.value = 0;
          },
        ),

        Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Text(c.ratingLabel.value)]),
            c.showStarRating.value
                ? starRatingField(context, t)
                : _plyRatingDropdown(context, t),
            const SizedBox(height: 8),
          ],
        )),
        const SizedBox(height: 14),

        Row(
          children: [
            Text(t.vehicleType),
            const Text(" *", style: TextStyle(color: Colors.red)),
          ],
        ),
        _searchDropdownDialog(
          hintText: t.vehicleType,
          controller: c.typeId,
          listGetter: () => c.typeList.toList(),
          context: context,
          selectedId: c.selectedTypeId,
          idListGetter: () => c.typeIdList.toList(),
          t: t,
        ),

        Row(children: [Text(t.indCode)]),
        _searchDropdownDialog(
          hintText: t.indCode,
          controller: c.indCodeId,
          listGetter: () => c.indCodeList.toList(),
          context: context,
          selectedId: c.selectedIndCodeId,
          idListGetter: () => c.indCodeIdList.toList(),
          t: t,
        ),

        Row(children: [Text(t.compound)]),
        _searchDropdownDialog(
          hintText: t.compound,
          controller: c.compoundId,
          listGetter: () => c.compoundList.toList(),
          context: context,
          selectedId: c.selectedCompoundId,
          idListGetter: () => c.compoundIdList.toList(),
          t: t,
        ),

        Row(children: [Text(t.loadRating)]),
        _searchDropdownDialog(
          hintText: t.loadRating,
          controller: c.loadRatingId,
          listGetter: () => c.loadRatingList.toList(),
          context: context,
          selectedId: c.selectedLoadRatingId,
          idListGetter: () => c.loadRatingIdList.toList(),
          t: t,
        ),

        Row(children: [Text(t.speedRating)]),
        _searchDropdownDialog(
          hintText: t.speedRating,
          controller: c.speedRatingId,
          listGetter: () => c.speedRatingList.toList(),
          context: context,
          selectedId: c.selectedSpeedRatingId,
          idListGetter: () => c.speedRatingIdList.toList(),
          t: t,
        ),

        const SizedBox(height: 24),
        _primaryBtn(t.nextBtn, () {
          if (c.formKey.currentState!.validate()) c.nextStep();
        }),
        const SizedBox(height: 12),
        _outlineBtn(t.previousBtn, c.previousStep),
        const SizedBox(height: 12),
        _outlineBtn(t.cancelBtn, c.cancelDialog),
      ],
    );
  }

  Widget _searchDropdownDialog({
    required String hintText,
    required TextEditingController controller,
    required List<String> Function() listGetter,
    required BuildContext context,
    required AppLocalizations t,
    RxInt? selectedId,
    List<int> Function()? idListGetter,
    void Function(int id, String name)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GetBuilder<EditTyreController>(
        builder: (c) {
          return TextFormField(
            controller: controller,
            readOnly: true,
            decoration: _dec(
              hint: hintText,
              prefix: const Icon(Icons.search),
            ),
            onTap: () async {
              c.checkStarEnable();
              final list = listGetter();
              final idList = idListGetter?.call() ?? [];

              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) {
                  List<String> filteredList = List.from(list);
                  final searchController = TextEditingController();
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
                                decoration: _dec(
                                  hint: "${t.searchHint}...",
                                  prefix: const Icon(Icons.search),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    filteredList = value.isEmpty
                                        ? List.from(list)
                                        : list
                                        .where(
                                          (item) => item
                                          .toLowerCase()
                                          .contains(
                                          value.toLowerCase()),
                                    )
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
                                separatorBuilder: (_, _) =>
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
                                        ? const Icon(
                                      Icons.check,
                                      color: Colors.red,
                                    )
                                        : null,
                                    onTap: () => setState(
                                          () => selectedValue = item,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Container(
                              height: 56,
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
                                        if (selectedValue != null) {
                                          final index =
                                          list.indexOf(selectedValue!);
                                          controller.text = selectedValue!;
                                          if (selectedId != null &&
                                              index >= 0 &&
                                              index < idList.length) {
                                            selectedId.value = idList[index];
                                            onChanged?.call(
                                              idList[index],
                                              selectedValue!,
                                            );
                                          }
                                        }
                                        Navigator.pop(context);
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

  Widget _plyRatingDropdown(BuildContext context, AppLocalizations t) {
    return _searchDropdownDialog(
      hintText: "Select Ply Rating",
      controller: c.plyRatingId,
      listGetter: () => c.plyRatingList.toList(),
      context: context,
      selectedId: c.selectedPlyRatingId,
      idListGetter: () => c.plyRatingIdList.toList(),
      t: t,
    );
  }

  Widget starRatingField(BuildContext context, AppLocalizations t) {
    return Obx(() {
      final currentVal = c.starRating.value;
      final List<String> starOptions = [
        "**",
        "***",
        "****",
        "*/**",
        "***/****",
      ];
      String displayText = (currentVal > 0 && currentVal <= 5)
          ? starOptions[currentVal - 1]
          : t.selectItem;

      return InkWell(
        onTap: () => _starDialog(context, t),
        child: InputDecorator(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.black),
            border: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
          ),
          child: Text(
            displayText,
            style: TextStyle(
              color: currentVal == 0 ? Colors.grey : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      );
    });
  }

  void _starDialog(BuildContext context, AppLocalizations t) {
    final List<String> starOptions = ["**", "***", "****", "*/**", "***/****"];
    int tempIndex = (c.starRating.value > 0 ? c.starRating.value - 1 : -1);

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
                    itemCount: starOptions.length,
                    itemBuilder: (context, index) {
                      final item = starOptions[index];
                      final isSelected = tempIndex == index;
                      return InkWell(
                        onTap: () =>
                            setDialogState(() => tempIndex = index),
                        child: Container(
                          color: isSelected
                              ? Colors.grey.withValues(alpha: 0.15)
                              : Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 18,
                              color: isSelected ? Colors.red : Colors.black,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
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
                        t.cancel,
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

  Widget _primaryBtn(String text, VoidCallback onTap) => SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: Colors.grey),
      ),
      child: Text(
        text,
        style:
        const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ),
    ),
  );
}