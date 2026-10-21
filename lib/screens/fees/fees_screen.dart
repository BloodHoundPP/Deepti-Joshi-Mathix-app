import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/fee_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_badge.dart';
import 'create_fee_screen.dart';
import 'payment_details_dialog.dart';
import '../../widgets/empty_state.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  String _searchQuery = '';
  FeeStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final allFees = provider.fees;

    final filteredFees = allFees.where((f) {
      if (_statusFilter != null && f.status != _statusFilter) {
        return false;
      }
      final student = provider.getStudentById(f.studentId);
      final q = _searchQuery.toLowerCase();
      final name = student?.fullName.toLowerCase() ?? '';
      final title = f.title.toLowerCase();
      final ref = f.transactionRef.toLowerCase();
      final rcp = f.receiptNo.toLowerCase();

      return name.contains(q) || title.contains(q) || ref.contains(q) || rcp.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Collection & Billing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add Fee Invoice',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateFeeScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton.extended(
          heroTag: 'fab_fees',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateFeeScreen()),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('New Invoice'),
        ),
      ),
      body: Column(
        children: [
          // Financial Metric Banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metricCard('Collected', '₹${provider.collectedFeesTotal.toStringAsFixed(0)}', Colors.white),
                Container(width: 1, height: 40, color: Colors.white24),
                _metricCard('Pending Dues', '₹${provider.pendingFeesTotal.toStringAsFixed(0)}', const Color(0xFFFDE68A)),
                Container(width: 1, height: 40, color: Colors.white24),
                _metricCard('Invoiced', '₹${(provider.collectedFeesTotal + provider.pendingFeesTotal).toStringAsFixed(0)}', Colors.white70),
              ],
            ),
          ),

          // Search & Status Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by student name, title, receipt #...',
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
                        selected: _statusFilter == null,
                        label: Text('All Records (${allFees.length})'),
                        onSelected: (_) => setState(() => _statusFilter = null),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _statusFilter == FeeStatus.pending,
                        label: Text('Pending (${allFees.where((f) => f.status == FeeStatus.pending).length})'),
                        onSelected: (selected) {
                          setState(() => _statusFilter = selected ? FeeStatus.pending : null);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _statusFilter == FeeStatus.partial,
                        label: Text('Partial (${allFees.where((f) => f.status == FeeStatus.partial).length})'),
                        onSelected: (selected) {
                          setState(() => _statusFilter = selected ? FeeStatus.partial : null);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _statusFilter == FeeStatus.paid,
                        label: Text('Paid (${allFees.where((f) => f.status == FeeStatus.paid).length})'),
                        onSelected: (selected) {
                          setState(() => _statusFilter = selected ? FeeStatus.paid : null);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Fees List
          Expanded(
            child: filteredFees.isEmpty
                ? EmptyStateWidget(
                    title: allFees.isEmpty ? 'No Fee Records Created' : 'No Matching Fee Records',
                    description: allFees.isEmpty
                        ? 'Issue fee schedules and collect tuition payments cleanly.'
                        : 'No records matching the selected status or query.',
                    buttonText: allFees.isEmpty ? 'Create First Invoice' : null,
                    onButtonPressed: allFees.isEmpty
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CreateFeeScreen()),
                            );
                          }
                        : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: filteredFees.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final fee = filteredFees[index];
                      final student = provider.getStudentById(fee.studentId);
                      final batch = student != null ? provider.getBatchById(student.batchId) : null;

                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  student?.fullName ?? 'Student',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                              ),
                              FeeStatusBadge(status: fee.status),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '${fee.installment} • ${fee.title} • ${batch?.batchName ?? ''}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Paid: ₹${fee.paidAmount.toStringAsFixed(0)} of ₹${fee.totalAmount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Due: ${DateFormat('dd MMM').format(fee.dueDate)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: fee.dueDate.isBefore(DateTime.now()) && fee.status != FeeStatus.paid
                                          ? AppColors.error
                                          : AppColors.textMuted,
                                      fontWeight: fee.dueDate.isBefore(DateTime.now()) && fee.status != FeeStatus.paid
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.receipt_outlined, color: AppColors.primary),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => PaymentDetailsDialog(fee: fee),
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

  Widget _metricCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }
}
