import '../../core/base/base_presenter.dart';
import '../../core/base/base_view.dart';
import '../../data/models/class_model.dart';
import '../../data/models/subject_model.dart';
import '../../data/models/teacher_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/master_data_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/schedule_repository.dart';
import 'schedule_contract.dart';

class SchedulePresenter extends BasePresenter<BaseView>
    implements SchedulePresenterContract {
  final ScheduleRepository _scheduleRepo;
  final MasterDataRepository _masterDataRepo;
  final ProfileRepository _profileRepo;
  final AuthRepository _authRepo;

  String? _teacherId;

  SchedulePresenter({
    ScheduleRepository? scheduleRepo,
    MasterDataRepository? masterDataRepo,
    ProfileRepository? profileRepo,
    AuthRepository? authRepo,
  }) : _scheduleRepo = scheduleRepo ?? ScheduleRepository(),
       _masterDataRepo = masterDataRepo ?? MasterDataRepository(),
       _profileRepo = profileRepo ?? ProfileRepository(),
       _authRepo = authRepo ?? AuthRepository();

  Future<String?> _resolveTeacherId() async {
    if (_teacherId != null && _teacherId!.isNotEmpty) return _teacherId;
    final user = _authRepo.currentUser;
    if (user == null) return null;
    final teacher = await _profileRepo.getTeacherByProfileId(user.id);
    _teacherId = teacher?.id;
    return _teacherId;
  }

  @override
  Future<void> loadTeacherSchedules() async {
    if (!isViewAttached) return;
    view?.showLoading();

    try {
      final tId = await _resolveTeacherId();
      if (tId == null) {
        if (isViewAttached) {
          view?.showError(
            'Data guru tidak ditemukan. Lengkapi profil terlebih dahulu.',
          );
        }
        return;
      }

      final schedules = await _scheduleRepo.getTeacherSchedules(tId);
      if (isViewAttached && view is ScheduleViewContract) {
        (view as ScheduleViewContract).updateScheduleList(schedules);
      }
    } catch (e) {
      if (isViewAttached) {
        view?.showError('Gagal memuat jadwal: ${e.toString()}');
      }
    } finally {
      if (isViewAttached) {
        view?.hideLoading();
      }
    }
  }

  @override
  Future<void> deleteSchedule(String scheduleId) async {
    if (!isViewAttached) return;
    view?.showLoading();

    try {
      await _scheduleRepo.deleteSchedule(scheduleId);
      if (isViewAttached) {
        view?.showSuccess('Jadwal berhasil dihapus');
        if (view is ScheduleViewContract) {
          (view as ScheduleViewContract).onScheduleDeleted();
        }
      }
    } catch (e) {
      if (isViewAttached) {
        view?.showError('Gagal menghapus jadwal: ${e.toString()}');
      }
    } finally {
      if (isViewAttached) {
        view?.hideLoading();
      }
    }
  }

  @override
  Future<void> loadFormData() async {
    if (!isViewAttached) return;
    view?.showLoading();

    try {
      final user = _authRepo.currentUser;
      if (user == null) return;

      final results = await Future.wait([
        _masterDataRepo.getClasses(),
        _masterDataRepo.getSubjects(),
        _profileRepo.getTeacherByProfileId(user.id),
        _masterDataRepo.getLessonPeriodConfigs(),
      ]);

      final allClasses = results[0] as List<ClassModel>;
      final allSubjects = results[1] as List<SubjectModel>;
      final teacher = results[2] as TeacherModel?;

      _teacherId = teacher?.id;

      // Filter subjects according to teacher's assigned subjects if specified
      List<SubjectModel> teacherSubjects = allSubjects;
      if (teacher != null && teacher.subjectIds.isNotEmpty) {
        teacherSubjects = allSubjects
            .where((s) => teacher.subjectIds.contains(s.id))
            .toList();
        if (teacherSubjects.isEmpty) teacherSubjects = allSubjects;
      }

      if (isViewAttached && view is ScheduleFormViewContract) {
        (view as ScheduleFormViewContract).updateFormData(
          classes: allClasses,
          subjects: teacherSubjects,
        );
      }
    } catch (e) {
      if (isViewAttached) {
        view?.showError('Gagal memuat data form jadwal: ${e.toString()}');
      }
    } finally {
      if (isViewAttached) {
        view?.hideLoading();
      }
    }
  }

  @override
  Future<void> computeOccupiedPeriods({
    required String classId,
    required int dayOfWeek,
    String? excludeScheduleId,
  }) async {
    final tId = await _resolveTeacherId();
    if (tId == null || classId.isEmpty) return;

    try {
      final result = await _scheduleRepo.computeOccupiedPeriods(
        classId: classId,
        teacherId: tId,
        dayOfWeek: dayOfWeek,
        excludeScheduleId: excludeScheduleId,
      );

      if (isViewAttached && view is ScheduleFormViewContract) {
        (view as ScheduleFormViewContract).updateOccupiedPeriods(result);
      }
    } catch (_) {}
  }

  @override
  Future<void> saveSchedule({
    String? id,
    required String classId,
    required String subjectId,
    required int dayOfWeek,
    required int periodStart,
    required int periodEnd,
    String? room,
  }) async {
    final tId = await _resolveTeacherId();
    if (tId == null) {
      view?.showError('Data guru tidak ditemukan');
      return;
    }

    if (periodStart > periodEnd) {
      view?.showError(
        'Jam pelajaran awal tidak boleh lebih besar dari jam akhir.',
      );
      return;
    }

    if (!isViewAttached) return;
    if (view is ScheduleFormViewContract) {
      (view as ScheduleFormViewContract).showSaving();
    }

    try {
      // Conflict validation re-check before saving
      final occupiedResult = await _scheduleRepo.computeOccupiedPeriods(
        classId: classId,
        teacherId: tId,
        dayOfWeek: dayOfWeek,
        excludeScheduleId: id,
      );

      for (int p = periodStart; p <= periodEnd; p++) {
        if (occupiedResult.occupiedPeriods.contains(p)) {
          final conflictSlot = occupiedResult.occupiedSlotsInfo.firstWhere(
            (slot) => p >= slot.start && p <= slot.end,
            orElse: () => const OccupiedSlotInfo(
              start: 1,
              end: 1,
              subject: 'Pelajaran lain',
              label: 'Slot terisi',
              isTeacherOwn: false,
            ),
          );

          if (isViewAttached) {
            view?.showError(
              'Bentrok Jadwal: JP $p sudah digunakan untuk ${conflictSlot.label}. Silakan pilih JP lain.',
            );
            if (view is ScheduleFormViewContract) {
              (view as ScheduleFormViewContract).hideSaving();
            }
          }
          return;
        }
      }

      await _scheduleRepo.saveSchedule(
        id: id,
        teacherId: tId,
        classId: classId,
        subjectId: subjectId,
        dayOfWeek: dayOfWeek,
        periodStart: periodStart,
        periodEnd: periodEnd,
        room: room,
      );

      if (isViewAttached) {
        view?.showSuccess(
          id != null ? 'Jadwal berhasil diperbarui' : 'Jadwal berhasil dibuat',
        );
        if (view is ScheduleFormViewContract) {
          (view as ScheduleFormViewContract).onScheduleSaved();
        }
      }
    } catch (e) {
      if (isViewAttached) {
        view?.showError('Gagal menyimpan jadwal: ${e.toString()}');
      }
    } finally {
      if (isViewAttached && view is ScheduleFormViewContract) {
        (view as ScheduleFormViewContract).hideSaving();
      }
    }
  }
}
