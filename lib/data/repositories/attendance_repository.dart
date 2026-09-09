import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance_model.dart';
import '../models/student_model.dart';

class AttendanceRepository {
  final SupabaseClient _supabase;

  AttendanceRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  Future<List<StudentModel>> getStudentsByClass(String classId) async {
    final res = await _supabase
        .from('students')
        .select('id, student_code, name, gender, class_id')
        .eq('class_id', classId)
        .order('name');

    return (res as List).map((j) => StudentModel.fromJson(j)).toList();
  }

  Future<Map<String, AttendanceStatus>> getAttendanceForSession({
    required String scheduleId,
    required DateTime date,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final res = await _supabase
        .from('attendance')
        .select('student_id, status')
        .eq('schedule_id', scheduleId)
        .eq('attendance_date', dateStr);

    final Map<String, AttendanceStatus> map = {};
    for (var row in res as List) {
      final studentId = row['student_id'] as String? ?? '';
      final statusStr = row['status'] as String? ?? '';
      final status = AttendanceStatus.fromDb(statusStr);
      if (studentId.isNotEmpty && status != null) {
        map[studentId] = status;
      }
    }
    return map;
  }

  Future<void> saveBulkAttendance({
    required String scheduleId,
    required String classId,
    required DateTime date,
    required Map<String, AttendanceStatus> attendanceMap,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final List<Map<String, dynamic>> records = [];
    attendanceMap.forEach((studentId, status) {
      records.add({
        'schedule_id': scheduleId,
        'student_id': studentId,
        'attendance_date': dateStr,
        'status': status.dbCode,
      });
    });

    if (records.isEmpty) return;

    // Bulk upsert directly in one network call
    await _supabase
        .from('attendance')
        .upsert(records, onConflict: 'schedule_id,student_id,attendance_date');
  }

  Future<int> getStudentCountForClass(String classId) async {
    try {
      final res = await _supabase
          .from('students')
          .select('id')
          .eq('class_id', classId);
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }
}
