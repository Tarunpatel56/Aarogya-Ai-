import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'widgets/bottom_nav_bar.dart';
import 'screens/doctor_dashboard_screen.dart';
import 'screens/patients_directory_screen.dart';
import 'screens/appointments/doctor_appointments_screen.dart';
import 'screens/notifications/doctor_notifications_screen.dart';
import 'core/config/api_config.dart';
import 'screens/doctor_profile_screen.dart';
import 'screens/auth/doctor_login_screen.dart';
import 'services/doctor_auth_service.dart';
import 'services/doctor_appointment_service.dart';
import 'services/doctor_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surfaceContainerLowest,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  await ApiConfig.autoDetectBaseUrl();
  runApp(const AarogyaHealthProApp());
}

class AarogyaHealthProApp extends StatefulWidget {
  const AarogyaHealthProApp({super.key});

  @override
  State<AarogyaHealthProApp> createState() => _AarogyaHealthProAppState();
}

class _AarogyaHealthProAppState extends State<AarogyaHealthProApp> {
  final DoctorAuthService _authService = DoctorAuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aarogya HealthPro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: DoctorAuthGate(authService: _authService),
    );
  }
}

class DoctorAuthGate extends StatefulWidget {
  final DoctorAuthService authService;

  const DoctorAuthGate({super.key, required this.authService});

  @override
  State<DoctorAuthGate> createState() => _DoctorAuthGateState();
}

class _DoctorAuthGateState extends State<DoctorAuthGate> {
  late Future<bool> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = widget.authService.restoreSession();
    widget.authService.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    widget.authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.surface,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Restoring Aarogya HealthPro Clinical Session...',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (widget.authService.isAuthenticated) {
          return MainNavigationShell(authService: widget.authService);
        }

        return DoctorLoginScreen(
          authService: widget.authService,
          onLoginSuccess: () {
            setState(() {});
          },
        );
      },
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  final DoctorAuthService? authService;

  const MainNavigationShell({super.key, this.authService});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DoctorDashboardScreen(
        onNavigateTab: _onTabSelected,
        authService: widget.authService,
      ),
      DoctorAppointmentsScreen(
        appointmentService: DoctorAppointmentService(),
      ),
      const PatientsDirectoryScreen(),
      DoctorNotificationsScreen(
        notificationService: DoctorNotificationService(),
      ),
      DoctorProfileScreen(authService: widget.authService),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: ClinicalBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        alertBadgeCount: 0,
      ),
    );
  }
}
