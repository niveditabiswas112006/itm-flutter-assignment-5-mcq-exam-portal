import 'package:flutter_test/flutter_test.dart';
import 'package:mcq_exam_portal/main.dart';

void main() {
  testWidgets('Exam Portal smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MCQExamPortalApp());
    expect(find.text('ITM MCQ Exam Portal'), findsOneWidget);
  });
}
