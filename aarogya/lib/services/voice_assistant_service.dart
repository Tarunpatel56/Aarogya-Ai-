import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

typedef VoiceResultCallback = void Function(String recognizedWords);
typedef VoiceStatusCallback = void Function(bool isListening);

class VoiceAssistantService {
  static final VoiceAssistantService _instance = VoiceAssistantService._internal();
  factory VoiceAssistantService() => _instance;

  VoiceAssistantService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isSpeechInitialized = false;
  bool _isTtsInitialized = false;
  bool _isListening = false;
  bool _isPlayingAudio = false;

  bool get isListening => _isListening;
  bool get isPlayingAudio => _isPlayingAudio;

  /// Initialize TTS engine
  Future<void> initTts() async {
    if (_isTtsInitialized) return;
    try {
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() {
        _isPlayingAudio = false;
      });

      _flutterTts.setErrorHandler((_) {
        _isPlayingAudio = false;
      });

      _isTtsInitialized = true;
    } catch (e) {
      debugPrint('VoiceAssistantService initTts warning: $e');
    }
  }

  /// Initialize Speech-to-Text engine
  Future<bool> initSpeech() async {
    if (_isSpeechInitialized) return true;
    try {
      _isSpeechInitialized = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
        onError: (errorNotification) {
          _isListening = false;
          debugPrint('Speech recognition error: ${errorNotification.errorMsg}');
        },
      );
      return _isSpeechInitialized;
    } catch (e) {
      debugPrint('VoiceAssistantService initSpeech warning: $e');
      return false;
    }
  }

  /// Start voice input listening with language support
  Future<bool> startListening({
    required VoiceResultCallback onResult,
    VoiceStatusCallback? onStatusChange,
    String language = 'en',
  }) async {
    try {
      final available = await initSpeech();
      if (!available) return false;

      final localeId = language == 'hi' ? 'hi_IN' : 'en_IN';

      _isListening = true;
      onStatusChange?.call(true);

      await _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            onResult(result.recognizedWords);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: localeId,
          listenMode: stt.ListenMode.dictation,
          cancelOnError: true,
        ),
      );

      return true;
    } catch (e) {
      _isListening = false;
      onStatusChange?.call(false);
      debugPrint('Failed to start listening: $e');
      return false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    try {
      if (_isListening) {
        await _speech.stop();
        _isListening = false;
      }
    } catch (e) {
      debugPrint('Failed to stop listening: $e');
    }
  }

  /// Speak clinical advice aloud using Text-to-Speech
  Future<void> speak(String text, {String language = 'en'}) async {
    if (text.trim().isEmpty) return;
    try {
      await initTts();

      // Clean markdown symbols from speech text (remove asterisks, brackets, hash)
      final cleanText = text
          .replaceAll(RegExp(r'[*#_`~]'), '')
          .replaceAll(RegExp(r'\[.*?\]'), '')
          .trim();

      final languageCode = language == 'hi' ? 'hi-IN' : 'en-US';
      await _flutterTts.setLanguage(languageCode);

      _isPlayingAudio = true;
      await _flutterTts.speak(cleanText);
    } catch (e) {
      _isPlayingAudio = false;
      debugPrint('TTS speak warning: $e');
    }
  }

  /// Stop speech playback
  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
      _isPlayingAudio = false;
    } catch (e) {
      debugPrint('TTS stop warning: $e');
    }
  }
}
