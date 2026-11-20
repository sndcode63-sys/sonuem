import 'package:emtrack/color/app_color.dart';
import 'package:emtrack/routes/app_pages.dart';
import 'package:emtrack/views/sign_up_view.dart';
import 'package:emtrack/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../utils/validators.dart';
import '../utils/app_snackbar.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final auth = Get.put(AuthController());

  @override
  void initState() {
    super.initState();
    _prefillRememberedCredentials();
  }

  Future<void> _prefillRememberedCredentials() async {
    final creds = await auth.getRememberedCredentials();
    if (creds != null && mounted) {
      setState(() {
        _userCtrl.text = creds['username'] ?? '';
        _passCtrl.text = creds['password'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  height: isKeyboardOpen ? 55 : 130,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(height: 10),
                        Image(image: AssetImage("assets/images/logo.png")),
                        SizedBox(height: 15),
                        Image(
                          image: AssetImage("assets/images/logo-emtrack.png"),
                          width: 140,
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Mobile",
                          style: TextStyle(
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Flexible(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Welcome",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // USERNAME
                            AppTextField(
                              controller: _userCtrl,
                              hintText: "Username",
                              validator: Validators.validateUsername,
                              textCapitalization: TextCapitalization.none,
                              autocorrect: false,
                              enableSuggestions: false,
                            ),
                            const SizedBox(height: 15),

                            // PASSWORD
                            Obx(
                                  () => AppTextField(
                                controller: _passCtrl,
                                hintText: "Password",
                                obscureText: !auth.showPassword.value,
                                validator: Validators.validatePassword,
                                textCapitalization: TextCapitalization.none,
                                autocorrect: false,
                                enableSuggestions: false,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    auth.showPassword.value
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () => auth.showPassword.toggle(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Password reset
                            Align(
                              alignment: Alignment.center,
                              child: InkWell(
                                onTap: () => Get.toNamed(AppPages.PASSWORD_RESET),
                                child: const Text(
                                  "Password Reset",
                                  style: TextStyle(
                                    color: AppColors.textBlack,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // LOGIN BUTTON
                            Obx(
                                  () => AppPrimaryButton(
                                label: "Login",
                                isLoading: auth.isLoading.value,
                                onTap: () async {
                                  final user = _userCtrl.text.trim();
                                  final pass = _passCtrl.text.trim();

                                  if (user.isEmpty) {
                                    AppSnackbar.error("Please enter username", title: "Validation Error");
                                    _formKey.currentState?.validate();
                                    return;
                                  }
                                  if (pass.isEmpty) {
                                    AppSnackbar.error("Please enter password", title: "Validation Error");
                                    _formKey.currentState?.validate();
                                    return;
                                  }
                                  if (pass.length < 6) {
                                    AppSnackbar.error("Password must be at least 6 characters", title: "Validation Error");
                                    _formKey.currentState?.validate();
                                    return;
                                  }

                                  if (!_formKey.currentState!.validate()) return;
                                  await auth.login(user, pass);
                                },
                              ),
                            ),
                            const SizedBox(height: 12),

                            // SIGN UP BUTTON
                            AppOutlineButton(
                              label: "Sign Up",
                              onTap: () => Get.to(() => const SignUpWebView()),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isKeyboardOpen
                      ? const SizedBox(height: 0, key: ValueKey("hidden-footer"))
                      : Column(
                    key: const ValueKey("visible-footer"),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Tire inspections made easy",
                        style: TextStyle(color: AppColors.textWhite),
                      ),
                      const SizedBox(height: 12),
                      const AnimatedFooterTexts(),
                      const SizedBox(height: 20),
                      Text(
                        "© ${DateTime.now().year} The Yokohama Rubber Co. Ltd.",
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedFooterTexts extends StatefulWidget {
  const AnimatedFooterTexts({super.key});

  @override
  State<AnimatedFooterTexts> createState() => _AnimatedFooterTextsState();
}

class _AnimatedFooterTextsState extends State<AnimatedFooterTexts> {
  double op1 = 0, op2 = 0, op3 = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => op1 = 1);
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => op2 = 1);
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => op3 = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: op1,
          child: const _BottomText("Inspect."),
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: op2,
          child: const _BottomText("Update."),
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: op3,
          child: const _BottomText("Done."),
        ),
      ],
    );
  }
}

class _BottomText extends StatelessWidget {
  final String text;
  const _BottomText(this.text);

  @override
  Widget build(BuildContext context) {
    final word = text.replaceAll(".", "");
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: word,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const TextSpan(
            text: ".",
            style: TextStyle(
              color: Colors.yellow,
              fontWeight: FontWeight.bold,
              fontSize: 40,
            ),
          ),
        ],
      ),
    );
  }
}