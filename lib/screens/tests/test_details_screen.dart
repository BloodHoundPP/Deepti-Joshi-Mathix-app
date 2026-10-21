import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/test_model.dart';
import '../../models/student_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';
import 'create_test_screen.dart';
import '../../widgets/empty_state.dart';

class TestDetailsScreen extends StatefulWidget {
  final String testId;

  const TestDetailsScreen({super.key, required this.testId});

  @override
  State<TestDetailsScreen> createState() => _TestDetailsScreenState();
}

class _TestDetailsScreenState extends State<TestDetailsScreen> {
  final Map<String, TextEditingController> _marksControllers = {};
  final Map<String, TextEditingController> _remarksControllers = {};
  bool _initialized = false;

  @override
  void dispose() {
    for (final c in _marksControllers.values) {
      c.dispose();
    }
    for (final c in _remarksControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initControllers(List<StudentModel> students, AppProvider provider) {
    if (_initialized) return;
    for (final s in students) {
      final existingMark = provider.getMarkForStudentAndTest(s.id, widget.testId);
      _marksControllers[s.id] = TextEditingController(
        text: existingMark != null ? existingMark.marksObtained.toString() : '',
      );
      _remarksControllers[s.id] = TextEditingController(
        text: existingMark?.remarks ?? '',
      );
    }
    _initialized = true;
  }

  void _saveAllMarks(List<StudentModel> students, TestModel test) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final List<StudentTestMarkModel> marksToSave = [];

    for (final s in students) {
      final text = _marksControllers[s.id]?.text.trim() ?? '';
      if (text.isNotEmpty) {
        final val = double.tryParse(text);
        if (val != null) {
          final existing = provider.getMarkForStudentAndTest(s.id, test.id);
          marksToSave.add(
            StudentTestMarkModel(
              id: existing?.id ?? 'mark_${s.id}_${test.id}',
              testId: test.id,
              studentId: s.id,
              marksObtained: val,
              remarks: _remarksControllers[s.id]?.text.trim() ?? '',
            ),
          );
        }
      }
    }

    await provider.batchSaveMarks(marksToSave);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved scores for ${marksToSave.length} students!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final test = provider.getTestById(widget.testId);

    if (test == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Test Details')),
        body: const Center(child: Text('Test not found')),
      );
    }

    final batch = provider.getBatchById(test.batchId);
    final students = provider.getStudentsByBatch(test.batchId);
    _initControllers(students, provider);

    final recordedMarks = provider.getMarksForTest(test.id);

    // Compute stats
    double avgScore = 0.0;
    double highestScore = 0.0;
    int passCount = 0;
    if (recordedMarks.isNotEmpty) {
      double sum = 0.0;
      for (final m in recordedMarks) {
        sum += m.marksObtained;
        if (m.marksObtained > highestScore) highestScore = m.marksObtained;
        if (m.marksObtained >= test.passingMarks) passCount++;
      }
      avgScore = sum / recordedMarks.length;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(test.testTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Test',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateTestScreen(existingTest: test),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Delete Test',
            onPressed: () => _confirmDelete(context, test),
          ),
        ],
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
          onPressed: students.isEmpty ? null : () => _saveAllMarks(students, test),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Save All Student Scores'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Test Details Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
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
                        DateFormat('dd MMM yyyy').format(test.testDate),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    test.testTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (test.chapter.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Chapter: ${test.chapter}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem('Total Marks', '${test.totalMarks}M', AppColors.primary),
                      _statItem('Passing Marks', '${test.passingMarks}M', AppColors.secondary),
                      _statItem('Graded', '${recordedMarks.length}/${students.length}', AppColors.textPrimary),
                    ],
                  ),
                ],
              ),
            ),

            // Performance Analytics Strip
            if (recordedMarks.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _subStat('Class Average', '${avgScore.toStringAsFixed(1)} / ${test.totalMarks}'),
                    _subStat('Highest Score', '${highestScore.toStringAsFixed(1)} / ${test.totalMarks}'),
                    _subStat('Pass Rate', '${((passCount / recordedMarks.length) * 100).toStringAsFixed(0)}%'),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Scorecard Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Student Scorecard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${students.length} Enrolled',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Students Scoring List
            students.isEmpty
                ? const EmptyStateWidget(
                    title: 'No Students Enrolled in this Batch',
                    description: 'Enroll students in this batch before assigning test scores.',
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: students.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final marksCtrl = _marksControllers[student.id];
                      final remarksCtrl = _remarksControllers[student.id];

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.primaryLight,
                                    child: Text(
                                      student.fullName.isNotEmpty ? student.fullName[0] : 'S',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student.fullName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (student.school.isNotEmpty)
                                          Text(
                                            student.school,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Score Input Box
                                  SizedBox(
                                    width: 90,
                                    child: TextFormField(
                                      controller: marksCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        hintText: '0 - ${test.totalMarks}',
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        suffixText: 'M',
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: remarksCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'Feedback / Remarks (optional)',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _subStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  void _confirmDelete(BuildContext context, TestModel test) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Test?'),
        content: Text('Are you sure you want to delete "${test.testTitle}" and all recorded scores?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Provider.of<AppProvider>(context, listen: false).deleteTest(test.id);
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
