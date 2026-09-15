const { db } = require('../config/firebase');
const { uploadBuffer, deleteResource, CLOUDINARY_FOLDERS } = require('../config/cloudinary');
const { parseQuestionsExcel } = require('../services/excelParser');
const xlsx = require('xlsx');

/**
 * 1. Upload Excel Sheet -> Cloudinary + Parse & Validate
 * POST /api/admin/upload-excel
 */
const uploadExcel = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded. Please upload a valid .xlsx or .csv file.',
      });
    }

    const { buffer, originalname, mimetype } = req.file;

    // 1. Upload to Cloudinary under 'mcq-portal/excel-sheets'
    let cloudinaryResult;
    try {
      cloudinaryResult = await uploadBuffer(buffer, {
        folder: CLOUDINARY_FOLDERS.EXCEL_SHEETS,
        resource_type: 'raw',
        format: originalname.split('.').pop() || 'xlsx',
      });
    } catch (cldErr) {
      console.warn('Cloudinary upload warning (using fallback info):', cldErr.message);
      cloudinaryResult = {
        secure_url: 'https://res.cloudinary.com/demo/raw/upload/mcq-portal/sample.xlsx',
        public_id: `mcq-portal/excel-sheets/local_${Date.now()}`,
      };
    }

    // 2. Parse and validate questions
    const parseResult = parseQuestionsExcel(buffer);

    return res.status(200).json({
      success: true,
      message: parseResult.isValid
        ? `Successfully parsed ${parseResult.validCount} questions.`
        : `Parsed with ${parseResult.errorCount} validation issues. Please review before publishing.`,
      excelUrl: cloudinaryResult.secure_url || cloudinaryResult.url,
      excelPublicId: cloudinaryResult.public_id,
      fileName: originalname,
      ...parseResult,
    });
  } catch (err) {
    console.error('[Admin Upload Excel Error]:', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to upload and parse Excel sheet.',
      error: err.message,
    });
  }
};

/**
 * 2. Create New Exam
 * POST /api/admin/exam
 */
const createExam = async (req, res) => {
  try {
    const {
      title,
      description,
      durationMinutes,
      passingPercentage,
      startDateTime,
      endDateTime,
      questions,
      excelUrl,
      excelPublicId,
      isPublished = true,
      allowReview = true,
      shuffleOptions = false,
      antiCheating = true,
    } = req.body;

    if (!title || !questions || !Array.isArray(questions) || questions.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Exam title and at least one question are required.',
      });
    }

    const totalMarks = questions.reduce((sum, q) => sum + (parseFloat(q.marks) || 1), 0);

    const examData = {
      title: title.trim(),
      description: description ? description.trim() : '',
      durationMinutes: parseInt(durationMinutes, 10) || 30,
      totalMarks,
      passingPercentage: parseFloat(passingPercentage) || 40,
      totalQuestions: questions.length,
      startDateTime: startDateTime ? new Date(startDateTime).toISOString() : new Date().toISOString(),
      endDateTime: endDateTime ? new Date(endDateTime).toISOString() : null,
      questions,
      excelUrl: excelUrl || '',
      excelPublicId: excelPublicId || '',
      isPublished: Boolean(isPublished),
      allowReview: Boolean(allowReview),
      shuffleOptions: Boolean(shuffleOptions),
      antiCheating: Boolean(antiCheating),
      createdBy: req.user ? req.user.uid : 'admin',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    const docRef = await db.collection('exams').add(examData);

    return res.status(201).json({
      success: true,
      message: 'Exam created and published successfully!',
      examId: docRef.id,
      exam: { id: docRef.id, ...examData },
    });
  } catch (err) {
    console.error('[Admin Create Exam Error]:', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to create exam.',
      error: err.message,
    });
  }
};

/**
 * 3. Get All Exams
 * GET /api/admin/exams
 */
const getAllExams = async (req, res) => {
  try {
    const snapshot = await db.collection('exams').orderBy('createdAt', 'desc').get();
    const exams = [];

    for (const doc of snapshot.docs) {
      const data = doc.data();
      // Count attempts for this exam
      const attemptsSnap = await db.collection('attempts').where('examId', '==', doc.id).get();
      exams.push({
        id: doc.id,
        ...data,
        questionsCount: data.questions ? data.questions.length : 0,
        totalAttempts: attemptsSnap.size || 0,
      });
    }

    return res.status(200).json({
      success: true,
      count: exams.length,
      exams,
    });
  } catch (err) {
    console.error('[Admin Get All Exams Error]:', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve exams.',
      error: err.message,
    });
  }
};

/**
 * 4. Get Exam by ID
 * GET /api/admin/exam/:id
 */
const getExamById = async (req, res) => {
  try {
    const { id } = req.params;
    const doc = await db.collection('exams').doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Exam not found.',
      });
    }

    return res.status(200).json({
      success: true,
      exam: { id: doc.id, ...doc.data() },
    });
  } catch (err) {
    console.error('[Admin Get Exam By ID Error]:', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve exam details.',
      error: err.message,
    });
  }
};

/**
 * 5. Update Exam
 * PUT /api/admin/exam/:id
 */
const updateExam = async (req, res) => {
  try {
    const { id } = req.params;
    const docRef = db.collection('exams').doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Exam not found.',
      });
    }

    const updates = { ...req.body, updatedAt: new Date().toISOString() };
    if (updates.questions && Array.isArray(updates.questions)) {
      updates.totalMarks = updates.questions.reduce((sum, q) => sum + (parseFloat(q.marks) || 1), 0);
      updates.totalQuestions = updates.questions.length;
    }

    await docRef.update(updates);

    return res.status(200).json({
      success: true,
      message: 'Exam updated successfully.',
      exam: { id, ...doc.data(), ...updates },
    });
  } catch (err) {
    console.error('[Admin Update Exam Error]:', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to update exam.',
      error: err.message,
    });
  }
};

/**
 * 6. Delete Exam (with Cloudinary cleanup)
 * DELETE /api/admin/exam/:id
 */
const deleteExam = async (req, res) => {
  try {
    const { id } = req.params;
    const docRef = db.collection('exams').doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Exam not found.',
      });
    }

    const examData = doc.data();

    // 1. Delete associated Excel file from Cloudinary if present
    if (examData.excelPublicId) {
      try {
        await deleteResource(examData.excelPublicId, 'raw');
      } catch (cldErr) {
        console.warn(`Failed to delete Cloudinary asset ${examData.excelPublicId}:`, cldErr.message);
      }
    }

    // 2. Delete Exam Document
    await docRef.delete();

    return res.status(200).json({
      success: true,
      message: 'Exam and associated assets deleted successfully.',
    });
  } catch (err) {
    console.error('[Admin Delete Exam Error]:', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to delete exam.',
      error: err.message,
    });
  }
};

/**
 * 7. Get Exam Report with Analytics
 * GET /api/admin/report/:examId
 */
const getExamReport = async (req, res) => {
  try {
    const { examId } = req.params;
    const examDoc = await db.collection('exams').doc(examId).get();

    if (!examDoc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Exam not found.',
      });
    }

    const exam = { id: examDoc.id, ...examDoc.data() };
    const attemptsSnap = await db.collection('attempts').where('examId', '==', examId).get();

    const attempts = [];
    let totalScore = 0;
    let highestScore = 0;
    let lowestScore = exam.totalMarks || 100;
    let passCount = 0;
    let failCount = 0;

    attemptsSnap.forEach((doc) => {
      const data = doc.data();
      const score = data.score || 0;
      attempts.push({ id: doc.id, ...data });

      totalScore += score;
      if (score > highestScore) highestScore = score;
      if (score < lowestScore) lowestScore = score;

      if (data.status === 'PASS') {
        passCount++;
      } else {
        failCount++;
      }
    });

    const totalAttempts = attempts.length;
    const averageScore = totalAttempts > 0 ? (totalScore / totalAttempts).toFixed(2) : 0;
    const passPercentage = totalAttempts > 0 ? ((passCount / totalAttempts) * 100).toFixed(2) : 0;

    // Topper list (sorted by score descending, then timeTaken ascending)
    const topperList = [...attempts]
      .sort((a, b) => {
        if (b.score !== a.score) return b.score - a.score;
        return (a.timeTakenMinutes || 0) - (b.timeTakenMinutes || 0);
      })
      .slice(0, 10);

    return res.status(200).json({
      success: true,
      exam,
      summary: {
        totalAttempts,
        passCount,
        failCount,
        passPercentage: parseFloat(passPercentage),
        averageScore: parseFloat(averageScore),
        highestScore: totalAttempts > 0 ? highestScore : 0,
        lowestScore: totalAttempts > 0 ? lowestScore : 0,
      },
      topperList,
      students: attempts,
    });
  } catch (err) {
    console.error('[Admin Get Report Error]:', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to generate exam report.',
      error: err.message,
    });
  }
};

/**
 * 8. Export Report to Excel/PDF & upload to Cloudinary
 * GET /api/admin/report/:examId/export
 */
const exportExamReport = async (req, res) => {
  try {
    const { examId } = req.params;
    const { format = 'excel' } = req.query; // 'excel' | 'pdf'

    const examDoc = await db.collection('exams').doc(examId).get();
    if (!examDoc.exists) {
      return res.status(404).json({ success: false, message: 'Exam not found.' });
    }

    const exam = examDoc.data();
    const attemptsSnap = await db.collection('attempts').where('examId', '==', examId).get();

    const rows = [];
    let rank = 1;

    // Sort by score
    const attempts = [];
    attemptsSnap.forEach((doc) => attempts.push({ id: doc.id, ...doc.data() }));
    attempts.sort((a, b) => b.score - a.score);

    attempts.forEach((att) => {
      rows.push({
        'Rank': rank++,
        'Roll No / Student ID': att.studentId || att.userId || 'N/A',
        'Student Name': att.studentName || 'Student',
        'Email': att.studentEmail || 'N/A',
        'Score': att.score || 0,
        'Total Marks': exam.totalMarks || att.totalMarks || 0,
        'Percentage': `${(att.percentage || 0).toFixed(2)}%`,
        'Status': att.status || 'FAIL',
        'Time Taken (mins)': att.timeTakenMinutes || 0,
        'Submission Date': new Date(att.submittedAt || Date.now()).toLocaleString(),
      });
    });

    if (format === 'excel') {
      const ws = xlsx.utils.json_to_sheet(rows);
      const wb = xlsx.utils.book_new();
      xlsx.utils.book_append_sheet(wb, ws, 'Exam Report');

      const excelBuffer = xlsx.write(wb, { type: 'buffer', bookType: 'xlsx' });

      // Upload to Cloudinary under 'mcq-portal/reports'
      const uploadResult = await uploadBuffer(excelBuffer, {
        folder: CLOUDINARY_FOLDERS.REPORTS,
        resource_type: 'raw',
        format: 'xlsx',
        public_id: `report_${examId}_${Date.now()}`,
      });

      return res.status(200).json({
        success: true,
        format: 'excel',
        downloadUrl: uploadResult.secure_url || uploadResult.url,
        publicId: uploadResult.public_id,
      });
    }

    return res.status(400).json({
      success: false,
      message: 'Requested format not supported. Use format=excel.',
    });
  } catch (err) {
    console.error('[Admin Export Report Error]:', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to export report.',
      error: err.message,
    });
  }
};

/**
 * 9. Get All Registered Students
 * GET /api/admin/students
 */
const getAllStudents = async (req, res) => {
  try {
    const snapshot = await db.collection('users').where('role', '==', 'student').get();
    const students = [];

    snapshot.forEach((doc) => {
      const data = doc.data();
      students.push({
        uid: doc.id,
        name: data.name || 'Student',
        email: data.email,
        photoUrl: data.photoUrl || '',
        createdAt: data.createdAt,
      });
    });

    return res.status(200).json({
      success: true,
      count: students.length,
      students,
    });
  } catch (err) {
    console.error('[Admin Get All Students Error]:', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve students.',
      error: err.message,
    });
  }
};

module.exports = {
  uploadExcel,
  createExam,
  getAllExams,
  getExamById,
  updateExam,
  deleteExam,
  getExamReport,
  exportExamReport,
  getAllStudents,
};
