import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/batch_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';

class CreateBatchScreen extends StatefulWidget {
  final BatchModel? existingBatch;

  const CreateBatchScreen({super.key, this.existingBatch});

  @override
  State<CreateBatchScreen> createState() => _CreateBatchScreenState();
}

class _CreateBatchScreenState extends State<CreateBatchScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _scheduleController;
  late TextEditingController _standardController;
  late TextEditingController _capacityController;

  @override
  void initState() {
    super.initState();
    final b = widget.existingBatch;
    _nameController = TextEditingController(text: b?.batchName ?? '');
    _scheduleController = TextEditingController(
      text: b?.schedule ?? 'Mon, Wed, Fri • 4:00 PM - 5:30 PM',
    );
    _standardController = TextEditingController(text: b?.standard ?? '10th ICSE');
    _capacityController = TextEditingController(
      text: b?.capacity.toString() ?? '25',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scheduleController.dispose();
    _standardController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  bool _isSaving = false;

  void _saveBatch() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    final batchName = _nameController.text.trim();

    // Check duplicate batch name
    final isDuplicate = provider.batches.any((b) =>
        b.id != widget.existingBatch?.id &&
        b.batchName.trim().toLowerCase() == batchName.toLowerCase());

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.warning,
          content: Text('A batch named "$batchName" already exists.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final capacity = int.tryParse(_capacityController.text.trim()) ?? 25;

    try {
      if (widget.existingBatch == null) {
        final newBatch = BatchModel(
          id: 'batch_${DateTime.now().millisecondsSinceEpoch}',
          batchName: batchName,
          schedule: _scheduleController.text.trim(),
          instructor: 'Prof. Deepti Joshi',
          subject: 'Mathematics',
          standard: _standardController.text.trim(),
          capacity: capacity,
        );
        await provider.addBatch(newBatch);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Batch created successfully!')),
          );
          Navigator.pop(context);
        }
      } else {
        final updated = widget.existingBatch!.copyWith(
          batchName: batchName,
          schedule: _scheduleController.text.trim(),
          instructor: 'Prof. Deepti Joshi',
          subject: 'Mathematics',
          standard: _standardController.text.trim(),
          capacity: capacity,
        );
        await provider.updateBatch(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Batch updated successfully!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to save batch: $e'),
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
    final isEditing = widget.existingBatch != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Batch' : 'Create New Batch'),
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
                        'Batch Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Batch Name *',
                          hintText: 'e.g. 10th ICSE Mathematics - Elite',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        validator: (val) =>
                            (val == null || val.trim().isEmpty)
                                ? 'Please enter batch name'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _standardController,
                        decoration: const InputDecoration(
                          labelText: 'Standard / Class *',
                          hintText: 'e.g. 10th ICSE',
                          prefixIcon: Icon(Icons.grade_outlined),
                        ),
                        validator: (val) =>
                            (val == null || val.trim().isEmpty)
                                ? 'Required'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _scheduleController,
                        decoration: const InputDecoration(
                          labelText: 'Timing / Schedule *',
                          hintText: 'e.g. Mon, Wed, Fri • 4:00 PM - 5:30 PM',
                          prefixIcon: Icon(Icons.access_time_rounded),
                        ),
                        validator: (val) =>
                            (val == null || val.trim().isEmpty)
                                ? 'Please enter schedule details'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _capacityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Student Intake Capacity',
                          hintText: 'e.g. 25',
                          prefixIcon: Icon(Icons.groups_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return null;
                          if (int.tryParse(val.trim()) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveBatch,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _isSaving
                      ? 'Saving Batch...'
                      : (isEditing ? 'Update Batch Details' : 'Create Batch'),
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
