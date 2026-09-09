import '../../core/base/base_presenter.dart';
import '../../core/utils/session_manager.dart';
import '../../data/models/subject_model.dart';
import '../../data/models/teacher_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/master_data_repository.dart';
import '../../data/repositories/profile_repository.dart';
import 'profile_contract.dart';

class ProfilePresenter extends BasePresenter<ProfileViewContract>
    implements ProfilePresenterContract {
  final ProfileRepository _profileRepo;
  final MasterDataRepository _masterDataRepo;
  final AuthRepository _authRepo;

  TeacherModel? _teacher;
  List<SubjectModel> _allSubjects = [];
  final List<String> _selectedSubjectIds = [];

  ProfilePresenter({
    ProfileRepository? profileRepo,
    MasterDataRepository? masterDataRepo,
    AuthRepository? authRepo,
  }) : _profileRepo = profileRepo ?? ProfileRepository(),
       _masterDataRepo = masterDataRepo ?? MasterDataRepository(),
       _authRepo = authRepo ?? AuthRepository();

  @override
  Future<void> loadProfile() async {
    if (!isViewAttached) return;
    view?.showLoading();

    try {
      final user = _authRepo.currentUser;
      if (user == null) {
        view?.onLoggedOut();
        return;
      }

      // Parallel fetching subjects and teacher profile
      final results = await Future.wait([
        _masterDataRepo.getSubjects(),
        _profileRepo.getTeacherByProfileId(user.id, email: user.email ?? '-'),
      ]);

      _allSubjects = results[0] as List<SubjectModel>;
      final teacherRes = results[1] as TeacherModel?;

      _teacher =
          teacherRes ??
          TeacherModel(
            id: '',
            profileId: user.id,
            teacherCode: 'GUR-BARU',
            name: user.userMetadata?['full_name'] as String? ?? 'Guru Baru',
            email: user.email ?? '-',
            status: 'ACTIVE',
            subjectIds: const [],
          );

      _selectedSubjectIds.clear();
      _selectedSubjectIds.addAll(_teacher!.subjectIds);

      if (isViewAttached) {
        view?.updateProfileData(
          teacher: _teacher!,
          allSubjects: _allSubjects,
          selectedSubjectIds: List.unmodifiable(_selectedSubjectIds),
        );
      }
    } catch (e) {
      if (isViewAttached) {
        view?.showError('Gagal memuat profil: ${e.toString()}');
      }
    } finally {
      if (isViewAttached) {
        view?.hideLoading();
      }
    }
  }

  @override
  void toggleSubject(String subjectId) {
    if (_selectedSubjectIds.contains(subjectId)) {
      _selectedSubjectIds.remove(subjectId);
    } else {
      if (_selectedSubjectIds.length >= 2) {
        view?.showError('Maksimal hanya dapat memilih 2 mata pelajaran.');
        return;
      }
      _selectedSubjectIds.add(subjectId);
    }

    if (isViewAttached && _teacher != null) {
      view?.updateProfileData(
        teacher: _teacher!,
        allSubjects: _allSubjects,
        selectedSubjectIds: List.unmodifiable(_selectedSubjectIds),
      );
    }
  }

  @override
  void setSelectedSubjects(List<String> subjectIds) {
    if (subjectIds.length > 2) {
      view?.showError('Maksimal hanya dapat memilih 2 mata pelajaran.');
      return;
    }
    _selectedSubjectIds.clear();
    _selectedSubjectIds.addAll(subjectIds);

    if (isViewAttached && _teacher != null) {
      view?.updateProfileData(
        teacher: _teacher!,
        allSubjects: _allSubjects,
        selectedSubjectIds: List.unmodifiable(_selectedSubjectIds),
      );
    }
  }

  @override
  Future<void> saveProfile(String name) async {
    if (name.trim().isEmpty) {
      view?.showError('Nama lengkap tidak boleh kosong');
      return;
    }
    if (_selectedSubjectIds.isEmpty) {
      view?.showError('Pilih minimal 1 mata pelajaran yang diampu');
      return;
    }
    if (_selectedSubjectIds.length > 2) {
      view?.showError('Maksimal hanya dapat memilih 2 mata pelajaran.');
      return;
    }

    final user = _authRepo.currentUser;
    if (user == null) {
      view?.onLoggedOut();
      return;
    }

    if (!isViewAttached) return;
    view?.showSaving();

    try {
      await _profileRepo.updateProfile(
        profileId: user.id,
        name: name.trim(),
        subjectIds: _selectedSubjectIds,
      );

      if (isViewAttached) {
        view?.showSuccess('Profil berhasil disimpan');
        view?.onProfileSaved();
      }
    } catch (e) {
      if (isViewAttached) {
        view?.showError('Gagal menyimpan profil: ${e.toString()}');
      }
    } finally {
      if (isViewAttached) {
        view?.hideSaving();
      }
    }
  }

  @override
  Future<void> logout() async {
    if (!isViewAttached) return;
    view?.showLoggingOut();

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
        view?.hideLoggingOut();
      }
    }
  }
}
