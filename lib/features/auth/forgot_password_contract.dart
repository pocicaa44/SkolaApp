import '../../core/base/base_view.dart';

/// State pemulihan kata sandi Native Supabase Recovery
enum ForgotPasswordState {
  initial,
  sendingRecoveryEmail,
  recoveryEmailSent,
  updatingPassword,
  passwordUpdated,
  error,
}

// --- Kontrak untuk Halaman Forgot Password ---
abstract class ForgotPasswordViewContract extends BaseView {
  void onRecoveryEmailSent(String email);
}

abstract class ForgotPasswordPresenterContract {
  Future<void> sendRecoveryEmail(String email);
}

// --- Kontrak untuk Halaman Reset Password ---
abstract class ResetPasswordViewContract extends BaseView {
  void onPasswordResetSuccess(String message);
  void navigateToLogin([String? message]);
}

abstract class ResetPasswordPresenterContract {
  Future<void> resetPassword({
    required String newPassword,
    required String confirmPassword,
  });
}

// --- Kontrak untuk Halaman Verifikasi OTP ---
abstract class VerifyOtpViewContract extends BaseView {
  void onOtpVerified();
  void onOtpResent();
  void updateResendCountdown(int secondsRemaining);
}

abstract class VerifyOtpPresenterContract {
  Future<void> verifyOtp({
    required String email,
    required String otp,
  });
  Future<void> resendOtp(String email);
  void startResendTimer();
  void disposeTimer();
}
