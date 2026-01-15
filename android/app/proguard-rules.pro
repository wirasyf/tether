# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep annotations
-keepattributes *Annotation*

# Don't warn about missing classes in dependencies
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn javax.naming.**

# Play Core rules
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
