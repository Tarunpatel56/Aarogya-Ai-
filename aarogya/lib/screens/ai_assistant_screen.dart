import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/ai_service.dart';
import '../services/image_picker_service.dart';
import '../services/voice_assistant_service.dart';
import '../models/ai_response_model.dart';
import 'ai/brain_mri_screen.dart';
import 'ai/lung_xray_screen.dart';
import 'ai/skin_analysis_screen.dart';
import 'ai/eye_analysis_screen.dart';
import 'ai/symptom_checker_screen.dart';
import 'ai/medical_report_analyzer_screen.dart';

class AIAssistantScreen extends StatefulWidget {
  final AiService? aiService;
  final ImagePickerService? imagePickerService;

  const AIAssistantScreen({
    super.key,
    this.aiService,
    this.imagePickerService,
  });

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  late final AiService _aiService;
  late final ImagePickerService _imagePickerService;
  bool _isHindi = false;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  PickedImageData? _attachedImage;
  String? _playingAudioMessageId;
  final Set<String> _bookmarkedMessageIds = <String>{};
  bool _isRecordingMic = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _lastFailedQuery;

  final List<Map<String, dynamic>> _messages = [
    {
      'id': '1',
      'isBot': true,
      'sender': 'Aarogya Health Assistant',
      'time': 'Just now',
      'textEn': 'Namaste! I am your Aarogya Health Assistant powered by Clinical AI. How can I assist you with your health questions or medication guidance today? You can ask in English or हिंदी.',
      'textHi': 'नमस्ते! मैं आपका आरोग्य स्वास्थ्य सहायक हूँ। आज मैं आपके स्वास्थ्य संबंधी प्रश्नों या दवा मार्गदर्शन में कैसे सहायता कर सकता हूँ? आप हिंदी या English में पूछ सकते हैं।',
      'verified': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _aiService = widget.aiService ?? AiService();
    _imagePickerService = widget.imagePickerService ?? ImagePickerService();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? retryText]) async {
    final text = retryText ?? _textController.text.trim();
    final attached = _attachedImage;

    if (text.isEmpty && attached == null && !_isLoading) return;

    final String query = text.isNotEmpty
        ? text
        : (_isHindi
            ? 'कृपया इस संलग्न मेडिकल दवा/पर्चे का विश्लेषण करें।'
            : 'Please review and analyze this attached medicine photo/prescription.');

    final Uint8List? imageBytesToSend = attached?.bytes;
    final String? imageNameToSend = attached?.name;

    if (retryText == null) {
      setState(() {
        _messages.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'isBot': false,
          'sender': 'You',
          'time': 'Just now',
          'text': query,
          'imageBytes': imageBytesToSend,
          'imageName': imageNameToSend,
        });
        _textController.clear();
        _attachedImage = null;
        _isLoading = true;
        _errorMessage = null;
        _lastFailedQuery = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    _scrollToBottom();

    try {
      final language = _isHindi ? 'hi' : 'en';

      if (imageBytesToSend != null) {
        // Direct Medicine Vision AI Analysis
        final med = await _aiService.analyzeMedicineImage(
          imageBytes: imageBytesToSend,
          filename: imageNameToSend ?? 'medicine_strip.jpg',
          language: language,
        );

        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _messages.add({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'isBot': true,
            'isGuidance': true,
            'isMedicineAnalysis': true,
            'medicineAnalysis': med,
            'sender': 'Aarogya Health Assistant',
            'time': 'Just now',
            'textEn': 'Here is the detailed analysis of ${med.medicineName}:',
            'textHi': 'यहाँ ${med.medicineName} का विस्तृत औषधीय विश्लेषण है:',
          });
        });
      } else {
        final response = await _aiService.sendChatMessage(
          message: query,
          language: language,
        );

        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _messages.add({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'isBot': true,
            'isGuidance': true,
            'sender': 'Aarogya Health Assistant',
            'time': 'Just now',
            'textEn': response.replyEn ?? response.reply,
            'textHi': response.replyHi ?? response.reply,
          });
        });
      }
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not get AI response. Please check your network and tap Retry.';
        _lastFailedQuery = query;
      });
      _scrollToBottom();
    }
  }

  void _retryLastMessage() {
    if (_lastFailedQuery != null) {
      _sendMessage(_lastFailedQuery);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Translate / Language Switcher
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.smart_toy_outlined,
                    color: AppColors.primaryTeal,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'AI Assistant',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildLanguageToggle(),
                ],
              ),
            ),
            const Divider(height: 1),
            _buildAiClinicalSuiteBar(),
            const Divider(height: 1),

            // Chat Feed
            Expanded(
              child: ListView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: [
                  ..._messages.map((msg) {
                    if (msg['isBot'] == true) {
                      if (msg['isGuidance'] == true) {
                        return _buildBotGuidanceMessage(msg);
                      }
                      return _buildBotWelcomeMessage(msg);
                    } else {
                      return _buildUserMessage(msg);
                    }
                  }),

                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cardBorder),
                              boxShadow: AppColors.cardShadow,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primaryTeal,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isHindi
                                      ? 'आरोग्य एआई उत्तर तैयार कर रहा है...'
                                      : 'Aarogya AI is thinking...',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFDC2626),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _retryLastMessage,
                            child: const Text(
                              'Retry',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Attached Image Preview
            _buildAttachedImagePreview(),

            // Bottom Input & Medical Disclaimer
            _buildChatInputBar(),
            if (!isKeyboardOpen) _buildBottomDisclaimer(),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageToggle() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isHindi = false),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: !_isHindi
                    ? AppColors.primaryTeal
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'English',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: !_isHindi
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _isHindi = true),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _isHindi
                    ? AppColors.primaryTeal
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'हिंदी',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: _isHindi
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotWelcomeMessage(Map<String, dynamic> msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.primaryTeal,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          msg['sender'],
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        msg['time'],
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isHindi ? msg['textHi'] : msg['textEn'],
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 14,
                            color: Color(0xFF10B981),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Clinical Assistant',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          final msgId = msg['id']?.toString() ?? '1';
                          final isPlaying = _playingAudioMessageId == msgId;
                          final textToSpeak = _isHindi
                              ? (msg['textHi'] ?? msg['text'] ?? '')
                              : (msg['textEn'] ?? msg['text'] ?? '');
                          if (isPlaying) {
                            VoiceAssistantService().stopSpeaking();
                            setState(() => _playingAudioMessageId = null);
                          } else {
                            VoiceAssistantService().speak(textToSpeak, language: _isHindi ? 'hi' : 'en');
                            setState(() => _playingAudioMessageId = msgId);
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _playingAudioMessageId == (msg['id']?.toString() ?? '1')
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_up_outlined,
                              size: 15,
                              color: AppColors.primaryTeal,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _playingAudioMessageId == (msg['id']?.toString() ?? '1') ? 'Playing...' : 'Listen',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryTeal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(Map<String, dynamic> msg) {
    final Uint8List? imageBytes = msg['imageBytes'] as Uint8List?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(
                  0xFF005B52,
                ), // Dark teal bubble from screenshot
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (imageBytes != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        imageBytes,
                        width: 180,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    msg['text'] ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg['time'] ?? 'Just now',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFCBD5E1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'You',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotGuidanceMessage(Map<String, dynamic> msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.primaryTeal,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          msg['sender'] ?? 'Aarogya Health Assistant',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        msg['time'] ?? 'Just now',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isHindi ? msg['textHi'] : msg['textEn'],
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                  if (msg['isMedicineAnalysis'] == true &&
                      msg['medicineAnalysis'] is AiMedicineAnalysis) ...[
                    const SizedBox(height: 8),
                    _buildMedicineDetailCard(
                        msg['medicineAnalysis'] as AiMedicineAnalysis),
                  ],
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          final msgId = msg['id']?.toString() ?? 'guidance';
                          final isPlaying = _playingAudioMessageId == msgId;
                          final textToSpeak = _isHindi
                              ? (msg['textHi'] ?? msg['replyHi'] ?? msg['text'] ?? '')
                              : (msg['textEn'] ?? msg['replyEn'] ?? msg['text'] ?? '');
                          if (isPlaying) {
                            VoiceAssistantService().stopSpeaking();
                            setState(() => _playingAudioMessageId = null);
                          } else {
                            VoiceAssistantService().speak(textToSpeak, language: _isHindi ? 'hi' : 'en');
                            setState(() => _playingAudioMessageId = msgId);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _playingAudioMessageId == (msg['id']?.toString() ?? 'guidance')
                                    ? Icons.pause_circle_outline_rounded
                                    : Icons.volume_up_outlined,
                                size: 14,
                                color: AppColors.primaryTeal,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _playingAudioMessageId == (msg['id']?.toString() ?? 'guidance')
                                    ? 'Playing (0:08)'
                                    : 'Listen (${_isHindi ? 'Hindi' : 'English'} • 0:14)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.translate_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _isHindi = !_isHindi;
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(
                          _bookmarkedMessageIds.contains(msg['id']?.toString() ?? 'guidance')
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 18,
                          color: _bookmarkedMessageIds.contains(msg['id']?.toString() ?? 'guidance')
                              ? AppColors.primaryTeal
                              : AppColors.textSecondary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          final msgId = msg['id']?.toString() ?? 'guidance';
                          final isBookmarked = _bookmarkedMessageIds.contains(msgId);
                          setState(() {
                            if (isBookmarked) {
                              _bookmarkedMessageIds.remove(msgId);
                            } else {
                              _bookmarkedMessageIds.add(msgId);
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                !isBookmarked
                                    ? 'Saved to health notes.'
                                    : 'Removed bookmark.',
                              ),
                              backgroundColor: AppColors.primaryTeal,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachedImagePreview() {
    final image = _attachedImage;
    if (image == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.memory(
              image.bytes,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  image.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${image.formattedSize} • ${_isHindi ? 'तस्वीर संलग्न' : 'Photo attached'}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Remove photo',
            onPressed: () {
              setState(() {
                _attachedImage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.camera_alt_outlined,
              color: AppColors.textSecondary,
              size: 22,
            ),
            tooltip: _isHindi ? 'फोटो जोड़ें' : 'Attach Photo',
            onPressed: _showPhotoSourceBottomSheet,
          ),
          IconButton(
            icon: Icon(
              _isRecordingMic ? Icons.mic : Icons.mic_none_outlined,
              color: _isRecordingMic
                  ? AppColors.sosRed
                  : AppColors.textSecondary,
              size: 22,
            ),
            tooltip: _isHindi ? 'आवाज से पूछें' : 'Voice Input',
            onPressed: _showVoiceInputDialog,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _textController,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: _isHindi
                    ? 'स्वास्थ्य समस्या या प्रश्न लिखें...'
                    : 'Type health query or symptom...',
                hintStyle: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFF00675B),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isHindi ? 'फोटो जोड़ें' : 'Attach Photo',
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // 1. Take Photo
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _pickImage(fromCamera: true);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: AppColors.primaryTeal,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isHindi ? 'फोटो खींचें (Take Photo)' : 'Take Photo',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isHindi ? 'कैमरा से सीधे तस्वीर लें' : 'Capture using device camera',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // 2. Upload Gallery
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _pickImage(fromCamera: false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.photo_library_rounded,
                            color: Color(0xFF0F766E),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isHindi ? 'गैलरी से अपलोड करें (Upload Gallery)' : 'Upload Gallery',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isHindi ? 'डिवाइस फोटो लाइब्रेरी से चुनें' : 'Choose image from gallery',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage({required bool fromCamera}) async {
    try {
      final picked = fromCamera
          ? await _imagePickerService.pickFromCamera()
          : await _imagePickerService.pickFromGallery();
      if (picked != null && mounted) {
        setState(() {
          _attachedImage = picked;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.sosRed,
          ),
        );
      }
    }
  }

  // Interactive Voice Input Assistant Modal
  void _showVoiceInputDialog() {
    setState(() => _isRecordingMic = true);
    final voiceTextController = TextEditingController(
      text: _textController.text.isNotEmpty ? _textController.text : '',
    );

    VoiceAssistantService().startListening(
      language: _isHindi ? 'hi' : 'en',
      onResult: (recognized) {
        voiceTextController.text = recognized;
      },
      onStatusChange: (listening) {
        if (mounted) setState(() => _isRecordingMic = listening);
      },
    );

    final List<String> suggestionsEn = [
      'Is Paracetamol safe with food?',
      'I have a headache, mild fever, and sore throat',
      'What are common side effects of Metformin?',
      'How to measure blood pressure and heart rate accurately?',
    ];

    final List<String> suggestionsHi = [
      'क्या पैरासिटामोल खाना खाने के बाद लेना सुरक्षित है?',
      'मुझे सिरदर्द, हल्का बुखार और गले में खराश है',
      'मेटफॉर्मिन के सामान्य दुष्प्रभाव क्या हैं?',
      'ब्लड प्रेशर और हृदय गति सही तरीके से कैसे मापें?',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final activeSuggestions = _isHindi ? suggestionsHi : suggestionsEn;

            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 18,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 18,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.sosRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isHindi ? 'आवाज से प्रश्न पूछें' : 'Voice Input Assistant',
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Animated Mic & Audio Waves
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryTeal.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.mic_rounded,
                                color: AppColors.primaryTeal,
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _isHindi
                                ? 'सुन रहा हूँ... बोलिए या सुझाव चुनें'
                                : 'Listening... Speak or choose a question',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(7, (index) {
                              final heights = [8.0, 16.0, 24.0, 14.0, 22.0, 12.0, 6.0];
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                width: 3,
                                height: heights[index],
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTeal,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: TextField(
                        controller: voiceTextController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: _isHindi
                              ? 'बोले गए शब्द यहाँ दिखेंगे...'
                              : 'Transcribed words will appear here...',
                          hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isHindi ? 'त्वरित आवाज सुझाव:' : 'Quick Voice Prompts:',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: activeSuggestions.map((suggestion) {
                        return ActionChip(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.cardBorder),
                          label: Text(
                            suggestion,
                            style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                          ),
                          onPressed: () {
                            setSheetState(() {
                              voiceTextController.text = suggestion;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.cardBorder),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              if (voiceTextController.text.trim().isNotEmpty) {
                                _textController.text = voiceTextController.text.trim();
                              }
                              Navigator.of(sheetContext).pop();
                            },
                            child: Text(
                              _isHindi ? 'चैट में डालें' : 'Use in Chat',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.send_rounded, size: 16),
                            label: Text(
                              _isHindi ? 'पूछें (Send)' : 'Ask Assistant',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              final text = voiceTextController.text.trim();
                              Navigator.of(sheetContext).pop();
                              if (text.isNotEmpty) {
                                _sendMessage(text);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      VoiceAssistantService().stopListening();
      if (mounted) {
        setState(() => _isRecordingMic = false);
      }
    });
  }

  // 6. Bottom Disclaimer
  Widget _buildBottomDisclaimer() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 4),
      child: const Text(
        'Aarogya AI provides clinical educational assistance, not emergency dispatch or prescription alterations.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 9.5,
          color: AppColors.textMuted,
          height: 1.3,
        ),
      ),
    );
  }

  // Rich Medicine Pharmacology & Pricing Card
  Widget _buildMedicineDetailCard(AiMedicineAnalysis med) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medicine Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.medication_rounded,
                    color: AppColors.primaryTeal, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.medicineName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (med.genericName != null &&
                        med.genericName!.isNotEmpty)
                      Text(
                        med.genericName!,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (med.strength != null)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              med.strength!,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6D28D9)),
                            ),
                          ),
                        if (med.manufacturer != null &&
                            med.manufacturer != 'Not visible on packaging')
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              med.manufacturer!,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Price & MRP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.currency_rupee_rounded,
                    size: 16, color: Color(0xFF059669)),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isHindi ? 'अनुमानित मूल्य / MRP' : 'Estimated Price / MRP',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF047857)),
                      ),
                      Text(
                        med.mrp != null &&
                                med.mrp != 'Not visible on packaging' &&
                                med.mrp != 'पैकेजिंग पर स्पष्ट नहीं'
                            ? '${med.mrp} (Est: ${med.estimatedPrice ?? "Market Standard"})'
                            : (med.estimatedPrice ?? '₹30 - ₹70 standard retail'),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065F46)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Uses (उपयोग)
          if (med.uses.isNotEmpty) ...[
            Text(
              _isHindi ? 'उपयोग (Uses):' : 'Key Medical Uses:',
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            ...med.uses.map((u) => Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ',
                          style: TextStyle(
                              color: Color(0xFF059669),
                              fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(u,
                            style: const TextStyle(
                                fontSize: 11.5, color: AppColors.textPrimary)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
          ],

          // Disadvantages / Side Effects (नुकसान / दुष्प्रभाव)
          if (med.disadvantages.isNotEmpty) ...[
            Text(
              _isHindi
                  ? 'नुकसान एवं दुष्प्रभाव (Disadvantages & Side Effects):'
                  : 'Disadvantages & Side Effects:',
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB45309)),
            ),
            const SizedBox(height: 4),
            ...med.disadvantages.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ',
                          style: TextStyle(
                              color: Color(0xFFD97706),
                              fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(d,
                            style: const TextStyle(
                                fontSize: 11.5, color: AppColors.textPrimary)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
          ],

          // What happens when taken (शरीर में क्या असर होता है)
          if (med.whatHappensWhenTaken != null &&
              med.whatHappensWhenTaken!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology_alt_outlined,
                          size: 14, color: Color(0xFF2563EB)),
                      const SizedBox(width: 6),
                      Text(
                        _isHindi
                            ? 'लेने से शरीर में क्या असर होगा (How it acts):'
                            : 'What Happens When Taken:',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D4ED8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    med.whatHappensWhenTaken!,
                    style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF1E3A8A),
                        height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Precautions (सावधानियां)
          if (med.precautions.isNotEmpty) ...[
            Text(
              _isHindi ? 'सावधानियां (Precautions):' : 'Clinical Precautions:',
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            ...med.precautions.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ',
                          style: TextStyle(
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(p,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 6),
          ],

          // Dosage Disclaimer Notice
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 13, color: Color(0xFFD97706)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    med.dosageGuideline ??
                        (_isHindi
                            ? 'आरोग्य एआई खुराक निर्धारित नहीं करता। सही खुराक के लिए डॉक्टर से परामर्श करें।'
                            : 'Dosage must be prescribed solely by a qualified physician.'),
                    style:
                        const TextStyle(fontSize: 10, color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiClinicalSuiteBar() {
    final suiteItems = [
      {
        'labelEn': 'Symptom Checker',
        'labelHi': 'लक्षण ट्राइएज',
        'icon': Icons.health_and_safety_outlined,
        'color': const Color(0xFF00796B),
        'screen': const SymptomCheckerScreen(),
      },
      {
        'labelEn': 'Lab Report AI',
        'labelHi': 'लैब रिपोर्ट',
        'icon': Icons.biotech_outlined,
        'color': const Color(0xFF0288D1),
        'screen': const MedicalReportAnalyzerScreen(),
      },
      {
        'labelEn': 'Eye Analyzer',
        'labelHi': 'नेत्र जांच',
        'icon': Icons.remove_red_eye_outlined,
        'color': const Color(0xFF00897B),
        'screen': const EyeAnalysisScreen(),
      },
      {
        'labelEn': 'Brain MRI',
        'labelHi': 'मस्तिष्क MRI',
        'icon': Icons.psychology_outlined,
        'color': const Color(0xFF5E35B1),
        'screen': const BrainMriScreen(),
      },
      {
        'labelEn': 'Chest X-Ray',
        'labelHi': 'छाती X-Ray',
        'icon': Icons.air_outlined,
        'color': const Color(0xFF1E88E5),
        'screen': const LungXrayScreen(),
      },
      {
        'labelEn': 'Dermatology',
        'labelHi': 'त्वचा जांच',
        'icon': Icons.water_drop_outlined,
        'color': const Color(0xFF8E24AA),
        'screen': const SkinAnalysisScreen(),
      },
    ];

    return Container(
      height: 48,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: suiteItems.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = suiteItems[i];
          final color = item['color'] as Color;
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => item['screen'] as Widget),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item['icon'] as IconData, size: 14, color: color),
                  const SizedBox(width: 5),
                  Text(
                    _isHindi ? item['labelHi'] as String : item['labelEn'] as String,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}