import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/exam_model.dart';
import '../../theme/app_theme.dart';
import 'exam_report_screen.dart';

class ExamListScreen extends StatefulWidget {
  const ExamListScreen({super.key});

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  bool _isLoading = true;
  List<ExamModel> _exams = [];

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    setState(() => _isLoading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final list = await api.getAllExamsAdmin();
      if (mounted) {
        setState(() {
          _exams = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteExam(String examId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exam'),
        content: const Text('Are you sure you want to delete this exam? All associated student attempts and Cloudinary files will be cleaned up.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final api = Provider.of<ApiService>(context, listen: false);
        await api.deleteExam(examId);
        _fetchExams();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exam deleted successfully.'), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting exam: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  void _showQuestionsModal(ExamModel exam) async {
    final api = Provider.of<ApiService>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<ExamModel>(
        future: api.getExamById(exam.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final fullExam = snapshot.data!;
          return AlertDialog(
            title: Text('Question Bank: ${fullExam.title}'),
            content: SizedBox(
              width: 600,
              height: 450,
              child: ListView.builder(
                itemCount: fullExam.questions.length,
                itemBuilder: (context, idx) {
                  final q = fullExam.questions[idx];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Q${idx + 1}: ${q.questionText}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          ...q.options.entries.map((e) => Text(
                                '${e.key}) ${e.value} ${e.key == q.correctOption ? '✅ (Correct)' : ''}',
                                style: TextStyle(
                                  color: e.key == q.correctOption ? AppColors.success : AppColors.slate700,
                                  fontWeight: e.key == q.correctOption ? FontWeight.bold : FontWeight.normal,
                                ),
                              )),
                          if (q.explanation.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('💡 ${q.explanation}', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Exam Repository', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.slate900)),
                    const SizedBox(height: 4),
                    Text('Manage all uploaded MCQ exams and view student performance reports.', style: TextStyle(color: AppColors.slate500, fontSize: 13)),
                  ],
                ),
                IconButton(
                  onPressed: _fetchExams,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh list',
                ),
              ],
            ),
            const SizedBox(height: 20),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _exams.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.assignment_late_outlined, size: 48, color: AppColors.slate400),
                              const SizedBox(height: 12),
                              const Text('No exams found.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Upload an Excel sheet to create your first exam.'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _exams.length,
                          itemBuilder: (context, idx) {
                            final exam = _exams[idx];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            exam.title,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate900),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: exam.isPublished ? AppColors.successLight : AppColors.slate100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            exam.isPublished ? 'Active' : 'Unpublished',
                                            style: TextStyle(
                                              color: exam.isPublished ? AppColors.success : AppColors.slate600,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (exam.description.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(exam.description, style: const TextStyle(fontSize: 13, color: AppColors.slate600)),
                                    ],
                                    const SizedBox(height: 12),

                                    // Metrics Badges
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 8,
                                      children: [
                                        _badge(Icons.help_outline, '${exam.totalQuestions} Questions'),
                                        _badge(Icons.timer_outlined, '${exam.durationMinutes} Minutes'),
                                        _badge(Icons.grade_outlined, '${exam.totalMarks} Total Marks'),
                                        _badge(Icons.people_outline, '${exam.totalAttempts} Submissions'),
                                        if (exam.excelUrl.isNotEmpty)
                                          _badge(Icons.cloud_done_outlined, 'Excel on Cloudinary', color: AppColors.primary),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const Divider(color: AppColors.slate200),
                                    const SizedBox(height: 8),

                                    // Actions
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _showQuestionsModal(exam),
                                          icon: const Icon(Icons.list_alt, size: 16),
                                          label: const Text('Questions'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ExamReportScreen(examId: exam.id, examTitle: exam.title),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.bar_chart, size: 16),
                                          label: const Text('View Report & Analytics'),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () => _deleteExam(exam.id),
                                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                          tooltip: 'Delete Exam',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String text, {Color? color}) {
    final c = color ?? AppColors.slate600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c)),
        ],
      ),
    );
  }
}
