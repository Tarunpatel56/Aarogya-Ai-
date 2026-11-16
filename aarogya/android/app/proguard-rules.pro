# Proguard / R8 rules for MediaPipe Tasks Vision & Aarogya

# 1. MediaPipe Tasks Vision, Core JNI & Native Framework
-keep class com.google.mediapipe.** { *; }
-keep interface com.google.mediapipe.** { *; }
-keep enum com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**
-allowaccessmodification

# 1b. Google Common & Flogger logging framework (required for MediaPipe Graph.<clinit>)
-keep class com.google.common.flogger.** { *; }
-dontwarn com.google.common.flogger.**
-keep class com.google.common.base.** { *; }
-dontwarn com.google.common.base.**

# 1c. AndroidX MultiDex
-keep class androidx.multidex.** { *; }
-dontwarn androidx.multidex.**

# 2. Protocol Buffers & Google Serialization
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# 3. Aarogya native Kotlin classes
-keep class com.example.aarogya.** { *; }
-dontwarn com.example.aarogya.**

# 4. Preserve all JNI native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# 5. TensorFlow Lite & FlatBuffers
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**
-keep class com.google.flatbuffers.** { *; }
-dontwarn com.google.flatbuffers.**

# 6. Image Processing and Android CameraX
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
