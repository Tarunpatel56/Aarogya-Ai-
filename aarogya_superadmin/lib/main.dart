import 'package:flutter/material.dart';
import 'core/config/api_config.dart';
import 'screens/auth/superadmin_login_screen.dart';
import 'screens/dashboard/superadmin_dashboard_screen.dart';
import 'screens/splash/superadmin_splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.autoDetectBaseUrl();
  runApp(const AarogyaSuperAdminApp());
}

class AarogyaSuperAdminApp extends StatelessWidget {
  const AarogyaSuperAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aarogya Super Admin Command',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SuperAdminAuthGate(),
    );
  }
}

class SuperAdminAuthGate extends StatefulWidget {
  const SuperAdminAuthGate({super.key});

  @override
  State<SuperAdminAuthGate> createState() => _SuperAdminAuthGateState();
}

class _SuperAdminAuthGateState extends State<SuperAdminAuthGate> {
  bool _isChecking = true;
  bool _isAuthenticated = false;

  void _onLoginSuccess() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  void _onLogout() {
    setState(() {
      _isAuthenticated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return SuperAdminSplashScreen(
        onSessionChecked: (hasSession) {
          if (mounted) {
            setState(() {
              _isAuthenticated = hasSession;
              _isChecking = false;
            });
          }
        },
      );
    }

    if (_isAuthenticated) {
      return SuperAdminDashboardScreen(onLogout: _onLogout);
    }

    return SuperAdminLoginScreen(onLoginSuccess: _onLoginSuccess);
  }
}
