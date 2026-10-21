import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/student_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state.dart';
import 'create_student_screen.dart';
import '../fees/create_fee_screen.dart';
import '../fees/payment_details_dialog.dart';
import '../reports/student_report_screen.dart';

class StudentDetailsScreen extends StatefulWidget {
  final String studentId;

  const StudentDetailsScreen({super.key, required this.studentId});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final student = provider.getStudentById(widget.studentId);

    if (student == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student Details')),
        body: const Center(child: Text('Student not found')),
      );
    }

    final batch = provider.getBatchById(student.batchId);
    final studentMarks = provider.getMarksForStudent(student.id);
    final studentFees = provider.getFeesForStudent(student.id);
    final attendanceRate = provider.getStudentAttendancePercentage(student.id, student.batchId);

    return Scaffold(
      appBar: AppBar(
        title: Text(student.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Download PDF Report',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentReportScreen(initialStudentId: student.id),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateStudentScreen(existingStudent: student),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Delete Student',
            onPressed: () => _confirmDelete(context, student),
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile Banner Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        student.fullName.isNotEmpty ? student.fullName[0] : 'S',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            batch != null ? '${batch.batchName} (${batch.standard})' : 'Unassigned Batch',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (student.school.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              student.school,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Contact Details Row
                Row(
                  children: [
                    Expanded(
                      child: _infoTile(
                        icon: Icons.phone_android_rounded,
                        label: 'Student Phone',
                        value: student.phone.isNotEmpty ? student.phone : 'Not provided',
                      ),
                    ),
                    Expanded(
                      child: _infoTile(
                        icon: Icons.supervised_user_circle_outlined,
                        label: 'Parent Phone',
                        value: student.parentPhone.isNotEmpty ? student.parentPhone : 'Not provided',
                      ),
                    ),
                  ],
                ),
                if (student.address.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _infoTile(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    value: student.address,
                  ),
                ],
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'Test Scores (${studentMarks.length})'),
              Tab(text: 'Attendance (${attendanceRate.toStringAsFixed(0)}%)'),
              Tab(text: 'Fees & Dues (${studentFees.length})'),
            ],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Test Scores Tab
                studentMarks.isEmpty
                    ? const EmptyStateWidget(
                        title: 'No Test Scores Recorded',
                        description: 'Academic tests and evaluation marks will show up here.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: studentMarks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final mark = studentMarks[index];
                          final test = provider.getTestById(mark.testId);
                          final total = test?.totalMarks ?? 100;
                          final pct = (mark.marksObtained / total) * 100;
                          final isPassed = mark.marksObtained >= (test?.passingMarks ?? 40);

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          test?.testTitle ?? 'Test Assessment',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isPassed ? AppColors.successLight : AppColors.errorLight,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isPassed ? 'Passed' : 'Needs Attention',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: isPassed ? AppColors.success : AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Score: ${mark.marksObtained.toStringAsFixed(1)} / $total (${pct.toStringAsFixed(1)}%)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (mark.remarks.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Remark: ${mark.remarks}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontStyle: FontStyle.italic,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                // 2. Attendance Tab
                _buildAttendanceTab(provider, student),

                // 3. Fees Tab
                _buildFeesTab(context, provider, student, studentFees),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              Text(
                value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceTab(AppProvider provider, StudentModel student) {
    final batchSessions = provider.getAttendanceByBatch(student.batchId);

    if (batchSessions.isEmpty) {
      return const EmptyStateWidget(
        title: 'No Attendance Records',
        description: 'No sessions have been conducted for this batch yet.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: batchSessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final session = batchSessions[index];
        final isPresent = session.records[student.id] ?? false;

        return Card(
          child: ListTile(
            title: Text(
              DateFormat('EEEE, dd MMM yyyy').format(session.attendanceDate),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              session.topicTaught.isNotEmpty ? session.topicTaught : 'Batch Session',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: AttendanceBadge(isPresent: isPresent),
          ),
        );
      },
    );
  }

  Widget _buildFeesTab(
    BuildContext context,
    AppProvider provider,
    StudentModel student,
    List fees,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fee Invoices & Payments',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Fee Record'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateFeeScreen(defaultStudentId: student.id),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: fees.isEmpty
              ? EmptyStateWidget(
                  title: 'No Fee Records Found',
                  description: 'Generate a tuition fee schedule or payment invoice.',
                  buttonText: 'Add Fee Record',
                  onButtonPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateFeeScreen(defaultStudentId: student.id),
                      ),
                    );
                  },
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: fees.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final fee = fees[index];
                    return Card(
                      child: ListTile(
                        title: Text(fee.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          'Paid: ₹${fee.paidAmount.toStringAsFixed(0)} / ₹${fee.totalAmount.toStringAsFixed(0)} • Due: ${DateFormat('dd MMM').format(fee.dueDate)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FeeStatusBadge(status: fee.status),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => PaymentDetailsDialog(fee: fee),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, StudentModel student) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Student?'),
        content: Text('Are you sure you want to delete "${student.fullName}"? All test and fee records will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Provider.of<AppProvider>(context, listen: false).deleteStudent(student.id);
              Navigator.pop(dialogCtx);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
