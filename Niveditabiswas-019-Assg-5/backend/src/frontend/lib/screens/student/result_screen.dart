import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../models/attempt_model.dart';
import '../../theme/app_theme.dart';

class ResultScreen extends StatefulWidget {
  final String attemptId;
  final AttemptResultModel? preloadedResult;

  const ResultScreen({
    super.key,
    required this.attemptId,
    this.preloadedResult,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = false;
  AttemptResultModel? _result;

  @override
  void initState() {
    super.initState();
    if (widget.preloadedResult != null) {
      _result = widget.preloadedResult;
    } else {
      _fetchResult();
    }
  }

  Future<void> _fetchResult() async {
    setState(() => _isLoading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final res = await api.getResult(widget.attemptId);
      if (mounted) {
        setState(() {
          _result = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _downloadPdf() async {
    if (_result?.pdfUrl.isNotEmpty == true) {
      final uri = Uri.parse(_result!.pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF Link: ${_result!.pdfUrl}'), backgroundColor: AppColors.info),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exam Result')),
        body: const Center(child: Text('Result not found.')),
      );
    }

    final res = _result!;
    final isPass = res.isPass;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Scorecard & Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Return to Dashboard',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score Banner Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPass
                      ? [const Color(0xFF065F46), const Color(0xFF059669)]
                      : [const Color(0xFF991B1B), const Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPass ? '🎉 EXAMINATION PASSED' : '⚠️ EXAMINATION FAILED',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    res.examTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Main Score Big Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        res.score.toStringAsFixed(res.score.truncateToDouble() == res.score ? 0 : 1),
                        style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ' / ${res.totalMarks.toStringAsFixed(0)}',
                        style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Percentage: ${res.percentage.toStringAsFixed(1)}%  •  Grade: ${res.grade}',
                    style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),

                  // PDF Download Action
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: isPass ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: _downloadPdf,
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('Download Official Result Card (PDF)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Performance Breakdown Stats
            Row(
              children: [
                Expanded(
                  child: _metricCard('Correct', '${res.correctCount}', Icons.check_circle, AppColors.success),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metricCard('Wrong', '${res.wrongCount}', Icons.cancel, AppColors.error),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metricCard('Unattempted', '${res.unattemptedCount}', Icons.help_outline, AppColors.slate500),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metricCard('Accuracy', '${res.accuracy.toStringAsFixed(0)}%', Icons.pie_chart_outline, AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Question-by-Question Review Header
            const Text(
              'Question-by-Question Detailed Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate900),
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: res.questionReview.length,
              itemBuilder: (context, idx) {
                final q = res.questionReview[idx];
                final isCorrect = q.status == 'CORRECT';
                final isWrong = q.status == 'WRONG';

                final statusColor = isCorrect
                    ? AppColors.success
                    : isWrong
                        ? AppColors.error
                        : AppColors.slate500;

                final statusBg = isCorrect
                    ? AppColors.successLight
                    : isWrong
                        ? AppColors.errorLight
                        : AppColors.slate100;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Question ${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              isCorrect
                                  ? '+${q.marksAwarded} Marks (Correct)'
                                  : isWrong
                                      ? '${q.marksAwarded} Marks (Wrong)'
                                      : '0 Marks (Unattempted)',
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(q.questionText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.slate900)),
                      const SizedBox(height: 14),

                      // Options
                      ...q.options.entries.map((entry) {
                        final isStudentPick = q.studentAnswer == entry.key;
                        final isRightPick = q.correctOption == entry.key;

                        Color optBg = Colors.transparent;
                        Color optBorder = AppColors.slate200;
                        Color textColor = AppColors.slate700;

                        if (isRightPick) {
                          optBg = AppColors.successLight;
                          optBorder = AppColors.success;
                          textColor = AppColors.success;
                        } else if (isStudentPick && !isRightPick) {
                          optBg = AppColors.errorLight;
                          optBorder = AppColors.error;
                          textColor = AppColors.error;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: optBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: optBorder),
                          ),
                          child: Row(
                            children: [
                              Text('${entry.key})', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(entry.value, style: TextStyle(color: textColor))),
                              if (isRightPick)
                                const Text('✅ Correct Answer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success)),
                              if (isStudentPick && !isRightPick)
                                const Text('❌ Your Answer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.error)),
                            ],
                          ),
                        );
                      }),

                      if (q.explanation.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('💡', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Explanation: ${q.explanation}',
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.slate700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
        ],
      ),
    );
  }
}
