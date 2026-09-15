const express = require('express');
const router = express.Router();
const multer = require('multer');
const adminController = require('../controllers/adminController');
const { requireAuth, requireAdmin } = require('../middlewares/auth');

// Multer memory storage configuration for file uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB limit
});

// All admin routes require authentication and admin role
router.use(requireAuth);
router.use(requireAdmin);

// 1. Upload Excel Sheet & Parse
router.post('/upload-excel', upload.single('file'), adminController.uploadExcel);

// 2. Exam Management
router.post('/exam', adminController.createExam);
router.get('/exams', adminController.getAllExams);
router.get('/exam/:id', adminController.getExamById);
router.put('/exam/:id', adminController.updateExam);
router.delete('/exam/:id', adminController.deleteExam);

// 3. Reports & Analytics
router.get('/report/:examId', adminController.getExamReport);
router.get('/report/:examId/export', adminController.exportExamReport);

// 4. Student Management
router.get('/students', adminController.getAllStudents);

module.exports = router;
