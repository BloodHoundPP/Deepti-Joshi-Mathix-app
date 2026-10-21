import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/fee_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_badge.dart';

class PaymentDetailsDialog extends StatefulWidget {
  final FeeRecordModel fee;

  const PaymentDetailsDialog({super.key, required this.fee});

  @override
  State<PaymentDetailsDialog> createState() => _PaymentDetailsDialogState();
}

class _PaymentDetailsDialogState extends State<PaymentDetailsDialog> {
  final _amountController = TextEditingController();
  final _refController = TextEditingController();
  String _paymentMode = 'UPI / GPay';
  bool _isCollecting = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.fee.pendingAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    super.dispose();
  }

  void _submitPayment() async {
    final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid payment amount')),
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.recordPayment(
      feeId: widget.fee.id,
      paymentAmount: amt,
      paymentMode: _paymentMode,
      transactionRef: _refController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final fee = provider.fees.firstWhere((f) => f.id == widget.fee.id, orElse: () => widget.fee);
    final student = provider.getStudentById(fee.studentId);
    final batch = student != null ? provider.getBatchById(student.batchId) : null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Fee Receipt & Ledger',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                fee.receiptNo.isNotEmpty ? fee.receiptNo : 'Pending Invoice',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FeeStatusBadge(status: fee.status),
                ],
              ),
              const Divider(height: 28),

              // Student & Fee Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _rowItem('Student Name', student?.fullName ?? 'N/A'),
                    const SizedBox(height: 8),
                    _rowItem('Batch / Standard', '${batch?.batchName ?? 'Batch'} (${batch?.standard ?? ''})'),
                    const SizedBox(height: 8),
                    _rowItem('Fee Particulars', fee.title),
                    const SizedBox(height: 8),
                    _rowItem('Installment Term', fee.installment),
                    const SizedBox(height: 8),
                    _rowItem('Due Date', DateFormat('dd MMM yyyy').format(fee.dueDate)),
                    if (fee.paidDate != null) ...[
                      const SizedBox(height: 8),
                      _rowItem('Last Payment Date', DateFormat('dd MMM yyyy').format(fee.paidDate!)),
                    ],
                    if (fee.transactionRef.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _rowItem('Txn Reference', fee.transactionRef),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Financial Figures
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metricTile('Total Fee', '₹${fee.totalAmount.toStringAsFixed(0)}', AppColors.textPrimary),
                  _metricTile('Paid Amount', '₹${fee.paidAmount.toStringAsFixed(0)}', AppColors.success),
                  _metricTile('Pending Due', '₹${fee.pendingAmount.toStringAsFixed(0)}', fee.pendingAmount > 0 ? AppColors.error : AppColors.success),
                ],
              ),
              const Divider(height: 28),

              // Collect Payment Form / Action
              if (fee.pendingAmount > 0 && !_isCollecting)
                ElevatedButton.icon(
                  onPressed: () => setState(() => _isCollecting = true),
                  icon: const Icon(Icons.add_card_rounded),
                  label: const Text('Record Payment / Installment'),
                )
              else if (_isCollecting) ...[
                const Text(
                  'Record Installment',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    prefixIcon: Icon(Icons.currency_rupee_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _paymentMode,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Payment Mode',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  items: ['UPI / GPay', 'Cash', 'Net Banking / NEFT', 'Cheque']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _paymentMode = val);
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _refController,
                  decoration: const InputDecoration(
                    labelText: 'Transaction Ref #',
                    hintText: 'e.g. UPI Ref, NEFT ID',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _isCollecting = false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitPayment,
                        child: const Text('Confirm'),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close Receipt'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _metricTile(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}
