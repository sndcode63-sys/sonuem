# EMTrack ProGuard Rules
# VAPT Fix: Code obfuscation to reduce reverse engineering risk

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep application entry point
-keep class com.example.emtrack.** { *; }

# Hive
-keep class * extends com.google.flatbuffers.Table { *; }
-keep class * implements com.google.flatbuffers.** { *; }

# Remove all debug/stack trace logs in release
-assumenosideeffects class java.lang.Throwable {
    public void printStackTrace();
}
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
