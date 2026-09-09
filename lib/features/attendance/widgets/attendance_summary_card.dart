import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../data/models/attendance_model.dart';

class AttendanceSummaryCard extends StatelessWidget {
  final Map<String, AttendanceStatus> attendanceMap;
  final int totalStudents;

  const AttendanceSummaryCard({
    super.key,
    required this.attendanceMap,
    required this.totalStudents,
  });

  @override
  Widget build(BuildContext context) {
    int present = 0;
    int permission = 0;
    int sick = 0;
    int absent = 0;

    for (final status in attendanceMap.values) {
      switch (status) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.permission:
          permission++;
          break;
        case AttendanceStatus.sick:
          sick++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
      }
    }

    final filledCount = attendanceMap.length;
    final unFilledCount = totalStudents - filledCount;

    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status Pengisian: $filledCount/$totalStudents Siswa',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (unFilledCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningSurface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
                  ),
                  child: Text(
                    '$unFilledCount Belum diisi',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.warning,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successSurface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
                  ),
                  child: const Text(
                    'Lengkap',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.success,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          Row(
            children: [
              Expanded(
                child: _buildBadge(
                  'Hadir',
                  present,
                  AppTheme.success,
                  AppTheme.successSurface,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildBadge(
                  'Izin',
                  permission,
                  AppTheme.info,
                  AppTheme.infoSurface,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildBadge(
                  'Sakit',
                  sick,
                  AppTheme.warning,
                  AppTheme.warningSurface,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildBadge(
                  'Alpa',
                  absent,
                  AppTheme.error,
                  AppTheme.errorSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, int count, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}
