import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/batch_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';
import '../students/student_details_screen.dart';
import '../students/create_student_screen.dart';
import '../attendance/create_attendance_screen.dart';
import '../tests/create_test_screen.dart';
import '../tests/test_details_screen.dart';
import 'create_batch_screen.dart';
import '../../widgets/empty_state.dart';

class BatchDetailsScreen extends StatefulWidget {
  final String batchId;

  const BatchDetailsScreen({super.key, required this.batchId});

  @override
  State<BatchDetailsScreen> createState() => _BatchDetailsScreenState();
}

class _BatchDetailsScreenState extends State<BatchDetailsScreen>
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
    final batch = provider.getBatchById(widget.batchId);

    if (batch == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Batch Details')),
        body: const Center(child: Text('Batch not found')),
      );
    }

    final enrolledStudents = provider.getStudentsByBatch(batch.id);
    final batchTests = provider.getTestsByBatch(batch.id);
    final batchAttendance = provider.getAttendanceByBatch(batch.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(batch.batchName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Batch',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateBatchScreen(existingBatch: batch),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Delete Batch',
            onPressed: () {
              _showDeleteDialog(context, batch);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Batch Header Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        batch.standard,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${enrolledStudents.length} / ${batch.capacity} Students',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  batch.batchName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 16, color: Colors.white70),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        batch.schedule,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Capacity Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (enrolledStudents.length / (batch.capacity == 0 ? 1 : batch.capacity)).clamp(0.0, 1.0),
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          // Quick Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateStudentScreen(defaultBatchId: batch.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add_alt_1, size: 16),
                    label: const Text('Add Student'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateAttendanceScreen(defaultBatchId: batch.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.how_to_reg, size: 16),
                    label: const Text('Attendance'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
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
              Tab(text: 'Students (${enrolledStudents.length})'),
              Tab(text: 'Tests (${batchTests.length})'),
              Tab(text: 'Attendance (${batchAttendance.length})'),
            ],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Students Tab
                enrolledStudents.isEmpty
                    ? EmptyStateWidget(
                        title: 'No Students Enrolled',
                        description: 'Add your first student to this batch.',
                        buttonText: 'Add Student',
                        onButtonPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateStudentScreen(defaultBatchId: batch.id),
                            ),
                          );
                        },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: enrolledStudents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final student = enrolledStudents[index];
                          final attendanceRate = provider.getStudentAttendancePercentage(student.id, batch.id);

                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryLight,
                                child: Text(
                                  student.fullName.isNotEmpty ? student.fullName[0] : 'S',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                student.fullName,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                'Attendance: ${attendanceRate.toStringAsFixed(0)}%',
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StudentDetailsScreen(studentId: student.id),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                // 2. Tests Tab
                batchTests.isEmpty
                    ? EmptyStateWidget(
                        title: 'No Tests Scheduled',
                        description: 'Schedule a chapter or practice test for this batch.',
                        buttonText: 'Schedule Test',
                        onButtonPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateTestScreen(defaultBatchId: batch.id),
                            ),
                          );
                        },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: batchTests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final test = batchTests[index];
                          final marks = provider.getMarksForTest(test.id);

                          return Card(
                            child: ListTile(
                              title: Text(
                                test.testTitle,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                '${DateFormat('dd MMM yyyy').format(test.testDate)} • Total: ${test.totalMarks}M • Marks: ${marks.length}/${enrolledStudents.length}',
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TestDetailsScreen(testId: test.id),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                // 3. Attendance Tab
                batchAttendance.isEmpty
                    ? EmptyStateWidget(
                        title: 'No Attendance Recorded',
                        description: 'Start taking daily attendance logs for this batch.',
                        buttonText: 'Take Attendance',
                        onButtonPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateAttendanceScreen(defaultBatchId: batch.id),
                            ),
                          );
                        },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: batchAttendance.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final att = batchAttendance[index];
                          return Card(
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                              ),
                              title: Text(
                                DateFormat('EEEE, dd MMM yyyy').format(att.attendanceDate),
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                att.topicTaught.isNotEmpty
                                    ? att.topicTaught
                                    : 'Present: ${att.presentCount} / ${att.totalCount} (${att.percentage.toStringAsFixed(0)}%)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                '${att.percentage.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: att.percentage >= 75 ? AppColors.success : AppColors.warning,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, BatchModel batch) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Batch?'),
        content: Text('Are you sure you want to delete "${batch.batchName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Provider.of<AppProvider>(context, listen: false).deleteBatch(batch.id);
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
