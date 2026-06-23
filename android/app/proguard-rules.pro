# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in /usr/local/Cellar/android-sdk/24.3.3/tools/proguard/proguard-android.txt
# You can edit the include path and order by changing the proguardFiles
# directive in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Add any project specific keep options here:

# ViroReact JNI & Native Methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep ViroReact SDK classes
-keep class com.viro.core.** { *; }
-keep interface com.viro.core.** { *; }
-keep class com.viro.renderer.** { *; }
-keep class com.viromedia.bridge.** { *; }
-keep class com.viromedia.bridge.component.** { *; }

# Ignore missing Google VR logging and protobuf classes (internal to prebuilt SDKs)
-dontwarn com.google.common.logging.**
-dontwarn com.google.protobuf.**
-dontwarn logs.proto.wireless.performance.mobile.**


