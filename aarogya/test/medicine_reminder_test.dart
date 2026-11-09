import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aarogya/models/medicine_reminder_model.dart';
import 'package:aarogya/services/medicine_reminder_service.dart';
import 'package:aarogya/screens/reminders/medicine_reminders_screen.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('MedicineReminderModel Unit Tests', () {
    test('serializes and deserializes correctly', () {
      const reminder = MedicineReminder(
        id: 'test_rem_1',
        medicineName: 'Amlodipine',
        dosage: '5mg • 1 Tab',
        doseTime: MedicineDoseTime.morning,
        mealTiming: MealTiming.afterFood,
        timeString: '09:00 AM',
        instructions: 'Take after breakfast',
      );

      final json = reminder.toJson();
      expect(json['medicineName'], 'Amlodipine');
      expect(json['doseTime'], 'morning');
      expect(json['mealTiming'], 'afterFood');

      final deserialized = MedicineReminder.fromJson(json);
      expect(deserialized.id, 'test_rem_1');
      expect(deserialized.medicineName, 'Amlodipine');
      expect(deserialized.doseTime, MedicineDoseTime.morning);
      expect(deserialized.mealTiming, MealTiming.afterFood);
      expect(deserialized.status, DoseStatus.pending);
    });
  });

  group('MedicineReminderService Unit Tests', () {
    test('initializes with seed reminders and computes adherence', () async {
      final storage = InMemoryMedicineReminderStorage();
      final service = MedicineReminderService(storage: storage);
      await service.init();

      final list = service.getReminders();
      expect(list.isNotEmpty, true);
      expect(list.any((r) => r.medicineName.contains('Telmisartan')), true);

      final stats = service.getAdherenceStats();
      expect(stats['totalDoses'], list.length);
      expect(stats['streakDays'], greaterThan(0));
    });

    test('updates dose status: taken, skipped, snoozed', () async {
      final storage = InMemoryMedicineReminderStorage();
      final service = MedicineReminderService(storage: storage);
      await service.init();

      final id = service.getReminders().first.id;

      await service.markDoseTaken(id);
      expect(service.getReminders().firstWhere((r) => r.id == id).status, DoseStatus.taken);
      expect(service.getReminders().firstWhere((r) => r.id == id).lastTakenAt, isNotNull);

      await service.markDoseSkipped(id);
      expect(service.getReminders().firstWhere((r) => r.id == id).status, DoseStatus.skipped);

      await service.snoozeDose(id);
      expect(service.getReminders().firstWhere((r) => r.id == id).status, DoseStatus.snoozed);
    });

    test('adds and deletes reminders', () async {
      final storage = InMemoryMedicineReminderStorage();
      final service = MedicineReminderService(storage: storage);
      await service.init();
      final countBefore = service.getReminders().length;

      await service.addReminder(
        medicineName: 'Atorvastatin',
        dosage: '10mg',
        doseTime: MedicineDoseTime.night,
        mealTiming: MealTiming.afterFood,
        timeString: '10:00 PM',
      );

      expect(service.getReminders().length, countBefore + 1);
      final newRem = service.getReminders().last;
      expect(newRem.medicineName, 'Atorvastatin');

      await service.deleteReminder(newRem.id);
      expect(service.getReminders().length, countBefore);
    });
  });

  group('MedicineRemindersScreen Widget Tests', () {
    testWidgets('renders schedule and allows marking dose taken', (tester) async {
      final storage = InMemoryMedicineReminderStorage();
      final service = MedicineReminderService(storage: storage);
      await service.init();

      await tester.pumpWidget(
        MaterialApp(
          home: MedicineRemindersScreen(reminderService: service),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Smart Medicine Reminders'), findsOneWidget);
      expect(find.text('Today\'s Medication Schedule'), findsOneWidget);
      expect(find.textContaining('Adherence Streak!'), findsOneWidget);

      // Tap Take Now on pending dose
      if (find.text('Take Now').evaluate().isNotEmpty) {
        await tester.tap(find.text('Take Now').first);
        await tester.pumpAndSettle();
        expect(find.text('Logged on time'), findsWidgets);
      }
    });
  });
}
