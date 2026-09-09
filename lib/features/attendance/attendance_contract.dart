import '../../core/base/base_view.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/journal_model.dart';
import '../../data/models/schedule_model.dart';
import '../../data/models/student_model.dart';

abstract class AttendanceViewContract extends BaseView {
  void showSaving();
  void hideSaving();
  void updateSessionData({
    required ScheduleModel activeSchedule,
    required List<ScheduleModel> availableSchedules,
    required List<StudentModel> students,
    required Map<String, AttendanceStatus> attendanceMap,
    required JournalModel? journal,
    required bool isLocked,
  });
  void updateStudentStatus(String studentId, AttendanceStatus status);
  void onAttendanceSaved();
  void showIncompleteWarning(int unfilledCount);
}

abstract class AttendancePresenterContract {
  Future<void> loadSessionData({ScheduleModel? schedule});
  void setStudentStatus(String studentId, AttendanceStatus status);
  void markAllPresent();
  Future<void> saveAttendance({String? journalMaterial, String? journalNotes});
  Future<void> saveJournal({required String material, String? notes});
}
