import 'question_model.dart';

class ExamModel {
  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final double totalMarks;
  final double passingPercentage;
  final int totalQuestions;
  final String startDateTime;
  final String? endDateTime;
  final String excelUrl;
  final String excelPublicId;
  final bool isPublished;
  final bool allowReview;
  final bool antiCheating;
  final List<QuestionModel> questions;
  final int totalAttempts;
  final bool isAttempted;
  final String? lastAttemptId;
  final double? lastScore;

  ExamModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.durationMinutes,
    required this.totalMarks,
    this.passingPercentage = 40.0,
    required this.totalQuestions,
    required this.startDateTime,
    this.endDateTime,
    this.excelUrl = '',
    this.excelPublicId = '',
    this.isPublished = true,
    this.allowReview = true,
    this.antiCheating = true,
    this.questions = const [],
    this.totalAttempts = 0,
    this.isAttempted = false,
    this.lastAttemptId,
    this.lastScore,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    List<QuestionModel> qList = [];
    if (json['questions'] is List) {
      qList = (json['questions'] as List)
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList();
    }

    return ExamModel(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      durationMinutes: json['durationMinutes'] is int ? json['durationMinutes'] : int.tryParse(json['durationMinutes']?.toString() ?? '30') ?? 30,
      totalMarks: (json['totalMarks'] is num) ? (json['totalMarks'] as num).toDouble() : double.tryParse(json['totalMarks']?.toString() ?? '0.0') ?? 0.0,
      passingPercentage: (json['passingPercentage'] is num) ? (json['passingPercentage'] as num).toDouble() : double.tryParse(json['passingPercentage']?.toString() ?? '40.0') ?? 40.0,
      totalQuestions: json['totalQuestions'] is int ? json['totalQuestions'] : (qList.isNotEmpty ? qList.length : int.tryParse(json['questionsCount']?.toString() ?? '0') ?? 0),
      startDateTime: json['startDateTime'] ?? DateTime.now().toIso8601String(),
      endDateTime: json['endDateTime'],
      excelUrl: json['excelUrl'] ?? '',
      excelPublicId: json['excelPublicId'] ?? '',
      isPublished: json['isPublished'] ?? true,
      allowReview: json['allowReview'] ?? true,
      antiCheating: json['antiCheating'] ?? true,
      questions: qList,
      totalAttempts: json['totalAttempts'] is int ? json['totalAttempts'] : 0,
      isAttempted: json['isAttempted'] ?? false,
      lastAttemptId: json['lastAttemptId'],
      lastScore: (json['lastScore'] is num) ? (json['lastScore'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'durationMinutes': durationMinutes,
      'totalMarks': totalMarks,
      'passingPercentage': passingPercentage,
      'totalQuestions': totalQuestions,
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
      'excelUrl': excelUrl,
      'excelPublicId': excelPublicId,
      'isPublished': isPublished,
      'allowReview': allowReview,
      'antiCheating': antiCheating,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}
