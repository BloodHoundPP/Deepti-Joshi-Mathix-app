import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';
import 'create_test_screen.dart';
import 'test_details_screen.dart';
import '../../widgets/empty_state.dart';

class TestsScreen extends StatefulWidget {
  const TestsScreen({super.key});

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  String _searchQuery = '';
  String? _selectedBatchFilter;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final allTests = provider.tests;
    final batches = provider.batches;

    final filteredTests = allTests.where((t) {
      if (_selectedBatchFilter != null && t.batchId != _selectedBatchFilter) {
        return false;
      }
      final q = _searchQuery.toLowerCase();
      return t.testTitle.toLowerCase().contains(q) ||
          t.subject.toLowerCase().contains(q) ||
          t.chapter.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Tests & Exams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            tooltip: 'Schedule Test',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateTestScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton.extended(
          heroTag: 'fab_tests',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateTestScreen()),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Schedule Test'),
        ),
      ),
      body: Column(
        children: [
          // Filter Controls
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search test title, chapter, or subject...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        selected: _selectedBatchFilter == null,
                        label: Text('All Tests (${allTests.length})'),
                        onSelected: (selected) {
                          setState(() => _selectedBatchFilter = null);
                        },
                      ),
                      const SizedBox(width: 8),
                      ...batches.map((b) {
                        final count = provider.getTestsByBatch(b.id).length;
                        final isSelected = _selectedBatchFilter == b.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text('${b.batchName} ($count)'),
                            onSelected: (selected) {
                              setState(() {
                                _selectedBatchFilter = selected ? b.id : null;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tests List
          Expanded(
            child: filteredTests.isEmpty
                ? EmptyStateWidget(
                    title: allTests.isEmpty ? 'No Tests Scheduled' : 'No Tests Found',
                    description: allTests.isEmpty
                        ? 'Schedule tests to track students\' chapter-wise performance and evaluate scores.'
                        : 'No test matches your search or batch criteria.',
                    buttonText: allTests.isEmpty ? 'Schedule First Test' : null,
                    onButtonPressed: allTests.isEmpty
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CreateTestScreen()),
                            );
                          }
                        : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: filteredTests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final test = filteredTests[index];
                      final batch = provider.getBatchById(test.batchId);
                      final enrolled = provider.getStudentsByBatch(test.batchId);
                      final graded = provider.getMarksForTest(test.id);

                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  test.testTitle,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${test.totalMarks} Marks',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                batch?.batchName ?? 'Batch',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.event_outlined, size: 14, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(test.testDate),
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Graded: ${graded.length}/${enrolled.length}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: graded.length == enrolled.length && enrolled.isNotEmpty
                                          ? AppColors.success
                                          : AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
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
          ),
        ],
      ),
    );
  }
}
