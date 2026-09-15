import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/exam_model.dart';
import '../../models/question_model.dart';
import '../../theme/app_theme.dart';
import 'result_screen.dart';

enum QuestionStatus {
  notVisited, // Gray
  notAnswered, // Red
  answered, // Green
  markedForReview, // Purple
}

class ExamScreen extends StatefulWidget {
  final String examId;
  final String examTitle;

  const ExamScreen({
    super.key,
    required this.examId,
    required this.examTitle,
  });

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  ExamModel? _exam;
  List<QuestionModel> _questions = [];
  int _currentIndex = 0;

  // Answers Map: { 'q_1': 'A', 'q_2': 'C' }
  final Map<String, String> _answers = {};

  // Review Status Map: { 'q_1': true }
  final Map<String, bool> _reviewFlags = {};

  // Visited Status Map: { 0: true, 1: true }
  final Set<int> _visitedIndices = {0};

  // Timer fields
  Timer? _timer;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  int _tabSwitchCount = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadExamData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (_exam?.antiCheating == true && !_isSubmitting) {
        setState(() => _tabSwitchCount++);
        _showAntiCheatingAlert();
      }
    }
  }

  void _showAntiCheatingAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ Tab switch or window blur detected! Total warnings: $_tabSwitchCount'),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _loadExamData() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final exam = await api.startExam(widget.examId);
      final durationMins = exam.durationMinutes > 0 ? exam.durationMinutes : 30;

      setState(() {
        _exam = exam;
        _questions = exam.questions;
        _remainingSeconds = durationMins * 60;
        _totalSeconds = _remainingSeconds;
        _isLoading = false;
      });

      _startTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load exam questions: $e'), backgroundColor: AppColors.error),
        );
        Navigator.pop(context);
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        _autoSubmitOnTimeout();
      }
    });
  }

  void _autoSubmitOnTimeout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏰ Time is up! Automatically submitting your answers...'),
        backgroundColor: AppColors.error,
      ),
    );
    _submitExamFinal();
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  QuestionStatus _getQuestionStatus(int index) {
    if (index >= _questions.length) return QuestionStatus.notVisited;
    final q = _questions[index];
    final isFlagged = _reviewFlags[q.id] == true;
    final hasAnswer = _answers.containsKey(q.id) && _answers[q.id]!.isNotEmpty;
    final isVisited = _visitedIndices.contains(index);

    if (isFlagged) return QuestionStatus.markedForReview;
    if (hasAnswer) return QuestionStatus.answered;
    if (isVisited) return QuestionStatus.notAnswered;
    return QuestionStatus.notVisited;
  }

  Color _getStatusColor(QuestionStatus status) {
    switch (status) {
      case QuestionStatus.answered:
        return AppColors.paletteAnswered; // Green
      case QuestionStatus.notAnswered:
        return AppColors.paletteNotAnswered; // Red
      case QuestionStatus.markedForReview:
        return AppColors.paletteReview; // Purple
      case QuestionStatus.notVisited:
        return AppColors.paletteNotVisited; // Gray
    }
  }

  void _selectQuestion(int index) {
    setState(() {
      _currentIndex = index;
      _visitedIndices.add(index);
    });
  }

  void _selectOption(String optionKey) {
    final q = _questions[_currentIndex];
    setState(() {
      _answers[q.id] = optionKey;
    });
  }

  void _clearResponse() {
    final q = _questions[_currentIndex];
    setState(() {
      _answers.remove(q.id);
    });
  }

  void _toggleReview() {
    final q = _questions[_currentIndex];
    setState(() {
      _reviewFlags[q.id] = !(_reviewFlags[q.id] ?? false);
    });
  }

  void _showSubmitConfirmation() {
    int answered = 0;
    int review = 0;
    int unanswered = 0;

    for (int i = 0; i < _questions.length; i++) {
      final status = _getQuestionStatus(i);
      if (status == QuestionStatus.answered) answered++;
      if (status == QuestionStatus.markedForReview) review++;
      if (status == QuestionStatus.notAnswered || status == QuestionStatus.notVisited) unanswered++;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Exam Submission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you ready to submit your exam? Here is your summary:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _summaryRow('Total Questions:', '${_questions.length}'),
                  _summaryRow('Answered:', '$answered', color: AppColors.paletteAnswered),
                  _summaryRow('Marked for Review:', '$review', color: AppColors.paletteReview),
                  _summaryRow('Unanswered:', '$unanswered', color: AppColors.paletteNotAnswered),
                  _summaryRow('Time Remaining:', _formatTime(_remainingSeconds)),
                  if (_tabSwitchCount > 0)
                    _summaryRow('Tab Switches:', '$_tabSwitchCount', color: AppColors.error),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue Exam'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              _submitExamFinal();
            },
            child: const Text('Yes, Submit Final'),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.slate700)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color ?? AppColors.slate900)),
        ],
      ),
    );
  }

  Future<void> _submitExamFinal() async {
    _timer?.cancel();
    setState(() => _isSubmitting = true);

    try {
      final timeTakenMins = ((_totalSeconds - _remainingSeconds) / 60.0);
      final api = Provider.of<ApiService>(context, listen: false);

      final result = await api.submitExam(
        examId: widget.examId,
        answers: _answers,
        timeTakenMinutes: timeTakenMins > 0 ? timeTakenMins : 0.5,
        tabSwitchCount: _tabSwitchCount,
      );

      if (!mounted) return;

      // Replace current screen with instant Result Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(attemptId: result.attemptId, preloadedResult: result),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e'), backgroundColor: AppColors.error),
        );
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

    final isDesktop = MediaQuery.of(context).size.width > 860;
    final currentQ = _questions[_currentIndex];
    final selectedOpt = _answers[currentQ.id];
    final isFlagged = _reviewFlags[currentQ.id] ?? false;
    final isTimeLow = _remainingSeconds < 300; // less than 5 mins

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.examTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          // Timer Widget
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isTimeLow ? AppColors.errorLight : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isTimeLow ? AppColors.error : AppColors.primary),
            ),
            child: Row(
              children: [
                Icon(Icons.alarm, size: 18, color: isTimeLow ? AppColors.error : AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  _formatTime(_remainingSeconds),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isTimeLow ? AppColors.error : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          // Submit Button in AppBar
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: _isSubmitting ? null : _showSubmitConfirmation,
              child: _isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit Exam'),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left: Question Viewer & Options
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Progress Bar
                LinearProgressIndicator(
                  value: _questions.isNotEmpty ? (_answers.length / _questions.length) : 0,
                  backgroundColor: AppColors.slate200,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 4,
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Question ${_currentIndex + 1} of ${_questions.length}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate800),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.successLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('+${currentQ.marks} Marks', style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                if (currentQ.negativeMarks > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('-${currentQ.negativeMarks} Neg', style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Question Body
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.slate200),
                          ),
                          child: Text(
                            currentQ.questionText,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.slate900, height: 1.4),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Options List
                        ...currentQ.options.entries.map((entry) {
                          final isSelected = selectedOpt == entry.key;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryLight : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.slate200,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: () => _selectOption(entry.key),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: isSelected ? AppColors.primary : AppColors.slate100,
                                      child: Text(
                                        entry.key,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : AppColors.slate700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          color: isSelected ? AppColors.primaryDark : AppColors.slate800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.slate200)),
                  ),
                  child: Row(
                    children: [
                      // Clear Response
                      if (selectedOpt != null)
                        TextButton(
                          onPressed: _clearResponse,
                          child: const Text('Clear Selection', style: TextStyle(color: AppColors.error)),
                        ),

                      // Mark for Review
                      if (_exam?.allowReview == true)
                        OutlinedButton.icon(
                          onPressed: _toggleReview,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: isFlagged ? AppColors.paletteReview : AppColors.slate200),
                            backgroundColor: isFlagged ? const Color(0xFFF3E8FF) : Colors.transparent,
                          ),
                          icon: Icon(
                            isFlagged ? Icons.bookmark : Icons.bookmark_border,
                            color: isFlagged ? AppColors.paletteReview : AppColors.slate600,
                            size: 16,
                          ),
                          label: Text(
                            isFlagged ? 'Flagged for Review' : 'Mark for Review',
                            style: TextStyle(color: isFlagged ? AppColors.paletteReview : AppColors.slate700),
                          ),
                        ),

                      const Spacer(),

                      // Previous Button
                      OutlinedButton(
                        onPressed: _currentIndex > 0 ? () => _selectQuestion(_currentIndex - 1) : null,
                        child: const Text('Previous'),
                      ),
                      const SizedBox(width: 10),

                      // Next / Submit Button
                      ElevatedButton(
                        onPressed: () {
                          if (_currentIndex < _questions.length - 1) {
                            _selectQuestion(_currentIndex + 1);
                          } else {
                            _showSubmitConfirmation();
                          }
                        },
                        child: Text(_currentIndex < _questions.length - 1 ? 'Next Question' : 'Review & Submit'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right: Question Palette (Desktop)
          if (isDesktop)
            Container(
              width: 300,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(left: BorderSide(color: AppColors.slate200)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.slate200)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Question Palette', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        // Legend
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            _legendItem(AppColors.paletteAnswered, 'Answered'),
                            _legendItem(AppColors.paletteNotAnswered, 'Not Answered'),
                            _legendItem(AppColors.paletteReview, 'For Review'),
                            _legendItem(AppColors.paletteNotVisited, 'Not Visited'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Palette Grid
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _questions.length,
                      itemBuilder: (context, idx) {
                        final status = _getQuestionStatus(idx);
                        final isCurrent = _currentIndex == idx;
                        final color = _getStatusColor(status);

                        return InkWell(
                          onTap: () => _selectQuestion(idx),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                              border: isCurrent ? Border.all(color: AppColors.slate900, width: 2.5) : null,
                              boxShadow: isCurrent ? [const BoxShadow(color: Color(0x33000000), blurRadius: 4)] : null,
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Widget _legendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: AppColors.slate600)),
      ],
    );
  }
}
