
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../l10n/app_localizations.dart';
import '../utils/approval_localizations.dart';

class IWAddVehicleScreen extends StatefulWidget {
  const IWAddVehicleScreen({super.key});

  @override
  State<IWAddVehicleScreen> createState() => _IWAddVehicleScreenState();
}

class _IWAddVehicleScreenState extends State<IWAddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNoCtrl = TextEditingController();
  final _vehicleTypeCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _axleConfigCtrl = TextEditingController();
  final _tireSizeCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _kmCtrl = TextEditingController();
  final _commentsCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _vehicleNoCtrl.dispose();
    _vehicleTypeCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _axleConfigCtrl.dispose();
    _tireSizeCtrl.dispose();
    _hoursCtrl.dispose();
    _kmCtrl.dispose();
    _commentsCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final a = ApprovalLocalizations.of(context);
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isSubmitting = false);
    Get.back();
    Get.snackbar(
      a.success,
      a.vehicleAddedSuccessfully(_vehicleNoCtrl.text),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade900,
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = ApprovalLocalizations.of(context);
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: const BackButton(color: Colors.white),
        title: Text(
          a.addVehicle,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(a.vehicleNumberRequired),
              _field(_vehicleNoCtrl, 'e.g. #4032', required: true, requiredMsg: a.required),

              _label(a.vehicleType),
              _field(_vehicleTypeCtrl, 'e.g. Truck, Trailer'),

              _label(a.make),
              _field(_makeCtrl, 'e.g. Tata, Volvo'),

              _label(a.model),
              _field(_modelCtrl, 'e.g. Prima, FH'),

              _label(a.axleConfig),
              _field(_axleConfigCtrl, 'e.g. 6x4, 4x2'),

              _label(a.tireSize),
              _field(_tireSizeCtrl, 'e.g. 295/80R22.5'),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(t.hours),
                        _field(
                          _hoursCtrl,
                          '0',
                          type: TextInputType.number,
                          required: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(a.kilometers),
                        _field(
                          _kmCtrl,
                          '0',
                          type: TextInputType.number,
                          required: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              _label(a.comments),
              TextFormField(
                controller: _commentsCtrl,
                maxLength: 200,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: a.commentsHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    a.addVehicle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _field(
      TextEditingController ctrl,
      String hint, {
        bool required = false,
        String? requiredMsg,
        TextInputType type = TextInputType.text,
      }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      validator: required
          ? (v) => (v == null || v.isEmpty) ? (requiredMsg ?? 'Required') : null
          : null,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}
