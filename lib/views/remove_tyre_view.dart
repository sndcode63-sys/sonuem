import 'package:emtrack/controllers/remove_tyre_controller.dart';
import 'package:emtrack/models/masterDataMobileModel/Tire_remove_reason_model.dart';
import 'package:emtrack/models/masterDataMobileModel/tire_desposition_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../l10n/app_localizations.dart';
import '../utils/local_helper.dart';
import '../utils/reusable_dialog.dart';

class RemoveTyreView extends StatelessWidget {
  RemoveTyreView({super.key});

  final controller = Get.put(RemoveTyreController());

  InputDecoration _dec({String? hint, Widget? prefix, Widget? suffix}) {
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

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "${t.remove}  ${LocaleHelper.tyreName(context)}",
          style: const TextStyle(color: Colors.white),
        ),
        leading: const BackButton(color: Colors.white),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child:
             Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Disposition
                Text(t.updateDisposition),
                const SizedBox(height: 6),
                Obx(() {
                  final currentM = controller.model.value;
                  final currentDisp = controller.dispositions.firstWhereOrNull(
                    (d) => d.dispositionId == currentM.dispositionId,
                  );
                  final currentDispText = currentDisp?.dispositionName ?? '';

                  return TextFormField(
                    readOnly: true,
                    // Force rebuild when text changes
                    key: ValueKey(currentDispText),
                    controller: TextEditingController(text: currentDispText),
                    decoration: _dec(
                      hint: t.selectDisposition,
                      suffix: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.red,
                      ),
                    ),
                    onTap: () => _showDispositionDialog(context, t),
                  );
                }),

                const SizedBox(height: 16),

                // 🔹 Removal Reason
                Text(t.removalReason),
                const SizedBox(height: 6),
                Obx(
                  () => TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: controller.selectedReason.value?.reasonName ?? '',
                    ),
                    decoration: _dec(
                      hint:
                          "${t.selectPrefix} ${LocaleHelper.tyreName(context)} ${t.removalReason}",
                      suffix: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.red,
                      ),
                    ),
                    onTap: () => _openReasonDialog(context, t),
                  ),
                ),

                const SizedBox(height: 16),

                // 🔹 Comments
                Text(t.commentsLabel),
                const SizedBox(height: 6),
                TextField(
                  maxLength: 200,
                  maxLines: 3,
                  onChanged: (v) =>
                      controller.model.update((m) => m!.comments = v),
                  decoration: _dec(hint: t.commentsHint),
                ),

                const SizedBox(height: 40),
                Column(
                  children: [
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            disabledBackgroundColor: Colors.red.withAlpha(180),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
  }

  void _openReasonDialog(BuildContext context, AppLocalizations t) {
    final RxList<TireRemovalReason> filteredList = <TireRemovalReason>[
      ...controller.reasons,
    ].obs;
    final TextEditingController searchCtrl = TextEditingController();
    final Rxn<TireRemovalReason> tempSelected = Rxn(
      controller.selectedReason.value,
    );

    Get.dialog(
      Scaffold(
        appBar: AppBar(
          title: Text(
            t.selectRemovalReason,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: searchCtrl,
                cursorColor: Colors.red,
                decoration: InputDecoration(
                  hintText: "${t.searchHint}...",
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
                  filteredList.value = controller.reasons
                      .where(
                        (r) => r.reasonName.toLowerCase().contains(
                          v.toLowerCase(),
                        ),
                      )
                      .toList();
                },
              ),
            ),
            Expanded(
              child: Obx(() {
                if (filteredList.isEmpty) {
                  return Center(child: Text(t.noDataAvailable));
                }
                return ListView.builder(
                  itemCount: filteredList.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (_, index) {
                    final item = filteredList[index];
                    return Obx(() {
                      final isSelected =
                          item.reasonId == tempSelected.value?.reasonId;
                      return ListTile(
                        visualDensity: const VisualDensity(vertical: -2),
                        title: Text(
                          item.reasonName,
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
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        t.cancel,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 50, color: Colors.grey.shade300),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        if (tempSelected.value != null) {
                          controller.selectReason(tempSelected.value!);
                        }
                        Get.back();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        t.okBtn,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
      barrierDismissible: false,
    );
  }

  void _showDispositionDialog(BuildContext context, AppLocalizations t) {
    final list = controller.dispositions;
    TireDisposition? tempSelected = controller.dispositions.firstWhereOrNull(
      (d) => d.dispositionId == controller.model.value.dispositionId,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: EdgeInsets.zero,
            titlePadding: const EdgeInsets.symmetric(vertical: 20),
            title: Text(
              t.selectDisposition,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 350,
              child: Column(
                children: [
                  const Divider(height: 1, thickness: 1),
                  Expanded(
                    child: list.isEmpty
                        ? Center(child: Text(t.noDataAvailable))
                        : ListView.builder(
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final item = list[index];
                              final isSelected =
                                  tempSelected?.dispositionId ==
                                  item.dispositionId;
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.dispositionName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isSelected
                                              ? Colors.red
                                              : Colors.black,
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
                      onPressed: () => Navigator.pop(context),
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
                        if (tempSelected != null) {
                          controller.selectDisposition(tempSelected!);
                        }
                        Navigator.pop(context);
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
    );
  }
}
