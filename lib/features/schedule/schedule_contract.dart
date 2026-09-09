import '../../core/base/base_view.dart';
import '../../data/models/class_model.dart';
import '../../data/models/schedule_model.dart';
import '../../data/models/subject_model.dart';
import '../../data/repositories/schedule_repository.dart';

abstract class ScheduleViewContract extends BaseView {
  void updateScheduleList(List<ScheduleModel> schedules);
  void onScheduleDeleted();
}

abstract class ScheduleFormViewContract extends BaseView {
  void showSaving();
  void hideSaving();
  void updateFormData({
    required List<ClassModel> classes,
    required List<SubjectModel> subjects,
  });
  void updateOccupiedPeriods(OccupiedPeriodsResult occupiedResult);
  void onScheduleSaved();
}

abstract class SchedulePresenterContract {
  Future<void> loadTeacherSchedules();
  Future<void> deleteSchedule(String scheduleId);
  Future<void> loadFormData();
  Future<void> computeOccupiedPeriods({
    required String classId,
    required int dayOfWeek,
    String? excludeScheduleId,
  });
  Future<void> saveSchedule({
    String? id,
    required String classId,
    required String subjectId,
    required int dayOfWeek,
    required int periodStart,
    required int periodEnd,
    String? room,
  });
}
