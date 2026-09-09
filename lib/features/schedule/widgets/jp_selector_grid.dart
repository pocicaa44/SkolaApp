import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../core/utils/period_helper.dart';

class JpSelectorGrid extends StatelessWidget {
  final int dayOfWeek;
  final int selectedStart;
  final int selectedEnd;
  final Set<int> occupiedPeriods;
  final int maxPeriods;
  final void Function(int start, int end) onRangeSelected;

  const JpSelectorGrid({
    super.key,
    required this.dayOfWeek,
    required this.selectedStart,
    required this.selectedEnd,
    required this.occupiedPeriods,
    this.maxPeriods = 10,
    required this.onRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pilih Jam Pelajaran (JP)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Terpilih: JP $selectedStart - $selectedEnd',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: maxPeriods,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, index) {
            final period = index + 1;
            final isOccupied = occupiedPeriods.contains(period);
            final isSelected =
                !isOccupied && period >= selectedStart && period <= selectedEnd;
            final sTime = PeriodHelper.getPeriodStartTime(dayOfWeek, period);

            Color bg;
            Color textCol;
            BorderSide border;

            if (isOccupied) {
              bg = AppTheme.background;
              textCol = AppTheme.textMuted;
              border = const BorderSide(color: AppTheme.border);
            } else if (isSelected) {
              bg = AppTheme.primary;
              textCol = Colors.white;
              border = const BorderSide(color: AppTheme.primary);
            } else {
              bg = AppTheme.surface;
              textCol = AppTheme.textPrimary;
              border = const BorderSide(color: AppTheme.border);
            }

            return InkWell(
              onTap: isOccupied
                  ? null
                  : () {
                      if (period < selectedStart || period > selectedEnd) {
                        onRangeSelected(period, period);
                      } else {
                        onRangeSelected(selectedStart, period);
                      }
                    },
              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                  border: Border.fromBorderSide(border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isOccupied)
                      const Icon(
                        Icons.lock_outline,
                        size: 12,
                        color: AppTheme.textMuted,
                      ),
                    Text(
                      'JP $period',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textCol,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOccupied ? 'Terisi' : sTime,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.9)
                            : (isOccupied
                                  ? AppTheme.textMuted
                                  : AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
