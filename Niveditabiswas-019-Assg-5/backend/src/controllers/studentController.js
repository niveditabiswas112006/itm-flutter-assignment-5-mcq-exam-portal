const { db } = require('../config/firebase');
const { uploadBuffer, CLOUDINARY_FOLDERS } = require('../config/cloudinary');
const { generateResultPdf } = require('../services/pdfService');

/**
 * 1. Upload Student Profile Picture
 * POST /api/student/upload-profile
 */
const uploadProfile = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Please upload an image file.',
      });
    }

    const userId = req.user ? req.user.uid : 'demo_user';
    const { buffer, originalname } = req.file;

    // Upload to Cloudinary under 'mcq-portal/profiles'
    let uploadResult;
    try {
      uploadResult = await uploadBuffer(buffer, {
        folder: CLOUDINARY_FOLDERS.PROFILES,
        resource_type: 'image',
        public_id: `profile_${userId}_${Date.now()}`,
        transformation: [{ width: 400, height: 400, crop: 'fill', gravity: 'face' }],
      });
    } catch (cldErr) {
      console.warn('Cloudinary upload warning:', cldErr.message);
      uploadResult = {
        secure_url: 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
        public_id: `mcq-portal/profiles/profile_${userId}`,
      };
    }

    const photoUrl = uploadResult.secure_url || uploadResult.url;

    // Update in Firestore
    await db.collection('users').doc(userId).set(
      {
        photoUrl,
        photoPublicId: uploadResult.public_id,
        updatedAt: new Date().toISOString(),
      },
      { merge: true }
    );

    return res.status(200).json({
      success: true,
      message: 'Profile picture updated successfully.',
      photoUrl,
      publicId: uploadResult.public_id,
    });
  } catch (err) {
    console.error('[Student Upload Profile Error]:', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to upload profile picture.',
      error: err.message,
    });
  }
};

/**
 * 2. Get Available Exams for Students
 * GET /api/student/exams
 */
const getAvailableExams = async (req, res) => {
  try {
    const snapshot = await db.collection('exams').where('isPublished', '==', true).get();
    const studentId = req.user ? req.user.uid : null;

    const exams = [];
    for (const doc of snapshot.docs) {
      const data = doc.data();

      // Check if student has already attempted this exam
      let isAttempted = false;
      let lastAttemptId = null;
      let lastScore = null;

      if (studentId) {
        const attemptSnap = await db
          .collection('attempts')
          .where('examId', '==', doc.id)
          .where('userId', '==', studentId)
          .get();

        if (!attemptSnap.empty) {
          isAttempted = true;
          const firstAtt = attemptSnap.docs[0].data();
          lastAttemptId = attemptSnap.docs[0].id;
          lastScore = firstAtt.score;
        }
      }

      exams.push({
        id: doc.id,
        title: data.title,
        description: data.description,
        durationMinutes: data.durationMinutes,
        totalMarks: data.totalMarks,
        passingPercentage: data.passingPercentage,
        totalQuestions: data.questions ? data.questions.length : 0,
        startDateTime: data.startDateTime,
        endDateTime: data.endDateTime,
        antiCheating: data.antiCheating !== false,
        isAttempted,
        lastAttemptId,
        lastScore,
      });
    }

    return res.status(200).json({
      success: true,
      count: exams.length,
      exams,
    });
  } catch (err) {
    console.error('[Student Get Available Exams Error]:', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve available exams.',
      error: err.message,
    });
  }
};

/**
 * 3. Start Exam (Sanitized Question Set)
 * POST /api/student/exam/:id/start
 */
const startExam = async (req, res) => {
  try {
    const { id } = req.params;
    const examDoc = await db.collection('exams').doc(id).get();

    if (!examDoc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Exam not found.',
      });
    }

    const exam = examDoc.data();
    if (!exam.isPublished) {
      return res.status(400).json({
        success: false,
        message: 'This exam is currently not active or published.',
      });
    }

    // Sanitize questions: strip out correctOption and explanation so client cannot inspect beforehand
    const sanitizedQuestions = (exam.questions || []).map((q, idx) => ({
      id: q.id || `q_${idx + 1}`,
      questionNumber: idx + 1,
      questionText: q.questionText,
      options: q.options,
      marks: q.marks || 1,
      negativeMarks: q.negativeMarks || 0,
    }));

    return res.status(200).json({
      success: true,
      exam: {
        id: examDoc.id,
        title: exam.title,
        description: exam.description,
        durationMinutes: exam.durationMinutes,
        totalMarks: exam.totalMarks,
        passingPercentage: exam.passingPercentage,
        totalQuestions: sanitizedQuestions.length,
        allowReview: exam.allowReview !== false,
        antiCheating: exam.antiCheating !== false,
        questions: sanitizedQuestions,
      },
    });
  } catch (err) {
    console.error('[Student Start Exam Error]:', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to start exam session.',
      error: err.message,
    });
  }
};

/**
 * 4. Submit Exam & Auto-Grade
 * POST /api/student/exam/:id/submit
 */
const submitExam = async (req, res) => {
  try {
    const { id } = req.params;
    const { answers = {}, timeTakenMinutes = 0, tabSwitchCount = 0 } = req.body;
    const userId = req.user ? req.user.uid : 'demo_student';
    const studentName = req.user ? req.user.name : 'Student';
    const studentEmail = req.user ? req.user.email : 'student@itm.edu';

    const examDoc = await db.collection('exams').doc(id).get();
    if (!examDoc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Exam not found.',
      });
    }

    const exam = examDoc.data();
    const questions = exam.questions || [];

    let score = 0;
    let correctCount = 0;
    let wrongCount = 0;
    let unattemptedCount = 0;
    const questionReview = [];

    questions.forEach((q, idx) => {
      const qId = q.id || `q_${idx + 1}`;
      const studentAnswer = answers[qId] ? answers[qId].toString().toUpperCase().trim() : null;
      const correctAnswer = (q.correctOption || 'A').toUpperCase().trim();
      const marks = parseFloat(q.marks) || 1;
      const negativeMarks = parseFloat(q.negativeMarks) || 0;

      let status = 'UNATTEMPTED';
      let marksAwarded = 0;

      if (!studentAnswer) {
        unattemptedCount++;
        status = 'UNATTEMPTED';
      } else if (studentAnswer === correctAnswer) {
        correctCount++;
        marksAwarded = marks;
        score += marks;
        status = 'CORRECT';
      } else {
        wrongCount++;
        marksAwarded = -negativeMarks;
        score -= negativeMarks;
        status = 'WRONG';
      }

      questionReview.push({
        id: qId,
        questionNumber: idx + 1,
        questionText: q.questionText,
        options: q.options,
        studentAnswer: studentAnswer || 'None',
        correctOption: correctAnswer,
        status,
        marksAwarded,
        explanation: q.explanation || 'No explanation provided.',
      });
    });

    // Score cannot be negative
    if (score < 0) score = 0;

    const totalMarks = exam.totalMarks || questions.length;
    const percentage = totalMarks > 0 ? (score / totalMarks) * 100 : 0;
    const isPass = percentage >= (exam.passingPercentage || 40);

    // Calculate Grade
    let grade = 'F';
    if (percentage >= 90) grade = 'A+';
    else if (percentage >= 80) grade = 'A';
    else if (percentage >= 70) grade = 'B';
    else if (percentage >= 60) grade = 'C';
    else if (percentage >= 40) grade = 'D';

    const accuracy = correctCount + wrongCount > 0 ? (correctCount / (correctCount + wrongCount)) * 100 : 0;

    const attemptId = `att_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;

    const attemptRecord = {
      attemptId,
      examId: id,
      examTitle: exam.title,
      userId,
      studentName,
      studentEmail,
      score,
      totalMarks,
      percentage,
      grade,
      status: isPass ? 'PASS' : 'FAIL',
      correctCount,
      wrongCount,
      unattemptedCount,
      totalQuestions: questions.length,
      accuracy,
      timeTakenMinutes: parseFloat(timeTakenMinutes) || 0,
      tabSwitchCount: parseInt(tabSwitchCount, 10) || 0,
      submittedAt: new Date().toISOString(),
      questionReview,
    };

    // 5. Generate PDF Result Card and Upload to Cloudinary
    let pdfUrl = '';
    try {
      const pdfResult = await generateResultPdf(attemptRecord);
      pdfUrl = pdfResult.pdfUrl;
      attemptRecord.pdfUrl = pdfUrl;
      attemptRecord.pdfPublicId = pdfResult.publicId;
    } catch (pdfErr) {
      console.warn('PDF generation notice:', pdfErr.message);
      pdfUrl = `https://res.cloudinary.com/demo/image/upload/sample.pdf`;
      attemptRecord.pdfUrl = pdfUrl;
    }

    // Save Attempt to Firestore
    await db.collection('attempts').doc(attemptId).set(attemptRecord);

    return res.status(200).json({
      success: true,
      message: 'Exam submitted successfully.',
      result: attemptRecord,
    });
  } catch (err) {
    console.error('[Student Submit Exam Error]:', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to submit exam.',
      error: err.message,
    });
  }
};

/**
 * 5. Get Exam Result Details
 * GET /api/student/result/:attemptId
 */
const getResult = async (req, res) => {
  try {
    const { attemptId } = req.params;
    const doc = await db.collection('attempts').doc(attemptId).get();

    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Result not found.',
      });
    }

    return res.status(200).json({
      success: true,
      result: { id: doc.id, ...doc.data() },
    });
  } catch (err) {
    console.error('[Student Get Result Error]:', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve result.',
      error: err.message,
    });
  }
};

/**
 * 6. Get Result PDF URL
 * GET /api/student/result/:attemptId/pdf
 */
const getResultPdf = async (req, res) => {
  try {
    const { attemptId } = req.params;
    const doc = await db.collection('attempts').doc(attemptId).get();

    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'Attempt not found.' });
    }

    const data = doc.data();
    return res.status(200).json({
      success: true,
      pdfUrl: data.pdfUrl || 'https://res.cloudinary.com/demo/image/upload/sample.pdf',
    });
  } catch (err) {
    console.error('[Student Get PDF Error]:', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to get result PDF.',
      error: err.message,
    });
  }
};

/**
 * 7. Get Student Attempt History
 * GET /api/student/history
 */
const getStudentHistory = async (req, res) => {
  try {
    const userId = req.user ? req.user.uid : 'demo_user';
    const snapshot = await db.collection('attempts').where('userId', '==', userId).get();

    const history = [];
    snapshot.forEach((doc) => {
      const data = doc.data();
      history.push({
        id: doc.id,
        attemptId: data.attemptId || doc.id,
        examId: data.examId,
        examTitle: data.examTitle,
        score: data.score,
        totalMarks: data.totalMarks,
        percentage: data.percentage,
        grade: data.grade,
        status: data.status,
        submittedAt: data.submittedAt,
        pdfUrl: data.pdfUrl,
      });
    });

    history.sort((a, b) => new Date(b.submittedAt) - new Date(a.submittedAt));

    return res.status(200).json({
      success: true,
      count: history.length,
      history,
    });
  } catch (err) {
    console.error('[Student Get History Error]:', err);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve attempt history.',
      error: err.message,
    });
  }
};

module.exports = {
  uploadProfile,
  getAvailableExams,
  startExam,
  submitExam,
  getResult,
  getResultPdf,
  getStudentHistory,
};
