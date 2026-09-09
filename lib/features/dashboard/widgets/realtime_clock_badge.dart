import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../core/widgets/realtime_ticker_builder.dart';

class RealtimeClockBadge extends StatelessWidget {
  const RealtimeClockBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return RealtimeTickerBuilder(
      builder: (context, now) {
        final hours = now.hour.toString().padLeft(2, '0');
        final minutes = now.minute.toString().padLeft(2, '0');
        final seconds = now.second.toString().padLeft(2, '0');

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space10,
            vertical: AppTheme.space6,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time, size: 14, color: AppTheme.primary),
              const SizedBox(width: 4),
              Text(
                '$hours:$minutes:$seconds WIB',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
