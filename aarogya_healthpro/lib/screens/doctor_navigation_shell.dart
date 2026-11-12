import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'doctor_dashboard_screen.dart';
import 'patients_directory_screen.dart';
import 'appointments/doctor_appointments_screen.dart';
import 'notifications/doctor_notifications_screen.dart';
import 'doctor_profile_screen.dart';
import '../services/doctor_auth_service.dart';
import '../services/doctor_appointment_service.dart';
import '../services/doctor_notification_service.dart';

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
