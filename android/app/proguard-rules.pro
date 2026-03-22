# TensorFlow Lite GPU Delegate
-keep class org.tensorflow.lite.gpu.** { *; }
-keep interface org.tensorflow.lite.gpu.** { *; }

# TensorFlow Lite Core
-keep class org.tensorflow.lite.** { *; }
-keep interface org.tensorflow.lite.** { *; }

# Keep all native methods from TFLite
-keepclasseswithmembernames class * {
    native <methods>;
}

# TensorFlow Lite C++ symbols
-keep class org.tensorflow.lite.acceleration.** { *; }

# Don't obfuscate TensorFlow Lite classes
-dontobfuscate
