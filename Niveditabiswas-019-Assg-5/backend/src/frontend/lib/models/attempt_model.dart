class QuestionReviewItem {
  final String id;
  final int questionNumber;
  final String questionText;
  final Map<String, String> options;
  final String studentAnswer;
  final String correctOption;
  final String status; // 'CORRECT' | 'WRONG' | 'UNATTEMPTED'
  final double marksAwarded;
  final String explanation;

  QuestionReviewItem({
    required this.id,
    required this.questionNumber,
    required this.questionText,
    required this.options,
    required this.studentAnswer,
    required this.correctOption,
    required this.status,
    required this.marksAwarded,
    required this.explanation,
  });

  factory QuestionReviewItem.fromJson(Map<String, dynamic> json) {
    Map<String, String> opts = {};
    if (json['options'] is Map) {
      json['options'].forEach((k, v) => opts[k.toString()] = v.toString());
    }

    return QuestionReviewItem(
      id: json['id'] ?? '',
      questionNumber: json['questionNumber'] is int ? json['questionNumber'] : int.tryParse(json['questionNumber']?.toString() ?? '1') ?? 1,
      questionText: json['questionText'] ?? '',
      options: opts,
      studentAnswer: json['studentAnswer'] ?? 'None',
      correctOption: json['correctOption'] ?? '',
      status: json['status'] ?? 'UNATTEMPTED',
      marksAwarded: (json['marksAwarded'] is num) ? (json['marksAwarded'] as num).toDouble() : double.tryParse(json['marksAwarded']?.toString() ?? '0') ?? 0.0,
      explanation: json['explanation'] ?? '',
    );
  }
}

class AttemptResultModel {
  final String attemptId;
  final String examId;
  final String examTitle;
  final String studentName;
  final String studentEmail;
  final double score;
  final double totalMarks;
  final double percentage;
  final String grade;
  final String status; // 'PASS' | 'FAIL'
  final int correctCount;
  final int wrongCount;
  final int unattemptedCount;
  final int totalQuestions;
  final double accuracy;
  final double timeTakenMinutes;
  final String submittedAt;
  final String pdfUrl;
  final List<QuestionReviewItem> questionReview;

  AttemptResultModel({
    required this.attemptId,
    required this.examId,
    required this.examTitle,
    required this.studentName,
    required this.studentEmail,
    required this.score,
    required this.totalMarks,
    required this.percentage,
    required this.grade,
    required this.status,
    required this.correctCount,
    required this.wrongCount,
    required this.unattemptedCount,
    required this.totalQuestions,
    required this.accuracy,
    required this.timeTakenMinutes,
    required this.submittedAt,
    this.pdfUrl = '',
    this.questionReview = const [],
  });

  bool get isPass => status.toUpperCase() == 'PASS';

  factory AttemptResultModel.fromJson(Map<String, dynamic> json) {
    List<QuestionReviewItem> reviews = [];
    if (json['questionReview'] is List) {
      reviews = (json['questionReview'] as List)
          .map((r) => QuestionReviewItem.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    return AttemptResultModel(
      attemptId: json['attemptId'] ?? json['id'] ?? '',
      examId: json['examId'] ?? '',
      examTitle: json['examTitle'] ?? 'MCQ Exam',
      studentName: json['studentName'] ?? 'Student',
      studentEmail: json['studentEmail'] ?? '',
      score: (json['score'] is num) ? (json['score'] as num).toDouble() : double.tryParse(json['score']?.toString() ?? '0.0') ?? 0.0,
      totalMarks: (json['totalMarks'] is num) ? (json['totalMarks'] as num).toDouble() : double.tryParse(json['totalMarks']?.toString() ?? '0.0') ?? 0.0,
      percentage: (json['percentage'] is num) ? (json['percentage'] as num).toDouble() : double.tryParse(json['percentage']?.toString() ?? '0.0') ?? 0.0,
      grade: json['grade'] ?? 'F',
      status: json['status'] ?? 'FAIL',
      correctCount: json['correctCount'] is int ? json['correctCount'] : int.tryParse(json['correctCount']?.toString() ?? '0') ?? 0,
      wrongCount: json['wrongCount'] is int ? json['wrongCount'] : int.tryParse(json['wrongCount']?.toString() ?? '0') ?? 0,
      unattemptedCount: json['unattemptedCount'] is int ? json['unattemptedCount'] : int.tryParse(json['unattemptedCount']?.toString() ?? '0') ?? 0,
      totalQuestions: json['totalQuestions'] is int ? json['totalQuestions'] : int.tryParse(json['totalQuestions']?.toString() ?? '0') ?? 0,
      accuracy: (json['accuracy'] is num) ? (json['accuracy'] as num).toDouble() : double.tryParse(json['accuracy']?.toString() ?? '0.0') ?? 0.0,
      timeTakenMinutes: (json['timeTakenMinutes'] is num) ? (json['timeTakenMinutes'] as num).toDouble() : double.tryParse(json['timeTakenMinutes']?.toString() ?? '0.0') ?? 0.0,
      submittedAt: json['submittedAt'] ?? DateTime.now().toIso8601String(),
      pdfUrl: json['pdfUrl'] ?? '',
      questionReview: reviews,
    );
  }
}
