import 'package:flutter/services.dart';
import '../models/pose_landmark_model.dart';

class MediaPipePoseService {
  static const MethodChannel _channel = MethodChannel('io.aarogya.mediapipe/pose');

  bool _isInitialized = false;
  bool _isProcessingFrame = false;
  String _activeDelegate = 'NONE';
  int _lastInferenceTimeMs = 0;
  String _lastError = '';

  bool get isInitialized => _isInitialized;
  String get activeDelegate => _activeDelegate;
  int get lastInferenceTimeMs => _lastInferenceTimeMs;
  String get lastError => _lastError;

  /// Initializes MediaPipe Pose Landmarker Lite on device
  Future<bool> init({bool preferGpu = true, double minConfidence = 0.5}) async {
    try {
      _lastError = '';
      final res = await _channel.invokeMethod<Map>('initPoseLandmarker', {
        'preferGpu': preferGpu,
        'minConfidence': minConfidence,
      });

      if (res != null && res['status'] == 'success') {
        _isInitialized = true;
        _activeDelegate = res['delegate']?.toString() ?? 'CPU';
        return true;
      }
      _lastError = res?['message']?.toString() ?? 'Failed to initialize pose landmarker.';
      return false;
    } catch (e) {
      _isInitialized = false;
      _lastError = e.toString();
      return false;
    }
  }

  /// Processes camera frame with zero queue latency (drops frames if busy)
  Future<PoseDetectionFrame?> processCameraFrame({
    required Uint8List bytes,
    required int width,
    required int height,
    int rotation = 0,
  }) async {
    if (!_isInitialized) return null;

    // Zero-lag guard: drop frame if inference is currently executing
    if (_isProcessingFrame) return null;

    _isProcessingFrame = true;
    try {
      final res = await _channel.invokeMethod<Map>('detectPoseFromRgbaBuffer', {
        'rgbaBytes': bytes,
        'width': width,
        'height': height,
        'rotation': rotation,
      });

      if (res != null && res['status'] == 'success') {
        _lastInferenceTimeMs = (res['inferenceTimeMs'] as num?)?.toInt() ?? 0;
        _activeDelegate = res['delegate']?.toString() ?? _activeDelegate;

        final landmarksRaw = res['landmarks'] as List? ?? [];
        final landmarks = landmarksRaw
            .map((e) => PoseLandmark.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        return PoseDetectionFrame(
          landmarks: landmarks,
          inferenceTimeMs: _lastInferenceTimeMs,
          delegate: _activeDelegate,
          timestamp: DateTime.now(),
          isPersonDetected: landmarks.isNotEmpty,
        );
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      _isProcessingFrame = false;
    }
  }

  /// Single image/JPEG detection fallback
  Future<PoseDetectionFrame?> processImageBytes({
    required Uint8List imageBytes,
    int rotation = 0,
  }) async {
    if (!_isInitialized) return null;

    try {
      final res = await _channel.invokeMethod<Map>('detectPoseFromImageBytes', {
        'imageBytes': imageBytes,
        'rotation': rotation,
      });

      if (res != null && res['status'] == 'success') {
        _lastInferenceTimeMs = (res['inferenceTimeMs'] as num?)?.toInt() ?? 0;
        final landmarksRaw = res['landmarks'] as List? ?? [];
        final landmarks = landmarksRaw
            .map((e) => PoseLandmark.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        return PoseDetectionFrame(
          landmarks: landmarks,
          inferenceTimeMs: _lastInferenceTimeMs,
          delegate: res['delegate']?.toString() ?? _activeDelegate,
          timestamp: DateTime.now(),
          isPersonDetected: landmarks.isNotEmpty,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    if (_isInitialized) {
      try {
        await _channel.invokeMethod('closePoseLandmarker');
      } catch (_) {}
      _isInitialized = false;
    }
  }
}
