import '../../core/base/base_view.dart';

abstract class SplashViewContract extends BaseView {
  void navigateToDashboard();
  void navigateToLogin({String? errorMessage});
  void navigateToResetPassword({required String email});
}

abstract class SplashPresenterContract {
  Future<void> checkInitialSession();
}
