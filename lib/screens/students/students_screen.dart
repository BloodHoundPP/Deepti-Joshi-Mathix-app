import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';
import 'create_student_screen.dart';
import 'student_details_screen.dart';
import '../../widgets/empty_state.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String _searchQuery = '';
  String? _selectedBatchFilter;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final allStudents = provider.students;
    final batches = provider.batches;

    final filteredStudents = allStudents.where((s) {
      if (_selectedBatchFilter != null && s.batchId != _selectedBatchFilter) {
        return false;
      }
      final q = _searchQuery.toLowerCase();
      return s.fullName.toLowerCase().contains(q) ||
          s.phone.toLowerCase().contains(q) ||
          s.parentPhone.toLowerCase().contains(q) ||
          s.school.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Enroll Student',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateStudentScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton.extended(
          heroTag: 'fab_students',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateStudentScreen()),
            );
          },
          icon: const Icon(Icons.person_add_rounded),
          label: const Text('New Student'),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter controls
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone, or roll no...',
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
                // Batch filter horizontal chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        selected: _selectedBatchFilter == null,
                        label: Text('All Batches (${allStudents.length})'),
                        onSelected: (selected) {
                          setState(() => _selectedBatchFilter = null);
                        },
                      ),
                      const SizedBox(width: 8),
                      ...batches.map((b) {
                        final count = provider.getStudentsByBatch(b.id).length;
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

          // Students List
          Expanded(
            child: filteredStudents.isEmpty
                ? EmptyStateWidget(
                    title: allStudents.isEmpty ? 'No Students Enrolled' : 'No Students Found',
                    description: allStudents.isEmpty
                        ? 'Enroll your students to manage their batches, tests, attendance, and fee ledgers.'
                        : 'No student matches your current search or batch filter.',
                    buttonText: allStudents.isEmpty ? 'Enroll First Student' : null,
                    onButtonPressed: allStudents.isEmpty
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CreateStudentScreen()),
                            );
                          }
                        : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: filteredStudents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      final batch = provider.getBatchById(student.batchId);
                      final attRate = provider.getStudentAttendancePercentage(student.id, student.batchId);

                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              student.fullName.isNotEmpty ? student.fullName[0] : 'S',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          title: Text(
                            student.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                batch?.batchName ?? 'Unassigned',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    student.phone.isNotEmpty ? student.phone : 'No phone',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                  const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                                  Text(
                                    'Att: ${attRate.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color: attRate >= 75 ? AppColors.success : AppColors.warning,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
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
                                builder: (_) => StudentDetailsScreen(studentId: student.id),
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
