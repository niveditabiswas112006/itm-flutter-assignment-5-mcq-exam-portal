import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../models/exam_model.dart';
import 'create_exam_screen.dart';
import 'exam_list_screen.dart';
import 'students_list_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  List<ExamModel> _exams = [];
  int _studentCount = 0;
  int _totalAttempts = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    setState(() => _isLoading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final exams = await api.getAllExamsAdmin();
      final students = await api.getAllStudents();

      int attemptsSum = 0;
      for (var e in exams) {
        attemptsSum += e.totalAttempts;
      }

      if (mounted) {
        setState(() {
          _exams = exams;
          _studentCount = students.length;
          _totalAttempts = attemptsSum;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

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
              child: const Icon(Icons.dashboard_customize_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Admin Management Console', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadDashboardStats,
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    auth.user?.name ?? 'Admin',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate800),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => auth.logout(),
                    child: const Icon(Icons.logout, size: 16, color: AppColors.error),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar on Desktop
          if (isDesktop)
            Container(
              width: 240,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: AppColors.slate200)),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                children: [
                  _buildSidebarItem(0, 'Dashboard Overview', Icons.analytics_outlined),
                  _buildSidebarItem(1, 'All Exams', Icons.assignment_outlined),
                  _buildSidebarItem(2, 'Create New Exam', Icons.add_circle_outline),
                  _buildSidebarItem(3, 'Students Directory', Icons.people_alt_outlined),
                ],
              ),
            ),

          // Main View Content
          Expanded(
            child: _buildSelectedTab(),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (idx) => setState(() => _selectedIndex = idx),
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.slate400,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
                BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Exams'),
                BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Create'),
                BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Students'),
              ],
            ),
    );
  }

  Widget _buildSidebarItem(int index, String label, IconData icon) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: isSelected ? AppColors.primaryLight : Colors.transparent,
        leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.slate600, size: 20),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.slate800,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: () => setState(() => _selectedIndex = index),
      ),
    );
  }

  Widget _buildSelectedTab() {
    switch (_selectedIndex) {
      case 1:
        return const ExamListScreen();
      case 2:
        return CreateExamScreen(onExamCreated: () {
          _loadDashboardStats();
          setState(() => _selectedIndex = 1);
        });
      case 3:
        return const StudentsListScreen();
      case 0:
      default:
        return _buildOverview();
    }
  }

  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3730A3), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to Exam Management Hub 🎓',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Upload Excel question banks to Cloudinary, track submissions, and generate instant reports.',
                      style: TextStyle(color: Color(0xFFE0E7FF), fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                      ),
                      onPressed: () => setState(() => _selectedIndex = 2),
                      icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: const Text('Create New Exam via Excel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stat Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Total Exams', '${_exams.length}', Icons.assignment, AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('Total Submissions', '$_totalAttempts', Icons.fact_check, AppColors.success),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('Active Students', '$_studentCount', Icons.groups, AppColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Recent Exams Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Published Exams',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate900),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 1),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_exams.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.note_add_outlined, size: 48, color: AppColors.slate400),
                    const SizedBox(height: 12),
                    const Text(
                      'No exams created yet.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate700),
                    ),
                    const SizedBox(height: 6),
                    const Text('Upload your first Excel question sheet to get started!'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _selectedIndex = 2),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Create First Exam'),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _exams.take(5).length,
              itemBuilder: (context, idx) {
                final exam = _exams[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.quiz_outlined, color: AppColors.primary),
                    ),
                    title: Text(exam.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Text('${exam.totalQuestions} Questions • ${exam.durationMinutes} mins • ${exam.totalMarks} Marks'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: exam.isPublished ? AppColors.successLight : AppColors.slate100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            exam.isPublished ? 'Published' : 'Draft',
                            style: TextStyle(
                              color: exam.isPublished ? AppColors.success : AppColors.slate600,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, color: AppColors.slate400),
                      ],
                    ),
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, color: AppColors.slate500)),
              const SizedBox(height: 4),
              Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.slate900)),
            ],
          ),
        ],
      ),
    );
  }
}
