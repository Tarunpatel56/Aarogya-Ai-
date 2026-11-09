import 'package:flutter_tts/flutter_tts.dart';

class PhysioTtsCoachService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isEnabled = true;
  bool _isSpeaking = false;
  String _language = 'en-US'; // 'en-US' or 'hi-IN'
  DateTime _lastSpokenTime = DateTime.now().subtract(const Duration(seconds: 10));
  String _lastSpokenPhrase = '';

  bool get isEnabled => _isEnabled;
  String get language => _language;

  Future<void> init({String language = 'en-US'}) async {
    _language = language;
    try {
      await _flutterTts.setLanguage(_language);
      await _flutterTts.setSpeechRate(0.48); // Clear, steady clinical pace
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      _flutterTts.setStartHandler(() => _isSpeaking = true);
      _flutterTts.setCompletionHandler(() => _isSpeaking = false);
      _flutterTts.setErrorHandler((_) => _isSpeaking = false);
    } catch (_) {}
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      stop();
    }
  }

  void setLanguage(String lang) {
    _language = lang;
    _flutterTts.setLanguage(lang);
  }

  /// Speaks cue with minimum 3.0s cooldown and deduplication
  Future<void> speakCue(String phrase, {bool highPriority = false}) async {
    if (!_isEnabled) return;

    final now = DateTime.now();
    final elapsedSec = now.difference(_lastSpokenTime).inMilliseconds / 1000.0;

    // Deduplication & cooldown check
    if (!highPriority) {
      if (_isSpeaking) return;
      if (phrase == _lastSpokenPhrase && elapsedSec < 4.0) return;
      if (elapsedSec < 2.5) return;
    }

    _lastSpokenTime = now;
    _lastSpokenPhrase = phrase;

    try {
      final textToSpeak = _translateIfHindi(phrase);
      await _flutterTts.speak(textToSpeak);
    } catch (_) {}
  }

  String _translateIfHindi(String english) {
    if (!_language.startsWith('hi')) return english;

    // Essential clinical coaching dictionary
    switch (english) {
      case 'Keep your back straight and chest lifted.':
        return 'अपनी पीठ सीधी रखें और सीना आगे रखें।';
      case 'Great depth! Now push back up.':
        return 'बहुत बढ़िया! अब धीरे-धीरे सीधे खड़े हों।';
      case 'Hold at top! Lower down slowly.':
        return 'ऊपर रोकें! अब धीरे-धीरे नीचे लाएं।';
      case 'Good peak contraction! Extend back slowly.':
        return 'शानदार खिंचाव! धीरे से वापस लाएं।';
      case 'Please move into the camera frame.':
        return 'कृपया कैमरे के सामने आएं।';
      case 'Incorrect posture detected.':
        return 'पोस्चर सही नहीं है, ध्यान दें।';
      default:
        if (english.startsWith('Rep ') && english.contains('completed!')) {
          final repNum = english.split(' ')[1];
          return 'रेपिटेशन $repNum पूरा हुआ! शाबाश!';
        }
        return english;
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (_) {}
  }
}

