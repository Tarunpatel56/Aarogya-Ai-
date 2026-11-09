import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aarogya/screens/auth/patient_login_screen.dart';
import 'package:aarogya/core/storage/token_storage.dart';
import 'package:aarogya/core/api/api_client.dart';
import 'package:aarogya/services/auth_service.dart';

void main() {
  testWidgets('PatientLoginScreen renders email, password fields and sign in button', (WidgetTester tester) async {
    final tokenStorage = InMemoryTokenStorage();
    final apiClient = ApiClient(baseUrl: 'http://localhost:5000/api/v1', tokenStorage: tokenStorage);
    final authService = AuthService(apiClient: apiClient);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PatientLoginScreen(
            authService: authService,
            onLoginSuccess: () {},
          ),
        ),
      ),
    );

    expect(find.text('Welcome to Aarogya'), findsOneWidget);
    expect(find.text('Sign in to your patient healthcare portal'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email & Password
    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
  });

  testWidgets('PatientLoginScreen shows validation errors for empty fields', (WidgetTester tester) async {
    final tokenStorage = InMemoryTokenStorage();
    final apiClient = ApiClient(baseUrl: 'http://localhost:5000/api/v1', tokenStorage: tokenStorage);
    final authService = AuthService(apiClient: apiClient);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PatientLoginScreen(
            authService: authService,
            onLoginSuccess: () {},
          ),
        ),
      ),
    );

    // Tap Sign In button without entering credentials
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pump();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });
}
