const xlsx = require('xlsx');

/**
 * Normalizes an object key to lowercase alphanumeric
 */
const normalizeKey = (key) => key.toString().trim().toLowerCase().replace(/[^a-z0-9]/g, '');

/**
 * Parses and validates an Excel or CSV buffer
 * @param {Buffer} buffer - Excel/CSV file buffer
 * @returns {Object} { isValid, questions, errors, totalMarks, totalQuestions, validCount, errorCount }
 */
const parseQuestionsExcel = (buffer) => {
  try {
    const workbook = xlsx.read(buffer, { type: 'buffer' });
    const sheetName = workbook.SheetNames[0];
    if (!sheetName) {
      return {
        isValid: false,
        questions: [],
        errors: [{ row: 0, message: 'Workbook contains no sheets.' }],
        totalMarks: 0,
        totalQuestions: 0,
      };
    }

    const worksheet = workbook.Sheets[sheetName];
    const rawRows = xlsx.utils.sheet_to_json(worksheet, { defval: '' });

    if (!rawRows || rawRows.length === 0) {
      return {
        isValid: false,
        questions: [],
        errors: [{ row: 0, message: 'The uploaded sheet is empty.' }],
        totalMarks: 0,
        totalQuestions: 0,
      };
    }

    const questions = [];
    const errors = [];
    let totalMarks = 0;

    rawRows.forEach((row, index) => {
      const rowNum = index + 2; // Row number in Excel (1-indexed + header)

      // Map dynamic column names
      const normalizedRow = {};
      Object.keys(row).forEach((k) => {
        normalizedRow[normalizeKey(k)] = row[k];
      });

      // Extract fields with multiple column alias variations
      const questionText = (
        normalizedRow['question'] ||
        normalizedRow['questiontext'] ||
        normalizedRow['title'] ||
        normalizedRow['q'] ||
        ''
      ).toString().trim();

      const optionA = (
        normalizedRow['optiona'] ||
        normalizedRow['a'] ||
        normalizedRow['opt1'] ||
        normalizedRow['option1'] ||
        ''
      ).toString().trim();

      const optionB = (
        normalizedRow['optionb'] ||
        normalizedRow['b'] ||
        normalizedRow['opt2'] ||
        normalizedRow['option2'] ||
        ''
      ).toString().trim();

      const optionC = (
        normalizedRow['optionc'] ||
        normalizedRow['c'] ||
        normalizedRow['opt3'] ||
        normalizedRow['option3'] ||
        ''
      ).toString().trim();

      const optionD = (
        normalizedRow['optiond'] ||
        normalizedRow['d'] ||
        normalizedRow['opt4'] ||
        normalizedRow['option4'] ||
        ''
      ).toString().trim();

      let correctOption = (
        normalizedRow['correctoption'] ||
        normalizedRow['correct'] ||
        normalizedRow['answer'] ||
        normalizedRow['ans'] ||
        normalizedRow['correctanswer'] ||
        ''
      ).toString().trim().toUpperCase();

      // In case they wrote numeric 1,2,3,4
      if (correctOption === '1') correctOption = 'A';
      if (correctOption === '2') correctOption = 'B';
      if (correctOption === '3') correctOption = 'C';
      if (correctOption === '4') correctOption = 'D';

      let marks = parseFloat(normalizedRow['marks'] || normalizedRow['mark'] || normalizedRow['weight'] || '1');
      if (isNaN(marks) || marks <= 0) marks = 1;

      let negativeMarks = parseFloat(normalizedRow['negativemarks'] || normalizedRow['negative'] || normalizedRow['negmark'] || '0');
      if (isNaN(negativeMarks) || negativeMarks < 0) negativeMarks = 0;

      const explanation = (
        normalizedRow['explanation'] ||
        normalizedRow['explain'] ||
        normalizedRow['solution'] ||
        ''
      ).toString().trim();

      const rowErrors = [];

      // Validations
      if (!questionText) {
        rowErrors.push('Missing Question text.');
      }
      if (!optionA) {
        rowErrors.push('Missing Option A.');
      }
      if (!optionB) {
        rowErrors.push('Missing Option B.');
      }
      if (!optionC) {
        rowErrors.push('Missing Option C.');
      }
      if (!optionD) {
        rowErrors.push('Missing Option D.');
      }
      if (!['A', 'B', 'C', 'D'].includes(correctOption)) {
        rowErrors.push(`Invalid Correct Option "${correctOption}". Must be A, B, C, or D.`);
      }

      if (rowErrors.length > 0) {
        errors.push({
          row: rowNum,
          question: questionText || `Row ${rowNum}`,
          issues: rowErrors,
        });
      } else {
        totalMarks += marks;
        questions.push({
          id: `q_${index + 1}`,
          questionNumber: index + 1,
          questionText,
          options: {
            A: optionA,
            B: optionB,
            C: optionC,
            D: optionD,
          },
          correctOption,
          marks,
          negativeMarks,
          explanation,
        });
      }
    });

    return {
      isValid: errors.length === 0,
      totalQuestions: rawRows.length,
      validCount: questions.length,
      errorCount: errors.length,
      totalMarks,
      questions,
      errors,
    };
  } catch (err) {
    console.error('[Excel Parsing Error]:', err);
    return {
      isValid: false,
      questions: [],
      errors: [{ row: 0, message: `Failed to parse Excel file: ${err.message}` }],
      totalMarks: 0,
      totalQuestions: 0,
      validCount: 0,
      errorCount: 1,
    };
  }
};

module.exports = {
  parseQuestionsExcel,
};
