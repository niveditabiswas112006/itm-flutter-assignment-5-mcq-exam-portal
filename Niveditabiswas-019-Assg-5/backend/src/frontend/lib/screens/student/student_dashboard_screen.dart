import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/exam_model.dart';
import '../../theme/app_theme.dart';
import 'exam_instructions_dialog.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'result_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _currentTab = 0;
  bool _isLoading = true;
  List<ExamModel> _availableExams = [];

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    setState(() => _isLoading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final list = await api.getAvailableExamsStudent();
      if (mounted) {
        setState(() {
          _availableExams = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onStartExam(ExamModel exam) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ExamInstructionsDialog(
        exam: exam,
        onExamFinished: () => _fetchExams(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('ITM Student Exam Portal', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchExams,
            tooltip: 'Refresh Exams',
          ),
          InkWell(
            onTap: () => setState(() => _currentTab = 2),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: user?.photoUrl.isNotEmpty == true ? NetworkImage(user!.photoUrl) : null,
                    child: user?.photoUrl.isEmpty == true
                        ? Text(
                            user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'S',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(user?.name ?? 'Student', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error, size: 20),
            onPressed: () => auth.logout(),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (idx) => setState(() => _currentTab = idx),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.slate400,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Available Exams'),
          BottomNavigationBarItem(icon: Icon(Icons.history_edu), label: 'My Results & History'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'My Profile'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentTab) {
      case 1:
        return const HistoryScreen();
      case 2:
        return const ProfileScreen();
      case 0:
      default:
        return _buildAvailableExamsView();
    }
  }

  Widget _buildAvailableExamsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF334155)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to Your Online Exam Hub 🎯',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Take timed MCQ exams, get instant auto-graded results, and download official PDF certificates.',
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          const Text(
            'Available Examinations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate900),
          ),
          const SizedBox(height: 12),

          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (_availableExams.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate200),
              ),
              child: const Column(
                children: [
                  Icon(Icons.event_busy, size: 48, color: AppColors.slate400),
                  SizedBox(height: 12),
                  Text('No active exams available at the moment.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate700)),
                  SizedBox(height: 4),
                  Text('Please check back later or contact your instructor.', style: TextStyle(color: AppColors.slate500)),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _availableExams.length,
              itemBuilder: (context, idx) {
                final exam = _availableExams[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                exam.title,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.slate900),
                              ),
                            ),
                            if (exam.isAttempted)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.successLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Completed',
                                  style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                          ],
                        ),
                        if (exam.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(exam.description, style: const TextStyle(color: AppColors.slate600, fontSize: 13)),
                        ],
                        const SizedBox(height: 14),

                        // Badges
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _examBadge(Icons.timer_outlined, '${exam.durationMinutes} Minutes'),
                            _examBadge(Icons.help_outline, '${exam.totalQuestions} Questions'),
                            _examBadge(Icons.military_tech_outlined, '${exam.totalMarks} Marks'),
                            _examBadge(Icons.percent_outlined, 'Pass: ${exam.passingPercentage}%'),
                            if (exam.antiCheating)
                              _examBadge(Icons.security, 'Anti-Cheating Enabled', color: AppColors.warning),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.slate200),
                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (exam.isAttempted && exam.lastAttemptId != null)
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ResultScreen(attemptId: exam.lastAttemptId!),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.receipt_long, size: 16),
                                label: Text('View Result (Score: ${exam.lastScore ?? 0})'),
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: () => _onStartExam(exam),
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Start Examination'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _examBadge(IconData icon, String text, {Color? color}) {
    final c = color ?? AppColors.slate600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c)),
        ],
      ),
    );
  }
}
