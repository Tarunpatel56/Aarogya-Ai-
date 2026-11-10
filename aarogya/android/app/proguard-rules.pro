# Proguard / R8 rules for MediaPipe Tasks Vision & Aarogya

# 1. MediaPipe Tasks Vision & Core JNI
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**

# 2. Aarogya native Kotlin classes
-keep class com.example.aarogya.** { *; }
-dontwarn com.example.aarogya.**

# 3. Preserve all JNI native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# 4. TensorFlow Lite & FlatBuffers
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**
-keep class com.google.flatbuffers.** { *; }
-dontwarn com.google.flatbuffers.**

# 5. Image Processing and Android CameraX
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

