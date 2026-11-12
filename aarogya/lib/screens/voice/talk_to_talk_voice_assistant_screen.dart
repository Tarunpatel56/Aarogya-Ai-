import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../services/voice_assistant_service.dart';

enum VoiceModeState {
  idle,
  listening,
  thinking,
  speaking,
}

class TalkToTalkVoiceAssistantScreen extends StatefulWidget {
  final AiService? aiService;
  final VoiceAssistantService? voiceService;

  const TalkToTalkVoiceAssistantScreen({
    super.key,
    this.aiService,
    this.voiceService,
  });

  @override
  State<TalkToTalkVoiceAssistantScreen> createState() => _TalkToTalkVoiceAssistantScreenState();
}

class _TalkToTalkVoiceAssistantScreenState extends State<TalkToTalkVoiceAssistantScreen>
    with SingleTickerProviderStateMixin {
  late final AiService _aiService;
  late final VoiceAssistantService _voiceService;
  late AnimationController _pulseController;

  VoiceModeState _state = VoiceModeState.idle;
  String _selectedLanguage = 'auto'; // 'auto', 'hi', 'en'
  String _liveTranscription = '';
  String _lastUserSaid = '';
  String _lastAiReply = '';
  bool _continuousMode = true; // Auto listen after AI finishes speaking
  final List<Map<String, String>> _conversationHistory = [];

  @override
  void initState() {
    super.initState();
    _aiService = widget.aiService ?? AiService();
    _voiceService = widget.voiceService ?? VoiceAssistantService();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Initial greeting aloud after screen builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _greetUser();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _voiceService.stopListening();
    _voiceService.stopSpeaking();
    super.dispose();
  }

  Future<void> _greetUser() async {
    final greetingText = _selectedLanguage == 'hi'
        ? 'नमस्ते! मैं आरोग्य वॉइस असिस्टेंट हूँ। आप हिंदी या English में कुछ भी पूछ सकते हैं।'
        : 'Namaste! I am your Aarogya Voice Assistant. You can speak to me naturally in Hindi or English.';

    setState(() {
      _state = VoiceModeState.speaking;
      _lastAiReply = greetingText;
    });

    final langCode = _selectedLanguage == 'hi' ? 'hi' : 'en';
    await _voiceService.speak(
      greetingText,
      language: langCode,
      onComplete: () {
        if (mounted) {
          if (_continuousMode) {
            _startListening();
          } else {
            setState(() => _state = VoiceModeState.idle);
          }
        }
      },
    );
  }

  Future<void> _startListening() async {
    await _voiceService.stopSpeaking();

    setState(() {
      _state = VoiceModeState.listening;
      _liveTranscription = '';
    });

    final langCode = _selectedLanguage == 'hi' ? 'hi' : 'en';

    final started = await _voiceService.startListening(
      language: langCode,
      onResult: (words) {
        if (mounted) {
          setState(() {
            _liveTranscription = words;
          });
        }
      },
      onStatusChange: (isListening) {
        if (!isListening && mounted && _state == VoiceModeState.listening) {
          // Finished speaking, submit voice query if words captured
          if (_liveTranscription.trim().isNotEmpty) {
            _processVoiceQuery(_liveTranscription.trim());
          } else {
            setState(() => _state = VoiceModeState.idle);
          }
        }
      },
    );

    if (!started && mounted) {
      setState(() => _state = VoiceModeState.idle);
    }
  }

  Future<void> _stopListeningAndProcess() async {
    await _voiceService.stopListening();
    if (_liveTranscription.trim().isNotEmpty) {
      _processVoiceQuery(_liveTranscription.trim());
    } else {
      setState(() => _state = VoiceModeState.idle);
    }
  }

  Future<void> _processVoiceQuery(String userQuery) async {
    setState(() {
      _state = VoiceModeState.thinking;
      _lastUserSaid = userQuery;
      _liveTranscription = '';
    });

    // Detect language if 'auto'
    String effectiveLanguage = _selectedLanguage;
    if (effectiveLanguage == 'auto') {
      effectiveLanguage = _voiceService.isHindi(userQuery) ? 'hi' : 'en';
    }

    try {
      final aiResponse = await _aiService.sendChatMessage(
        message: userQuery,
        language: effectiveLanguage,
        history: _conversationHistory,
      );

      final reply = effectiveLanguage == 'hi'
          ? (aiResponse.replyHi ?? aiResponse.reply)
          : (aiResponse.replyEn ?? aiResponse.reply);

      // Save into short conversation memory
      _conversationHistory.add({'role': 'user', 'content': userQuery});
      _conversationHistory.add({'role': 'assistant', 'content': reply});
      if (_conversationHistory.length > 8) {
        _conversationHistory.removeRange(0, 2);
      }

      if (mounted) {
        setState(() {
          _state = VoiceModeState.speaking;
          _lastAiReply = reply;
        });

        await _voiceService.speak(
          reply,
          language: effectiveLanguage,
          onComplete: () {
            if (mounted) {
              if (_continuousMode) {
                _startListening();
              } else {
                setState(() => _state = VoiceModeState.idle);
              }
            }
          },
        );
      }
    } catch (_) {
      if (mounted) {
        final fallback = effectiveLanguage == 'hi'
            ? 'क्षमा करें, आपके प्रश्न का विश्लेषण करने में कठिनाई हुई। कृपया पुनः बोलें।'
            : 'I am having trouble analyzing your request. Please speak again.';

        setState(() {
          _state = VoiceModeState.speaking;
          _lastAiReply = fallback;
        });

        await _voiceService.speak(
          fallback,
          language: effectiveLanguage,
          onComplete: () {
            if (mounted) setState(() => _state = VoiceModeState.idle);
          },
        );
      }
    }
  }

  void _interrupt() {
    _voiceService.stopSpeaking();
    _voiceService.stopListening();
    setState(() => _state = VoiceModeState.idle);
  }

  void _onOrbTapped() {
    if (_state == VoiceModeState.listening) {
      _stopListeningAndProcess();
    } else if (_state == VoiceModeState.speaking) {
      _interrupt();
    } else if (_state == VoiceModeState.thinking) {
      _interrupt();
    } else {
      _startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF041C1A), // Deep Sanctuary Teal Night
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Column(
          children: const [
            Text(
              'Aarogya Live Voice AI',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
            ),
            Text(
              '100% Talk-to-Talk • Hindi & English',
              style: TextStyle(fontSize: 11, color: Color(0xFF80CBC4)),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Reset Conversation',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () {
              _interrupt();
              _conversationHistory.clear();
              setState(() {
                _lastUserSaid = '';
                _lastAiReply = '';
              });
              _greetUser();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Language Selector Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLangChip('auto', 'Auto (हिंदी + Eng)'),
                    _buildLangChip('hi', 'हिंदी'),
                    _buildLangChip('en', 'English'),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Center: The Living Voice Orb (Waveform / Breathing Pulse)
            GestureDetector(
              onTap: _onOrbTapped,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  double scale = 1.0;
                  Color orbColor = const Color(0xFF00897B);
                  Color ringColor = const Color(0xFF80CBC4).withValues(alpha: 0.25);

                  if (_state == VoiceModeState.listening) {
                    scale = 1.0 + (_pulseController.value * 0.18);
                    orbColor = const Color(0xFF00BFA5);
                    ringColor = const Color(0xFF00E676).withValues(alpha: 0.35);
                  } else if (_state == VoiceModeState.thinking) {
                    scale = 1.0 + (_pulseController.value * 0.08);
                    orbColor = const Color(0xFF0284C7);
                    ringColor = const Color(0xFF38BDF8).withValues(alpha: 0.3);
                  } else if (_state == VoiceModeState.speaking) {
                    scale = 1.0 + (_pulseController.value * 0.22);
                    orbColor = const Color(0xFF0F766E);
                    ringColor = const Color(0xFF5EEAD4).withValues(alpha: 0.4);
                  }

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Pulsing Halo Ring 2
                      Container(
                        width: 220 * scale,
                        height: 220 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ringColor,
                        ),
                      ),
                      // Outer Pulsing Halo Ring 1
                      Container(
                        width: 170 * (scale * 0.95),
                        height: 170 * (scale * 0.95),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ringColor.withValues(alpha: 0.5),
                        ),
                      ),
                      // Core Living Orb
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white,
                              orbColor,
                              orbColor.withValues(alpha: 0.8),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: orbColor.withValues(alpha: 0.6),
                              blurRadius: 32,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _state == VoiceModeState.listening
                                ? Icons.mic_rounded
                                : (_state == VoiceModeState.thinking
                                    ? Icons.hourglass_top_rounded
                                    : (_state == VoiceModeState.speaking
                                        ? Icons.volume_up_rounded
                                        : Icons.mic_none_rounded)),
                            color: const Color(0xFF041C1A),
                            size: 48,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Live State Subtitle
            Text(
              _getStateStatusText(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _state == VoiceModeState.listening
                  ? 'Speak freely in your own language...'
                  : (_state == VoiceModeState.speaking
                      ? 'Tap orb to pause / interrupt'
                      : 'Tap orb to speak'),
              style: const TextStyle(fontSize: 12, color: Color(0xFF80CBC4)),
            ),

            const Spacer(),

            // Real-time Captions / Subtitle Card (What was said & What was replied)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_state == VoiceModeState.listening && _liveTranscription.isNotEmpty) ...[
                    Row(
                      children: const [
                        Icon(Icons.record_voice_over_rounded, color: Color(0xFF00E676), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'You are saying:',
                          style: TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _liveTranscription,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ] else if (_lastUserSaid.isNotEmpty) ...[
                    Row(
                      children: const [
                        Icon(Icons.person_outline_rounded, color: Color(0xFF80CBC4), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'You said:',
                          style: TextStyle(color: Color(0xFF80CBC4), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _lastUserSaid,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (_lastAiReply.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: const [
                        Icon(Icons.health_and_safety_rounded, color: Color(0xFF5EEAD4), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Aarogya Clinical Advice:',
                          style: TextStyle(color: Color(0xFF5EEAD4), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _lastAiReply,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.3),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Bottom Continuous Mode & Mute Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: _continuousMode,
                          activeThumbColor: const Color(0xFF00BFA5),
                          activeTrackColor: const Color(0xFF00897B),
                          onChanged: (val) {
                            setState(() => _continuousMode = val);
                          },
                        ),
                        const SizedBox(width: 4),
                        const Flexible(
                          child: Text(
                            'Continuous Talk Mode',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_state == VoiceModeState.speaking)
                    TextButton.icon(
                      onPressed: _interrupt,
                      icon: const Icon(Icons.stop_circle_outlined, color: Color(0xFFEF4444)),
                      label: const Text('Stop Audio', style: TextStyle(color: Color(0xFFEF4444))),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangChip(String code, String label) {
    final isSel = _selectedLanguage == code;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedLanguage = code);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF00897B) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _getStateStatusText() {
    switch (_state) {
      case VoiceModeState.listening:
        return _selectedLanguage == 'hi' ? 'सुन रहा हूँ... बोलिए' : 'Listening... Speak now';
      case VoiceModeState.thinking:
        return _selectedLanguage == 'hi' ? 'सोच रहा हूँ...' : 'Analyzing clinical guidance...';
      case VoiceModeState.speaking:
        return _selectedLanguage == 'hi' ? 'आरोग्य बोल रहा है...' : 'Aarogya is speaking...';
      case VoiceModeState.idle:
        return _selectedLanguage == 'hi' ? 'बोलने के लिए माइक दबाएं' : 'Tap to start conversation';
    }
  }
}
