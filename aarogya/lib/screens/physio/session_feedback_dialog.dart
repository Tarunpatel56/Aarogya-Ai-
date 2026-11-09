import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/physiotherapy_model.dart';

class SessionFeedbackDialog extends StatefulWidget {
  final PhysioExercise exercise;
  final int durationSeconds;
  final int completedReps;

  const SessionFeedbackDialog({
    super.key,
    required this.exercise,
    required this.durationSeconds,
    required this.completedReps,
  });

  @override
  State<SessionFeedbackDialog> createState() => _SessionFeedbackDialogState();
}

class _SessionFeedbackDialogState extends State<SessionFeedbackDialog> {
  double _painRating = 1.0;
  SessionDifficulty _difficulty = SessionDifficulty.justRight;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _getPainDescription(int score) {
    if (score == 0) return '0 - No Pain (Comfortable)';
    if (score <= 3) return '$score - Mild Discomfort (Expected)';
    if (score <= 6) return '$score - Moderate Pain (Noticeable)';
    return '$score - Severe Pain (Review with Clinician)';
  }

  Color _getPainColor(int score) {
    if (score <= 2) return const Color(0xFF10B981);
    if (score <= 5) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.primaryTeal, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Session Completed!',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        widget.exercise.title,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Metrics Summary Tile
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${widget.durationSeconds}s',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                      ),
                      const Text('Duration', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  Container(width: 1, height: 26, color: AppColors.cardBorder),
                  Column(
                    children: [
                      Text(
                        '${widget.completedReps}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                      ),
                      const Text('Reps Completed', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Visual Analog Scale (VAS) Pain Feedback
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Post-Session Pain (VAS Scale)',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  _getPainDescription(_painRating.round()),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _getPainColor(_painRating.round())),
                ),
              ],
            ),
            Slider(
              value: _painRating,
              min: 0,
              max: 10,
              divisions: 10,
              activeColor: _getPainColor(_painRating.round()),
              onChanged: (val) {
                setState(() => _painRating = val);
              },
            ),
            const SizedBox(height: 14),

            // Difficulty Feedback
            const Text(
              'Perceived Difficulty',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildDifficultyChip(SessionDifficulty.tooEasy, 'Too Easy'),
                const SizedBox(width: 8),
                _buildDifficultyChip(SessionDifficulty.justRight, 'Just Right'),
                const SizedBox(width: 8),
                _buildDifficultyChip(SessionDifficulty.tooChallenging, 'Challenging'),
              ],
            ),
            const SizedBox(height: 16),

            // Notes
            const Text(
              'Symptom Notes (Optional)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Mild shoulder stiffness during rep 8...',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'painRating': _painRating.round(),
                    'difficulty': _difficulty,
                    'notes': _notesController.text.trim().isNotEmpty
                        ? _notesController.text.trim()
                        : null,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Save Session & Feedback', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(SessionDifficulty diff, String label) {
    final isSelected = _difficulty == diff;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _difficulty = diff),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryTeal : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppColors.primaryTeal : AppColors.cardBorder),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
