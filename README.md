# Professional MCQ Exam Portal
### Full Stack Assignment — Flutter + Node.js + Firebase + Cloudinary
**ITM Skills University**

---

## 🌟 Overview
The **MCQ Exam Portal** is an end-to-end full-stack assessment platform featuring:
- **Admin Panel**: Upload Excel spreadsheets (`.xlsx`/`.csv`) to create exams, real-time question preview, automated validation, student attempt tracking, and analytics dashboards with Cloudinary report exports.
- **Role-Based Authentication**: Secure access for Admins and Students with role-based dashboard routing.
- **Student Exam Interface**: Real-time countdown timer, multi-color Question Palette (Answered, Not Answered, Marked for Review, Not Visited), anti-cheating tab-switch detection, and auto-submit on timeout.
- **Auto-Grading Engine**: Instant result computation with customizable positive/negative marking schemes and letter grade assignment.
- **Automated Scorecard Generation**: Dynamic generation of official PDF result certificates stored securely in Cloudinary storage.
- **Cloudinary Storage**: Cloud-hosted storage for Excel question sheets, candidate profile pictures, generated result scorecards, and report exports.

---

## 🏗️ Architecture & Technology Stack

```
Assgment 5/
├── backend/                       # Node.js + Express REST API
│   ├── sample_files/              # Sample questions Excel files
│   ├── src/
│   │   ├── config/                # Cloudinary & Firebase Admin configuration
│   │   ├── controllers/           # Admin & Student business logic
│   │   ├── middlewares/           # Authentication & RBAC middleware
│   │   ├── routes/                # Express API routes
│   │   ├── services/              # Excel Parser & PDF Result Generator
│   │   ├── utils/                 # Sample generator & test suite
│   │   └── server.js              # Server entry point
│   ├── .env.example
│   └── package.json
└── frontend/                      # Flutter Application (Web & Mobile)
    ├── lib/
    │   ├── models/                # Exam, Question, Attempt, User models
    │   ├── services/              # API Client & Auth Provider state management
    │   ├── theme/                 # Modern UI Theme tokens & colors
    │   ├── screens/
    │   │   ├── auth/              # Login, Register, Auth Wrapper
    │   │   ├── admin/             # Admin Dashboard, Create Exam, Reports, Students
    │   │   └── student/           # Student Dashboard, Exam Screen, Results, History, Profile
    │   └── main.dart
    └── pubspec.yaml
```

---

## 📊 Excel Question File Schema

Admins upload question papers in `.xlsx` or `.csv` format matching the following columns:

| Column Header | Type | Description |
| :--- | :--- | :--- |
| **Question** | Text | The question statement |
| **Option A** | Text | Choice A text |
| **Option B** | Text | Choice B text |
| **Option C** | Text | Choice C text |
| **Option D** | Text | Choice D text |
| **Correct Option** | Character | `A`, `B`, `C`, or `D` |
| **Marks** | Numeric | Positive marks awarded (e.g., `2` or `1`) |
| **Negative Marks** | Numeric | Deduction for wrong choice (e.g., `0.5` or `0.25`) |
| **Explanation** | Text | Optional answer rationale shown to students post-exam |

> 💡 *A ready-to-use sample template is generated at `backend/sample_files/sample_questions.xlsx`.*

---

## ☁️ Cloudinary Storage Organization

All media and documents are segregated into dedicated Cloudinary folders:
- `mcq-portal/excel-sheets/`: Admin-uploaded question sheets (`.xlsx`/`.csv`)
- `mcq-portal/profiles/`: Student & Admin profile avatars
- `mcq-portal/results/`: Dynamically generated PDF result scorecards
- `mcq-portal/reports/`: Exported Excel / PDF performance spreadsheets

---

## 🚀 Quick Start Guide

### 1. Backend Setup
```bash
cd backend

# Install dependencies
npm install

# Copy environment variables
cp .env.example .env

# Generate sample questions Excel file
npm run generate-sample

# Run automated verification tests
npm test

# Start the API server
npm start
# Server starts at http://localhost:5000 (Health: http://localhost:5000/api/health)
```

### 2. Frontend Setup (Flutter)
```bash
cd frontend

# Install Flutter packages
flutter pub get

# Run on Chrome / Web
flutter run -d chrome

# Or run on macOS / Android / iOS
flutter run
```

---

## 🔑 Demo Credentials

| Role | Email | Password | Access |
| :--- | :--- | :--- | :--- |
| **Admin** | `admin@itm.edu` | Any (or click "Admin Demo") | Full exam creation, Excel upload, analytics & export |
| **Student** | `student@itm.edu` | Any (or click "Student Demo") | Browse exams, take timed test, view scorecard & PDF |

---

## 📡 REST API Reference

### Admin Endpoints (`/api/admin`)
- `POST /api/admin/upload-excel`: Uploads file to Cloudinary and returns parsed question preview + validation results.
- `POST /api/admin/exam`: Creates a new exam with questions and parameters.
- `GET /api/admin/exams`: Lists all exams with submission counts.
- `GET /api/admin/exam/:id`: Gets full exam details including question bank.
- `PUT /api/admin/exam/:id`: Updates exam settings.
- `DELETE /api/admin/exam/:id`: Deletes exam and cleans up Cloudinary assets.
- `GET /api/admin/report/:examId`: Exam analytics, pass rate, score distribution, topper list.
- `GET /api/admin/report/:examId/export`: Exports report to Excel on Cloudinary.
- `GET /api/admin/students`: Directory of registered students.

### Student Endpoints (`/api/student`)
- `POST /api/student/upload-profile`: Uploads candidate profile picture to Cloudinary.
- `GET /api/student/exams`: Lists active and available exams.
- `POST /api/student/exam/:id/start`: Retrieves sanitized question set for exam session.
- `POST /api/student/exam/:id/submit`: Submits answers, executes auto-grading, generates Cloudinary PDF scorecard, returns result.
- `GET /api/student/result/:attemptId`: Retrieves result metrics & question-by-question explanations.
- `GET /api/student/result/:attemptId/pdf`: Retrieves Cloudinary PDF download link.
- `GET /api/student/history`: Lists student's previous attempts and scores.
