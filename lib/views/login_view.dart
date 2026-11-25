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
    // User ne type karna shuru kar diya ho to overwrite mat karo
    // (setState nahi, taaki keyboard/focus disturb na ho).
    if (creds != null &&
        mounted &&
        _userCtrl.text.isEmpty &&
        _passCtrl.text.isEmpty) {
      _userCtrl.text = creds['username'] ?? '';
      _passCtrl.text = creds['password'] ?? '';
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
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Builder(
            builder: (context) {
              // Keyboard khula ho to logo apne aap chhota ho jata hai (Flexible +
              // FittedBox), footer hide hota hai. Koi scroll nahi, sab kuch
              // screen par fit.
              final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: keyboardOpen ? 6 : 12,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top Header / Logo
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: keyboardOpen ? 4 : 10,
                          bottom: keyboardOpen ? 4 : 15,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.topCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Image(image: AssetImage("assets/images/logo.png")),
                              SizedBox(height: 12),
                              Image(
                                image: AssetImage("assets/images/logo-emtrack.png"),
                                width: 140,
                              ),
                              SizedBox(height: 4),
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
                    ),

                    // Login Card
                    Container(
                      key: const ValueKey('login_card'),
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(vertical: keyboardOpen ? 6 : 12),
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

                    // Footer
                    keyboardOpen ? const SizedBox.shrink() : Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Tire inspections made easy",
                            style: TextStyle(color: AppColors.textWhite),
                          ),
                          const SizedBox(height: 10),
                          const AnimatedFooterTexts(),
                          const SizedBox(height: 14),
                          Text(
                            "© ${DateTime.now().year} The Yokohama Rubber Co. Ltd.",
                            style: const TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
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

class _AnimatedFooterTextsState extends State<AnimatedFooterTexts>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim1;
  late Animation<double> _anim2;
  late Animation<double> _anim3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _anim1 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );
    _anim2 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
    );
    _anim3 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FadeTransition(
            opacity: _anim1,
            child: const _BottomText("Inspect."),
          ),
          const SizedBox(width: 16),
          FadeTransition(
            opacity: _anim2,
            child: const _BottomText("Update."),
          ),
          const SizedBox(width: 16),
          FadeTransition(
            opacity: _anim3,
            child: const _BottomText("Done."),
          ),
        ],
      ),
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