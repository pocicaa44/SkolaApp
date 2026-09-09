import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../data/repositories/schedule_repository.dart';

class OccupiedPeriodBadge extends StatelessWidget {
  final List<OccupiedSlotInfo> occupiedSlots;

  const OccupiedPeriodBadge({super.key, required this.occupiedSlots});

  @override
  Widget build(BuildContext context) {
    if (occupiedSlots.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space16),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, size: 16, color: AppTheme.warning),
              SizedBox(width: 6),
              Text(
                'Jam Pelajaran Terisi pada Hari & Kelas Ini:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: occupiedSlots.map((slot) {
              final isOwn = slot.isTeacherOwn;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOwn ? AppTheme.primaryLight : AppTheme.errorSurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
                  border: Border.all(
                    color: isOwn ? AppTheme.primary : AppTheme.error,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  'JP ${slot.start}-${slot.end}: ${slot.label}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isOwn ? AppTheme.primary : AppTheme.error,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
