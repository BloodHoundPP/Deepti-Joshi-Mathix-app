import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/fee_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';

class CreateFeeScreen extends StatefulWidget {
  final String? defaultStudentId;
  final FeeRecordModel? existingFee;

  const CreateFeeScreen({
    super.key,
    this.defaultStudentId,
    this.existingFee,
  });

  @override
  State<CreateFeeScreen> createState() => _CreateFeeScreenState();
}

class _CreateFeeScreenState extends State<CreateFeeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _totalAmountController;
  late TextEditingController _paidAmountController;
  late TextEditingController _transactionRefController;
  String? _selectedStudentId;
  late DateTime _selectedDueDate;
  String _selectedPaymentMode = 'UPI / GPay';
  String _selectedInstallment = '1st Installment';

  final List<String> _installmentOptions = [
    '1st Installment',
    '2nd Installment',
    '3rd Installment',
    '4th Installment',
    'Full Payment',
  ];

  final List<String> _paymentModes = [
    'UPI / GPay',
    'Cash',
    'Net Banking / NEFT',
    'Cheque',
  ];

  @override
  void initState() {
    super.initState();
    final f = widget.existingFee;
    _selectedInstallment = f?.installment ?? '1st Installment';
    _titleController = TextEditingController(
      text: f?.title ?? '$_selectedInstallment Tuition Fee',
    );
    _totalAmountController = TextEditingController(
      text: f != null ? f.totalAmount.toStringAsFixed(0) : '15000',
    );
    _paidAmountController = TextEditingController(
      text: f != null ? f.paidAmount.toStringAsFixed(0) : '0',
    );
    _transactionRefController = TextEditingController(text: f?.transactionRef ?? '');
    _selectedStudentId = f?.studentId ?? widget.defaultStudentId;
    _selectedDueDate = f?.dueDate ?? DateTime.now().add(const Duration(days: 15));
    _selectedPaymentMode = f?.paymentMode ?? 'UPI / GPay';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _totalAmountController.dispose();
    _paidAmountController.dispose();
    _transactionRefController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  bool _isSaving = false;

  void _saveFee() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student')),
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);

    // If creating a new fee, check duplicate fee invoice for this student with this installment
    if (widget.existingFee == null) {
      final isDuplicate = provider.fees.any((f) =>
          f.studentId == _selectedStudentId &&
          f.installment == _selectedInstallment);

      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.warning,
            content: Text(
              'A fee invoice for "$_selectedInstallment" already exists for this student.',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    final total = double.tryParse(_totalAmountController.text.trim()) ?? 0.0;
    final paid = double.tryParse(_paidAmountController.text.trim()) ?? 0.0;

    FeeStatus status = FeeStatus.pending;
    if (paid >= total && total > 0) {
      status = FeeStatus.paid;
    } else if (paid > 0) {
      status = FeeStatus.partial;
    }

    try {
      if (widget.existingFee == null) {
        final receiptNum = 'RCP-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
        final newFee = FeeRecordModel(
          id: 'fee_${DateTime.now().millisecondsSinceEpoch}',
          studentId: _selectedStudentId!,
          title: _titleController.text.trim(),
          installment: _selectedInstallment,
          totalAmount: total,
          paidAmount: paid,
          status: status,
          dueDate: _selectedDueDate,
          paidDate: paid > 0 ? DateTime.now() : null,
          paymentMode: _selectedPaymentMode,
          transactionRef: _transactionRefController.text.trim(),
          receiptNo: paid > 0 ? receiptNum : '',
        );
        await provider.addFee(newFee);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fee record created successfully!')),
          );
          Navigator.pop(context);
        }
      } else {
        final updated = widget.existingFee!.copyWith(
          studentId: _selectedStudentId!,
          title: _titleController.text.trim(),
          installment: _selectedInstallment,
          totalAmount: total,
          paidAmount: paid,
          status: status,
          dueDate: _selectedDueDate,
          paidDate: paid > 0 ? (widget.existingFee!.paidDate ?? DateTime.now()) : null,
          paymentMode: _selectedPaymentMode,
          transactionRef: _transactionRefController.text.trim(),
        );
        await provider.updateFee(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fee record updated successfully!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to save fee record: $e'),
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
    final students = provider.students;
    final isEditing = widget.existingFee != null;

    if (_selectedStudentId == null && students.isNotEmpty) {
      _selectedStudentId = students.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Fee Details' : 'Create Fee Invoice'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fee Particulars',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Student Selector
                      DropdownButtonFormField<String>(
                        value: _selectedStudentId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Student *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: students.map((s) {
                          final batch = provider.getBatchById(s.batchId);
                          return DropdownMenuItem(
                            value: s.id,
                            child: Text(
                              '${s.fullName} (${batch?.standard ?? 'Batch'})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedStudentId = val),
                        validator: (val) => val == null ? 'Please select a student' : null,
                      ),
                      const SizedBox(height: 16),
                      // Installment Selector
                      DropdownButtonFormField<String>(
                        value: _selectedInstallment,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Installment Term *',
                          prefixIcon: Icon(Icons.layers_outlined),
                        ),
                        items: _installmentOptions.map((opt) {
                          return DropdownMenuItem(
                            value: opt,
                            child: Text(opt),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedInstallment = val;
                              if (_titleController.text.contains('Installment') ||
                                  _titleController.text.isEmpty ||
                                  _titleController.text == 'Term Tuition Fee') {
                                _titleController.text = '$val Tuition Fee';
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Fee Title / Description *',
                          hintText: 'e.g. 1st Installment Tuition Fee',
                          prefixIcon: Icon(Icons.receipt_long_outlined),
                        ),
                        validator: (val) =>
                            (val == null || val.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _totalAmountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Total Fee (₹) *',
                                prefixIcon: Icon(Icons.currency_rupee_rounded),
                              ),
                              validator: (val) =>
                                  (val == null || val.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _paidAmountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Paid Amount (₹)',
                                prefixIcon: Icon(Icons.payments_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _pickDueDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Payment Due Date',
                            prefixIcon: Icon(Icons.event_outlined),
                          ),
                          child: Text(
                            DateFormat('dd MMMM yyyy').format(_selectedDueDate),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedPaymentMode,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Payment Method',
                          prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                        ),
                        items: _paymentModes.map((m) {
                          return DropdownMenuItem(value: m, child: Text(m));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPaymentMode = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _transactionRefController,
                        decoration: const InputDecoration(
                          labelText: 'Transaction Ref / Receipt Note',
                          hintText: 'e.g. UPI-9820-AARAV or Cheque #1234',
                          prefixIcon: Icon(Icons.tag_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveFee,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _isSaving
                      ? 'Generating Invoice...'
                      : (isEditing ? 'Update Fee Record' : 'Generate Fee Invoice'),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
