const express = require('express');
const router = express.Router();
const multer = require('multer');
const studentController = require('../controllers/studentController');
const { requireAuth, requireStudent } = require('../middlewares/auth');

// Multer memory storage configuration for image uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB limit
});

// All student routes require authentication
router.use(requireAuth);
router.use(requireStudent);

// 1. Upload Profile Picture
router.post('/upload-profile', upload.single('image'), studentController.uploadProfile);

// 2. Exam Discovery & Interaction
router.get('/exams', studentController.getAvailableExams);
router.post('/exam/:id/start', studentController.startExam);
router.post('/exam/:id/submit', studentController.submitExam);

// 3. Results & Reports
router.get('/result/:attemptId', studentController.getResult);
router.get('/result/:attemptId/pdf', studentController.getResultPdf);
router.get('/history', studentController.getStudentHistory);

module.exports = router;
