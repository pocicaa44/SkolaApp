import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/student_model.dart';

class StudentAttendanceTile extends StatelessWidget {
  final int index;
  final StudentModel student;
  final AttendanceStatus? status;
  final bool isLocked;
  final void Function(AttendanceStatus status) onStatusChanged;

  const StudentAttendanceTile({
    super.key,
    required this.index,
    required this.student,
    required this.status,
    required this.isLocked,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppTheme.space8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: BorderSide(
          color: status != null
              ? status!.color.withValues(alpha: 0.4)
              : AppTheme.border,
          width: status != null ? 1.2 : 1,
        ),
      ),
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space12,
          vertical: AppTheme.space8,
        ),
        child: Row(
          children: [
            // Nomor Urut
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
              ),
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.space10),

            // Nama & NIS Siswa
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${student.studentCode} • ${student.gender == "L" ? "Laki-laki" : "Perempuan"}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.space8),

            // Tombol Pilihan Status (H, I, S, A)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: AttendanceStatus.values.map((s) {
                final isSelected = status == s;

                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: InkWell(
                    onTap: isLocked ? null : () => onStatusChanged(s),
                    borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                    child: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? s.color : s.surfaceColor,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusButton,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? s.color
                              : s.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        s.shortCode,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : s.color,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
