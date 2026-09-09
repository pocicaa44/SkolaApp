import 'schedule_model.dart';

class SessionModel {
  final String id;
  final String scheduleId;
  final DateTime sessionDate;
  final String status; // LOCKED, OPEN, CLOSED
  final ScheduleModel schedule;

  const SessionModel({
    required this.id,
    required this.scheduleId,
    required this.sessionDate,
    required this.status,
    required this.schedule,
  });

  bool get isLocked =>
      status == 'LOCKED' ||
      schedule.getStatus(DateTime.now()) == SessionState.locked;
  bool get isOpen =>
      status == 'OPEN' ||
      schedule.getStatus(DateTime.now()) == SessionState.open;
  bool get isClosed =>
      status == 'CLOSED' ||
      schedule.getStatus(DateTime.now()) == SessionState.closed;

  factory SessionModel.fromSchedule(ScheduleModel schedule, DateTime date) {
    final state = schedule.getStatus(DateTime.now());
    String statusStr = 'LOCKED';
    if (state == SessionState.open) statusStr = 'OPEN';
    if (state == SessionState.closed) statusStr = 'CLOSED';

    return SessionModel(
      id: '${schedule.id}_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      scheduleId: schedule.id,
      sessionDate: date,
      status: statusStr,
      schedule: schedule,
    );
  }
}
