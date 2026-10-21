import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/attendance_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_badge.dart';
import 'create_attendance_screen.dart';

class AttendanceDetailsScreen extends StatelessWidget {
  final AttendanceRecordModel attendanceRecord;

  const AttendanceDetailsScreen({super.key, required this.attendanceRecord});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final batch = provider.getBatchById(attendanceRecord.batchId);
    final students = provider.getStudentsByBatch(attendanceRecord.batchId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Session Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Session',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateAttendanceScreen(existingRecord: attendanceRecord),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Delete Session',
            onPressed: () => _confirmDelete(context, provider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Session Overview Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            batch?.batchName ?? 'Batch',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('dd MMMM yyyy').format(attendanceRecord.attendanceDate),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (attendanceRecord.topicTaught.isNotEmpty) ...[
                      const Text(
                        'Topic Covered',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        attendanceRecord.topicTaught,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Divider(height: 24),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _summaryBlock('Present', '${attendanceRecord.presentCount}', AppColors.success),
                        _summaryBlock('Absent', '${attendanceRecord.absentCount}', AppColors.error),
                        _summaryBlock('Attendance', '${attendanceRecord.percentage.toStringAsFixed(0)}%', AppColors.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Student Roster',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 10),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: students.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final student = students[index];
                final isPresent = attendanceRecord.records[student.id] ?? false;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: isPresent ? AppColors.successLight : AppColors.errorLight,
                      child: Text(
                        student.fullName.isNotEmpty ? student.fullName[0] : 'S',
                        style: TextStyle(
                          color: isPresent ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: student.school.isNotEmpty ? Text(student.school) : null,
                    trailing: AttendanceBadge(isPresent: isPresent),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryBlock(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  void _confirmDelete(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Session?'),
        content: const Text('Are you sure you want to delete this attendance record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              provider.deleteAttendanceRecord(attendanceRecord.id);
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
