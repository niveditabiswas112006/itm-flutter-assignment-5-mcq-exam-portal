const xlsx = require('xlsx');
const path = require('path');
const fs = require('fs');

/**
 * Generates a sample questions Excel file adhering to the assignment requirements
 */
const generateSampleExcel = () => {
  const sampleData = [
    {
      'Question': 'Which programming language is Flutter primarily based on?',
      'Option A': 'Java',
      'Option B': 'Kotlin',
      'Option C': 'Dart',
      'Option D': 'Swift',
      'Correct Option': 'C',
      'Marks': 2,
      'Negative Marks': 0.5,
      'Explanation': 'Flutter uses the Dart programming language created by Google for reactive, fast, multi-platform applications.',
    },
    {
      'Question': 'Which widget is used to arrange children in a vertical direction in Flutter?',
      'Option A': 'Row',
      'Option B': 'Column',
      'Option C': 'Stack',
      'Option D': 'Wrap',
      'Correct Option': 'B',
      'Marks': 2,
      'Negative Marks': 0.5,
      'Explanation': 'Column is a layout widget in Flutter that displays its children in a vertical array.',
    },
    {
      'Question': 'What type of database is Google Cloud Firestore?',
      'Option A': 'Relational SQL',
      'Option B': 'NoSQL Document Database',
      'Option C': 'Graph Database',
      'Option D': 'In-Memory Cache',
      'Correct Option': 'B',
      'Marks': 2,
      'Negative Marks': 0.5,
      'Explanation': 'Cloud Firestore is a flexible, scalable NoSQL cloud database to store and sync data for client- and server-side development.',
    },
    {
      'Question': 'In Cloudinary, what resource type is used for non-media files like Excel spreadsheets and PDFs?',
      'Option A': 'image',
      'Option B': 'video',
      'Option C': 'raw',
      'Option D': 'document',
      'Correct Option': 'C',
      'Marks': 2,
      'Negative Marks': 0.5,
      'Explanation': 'Cloudinary classifies spreadsheets, zips, PDFs, and generic files as "raw" resource type unless transformed into images.',
    },
    {
      'Question': 'Which HTTP status code signifies "Created" in REST APIs?',
      'Option A': '200',
      'Option B': '201',
      'Option C': '204',
      'Option D': '400',
      'Correct Option': 'B',
      'Marks': 2,
      'Negative Marks': 0.5,
      'Explanation': 'HTTP 201 Created indicates that the request has succeeded and has led to the creation of a resource.',
    },
    {
      'Question': 'What is the default port for an Express.js server when PORT is not set?',
      'Option A': '3000',
      'Option B': '8080',
      'Option C': '5000',
      'Option D': '4200',
      'Correct Option': 'C',
      'Marks': 2,
      'Negative Marks': 0.5,
      'Explanation': 'In our MCQ portal configuration, the default fallback port is 5000.',
    },
  ];

  const ws = xlsx.utils.json_to_sheet(sampleData);
  const wb = xlsx.utils.book_new();
  xlsx.utils.book_append_sheet(wb, ws, 'Questions');

  // Also create sample directory in workspace
  const outputDir = path.join(__dirname, '../../sample_files');
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  const filePath = path.join(outputDir, 'sample_questions.xlsx');
  xlsx.writeFile(wb, filePath);
  console.log(`✅ Sample Excel generated at: ${filePath}`);
};

if (require.main === module) {
  generateSampleExcel();
}

module.exports = { generateSampleExcel };
