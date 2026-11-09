import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aarogya_rapid/main.dart';
import 'package:aarogya_rapid/screens/auth/driver_login_screen.dart';
import 'package:aarogya_rapid/screens/active_trip_screen.dart';
import 'package:aarogya_rapid/screens/history_screen.dart';
import 'package:aarogya_rapid/models/trip_model.dart';

void main() {
  testWidgets(
    'DriverLoginScreen displays EMS credentials inputs and sign in action',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: DriverLoginScreen(onLoginSuccess: () {})),
      );

      // Verify EMS login terminal
      expect(find.text('Aarogya Rapid EMS'), findsOneWidget);
      expect(
        find.text('Ambulance Driver & Paramedic Terminal'),
        findsOneWidget,
      );
      expect(find.text('Sign In to EMS Terminal'), findsOneWidget);
    },
  );

  testWidgets(
    'RapidRootNavigationHost initial state shows empty queue and standby',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RapidRootNavigationHost()),
      );

      // Verify terminal title
      expect(find.text('Aarogya Rapid'), findsAtLeast(1));

      // Verify honest empty state with zero fake emergencies
      expect(find.text('No Active Emergency Dispatches'), findsOneWidget);
      expect(find.text('Queue Clear'), findsOneWidget);
      expect(find.text('Log Manual Emergency Intake'), findsOneWidget);
    },
  );

  testWidgets(
    'ActiveTripScreen displays honest standby state when no active transit',
    (WidgetTester tester) async {
      bool navigatedBack = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveTripScreen(
            request: null,
            onOpenHandoverReport: () {},
            onBackToQueue: () => navigatedBack = true,
          ),
        ),
      );

      expect(find.text('No Active Transit in Progress'), findsOneWidget);
      expect(find.text('View Emergency Queue'), findsOneWidget);

      await tester.tap(find.text('View Emergency Queue'));
      await tester.pump();
      expect(navigatedBack, isTrue);
    },
  );

  testWidgets('HistoryScreen displays clean empty state when no past trips', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: HistoryScreen(completedTrips: [])),
    );

    expect(find.text('No Past Emergency Trips Recorded'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('Manual emergency intake creates request and dispatches', (
    WidgetTester tester,
  ) async {
    final req = EmergencyRequest.manualIntake(
      patientName: 'Devendra Joshi',
      pickupAddress: 'MG Road, Bengaluru',
      reportedEmergency: 'Acute breathlessness',
      isCritical: true,
    );

    expect(req.patientName, 'Devendra Joshi');
    expect(req.pickupAddress, 'MG Road, Bengaluru');
    expect(req.isCritical, isTrue);
    expect(req.tier, 'Tier 1 Critical');
    expect(req.id, startsWith('EMS-'));
  });
}
