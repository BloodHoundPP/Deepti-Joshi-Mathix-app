import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/attendance_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_badge.dart';
import 'create_attendance_screen.dart';

class AttendanceDetailsScreen extends StatefulWidget {
  final AttendanceRecordModel attendanceRecord;

  const AttendanceDetailsScreen({super.key, required this.attendanceRecord});

  @override
  State<AttendanceDetailsScreen> createState() => _AttendanceDetailsScreenState();
}

class _AttendanceDetailsScreenState extends State<AttendanceDetailsScreen> {
  AttendanceSortMode _sortMode = AttendanceSortMode.alphabetical;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final record = widget.attendanceRecord;
    final batch = provider.getBatchById(record.batchId);
    final allStudents = provider.getStudentsByBatch(record.batchId);

    final filteredStudents = allStudents.where((student) {
      final isPresent = record.records[student.id] ?? false;
      if (_sortMode == AttendanceSortMode.presentOnly && !isPresent) return false;
      if (_sortMode == AttendanceSortMode.absentOnly && isPresent) return false;
      return true;
    }).toList();

    filteredStudents.sort((a, b) {
      final isPresA = record.records[a.id] ?? false;
      final isPresB = record.records[b.id] ?? false;
      if (_sortMode == AttendanceSortMode.presentFirst) {
        if (isPresA != isPresB) {
          return isPresA ? -1 : 1;
        }
      } else if (_sortMode == AttendanceSortMode.absentFirst) {
        if (isPresA != isPresB) {
          return !isPresA ? -1 : 1;
        }
      }
      return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
    });

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
                  builder: (_) => CreateAttendanceScreen(existingRecord: record),
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
                          DateFormat('dd MMMM yyyy').format(record.attendanceDate),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (record.topicTaught.isNotEmpty) ...[
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
                        record.topicTaught,
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
                        _summaryBlock('Present', '${record.presentCount}', AppColors.success),
                        _summaryBlock('Absent', '${record.absentCount}', AppColors.error),
                        _summaryBlock('Attendance', '${record.percentage.toStringAsFixed(0)}%', AppColors.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Student Roster',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  Text(
                    'Showing ${filteredStudents.length} of ${allStudents.length}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Horizontal Sort & Filter Chips
            if (allStudents.isNotEmpty) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      avatar: const Icon(Icons.sort_by_alpha, size: 16),
                      selected: _sortMode == AttendanceSortMode.alphabetical,
                      label: Text('Alphabetical (A-Z) (${allStudents.length})'),
                      onSelected: (selected) {
                        if (selected) setState(() => _sortMode = AttendanceSortMode.alphabetical);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                      selected: _sortMode == AttendanceSortMode.presentFirst,
                      label: Text('Present First (${record.presentCount})'),
                      onSelected: (selected) {
                        if (selected) setState(() => _sortMode = AttendanceSortMode.presentFirst);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: const Icon(Icons.highlight_off, size: 16, color: AppColors.error),
                      selected: _sortMode == AttendanceSortMode.absentFirst,
                      label: Text('Absent First (${record.absentCount})'),
                      onSelected: (selected) {
                        if (selected) setState(() => _sortMode = AttendanceSortMode.absentFirst);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                      selected: _sortMode == AttendanceSortMode.presentOnly,
                      label: Text('Present Only (${record.presentCount})'),
                      onSelected: (selected) {
                        if (selected) setState(() => _sortMode = AttendanceSortMode.presentOnly);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: const Icon(Icons.cancel, size: 16, color: AppColors.error),
                      selected: _sortMode == AttendanceSortMode.absentOnly,
                      label: Text('Absent Only (${record.absentCount})'),
                      onSelected: (selected) {
                        if (selected) setState(() => _sortMode = AttendanceSortMode.absentOnly);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            filteredStudents.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          const Icon(Icons.filter_list_off, size: 40, color: AppColors.textMuted),
                          const SizedBox(height: 8),
                          const Text('No students match this filter', style: TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => setState(() => _sortMode = AttendanceSortMode.alphabetical),
                            child: const Text('Show All Students'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredStudents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      final isPresent = record.records[student.id] ?? false;

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
              provider.deleteAttendanceRecord(widget.attendanceRecord.id);
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
