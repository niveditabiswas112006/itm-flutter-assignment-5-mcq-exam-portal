const PDFDocument = require('pdfkit');
const { uploadBuffer, CLOUDINARY_FOLDERS } = require('../config/cloudinary');

/**
 * Generates an elegant PDF Result Card for an exam attempt and uploads it to Cloudinary
 * @param {Object} resultData - Attempt and exam data
 * @returns {Promise<Object>} { pdfUrl, publicId }
 */
const generateResultPdf = async (resultData) => {
  return new Promise((resolve, reject) => {
    try {
      const doc = new PDFDocument({ margin: 40, size: 'A4' });
      const buffers = [];

      doc.on('data', buffers.push.bind(buffers));
      doc.on('end', async () => {
        const pdfBuffer = Buffer.concat(buffers);
        try {
          // Upload generated PDF to Cloudinary
          const uploadResult = await uploadBuffer(pdfBuffer, {
            folder: CLOUDINARY_FOLDERS.RESULTS,
            resource_type: 'raw',
            format: 'pdf',
            public_id: `result_${resultData.attemptId || Date.now()}`,
          });

          resolve({
            pdfUrl: uploadResult.secure_url || uploadResult.url,
            publicId: uploadResult.public_id,
            bytes: pdfBuffer.length,
          });
        } catch (uploadErr) {
          reject(uploadErr);
        }
      });

      // === PDF CONTENT DESIGN ===
      // Primary Header Banner
      doc.rect(0, 0, 595.28, 90).fill('#1E293B');
      
      doc.fillColor('#FFFFFF')
        .fontSize(22)
        .font('Helvetica-Bold')
        .text('ITM SKILLS UNIVERSITY', 40, 25);

      doc.fontSize(12)
        .font('Helvetica')
        .fillColor('#94A3B8')
        .text('OFFICIAL MCQ EXAM RESULT CARD & CERTIFICATE', 40, 52);

      // Status Pill (Pass/Fail)
      const isPass = resultData.status === 'PASS';
      const statusColor = isPass ? '#10B981' : '#EF4444';
      
      doc.roundedRect(440, 25, 115, 38, 6)
        .fill(statusColor);

      doc.fillColor('#FFFFFF')
        .fontSize(14)
        .font('Helvetica-Bold')
        .text(resultData.status || 'PASS', 440, 36, { width: 115, align: 'center' });

      // Student & Exam Information Section
      doc.moveDown(4);
      doc.fillColor('#0F172A')
        .fontSize(16)
        .font('Helvetica-Bold')
        .text(resultData.examTitle || 'MCQ Examination', 40, 115);

      doc.strokeColor('#E2E8F0')
        .lineWidth(1)
        .moveTo(40, 140)
        .lineTo(555, 140)
        .stroke();

      // Info Grid
      doc.fontSize(10).font('Helvetica');
      const startY = 155;
      const lineHeight = 20;

      doc.fillColor('#64748B').text('Student Name:', 40, startY);
      doc.fillColor('#0F172A').font('Helvetica-Bold').text(resultData.studentName || 'Student', 140, startY);

      doc.fillColor('#64748B').font('Helvetica').text('Student Email:', 40, startY + lineHeight);
      doc.fillColor('#0F172A').font('Helvetica-Bold').text(resultData.studentEmail || 'student@example.com', 140, startY + lineHeight);

      doc.fillColor('#64748B').font('Helvetica').text('Student ID / Roll:', 40, startY + lineHeight * 2);
      doc.fillColor('#0F172A').font('Helvetica-Bold').text(resultData.studentId || resultData.userId || 'N/A', 140, startY + lineHeight * 2);

      doc.fillColor('#64748B').font('Helvetica').text('Attempt ID:', 340, startY);
      doc.fillColor('#0F172A').font('Helvetica-Bold').text(resultData.attemptId ? resultData.attemptId.substring(0, 14) : 'N/A', 430, startY);

      doc.fillColor('#64748B').font('Helvetica').text('Date & Time:', 340, startY + lineHeight);
      doc.fillColor('#0F172A').font('Helvetica-Bold').text(new Date(resultData.submittedAt || Date.now()).toLocaleString(), 430, startY + lineHeight);

      doc.fillColor('#64748B').font('Helvetica').text('Time Taken:', 340, startY + lineHeight * 2);
      doc.fillColor('#0F172A').font('Helvetica-Bold').text(`${resultData.timeTakenMinutes || 0} mins`, 430, startY + lineHeight * 2);

      // Score Metrics Cards
      const cardY = startY + lineHeight * 3 + 20;
      const cardWidth = 118;
      const cardHeight = 65;

      const metrics = [
        { label: 'Score Obtained', value: `${resultData.score || 0} / ${resultData.totalMarks || 0}`, color: '#2563EB' },
        { label: 'Percentage', value: `${(resultData.percentage || 0).toFixed(1)}%`, color: '#7C3AED' },
        { label: 'Grade', value: resultData.grade || 'A', color: '#059669' },
        { label: 'Accuracy', value: `${(resultData.accuracy || 0).toFixed(1)}%`, color: '#D97706' },
      ];

      metrics.forEach((m, idx) => {
        const x = 40 + idx * (cardWidth + 14);
        doc.roundedRect(x, cardY, cardWidth, cardHeight, 6)
          .fill('#F8FAFC')
          .strokeColor('#E2E8F0')
          .lineWidth(1)
          .stroke();

        doc.fillColor('#64748B')
          .fontSize(9)
          .font('Helvetica')
          .text(m.label, x, cardY + 12, { width: cardWidth, align: 'center' });

        doc.fillColor(m.color)
          .fontSize(16)
          .font('Helvetica-Bold')
          .text(m.value, x, cardY + 30, { width: cardWidth, align: 'center' });
      });

      // Question Breakdown Summary
      const breakdownY = cardY + cardHeight + 25;
      doc.fillColor('#0F172A')
        .fontSize(12)
        .font('Helvetica-Bold')
        .text('Performance Breakdown', 40, breakdownY);

      const items = [
        { label: 'Correct Questions', count: resultData.correctCount || 0, color: '#10B981' },
        { label: 'Wrong Questions', count: resultData.wrongCount || 0, color: '#EF4444' },
        { label: 'Unattempted Questions', count: resultData.unattemptedCount || 0, color: '#6B7280' },
        { label: 'Total Questions', count: resultData.totalQuestions || 0, color: '#3B82F6' },
      ];

      let rowY = breakdownY + 20;
      items.forEach((item) => {
        doc.circle(48, rowY + 5, 4).fill(item.color);
        doc.fillColor('#334155').fontSize(10).font('Helvetica').text(item.label, 60, rowY);
        doc.fillColor('#0F172A').font('Helvetica-Bold').text(item.count.toString(), 250, rowY);
        rowY += 18;
      });

      // Footer
      doc.strokeColor('#E2E8F0')
        .lineWidth(1)
        .moveTo(40, 750)
        .lineTo(555, 750)
        .stroke();

      doc.fillColor('#94A3B8')
        .fontSize(8)
        .font('Helvetica')
        .text('Generated electronically by ITM MCQ Exam Portal • Verified on Cloudinary Storage', 40, 760, {
          align: 'center',
          width: 515,
        });

      doc.end();
    } catch (err) {
      reject(err);
    }
  });
};

module.exports = {
  generateResultPdf,
};
