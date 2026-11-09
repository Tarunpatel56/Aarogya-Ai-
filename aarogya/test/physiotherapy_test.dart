import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aarogya/models/physiotherapy_model.dart';
import 'package:aarogya/services/physiotherapy_service.dart';
import 'package:aarogya/screens/physio/physiotherapy_home_screen.dart';
import 'package:aarogya/screens/physio/exercise_session_screen.dart';
import 'package:aarogya/models/ai_response_model.dart';
import 'package:aarogya/services/ai_service.dart';
import 'package:aarogya/screens/ocr_scanner_modal.dart';

class MockAiService extends AiService {
  @override
  Future<AiMedicineAnalysis> analyzeMedicine(
      {required String ocrText, String language = 'en'}) async {
    return const AiMedicineAnalysis(
      medicineName: 'Telmisartan',
      genericName: 'Telmisartan',
      dosage: '40mg',
      dosageForm: 'Tablet',
      frequency: 'Once daily',
      purpose: 'Hypertension treatment',
      uses: ['Hypertension management', 'Heart attack risk reduction'],
      disadvantages: ['Dizziness', 'Hyperkalemia'],
      whatHappensWhenTaken: 'Relaxes blood vessels by blocking Angiotensin II.',
      estimatedPrice: '₹35 - ₹65 per strip (10 tablets)',
      instructions: 'Take once daily in evening with water.',
      warnings: ['Avoid potassium substitutes'],
      disclaimer: 'Notice: Informational only.',
      provider: 'Gemini',
    );
  }

  @override
  Future<AiMedicineAnalysis> analyzeMedicineImage({
    required List<int> imageBytes,
    String filename = 'medicine_strip.jpg',
    String language = 'en',
  }) async {
    return analyzeMedicine(ocrText: 'TELMISARTAN TABLETS IP 40mg', language: language);
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('PhysiotherapyService Unit Tests', () {
    test('provides exercises across all body areas with safety guidance', () {
      final service = PhysiotherapyService(storage: InMemoryPhysioStorage());
      final all = service.getExercises();

      expect(all.isNotEmpty, true);
      expect(all.any((e) => e.bodyArea == BodyArea.neck), true);
      expect(all.any((e) => e.bodyArea == BodyArea.lowerBack), true);
      expect(all.any((e) => e.bodyArea == BodyArea.shoulder), true);
      expect(all.any((e) => e.bodyArea == BodyArea.knee), true);
      expect(all.any((e) => e.bodyArea == BodyArea.posture), true);

      for (final ex in all) {
        expect(ex.instructions.isNotEmpty, true);
        expect(ex.safetyGuidance.isNotEmpty, true);
        expect(ex.breathingNotes.isNotEmpty, true);
      }
    });

    test('filters exercises by area and goal', () {
      final service = PhysiotherapyService(storage: InMemoryPhysioStorage());
      final neckMobility = service.getExercises(
        area: BodyArea.neck,
        goal: ExerciseGoal.mobility,
      );

      for (final ex in neckMobility) {
        expect(ex.bodyArea, BodyArea.neck);
        expect(ex.goal, ExerciseGoal.mobility);
      }
    });

    test('daily plans group exercises into targeted routines', () {
      final service = PhysiotherapyService(storage: InMemoryPhysioStorage());
      final plans = service.getDailyPlans();

      expect(plans.length, 3);
      expect(plans[0].title, contains('Desk Worker'));
      expect(plans[0].exercises.isNotEmpty, true);
    });

    test('logs completed session and calculates weekly progress', () async {
      final storage = InMemoryPhysioStorage();
      final service = PhysiotherapyService(storage: storage);
      await service.init();
      final exercise = service.getExercises().first;

      await service.logCompletedSession(
        exercise: exercise,
        durationSeconds: 120,
        completedReps: 10,
        painRating: 2,
        difficulty: SessionDifficulty.justRight,
        userNotes: 'Felt good relief in upper neck',
      );

      expect(service.sessionHistoryNotifier.value.length, 1);
      final log = service.sessionHistoryNotifier.value.first;
      expect(log.exerciseId, exercise.id);
      expect(log.painRating, 2);
      expect(log.difficulty, SessionDifficulty.justRight);

      final progress = service.getWeeklyProgress();
      expect(progress['completedSessionsCount'], 1);
      expect(progress['totalMinutes'], 2);
      expect(progress['averagePainScore'], 2.0);
    });
  });

  group('Physiotherapy UI Widget Tests', () {
    testWidgets('PhysiotherapyHomeScreen renders progress header, plans, and exercise library', (tester) async {
      final service = PhysiotherapyService(storage: InMemoryPhysioStorage());

      await tester.pumpWidget(
        MaterialApp(
          home: PhysiotherapyHomeScreen(physioService: service),
        ),
      );

      expect(find.text('Physiotherapy & Rehab'), findsOneWidget);
      expect(find.text('7-Day Rehabilitation Activity'), findsOneWidget);
      expect(find.text('Daily Guided Rehabilitation Plans'), findsOneWidget);
      expect(find.text('Exercise Library'), findsOneWidget);
      expect(find.text('All Areas'), findsOneWidget);
      expect(find.text('Cervical Retraction (Chin Tucks)'), findsOneWidget);
    });

    testWidgets('ExerciseSessionScreen displays timer, reps, steps, and safety notice', (tester) async {
      final service = PhysiotherapyService(storage: InMemoryPhysioStorage());
      await service.init();
      final exercise = service.getExercises().first;

      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseSessionScreen(
            exercise: exercise,
            physioService: service,
          ),
        ),
      );

      expect(find.text(exercise.title), findsWidgets);
      expect(find.text('Remaining'), findsOneWidget);
      expect(find.text('Repetitions Completed'), findsOneWidget);
      expect(find.text('Step-by-Step Execution'), findsOneWidget);
      expect(find.text('Rehabilitation Safety Notice'), findsOneWidget);

      // Tap + button to increment reps
      await tester.tap(find.byIcon(Icons.add_circle));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      // Scroll to Next Step button and tap
      await tester.ensureVisible(find.text('Next Step'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next Step'));
      await tester.pump();
      expect(find.text('Step 2 of ${exercise.instructions.length}'), findsOneWidget);
    });
  });

  group('Enhanced Medicine Analyzer OCR Tests', () {
    testWidgets('OcrScannerModal renders samples and separates OCR text from drug reference', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OcrScannerModal(aiService: MockAiService()),
          ),
        ),
      );

      // Step animation forward
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Medicine Strip & Rx Analyzer'), findsOneWidget);
      expect(find.text('Test Samples / Prescriptions:'), findsOneWidget);
      expect(find.text('1. Raw Extracted Text (From Camera / OCR):'), findsOneWidget);
      expect(find.text('Edit OCR Text'), findsOneWidget);

      // Switch to blurry sample to verify honest unconfident identification
      await tester.ensureVisible(find.text('Blurry / Unclear'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Blurry / Unclear'));
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.textContaining('Cannot identify medicine with sufficient confidence'), findsOneWidget);
      expect(find.text('Type Manually'), findsOneWidget);
    });
  });
}
