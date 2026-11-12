import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'core/config/api_config.dart';
import 'services/doctor_auth_service.dart';
import 'screens/splash/doctor_splash_screen.dart';

export 'screens/doctor_navigation_shell.dart';

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
  final Widget? home;
  final DoctorAuthService? authService;

  const AarogyaHealthProApp({
    super.key,
    this.home,
    this.authService,
  });

  @override
  State<AarogyaHealthProApp> createState() => _AarogyaHealthProAppState();
}

class _AarogyaHealthProAppState extends State<AarogyaHealthProApp> {
  late final DoctorAuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? DoctorAuthService();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aarogya HealthPro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: widget.home ?? DoctorSplashScreen(authService: _authService),
    );
  }
}
