import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/exam_model.dart';
import '../models/attempt_model.dart';
import '../models/user_model.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, localhost for Web and iOS/macOS
  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:5000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  String baseUrl = defaultBaseUrl;
  UserModel? currentUser;

  void setUser(UserModel? user) {
    currentUser = user;
  }

  Map<String, String> get _headers {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (currentUser != null) {
      map['x-mock-user-id'] = currentUser!.uid;
      map['x-mock-user-role'] = currentUser!.role;
      map['x-mock-user-name'] = currentUser!.name;
      map['x-mock-user-email'] = currentUser!.email;
      map['Authorization'] = 'Bearer token_${currentUser!.uid}';
    }

    return map;
  }

  // ================= ADMIN APIS =================

  /// Upload Excel File to Cloudinary & Parse Questions
  Future<Map<String, dynamic>> uploadExcel(Uint8List fileBytes, String fileName) async {
    try {
      final uri = Uri.parse('$baseUrl/admin/upload-excel');
      final request = http.MultipartRequest('POST', uri);

      if (currentUser != null) {
        request.headers['x-mock-user-id'] = currentUser!.uid;
        request.headers['x-mock-user-role'] = currentUser!.role;
        request.headers['x-mock-user-name'] = currentUser!.name;
        request.headers['x-mock-user-email'] = currentUser!.email;
        request.headers['Authorization'] = 'Bearer token_${currentUser!.uid}';
      }

      final ext = fileName.split('.').last;
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
        contentType: MediaType('application', ext == 'csv' ? 'csv' : 'vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
      );

      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to upload Excel sheet.');
      }
    } catch (e) {
      debugPrint('[API uploadExcel Error]: $e');
      rethrow;
    }
  }

  /// Create and Publish Exam
  Future<ExamModel> createExam(Map<String, dynamic> examData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/exam'),
      headers: _headers,
      body: json.encode(examData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final res = json.decode(response.body);
      return ExamModel.fromJson(res['exam'] ?? res);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to create exam.');
    }
  }

  /// Get All Exams (Admin)
  Future<List<ExamModel>> getAllExamsAdmin() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/exams'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final res = json.decode(response.body);
      final List list = res['exams'] ?? [];
      return list.map((item) => ExamModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch exams.');
    }
  }

  /// Get Exam By ID
  Future<ExamModel> getExamById(String examId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/exam/$examId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final res = json.decode(response.body);
      return ExamModel.fromJson(res['exam']);
    } else {
      throw Exception('Failed to fetch exam details.');
    }
  }

  /// Update Exam
  Future<ExamModel> updateExam(String examId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/exam/$examId'),
      headers: _headers,
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      final res = json.decode(response.body);
      return ExamModel.fromJson(res['exam']);
    } else {
      throw Exception('Failed to update exam.');
    }
  }

  /// Delete Exam
  Future<void> deleteExam(String examId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/exam/$examId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to delete exam.');
    }
  }

  /// Get Exam Analytics Report
  Future<Map<String, dynamic>> getExamReport(String examId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/report/$examId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load exam report.');
    }
  }

  /// Export Exam Report to Cloudinary
  Future<String> exportExamReport(String examId, {String format = 'excel'}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/report/$examId/export?format=$format'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final res = json.decode(response.body);
      return res['downloadUrl'] ?? '';
    } else {
      throw Exception('Failed to export report.');
    }
  }

  /// Get All Students
  Future<List<UserModel>> getAllStudents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/students'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final res = json.decode(response.body);
      final List list = res['students'] ?? [];
      return list.map((item) => UserModel.fromJson(item)).toList();
    } else {
      return [];
    }
  }

  // ================= STUDENT APIS =================

  /// Upload Profile Picture to Cloudinary
  Future<String> uploadProfilePicture(Uint8List imageBytes, String fileName) async {
    final uri = Uri.parse('$baseUrl/student/upload-profile');
    final request = http.MultipartRequest('POST', uri);

    if (currentUser != null) {
      request.headers['x-mock-user-id'] = currentUser!.uid;
      request.headers['x-mock-user-role'] = currentUser!.role;
      request.headers['x-mock-user-name'] = currentUser!.name;
      request.headers['x-mock-user-email'] = currentUser!.email;
      request.headers['Authorization'] = 'Bearer token_${currentUser!.uid}';
    }

    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: fileName,
      contentType: MediaType('image', 'jpeg'),
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final res = json.decode(response.body);
      return res['photoUrl'] ?? '';
    } else {
      throw Exception('Failed to upload profile picture.');
    }
  }

  /// Get Available Exams for Students
  Future<List<ExamModel>> getAvailableExamsStudent() async {
    final response = await http.get(
      Uri.parse('$baseUrl/student/exams'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final res = json.decode(response.body);
      final List list = res['exams'] ?? [];
      return list.map((item) => ExamModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load available exams.');
    }
  }

  /// Start Exam (Retrieve Questions)
  Future<ExamModel> startExam(String examId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/student/exam/$examId/start'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final res = json.decode(response.body);
      return ExamModel.fromJson(res['exam']);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to start exam.');
    }
  }

  /// Submit Exam & Receive Auto-Graded Result
  Future<AttemptResultModel> submitExam({
    required String examId,
    required Map<String, String> answers,
    required double timeTakenMinutes,
    int tabSwitchCount = 0,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/student/exam/$examId/submit'),
      headers: _headers,
      body: json.encode({
        'answers': answers,
        'timeTakenMinutes': timeTakenMinutes,
        'tabSwitchCount': tabSwitchCount,
      }),
    );

    if (response.statusCode == 200) {
      final res = json.decode(response.body);
      return AttemptResultModel.fromJson(res['result']);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to submit exam.');
    }
  }

  /// Get Result by Attempt ID
  Future<AttemptResultModel> getResult(String attemptId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/student/result/$attemptId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final res = json.decode(response.body);
      return AttemptResultModel.fromJson(res['result']);
    } else {
      throw Exception('Failed to load exam result.');
    }
  }

  /// Get Student Exam Attempt History
  Future<List<Map<String, dynamic>>> getStudentHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/student/history'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final res = json.decode(response.body);
      final List list = res['history'] ?? [];
      return list.cast<Map<String, dynamic>>();
    } else {
      return [];
    }
  }
}
