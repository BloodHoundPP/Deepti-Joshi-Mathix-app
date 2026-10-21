import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';
import 'create_attendance_screen.dart';
import 'attendance_details_screen.dart';
import '../../widgets/empty_state.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _selectedBatchFilter;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final allSessions = provider.attendance;
    final batches = provider.batches;

    final filteredSessions = allSessions.where((s) {
      if (_selectedBatchFilter != null && s.batchId != _selectedBatchFilter) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Take Attendance',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateAttendanceScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_attendance',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateAttendanceScreen()),
          );
        },
        icon: const Icon(Icons.how_to_reg_rounded),
        label: const Text('Take Attendance'),
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    selected: _selectedBatchFilter == null,
                    label: Text('All Batches (${allSessions.length})'),
                    onSelected: (selected) {
                      setState(() => _selectedBatchFilter = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ...batches.map((b) {
                    final count = provider.getAttendanceByBatch(b.id).length;
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
          ),

          // Attendance Sessions List
          Expanded(
            child: filteredSessions.isEmpty
                ? EmptyStateWidget(
                    title: allSessions.isEmpty ? 'No Attendance Recorded Yet' : 'No Sessions for this Batch',
                    description: allSessions.isEmpty
                        ? 'Keep track of daily student presence by recording attendance sessions.'
                        : 'No session records found matching the selected filter.',
                    buttonText: allSessions.isEmpty ? 'Mark First Attendance' : null,
                    onButtonPressed: allSessions.isEmpty
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CreateAttendanceScreen()),
                            );
                          }
                        : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: filteredSessions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final session = filteredSessions[index];
                      final batch = provider.getBatchById(session.batchId);

                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.event_available_rounded, color: AppColors.primary, size: 22),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('EEE, dd MMM yyyy').format(session.attendanceDate),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              Text(
                                '${session.percentage.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: session.percentage >= 75 ? AppColors.success : AppColors.warning,
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
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                session.topicTaught.isNotEmpty
                                    ? 'Topic: ${session.topicTaught}'
                                    : 'Present: ${session.presentCount} • Absent: ${session.absentCount}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AttendanceDetailsScreen(attendanceRecord: session),
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
