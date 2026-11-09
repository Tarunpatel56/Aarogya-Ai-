import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/appointment_model.dart';

class ConsultationRoomScreen extends StatefulWidget {
  final AppointmentModel appointment;

  const ConsultationRoomScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<ConsultationRoomScreen> createState() => _ConsultationRoomScreenState();
}

class _ConsultationRoomScreenState extends State<ConsultationRoomScreen> {
  bool _isMicMuted = false;
  bool _isVideoOff = false;
  bool _isFrontCamera = true;
  int _callSeconds = 0;
  Timer? _callTimer;

  final List<Map<String, String>> _consultationChat = [
    {
      'sender': 'Doctor',
      'text': 'Namaste! I am reviewing your recent health vitals and medical reports.',
      'time': '10:02 AM',
    },
  ];
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _callSeconds++);
      }
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  String get _formattedDuration {
    final minutes = (_callSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_callSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _sendChatMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _consultationChat.add({
        'sender': 'You',
        'text': text,
        'time': 'Just now',
      });
      _chatController.clear();
    });
  }

  void _openChatDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chat with ${widget.appointment.doctorName ?? "Doctor"}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 1),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _consultationChat.length,
                  itemBuilder: (ctx, i) {
                    final msg = _consultationChat[i];
                    final isMe = msg['sender'] == 'You';
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primaryTeal : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['text']!,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isMe ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      decoration: InputDecoration(
                        hintText: 'Type message to doctor...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.primaryTeal),
                    onPressed: () {
                      _sendChatMessage();
                      setSheetState(() {});
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPrescriptionReview() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Digital Prescription & Notes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doctor: ${widget.appointment.doctorName ?? "Doctor"}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Specialization: ${widget.appointment.doctorSpecialization ?? "General Physician"}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            const Text('Clinical Notes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              widget.appointment.doctorNotes ?? 'Preliminary consultation in progress. Final digital prescription will be synced to your Medical Records upon session completion.',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _endCall() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Consultation?'),
        content: const Text('Are you sure you want to end this live consultation session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Stay in Call')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('End Consultation', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            // Main Video Surface (Doctor view)
            Positioned.fill(
              child: Container(
                color: const Color(0xFF1E293B),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryTeal, width: 2),
                        ),
                        child: const Icon(Icons.person, size: 60, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.appointment.doctorName ?? 'Dr. Ananya Sharma',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.appointment.doctorSpecialization ?? 'Cardiologist • AIIMS New Delhi',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF15803D).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
                            const SizedBox(width: 6),
                            Text(
                              'LIVE • $_formattedDuration',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Patient Self Video Inset Preview (Top Right)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 100,
                height: 130,
                decoration: BoxDecoration(
                  color: _isVideoOff ? const Color(0xFF334155) : const Color(0xFF0F766E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 1.5),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
                ),
                child: Center(
                  child: _isVideoOff
                      ? const Icon(Icons.videocam_off, color: Colors.white54, size: 24)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.face, color: Colors.white, size: 30),
                            SizedBox(height: 4),
                            Text('You', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),
            ),

            // Top Header: Back & Prescription Review
            Positioned(
              top: 16,
              left: 16,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _endCall,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _openPrescriptionReview,
                    icon: const Icon(Icons.receipt_long, size: 14),
                    label: const Text('Prescription', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom In-Call Controls Bar
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mic Mute / Unmute
                    _buildRoundButton(
                      icon: _isMicMuted ? Icons.mic_off : Icons.mic,
                      color: _isMicMuted ? Colors.red : Colors.white24,
                      onTap: () => setState(() => _isMicMuted = !_isMicMuted),
                    ),

                    // Video Toggle
                    _buildRoundButton(
                      icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                      color: _isVideoOff ? Colors.red : Colors.white24,
                      onTap: () => setState(() => _isVideoOff = !_isVideoOff),
                    ),

                    // Flip Camera
                    _buildRoundButton(
                      icon: Icons.flip_camera_ios,
                      color: Colors.white24,
                      onTap: () => setState(() => _isFrontCamera = !_isFrontCamera),
                    ),

                    // Live Consultation Chat
                    _buildRoundButton(
                      icon: Icons.chat_bubble_outline,
                      color: Colors.white24,
                      onTap: _openChatDrawer,
                    ),

                    // End Call
                    _buildRoundButton(
                      icon: Icons.call_end,
                      color: const Color(0xFFDC2626),
                      onTap: _endCall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

