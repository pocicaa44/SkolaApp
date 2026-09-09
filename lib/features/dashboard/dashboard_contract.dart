import '../../core/base/base_view.dart';
import '../../data/models/schedule_model.dart';
import '../../data/models/teacher_model.dart';

abstract class DashboardViewContract extends BaseView {
  void updateDashboardData({
    required TeacherModel teacher,
    required List<ScheduleModel> todaySchedules,
  });
  void navigateToSchedule();
  void navigateToAttendance(ScheduleModel schedule);
  void navigateToProfile();
  void onLoggedOut();
}

abstract class DashboardPresenterContract {
  Future<void> loadDashboardData();
  Future<void> refreshData();
  void onScheduleSelected(ScheduleModel schedule);
  void onActiveSessionTapped(ScheduleModel schedule);
  Future<void> logout();
}
