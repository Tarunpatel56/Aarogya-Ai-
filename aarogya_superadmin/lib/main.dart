import 'package:flutter/material.dart';
import 'core/config/api_config.dart';
import 'core/storage/token_storage.dart';
import 'screens/auth/superadmin_login_screen.dart';
import 'screens/dashboard/superadmin_dashboard_screen.dart';
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
  final TokenStorage _tokenStorage = TokenStorage();
  bool _isChecking = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final valid = await _tokenStorage.hasValidToken();
    if (mounted) {
      setState(() {
        _isAuthenticated = valid;
        _isChecking = false;
      });
    }
  }

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
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFEF4444)),
        ),
      );
    }

    if (_isAuthenticated) {
      return SuperAdminDashboardScreen(onLogout: _onLogout);
    }

    return SuperAdminLoginScreen(onLoginSuccess: _onLoginSuccess);
  }
}
