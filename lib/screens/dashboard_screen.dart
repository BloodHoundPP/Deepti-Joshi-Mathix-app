import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/summary_card.dart';
import 'batches/batches_screen.dart';
import 'batches/batch_details_screen.dart';
import 'students/students_screen.dart';
import 'students/create_student_screen.dart';
import 'tests/tests_screen.dart';
import 'tests/create_test_screen.dart';
import 'tests/test_details_screen.dart';
import 'attendance/attendance_screen.dart';
import 'attendance/create_attendance_screen.dart';
import 'fees/fees_screen.dart';
import 'fees/create_fee_screen.dart';
import 'fees/payment_details_dialog.dart';
import 'reports/reports_screen.dart';
import 'reports/student_report_screen.dart';
import '../services/auth_service.dart';
import '../services/update_service.dart';
import 'auth/auth_gate.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final upcomingTests = provider.tests.take(3).toList();
    final recentAttendance = provider.attendance.take(3).toList();
    final pendingFees = provider.fees
        .where((f) => f.pendingAmount > 0)
        .take(3)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deepti Joshi Academy',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              'Mathematics Coaching Portal',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'View Analytics & Reports',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'Settings & Data',
            onSelected: (val) {
              if (val == 'reports') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportsScreen()),
                );
              } else if (val == 'supabase_sync') {
                _showSupabaseSyncDialog(context, provider);
              } else if (val == 'check_updates') {
                UpdateService.instance.checkForUpdates(context, showNotificationIfLatest: true);
              } else if (val == 'sign_out') {
                _confirmSignOut(context);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'reports',
                child: Row(
                  children: [
                    Icon(Icons.insights, size: 18),
                    SizedBox(width: 8),
                    Text('Reports & Analytics'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'supabase_sync',
                child: Row(
                  children: [
                    Icon(
                      provider.isSupabaseConnected
                          ? Icons.cloud_done_rounded
                          : Icons.cloud_outlined,
                      size: 18,
                      color: provider.isSupabaseConnected
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      provider.isSupabaseConnected
                          ? 'Supabase Cloud (Connected)'
                          : 'Supabase Cloud (Offline)',
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'check_updates',
                child: Row(
                  children: [
                    Icon(Icons.system_update_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Check for Updates'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'sign_out',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text(
                      'Sign Out / Lock Portal',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.init(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Executive Dashboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Welcome back, Prof. Deepti',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'EEEE, dd MMMM yyyy',
                            ).format(DateTime.now()),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calculate_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // KPI Summary Cards Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardBatches = SummaryCard(
                    title: 'Active Batches',
                    value: '${provider.activeBatchesCount}',
                    icon: Icons.groups_rounded,
                    accentColor: AppColors.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BatchesScreen(),
                        ),
                      );
                    },
                  );
                  final cardStudents = SummaryCard(
                    title: 'Total Students',
                    value: '${provider.totalStudentsCount}',
                    icon: Icons.person_rounded,
                    accentColor: AppColors.secondary,
                    onTap: () {
                      if (onNavigateTab != null) {
                        onNavigateTab!(1);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudentsScreen(),
                          ),
                        );
                      }
                    },
                  );
                  final cardFees = SummaryCard(
                    title: 'Pending Fees',
                    value:
                        '₹${provider.pendingFeesTotal.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: AppColors.error,
                    onTap: () {
                      if (onNavigateTab != null) {
                        onNavigateTab!(4);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FeesScreen(),
                          ),
                        );
                      }
                    },
                  );
                  final cardAttendance = SummaryCard(
                    title: 'Attendance',
                    value:
                        '${provider.overallAttendanceRate.toStringAsFixed(0)}%',
                    icon: Icons.how_to_reg_rounded,
                    accentColor: AppColors.success,
                    onTap: () {
                      if (onNavigateTab != null) {
                        onNavigateTab!(3);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AttendanceScreen(),
                          ),
                        );
                      }
                    },
                  );

                  if (constraints.maxWidth > 600) {
                    return Row(
                      children: [
                        Expanded(child: cardBatches),
                        const SizedBox(width: 12),
                        Expanded(child: cardStudents),
                        const SizedBox(width: 12),
                        Expanded(child: cardFees),
                        const SizedBox(width: 12),
                        Expanded(child: cardAttendance),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: cardBatches),
                          const SizedBox(width: 12),
                          Expanded(child: cardStudents),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: cardFees),
                          const SizedBox(width: 12),
                          Expanded(child: cardAttendance),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Quick Actions Bar
              const Text(
                'Quick Administrative Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _actionChip(
                      context,
                      label: 'Mark Att.',
                      icon: Icons.how_to_reg_rounded,
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateAttendanceScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _actionChip(
                      context,
                      label: 'New Student',
                      icon: Icons.person_add_rounded,
                      color: AppColors.secondary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateStudentScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _actionChip(
                      context,
                      label: 'New Test',
                      icon: Icons.assignment_add,
                      color: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateTestScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _actionChip(
                      context,
                      label: 'Collect Fee',
                      icon: Icons.payments_rounded,
                      color: AppColors.success,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateFeeScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _actionChip(
                      context,
                      label: 'PDF Report',
                      icon: Icons.picture_as_pdf_rounded,
                      color: const Color(0xFFE11D48),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudentReportScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Student Academic Report PDF Generator Feature Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Color(0xFFFBBF24),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Student Academic Progress Report',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Generate monthly, 2-month or yearly progress card & download PDF',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudentReportScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Generate PDF', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Active Cohorts Horizontal Carousel
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Batches',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BatchesScreen(),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (provider.batches.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.school_outlined, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No batches created yet',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Add your first coaching batch to get started.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BatchesScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text('Add Batch', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: provider.batches.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final batch = provider.batches[index];
                      final count = provider.getStudentsByBatch(batch.id).length;

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BatchDetailsScreen(batchId: batch.id),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 220,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  batch.standard,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                batch.batchName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$count Students',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),

              // Upcoming Tests Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Academic Tests',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () {
                      if (onNavigateTab != null) {
                        onNavigateTab!(2);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TestsScreen(),
                          ),
                        );
                      }
                    },
                    child: const Text('All Tests'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (upcomingTests.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('No upcoming tests scheduled')),
                  ),
                )
              else
                ...upcomingTests.map((t) {
                  final b = provider.getBatchById(t.batchId);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.assignment_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        t.testTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${b?.batchName ?? ''} • ${DateFormat('dd MMM').format(t.testDate)}',
                      ),
                      trailing: Text(
                        '${t.totalMarks}M',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TestDetailsScreen(testId: t.id),
                          ),
                        );
                      },
                    ),
                  );
                }),
              // Recent Attendance Activity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Attendance Sessions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () {
                      if (onNavigateTab != null) {
                        onNavigateTab!(3);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AttendanceScreen(),
                          ),
                        );
                      }
                    },
                    child: const Text('All Sessions'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (recentAttendance.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text('No attendance recorded recently'),
                    ),
                  ),
                )
              else
                ...recentAttendance.map((att) {
                  final b = provider.getBatchById(att.batchId);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.event_available_rounded,
                          color: AppColors.success,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        DateFormat(
                          'EEE, dd MMM yyyy',
                        ).format(att.attendanceDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${b?.batchName ?? ''} • ${att.presentCount}/${att.totalCount} Present',
                      ),
                      trailing: Text(
                        '${att.percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: att.percentage >= 75
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 16),

              // Pending Dues Alert Card
              if (pendingFees.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pending Tuition Invoices',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (onNavigateTab != null) {
                          onNavigateTab!(4);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FeesScreen(),
                            ),
                          );
                        }
                      },
                      child: const Text('Manage Fees'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...pendingFees.map((fee) {
                  final student = provider.getStudentById(fee.studentId);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(
                        student?.fullName ?? 'Student',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(fee.title),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${fee.pendingAmount.toStringAsFixed(0)} due',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.error,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Due: ${DateFormat('dd MMM').format(fee.dueDate)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
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
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 82,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSupabaseSyncDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              provider.isSupabaseConnected ? Icons.cloud_done : Icons.cloud_off,
              color: provider.isSupabaseConnected
                  ? AppColors.success
                  : AppColors.warning,
            ),
            const SizedBox(width: 8),
            Text(provider.isSupabaseConnected
                ? 'Supabase Connected'
                : 'Supabase Setup'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.isSupabaseConnected) ...[
              const Text(
                'Your app is connected to your cloud Supabase database.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                'All new batches, students, tests, marks, attendance sessions, and fee installments are automatically synchronized.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              const Text(
                'Click "Upload All to Cloud" if you want to push any offline records to your Supabase tables.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ] else ...[
              const Text(
                'Supabase is not configured yet.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'To connect your cloud database:\n\n1. Open your project .env file:\n   d:\\Deepti Joshi Tutor App\\.env\n\n2. Set your Project URL and Anon Key:\n   SUPABASE_URL=https://xyz.supabase.co\n   SUPABASE_ANON_KEY=eyJhbGci...\n\n3. Restart the app. It will automatically connect and sync!',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
          if (provider.isSupabaseConnected)
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload_rounded, size: 18),
              label: const Text('Upload All to Cloud'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(dialogCtx);
                await provider.syncAllToSupabase();
                messenger.showSnackBar(
                  const SnackBar(
                      content: Text('All records uploaded to Supabase!')),
                );
              },
            ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out of the faculty coaching portal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await AuthService.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
