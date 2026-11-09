import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aarogya_healthpro/screens/auth/doctor_login_screen.dart';
import 'package:aarogya_healthpro/core/api/api_client.dart';
import 'package:aarogya_healthpro/core/storage/token_storage.dart';
import 'package:aarogya_healthpro/services/doctor_auth_service.dart';

void main() {
  testWidgets('DoctorLoginScreen renders clinical header, inputs and sign in button', (WidgetTester tester) async {
    final tokenStorage = InMemoryTokenStorage();
    final apiClient = ApiClient(baseUrl: 'http://localhost:5000/api/v1', tokenStorage: tokenStorage);
    final authService = DoctorAuthService(apiClient: apiClient);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DoctorLoginScreen(
            authService: authService,
            onLoginSuccess: () {},
          ),
        ),
      ),
    );

    expect(find.text('Aarogya HealthPro'), findsOneWidget);
    expect(find.text('Physician Portal & Clinical Tele-ICU Console'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email & Password
    expect(find.widgetWithText(ElevatedButton, 'Sign In to Clinical Portal'), findsOneWidget);
    expect(find.text('Register Medical Profile'), findsOneWidget);
  });

  testWidgets('DoctorLoginScreen validates empty email and password', (WidgetTester tester) async {
    final tokenStorage = InMemoryTokenStorage();
    final apiClient = ApiClient(baseUrl: 'http://localhost:5000/api/v1', tokenStorage: tokenStorage);
    final authService = DoctorAuthService(apiClient: apiClient);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DoctorLoginScreen(
            authService: authService,
            onLoginSuccess: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In to Clinical Portal'));
    await tester.pump();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });
}
