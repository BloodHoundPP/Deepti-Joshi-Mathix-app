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

  void _saveTest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBatchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a batch')),
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);
    final totalMarks = int.tryParse(_totalMarksController.text.trim()) ?? 50;
    final passingMarks = int.tryParse(_passingMarksController.text.trim()) ?? 20;

    if (widget.existingTest == null) {
      final newTest = TestModel(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        testTitle: _titleController.text.trim(),
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
        testTitle: _titleController.text.trim(),
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
                onPressed: _saveTest,
                icon: const Icon(Icons.save_rounded),
                label: Text(isEditing ? 'Update Test Details' : 'Save & Schedule Test'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
