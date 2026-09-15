import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../models/question_model.dart';

class CreateExamScreen extends StatefulWidget {
  final VoidCallback? onExamCreated;

  const CreateExamScreen({super.key, this.onExamCreated});

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: 'Full Stack Flutter & Node.js Exam');
  final _descController = TextEditingController(text: 'Assessment covering Flutter widgets, Dart logic, REST APIs, Firebase & Cloudinary.');
  final _durationController = TextEditingController(text: '30');
  final _passingPercentController = TextEditingController(text: '40');

  bool _isUploading = false;
  bool _isSubmitting = false;
  bool _antiCheating = true;
  bool _allowReview = true;

  String? _fileName;
  String _excelCloudinaryUrl = '';
  String _excelPublicId = '';
  List<QuestionModel> _parsedQuestions = [];
  List<dynamic> _validationErrors = [];
  double _calculatedTotalMarks = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    _passingPercentController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadExcel() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv', 'xls'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        setState(() {
          _isUploading = true;
          _fileName = file.name;
        });

        final res = await api.uploadExcel(file.bytes!, file.name);

        final List qList = res['questions'] ?? [];
        final List errList = res['errors'] ?? [];

        setState(() {
          _excelCloudinaryUrl = res['excelUrl'] ?? '';
          _excelPublicId = res['excelPublicId'] ?? '';
          _parsedQuestions = qList.map((q) => QuestionModel.fromJson(q)).toList();
          _validationErrors = errList;
          _calculatedTotalMarks = (res['totalMarks'] is num) ? (res['totalMarks'] as num).toDouble() : _parsedQuestions.length.toDouble();
          _isUploading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Excel parsed successfully!'),
              backgroundColor: _validationErrors.isEmpty ? AppColors.success : AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading Excel: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _publishExam() async {
    if (!_formKey.currentState!.validate()) return;
    if (_parsedQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload an Excel file containing at least one valid question.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final examData = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'durationMinutes': int.tryParse(_durationController.text) ?? 30,
        'passingPercentage': double.tryParse(_passingPercentController.text) ?? 40.0,
        'totalMarks': _calculatedTotalMarks,
        'antiCheating': _antiCheating,
        'allowReview': _allowReview,
        'excelUrl': _excelCloudinaryUrl,
        'excelPublicId': _excelPublicId,
        'questions': _parsedQuestions.map((q) => q.toJson()).toList(),
      };

      await api.createExam(examData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Exam successfully created and published!'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onExamCreated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating exam: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create & Publish New Exam',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.slate900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Upload questions via Excel file to Cloudinary and configure exam parameters.',
              style: TextStyle(color: AppColors.slate500, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Step 1: Excel Upload Box
            Container(
              padding: const EdgeInsets.all(24),
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
                      const Row(
                        children: [
                          Icon(Icons.table_chart_outlined, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('Step 1: Upload Question Bank (Excel / CSV)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      if (_excelCloudinaryUrl.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_done, size: 14, color: AppColors.success),
                              SizedBox(width: 4),
                              Text('Cloudinary Synced', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Supported format: .xlsx, .csv. Columns: Question, Option A, Option B, Option C, Option D, Correct Option (A, B, C, or D), Marks, Negative Marks, Explanation',
                    style: TextStyle(fontSize: 12, color: AppColors.slate500),
                  ),
                  const SizedBox(height: 16),

                  InkWell(
                    onTap: _isUploading ? null : _pickAndUploadExcel,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.slate100.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.slate200, style: BorderStyle.solid),
                      ),
                      child: Column(
                        children: [
                          if (_isUploading)
                            const CircularProgressIndicator()
                          else ...[
                            Icon(
                              _fileName != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                              size: 40,
                              color: _fileName != null ? AppColors.success : AppColors.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _fileName != null ? 'Selected File: $_fileName' : 'Click to Browse & Upload Excel File',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.slate800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _fileName != null ? 'Click again to replace file' : 'Files are securely stored on Cloudinary storage',
                              style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Step 2: Question Preview & Validation Badges
            if (_parsedQuestions.isNotEmpty || _validationErrors.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(24),
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
                        Row(
                          children: [
                            const Icon(Icons.preview_outlined, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Step 2: Question Preview (${_parsedQuestions.length} Valid Questions)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        Text(
                          'Total Marks: $_calculatedTotalMarks',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Validation Errors Banner if any
                    if (_validationErrors.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '⚠️ Found ${_validationErrors.length} Issue(s) in Excel File:',
                              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            ..._validationErrors.map((err) => Text(
                                  '• Row ${err['row']}: ${(err['issues'] as List?)?.join(', ') ?? err['message']}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                                )),
                          ],
                        ),
                      ),

                    // Questions Accordion / List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _parsedQuestions.length,
                      itemBuilder: (context, idx) {
                        final q = _parsedQuestions[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.slate100.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.slate200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.primaryLight,
                                    child: Text('${idx + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      q.questionText,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.slate900),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppColors.slate200),
                                    ),
                                    child: Text('+${q.marks} / -${q.negativeMarks}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: q.options.entries.map((entry) {
                                  final isCorrect = entry.key == q.correctOption;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isCorrect ? AppColors.successLight : Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isCorrect ? AppColors.success : AppColors.slate200),
                                    ),
                                    child: Text(
                                      '${entry.key}) ${entry.value}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                        color: isCorrect ? AppColors.success : AppColors.slate700,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              if (q.explanation.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '💡 Explanation: ${q.explanation}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.slate500, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Step 3: Exam Parameters & Details
            Container(
              padding: const EdgeInsets.all(24),
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
                      Icon(Icons.tune_outlined, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Step 3: Exam Configuration & Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Exam Title *',
                      hintText: 'e.g. Midterm Dart & Flutter Evaluation',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Exam title is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description / Instructions',
                      hintText: 'Brief instructions for students taking this exam...',
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Duration (Minutes) *',
                            prefixIcon: Icon(Icons.timer_outlined, color: AppColors.slate400),
                          ),
                          validator: (v) => v == null || int.tryParse(v) == null ? 'Enter valid duration' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _passingPercentController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Passing Percentage (%) *',
                            prefixIcon: Icon(Icons.percent_outlined, color: AppColors.slate400),
                          ),
                          validator: (v) => v == null || double.tryParse(v) == null ? 'Enter valid percentage' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Toggles
                  SwitchListTile(
                    title: const Text('Anti-Cheating Detection', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Detect tab-switches and window blur during exam', style: TextStyle(fontSize: 12)),
                    value: _antiCheating,
                    onChanged: (val) => setState(() => _antiCheating = val),
                    activeColor: AppColors.primary,
                  ),
                  SwitchListTile(
                    title: const Text('Allow Mark for Review', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Students can flag questions to revisit before final submission', style: TextStyle(fontSize: 12)),
                    value: _allowReview,
                    onChanged: (val) => setState(() => _allowReview = val),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _publishExam,
                icon: _isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.publish_rounded),
                label: Text(_isSubmitting ? 'Publishing Exam...' : 'Publish Exam to Portal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
