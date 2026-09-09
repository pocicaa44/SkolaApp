import '../../core/base/base_view.dart';
import '../../data/models/subject_model.dart';
import '../../data/models/teacher_model.dart';

abstract class ProfileViewContract extends BaseView {
  void showSaving();
  void hideSaving();
  void showLoggingOut();
  void hideLoggingOut();
  void updateProfileData({
    required TeacherModel teacher,
    required List<SubjectModel> allSubjects,
    required List<String> selectedSubjectIds,
  });
  void onProfileSaved();
  void onLoggedOut();
}

abstract class ProfilePresenterContract {
  Future<void> loadProfile();
  void toggleSubject(String subjectId);
  void setSelectedSubjects(List<String> subjectIds);
  Future<void> saveProfile(String name);
  Future<void> logout();
}
