class LessonPeriodModel {
  final int dayOfWeek;
  final int periodDurationMinutes;

  const LessonPeriodModel({
    required this.dayOfWeek,
    required this.periodDurationMinutes,
  });

  factory LessonPeriodModel.fromJson(Map<String, dynamic> json) {
    return LessonPeriodModel(
      dayOfWeek: json['day_of_week'] as int? ?? 1,
      periodDurationMinutes: json['period_duration_minutes'] as int? ?? 45,
    );
  }
}
