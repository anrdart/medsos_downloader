# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# OkHttp / Okio (used by Dio's native http stack on some plugins)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# WebView JS interfaces
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# flutter_secure_storage (uses AndroidKeyStore reflection)
-keep class androidx.security.crypto.** { *; }

# Keep annotations & native methods
-keepattributes *Annotation*
-keepclasseswithmembernames class * {
    native <methods>;
}

# Play Core (Flutter deferred components / split install) — referenced but optional
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
