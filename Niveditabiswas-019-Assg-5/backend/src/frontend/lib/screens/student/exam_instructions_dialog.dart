import 'package:flutter/material.dart';
import '../../models/exam_model.dart';
import '../../theme/app_theme.dart';
import 'exam_screen.dart';

class ExamInstructionsDialog extends StatelessWidget {
  final ExamModel exam;
  final VoidCallback? onExamFinished;

  const ExamInstructionsDialog({
    super.key,
    required this.exam,
    this.onExamFinished,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exam.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text('Exam Guidelines & Instructions', style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Exam Info Grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoTile('Questions', '${exam.totalQuestions}'),
                  _infoTile('Duration', '${exam.durationMinutes} mins'),
                  _infoTile('Total Marks', '${exam.totalMarks}'),
                  _infoTile('Pass %', '${exam.passingPercentage}%'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('Important Instructions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            _instructionBullet('The timer starts immediately after clicking "Start Now". It will auto-submit when time expires.'),
            _instructionBullet('Use the Question Palette on the right/bottom to jump between questions.'),
            _instructionBullet('Color codes: Green (Answered), Red (Not Answered), Purple (Marked for Review), Gray (Not Visited).'),
            _instructionBullet('Negative marks are deducted for incorrect answers as specified in the question header.'),
            if (exam.antiCheating)
              _instructionBullet('Anti-Cheating is ENABLED: Switching browser tabs or minimizing the app is logged and may trigger auto-submission.', isWarning: true),

            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExamScreen(examId: exam.id, examTitle: exam.title),
                      ),
                    ).then((_) {
                      onExamFinished?.call();
                    });
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('I Understand, Start Exam'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate900)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
      ],
    );
  }

  Widget _instructionBullet(String text, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isWarning ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            size: 16,
            color: isWarning ? AppColors.warning : AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                color: isWarning ? const Color(0xFFB45309) : AppColors.slate700,
                fontWeight: isWarning ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
