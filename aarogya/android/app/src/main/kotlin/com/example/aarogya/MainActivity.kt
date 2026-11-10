package com.example.aarogya

import android.os.Bundle
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.location.Location
import android.location.LocationManager
import android.content.pm.PackageManager
import android.Manifest
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

                "getCurrentLocation" -> {
                    try {
                        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
                        var location: Location? = null

                        if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
                            checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                            
                            val providers = locationManager.getProviders(true)
                            for (provider in listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER, LocationManager.PASSIVE_PROVIDER)) {
                                if (providers.contains(provider)) {
                                    val loc = locationManager.getLastKnownLocation(provider)
                                    if (loc != null && (location == null || loc.accuracy < location.accuracy)) {
                                        location = loc
                                    }
                                }
                            }
                        }

                        if (location != null) {
                            result.success(mapOf(
                                "status" to "success",
                                "latitude" to location.latitude,
                                "longitude" to location.longitude,
                                "accuracy" to location.accuracy.toDouble()
                            ))
                        } else {
                            result.success(mapOf(
                                "status" to "unavailable"
                            ))
                        }
                    } catch (e: Exception) {
                        result.success(mapOf(
                            "status" to "error",
                            "message" to (e.message ?: "Location error")
                        ))
                    }
                }

                "launchDialer" -> {
                    val phone = call.argument<String>("phoneNumber") ?: ""
                    try {
                        val dialIntent = Intent(Intent.ACTION_DIAL).apply {
                            data = Uri.parse("tel:${phone.trim()}")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(dialIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("DIALER_ERROR", e.message ?: "Could not open dialer", null)
                    }
                }

                "launchMapDirections" -> {
                    val lat = call.argument<Double>("latitude") ?: 0.0
                    val lng = call.argument<Double>("longitude") ?: 0.0
                    val label = call.argument<String>("label") ?: "Hospital"
                    try {
                        // First attempt Google Maps navigation intent
                        val navUri = Uri.parse("google.navigation:q=$lat,$lng")
                        val navIntent = Intent(Intent.ACTION_VIEW, navUri).apply {
                            setPackage("com.google.android.apps.maps")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(navIntent)
                        result.success(true)
                    } catch (e1: Exception) {
                        try {
                            // Fallback to geo: intent
                            val geoUri = Uri.parse("geo:$lat,$lng?q=$lat,$lng($label)")
                            val geoIntent = Intent(Intent.ACTION_VIEW, geoUri).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(geoIntent)
                            result.success(true)
                        } catch (e2: Exception) {
                            try {
                                // Web Google Maps fallback
                                val webUri = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$lat,$lng")
                                val webIntent = Intent(Intent.ACTION_VIEW, webUri).apply {
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                }
                                startActivity(webIntent)
                                result.success(true)
                            } catch (e3: Exception) {
                                result.error("MAPS_ERROR", e3.message ?: "Could not launch maps", null)
                            }
                        }
                    }
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
