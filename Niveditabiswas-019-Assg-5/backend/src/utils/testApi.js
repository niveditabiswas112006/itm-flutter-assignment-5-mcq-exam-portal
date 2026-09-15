const fs = require('fs');
const path = require('path');
const { parseQuestionsExcel } = require('../services/excelParser');
const { generateResultPdf } = require('../services/pdfService');

async function runTests() {
  console.log('🧪 Starting Backend Service Verification Tests...\n');

  // Test 1: Excel Parsing
  const samplePath = path.join(__dirname, '../../sample_files/sample_questions.xlsx');
  if (fs.existsSync(samplePath)) {
    const buffer = fs.readFileSync(samplePath);
    const parsed = parseQuestionsExcel(buffer);
    console.log('Test 1: Excel Parsing:');
    console.log(`- Is Valid: ${parsed.isValid}`);
    console.log(`- Questions Count: ${parsed.validCount}`);
    console.log(`- Total Marks: ${parsed.totalMarks}`);
    console.log(`- Error Count: ${parsed.errorCount}`);
    if (parsed.isValid && parsed.validCount === 6) {
      console.log('✅ Test 1 Passed: Excel parsed successfully.\n');
    } else {
      console.error('❌ Test 1 Failed: Unexpected parsing output.\n');
    }
  } else {
    console.error('❌ Test 1 Failed: Sample file missing.\n');
  }

  // Test 2: PDF Generation Service
  console.log('Test 2: PDF Result Card Generation:');
  try {
    const mockResult = {
      attemptId: 'att_test_12345',
      examTitle: 'Flutter & Dart Mastery Exam',
      studentName: 'Alex Mercer',
      studentEmail: 'alex@itm.edu',
      studentId: 'ITM-2026-0042',
      score: 10,
      totalMarks: 12,
      percentage: 83.33,
      grade: 'A',
      status: 'PASS',
      correctCount: 5,
      wrongCount: 1,
      unattemptedCount: 0,
      totalQuestions: 6,
      accuracy: 83.33,
      timeTakenMinutes: 14.5,
      submittedAt: new Date().toISOString(),
    };

    const pdfResult = await generateResultPdf(mockResult);
    console.log(`- Generated PDF URL: ${pdfResult.pdfUrl}`);
    console.log(`- Public ID: ${pdfResult.publicId}`);
    console.log(`- Size: ${pdfResult.bytes} bytes`);
    console.log('✅ Test 2 Passed: PDF generated successfully.\n');
  } catch (err) {
    console.error('❌ Test 2 Failed:', err.message, '\n');
  }

  console.log('🎉 Backend Service Tests Completed Successfully!');
}

runTests();
