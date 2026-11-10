import 'package:camera/camera.dart';
import 'package:get/get.dart';
import '../models/pose_landmark_model.dart';
import '../services/mediapipe_pose_service.dart';

class PoseEstimationController extends GetxController {
  final MediaPipePoseService _poseService = MediaPipePoseService();

  CameraController? cameraController;
  List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;

  final Rx<PoseDetectionFrame> currentFrame = PoseDetectionFrame.empty().obs;
  final RxBool isModelLoaded = false.obs;
  final RxBool isCameraReady = false.obs;
  final RxBool isDetecting = false.obs;
  final RxString activeDelegate = 'NONE'.obs;
  final RxInt inferenceLatencyMs = 0.obs;
  final RxInt currentFps = 0.obs;
  final RxBool isPersonDetected = false.obs;
  final RxBool isFullBodyVisible = false.obs;
  final RxString guidanceMessage = 'Initializing MediaPipe Pose Engine...'.obs;

  int _frameCount = 0;
  DateTime _lastFpsCheck = DateTime.now();
  bool _isProcessingFrame = false;

  @override
  void onInit() {
    super.onInit();
    initEngineAndCamera();
  }

  Future<void> initEngineAndCamera({bool preferGpu = true}) async {
    guidanceMessage.value = 'Starting MediaPipe Pose Landmarker Lite...';

    // 1. Initialize On-Device MediaPipe
    final success = await _poseService.init(preferGpu: preferGpu);
    if (success) {
      isModelLoaded.value = true;
      activeDelegate.value = _poseService.activeDelegate;
    } else {
      guidanceMessage.value = _poseService.lastError.isNotEmpty
          ? 'Pose Error: ${_poseService.lastError}'
          : 'Error initializing pose engine.';
      return;
    }

    // 2. Initialize Camera
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        guidanceMessage.value = 'No camera found on device.';
        return;
      }

      // Default to front camera for physiotherapy self-monitoring if available
      final frontIdx = _availableCameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      _selectedCameraIndex = frontIdx != -1 ? frontIdx : 0;

      await _setupCameraController(_availableCameras[_selectedCameraIndex]);
      isCameraReady.value = true;
      guidanceMessage.value = 'Stand back so your full body is visible in the frame.';
    } catch (e) {
      guidanceMessage.value = 'Camera error: $e';
    }
  }

  Future<void> _setupCameraController(CameraDescription cameraDesc) async {
    await cameraController?.dispose();

    cameraController = CameraController(
      cameraDesc,
      ResolutionPreset.medium, // 720p optimal for sub-20ms mobile inference
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await cameraController!.initialize();

    // Start live inference loop
    isDetecting.value = true;
    _startFrameStreaming();
  }

  void _startFrameStreaming() {
    if (cameraController == null || !cameraController!.value.isInitialized) return;

    // Use continuous frame capture with zero buffer accumulation
    cameraController!.startImageStream((CameraImage image) async {
      if (_isProcessingFrame || !isModelLoaded.value) return;

      _isProcessingFrame = true;
      try {
        final plane = image.planes.first;
        final sensorOrientation = cameraController!.description.sensorOrientation;

        // Process directly via MediaPipe native channel
        final frame = await _poseService.processCameraFrame(
          bytes: plane.bytes,
          width: image.width,
          height: image.height,
          rotation: sensorOrientation,
        );

        if (frame != null) {
          currentFrame.value = frame;
          isPersonDetected.value = frame.isPersonDetected;
          isFullBodyVisible.value = frame.isFullBodyVisible;
          inferenceLatencyMs.value = frame.inferenceTimeMs;

          // Frame rate meter
          _frameCount++;
          final now = DateTime.now();
          if (now.difference(_lastFpsCheck).inMilliseconds >= 1000) {
            currentFps.value = _frameCount;
            _frameCount = 0;
            _lastFpsCheck = now;
          }

          // User positioning guidance
          if (!frame.isPersonDetected) {
            guidanceMessage.value = 'Please step into the camera frame.';
          } else if (!frame.isFullBodyVisible) {
            guidanceMessage.value = 'Step back slightly to bring your full body into view.';
          } else {
            guidanceMessage.value = 'Optimal posture tracking active.';
          }
        }
      } catch (_) {
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  /// Switch between Front and Rear camera
  Future<void> toggleCamera() async {
    if (_availableCameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    await _setupCameraController(_availableCameras[_selectedCameraIndex]);
  }

  /// Toggle between GPU and CPU delegate on the fly
  Future<void> toggleDelegate() async {
    final nextPref = activeDelegate.value != 'GPU';
    await _poseService.init(preferGpu: nextPref);
    activeDelegate.value = _poseService.activeDelegate;
  }

  @override
  void onClose() {
    isDetecting.value = false;
    cameraController?.dispose();
    _poseService.dispose();
    super.onClose();
  }
}
