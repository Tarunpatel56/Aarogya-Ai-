package com.example.aarogya

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.YuvImage
import android.os.SystemClock
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class PoseLandmarkerManager(
    private val context: Context,
    private val onResults: ((Map<String, Any>) -> Unit)? = null,
    private val onError: ((String) -> Unit)? = null
) {
    private var poseLandmarker: PoseLandmarker? = null
    private var activeDelegate: String = "CPU"
    private var runningMode: RunningMode = RunningMode.IMAGE
    private val isProcessing = AtomicBoolean(false)
    private val backgroundExecutor = Executors.newSingleThreadExecutor()

    companion object {
        const val MODEL_PATH = "pose_landmarker_lite.task"
        
        val LANDMARK_NAMES = arrayOf(
            "nose", "left_eye_inner", "left_eye", "left_eye_outer",
            "right_eye_inner", "right_eye", "right_eye_outer",
            "left_ear", "right_ear", "mouth_left", "mouth_right",
            "left_shoulder", "right_shoulder", "left_elbow", "right_elbow",
            "left_wrist", "right_wrist", "left_pinky", "right_pinky",
            "left_index", "right_index", "left_thumb", "right_thumb",
            "left_hip", "right_hip", "left_knee", "right_knee",
            "left_ankle", "right_ankle", "left_heel", "right_heel",
            "left_foot_index", "right_foot_index"
        )
    }

    private var lastInitErrorMessage: String? = null

    /**
     * Initializes PoseLandmarker with GPU delegate and automatic CPU fallback
     */
    fun setupPoseLandmarker(preferGpu: Boolean = true, minPoseDetectionConfidence: Float = 0.5f): Map<String, Any> {
        close()
        lastInitErrorMessage = null

        val delegateToTry = if (preferGpu) Delegate.GPU else Delegate.CPU
        val success = tryInit(delegateToTry, minPoseDetectionConfidence)

        if (!success && preferGpu) {
            // Automatic graceful fallback to CPU
            android.util.Log.w("MediaPipePose", "GPU delegate failed ($lastInitErrorMessage), falling back to CPU")
            val cpuSuccess = tryInit(Delegate.CPU, minPoseDetectionConfidence)
            if (!cpuSuccess) {
                return mapOf(
                    "status" to "error",
                    "message" to (lastInitErrorMessage ?: "Failed to initialize MediaPipe Pose Landmarker Lite on both GPU and CPU delegates.")
                )
            }
        } else if (!success) {
            return mapOf(
                "status" to "error",
                "message" to (lastInitErrorMessage ?: "Failed to initialize MediaPipe Pose Landmarker Lite.")
            )
        }

        return mapOf(
            "status" to "success",
            "delegate" to activeDelegate,
            "model" to MODEL_PATH,
            "landmarksCount" to 33
        )
    }

    private fun tryInit(delegate: Delegate, minConfidence: Float): Boolean {
        return try {
            val baseOptionsBuilder = BaseOptions.builder()
                .setModelAssetPath(MODEL_PATH)
                .setDelegate(delegate)

            val optionsBuilder = PoseLandmarker.PoseLandmarkerOptions.builder()
                .setBaseOptions(baseOptionsBuilder.build())
                .setMinPoseDetectionConfidence(minConfidence)
                .setMinPosePresenceConfidence(minConfidence)
                .setMinTrackingConfidence(minConfidence)
                .setRunningMode(RunningMode.IMAGE)

            poseLandmarker = PoseLandmarker.createFromOptions(context, optionsBuilder.build())
            activeDelegate = if (delegate == Delegate.GPU) "GPU" else "CPU"
            true
        } catch (t: Throwable) {
            lastInitErrorMessage = "${t.javaClass.simpleName}: ${t.message}"
            android.util.Log.e("MediaPipePose", "tryInit failed for delegate $delegate: $lastInitErrorMessage", t)
            poseLandmarker = null
            false
        }
    }

    /**
     * Detects 33 body landmarks from raw JPEG / PNG image bytes
     */
    fun detectFromImageBytes(
        imageBytes: ByteArray,
        rotationDegrees: Int = 0
    ): Map<String, Any> {
        val landmarker = poseLandmarker ?: return mapOf(
            "status" to "error",
            "message" to "Pose Landmarker is not initialized"
        )

        val startTime = SystemClock.uptimeMillis()
        var bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size) ?: return mapOf(
            "status" to "error",
            "message" to "Failed to decode frame into bitmap"
        )

        // Handle camera sensor rotation if necessary
        if (rotationDegrees != 0) {
            val matrix = Matrix().apply { postRotate(rotationDegrees.toFloat()) }
            val rotatedBitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
            if (rotatedBitmap != bitmap) {
                bitmap.recycle()
                bitmap = rotatedBitmap
            }
        }

        val mpImage = BitmapImageBuilder(bitmap).build()
        val result = landmarker.detect(mpImage)
        val inferenceTime = SystemClock.uptimeMillis() - startTime
        bitmap.recycle()

        return formatPoseResult(result, inferenceTime)
    }

    /**
     * Processes live camera frame bytes (RGBA, NV21, Y-plane, or JPEG) with frame-dropping guard
     */
    fun detectFromRgbaBuffer(
        rgbaBytes: ByteArray,
        width: Int,
        height: Int,
        rotationDegrees: Int = 0
    ): Map<String, Any> {
        val landmarker = poseLandmarker ?: return mapOf(
            "status" to "error",
            "message" to "Pose Landmarker is not initialized"
        )

        // Prevent queue backlog: if last frame is still processing, drop frame immediately
        if (!isProcessing.compareAndSet(false, true)) {
            return mapOf(
                "status" to "dropped",
                "message" to "Inference engine busy; frame dropped to maintain sub-30ms latency"
            )
        }

        try {
            val startTime = SystemClock.uptimeMillis()
            var bitmap: Bitmap? = null

            // 1. Check if compressed JPEG
            if (rgbaBytes.size >= 2 && rgbaBytes[0] == 0xFF.toByte() && rgbaBytes[1] == 0xD8.toByte()) {
                bitmap = BitmapFactory.decodeByteArray(rgbaBytes, 0, rgbaBytes.size)
            }
            // 2. Check if RGBA_8888 buffer (width * height * 4)
            else if (rgbaBytes.size == width * height * 4) {
                bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                val buffer = ByteBuffer.wrap(rgbaBytes)
                bitmap.copyPixelsFromBuffer(buffer)
            }
            // 3. Check if NV21 buffer (width * height * 3 / 2)
            else if (rgbaBytes.size == (width * height * 3) / 2) {
                val yuvImage = YuvImage(rgbaBytes, ImageFormat.NV21, width, height, null)
                val out = ByteArrayOutputStream()
                yuvImage.compressToJpeg(Rect(0, 0, width, height), 85, out)
                val jpegBytes = out.toByteArray()
                bitmap = BitmapFactory.decodeByteArray(jpegBytes, 0, jpegBytes.size)
            }
            // 4. Check if single Y luminance plane (width * height)
            else if (rgbaBytes.size >= width * height) {
                val pixels = IntArray(width * height)
                for (i in 0 until (width * height)) {
                    val y = rgbaBytes[i].toInt() and 0xFF
                    pixels[i] = -0x1000000 or (y shl 16) or (y shl 8) or y
                }
                bitmap = Bitmap.createBitmap(pixels, width, height, Bitmap.Config.ARGB_8888)
            }
            // 5. Fallback decode
            else {
                bitmap = BitmapFactory.decodeByteArray(rgbaBytes, 0, rgbaBytes.size)
            }

            if (bitmap == null) {
                return mapOf(
                    "status" to "error",
                    "message" to "Failed to decode camera frame into bitmap (size=${rgbaBytes.size}, w=$width, h=$height)"
                )
            }

            if (rotationDegrees != 0) {
                val matrix = Matrix().apply { postRotate(rotationDegrees.toFloat()) }
                val rotated = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
                if (rotated != bitmap) {
                    bitmap.recycle()
                    bitmap = rotated
                }
            }

            val mpImage = BitmapImageBuilder(bitmap).build()
            val result = landmarker.detect(mpImage)
            val inferenceTime = SystemClock.uptimeMillis() - startTime
            bitmap.recycle()

            return formatPoseResult(result, inferenceTime)
        } catch (e: Exception) {
            return mapOf(
                "status" to "error",
                "message" to "Frame inference exception: ${e.message}"
            )
        } finally {
            isProcessing.set(false)
        }
    }

    private fun formatPoseResult(result: PoseLandmarkerResult, inferenceTimeMs: Long): Map<String, Any> {
        val landmarkList = mutableListOf<Map<String, Any>>()
        val allLandmarks = result.landmarks()

        if (allLandmarks.isNotEmpty() && allLandmarks[0].isNotEmpty()) {
            val firstPose = allLandmarks[0]
            for (i in firstPose.indices) {
                val lm = firstPose[i]
                val name = if (i < LANDMARK_NAMES.size) LANDMARK_NAMES[i] else "landmark_$i"
                val visibility = if (lm.visibility().isPresent) lm.visibility().get() else 1.0f
                val presence = if (lm.presence().isPresent) lm.presence().get() else 1.0f

                landmarkList.add(
                    mapOf(
                        "index" to i,
                        "name" to name,
                        "x" to lm.x(),
                        "y" to lm.y(),
                        "z" to lm.z(),
                        "visibility" to visibility,
                        "presence" to presence
                    )
                )
            }
        }

        return mapOf(
            "status" to "success",
            "landmarks" to landmarkList,
            "landmarksCount" to landmarkList.size,
            "detected" to landmarkList.isNotEmpty(),
            "inferenceTimeMs" to inferenceTimeMs,
            "delegate" to activeDelegate
        )
    }

    fun close() {
        poseLandmarker?.close()
        poseLandmarker = null
    }
}

