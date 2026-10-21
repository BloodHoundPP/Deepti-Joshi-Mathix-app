import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/attendance_model.dart';
import '../../models/student_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';

class CreateAttendanceScreen extends StatefulWidget {
  final String? defaultBatchId;
  final AttendanceRecordModel? existingRecord;

  const CreateAttendanceScreen({
    super.key,
    this.defaultBatchId,
    this.existingRecord,
  });

  @override
  State<CreateAttendanceScreen> createState() => _CreateAttendanceScreenState();
}

class _CreateAttendanceScreenState extends State<CreateAttendanceScreen> {
  String? _selectedBatchId;
  late DateTime _selectedDate;
  late TextEditingController _topicController;
  final Map<String, bool> _attendanceMap = {};
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final rec = widget.existingRecord;
    _selectedBatchId = rec?.batchId ?? widget.defaultBatchId;
    _selectedDate = rec?.attendanceDate ?? DateTime.now();
    _topicController = TextEditingController(text: rec?.topicTaught ?? '');

    if (rec != null) {
      _attendanceMap.addAll(rec.records);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  void _syncStudents(List<StudentModel> students) {
    if (_initialized) return;
    for (final s in students) {
      _attendanceMap.putIfAbsent(s.id, () => true); // default present
    }
    _initialized = true;
  }

  void _markAll(bool status, List<StudentModel> students) {
    setState(() {
      for (final s in students) {
        _attendanceMap[s.id] = status;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveAttendance() async {
    if (_selectedBatchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a batch')),
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);
    final rec = AttendanceRecordModel(
      id: widget.existingRecord?.id ?? 'att_${DateTime.now().millisecondsSinceEpoch}',
      batchId: _selectedBatchId!,
      attendanceDate: _selectedDate,
      records: Map.from(_attendanceMap),
      topicTaught: _topicController.text.trim(),
    );

    await provider.saveAttendanceSession(rec);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance session saved successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final batches = provider.batches;

    if (_selectedBatchId == null && batches.isNotEmpty) {
      _selectedBatchId = batches.first.id;
    }

    final students = _selectedBatchId != null ? provider.getStudentsByBatch(_selectedBatchId!) : <StudentModel>[];
    _syncStudents(students);

    final presentCount = _attendanceMap.values.where((v) => v).length;
    final totalCount = students.length;
    final pct = totalCount == 0 ? 0.0 : (presentCount / totalCount) * 100;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingRecord != null ? 'Edit Attendance' : 'Mark Attendance Session'),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: students.isEmpty ? null : _saveAttendance,
          icon: const Icon(Icons.check_circle_rounded),
          label: Text('Save Attendance ($presentCount / $totalCount Present)'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Batch & Date Configuration Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedBatchId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Batch',
                        prefixIcon: Icon(Icons.group_work_outlined),
                      ),
                      items: batches.map((b) {
                        return DropdownMenuItem(
                          value: b.id,
                          child: Text(
                            '${b.batchName} (${b.standard})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedBatchId = val;
                          _initialized = false;
                          _attendanceMap.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Session Date',
                          prefixIcon: Icon(Icons.calendar_today_rounded),
                        ),
                        child: Text(
                          DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _topicController,
                      decoration: const InputDecoration(
                        labelText: 'Topic / Lesson Taught',
                        hintText: 'e.g. Quadratic Equations - Discriminant method',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bulk Quick Actions & Stats Bar
            if (students.isNotEmpty)
              Card(
                color: AppColors.primaryLight.withOpacity(0.4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$presentCount of $totalCount Present',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Attendance Rate: ${pct.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: pct >= 75 ? AppColors.success : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _markAll(true, students),
                        icon: const Icon(Icons.done_all, size: 16, color: AppColors.success),
                        label: const Text('All Present', style: TextStyle(color: AppColors.success)),
                      ),
                      TextButton.icon(
                        onPressed: () => _markAll(false, students),
                        icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                        label: const Text('All Absent', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Student Toggles
            students.isEmpty
                ? const EmptyStateWidget(
                    title: 'No Students in Batch',
                    description: 'Add students to this batch before marking attendance.',
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: students.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final isPresent = _attendanceMap[student.id] ?? true;

                      return Card(
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          secondary: CircleAvatar(
                            backgroundColor: isPresent ? AppColors.successLight : AppColors.errorLight,
                            child: Icon(
                              isPresent ? Icons.check : Icons.close,
                              color: isPresent ? AppColors.success : AppColors.error,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            student.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          subtitle: Text(
                            isPresent ? 'Present' : 'Absent',
                            style: TextStyle(
                              color: isPresent ? AppColors.success : AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          value: isPresent,
                          activeThumbColor: AppColors.success,
                          activeTrackColor: AppColors.successLight,
                          inactiveThumbColor: AppColors.error,
                          inactiveTrackColor: AppColors.errorLight,
                          onChanged: (val) {
                            setState(() {
                              _attendanceMap[student.id] = val;
                            });
                          },
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
