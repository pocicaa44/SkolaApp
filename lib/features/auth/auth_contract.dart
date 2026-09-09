import '../../core/base/base_view.dart';

abstract class AuthViewContract extends BaseView {
  void showGoogleLoading();
  void hideGoogleLoading();
  void onAuthSuccess(String message);
  void navigateToDashboard();
  void navigateToRegister();
  void navigateToLogin();
  void navigateToForgotPassword();
}

abstract class AuthPresenterContract {
  Future<void> loginWithEmail(String email, String password);
  Future<void> registerWithEmail(
    String fullName,
    String email,
    String password,
  );
  Future<void> loginWithGoogle();
}
