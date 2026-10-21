import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/test_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';

class CreateTestScreen extends StatefulWidget {
  final TestModel? existingTest;
  final String? defaultBatchId;

  const CreateTestScreen({
    super.key,
    this.existingTest,
    this.defaultBatchId,
  });

  @override
  State<CreateTestScreen> createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends State<CreateTestScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subjectController;
  late TextEditingController _chapterController;
  late TextEditingController _totalMarksController;
  late TextEditingController _passingMarksController;
  String? _selectedBatchId;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTest;
    _titleController = TextEditingController(text: t?.testTitle ?? '');
    _subjectController = TextEditingController(text: t?.subject ?? 'Mathematics');
    _chapterController = TextEditingController(text: t?.chapter ?? '');
    _totalMarksController = TextEditingController(text: t?.totalMarks.toString() ?? '50');
    _passingMarksController = TextEditingController(text: t?.passingMarks.toString() ?? '20');
    _selectedBatchId = t?.batchId ?? widget.defaultBatchId;
    _selectedDate = t?.testDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _chapterController.dispose();
    _totalMarksController.dispose();
    _passingMarksController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  bool _isSaving = false;

  void _saveTest() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBatchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a batch')),
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);
    final title = _titleController.text.trim();

    // Check duplicate test (same batch, same title, same date)
    final isDuplicate = provider.tests.any((t) =>
        t.id != widget.existingTest?.id &&
        t.batchId == _selectedBatchId &&
        t.testTitle.trim().toLowerCase() == title.toLowerCase() &&
        t.testDate.year == _selectedDate.year &&
        t.testDate.month == _selectedDate.month &&
        t.testDate.day == _selectedDate.day);

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.warning,
          content: Text('A test titled "$title" is already scheduled for this batch on this date.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final totalMarks = int.tryParse(_totalMarksController.text.trim()) ?? 50;
    final passingMarks = int.tryParse(_passingMarksController.text.trim()) ?? 20;

    try {
      if (widget.existingTest == null) {
        final newTest = TestModel(
          id: 'test_${DateTime.now().millisecondsSinceEpoch}',
          testTitle: title,
          subject: _subjectController.text.trim(),
          chapter: _chapterController.text.trim(),
          batchId: _selectedBatchId!,
          totalMarks: totalMarks,
          passingMarks: passingMarks,
          testDate: _selectedDate,
        );
        await provider.addTest(newTest);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test scheduled successfully!')),
          );
          Navigator.pop(context);
        }
      } else {
        final updated = widget.existingTest!.copyWith(
          testTitle: title,
          subject: _subjectController.text.trim(),
          chapter: _chapterController.text.trim(),
          batchId: _selectedBatchId!,
          totalMarks: totalMarks,
          passingMarks: passingMarks,
          testDate: _selectedDate,
        );
        await provider.updateTest(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test updated successfully!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to save test: $e'),
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
    final batches = provider.batches;
    final isEditing = widget.existingTest != null;

    if (_selectedBatchId == null && batches.isNotEmpty) {
      _selectedBatchId = batches.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Test' : 'Schedule Academic Test'),
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
                        'Test Specifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Test Title *',
                          hintText: 'e.g. Unit Test: Quadratic Equations',
                          prefixIcon: Icon(Icons.assignment_outlined),
                        ),
                        validator: (val) =>
                            (val == null || val.trim().isEmpty) ? 'Please enter test title' : null,
                      ),
                      const SizedBox(height: 16),
                      // Batch Selector
                      DropdownButtonFormField<String>(
                        value: _selectedBatchId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Target Batch *',
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
                        onChanged: (val) => setState(() => _selectedBatchId = val),
                        validator: (val) => val == null ? 'Please select a batch' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _chapterController,
                        decoration: const InputDecoration(
                          labelText: 'Chapter / Unit / Topic',
                          hintText: 'e.g. Quadratics & Trigonometry',
                          prefixIcon: Icon(Icons.bookmark_border),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Date Picker Field
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Scheduled Test Date *',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(
                            DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _totalMarksController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Total Marks *',
                                hintText: 'e.g. 50',
                                prefixIcon: Icon(Icons.stars_outlined),
                              ),
                              validator: (val) =>
                                  (val == null || val.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _passingMarksController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Passing Marks *',
                                hintText: 'e.g. 20',
                                prefixIcon: Icon(Icons.check_circle_outline),
                              ),
                              validator: (val) =>
                                  (val == null || val.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveTest,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _isSaving
                      ? 'Saving Test...'
                      : (isEditing ? 'Update Test Details' : 'Save & Schedule Test'),
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
