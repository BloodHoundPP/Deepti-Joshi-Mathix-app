import 'package:flutter/foundation.dart';
import '../models/batch_model.dart';
import '../models/student_model.dart';
import '../models/test_model.dart';
import '../models/attendance_model.dart';
import '../models/fee_model.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

class AppProvider with ChangeNotifier {
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  bool get isSupabaseConnected => SupabaseService.isReady;

  List<BatchModel> _batches = [];
  List<StudentModel> _students = [];
  List<TestModel> _tests = [];
  List<StudentTestMarkModel> _marks = [];
  List<AttendanceRecordModel> _attendance = [];
  List<FeeRecordModel> _fees = [];

  List<BatchModel> get batches => List.unmodifiable(_batches);
  List<StudentModel> get students =>
      List.unmodifiable(_students..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase())));
  List<TestModel> get tests => List.unmodifiable(_tests);
  List<StudentTestMarkModel> get marks => List.unmodifiable(_marks);
  List<AttendanceRecordModel> get attendance => List.unmodifiable(_attendance);
  List<FeeRecordModel> get fees => List.unmodifiable(_fees);

  AppProvider() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await StorageService.ensureProductionClean();

    _batches = await StorageService.loadBatches();
    _students = await StorageService.loadStudents();
    _students.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    _tests = await StorageService.loadTests();
    _marks = await StorageService.loadTestMarks();
    _attendance = await StorageService.loadAttendance();
    _fees = await StorageService.loadFees();

    _isLoading = false;
    notifyListeners();
  }

  /// Re-seeds and refreshes clean mock data in Demo Mode
  Future<void> reloadDemoData() async {
    _isLoading = true;
    notifyListeners();
    await StorageService.resetDemoData();
    await init();
  }

  Future<void> syncAllToSupabase() async {
    if (!SupabaseService.isReady) return;
    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseService.syncLocalDataToSupabase(
        batches: _batches,
        students: _students,
        tests: _tests,
        marks: _marks,
        attendance: _attendance,
        fees: _fees,
      );
    } catch (e) {
      debugPrint('Sync all to Supabase error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- BATCH MANAGEMENT ---
  BatchModel? getBatchById(String id) {
    try {
      return _batches.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addBatch(BatchModel batch) async {
    _batches.add(batch);
    notifyListeners();
    await StorageService.saveBatches(_batches);
    if (SupabaseService.isReady) {
      try {
        await SupabaseService.upsertBatch(batch);
      } catch (e) {
        debugPrint('Supabase direct addBatch error: $e');
      }
    }
  }

  Future<void> updateBatch(BatchModel batch) async {
    final index = _batches.indexWhere((b) => b.id == batch.id);
    if (index != -1) {
      _batches[index] = batch;
      notifyListeners();
      await StorageService.saveBatches(_batches);
      if (SupabaseService.isReady) {
        try {
          await SupabaseService.upsertBatch(batch);
        } catch (e) {
          debugPrint('Supabase direct updateBatch error: $e');
        }
      }
    }
  }

  Future<void> deleteBatch(String batchId) async {
    _batches.removeWhere((b) => b.id == batchId);
    notifyListeners();
    await StorageService.saveBatches(_batches);
    if (SupabaseService.isReady) {
      try {
        await SupabaseService.deleteBatch(batchId);
      } catch (_) {}
    }
  }

  // --- STUDENT MANAGEMENT ---
  StudentModel? getStudentById(String id) {
    try {
      return _students.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  List<StudentModel> getStudentsByBatch(String batchId) {
    final list = _students.where((s) => s.batchId == batchId).toList();
    list.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    return list;
  }

  Future<void> addStudent(StudentModel student) async {
    _students.add(student);
    _students.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    notifyListeners();
    await StorageService.saveStudents(_students);
    if (SupabaseService.isReady) {
      try {
        final matchingBatch = _batches.where((b) => b.id == student.batchId).firstOrNull;
        if (matchingBatch != null) {
          await SupabaseService.upsertBatch(matchingBatch);
        }
        await SupabaseService.upsertStudent(student);
      } catch (e) {
        debugPrint('Supabase direct addStudent error: $e');
      }
    }
  }

  Future<void> updateStudent(StudentModel student) async {
    final index = _students.indexWhere((s) => s.id == student.id);
    if (index != -1) {
      _students[index] = student;
      _students.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      notifyListeners();
      await StorageService.saveStudents(_students);
      if (SupabaseService.isReady) {
        try {
          final matchingBatch = _batches.where((b) => b.id == student.batchId).firstOrNull;
          if (matchingBatch != null) {
            await SupabaseService.upsertBatch(matchingBatch);
          }
          await SupabaseService.upsertStudent(student);
        } catch (e) {
          debugPrint('Supabase direct updateStudent error: $e');
        }
      }
    }
  }

  Future<void> deleteStudent(String studentId) async {
    _students.removeWhere((s) => s.id == studentId);
    _marks.removeWhere((m) => m.studentId == studentId);
    _fees.removeWhere((f) => f.studentId == studentId);
    await StorageService.saveStudents(_students);
    await StorageService.saveTestMarks(_marks);
    await StorageService.saveFees(_fees);
    if (SupabaseService.isReady) {
      try {
        await SupabaseService.deleteStudent(studentId);
      } catch (_) {}
    }
    notifyListeners();
  }

  // --- TEST & EVALUATION MANAGEMENT ---
  TestModel? getTestById(String id) {
    try {
      return _tests.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  List<TestModel> getTestsByBatch(String batchId) {
    return _tests.where((t) => t.batchId == batchId).toList();
  }

  Future<void> addTest(TestModel test) async {
    _tests.add(test);
    notifyListeners();
    await StorageService.saveTests(_tests);
    if (SupabaseService.isReady) {
      try {
        final matchingBatch = _batches.where((b) => b.id == test.batchId).firstOrNull;
        if (matchingBatch != null) {
          await SupabaseService.upsertBatch(matchingBatch);
        }
        await SupabaseService.upsertTest(test);
      } catch (e) {
        debugPrint('Supabase direct addTest error: $e');
      }
    }
  }

  Future<void> updateTest(TestModel test) async {
    final index = _tests.indexWhere((t) => t.id == test.id);
    if (index != -1) {
      _tests[index] = test;
      notifyListeners();
      await StorageService.saveTests(_tests);
      if (SupabaseService.isReady) {
        try {
          final matchingBatch = _batches.where((b) => b.id == test.batchId).firstOrNull;
          if (matchingBatch != null) {
            await SupabaseService.upsertBatch(matchingBatch);
          }
          await SupabaseService.upsertTest(test);
        } catch (e) {
          debugPrint('Supabase direct updateTest error: $e');
        }
      }
    }
  }

  Future<void> deleteTest(String testId) async {
    _tests.removeWhere((t) => t.id == testId);
    _marks.removeWhere((m) => m.testId == testId);
    notifyListeners();
    await StorageService.saveTests(_tests);
    await StorageService.saveTestMarks(_marks);
    if (SupabaseService.isReady) {
      try {
        await SupabaseService.deleteTest(testId);
      } catch (_) {}
    }
  }

  // Student Test Marks
  List<StudentTestMarkModel> getMarksForTest(String testId) {
    return _marks.where((m) => m.testId == testId).toList();
  }

  List<StudentTestMarkModel> getMarksForStudent(String studentId) {
    return _marks.where((m) => m.studentId == studentId).toList();
  }

  StudentTestMarkModel? getMarkForStudentAndTest(String studentId, String testId) {
    try {
      return _marks.firstWhere((m) => m.studentId == studentId && m.testId == testId);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveStudentMark(StudentTestMarkModel mark) async {
    final index = _marks.indexWhere(
      (m) => m.testId == mark.testId && m.studentId == mark.studentId,
    );
    if (index != -1) {
      _marks[index] = mark;
    } else {
      _marks.add(mark);
    }
    notifyListeners();
    await StorageService.saveTestMarks(_marks);
    if (SupabaseService.isReady) {
      try {
        await SupabaseService.upsertTestMark(mark);
      } catch (e) {
        debugPrint('Supabase direct saveStudentMark error: $e');
      }
    }
  }

  Future<void> batchSaveMarks(List<StudentTestMarkModel> newMarks) async {
    for (final mark in newMarks) {
      final index = _marks.indexWhere(
        (m) => m.testId == mark.testId && m.studentId == mark.studentId,
      );
      if (index != -1) {
        _marks[index] = mark;
      } else {
        _marks.add(mark);
      }
      if (SupabaseService.isReady) {
        try {
          await SupabaseService.upsertTestMark(mark);
        } catch (_) {}
      }
    }
    notifyListeners();
    await StorageService.saveTestMarks(_marks);
  }

  // --- ATTENDANCE MANAGEMENT ---
  List<AttendanceRecordModel> getAttendanceByBatch(String batchId) {
    final list = _attendance.where((a) => a.batchId == batchId).toList();
    list.sort((a, b) => b.attendanceDate.compareTo(a.attendanceDate));
    return list;
  }

  Future<void> saveAttendanceSession(AttendanceRecordModel record) async {
    final index = _attendance.indexWhere((a) => a.id == record.id);
    if (index != -1) {
      _attendance[index] = record;
    } else {
      _attendance.insert(0, record);
    }
    notifyListeners();
    await StorageService.saveAttendance(_attendance);
    if (SupabaseService.isReady) {
      try {
        final matchingBatch = _batches.where((b) => b.id == record.batchId).firstOrNull;
        if (matchingBatch != null) {
          await SupabaseService.upsertBatch(matchingBatch);
        }
        await SupabaseService.upsertAttendance(record);
      } catch (e) {
        debugPrint('Supabase direct saveAttendance error: $e');
      }
    }
  }

  Future<void> deleteAttendanceRecord(String id) async {
    _attendance.removeWhere((a) => a.id == id);
    notifyListeners();
    await StorageService.saveAttendance(_attendance);
    if (SupabaseService.isReady) {
      try {
        await SupabaseService.deleteAttendance(id);
      } catch (_) {}
    }
  }

  double getStudentAttendancePercentage(String studentId, String batchId) {
    final batchSessions = _attendance.where((a) => a.batchId == batchId).toList();
    if (batchSessions.isEmpty) return 100.0;
    int attended = 0;
    int countedSessions = 0;
    for (final s in batchSessions) {
      if (s.records.containsKey(studentId)) {
        countedSessions++;
        if (s.records[studentId] == true) {
          attended++;
        }
      }
    }
    if (countedSessions == 0) return 100.0;
    return (attended / countedSessions) * 100.0;
  }

  // --- FEE COLLECTION MANAGEMENT ---
  List<FeeRecordModel> getFeesForStudent(String studentId) {
    return _fees.where((f) => f.studentId == studentId).toList();
  }

  Future<void> addFee(FeeRecordModel fee) async {
    _fees.add(fee);
    notifyListeners();
    await StorageService.saveFees(_fees);
    if (SupabaseService.isReady) {
      try {
        final matchingStudent = _students.where((s) => s.id == fee.studentId).firstOrNull;
        if (matchingStudent != null) {
          final matchingBatch = _batches.where((b) => b.id == matchingStudent.batchId).firstOrNull;
          if (matchingBatch != null) {
            await SupabaseService.upsertBatch(matchingBatch);
          }
          await SupabaseService.upsertStudent(matchingStudent);
        }
        await SupabaseService.upsertFee(fee);
      } catch (e) {
        debugPrint('Supabase direct addFee error: $e');
      }
    }
  }

  Future<void> updateFee(FeeRecordModel fee) async {
    final index = _fees.indexWhere((f) => f.id == fee.id);
    if (index != -1) {
      _fees[index] = fee;
      notifyListeners();
      await StorageService.saveFees(_fees);
      if (SupabaseService.isReady) {
        try {
          await SupabaseService.upsertFee(fee);
        } catch (e) {
          debugPrint('Supabase direct updateFee error: $e');
        }
      }
    }
  }

  Future<void> recordPayment({
    required String feeId,
    required double paymentAmount,
    required String paymentMode,
    required String transactionRef,
  }) async {
    final index = _fees.indexWhere((f) => f.id == feeId);
    if (index != -1) {
      final current = _fees[index];
      final newPaid = (current.paidAmount + paymentAmount).clamp(0.0, current.totalAmount);
      final newStatus = newPaid >= current.totalAmount
          ? FeeStatus.paid
          : (newPaid > 0 ? FeeStatus.partial : FeeStatus.pending);

      final updated = current.copyWith(
        paidAmount: newPaid,
        status: newStatus,
        paymentMode: paymentMode,
        transactionRef: transactionRef.isNotEmpty ? transactionRef : current.transactionRef,
        paidDate: DateTime.now(),
      );
      _fees[index] = updated;
      notifyListeners();
      await StorageService.saveFees(_fees);
      if (SupabaseService.isReady) {
        try {
          await SupabaseService.upsertFee(updated);
        } catch (e) {
          debugPrint('Supabase direct recordPayment error: $e');
        }
      }
    }
  }

  Future<void> deleteFee(String feeId) async {
    _fees.removeWhere((f) => f.id == feeId);
    notifyListeners();
    await StorageService.saveFees(_fees);
    if (SupabaseService.isReady) {
      try {
        await SupabaseService.deleteFee(feeId);
      } catch (_) {}
    }
  }

  // --- ANALYTICS & DASHBOARD AGGREGATES ---
  int get totalStudentsCount => _students.length;
  int get activeBatchesCount => _batches.length;

  double get pendingFeesTotal {
    double total = 0;
    for (final f in _fees) {
      total += f.pendingAmount;
    }
    return total;
  }

  double get collectedFeesTotal {
    double total = 0;
    for (final f in _fees) {
      total += f.paidAmount;
    }
    return total;
  }

  int get upcomingTestsCount {
    final now = DateTime.now();
    return _tests.where((t) => t.testDate.isAfter(now.subtract(const Duration(hours: 12)))).length;
  }

  double get overallAttendanceRate {
    if (_attendance.isEmpty) return 0.0;
    int totalPresents = 0;
    int totalSlots = 0;
    for (final record in _attendance) {
      totalPresents += record.presentCount;
      totalSlots += record.totalCount;
    }
    if (totalSlots == 0) return 0.0;
    return (totalPresents / totalSlots) * 100;
  }
}
