import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skolaapp/app_theme.dart';
import 'package:skolaapp/data/models/schedule_model.dart';
import 'package:skolaapp/features/dashboard/widgets/today_schedule_tile.dart';

void main() {
  Widget createTestWidget(ScheduleModel schedule) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: TodayScheduleTile(
          schedule: schedule,
          onTap: () {},
        ),
      ),
    );
  }

  group('TodayScheduleTile Status Badge Tests', () {
    testWidgets('Shows "Siap" with blue badge when current time is in session range', (tester) async {
      final now = DateTime.now();
      // Format start time to 30 min ago, and end time to 30 min in future
      final start = now.subtract(const Duration(minutes: 30));
      final end = now.add(const Duration(minutes: 30));
      final startTimeStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
      final endTimeStr = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

      final schedule = ScheduleModel(
        id: 's-1',
        teacherId: 't-1',
        classId: 'c-1',
        className: '10A',
        subjectId: 'sub-1',
        subjectName: 'Bahasa Indonesia',
        dayOfWeek: now.weekday,
        periodStart: 1,
        periodEnd: 2,
        startTime: startTimeStr,
        endTime: endTimeStr,
        isCompletedToday: false,
      );

      await tester.pumpWidget(createTestWidget(schedule));
      await tester.pumpAndSettle();

      expect(find.text('Siap'), findsOneWidget);
      expect(find.text('Locked'), findsNothing);
      expect(find.text('Selesai'), findsNothing);
    });

    testWidgets('Shows "Locked" with gray badge when current time is outside session range (in the future)', (tester) async {
      final now = DateTime.now();
      // Start time 2 hours from now
      final start = now.add(const Duration(hours: 2));
      final end = now.add(const Duration(hours: 3));
      final startTimeStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
      final endTimeStr = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

      final schedule = ScheduleModel(
        id: 's-2',
        teacherId: 't-1',
        classId: 'c-1',
        className: '10A',
        subjectId: 'sub-1',
        subjectName: 'Matematika',
        dayOfWeek: now.weekday,
        periodStart: 3,
        periodEnd: 4,
        startTime: startTimeStr,
        endTime: endTimeStr,
        isCompletedToday: false,
      );

      await tester.pumpWidget(createTestWidget(schedule));
      await tester.pumpAndSettle();

      expect(find.text('Locked'), findsOneWidget);
      expect(find.text('Siap'), findsNothing);
      expect(find.text('Selesai'), findsNothing);
    });

    testWidgets('Shows "Selesai" with green badge when schedule is completed today', (tester) async {
      final now = DateTime.now();
      final schedule = ScheduleModel(
        id: 's-3',
        teacherId: 't-1',
        classId: 'c-1',
        className: '10A',
        subjectId: 'sub-1',
        subjectName: 'Fisika',
        dayOfWeek: now.weekday,
        periodStart: 1,
        periodEnd: 2,
        startTime: '07:00',
        endTime: '08:30',
        isCompletedToday: true,
      );

      await tester.pumpWidget(createTestWidget(schedule));
      await tester.pumpAndSettle();

      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('Locked'), findsNothing);
      expect(find.text('Siap'), findsNothing);
    });
  });
}
