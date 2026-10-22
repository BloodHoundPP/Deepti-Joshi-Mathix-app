import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/test_model.dart';
import '../../models/student_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';
import 'create_test_screen.dart';
import '../../widgets/empty_state.dart';

enum TestScoreSortMode {
  alphabetical,
  highestMarks,
  lowestMarks,
  passedOnly,
  failedOnly,
  ungradedOnly,
}

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
  TestScoreSortMode _sortMode = TestScoreSortMode.alphabetical;

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

  double? _getScore(String studentId, TestModel test, AppProvider provider) {
    final text = _marksControllers[studentId]?.text.trim() ?? '';
    if (text.isNotEmpty) {
      return double.tryParse(text);
    }
    final stored = provider.getMarkForStudentAndTest(studentId, test.id);
    return stored?.marksObtained;
  }

  bool _isSaving = false;

  void _saveAllMarks(List<StudentModel> students, TestModel test) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to save scores: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
    int failCount = 0;
    int scoredCount = 0;

    for (final s in students) {
      final sc = _getScore(s.id, test, provider);
      if (sc != null) {
        scoredCount++;
        if (sc > highestScore) highestScore = sc;
        if (sc >= test.passingMarks) {
          passCount++;
        } else {
          failCount++;
        }
      }
    }
    final unscoredCount = students.length - scoredCount;
    if (recordedMarks.isNotEmpty) {
      double sum = 0.0;
      for (final m in recordedMarks) {
        sum += m.marksObtained;
      }
      avgScore = sum / recordedMarks.length;
    }

    final displayedStudents = students.where((s) {
      final score = _getScore(s.id, test, provider);
      if (_sortMode == TestScoreSortMode.passedOnly) {
        return score != null && score >= test.passingMarks;
      }
      if (_sortMode == TestScoreSortMode.failedOnly) {
        return score != null && score < test.passingMarks;
      }
      if (_sortMode == TestScoreSortMode.ungradedOnly) {
        return score == null;
      }
      return true;
    }).toList();

    displayedStudents.sort((a, b) {
      final scoreA = _getScore(a.id, test, provider);
      final scoreB = _getScore(b.id, test, provider);

      if (_sortMode == TestScoreSortMode.highestMarks || _sortMode == TestScoreSortMode.passedOnly) {
        if (scoreA != null && scoreB != null) {
          final comp = scoreB.compareTo(scoreA); // Highest first
          if (comp != 0) return comp;
        } else if (scoreA != null) {
          return -1;
        } else if (scoreB != null) {
          return 1;
        }
      } else if (_sortMode == TestScoreSortMode.lowestMarks || _sortMode == TestScoreSortMode.failedOnly) {
        if (scoreA != null && scoreB != null) {
          final comp = scoreA.compareTo(scoreB); // Lowest first
          if (comp != 0) return comp;
        } else if (scoreA != null) {
          return -1;
        } else if (scoreB != null) {
          return 1;
        }
      }

      // Default / tie-breaker: Alphabetical order (A-Z)
      return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
    });

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
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: (students.isEmpty || _isSaving) ? null : () => _saveAllMarks(students, test),
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(_isSaving ? 'Saving Scores...' : 'Save All Student Scores'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
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
                    'Showing ${displayedStudents.length} of ${students.length}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Horizontal Sort & Filter Chips
            if (students.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        avatar: const Icon(Icons.sort_by_alpha, size: 16),
                        selected: _sortMode == TestScoreSortMode.alphabetical,
                        label: Text('Alphabetical (A-Z) (${students.length})'),
                        onSelected: (selected) {
                          if (selected) setState(() => _sortMode = TestScoreSortMode.alphabetical);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        avatar: const Icon(Icons.trending_up_rounded, size: 16, color: AppColors.primary),
                        selected: _sortMode == TestScoreSortMode.highestMarks,
                        label: const Text('Higher to Lower'),
                        onSelected: (selected) {
                          if (selected) setState(() => _sortMode = TestScoreSortMode.highestMarks);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        avatar: const Icon(Icons.trending_down_rounded, size: 16, color: AppColors.textSecondary),
                        selected: _sortMode == TestScoreSortMode.lowestMarks,
                        label: const Text('Lower to Higher'),
                        onSelected: (selected) {
                          if (selected) setState(() => _sortMode = TestScoreSortMode.lowestMarks);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        avatar: const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                        selected: _sortMode == TestScoreSortMode.passedOnly,
                        label: Text('Passed ($passCount)'),
                        onSelected: (selected) {
                          if (selected) setState(() => _sortMode = TestScoreSortMode.passedOnly);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        avatar: const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                        selected: _sortMode == TestScoreSortMode.failedOnly,
                        label: Text('Below Passing ($failCount)'),
                        onSelected: (selected) {
                          if (selected) setState(() => _sortMode = TestScoreSortMode.failedOnly);
                        },
                      ),
                      if (unscoredCount > 0) ...[
                        const SizedBox(width: 8),
                        FilterChip(
                          avatar: const Icon(Icons.pending_outlined, size: 16, color: AppColors.warning),
                          selected: _sortMode == TestScoreSortMode.ungradedOnly,
                          label: Text('Ungraded ($unscoredCount)'),
                          onSelected: (selected) {
                            if (selected) setState(() => _sortMode = TestScoreSortMode.ungradedOnly);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Students Scoring List
            students.isEmpty
                ? const EmptyStateWidget(
                    title: 'No Students Enrolled in this Batch',
                    description: 'Enroll students in this batch before assigning test scores.',
                  )
                : displayedStudents.isEmpty
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
                                onPressed: () => setState(() => _sortMode = TestScoreSortMode.alphabetical),
                                child: const Text('Show All Students'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                        itemCount: displayedStudents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final student = displayedStudents[index];
                          final marksCtrl = _marksControllers[student.id];
                          final remarksCtrl = _remarksControllers[student.id];
                          final currentScore = _getScore(student.id, test, provider);

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
                                            if (currentScore != null)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Text(
                                                  currentScore >= test.passingMarks ? 'Passed' : 'Below Passing',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: currentScore >= test.passingMarks
                                                        ? AppColors.success
                                                        : AppColors.error,
                                                  ),
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
