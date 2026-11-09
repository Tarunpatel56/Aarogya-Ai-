import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/exercise_tracking_controller.dart';
import '../controllers/physio_session_controller.dart';
import '../controllers/pose_estimation_controller.dart';
import '../models/exercise_biomechanics_config.dart';
import '../widgets/joint_angle_hud.dart';
import '../widgets/pose_skeleton_painter.dart';
import '../widgets/posture_alert_card.dart';
import '../widgets/rep_counter_wheel.dart';
import 'physio_session_report_screen.dart';

class LivePoseExerciseScreen extends StatefulWidget {
  final ExerciseType exerciseType;
  final int targetReps;

  const LivePoseExerciseScreen({
    super.key,
    required this.exerciseType,
    this.targetReps = 10,
  });

  @override
  State<LivePoseExerciseScreen> createState() => _LivePoseExerciseScreenState();
}

class _LivePoseExerciseScreenState extends State<LivePoseExerciseScreen> {
  late final PoseEstimationController poseCtrl;
  late final ExerciseTrackingController trackCtrl;
  late final PhysioSessionController sessionCtrl;

  @override
  void initState() {
    super.initState();
    poseCtrl = Get.put(PoseEstimationController());
    trackCtrl = Get.put(
      ExerciseTrackingController(
        exerciseType: widget.exerciseType,
        targetReps: widget.targetReps,
      ),
    );
    sessionCtrl = Get.put(
      PhysioSessionController(
        exerciseType: widget.exerciseType,
        targetReps: widget.targetReps,
      ),
    );
  }

  @override
  void dispose() {
    Get.delete<PhysioSessionController>();
    Get.delete<ExerciseTrackingController>();
    Get.delete<PoseEstimationController>();
    super.dispose();
  }

  void _onFinishSessionPressed() async {
    final report = await sessionCtrl.finalizeSessionReport();
    if (mounted) {
      Get.off(
        () => PhysioSessionReportScreen(report: report),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Full-Screen Edge-to-Edge Camera Preview + Matched Skeleton Overlay
            Obx(() {
              if (!poseCtrl.isCameraReady.value || poseCtrl.cameraController == null) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF00E5FF)),
                      SizedBox(height: 16),
                      Text(
                        'Starting Camera & MediaPipe Landmarker Lite...',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              final camera = poseCtrl.cameraController!;
              final previewSize = camera.value.previewSize;
              // On Android in portrait mode, previewSize width is the long side, height is short side
              final double pWidth = previewSize != null ? previewSize.height : 720.0;
              final double pHeight = previewSize != null ? previewSize.width : 1280.0;
              final isFront = camera.description.lensDirection == CameraLensDirection.front;
              final frame = poseCtrl.currentFrame.value;
              final hasPostureError = trackCtrl.hasActivePostureError.value;

              return SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: pWidth,
                    height: pHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(camera),
                        CustomPaint(
                          size: Size(pWidth, pHeight),
                          painter: PoseSkeletonPainter(
                            frame: frame,
                            isFrontCamera: isFront,
                            hasPostureError: hasPostureError,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // 3. Top Control Bar (Navigation, Camera switch, Engine delegate, Voice)
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: () => Get.back(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.exerciseType.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.exerciseType.targetArea,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Delegate Switcher Chip (GPU / CPU)
                  Obx(
                    () => ActionChip(
                      backgroundColor: Colors.black54,
                      side: BorderSide(
                        color: poseCtrl.activeDelegate.value == 'GPU'
                            ? const Color(0xFF00E676)
                            : Colors.white30,
                      ),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      avatar: Icon(
                        poseCtrl.activeDelegate.value == 'GPU'
                            ? Icons.bolt
                            : Icons.memory,
                        size: 14,
                        color: poseCtrl.activeDelegate.value == 'GPU'
                            ? const Color(0xFF00E676)
                            : Colors.white70,
                      ),
                      label: Text(
                        poseCtrl.activeDelegate.value,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: poseCtrl.activeDelegate.value == 'GPU'
                              ? const Color(0xFF00E676)
                              : Colors.white70,
                        ),
                      ),
                      onPressed: () => poseCtrl.toggleDelegate(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Camera Flip Button
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 18,
                    child: IconButton(
                      icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 16),
                      onPressed: () => poseCtrl.toggleCamera(),
                    ),
                  ),
                ],
              ),
            ),

            // 4. Biomechanical HUD (Repetition Wheel & Joint Angle Gauge) - Auto-scaling, Zero Overflow
            Positioned(
              top: 65,
              left: 12,
              right: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rep Wheel
                  Expanded(
                    flex: 5,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Obx(
                          () => RepCounterWheel(
                            completedReps: trackCtrl.completedReps.value,
                            targetReps: widget.targetReps,
                            phase: trackCtrl.currentPhase.value,
                            elapsedSeconds: sessionCtrl.elapsedSeconds.value,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Angle & Performance HUD
                  Expanded(
                    flex: 4,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Obx(
                          () => JointAngleHud(
                            primaryJointName: trackCtrl.config.primaryJointName,
                            currentAngle: trackCtrl.currentJointAngle.value,
                            formAccuracy: trackCtrl.formAccuracy.value,
                            latencyMs: poseCtrl.inferenceLatencyMs.value,
                            fps: poseCtrl.currentFps.value,
                            delegate: poseCtrl.activeDelegate.value,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 5. Bottom Feedback Coaching Card & Action Buttons
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Real-Time Spoken & Visual Coaching Card
                  Obx(
                    () {
                      final cue = trackCtrl.activeFeedbackCue.value.isNotEmpty
                          ? trackCtrl.activeFeedbackCue.value
                          : poseCtrl.guidanceMessage.value;
                      final isErr = trackCtrl.hasActivePostureError.value;

                      return PostureAlertCard(
                        message: cue,
                        isError: isErr,
                        isAudioEnabled: trackCtrl.ttsCoach.isEnabled,
                        onToggleAudio: () {
                          final next = !trackCtrl.ttsCoach.isEnabled;
                          trackCtrl.ttsCoach.setEnabled(next);
                          setState(() {});
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Finish Session Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E), // Clinical Teal
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _onFinishSessionPressed,
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: const Text(
                          'COMPLETE & VIEW REPORT',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

