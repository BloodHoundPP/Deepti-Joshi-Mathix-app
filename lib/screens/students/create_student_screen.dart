import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/student_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';

class CreateStudentScreen extends StatefulWidget {
  final StudentModel? existingStudent;
  final String? defaultBatchId;

  const CreateStudentScreen({
    super.key,
    this.existingStudent,
    this.defaultBatchId,
  });

  @override
  State<CreateStudentScreen> createState() => _CreateStudentScreenState();
}

class _CreateStudentScreenState extends State<CreateStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _parentPhoneController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;
  late TextEditingController _schoolController;
  String? _selectedBatchId;

  @override
  void initState() {
    super.initState();
    final s = widget.existingStudent;
    _nameController = TextEditingController(text: s?.fullName ?? '');
    _phoneController = TextEditingController(text: s?.phone ?? '');
    _parentPhoneController = TextEditingController(text: s?.parentPhone ?? '');
    _addressController = TextEditingController(text: s?.address ?? '');
    _emailController = TextEditingController(text: s?.email ?? '');
    _schoolController = TextEditingController(text: s?.school ?? '');
    _selectedBatchId = s?.batchId ?? widget.defaultBatchId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _parentPhoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  bool _isSaving = false;

  void _saveStudent() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBatchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a batch for this student')),
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);
    final fullName = _nameController.text.trim();

    // Check duplicate student in the selected batch
    final isDuplicate = provider.students.any((s) =>
        s.id != widget.existingStudent?.id &&
        s.batchId == _selectedBatchId &&
        s.fullName.trim().toLowerCase() == fullName.toLowerCase());

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.warning,
          content: Text('A student named "$fullName" is already enrolled in this batch.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.existingStudent == null) {
        final newStudent = StudentModel(
          id: 'std_${DateTime.now().millisecondsSinceEpoch}',
          fullName: fullName,
          phone: _phoneController.text.trim(),
          parentPhone: _parentPhoneController.text.trim(),
          address: _addressController.text.trim(),
          batchId: _selectedBatchId!,
          email: _emailController.text.trim(),
          rollNo: '',
          school: _schoolController.text.trim(),
          joinDate: DateTime.now(),
        );
        await provider.addStudent(newStudent);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student added successfully!')),
          );
          Navigator.pop(context);
        }
      } else {
        final updated = widget.existingStudent!.copyWith(
          fullName: fullName,
          phone: _phoneController.text.trim(),
          parentPhone: _parentPhoneController.text.trim(),
          address: _addressController.text.trim(),
          batchId: _selectedBatchId!,
          email: _emailController.text.trim(),
          rollNo: '',
          school: _schoolController.text.trim(),
        );
        await provider.updateStudent(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student updated successfully!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to save student: $e'),
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
    final isEditing = widget.existingStudent != null;

    if (_selectedBatchId == null && batches.isNotEmpty) {
      _selectedBatchId = batches.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Student Profile' : 'Enroll New Student'),
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
                        'Student Details',
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
                          labelText: 'Full Name *',
                          hintText: 'e.g. Aarav Sharma',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (val) =>
                            (val == null || val.trim().isEmpty) ? 'Please enter student name' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _schoolController,
                        decoration: const InputDecoration(
                          labelText: 'School / College (Optional)',
                          hintText: 'e.g. St. Mary\'s High School',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Batch Selector
                      DropdownButtonFormField<String>(
                        value: _selectedBatchId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Assigned Batch *',
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
                        onChanged: (val) {
                          setState(() => _selectedBatchId = val);
                        },
                        validator: (val) => val == null ? 'Please select a batch' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contact & Guardian Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Student Phone Number (Optional)',
                          hintText: 'e.g. +91 98201 23456',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _parentPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Parent / Guardian Contact (Optional)',
                          hintText: 'e.g. +91 98201 65432',
                          prefixIcon: Icon(Icons.contact_phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'e.g. aarav.sharma@gmail.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Residential Address',
                          hintText: 'e.g. B-402, Sunshine Heights, Pune',
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveStudent,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _isSaving
                      ? 'Saving Student...'
                      : (isEditing ? 'Update Student Profile' : 'Enroll Student'),
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
