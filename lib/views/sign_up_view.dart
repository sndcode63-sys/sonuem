import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

class SignUpWebView extends StatefulWidget {
  const SignUpWebView({super.key});

  @override
  State<SignUpWebView> createState() => _SignUpWebViewState();
}

class _SignUpWebViewState extends State<SignUpWebView> {
  bool isLoading = true;

  void _stopLoading() {
    if (mounted && isLoading) setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    debugPrint('🟢 [SignUp] initState called');
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    debugPrint('🟢 [SignUp] Full screen mode enabled');

    Future.delayed(const Duration(seconds: 10), () {
      debugPrint('⚠️ [SignUp] 10s timeout reached — forcing loading stop');
      _stopLoading();
    });
  }

  @override
  void dispose() {
    debugPrint('🔴 [SignUp] dispose called — restoring system UI');
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔵 [SignUp] build called');
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sign Up',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back, color: Colors.black),
          onPressed: () {
            Get.back();
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri('https://www.yokohamaotr.com/emtrack'),
              ),
              initialSettings: InAppWebViewSettings(
                useShouldOverrideUrlLoading: true,
                mediaPlaybackRequiresUserGesture: false,
                javaScriptEnabled: true,
                allowsInlineMediaPlayback: true,
                transparentBackground: false,
              ),
              onWebViewCreated: (controller) {},
              onLoadStart: (controller, url) {},
              onLoadStop: (controller, url) {
                _stopLoading();
              },
              onReceivedError: (controller, request, error) {
                _stopLoading();
              },
              onReceivedHttpError: (controller, request, response) {
                _stopLoading();
              },
              onConsoleMessage: (controller, consoleMessage) {},
              onProgressChanged: (controller, progress) {},
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                return NavigationActionPolicy.ALLOW;
              },
              onPermissionRequest: (controller, request) async {
                return PermissionResponse(
                  resources: request.resources,
                  action: PermissionResponseAction.GRANT,
                );
              },
            ),
            if (isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
