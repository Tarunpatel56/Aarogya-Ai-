import 'package:flutter/material.dart';

class PostureAlertCard extends StatelessWidget {
  final String message;
  final bool isError;
  final bool isGoodPosture;
  final bool isAudioEnabled;
  final VoidCallback? onToggleAudio;

  const PostureAlertCard({
    super.key,
    required this.message,
    this.isError = false,
    this.isGoodPosture = false,
    this.isAudioEnabled = true,
    this.onToggleAudio,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();

    final Color bgColor;
    final Color borderColor;
    final IconData iconData;
    final Color iconColor;

    if (isError) {
      bgColor = const Color(0xFFDC2626).withValues(alpha: 0.92); // Vivid Red
      borderColor = const Color(0xFFFCA5A5);
      iconData = Icons.warning_amber_rounded;
      iconColor = Colors.white;
    } else if (isGoodPosture) {
      bgColor = const Color(0xFF15803D).withValues(alpha: 0.92); // Clinical Emerald Green
      borderColor = const Color(0xFF86EFAC);
      iconData = Icons.check_circle_rounded;
      iconColor = const Color(0xFF86EFAC);
    } else {
      bgColor = const Color(0xFF0F172A).withValues(alpha: 0.88); // Dark Slate/Navy
      borderColor = Colors.white.withValues(alpha: 0.2);
      iconData = Icons.record_voice_over_rounded;
      iconColor = const Color(0xFF00E5FF);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            iconData,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (onToggleAudio != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onToggleAudio,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  isAudioEnabled ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

