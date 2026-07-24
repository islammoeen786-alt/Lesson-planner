-keep class com.smartlessonplanner.** { *; }
-keep class io.flutter.** { *; }
-keep class com.google.firebase.** { *; }
-keep class org.json.** { *; }

# Play Core split compat (referenced by Flutter PlayStoreDeferredComponentManager)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

-dontwarn com.google.auto.value.**
-dontwarn com.google.errorprone.**
