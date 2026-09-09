import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../core/utils/period_helper.dart';
import '../../../core/widgets/realtime_ticker_builder.dart';
import '../../../data/models/schedule_model.dart';

class ActiveSessionCard extends StatelessWidget {
  final ScheduleModel schedule;
  final VoidCallback onTap;

  const ActiveSessionCard({
    super.key,
    required this.schedule,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RealtimeTickerBuilder(
      builder: (context, now) {
        final status = schedule.getStatus(now);
        final remaining = schedule.getRemainingDuration(now);

        Color badgeColor;
        Color badgeBgColor;
        String badgeText;
        IconData statusIcon;

        switch (status) {
          case SessionState.open:
            badgeColor = AppTheme.success;
            badgeBgColor = AppTheme.successSurface;
            badgeText = 'SEDANG BERLANGSUNG';
            statusIcon = Icons.play_circle_outline;
            break;
          case SessionState.locked:
            badgeColor = AppTheme.primary;
            badgeBgColor = AppTheme.primaryLight;
            badgeText = 'BELUM DIMULAI';
            statusIcon = Icons.lock_outline;
            break;
          case SessionState.closed:
            badgeColor = AppTheme.textMuted;
            badgeBgColor = AppTheme.surface;
            badgeText = schedule.isCompletedToday ? 'SELESAI' : 'BERAKHIR';
            statusIcon = Icons.check_circle_outline;
            break;
        }

        final remMinutes = remaining.inMinutes;
        final remSeconds = remaining.inSeconds % 60;
        final timeCountdownStr = status == SessionState.open
            ? '${remMinutes.toString().padLeft(2, '0')}:${remSeconds.toString().padLeft(2, '0')}'
            : null;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            side: BorderSide(
              color: status == SessionState.open
                  ? AppTheme.primary
                  : AppTheme.border,
              width: status == SessionState.open ? 1.5 : 1,
            ),
          ),
          color: AppTheme.surface,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space8,
                          vertical: AppTheme.space4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusBadge,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 14, color: badgeColor),
                            const SizedBox(width: 4),
                            Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: badgeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (timeCountdownStr != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space8,
                            vertical: AppTheme.space4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.errorSurface,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusBadge,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                size: 13,
                                color: AppTheme.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$timeCountdownStr tersisa',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space12),
                  Text(
                    schedule.subjectName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.meeting_room_outlined,
                        size: 15,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        schedule.className,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.schedule,
                        size: 15,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        PeriodHelper.formatPeriodRange(
                          schedule.dayOfWeek,
                          schedule.periodStart,
                          schedule.periodEnd,
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space16),
                  ElevatedButton.icon(
                    onPressed: onTap,
                    icon: Icon(
                      status == SessionState.open
                          ? Icons.edit_calendar
                          : Icons.visibility,
                      size: 16,
                    ),
                    label: Text(
                      status == SessionState.open
                          ? 'Buka Presensi Sesi Ini'
                          : (status == SessionState.locked
                                ? 'Lihat Detail Sesi'
                                : 'Lihat Hasil Presensi'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status == SessionState.open
                          ? AppTheme.primary
                          : AppTheme.surface,
                      foregroundColor: status == SessionState.open
                          ? Colors.white
                          : AppTheme.primary,
                      side: status == SessionState.open
                          ? null
                          : const BorderSide(color: AppTheme.primary),
                      minimumSize: const Size.fromHeight(40),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusButton,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
