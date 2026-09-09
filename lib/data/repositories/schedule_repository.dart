import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/period_helper.dart';
import '../models/schedule_model.dart';

class OccupiedSlotInfo {
  final int start;
  final int end;
  final String subject;
  final String label;
  final bool isTeacherOwn;
  final String? teacherName;

  const OccupiedSlotInfo({
    required this.start,
    required this.end,
    required this.subject,
    required this.label,
    required this.isTeacherOwn,
    this.teacherName,
  });
}

class OccupiedPeriodsResult {
  final Set<int> occupiedPeriods;
  final List<OccupiedSlotInfo> occupiedSlotsInfo;

  const OccupiedPeriodsResult({
    required this.occupiedPeriods,
    required this.occupiedSlotsInfo,
  });
}

class ScheduleRepository {
  final SupabaseClient _supabase;

  ScheduleRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  Future<List<ScheduleModel>> getTeacherSchedules(String teacherId) async {
    final res = await _supabase
        .from('schedules')
        .select(
          'id, teacher_id, class_id, subject_id, room, day_of_week, period_start, period_end, classes(id, name), subjects(id, name)',
        )
        .eq('teacher_id', teacherId)
        .order('day_of_week')
        .order('period_start');

    final List<ScheduleModel> list = [];
    for (var row in res as List) {
      list.add(ScheduleModel.fromJson(row));
    }
    return list;
  }

  Future<List<ScheduleModel>> getTodaySchedules(
    String teacherId,
    int dayOfWeek,
  ) async {
    final res = await _supabase
        .from('schedules')
        .select(
          'id, teacher_id, class_id, subject_id, room, day_of_week, period_start, period_end, classes(id, name), subjects(id, name)',
        )
        .eq('teacher_id', teacherId)
        .eq('day_of_week', dayOfWeek)
        .order('period_start');

    final List<ScheduleModel> list = [];
    for (var row in res as List) {
      list.add(ScheduleModel.fromJson(row));
    }
    return list;
  }

  Future<OccupiedPeriodsResult> computeOccupiedPeriods({
    required String classId,
    required String teacherId,
    required int dayOfWeek,
    String? excludeScheduleId,
  }) async {
    // 1. Ambil seluruh jadwal di kelas ini pada hari terpilih (termasuk jadwal guru lain)
    var classQuery = _supabase
        .from('schedules')
        .select(
          'id, teacher_id, period_start, period_end, subjects(name), classes(name), teachers(name)',
        )
        .eq('class_id', classId)
        .eq('day_of_week', dayOfWeek);

    if (excludeScheduleId != null && excludeScheduleId.isNotEmpty) {
      classQuery = classQuery.neq('id', excludeScheduleId);
    }

    // 2. Ambil seluruh jadwal guru ini di kelas manapun pada hari terpilih (konflik jadwal diri sendiri)
    var teacherQuery = _supabase
        .from('schedules')
        .select(
          'id, teacher_id, period_start, period_end, subjects(name), classes(name), teachers(name)',
        )
        .eq('teacher_id', teacherId)
        .eq('day_of_week', dayOfWeek);

    if (excludeScheduleId != null && excludeScheduleId.isNotEmpty) {
      teacherQuery = teacherQuery.neq('id', excludeScheduleId);
    }

    final classSchedules = await classQuery;
    final teacherSchedules = await teacherQuery;

    final Set<int> occupied = {};
    final List<OccupiedSlotInfo> occupiedInfo = [];
    final Set<String> processedScheduleIds = {};

    // 1. Tambahkan jadwal guru sendiri di kelas lain
    for (var row in teacherSchedules as List) {
      final id = row['id'] as String;
      processedScheduleIds.add(id);
      final pStart = row['period_start'] as int? ?? 1;
      final pEnd = row['period_end'] as int? ?? 1;
      final subjectMap = row['subjects'] as Map<String, dynamic>?;
      final classMap = row['classes'] as Map<String, dynamic>?;
      final subjectName = subjectMap?['name'] as String? ?? 'Pelajaran';
      final className = classMap?['name'] as String? ?? 'Kelas Lain';

      occupiedInfo.add(
        OccupiedSlotInfo(
          start: pStart,
          end: pEnd,
          subject: subjectName,
          label: 'Jadwal Anda di $className ($subjectName)',
          isTeacherOwn: true,
        ),
      );

      for (int p = pStart; p <= pEnd; p++) {
        occupied.add(p);
      }
    }

    // 2. Tambahkan jadwal guru lain di kelas yang dipilih
    for (var row in classSchedules as List) {
      final id = row['id'] as String;
      if (processedScheduleIds.contains(id)) continue;
      processedScheduleIds.add(id);

      final pStart = row['period_start'] as int? ?? 1;
      final pEnd = row['period_end'] as int? ?? 1;
      final subjectMap = row['subjects'] as Map<String, dynamic>?;
      final teacherMap = row['teachers'] as Map<String, dynamic>?;
      final subjectName = subjectMap?['name'] as String? ?? 'Pelajaran';
      final teacherName = teacherMap?['name'] as String? ?? 'Guru Lain';

      occupiedInfo.add(
        OccupiedSlotInfo(
          start: pStart,
          end: pEnd,
          subject: subjectName,
          label: '$subjectName ($teacherName)',
          isTeacherOwn: false,
          teacherName: teacherName,
        ),
      );

      for (int p = pStart; p <= pEnd; p++) {
        occupied.add(p);
      }
    }

    return OccupiedPeriodsResult(
      occupiedPeriods: occupied,
      occupiedSlotsInfo: occupiedInfo,
    );
  }

  Future<void> saveSchedule({
    String? id,
    required String teacherId,
    required String classId,
    required String subjectId,
    required int dayOfWeek,
    required int periodStart,
    required int periodEnd,
    String? room,
  }) async {
    final startTime = PeriodHelper.getPeriodStartTime(dayOfWeek, periodStart);
    final endTime = PeriodHelper.getPeriodEndTime(dayOfWeek, periodEnd);

    final payload = <String, dynamic>{
      'teacher_id': teacherId,
      'class_id': classId,
      'subject_id': subjectId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'period_start': periodStart,
      'period_end': periodEnd,
    };
    if (room != null && room.isNotEmpty) {
      payload['room'] = room;
    }

    if (id != null && id.isNotEmpty) {
      await _supabase.from('schedules').update(payload).eq('id', id);
    } else {
      await _supabase.from('schedules').insert(payload);
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _supabase.from('schedules').delete().eq('id', scheduleId);
  }

  Future<bool> hasAttendanceHistory(String scheduleId) async {
    try {
      final count = await _supabase
          .from('attendance')
          .select('id')
          .eq('schedule_id', scheduleId)
          .limit(1);
      return (count as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
