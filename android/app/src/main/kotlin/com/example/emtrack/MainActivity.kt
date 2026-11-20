package com.example.emtrack

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import java.security.MessageDigest
import java.security.Security

class MainActivity : FlutterActivity() {

    private val SECURITY_CHANNEL = "com.example.emtrack/security"

    override fun onCreate(savedInstanceState: Bundle?) {
        // Android 12+ native splash — logo turant dikhta hai, koi blank screen nahi
        installSplashScreen()

        try {
            Security.insertProviderAt(
                Class.forName("com.android.org.conscrypt.OpenSSLProvider")
                    .getDeclaredConstructor()
                    .newInstance() as java.security.Provider,
                1
            )
        } catch (_: Exception) {
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSignatureFingerprint" -> {
                        try {
                            result.success(getSignatureFingerprint())
                        } catch (e: Exception) {
                            result.error("SIGNATURE_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun getSignatureFingerprint(): String {
        val pm = packageManager
        val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val info = pm.getPackageInfo(
                packageName,
                PackageManager.GET_SIGNING_CERTIFICATES
            )
            info.signingInfo?.apkContentsSigners ?: emptyArray()
        } else {
            val info = pm.getPackageInfo(
                packageName,
                PackageManager.GET_SIGNATURES
            )
            @Suppress("DEPRECATION")
            info.signatures ?: emptyArray()
        }

        if (signatures.isEmpty()) return ""

        val certBytes = signatures[0].toByteArray()
        val digest = MessageDigest.getInstance("SHA-256")
        val hashBytes = digest.digest(certBytes)

        return hashBytes.joinToString("") { "%02X".format(it) }
    }
}
