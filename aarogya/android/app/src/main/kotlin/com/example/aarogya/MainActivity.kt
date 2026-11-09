package com.example.aarogya

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val POSE_CHANNEL = "io.aarogya.mediapipe/pose"
    private var poseManager: PoseLandmarkerManager? = null
    private val backgroundExecutor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        poseManager = PoseLandmarkerManager(context = applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, POSE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initPoseLandmarker" -> {
                    val preferGpu = call.argument<Boolean>("preferGpu") ?: true
                    val minConfidence = (call.argument<Double>("minConfidence") ?: 0.5).toFloat()

                    backgroundExecutor.execute {
                        val initResult = poseManager?.setupPoseLandmarker(preferGpu, minConfidence) ?: mapOf(
                            "status" to "error",
                            "message" to "PoseLandmarkerManager is not initialized"
                        )
                        runOnUiThread {
                            result.success(initResult)
                        }
                    }
                }

                "detectPoseFromImageBytes" -> {
                    val bytes = call.argument<ByteArray>("imageBytes")
                    val rotation = call.argument<Int>("rotation") ?: 0

                    if (bytes == null || bytes.isEmpty()) {
                        result.error("INVALID_ARGUMENT", "imageBytes cannot be null or empty", null)
                        return@setMethodCallHandler
                    }

                    backgroundExecutor.execute {
                        val detectionResult = poseManager?.detectFromImageBytes(bytes, rotation) ?: mapOf(
                            "status" to "error",
                            "message" to "PoseLandmarkerManager is not initialized"
                        )
                        runOnUiThread {
                            result.success(detectionResult)
                        }
                    }
                }

                "detectPoseFromRgbaBuffer" -> {
                    val bytes = call.argument<ByteArray>("rgbaBytes")
                    val width = call.argument<Int>("width") ?: 0
                    val height = call.argument<Int>("height") ?: 0
                    val rotation = call.argument<Int>("rotation") ?: 0

                    if (bytes == null || width <= 0 || height <= 0) {
                        result.error("INVALID_ARGUMENT", "Invalid buffer dimensions or null bytes", null)
                        return@setMethodCallHandler
                    }

                    backgroundExecutor.execute {
                        val detectionResult = poseManager?.detectFromRgbaBuffer(bytes, width, height, rotation) ?: mapOf(
                            "status" to "error",
                            "message" to "PoseLandmarkerManager is not initialized"
                        )
                        runOnUiThread {
                            result.success(detectionResult)
                        }
                    }
                }

                "closePoseLandmarker" -> {
                    poseManager?.close()
                    result.success(mapOf("status" to "closed"))
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        poseManager?.close()
        backgroundExecutor.shutdown()
        super.onDestroy()
    }
}
