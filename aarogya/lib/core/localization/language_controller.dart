import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../../features/physiotherapy/services/physio_tts_coach_service.dart';

class LanguageController extends GetxController {
  static LanguageController get to => Get.find<LanguageController>();

  static const String _storageKey = 'aarogya_app_language';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final RxString currentLanguage = 'en'.obs;

  bool get isHindi => currentLanguage.value == 'hi';
  bool get isEnglish => currentLanguage.value == 'en';

  Locale get locale => isHindi ? const Locale('hi', 'IN') : const Locale('en', 'US');

  @override
  void onInit() {
    super.onInit();
    loadSavedLanguage();
  }

  /// Load persisted language from secure storage
  Future<void> loadSavedLanguage() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (saved == 'hi' || saved == 'en') {
        currentLanguage.value = saved!;
        Get.updateLocale(locale);
        _syncTtsLanguage();
      }
    } catch (_) {
      // Default remains 'en'
    }
  }

  /// Switch language between pure English ('en') and pure Hindi ('hi')
  Future<void> changeLanguage(String langCode) async {
    if (langCode != 'en' && langCode != 'hi') return;
    if (currentLanguage.value == langCode) return;

    currentLanguage.value = langCode;
    await Get.updateLocale(locale);

    try {
      await _storage.write(key: _storageKey, value: langCode);
    } catch (_) {}

    _syncTtsLanguage();
  }

  /// Toggle language between English and Hindi
  Future<void> toggleLanguage() async {
    final next = isHindi ? 'en' : 'hi';
    await changeLanguage(next);
  }

  void _syncTtsLanguage() {
    try {
      PhysioTtsCoachService().setLanguage(isHindi ? 'hi-IN' : 'en-US');
    } catch (_) {}
  }
}
