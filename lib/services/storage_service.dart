import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/demo_config.dart';
import '../models/batch_model.dart';
import '../models/student_model.dart';
import '../models/test_model.dart';
import '../models/attendance_model.dart';
import '../models/fee_model.dart';
import 'mock_data_service.dart';
import 'supabase_service.dart';

class StorageService {
  static String get _keyBatches =>
      DemoConfig.isDemoMode ? 'demo_batches_v1' : 'coaching_batches_v1';
  static String get _keyStudents =>
      DemoConfig.isDemoMode ? 'demo_students_v1' : 'coaching_students_v1';
  static String get _keyTests =>
      DemoConfig.isDemoMode ? 'demo_tests_v1' : 'coaching_tests_v1';
  static String get _keyMarks =>
      DemoConfig.isDemoMode ? 'demo_marks_v1' : 'coaching_marks_v1';
  static String get _keyAttendance =>
      DemoConfig.isDemoMode ? 'demo_attendance_v1' : 'coaching_attendance_v1';
  static String get _keyFees =>
      DemoConfig.isDemoMode ? 'demo_fees_v1' : 'coaching_fees_v1';
  static const String _keyProductionCleaned = 'coaching_production_cleaned_v1';
  static const String _keyDemoSeeded = 'demo_data_seeded_v1';

  /// Ensures that any old debug mock data cached in local device storage is purged once in production,
  /// or seeds fresh demo data if running in Demo Mode.
  static Future<void> ensureProductionClean() async {
    final prefs = await SharedPreferences.getInstance();
    if (DemoConfig.isDemoMode) {
      final seeded = prefs.getBool(_keyDemoSeeded) ?? false;
      if (!seeded) {
        await resetDemoData();
      }
      return;
    }

    if (!(prefs.getBool(_keyProductionCleaned) ?? false)) {
      await resetAllData();
      await prefs.setBool(_keyProductionCleaned, true);
    }
  }

  /// Resets and seeds pristine mock data for portfolio recordings.
  static Future<void> resetDemoData() async {
    final prefs = await SharedPreferences.getInstance();
    final mock = MockDataService.generateMockData();
    await _saveBatchesLocal(mock.batches);
    await _saveStudentsLocal(mock.students);
    await _saveTestsLocal(mock.tests);
    await _saveTestMarksLocal(mock.marks);
    await _saveAttendanceLocal(mock.attendance);
    await _saveFeesLocal(mock.fees);
    await prefs.setBool(_keyDemoSeeded, true);
  }

  // ===================== BATCHES =====================
  static Future<List<BatchModel>> loadBatches() async {
    if (SupabaseService.isReady) {
      try {
        final cloudBatches = await SupabaseService.getBatches();
        await _saveBatchesLocal(cloudBatches);
        return cloudBatches;
      } catch (e) {
        debugPrint('Supabase loadBatches error: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyBatches);
    if (jsonString == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) => BatchModel.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveBatches(List<BatchModel> batches) async {
    await _saveBatchesLocal(batches);
  }

  static Future<void> upsertBatchCloud(BatchModel batch) async {
    if (SupabaseService.isReady) {
      try {
        await SupabaseService.upsertBatch(batch);
      } catch (e) {
        debugPrint('Supabase upsertBatchCloud error (${batch.id}): $e');
      }
    }
  }

  static Future<void> _saveBatchesLocal(List<BatchModel> batches) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(batches.map((e) => e.toJson()).toList());
    await prefs.setString(_keyBatches, encoded);
  }

  // ===================== STUDENTS =====================
  static Future<List<StudentModel>> loadStudents() async {
    if (SupabaseService.isReady) {
      try {
        final cloudStudents = await SupabaseService.getStudents();
        await _saveStudentsLocal(cloudStudents);
        return cloudStudents;
      } catch (e) {
        debugPrint('Supabase loadStudents error: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyStudents);
    if (jsonString == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) => StudentModel.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveStudents(List<StudentModel> students) async {
    await _saveStudentsLocal(students);
  }

  static Future<void> upsertStudentCloud(StudentModel student) async {
    if (SupabaseService.isReady) {
      try {
        await SupabaseService.upsertStudent(student);
      } catch (e) {
        debugPrint('Supabase upsertStudentCloud error (${student.id}): $e');
      }
    }
  }

  static Future<void> _saveStudentsLocal(List<StudentModel> students) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(students.map((e) => e.toJson()).toList());
    await prefs.setString(_keyStudents, encoded);
  }

  // ===================== TESTS =====================
  static Future<List<TestModel>> loadTests() async {
    if (SupabaseService.isReady) {
      try {
        final cloudTests = await SupabaseService.getTests();
        await _saveTestsLocal(cloudTests);
        return cloudTests;
      } catch (e) {
        debugPrint('Supabase loadTests error: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyTests);
    if (jsonString == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) => TestModel.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveTests(List<TestModel> tests) async {
    await _saveTestsLocal(tests);
  }

  static Future<void> upsertTestCloud(TestModel test) async {
    if (SupabaseService.isReady) {
      try {
        await SupabaseService.upsertTest(test);
      } catch (e) {
        debugPrint('Supabase upsertTestCloud error (${test.id}): $e');
      }
    }
  }

  static Future<void> _saveTestsLocal(List<TestModel> tests) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(tests.map((e) => e.toJson()).toList());
    await prefs.setString(_keyTests, encoded);
  }

  // ===================== TEST MARKS =====================
  static Future<List<StudentTestMarkModel>> loadTestMarks() async {
    if (SupabaseService.isReady) {
      try {
        final cloudMarks = await SupabaseService.getTestMarks();
        await _saveTestMarksLocal(cloudMarks);
        return cloudMarks;
      } catch (e) {
        debugPrint('Supabase loadTestMarks error: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyMarks);
    if (jsonString == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) => StudentTestMarkModel.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveTestMarks(List<StudentTestMarkModel> marks) async {
    await _saveTestMarksLocal(marks);
  }

  static Future<void> upsertTestMarkCloud(StudentTestMarkModel mark) async {
    if (SupabaseService.isReady) {
      try {
        await SupabaseService.upsertTestMark(mark);
      } catch (e) {
        debugPrint('Supabase upsertTestMarkCloud error (${mark.id}): $e');
      }
    }
  }

  static Future<void> _saveTestMarksLocal(List<StudentTestMarkModel> marks) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(marks.map((e) => e.toJson()).toList());
    await prefs.setString(_keyMarks, encoded);
  }

  // ===================== ATTENDANCE =====================
  static Future<List<AttendanceRecordModel>> loadAttendance() async {
    if (SupabaseService.isReady) {
      try {
        final cloudAttendance = await SupabaseService.getAttendance();
        await _saveAttendanceLocal(cloudAttendance);
        return cloudAttendance;
      } catch (e) {
        debugPrint('Supabase loadAttendance error: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyAttendance);
    if (jsonString == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) => AttendanceRecordModel.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAttendance(List<AttendanceRecordModel> attendance) async {
    await _saveAttendanceLocal(attendance);
  }

  static Future<void> upsertAttendanceCloud(AttendanceRecordModel attendance) async {
    if (SupabaseService.isReady) {
      try {
        await SupabaseService.upsertAttendance(attendance);
      } catch (e) {
        debugPrint('Supabase upsertAttendanceCloud error (${attendance.id}): $e');
      }
    }
  }

  static Future<void> _saveAttendanceLocal(List<AttendanceRecordModel> attendance) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(attendance.map((e) => e.toJson()).toList());
    await prefs.setString(_keyAttendance, encoded);
  }

  // ===================== FEES =====================
  static Future<List<FeeRecordModel>> loadFees() async {
    if (SupabaseService.isReady) {
      try {
        final cloudFees = await SupabaseService.getFees();
        await _saveFeesLocal(cloudFees);
        return cloudFees;
      } catch (e) {
        debugPrint('Supabase loadFees error: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyFees);
    if (jsonString == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) => FeeRecordModel.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveFees(List<FeeRecordModel> fees) async {
    await _saveFeesLocal(fees);
  }

  static Future<void> upsertFeeCloud(FeeRecordModel fee) async {
    if (SupabaseService.isReady) {
      try {
        await SupabaseService.upsertFee(fee);
      } catch (e) {
        debugPrint('Supabase upsertFeeCloud error (${fee.id}): $e');
      }
    }
  }

  static Future<void> _saveFeesLocal(List<FeeRecordModel> fees) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(fees.map((e) => e.toJson()).toList());
    await prefs.setString(_keyFees, encoded);
  }

  // ===================== RESET ALL =====================
  static Future<void> resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBatches);
    await prefs.remove(_keyStudents);
    await prefs.remove(_keyTests);
    await prefs.remove(_keyMarks);
    await prefs.remove(_keyAttendance);
    await prefs.remove(_keyFees);
  }
}
