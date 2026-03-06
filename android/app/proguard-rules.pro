# android/app/proguard-rules.pro

# TFLite
-keep class org.tensorflow.** { *; }
-keep class com.google.firebase.** { *; }

# Flutter
-keep class io.flutter.** { *; }

# Image Picker / Cropper
-keep class com.yalantis.ucrop.** { *; }
