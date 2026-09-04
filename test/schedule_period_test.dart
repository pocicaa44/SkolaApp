import 'package:flutter_test/flutter_test.dart';
import 'package:skolaapp/schedule_page.dart';

void main() {
  group('SchoolPeriodHelper Tests', () {
    test('Senin (Day 1, 45 min/JP) calculates correct JP start and end times', () {
      final times = SchoolPeriodHelper.calculateTimes(
        dayOfWeek: 1, // Senin
        startPeriod: 1,
        endPeriod: 2,
        customDurationMinutes: 45,
      );

      // JP 1-2 on Monday (45 min): 07:00 to 08:30 (90 min)
      expect(times['startTime'], '07:00');
      expect(times['endTime'], '08:30');
      expect(times['totalDuration'], '90');
    });

    test('Selasa (Day 2, 30 min/JP) calculates correct JP start and end times', () {
      final times = SchoolPeriodHelper.calculateTimes(
        dayOfWeek: 2, // Selasa
        startPeriod: 1,
        endPeriod: 2,
        customDurationMinutes: 30,
      );

      // JP 1-2 on Tuesday (30 min): 07:00 to 08:00 (60 min)
      expect(times['startTime'], '07:00');
      expect(times['endTime'], '08:00');
      expect(times['totalDuration'], '60');
    });

    test('Jumat (Day 5, 40 min/JP) JP 3-4 calculation', () {
      final times = SchoolPeriodHelper.calculateTimes(
        dayOfWeek: 5, // Jumat
        startPeriod: 3,
        endPeriod: 4,
        customDurationMinutes: 40,
      );

      // JP 1: 07:00 - 07:40
      // JP 2: 07:40 - 08:20
      // JP 3: 08:20 - 09:00
      // JP 4: 09:00 - 09:40
      expect(times['startTime'], '08:20');
      expect(times['endTime'], '09:40');
      expect(times['totalDuration'], '80');
    });

    test('Operational days configuration strictly contains Monday to Friday (1 to 5)', () {
      expect(SchoolPeriodHelper.periodDurations.keys, containsAll([1, 2, 3, 4, 5]));
      expect(SchoolPeriodHelper.periodDurations.containsKey(6), isFalse); // No Saturday
      expect(SchoolPeriodHelper.periodDurations.containsKey(7), isFalse); // No Sunday
    });
  });

  group('TeacherSchedule SessionState Tests', () {
    const schedule = TeacherSchedule(
      id: 'test-1',
      teacherId: 't-1',
      classId: 'c-1',
      className: '11A',
      subjectId: 's-1',
      subjectName: 'Matematika',
      room: 'C10',
      dayOfWeek: 1,
      periodStart: 1,
      periodEnd: 2,
      startTime: '07:00',
      endTime: '08:30',
    );

    test('Status is LOCKED before start time', () {
      final now = DateTime(2026, 9, 1, 6, 30); // 06:30
      expect(schedule.getStatus(now), SessionState.locked);
    });

    test('Status is OPEN during schedule time', () {
      final now = DateTime(2026, 9, 1, 7, 30); // 07:30
      expect(schedule.getStatus(now), SessionState.open);
      final remaining = schedule.getRemainingDuration(now);
      expect(remaining.inMinutes, 60); // 08:30 - 07:30 = 60 min
    });

    test('Status is CLOSED after end time', () {
      final now = DateTime(2026, 9, 1, 9, 00); // 09:00
      expect(schedule.getStatus(now), SessionState.closed);
      final remaining = schedule.getRemainingDuration(now);
      expect(remaining, Duration.zero);
    });

    test('Status is CLOSED if marked isLocked or isCompletedToday', () {
      const lockedSchedule = TeacherSchedule(
        id: 'test-2',
        teacherId: 't-1',
        classId: 'c-1',
        className: '11A',
        subjectId: 's-1',
        subjectName: 'Matematika',
        room: 'C10',
        dayOfWeek: 1,
        periodStart: 1,
        periodEnd: 2,
        startTime: '07:00',
        endTime: '08:30',
        isCompletedToday: true,
        isLocked: true,
      );

      final now = DateTime(2026, 9, 1, 7, 30); // during time, but already locked
      expect(lockedSchedule.getStatus(now), SessionState.closed);
    });
  });
}
