import 'dart:async';
import 'package:get/get.dart';
import '../models/exercise_biomechanics_config.dart';
import '../models/physio_session_report_model.dart';
import '../services/physio_api_service.dart';
import 'exercise_tracking_controller.dart';

class PhysioSessionController extends GetxController {
  final ExerciseType exerciseType;
  final int targetReps;

  final PhysioApiService _apiService = PhysioApiService();

  Timer? _sessionTimer;
  final RxInt elapsedSeconds = 0.obs;
  final RxBool isTimerRunning = false.obs;
  final RxInt painVAS = 0.obs; // 0 (No Pain) to 10 (Severe)
  final RxString difficulty = 'Just Right'.obs;
  final RxBool isSubmitting = false.obs;

  PhysioSessionController({
    required this.exerciseType,
    this.targetReps = 10,
  });

  /// Formatted duration string MM:SS (e.g., 01:25)
  String get formattedDuration {
    final m = (elapsedSeconds.value ~/ 60).toString().padLeft(2, '0');
    final s = (elapsedSeconds.value % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void onInit() {
    super.onInit();
    startTimer();
  }

  void startTimer() {
    isTimerRunning.value = true;
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsedSeconds.value++;
    });
  }

  void pauseTimer() {
    _sessionTimer?.cancel();
    isTimerRunning.value = false;
  }

  void resumeTimer() {
    startTimer();
  }

  /// Builds report and syncs with backend & doctor portal
  Future<PhysioSessionReport> finalizeSessionReport({
    int? painRating,
    String? userDifficulty,
  }) async {
    pauseTimer();
    isSubmitting.value = true;

    final trackingCtrl = Get.find<ExerciseTrackingController>();

    final report = PhysioSessionReport(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      patientId: 'patient_current',
      exerciseId: exerciseType.id,
      exerciseTitle: exerciseType.title,
      targetReps: targetReps,
      completedReps: trackingCtrl.completedReps.value,
      durationSeconds: elapsedSeconds.value > 0 ? elapsedSeconds.value : 1,
      formAccuracyScore: trackingCtrl.formAccuracy.value,
      minJointAngle: 50.0,
      maxJointAngle: 165.0,
      avgJointAngle: trackingCtrl.currentJointAngle.value,
      detectedPostureErrors: trackingCtrl.postureErrors,
      painRatingVAS: painRating ?? painVAS.value,
      difficultyFeedback: userDifficulty ?? difficulty.value,
      completionStatus: trackingCtrl.completedReps.value >= targetReps ? 'COMPLETED' : 'PARTIAL',
      completedAt: DateTime.now(),
    );

    await _apiService.saveSessionReport(report);
    isSubmitting.value = false;

    return report;
  }

  @override
  void onClose() {
    _sessionTimer?.cancel();
    super.onClose();
  }
}

