import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/student_model.dart';
import '../../models/attendance_model.dart';
import '../../models/fee_model.dart';
import '../../providers/app_provider.dart';
import '../../services/report_pdf_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';

class StudentReportScreen extends StatefulWidget {
  final String? initialStudentId;

  const StudentReportScreen({super.key, this.initialStudentId});

  @override
  State<StudentReportScreen> createState() => _StudentReportScreenState();
}

class _StudentReportScreenState extends State<StudentReportScreen> {
  String? _selectedStudentId;
  int _selectedPeriodIndex = 0; // Default to 1 Month
  int _attendanceFilterIndex = 0; // 0: All, 1: Present, 2: Absent
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.initialStudentId;
  }

  (DateTime startDate, DateTime endDate) _getDateRange(int? months) {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    if (months == null) {
      return (DateTime(2020, 1, 1), end);
    }
    final start = DateTime(now.year, now.month - months, now.day);
    return (start, end);
  }

  Future<void> _generateAndDownloadPdf({
    required StudentModel student,
    required AppProvider provider,
  }) async {
    setState(() => _isGeneratingPdf = true);
    try {
      final period = ReportPeriod.periods[_selectedPeriodIndex];
      final (start, end) = _getDateRange(period.months);

      final batch = provider.getBatchById(student.batchId);
      final tests = provider.tests;
      final marks = provider.getMarksForStudent(student.id);
      final attendance = provider.attendance;
      final fees = provider.getFeesForStudent(student.id);

      await ReportPdfService.downloadOrPrintReport(
        student: student,
        batch: batch,
        tests: tests,
        marks: marks,
        attendanceSessions: attendance,
        fees: fees,
        periodLabel: period.label,
        startDate: start,
        endDate: end,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final students = provider.students;

    if (_selectedStudentId == null && students.isNotEmpty) {
      _selectedStudentId = students.first.id;
    }

    final selectedStudent =
        students.where((s) => s.id == _selectedStudentId).firstOrNull;
    final batch = selectedStudent != null
        ? provider.getBatchById(selectedStudent.batchId)
        : null;

    final selectedPeriod = ReportPeriod.periods[_selectedPeriodIndex];
    final (startDate, endDate) = _getDateRange(selectedPeriod.months);

    // Compute metrics & extract detailed items for selected student & period
    List<Map<String, dynamic>> periodMarks = [];
    List<Map<String, dynamic>> periodAttendance = [];
    List<FeeRecordModel> periodFees = [];
    int presentSessions = 0;
    int totalSessions = 0;
    double totalFeeInvoiced = 0;
    double totalFeePaid = 0;

    if (selectedStudent != null) {
      // 1. Tests in period
      final allMarks = provider.getMarksForStudent(selectedStudent.id);
      for (final m in allMarks) {
        final t = provider.getTestById(m.testId);
        if (t != null &&
            t.testDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            t.testDate.isBefore(endDate.add(const Duration(days: 1)))) {
          periodMarks.add({'test': t, 'mark': m});
        }
      }
      periodMarks.sort((a, b) =>
          (b['test'] as dynamic).testDate.compareTo((a['test'] as dynamic).testDate));

      // 2. Attendance sessions in period
      for (final session in provider.attendance) {
        if (session.batchId == selectedStudent.batchId &&
            session.attendanceDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            session.attendanceDate.isBefore(endDate.add(const Duration(days: 1)))) {
          totalSessions++;
          final isPresent = session.records[selectedStudent.id] == true;
          if (isPresent) {
            presentSessions++;
          }
          periodAttendance.add({
            'session': session,
            'isPresent': isPresent,
          });
        }
      }
      periodAttendance.sort((a, b) =>
          (b['session'] as AttendanceRecordModel).attendanceDate.compareTo(
              (a['session'] as AttendanceRecordModel).attendanceDate));

      // 3. Tuition Fees & Installments in period
      final studentFees = provider.getFeesForStudent(selectedStudent.id);
      for (final f in studentFees) {
        if (f.dueDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            f.dueDate.isBefore(endDate.add(const Duration(days: 1)))) {
          periodFees.add(f);
          totalFeeInvoiced += f.totalAmount;
          totalFeePaid += f.paidAmount;
        }
      }
      periodFees.sort((a, b) => b.dueDate.compareTo(a.dueDate));
    }

    final int absentSessions = totalSessions - presentSessions;
    final attendanceRate =
        totalSessions > 0 ? (presentSessions / totalSessions) * 100 : 100.0;

    double totalScored = 0;
    double totalMax = 0;
    for (final pm in periodMarks) {
      totalScored += (pm['mark'].marksObtained as num).toDouble();
      totalMax += (pm['test'].totalMarks as num).toDouble();
    }
    final academicAverage = totalMax > 0 ? (totalScored / totalMax) * 100 : 0.0;

    // Filter attendance list based on chip
    final filteredAttendance = periodAttendance.where((item) {
      if (_attendanceFilterIndex == 1) return item['isPresent'] == true;
      if (_attendanceFilterIndex == 2) return item['isPresent'] == false;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detailed Student Progress Report'),
        actions: [
          if (selectedStudent != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: _isGeneratingPdf
                    ? null
                    : () => _generateAndDownloadPdf(
                          student: selectedStudent,
                          provider: provider,
                        ),
                icon: _isGeneratingPdf
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text('Download PDF'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ),
        ],
      ),
      body: students.isEmpty
          ? const EmptyStateWidget(
              title: 'No Students Enrolled',
              description: 'Enroll students to generate progress reports.',
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Student & Period Selector Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Student',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedStudentId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            items: students.map((s) {
                              final b = provider.getBatchById(s.batchId);
                              return DropdownMenuItem(
                                value: s.id,
                                child: Text(
                                  '${s.fullName} (${b?.standard ?? 'Batch'})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => _selectedStudentId = val);
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Evaluation Period',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(ReportPeriod.periods.length, (i) {
                              final isSelected = _selectedPeriodIndex == i;
                              return ChoiceChip(
                                label: Text(ReportPeriod.periods[i].label),
                                selected: isSelected,
                                selectedColor: AppColors.primaryLight,
                                labelStyle: TextStyle(
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 12,
                                ),
                                onSelected: (selected) {
                                  if (selected) setState(() => _selectedPeriodIndex = i);
                                },
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (selectedStudent != null) ...[
                    // 2. Student Header Overview Banner
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Text(
                              selectedStudent.fullName.isNotEmpty
                                  ? selectedStudent.fullName[0]
                                  : 'S',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedStudent.fullName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${batch?.batchName ?? 'Batch'} • ${batch?.standard ?? ''}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                if (selectedStudent.school.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedStudent.school,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Performance KPI Stat Cards
                    Row(
                      children: [
                        Expanded(
                          child: _metricCard(
                            title: 'Attendance',
                            value: '${attendanceRate.toStringAsFixed(0)}%',
                            subtitle: '$presentSessions / $totalSessions Sessions',
                            color: attendanceRate >= 75
                                ? AppColors.success
                                : AppColors.error,
                            icon: Icons.how_to_reg_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _metricCard(
                            title: 'Academic Score',
                            value: totalMax > 0
                                ? '${academicAverage.toStringAsFixed(1)}%'
                                : 'N/A',
                            subtitle: '${periodMarks.length} Tests in Period',
                            color: academicAverage >= 60
                                ? AppColors.primary
                                : AppColors.warning,
                            icon: Icons.assignment_turned_in_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _metricCard(
                            title: 'Fees Paid',
                            value: '₹${totalFeePaid.toStringAsFixed(0)}',
                            subtitle:
                                'Invoiced: ₹${totalFeeInvoiced.toStringAsFixed(0)}',
                            color: AppColors.success,
                            icon: Icons.payments_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _metricCard(
                            title: 'Fee Dues',
                            value:
                                '₹${(totalFeeInvoiced - totalFeePaid).clamp(0.0, totalFeeInvoiced).toStringAsFixed(0)}',
                            subtitle: (totalFeeInvoiced - totalFeePaid) <= 0
                                ? 'Fully Paid'
                                : 'Balance Pending',
                            color: (totalFeeInvoiced - totalFeePaid) <= 0
                                ? AppColors.success
                                : AppColors.error,
                            icon: Icons.account_balance_wallet_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 4. Detailed Attendance Log Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.successLight,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.calendar_month_rounded,
                                          color: AppColors.success,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Text(
                                          'Detailed Attendance Log',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: attendanceRate >= 75
                                        ? AppColors.successLight
                                        : AppColors.errorLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${attendanceRate.toStringAsFixed(0)}% Regularity',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: attendanceRate >= 75
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Attendance Summary Pills
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _attendanceSummaryStat(
                                    'Total Held',
                                    '$totalSessions',
                                    AppColors.textPrimary,
                                  ),
                                  const SizedBox(
                                      height: 24, child: VerticalDivider(width: 1)),
                                  _attendanceSummaryStat(
                                    'Present',
                                    '$presentSessions',
                                    AppColors.success,
                                  ),
                                  const SizedBox(
                                      height: 24, child: VerticalDivider(width: 1)),
                                  _attendanceSummaryStat(
                                    'Absent',
                                    '$absentSessions',
                                    absentSessions > 0
                                        ? AppColors.error
                                        : AppColors.textMuted,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Attendance Filter Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _filterChip('All ($totalSessions)', 0),
                                  const SizedBox(width: 8),
                                  _filterChip('Present ($presentSessions)', 1),
                                  const SizedBox(width: 8),
                                  _filterChip('Absent ($absentSessions)', 2),
                                ],
                              ),
                            ),
                            const Divider(height: 20),

                            if (filteredAttendance.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    totalSessions == 0
                                        ? 'No attendance sessions recorded in this period.'
                                        : 'No attendance records matching this filter.',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredAttendance.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 16),
                                itemBuilder: (context, idx) {
                                  final item = filteredAttendance[idx];
                                  final session =
                                      item['session'] as AttendanceRecordModel;
                                  final isPresent = item['isPresent'] as bool;

                                  return Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isPresent
                                              ? AppColors.successLight
                                              : AppColors.errorLight,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          isPresent
                                              ? Icons.check_circle_rounded
                                              : Icons.cancel_rounded,
                                          color: isPresent
                                              ? AppColors.success
                                              : AppColors.error,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              DateFormat('EEEE, dd MMM yyyy')
                                                  .format(session.attendanceDate),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              session.topicTaught.isNotEmpty
                                                  ? session.topicTaught
                                                  : 'Mathematics Coaching Session',
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isPresent
                                                  ? AppColors.successLight
                                                  : AppColors.errorLight,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isPresent ? 'PRESENT' : 'ABSENT',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 11,
                                                color: isPresent
                                                    ? AppColors.success
                                                    : AppColors.error,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Batch: ${session.presentCount}/${session.totalCount}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. Test Scores Table Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.assignment_rounded,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Text(
                                          'Academic Test Results',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${periodMarks.length} Tests',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            if (periodMarks.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    'No tests evaluated during this selected timeframe.',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: periodMarks.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 16),
                                itemBuilder: (context, idx) {
                                  final item = periodMarks[idx];
                                  final t = item['test'];
                                  final m = item['mark'];
                                  final pct = (m.marksObtained / t.totalMarks) * 100;
                                  final isPass = m.marksObtained >= t.passingMarks;

                                  return Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              t.testTitle,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${DateFormat('dd MMM yyyy').format(t.testDate)} • ${t.chapter.isNotEmpty ? t.chapter : 'Mathematics'}',
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${m.marksObtained} / ${t.totalMarks} (${pct.toStringAsFixed(0)}%)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                              color: isPass
                                                  ? AppColors.textPrimary
                                                  : AppColors.error,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isPass ? 'Passed' : 'Needs Practice',
                                            style: TextStyle(
                                              color: isPass
                                                  ? AppColors.success
                                                  : AppColors.error,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 6. Detailed Tuition Fee & Installments Ledger Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryLight,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.account_balance_wallet_rounded,
                                          color: AppColors.secondary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Text(
                                          'Tuition Fee & Installments',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${periodFees.length} Invoices',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            if (periodFees.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    'No tuition fees billed during this evaluation period.',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: periodFees.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 16),
                                itemBuilder: (context, idx) {
                                  final fee = periodFees[idx];
                                  final isFullyPaid = fee.pendingAmount <= 0;

                                  return Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primaryLight,
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    fee.installment,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    fee.title,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Due: ${DateFormat('dd MMM yyyy').format(fee.dueDate)}',
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₹${fee.paidAmount.toStringAsFixed(0)} / ₹${fee.totalAmount.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isFullyPaid
                                                ? 'Paid in Full'
                                                : '₹${fee.pendingAmount.toStringAsFixed(0)} due',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isFullyPaid
                                                  ? AppColors.success
                                                  : AppColors.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 7. Download PDF Large CTA Button
                    ElevatedButton.icon(
                      onPressed: _isGeneratingPdf
                          ? null
                          : () => _generateAndDownloadPdf(
                                student: selectedStudent,
                                provider: provider,
                              ),
                      icon: _isGeneratingPdf
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download_rounded),
                      label: Text(_isGeneratingPdf
                          ? 'Generating PDF Report...'
                          : 'Download & Print Detailed Progress Report (PDF)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _filterChip(String label, int index) {
    final isSelected = _attendanceFilterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 11,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _attendanceFilterIndex = index);
      },
    );
  }

  Widget _attendanceSummaryStat(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
