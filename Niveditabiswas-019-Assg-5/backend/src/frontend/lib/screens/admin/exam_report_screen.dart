import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ExamReportScreen extends StatefulWidget {
  final String examId;
  final String examTitle;

  const ExamReportScreen({
    super.key,
    required this.examId,
    required this.examTitle,
  });

  @override
  State<ExamReportScreen> createState() => _ExamReportScreenState();
}

class _ExamReportScreenState extends State<ExamReportScreen> {
  bool _isLoading = true;
  bool _isExporting = false;
  Map<String, dynamic>? _reportData;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final data = await api.getExamReport(widget.examId);
      if (mounted) {
        setState(() {
          _reportData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportReport() async {
    setState(() => _isExporting = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final downloadUrl = await api.exportExamReport(widget.examId, format: 'excel');

      if (downloadUrl.isNotEmpty) {
        final uri = Uri.parse(downloadUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Report exported to Cloudinary: $downloadUrl'),
              backgroundColor: AppColors.success,
              action: SnackBarAction(
                label: 'Open',
                textColor: Colors.white,
                onPressed: () => launchUrl(uri),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _reportData?['summary'] ?? {};
    final List toppers = _reportData?['topperList'] ?? [];
    final List students = _reportData?['students'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Exam Analytics & Report: ${widget.examTitle}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchReport,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportReport,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              icon: _isExporting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.download, size: 16),
              label: const Text('Export Excel to Cloudinary'),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Cards
                  Row(
                    children: [
                      Expanded(
                        child: _kpiCard('Total Attempts', '${summary['totalAttempts'] ?? 0}', Icons.people, AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _kpiCard('Pass Percentage', '${summary['passPercentage'] ?? 0}%', Icons.check_circle_outline, AppColors.success),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _kpiCard('Average Score', '${summary['averageScore'] ?? 0}', Icons.timeline, AppColors.secondary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _kpiCard('Highest Score', '${summary['highestScore'] ?? 0}', Icons.emoji_events_outlined, AppColors.warning),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Topper Leaderboard Section
                  if (toppers.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.military_tech, color: AppColors.warning),
                              SizedBox(width: 8),
                              Text('Topper Leaderboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            children: toppers.take(3).toList().asMap().entries.map((entry) {
                              final rank = entry.key + 1;
                              final student = entry.value;
                              final rankColor = rank == 1
                                  ? const Color(0xFFEAB308)
                                  : rank == 2
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFFB45309);

                              return Container(
                                width: 260,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.slate100.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: rankColor.withOpacity(0.5)),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: rankColor,
                                      child: Text('#$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(student['studentName'] ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          Text('Score: ${student['score']} • ${student['percentage']?.toStringAsFixed(1) ?? student['percentage']}%',
                                              style: const TextStyle(fontSize: 12, color: AppColors.slate600)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Student Performance Table
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Detailed Student Submissions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        if (students.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: Text('No student submissions yet for this exam.')),
                          )
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(AppColors.slate100),
                              columns: const [
                                DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Score', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Percentage', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Time Taken', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Submitted At', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: students.map((att) {
                                final isPass = att['status'] == 'PASS';
                                return DataRow(
                                  cells: [
                                    DataCell(Text(att['studentName'] ?? 'Student', style: const TextStyle(fontWeight: FontWeight.w600))),
                                    DataCell(Text(att['studentEmail'] ?? 'N/A')),
                                    DataCell(Text('${att['score']} / ${att['totalMarks']}')),
                                    DataCell(Text('${(att['percentage'] as num?)?.toStringAsFixed(1) ?? att['percentage']}%')),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isPass ? AppColors.successLight : AppColors.errorLight,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          att['status'] ?? 'FAIL',
                                          style: TextStyle(
                                            color: isPass ? AppColors.success : AppColors.error,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text('${att['timeTakenMinutes'] ?? 0} mins')),
                                    DataCell(Text(DateTime.tryParse(att['submittedAt'] ?? '')?.toLocal().toString().split('.')[0] ?? 'N/A')),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
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
              Text(title, style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.slate900)),
            ],
          ),
        ],
      ),
    );
  }
}
