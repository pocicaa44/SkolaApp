import '../../core/utils/period_helper.dart';

enum SessionState { locked, open, closed }

class ScheduleModel {
  final String id;
  final String teacherId;
  final String? teacherName;
  final String classId;
  final String className;
  final String subjectId;
  final String subjectName;
  final String room;
  final int dayOfWeek; // 1 = Senin ... 7 = Minggu
  final int periodStart;
  final int periodEnd;
  final String startTime; // "07:00"
  final String endTime; // "08:30"
  final int studentCount;
  final bool isCompletedToday;
  final bool isLocked;

  const ScheduleModel({
    required this.id,
    required this.teacherId,
    this.teacherName,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    this.room = '',
    required this.dayOfWeek,
    required this.periodStart,
    required this.periodEnd,
    required this.startTime,
    required this.endTime,
    this.studentCount = 0,
    this.isCompletedToday = false,
    this.isLocked = false,
  });

  SessionState getStatus(DateTime now) {
    if (isCompletedToday || isLocked) {
      return SessionState.closed;
    }
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    if (startParts.length < 2 || endParts.length < 2) {
      return SessionState.locked;
    }

    final startDt = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );
    final endDt = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );

    if (now.isBefore(startDt)) {
      return SessionState.locked;
    } else if (now.isAfter(endDt)) {
      return SessionState.closed;
    } else {
      return SessionState.open;
    }
  }

  Duration getRemainingDuration(DateTime now) {
    final endParts = endTime.split(':');
    if (endParts.length < 2) return Duration.zero;
    final endDt = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );
    final diff = endDt.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  factory ScheduleModel.fromJson(
    Map<String, dynamic> json, {
    int studentCount = 0,
    bool isCompletedToday = false,
  }) {
    final sId = json['id'] as String? ?? '';
    final tId = json['teacher_id'] as String? ?? '';
    final cId = json['class_id'] as String? ?? '';
    final subId = json['subject_id'] as String? ?? '';
    final day = json['day_of_week'] as int? ?? 1;
    final pStart = json['period_start'] as int? ?? 1;
    final pEnd = json['period_end'] as int? ?? 1;

    final subjectMap = json['subjects'] as Map<String, dynamic>?;
    final classMap = json['classes'] as Map<String, dynamic>?;
    final teacherMap = json['teachers'] as Map<String, dynamic>?;

    final sName =
        subjectMap?['name'] as String? ??
        (json['subject_name'] as String? ?? 'Pelajaran');
    final cName =
        classMap?['name'] as String? ??
        (json['class_name'] as String? ?? 'Kelas');
    final tName =
        teacherMap?['name'] as String? ?? (json['teacher_name'] as String?);

    final sTime = PeriodHelper.getPeriodStartTime(day, pStart);
    final eTime = PeriodHelper.getPeriodEndTime(day, pEnd);

    return ScheduleModel(
      id: sId,
      teacherId: tId,
      teacherName: tName,
      classId: cId,
      className: cName,
      subjectId: subId,
      subjectName: sName,
      room: json['room'] as String? ?? '',
      dayOfWeek: day,
      periodStart: pStart,
      periodEnd: pEnd,
      startTime: sTime,
      endTime: eTime,
      studentCount: studentCount,
      isCompletedToday: isCompletedToday,
    );
  }

  ScheduleModel copyWith({
    String? id,
    String? teacherId,
    String? teacherName,
    String? classId,
    String? className,
    String? subjectId,
    String? subjectName,
    String? room,
    int? dayOfWeek,
    int? periodStart,
    int? periodEnd,
    String? startTime,
    String? endTime,
    int? studentCount,
    bool? isCompletedToday,
    bool? isLocked,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      room: room ?? this.room,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      studentCount: studentCount ?? this.studentCount,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

/// Backward-compatibility alias
typedef TeacherSchedule = ScheduleModel;
