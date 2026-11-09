import 'package:flutter/material.dart';

class PostureAlertCard extends StatelessWidget {
  final String message;
  final bool isError;
  final bool isAudioEnabled;
  final VoidCallback? onToggleAudio;

  const PostureAlertCard({
    super.key,
    required this.message,
    this.isError = false,
    this.isAudioEnabled = true,
    this.onToggleAudio,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();

    final bgColor = isError
        ? const Color(0xFFDC2626).withValues(alpha: 0.90) // Red warning
        : const Color(0xFF0F172A).withValues(alpha: 0.88); // Dark Teal/Navy guidance

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isError ? const Color(0xFFFCA5A5) : Colors.white.withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.warning_amber_rounded : Icons.record_voice_over_rounded,
            color: isError ? Colors.white : const Color(0xFF00E5FF),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
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

