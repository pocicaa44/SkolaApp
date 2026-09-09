import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../core/utils/period_helper.dart';
import '../../../data/models/schedule_model.dart';

class TodayScheduleTile extends StatelessWidget {
  final ScheduleModel schedule;
  final VoidCallback onTap;

  const TodayScheduleTile({
    super.key,
    required this.schedule,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = schedule.getStatus(DateTime.now());

    final String statusLabel;
    final Color badgeColor;
    final Color badgeBgColor;

    if (schedule.isCompletedToday) {
      statusLabel = 'Selesai';
      badgeColor = AppTheme.success;
      badgeBgColor = AppTheme.successSurface;
    } else if (status == SessionState.open) {
      statusLabel = 'Siap';
      badgeColor = AppTheme.primary;
      badgeBgColor = AppTheme.primaryLight;
    } else {
      statusLabel = 'Locked';
      badgeColor = AppTheme.textMuted;
      badgeBgColor = const Color(0xFFF1F3F5);
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppTheme.space10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: const BorderSide(color: AppTheme.border),
      ),
      color: AppTheme.surface,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space16,
          vertical: AppTheme.space6,
        ),
        onTap: onTap,
        title: Text(
          schedule.subjectName,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${schedule.className} • ${PeriodHelper.formatPeriodRange(schedule.dayOfWeek, schedule.periodStart, schedule.periodEnd)}',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeBgColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
            border: (statusLabel == 'Locked')
                ? Border.all(color: AppTheme.border)
                : null,
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ),
      ),
    );
  }
}
