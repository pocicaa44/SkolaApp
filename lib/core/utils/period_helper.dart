class PeriodHelper {
  // Default durations per day in minutes (Senin s/d Jumat)
  static Map<int, int> periodDurations = {
    1: 45, // Senin
    2: 30, // Selasa
    3: 30, // Rabu
    4: 30, // Kamis
    5: 40, // Jumat
  };

  static String formatPeriodRange(
    int dayOfWeek,
    int periodStart,
    int periodEnd,
  ) {
    final startTime = getPeriodStartTime(dayOfWeek, periodStart);
    final endTime = getPeriodEndTime(dayOfWeek, periodEnd);
    return 'JP $periodStart-$periodEnd ($startTime - $endTime)';
  }

  static String getPeriodStartTime(
    int dayOfWeek,
    int periodNumber, {
    int? customDurationMinutes,
  }) {
    final duration = customDurationMinutes ?? periodDurations[dayOfWeek] ?? 45;
    int totalMinutes = 7 * 60 + ((periodNumber - 1) * duration);
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  static String getPeriodEndTime(
    int dayOfWeek,
    int periodNumber, {
    int? customDurationMinutes,
  }) {
    final duration = customDurationMinutes ?? periodDurations[dayOfWeek] ?? 45;
    int totalMinutes = 7 * 60 + (periodNumber * duration);
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  static Map<String, String> calculateTimes({
    required int dayOfWeek,
    required int startPeriod,
    required int endPeriod,
    int? customDurationMinutes,
  }) {
    final startTime = getPeriodStartTime(
      dayOfWeek,
      startPeriod,
      customDurationMinutes: customDurationMinutes,
    );
    final endTime = getPeriodEndTime(
      dayOfWeek,
      endPeriod,
      customDurationMinutes: customDurationMinutes,
    );
    final duration = customDurationMinutes ?? periodDurations[dayOfWeek] ?? 45;
    final totalDuration = (endPeriod - startPeriod + 1) * duration;

    return {
      'startTime': startTime,
      'endTime': endTime,
      'totalDuration': totalDuration.toString(),
    };
  }

  static String getDayName(int day) {
    switch (day) {
      case 1:
        return 'Senin';
      case 2:
        return 'Selasa';
      case 3:
        return 'Rabu';
      case 4:
        return 'Kamis';
      case 5:
        return 'Jumat';
      case 6:
        return 'Sabtu';
      case 7:
        return 'Minggu';
      default:
        return '';
    }
  }

  static String formatDateIndonesian(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${getDayName(date.weekday)}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Backward-compatibility alias
typedef SchoolPeriodHelper = PeriodHelper;
