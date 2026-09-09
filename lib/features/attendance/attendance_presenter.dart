import '../../core/base/base_presenter.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/journal_model.dart';
import '../../data/models/schedule_model.dart';
import '../../data/models/student_model.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/journal_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/schedule_repository.dart';
import 'attendance_contract.dart';

class AttendancePresenter extends BasePresenter<AttendanceViewContract>
    implements AttendancePresenterContract {
  final AttendanceRepository _attendanceRepo;
  final JournalRepository _journalRepo;
  final ScheduleRepository _scheduleRepo;
  final ProfileRepository _profileRepo;
  final AuthRepository _authRepo;

  ScheduleModel? _activeSchedule;
  List<ScheduleModel> _availableSchedules = [];
  List<StudentModel> _students = [];
  final Map<String, AttendanceStatus> _attendanceMap = {};
  JournalModel? _journal;

  AttendancePresenter({
    AttendanceRepository? attendanceRepo,
    JournalRepository? journalRepo,
    ScheduleRepository? scheduleRepo,
    ProfileRepository? profileRepo,
    AuthRepository? authRepo,
  }) : _attendanceRepo = attendanceRepo ?? AttendanceRepository(),
       _journalRepo = journalRepo ?? JournalRepository(),
       _scheduleRepo = scheduleRepo ?? ScheduleRepository(),
       _profileRepo = profileRepo ?? ProfileRepository(),
       _authRepo = authRepo ?? AuthRepository();

  @override
  Future<void> loadSessionData({ScheduleModel? schedule}) async {
    if (!isViewAttached) return;
    view?.showLoading();

    try {
      final user = _authRepo.currentUser;
      if (user == null) return;

      final teacher = await _profileRepo.getTeacherByProfileId(user.id);
      if (teacher == null) {
        if (isViewAttached) {
          view?.showError('Data guru belum lengkap.');
        }
        return;
      }

      final weekday = DateTime.now().weekday;
      _availableSchedules = await _scheduleRepo.getTodaySchedules(
        teacher.id,
        weekday,
      );

      if (schedule != null) {
        _activeSchedule = schedule;
      } else if (_availableSchedules.isNotEmpty) {
        // Auto-select session yang sedang OPEN atau LOCKED pertama
        _activeSchedule = _availableSchedules.firstWhere(
          (s) => s.getStatus(DateTime.now()) == SessionState.open,
          orElse: () => _availableSchedules.first,
        );
      }

      if (_activeSchedule == null) {
        if (isViewAttached) {
          view?.updateSessionData(
            activeSchedule: const ScheduleModel(
              id: '',
              teacherId: '',
              classId: '',
              className: 'Belum Ada Jadwal',
              subjectId: '',
              subjectName: 'Tidak ada sesi hari ini',
              dayOfWeek: 1,
              periodStart: 1,
              periodEnd: 1,
              startTime: '00:00',
              endTime: '00:00',
            ),
            availableSchedules: [],
            students: [],
            attendanceMap: {},
            journal: null,
            isLocked: true,
          );
        }
        return;
      }

      // Fetch students, existing attendance, and journal in parallel
      final now = DateTime.now();
      final results = await Future.wait([
        _attendanceRepo.getStudentsByClass(_activeSchedule!.classId),
        _attendanceRepo.getAttendanceForSession(
          scheduleId: _activeSchedule!.id,
          date: now,
        ),
        _journalRepo.getJournalForSession(
          scheduleId: _activeSchedule!.id,
          date: now,
        ),
      ]);

      _students = results[0] as List<StudentModel>;
      final existingAttendance = results[1] as Map<String, AttendanceStatus>;
      _journal = results[2] as JournalModel?;

      _attendanceMap.clear();
      _attendanceMap.addAll(existingAttendance);

      final status = _activeSchedule!.getStatus(now);
      final isLocked =
          status == SessionState.locked || status == SessionState.closed;

      if (isViewAttached) {
        view?.updateSessionData(
          activeSchedule: _activeSchedule!,
          availableSchedules: List.unmodifiable(_availableSchedules),
          students: List.unmodifiable(_students),
          attendanceMap: Map.unmodifiable(_attendanceMap),
          journal: _journal,
          isLocked: isLocked,
        );
      }
    } catch (e) {
      if (isViewAttached) {
        view?.showError('Gagal memuat data presensi: ${e.toString()}');
      }
    } finally {
      if (isViewAttached) {
        view?.hideLoading();
      }
    }
  }

  @override
  void setStudentStatus(String studentId, AttendanceStatus status) {
    _attendanceMap[studentId] = status;
    if (isViewAttached) {
      view?.updateStudentStatus(studentId, status);
    }
  }

  @override
  void markAllPresent() {
    for (var s in _students) {
      _attendanceMap[s.id] = AttendanceStatus.present;
      if (isViewAttached) {
        view?.updateStudentStatus(s.id, AttendanceStatus.present);
      }
    }
  }

  @override
  Future<void> saveAttendance({
    String? journalMaterial,
    String? journalNotes,
  }) async {
    if (_activeSchedule == null) return;

    // Validate that all students have an attendance status
    int unfilledCount = 0;
    for (var s in _students) {
      if (!_attendanceMap.containsKey(s.id)) {
        unfilledCount++;
      }
    }

    if (unfilledCount > 0) {
      if (isViewAttached) {
        view?.showIncompleteWarning(unfilledCount);
      }
      return;
    }

    if (!isViewAttached) return;
    view?.showSaving();

    try {
      final now = DateTime.now();

      // Parallel batch save for attendance and optional journal
      final List<Future> saveTasks = [
        _attendanceRepo.saveBulkAttendance(
          scheduleId: _activeSchedule!.id,
          classId: _activeSchedule!.classId,
          date: now,
          attendanceMap: _attendanceMap,
        ),
      ];

      if (journalMaterial != null && journalMaterial.trim().isNotEmpty) {
        saveTasks.add(
          _journalRepo.saveJournal(
            scheduleId: _activeSchedule!.id,
            classId: _activeSchedule!.classId,
            subjectId: _activeSchedule!.subjectId,
            date: now,
            teachingMaterial: journalMaterial.trim(),
            notes: journalNotes?.trim(),
          ),
        );
      }

      await Future.wait(saveTasks);

      if (isViewAttached) {
        view?.showSuccess('Presensi sesi pembelajaran berhasil disimpan!');
        view?.onAttendanceSaved();
      }
    } catch (e) {
      if (isViewAttached) {
        view?.showError('Gagal menyimpan presensi: ${e.toString()}');
      }
    } finally {
      if (isViewAttached) {
        view?.hideSaving();
      }
    }
  }

  @override
  Future<void> saveJournal({required String material, String? notes}) async {
    if (_activeSchedule == null || material.trim().isEmpty) return;

    if (!isViewAttached) return;
    view?.showSaving();

    try {
      await _journalRepo.saveJournal(
        scheduleId: _activeSchedule!.id,
        classId: _activeSchedule!.classId,
        subjectId: _activeSchedule!.subjectId,
        date: DateTime.now(),
        teachingMaterial: material.trim(),
        notes: notes?.trim(),
      );

      _journal = JournalModel(
        sessionId: _activeSchedule!.id,
        teachingMaterial: material.trim(),
        notes: notes?.trim(),
        createdAt: DateTime.now(),
      );

      if (isViewAttached) {
        view?.showSuccess('Jurnal pembelajaran berhasil disimpan');
      }
    } catch (e) {
      if (isViewAttached) {
        view?.showError('Gagal menyimpan jurnal: ${e.toString()}');
      }
    } finally {
      if (isViewAttached) {
        view?.hideSaving();
      }
    }
  }
}
