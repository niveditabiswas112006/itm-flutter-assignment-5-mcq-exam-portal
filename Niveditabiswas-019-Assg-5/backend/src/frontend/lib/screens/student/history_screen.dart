import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final list = await api.getStudentHistory();
      if (mounted) {
        setState(() {
          _history = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openPdf(String url) async {
    if (url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
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
                    const Text('My Exam History & Results', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.slate900)),
                    const SizedBox(height: 4),
                    Text('Review your previous attempts, grades, and Cloudinary PDF certificates.', style: TextStyle(color: AppColors.slate500, fontSize: 13)),
                  ],
                ),
                IconButton(onPressed: _fetchHistory, icon: const Icon(Icons.refresh)),
              ],
            ),
            const SizedBox(height: 20),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _history.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.history_toggle_off_outlined, size: 48, color: AppColors.slate400),
                              const SizedBox(height: 12),
                              const Text('No exam attempts found.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Attempt an exam from the Available Exams tab to see your records here.'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _history.length,
                          itemBuilder: (context, idx) {
                            final item = _history[idx];
                            final isPass = item['status'] == 'PASS';
                            final score = item['score'] ?? 0;
                            final total = item['totalMarks'] ?? 0;
                            final percent = (item['percentage'] as num?)?.toDouble() ?? 0.0;
                            final dateStr = item['submittedAt'] != null
                                ? DateTime.tryParse(item['submittedAt'])?.toLocal().toString().split('.')[0] ?? 'Recent'
                                : 'Recent';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: isPass ? AppColors.successLight : AppColors.errorLight,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          item['grade'] ?? (isPass ? 'A' : 'F'),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: isPass ? AppColors.success : AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['examTitle'] ?? 'MCQ Exam',
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.slate900),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Submitted on: $dateStr • Score: $score / $total (${percent.toStringAsFixed(1)}%)',
                                            style: const TextStyle(fontSize: 12, color: AppColors.slate600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Actions
                                    if (item['pdfUrl'] != null && item['pdfUrl'].toString().isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.picture_as_pdf, color: AppColors.error),
                                        tooltip: 'Download PDF',
                                        onPressed: () => _openPdf(item['pdfUrl'].toString()),
                                      ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ResultScreen(attemptId: item['attemptId'] ?? item['id']),
                                          ),
                                        );
                                      },
                                      child: const Text('View Analysis', style: TextStyle(fontSize: 12)),
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
}
