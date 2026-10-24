import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/demo_config.dart';
import '../config/supabase_config.dart';
import '../models/batch_model.dart';
import '../models/student_model.dart';
import '../models/test_model.dart';
import '../models/attendance_model.dart';
import '../models/fee_model.dart';

class SupabaseService {
  static SupabaseClient? get client {
    if (DemoConfig.isDemoMode) return null;
    if (!SupabaseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static bool get isReady => !DemoConfig.isDemoMode && client != null;

  // ===================== BATCHES =====================
  static Future<List<BatchModel>> getBatches() async {
    final c = client;
    if (c == null) return [];
    final data = await c.from('batches').select();
    return (data as List).map((e) => BatchModel.fromSupabaseJson(e)).toList();
  }

  static Future<void> upsertBatch(BatchModel batch) async {
    final c = client;
    if (c == null) return;
    await c.from('batches').upsert(batch.toSupabaseJson());
  }

  static Future<void> deleteBatch(String id) async {
    final c = client;
    if (c == null) return;
    await c.from('batches').delete().eq('id', id);
  }

  // ===================== STUDENTS =====================
  static Future<List<StudentModel>> getStudents() async {
    final c = client;
    if (c == null) return [];
    final data = await c.from('students').select();
    return (data as List).map((e) => StudentModel.fromSupabaseJson(e)).toList();
  }

  static Future<void> upsertStudent(StudentModel student) async {
    final c = client;
    if (c == null) return;
    await c.from('students').upsert(student.toSupabaseJson());
  }

  static Future<void> deleteStudent(String id) async {
    final c = client;
    if (c == null) return;
    await c.from('students').delete().eq('id', id);
  }

  // ===================== TESTS =====================
  static Future<List<TestModel>> getTests() async {
    final c = client;
    if (c == null) return [];
    final data = await c.from('tests').select();
    return (data as List).map((e) => TestModel.fromSupabaseJson(e)).toList();
  }

  static Future<void> upsertTest(TestModel test) async {
    final c = client;
    if (c == null) return;
    await c.from('tests').upsert(test.toSupabaseJson());
  }

  static Future<void> deleteTest(String id) async {
    final c = client;
    if (c == null) return;
    await c.from('tests').delete().eq('id', id);
  }

  // ===================== TEST MARKS =====================
  static Future<List<StudentTestMarkModel>> getTestMarks() async {
    final c = client;
    if (c == null) return [];
    final data = await c.from('test_marks').select();
    return (data as List).map((e) => StudentTestMarkModel.fromSupabaseJson(e)).toList();
  }

  static Future<void> upsertTestMark(StudentTestMarkModel mark) async {
    final c = client;
    if (c == null) return;
    await c.from('test_marks').upsert(mark.toSupabaseJson());
  }

  static Future<void> deleteTestMark(String id) async {
    final c = client;
    if (c == null) return;
    await c.from('test_marks').delete().eq('id', id);
  }

  // ===================== ATTENDANCE =====================
  static Future<List<AttendanceRecordModel>> getAttendance() async {
    final c = client;
    if (c == null) return [];
    final data = await c.from('attendance').select();
    return (data as List).map((e) => AttendanceRecordModel.fromSupabaseJson(e)).toList();
  }

  static Future<void> upsertAttendance(AttendanceRecordModel record) async {
    final c = client;
    if (c == null) return;
    await c.from('attendance').upsert(record.toSupabaseJson());
  }

  static Future<void> deleteAttendance(String id) async {
    final c = client;
    if (c == null) return;
    await c.from('attendance').delete().eq('id', id);
  }

  // ===================== FEES =====================
  static Future<List<FeeRecordModel>> getFees() async {
    final c = client;
    if (c == null) return [];
    final data = await c.from('fees').select();
    return (data as List).map((e) => FeeRecordModel.fromSupabaseJson(e)).toList();
  }

  static Future<void> upsertFee(FeeRecordModel fee) async {
    final c = client;
    if (c == null) return;
    await c.from('fees').upsert(fee.toSupabaseJson());
  }

  static Future<void> deleteFee(String id) async {
    final c = client;
    if (c == null) return;
    await c.from('fees').delete().eq('id', id);
  }

  // ===================== ONE-CLICK SYNC ALL =====================
  static Future<void> syncLocalDataToSupabase({
    required List<BatchModel> batches,
    required List<StudentModel> students,
    required List<TestModel> tests,
    required List<StudentTestMarkModel> marks,
    required List<AttendanceRecordModel> attendance,
    required List<FeeRecordModel> fees,
  }) async {
    final c = client;
    if (c == null) return;

    // 1. Batches first (independent)
    for (final b in batches) {
      try {
        await c.from('batches').upsert(b.toSupabaseJson());
      } catch (e) {
        debugPrint('Sync batch error (${b.id}): $e');
      }
    }

    // 2. Students second (depends on batches)
    for (final s in students) {
      try {
        await c.from('students').upsert(s.toSupabaseJson());
      } catch (e) {
        debugPrint('Sync student error (${s.id}): $e');
      }
    }

    // 3. Tests third (depends on batches)
    for (final t in tests) {
      try {
        await c.from('tests').upsert(t.toSupabaseJson());
      } catch (e) {
        debugPrint('Sync test error (${t.id}): $e');
      }
    }

    // 4. Test Marks fourth (depends on tests and students)
    for (final m in marks) {
      try {
        await c.from('test_marks').upsert(m.toSupabaseJson());
      } catch (e) {
        debugPrint('Sync mark error (${m.id}): $e');
      }
    }

    // 5. Attendance fifth (depends on batches)
    for (final a in attendance) {
      try {
        await c.from('attendance').upsert(a.toSupabaseJson());
      } catch (e) {
        debugPrint('Sync attendance error (${a.id}): $e');
      }
    }

    // 6. Fees sixth (depends on students)
    for (final f in fees) {
      try {
        await c.from('fees').upsert(f.toSupabaseJson());
      } catch (e) {
        debugPrint('Sync fee error (${f.id}): $e');
      }
    }
  }
}
