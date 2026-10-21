import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/student_model.dart';
import '../models/batch_model.dart';
import '../models/test_model.dart';
import '../models/attendance_model.dart';
import '../models/fee_model.dart';

class ReportPeriod {
  final String label;
  final int? months;

  const ReportPeriod(this.label, this.months);

  static const periods = [
    ReportPeriod('1 Month (Monthly)', 1),
    ReportPeriod('2 Months', 2),
    ReportPeriod('3 Months (Quarterly)', 3),
    ReportPeriod('6 Months (Half-Yearly)', 6),
    ReportPeriod('1 Year (Yearly)', 12),
    ReportPeriod('All-Time (Complete)', null),
  ];
}

class ReportPdfService {
  static Future<Uint8List> generateStudentReportPdf({
    required StudentModel student,
    required BatchModel? batch,
    required List<TestModel> tests,
    required List<StudentTestMarkModel> marks,
    required List<AttendanceRecordModel> attendanceSessions,
    required List<FeeRecordModel> fees,
    required String periodLabel,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();

    // Filter tests by period
    final periodMarks = <Map<String, dynamic>>[];
    for (final mark in marks) {
      final test = tests.where((t) => t.id == mark.testId).firstOrNull;
      if (test != null &&
          test.testDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          test.testDate.isBefore(endDate.add(const Duration(days: 1)))) {
        periodMarks.add({
          'test': test,
          'mark': mark,
        });
      }
    }

    // Filter attendance by period
    final periodAttendance = <AttendanceRecordModel>[];
    int presentSessions = 0;
    int totalSessions = 0;
    for (final session in attendanceSessions) {
      if (session.batchId == student.batchId &&
          session.attendanceDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          session.attendanceDate.isBefore(endDate.add(const Duration(days: 1)))) {
        totalSessions++;
        if (session.records[student.id] == true) {
          presentSessions++;
        }
        periodAttendance.add(session);
      }
    }
    periodAttendance.sort((a, b) => b.attendanceDate.compareTo(a.attendanceDate));
    final attendancePct = totalSessions > 0 ? (presentSessions / totalSessions) * 100 : 100.0;

    // Filter fees
    final periodFees = fees.where((f) {
      return f.dueDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          f.dueDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    double totalFeeInvoiced = 0;
    double totalFeePaid = 0;
    for (final f in periodFees) {
      totalFeeInvoiced += f.totalAmount;
      totalFeePaid += f.paidAmount;
    }

    // Compute academic average
    double totalMarksScored = 0;
    double totalMarksMax = 0;
    for (final item in periodMarks) {
      final mark = item['mark'] as StudentTestMarkModel;
      final test = item['test'] as TestModel;
      totalMarksScored += mark.marksObtained;
      totalMarksMax += test.totalMarks;
    }
    final academicPct = totalMarksMax > 0 ? (totalMarksScored / totalMarksMax) * 100 : 0.0;

    String performanceGrade;
    if (academicPct >= 85) {
      performanceGrade = 'Excellent (Grade A+)';
    } else if (academicPct >= 70) {
      performanceGrade = 'Good (Grade A)';
    } else if (academicPct >= 50) {
      performanceGrade = 'Satisfactory (Grade B)';
    } else if (totalMarksMax == 0) {
      performanceGrade = 'N/A (No tests in period)';
    } else {
      performanceGrade = 'Needs Improvement (Grade C)';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('1E3A8A'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MATHIX ACADEMY',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Mathematics Specialist Tutoring • Prof. Deepti Joshi',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'STUDENT PROGRESS REPORT',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('FBBF24'),
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Period: $periodLabel',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 9,
                        ),
                      ),
                      pw.Text(
                        'Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Student Information Box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
                color: PdfColor.fromHex('F8FAFC'),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Student Name: ${student.fullName}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (student.school.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'School: ${student.school}',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        ),
                      ],
                      if (student.phone.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Phone: ${student.phone}',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        ),
                      ],
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Batch: ${batch?.batchName ?? 'Assigned Batch'}',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Standard: ${batch?.standard ?? 'N/A'}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                      if (student.parentPhone.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Parent Contact: ${student.parentPhone}',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Performance KPI Cards Row
            pw.Row(
              children: [
                pw.Expanded(
                  child: _pdfKpiCard(
                    title: 'Attendance Rate',
                    value: '${attendancePct.toStringAsFixed(0)}%',
                    subvalue: '$presentSessions / $totalSessions Sessions',
                    colorHex: attendancePct >= 75 ? '16A34A' : 'DC2626',
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _pdfKpiCard(
                    title: 'Academic Score',
                    value: totalMarksMax > 0 ? '${academicPct.toStringAsFixed(1)}%' : 'N/A',
                    subvalue: '${periodMarks.length} Tests Assessed',
                    colorHex: academicPct >= 60 ? '2563EB' : 'D97706',
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _pdfKpiCard(
                    title: 'Performance Grade',
                    value: performanceGrade.split('(').first.trim(),
                    subvalue: performanceGrade.contains('(') ? performanceGrade.split('(').last.replaceAll(')', '') : '',
                    colorHex: '7C3AED',
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _pdfKpiCard(
                    title: 'Fee Status',
                    value: (totalFeeInvoiced - totalFeePaid) <= 0 ? 'Clear' : 'Pending',
                    subvalue: 'Paid: Rs. ${totalFeePaid.toStringAsFixed(0)}',
                    colorHex: (totalFeeInvoiced - totalFeePaid) <= 0 ? '16A34A' : 'DC2626',
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Detailed Attendance Register
            pw.Text(
              'Detailed Attendance Register ($presentSessions / $totalSessions Classes Attended - ${attendancePct.toStringAsFixed(0)}%)',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('1E3A8A'),
              ),
            ),
            pw.SizedBox(height: 6),
            if (periodAttendance.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'No attendance sessions conducted during this evaluation period.',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('F1F5F9')),
                headerHeight: 24,
                cellHeight: 20,
                headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                headers: ['Session Date', 'Topic / Chapter Taught', 'Student Attendance', 'Batch Attendance'],
                data: periodAttendance.map((session) {
                  final isPresent = session.records[student.id] == true;
                  return [
                    DateFormat('EEE, dd MMM yyyy').format(session.attendanceDate),
                    session.topicTaught.isNotEmpty ? session.topicTaught : 'Math Coaching Class',
                    isPresent ? 'PRESENT' : 'ABSENT',
                    '${session.presentCount}/${session.totalCount} Attended',
                  ];
                }).toList(),
              ),
            pw.SizedBox(height: 20),

            // Academic Test Scores Section
            pw.Text(
              'Academic Test Performance',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('1E3A8A'),
              ),
            ),
            pw.SizedBox(height: 6),
            if (periodMarks.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'No tests scheduled or completed during this evaluation period.',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('F1F5F9')),
                headerHeight: 24,
                cellHeight: 22,
                headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headers: ['Date', 'Test Title', 'Chapter / Topic', 'Score', 'Max', 'Percentage', 'Status'],
                data: periodMarks.map((item) {
                  final t = item['test'] as TestModel;
                  final m = item['mark'] as StudentTestMarkModel;
                  final pct = (m.marksObtained / t.totalMarks) * 100;
                  final isPass = m.marksObtained >= t.passingMarks;
                  return [
                    DateFormat('dd MMM yy').format(t.testDate),
                    t.testTitle,
                    t.chapter.isNotEmpty ? t.chapter : 'Mathematics',
                    m.marksObtained.toStringAsFixed(1),
                    t.totalMarks.toString(),
                    '${pct.toStringAsFixed(0)}%',
                    isPass ? 'Passed' : 'Needs Retest',
                  ];
                }).toList(),
              ),
            pw.SizedBox(height: 20),

            // Fee Records Summary
            pw.Text(
              'Tuition Fee & Installment Summary',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('1E3A8A'),
              ),
            ),
            pw.SizedBox(height: 6),
            if (periodFees.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'No fee records issued within this duration.',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('F1F5F9')),
                headerHeight: 24,
                cellHeight: 22,
                headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headers: ['Installment', 'Fee Title', 'Due Date', 'Total Amount', 'Paid Amount', 'Balance', 'Status'],
                data: periodFees.map((f) {
                  return [
                    f.installment,
                    f.title,
                    DateFormat('dd MMM yy').format(f.dueDate),
                    'Rs. ${f.totalAmount.toStringAsFixed(0)}',
                    'Rs. ${f.paidAmount.toStringAsFixed(0)}',
                    'Rs. ${f.pendingAmount.toStringAsFixed(0)}',
                    f.status.displayName,
                  ];
                }).toList(),
              ),
            pw.SizedBox(height: 24),

            // Teacher Remarks & Assessment
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('F8FAFC'),
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Teacher\'s Assessment & Observations:',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _generateTeacherRemarks(student.fullName, academicPct, attendancePct),
                    style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800, lineSpacing: 2),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 40),

            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 160,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 1)),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Prof. Deepti Joshi',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Lead Mathematics Faculty & Director',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 160,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 1)),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Parent / Guardian Signature',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Acknowledged & Verified',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfKpiCard({
    required String title,
    required String value,
    required String subvalue,
    required String colorHex,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex(colorHex),
            ),
          ),
          if (subvalue.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              subvalue,
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey500),
            ),
          ],
        ],
      ),
    );
  }

  static String _generateTeacherRemarks(String name, double academicPct, double attendancePct) {
    if (academicPct >= 85 && attendancePct >= 85) {
      return '$name exhibits exemplary commitment in Mathematics. Regular attendance and strong problem-solving fundamentals are clearly reflected in test scores. Keep up the high standard of preparation.';
    } else if (academicPct >= 70) {
      return '$name has demonstrated consistent progress in mathematical concepts. Continued focus on formula practice and speed calculation will help achieve top percentile scores in final exams.';
    } else if (academicPct >= 50) {
      return '$name is showing satisfactory effort. We recommend solving additional chapter-wise problem sets and clearing foundational doubts promptly during doubt sessions.';
    } else {
      return '$name requires focused attention and revision of fundamental mathematical formulas and step-wise proofs. Regular classroom participation and daily homework completion are strongly encouraged.';
    }
  }

  static Future<void> downloadOrPrintReport({
    required StudentModel student,
    required BatchModel? batch,
    required List<TestModel> tests,
    required List<StudentTestMarkModel> marks,
    required List<AttendanceRecordModel> attendanceSessions,
    required List<FeeRecordModel> fees,
    required String periodLabel,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdfBytes = await generateStudentReportPdf(
      student: student,
      batch: batch,
      tests: tests,
      marks: marks,
      attendanceSessions: attendanceSessions,
      fees: fees,
      periodLabel: periodLabel,
      startDate: startDate,
      endDate: endDate,
    );

    final fileName = '${student.fullName.replaceAll(' ', '_')}_Report_${periodLabel.replaceAll(' ', '_')}.pdf';

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: fileName,
    );
  }
}
