import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/base/base_presenter.dart';
import '../../core/utils/session_manager.dart';
import '../../data/models/schedule_model.dart';
import '../../data/models/teacher_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/master_data_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/schedule_repository.dart';
import 'dashboard_contract.dart';

class DashboardPresenter extends BasePresenter<DashboardViewContract>
    implements DashboardPresenterContract {
  final AuthRepository _authRepo;
  final ProfileRepository _profileRepo;
  final ScheduleRepository _scheduleRepo;
  final MasterDataRepository _masterDataRepo;

  TeacherModel? _teacher;
  List<ScheduleModel> _todaySchedules = [];

  DashboardPresenter({
    AuthRepository? authRepo,
    ProfileRepository? profileRepo,
    ScheduleRepository? scheduleRepo,
    MasterDataRepository? masterDataRepo,
  }) : _authRepo = authRepo ?? AuthRepository(),
       _profileRepo = profileRepo ?? ProfileRepository(),
       _scheduleRepo = scheduleRepo ?? ScheduleRepository(),
       _masterDataRepo = masterDataRepo ?? MasterDataRepository();

  @override
  Future<void> loadDashboardData() async {
    if (!isViewAttached) return;
    view?.showLoading();

    try {
      final user = _authRepo.currentUser;
      if (user == null) {
        view?.onLoggedOut();
        return;
      }

      // Parallel execution: lesson period configs & teacher profile
      final initResults = await Future.wait([
        _masterDataRepo.getLessonPeriodConfigs(),
        _profileRepo.getTeacherByProfileId(user.id, email: user.email ?? '-'),
      ]);

      final teacherRes = initResults[1] as TeacherModel?;

      _teacher =
          teacherRes ??
          TeacherModel(
            id: '',
            profileId: user.id,
            teacherCode: 'GUR',
            name: user.userMetadata?['full_name'] as String? ?? 'Guru',
            email: user.email ?? '-',
            status: 'ACTIVE',
            subjectIds: const [],
          );

      // Check account status
      if (_teacher!.isDeleted) {
        await _authRepo.signOut();
        if (isViewAttached) {
          view?.onLoggedOut();
        }
        return;
      }

      final weekday = DateTime.now().weekday;
      List<ScheduleModel> rawSchedules = [];

      if (_teacher!.id.isNotEmpty) {
        rawSchedules = await _scheduleRepo.getTodaySchedules(
          _teacher!.id,
          weekday,
        );
      }

      // Calculate attendance completion & student count for each schedule
      final todayStr =
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
      final supabase = Supabase.instance.client;

      final List<ScheduleModel> enrichedSchedules = [];

      for (var s in rawSchedules) {
        bool isCompleted = false;
        int count = 0;
        try {
          final attCheck = await supabase
              .from('attendance')
              .select('id')
              .eq('schedule_id', s.id)
              .eq('attendance_date', todayStr)
              .limit(1);
          isCompleted = (attCheck as List).isNotEmpty;

          final studentsData = await supabase
              .from('students')
              .select('id')
              .eq('class_id', s.classId);
          count = (studentsData as List).length;
        } catch (_) {}

        enrichedSchedules.add(
          s.copyWith(studentCount: count, isCompletedToday: isCompleted),
        );
      }

      _todaySchedules = enrichedSchedules;

      if (isViewAttached) {
        view?.updateDashboardData(
          teacher: _teacher!,
          todaySchedules: List.unmodifiable(_todaySchedules),
        );
      }
    } catch (e) {
      if (isViewAttached) {
        view?.showError('Gagal memuat data dasbor: ${e.toString()}');
      }
    } finally {
      if (isViewAttached) {
        view?.hideLoading();
      }
    }
  }

  @override
  Future<void> refreshData() async {
    await loadDashboardData();
  }

  @override
  void onScheduleSelected(ScheduleModel schedule) {
    view?.navigateToAttendance(schedule);
  }

  @override
  void onActiveSessionTapped(ScheduleModel schedule) {
    final status = schedule.getStatus(DateTime.now());
    if (status == SessionState.locked) {
      view?.showError(
        'Sesi pembelajaran belum dimulai. Waktu mulai: ${schedule.startTime}',
      );
      return;
    }
    view?.navigateToAttendance(schedule);
  }

  @override
  Future<void> logout() async {
    if (!isViewAttached) return;
    view?.showLoading();
    try {
      await _authRepo.signOut();
      await SessionManager.instance.clearSession();
      if (isViewAttached) {
        view?.onLoggedOut();
      }
    } catch (e) {
      if (isViewAttached) {
        view?.showError('Gagal keluar: ${e.toString()}');
      }
    } finally {
      if (isViewAttached) {
        view?.hideLoading();
      }
    }
  }
}
