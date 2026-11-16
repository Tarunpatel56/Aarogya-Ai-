import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'theme/app_theme.dart';
import 'core/config/api_config.dart';
import 'core/localization/app_translations.dart';
import 'core/localization/language_controller.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';

export 'screens/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await ApiConfig.autoDetectBaseUrl();
  Get.put(LanguageController());
  runApp(const AarogyaAiApp());
}

class AarogyaAiApp extends StatefulWidget {
  final Widget? home;
  final AuthService? authService;

  const AarogyaAiApp({
    super.key,
    this.home,
    this.authService,
  });

  @override
  State<AarogyaAiApp> createState() => _AarogyaAiAppState();
}

class _AarogyaAiAppState extends State<AarogyaAiApp> {
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  Widget build(BuildContext context) {
    final langCtrl = Get.find<LanguageController>();

    return GetMaterialApp(
      title: 'Aarogya AI 2.0',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      translations: AppTranslations(),
      locale: langCtrl.locale,
      fallbackLocale: const Locale('en', 'US'),
      // High polish splash screen handling animated session restoration
      home: widget.home ?? SplashScreen(authService: _authService),
    );
  }
}
