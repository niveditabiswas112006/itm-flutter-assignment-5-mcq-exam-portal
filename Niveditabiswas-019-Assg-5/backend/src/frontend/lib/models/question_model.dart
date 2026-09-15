class QuestionModel {
  final String id;
  final int questionNumber;
  final String questionText;
  final Map<String, String> options; // {'A': '...', 'B': '...', 'C': '...', 'D': '...'}
  final String correctOption; // 'A' | 'B' | 'C' | 'D' (empty in student taking mode)
  final double marks;
  final double negativeMarks;
  final String explanation;

  QuestionModel({
    required this.id,
    required this.questionNumber,
    required this.questionText,
    required this.options,
    this.correctOption = '',
    this.marks = 1.0,
    this.negativeMarks = 0.0,
    this.explanation = '',
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    Map<String, String> opts = {};
    if (json['options'] is Map) {
      json['options'].forEach((k, v) {
        opts[k.toString().toUpperCase()] = v.toString();
      });
    }

    return QuestionModel(
      id: json['id'] ?? json['_id'] ?? '',
      questionNumber: json['questionNumber'] is int ? json['questionNumber'] : int.tryParse(json['questionNumber']?.toString() ?? '1') ?? 1,
      questionText: json['questionText'] ?? json['question'] ?? '',
      options: opts,
      correctOption: (json['correctOption'] ?? json['correct'] ?? '').toString().toUpperCase(),
      marks: (json['marks'] is num) ? (json['marks'] as num).toDouble() : double.tryParse(json['marks']?.toString() ?? '1.0') ?? 1.0,
      negativeMarks: (json['negativeMarks'] is num) ? (json['negativeMarks'] as num).toDouble() : double.tryParse(json['negativeMarks']?.toString() ?? '0.0') ?? 0.0,
      explanation: json['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionNumber': questionNumber,
      'questionText': questionText,
      'options': options,
      'correctOption': correctOption,
      'marks': marks,
      'negativeMarks': negativeMarks,
      'explanation': explanation,
    };
  }
}
