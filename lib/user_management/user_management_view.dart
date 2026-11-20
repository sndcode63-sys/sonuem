import 'package:emtrack/color/app_color.dart';
import 'package:emtrack/user_management/user_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../l10n/app_localizations.dart';

class UserManagementView extends StatelessWidget {
  const UserManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(UserManagementController());
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          t.createUser,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Obx(() => Column(
              children: [
                _stepHeader(c, t),
                Expanded(child: _stepBody(c, t)),
              ],
            )),
        
            Obx(() {
              if (!c.isLoading.value) return const SizedBox();
              return Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.red),
                        const SizedBox(height: 16),
                        Text(t.creatingUser,
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _stepHeader(UserManagementController c, AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _circle(c, 0, t.loginLabel),
          _circle(c, 1, t.personalLabel),
          _circle(c, 2, t.preferenceLabel),
        ],
      ),
    );
  }

  Widget _circle(UserManagementController c, int step, String title) {
    final isDone    = step < c.currentStep.value;
    final isCurrent = step == c.currentStep.value;

    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isDone
              ? Colors.green
              : isCurrent
              ? Colors.red
              : Colors.grey.shade400,
          child: isDone
              ? const Icon(Icons.check, color: Colors.white)
              : Text(
            "${step + 1}",
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
            isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isDone
                ? Colors.green
                : isCurrent
                ? Colors.red
                : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _stepBody(UserManagementController c, AppLocalizations t) {
    switch (c.currentStep.value) {
      case 0:
        return _loginInfo(c, t);
      case 1:
        return _personalDetail(c, t);
      default:
        return Form(
          key: c.preferenceFormKey,
          child: _preferences(c, t),
        );
    }
  }

  Widget _loginInfo(UserManagementController c, AppLocalizations t) {
    return Form(
      key: c.loginFormKey,
      child: _formWrapper(
        c: c,
        t: t,
        stepIndex: 0,
        onNext: () {
          if (c.loginFormKey.currentState!.validate()) {
            if (c.role.value.isEmpty) {
              Get.snackbar('Error', 'Please select User Role',
                  backgroundColor: Colors.red, colorText: Colors.white);
              return;
            }
            c.next();
          }
        },
        fields: [
          _textField(
            label: t.username,
            controller: c.usernameC,
            validator: (v) {
              if (v == null || v.isEmpty) return "Username required";
              if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]{3,19}$').hasMatch(v)) {
                return "4-20 chars, start with letter";
              }
              return null;
            },
          ),
          _textField(
            label: t.password,
            controller: c.passwordC,
            obscure: true,
            validator: (v) {
              if (v == null || v.isEmpty) return "Password required";
              if (v.length < 6) return "Min 6 characters";
              if (!RegExp(r'[A-Z]').hasMatch(v)) {
                return "At least one uppercase letter required";
              }
              if (!RegExp(r'[0-9]').hasMatch(v)) {
                return "At least one number required";
              }
              if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-\\\/\[\]~`+=;]')
                  .hasMatch(v)) {
                return "At least one special character required";
              }
              return null;
            },
          ),
          _textField(
            label: "Email",
            controller: c.emailC,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return "Email required";
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(v)) {
                return "Invalid email";
              }
              return null;
            },
          ),
          Obx(() => AppDropdownField(
            label: t.userRole,
            items: List<String>.from(c.roles),
            value: c.role,
            isRequired: true,
          )),
        ],
      ),
    );
  }

  Widget _personalDetail(UserManagementController c, AppLocalizations t) {
    final nameRegex = RegExp(r'^[A-Za-z ]{2,}$');
    return Form(
      key: c.personalFormKey,
      child: _formWrapper(
        c: c,
        t: t,
        stepIndex: 1,
        onNext: () {
          if (c.personalFormKey.currentState!.validate()) {
            if (c.country.value.isEmpty) {
              Get.snackbar('Error', 'Please select Country',
                  backgroundColor: Colors.red, colorText: Colors.white);
              return;
            }
            c.next();
          }
        },
        fields: [
          _textField(
            label: t.firstName,
            controller: c.firstNameC,
            focusNode: c.firstNameFocus,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return "First name required";
              if (!nameRegex.hasMatch(v)) return "Only letters allowed";
              return null;
            },
          ),
          _textField(
            label: t.middleName,
            controller: c.middleNameC,
            focusNode: c.middleNameFocus,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return "Middle name required";
              if (!nameRegex.hasMatch(v)) return "Only letters allowed";
              return null;
            },
          ),
          _textField(
            label: t.lastName,
            controller: c.lastNameC,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return "Last name required";
              if (!nameRegex.hasMatch(v)) return "Only letters allowed";
              return null;
            },
          ),
          _textField(
            label: t.phone,
            controller: c.phoneC,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return "Phone required";
              if (!RegExp(r'^[0-9]{7,15}$').hasMatch(v)) {
                return "Invalid phone number";
              }
              return null;
            },
          ),
          Obx(() => AppDropdownField(
            label: t.country,
            items: List<String>.from(c.countries),
            value: c.country,
            isRequired: true,
          )),
        ],
      ),
    );
  }

  Widget _preferences(UserManagementController c, AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Obx(() => AppDropdownField(
                  label: t.language,
                  items: List<String>.from(c.languages),
                  value: c.language,
                  isRequired: true,
                )),

                // ── Measurement ────────────────────────────────────────
                Obx(() => AppDropdownField(
                  label: t.measurement, // ✅ Localized
                  items: List<String>.from(c.measurements),
                  value: c.measurement,
                  isRequired: true,
                )),

                Obx(() => AppDropdownField(
                  label: t.pressureUnit,
                  items: List<String>.from(c.pressureUnits),
                  value: c.pressureUnit,
                  isRequired: true,
                )),

                const SizedBox(height: 20),
                Obx(() => Row(
                  children: [
                    if (c.currentStep.value > 0) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: c.previous,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Colors.red, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(10)),
                            minimumSize:
                            const Size(double.infinity, 48),
                          ),
                          child: Text(t.previous,
                              style: const TextStyle(color: Colors.red)),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Obx(
                        () => ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            disabledBackgroundColor: Colors.red.withAlpha(180),
                            minimumSize:
                            const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(10)),
                          ),
                          onPressed: c.isLoading.value
                              ? null
                              : () {
                                  Get.focusScope?.unfocus();
                                  if (c.language.value.isEmpty) {
                                    Get.snackbar(
                                        'Error', 'Please select Language',
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white);
                                    return;
                                  }
                                  if (c.measurement.value.isEmpty) {
                                    Get.snackbar(
                                        'Error', 'Please select Measurement',
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white);
                                    return;
                                  }
                                  if (c.pressureUnit.value.isEmpty) {
                                    Get.snackbar(
                                        'Error', 'Please select Pressure Unit',
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white);
                                    return;
                                  }
                                  c.submit();
                                },
                          child: c.isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  t.create,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ),
                  ],
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formWrapper({
    required UserManagementController c,
    required AppLocalizations t,
    required int stepIndex,
    required VoidCallback onNext,
    required List<Widget> fields,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          ...fields,
          const SizedBox(height: 20),

          Obx(() => Row(
            children: [
              if (c.currentStep.value > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: c.previous,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text(t.previous,
                        style: const TextStyle(color: Colors.red)),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Get.focusScope?.unfocus();
                    onNext();
                  },
                  child: Text(
                    t.next,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    bool obscure = false,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure,
        keyboardType: keyboardType,
        autofocus: false,
        cursorColor: Colors.red,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
      ),
    );
  }
}


class AppDropdownField extends StatelessWidget {
  final String label;
  final List<String> items;
  final RxString value;
  final void Function(String)? onChanged;
  final bool isRequired;

  const AppDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    this.onChanged,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final touched = false.obs;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Obx(() {
        final isEmpty   = value.value.isEmpty;
        final showError = touched.value && isEmpty;

        return GestureDetector(
          onTap: () {
            touched.value = true;
            _openDialog(label, items, value, onChanged, t);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                        color: Colors.black54, fontSize: 16),
                  ),
                  if (isRequired)
                    const Text(
                      ' *',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                ],
              ),
              errorText: showError ? 'Please select $label' : null,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: showError ? Colors.red : Colors.grey.shade400,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              suffixIcon: const Icon(
                Icons.arrow_drop_down,
                color: Colors.red,
              ),
            ),
            child: Text(
              isEmpty ? "${t.selectPrefix} $label" : value.value,
              style: TextStyle(
                fontSize: 14,
                color: isEmpty ? Colors.grey : Colors.black,
              ),
            ),
          ),
        );
      }),
    );
  }

  static void _openDialog(
      String label,
      List<String> items,
      RxString value,
      void Function(String)? onChanged,
      AppLocalizations t,
      ) {
    final filtered     = <String>[...items].obs;
    final tempSelected = RxString(value.value);
    final searchCtrl   = TextEditingController();

    Get.dialog(
      Scaffold(
        appBar: AppBar(
          title: Text(
            "${t.selectPrefix} $label",
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
                onChanged: (q) {
                  filtered.value = items
                      .where((e) =>
                      e.toLowerCase().contains(q.toLowerCase()))
                      .toList();
                },
              ),
            ),

            Expanded(
              child: Obx(() {
                if (filtered.isEmpty) {
                  return Center(child: Text(t.noDataAvailable));
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    return Obx(() {
                      final isSelected = tempSelected.value == item;
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
                        onTap: () => tempSelected.value = item,
                      );
                    });
                  },
                );
              }),
            ),

            Container(
              height: 56,
              decoration: BoxDecoration(
                border:
                Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: Get.back,
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16)),
                      child: Text(
                        t.cancel,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  ),
                  Container(
                      width: 1, height: 56, color: Colors.grey.shade300),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        if (tempSelected.value.isNotEmpty) {
                          value.value = tempSelected.value;
                          onChanged?.call(tempSelected.value);
                        }
                        Get.back();
                      },
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16)),
                      child: Text(
                        t.okBtn,
                        style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
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
}