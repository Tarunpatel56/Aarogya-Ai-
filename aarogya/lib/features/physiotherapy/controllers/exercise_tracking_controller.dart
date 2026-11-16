import 'package:get/get.dart';
import '../models/exercise_biomechanics_config.dart';
import '../models/joint_angle_model.dart';
import '../models/pose_landmark_model.dart';
import '../services/joint_angle_calculator.dart';
import '../services/exercise_state_machine.dart';
import '../services/physio_tts_coach_service.dart';
import 'pose_estimation_controller.dart';

class ExerciseTrackingController extends GetxController {
  final ExerciseType exerciseType;
  final int targetReps;
  final PhysioTtsCoachService ttsCoach = PhysioTtsCoachService();
  final JointAngleCalculator _angleCalc = JointAngleCalculator();
  late final ExerciseStateMachine _stateMachine;

  final Rx<JointAngleSnapshot> currentAngles = JointAngleSnapshot.empty().obs;
  final RxInt completedReps = 0.obs;
  final Rx<ExercisePhase> currentPhase = ExercisePhase.startingPosition.obs;
  final RxDouble currentJointAngle = 0.0.obs;
  final RxDouble formAccuracy = 95.0.obs;
  final RxString activeFeedbackCue = ''.obs;
  final RxList<String> postureErrors = <String>[].obs;
  final RxBool hasActivePostureError = false.obs;
  final RxBool isSessionCompleted = false.obs;

  ExerciseBiomechanicsConfig get config => _stateMachine.config;

  ExerciseTrackingController({
    required this.exerciseType,
    this.targetReps = 10,
  }) {
    _stateMachine = ExerciseStateMachine(exerciseType: exerciseType);
  }

  @override
  void onInit() {
    super.onInit();
    ttsCoach.init();

    // Listen to live pose frames from PoseEstimationController
    final poseController = Get.find<PoseEstimationController>();
    ever<PoseDetectionFrame>(poseController.currentFrame, (frame) {
      _processPoseFrame(frame);
    });
  }

  void _processPoseFrame(PoseDetectionFrame frame) {
    if (!frame.isPersonDetected || isSessionCompleted.value) return;

    // 1. Calculate and smooth biomechanical angles
    final angles = _angleCalc.calculateAngles(frame);
    currentAngles.value = angles;

    // 2. Feed into clinical state machine
    final repEvent = _stateMachine.processFrame(angles: angles, frame: frame);

    currentJointAngle.value = repEvent.currentAngle;
    completedReps.value = repEvent.completedReps;
    currentPhase.value = repEvent.phase;
    formAccuracy.value = _stateMachine.overallAccuracyScore;
    postureErrors.assignAll(_stateMachine.allSessionErrors);
    hasActivePostureError.value = _stateMachine.hasActivePostureError;

    // 3. Audio & Visual Coaching
    final isHindi = Get.locale?.languageCode == 'hi';
    if (repEvent.feedbackMessage != null && repEvent.feedbackMessage!.isNotEmpty) {
      final msg = repEvent.feedbackMessage!;
      final localized = _localizeCue(msg, isHindi);
      activeFeedbackCue.value = localized;
      ttsCoach.speakCue(localized);
    } else if (!_stateMachine.hasActivePostureError) {
      final goodFormCue = isHindi ? 'मुद्रा बिल्कुल सही है' : 'Good Form';
      activeFeedbackCue.value = goodFormCue;
    }

    // 4. Milestone Check
    if (completedReps.value >= targetReps && !isSessionCompleted.value) {
      isSessionCompleted.value = true;
      final doneCue = isHindi
          ? 'लक्ष्य पुनरावृत्तियां पूर्ण हुईं! उत्कृष्ट व्यायाम प्रदर्शन।'
          : 'Target repetitions completed! Excellent rehabilitation work.';
      activeFeedbackCue.value = doneCue;
      ttsCoach.speakCue(doneCue, highPriority: true);
    }
  }

  String _localizeCue(String cue, bool isHindi) {
    if (!isHindi) {
      if (cue.contains('Back') || cue.contains('पीठ')) return 'Keep your back straight';
      if (cue.contains('neck') || cue.contains('गर्दन')) return 'Keep your neck aligned';
      if (cue.contains('Form') || cue.contains('मुद्रा')) return 'Good Form';
      return cue;
    }
    if (cue.contains('Back') || cue.contains('straight')) return 'अपनी पीठ सीधी रखें';
    if (cue.contains('neck') || cue.contains('aligned')) return 'अपनी गर्दन सीधी रखें';
    if (cue.contains('Good') || cue.contains('Form')) return 'मुद्रा बिल्कुल सही है';
    return cue;
  }

  void resetExercise() {
    _stateMachine.reset();
    _angleCalc.resetSmoothing();
    completedReps.value = 0;
    isSessionCompleted.value = false;
    currentPhase.value = ExercisePhase.startingPosition;
    postureErrors.clear();
  }

  @override
  void onClose() {
    ttsCoach.stop();
    super.onClose();
  }
}
