import 'dart:async';
import 'dart:io' show SocketException;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/base/base_presenter.dart';
import '../../core/utils/session_manager.dart';
import '../../data/repositories/auth_repository.dart';
import 'forgot_password_contract.dart';

/// Presenter untuk halaman Forgot Password (Permintaan Recovery Link Supabase)
class ForgotPasswordPresenter extends BasePresenter<ForgotPasswordViewContract>
    implements ForgotPasswordPresenterContract {
  final AuthRepository _authRepo;

  ForgotPasswordPresenter({AuthRepository? authRepo})
    : _authRepo = authRepo ?? AuthRepository();

  @override
  Future<void> sendRecoveryEmail(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty ||
        !cleanEmail.contains('@') ||
        !cleanEmail.contains('.')) {
      view?.showError('Format email tidak valid. Masukkan email yang benar.');
      return;
    }

    if (!isViewAttached) return;
    view?.showLoading();

    try {
      await _authRepo.resetPasswordForEmail(email: cleanEmail);

      if (isViewAttached) {
        view?.showSuccess(
          'Kode OTP telah dikirimkan ke email Anda. Silakan periksa kotak masuk email Anda.',
        );
        view?.onRecoveryEmailSent(cleanEmail);
      }
    } on AuthException catch (e) {
      if (isViewAttached) {
        final lower = e.message.toLowerCase();
        if (lower.contains('rate limit') ||
            lower.contains('too many requests')) {
          view?.showError(
            'Terlalu banyak permintaan pemulihan. Silakan tunggu beberapa saat sebelum mencoba lagi.',
          );
        } else if (lower.contains('error sending recovery email') ||
            lower.contains('unexpected_failure') ||
            lower.contains('smtp')) {
          view?.showError(
            'Layanan SMTP Supabase gagal mengirim email. Silakan periksa konfigurasi SMTP (Host, Port, User, App Password) dan Sender Email di Supabase Dashboard.',
          );
        } else {
          view?.showError('Gagal mengirimkan kode OTP: ${e.message}');
        }
      }
    } catch (e) {
      if (isViewAttached) {
        if (!kIsWeb && e is SocketException) {
          view?.showError(
            'Gagal terhubung ke server. Periksa koneksi internet lalu coba lagi.',
          );
        } else {
          view?.showError(
            'Terjadi kesalahan saat memproses permintaan: ${e.toString()}',
          );
        }
      }
    } finally {
      if (isViewAttached) {
        view?.hideLoading();
      }
    }
  }
}

/// Presenter untuk halaman Reset Password (Buat Password Baru)
class ResetPasswordPresenter extends BasePresenter<ResetPasswordViewContract>
    implements ResetPasswordPresenterContract {
  final AuthRepository _authRepo;

  ResetPasswordPresenter({AuthRepository? authRepo})
    : _authRepo = authRepo ?? AuthRepository();

  @override
  Future<void> resetPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword.isEmpty) {
      view?.showError('Kata sandi baru wajib diisi.');
      return;
    }

    if (newPassword.length < 8) {
      view?.showError('Kata sandi minimal 8 karakter.');
      return;
    }

    if (confirmPassword.isEmpty) {
      view?.showError('Konfirmasi kata sandi wajib diisi.');
      return;
    }

    if (newPassword != confirmPassword) {
      view?.showError('Konfirmasi kata sandi tidak sama.');
      return;
    }

    // Pastikan ada sesi pemulihan aktif dari Supabase
    if (_authRepo.currentUser == null) {
      view?.showError(
        'Sesi pemulihan telah berakhir. Silakan minta link pemulihan baru.',
      );
      view?.navigateToLogin();
      return;
    }

    if (!isViewAttached) return;
    view?.showLoading();

    try {
      await _authRepo.updateUserPassword(newPassword: newPassword);

      // Bersihkan sesi pemulihan agar user login kembali secara bersih
      await _authRepo.signOut();
      await SessionManager.instance.clearSession();
      SessionManager.instance.isPasswordRecoveryActive = false;

      if (isViewAttached) {
        const successMsg =
            'Password berhasil diperbarui. Silakan login menggunakan password baru Anda.';
        view?.onPasswordResetSuccess(successMsg);
        view?.navigateToLogin(successMsg);
      }
    } on AuthException catch (e) {
      if (isViewAttached) {
        view?.showError('Gagal memperbarui kata sandi: ${e.message}');
      }
    } catch (e) {
      if (isViewAttached) {
        if (!kIsWeb && e is SocketException) {
          view?.showError(
            'Gagal terhubung ke server. Periksa koneksi internet lalu coba lagi.',
          );
        } else {
          view?.showError('Terjadi kesalahan saat memperbarui kata sandi.');
        }
      }
    } finally {
      if (isViewAttached) {
        view?.hideLoading();
      }
    }
  }
}

/// Presenter untuk halaman Verifikasi Kode OTP
class VerifyOtpPresenter extends BasePresenter<VerifyOtpViewContract>
    implements VerifyOtpPresenterContract {
  final AuthRepository _authRepo;
  Timer? _countdownTimer;
  int _secondsRemaining = 0;

  VerifyOtpPresenter({AuthRepository? authRepo})
      : _authRepo = authRepo ?? AuthRepository();

  int get secondsRemaining => _secondsRemaining;

  @override
  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final cleanOtp = otp.trim();
    if (cleanOtp.length != 6 || int.tryParse(cleanOtp) == null) {
      view?.showError('Masukkan 6 digit kode OTP yang valid.');
      return;
    }

    if (!isViewAttached) return;
    view?.showLoading();

    try {
      final response = await _authRepo.verifyRecoveryOtp(
        email: email.trim(),
        token: cleanOtp,
      );

      if (response.session != null ||
          response.user != null ||
          _authRepo.currentUser != null) {
        SessionManager.instance.isPasswordRecoveryActive = true;
        SessionManager.instance.pendingRecoveryEmail = email.trim();

        if (isViewAttached) {
          view?.showSuccess('Kode OTP berhasil diverifikasi.');
          view?.onOtpVerified();
        }
      } else {
        if (isViewAttached) {
          view?.showError('Verifikasi gagal. Sesi tidak ditemukan.');
        }
      }
    } on AuthException catch (e) {
      if (isViewAttached) {
        final lower = e.message.toLowerCase();
        if (lower.contains('expired') || lower.contains('invalid') || lower.contains('token')) {
          view?.showError('Kode OTP salah atau telah kadaluarsa.');
        } else {
          view?.showError('Gagal memverifikasi OTP: ${e.message}');
        }
      }
    } catch (e) {
      if (isViewAttached) {
        if (!kIsWeb && e is SocketException) {
          view?.showError('Gagal terhubung ke server. Periksa koneksi internet.');
        } else {
          view?.showError('Terjadi kesalahan saat memverifikasi OTP.');
        }
      }
    } finally {
      if (isViewAttached) {
        view?.hideLoading();
      }
    }
  }

  @override
  Future<void> resendOtp(String email) async {
    if (_secondsRemaining > 0) return;

    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) {
      view?.showError('Alamat email tidak valid.');
      return;
    }

    if (!isViewAttached) return;
    view?.showLoading();

    try {
      await _authRepo.resetPasswordForEmail(email: cleanEmail);
      startResendTimer();
      if (isViewAttached) {
        view?.showSuccess('Kode OTP baru telah dikirimkan ke email Anda.');
        view?.onOtpResent();
      }
    } on AuthException catch (e) {
      if (isViewAttached) {
        final lower = e.message.toLowerCase();
        if (lower.contains('rate limit') || lower.contains('too many requests')) {
          view?.showError('Terlalu sering meminta kode. Silakan tunggu beberapa saat.');
        } else if (lower.contains('error sending recovery email') ||
            lower.contains('unexpected_failure') ||
            lower.contains('smtp')) {
          view?.showError(
            'Layanan SMTP Supabase gagal mengirim email. Silakan periksa kredensial SMTP atau log di Supabase Dashboard.',
          );
        } else {
          view?.showError('Gagal mengirim ulang OTP: ${e.message}');
        }
      }
    } catch (e) {
      if (isViewAttached) {
        if (!kIsWeb && e is SocketException) {
          view?.showError('Gagal terhubung ke server. Periksa koneksi internet.');
        } else {
          view?.showError('Terjadi kesalahan saat mengirim ulang kode.');
        }
      }
    } finally {
      if (isViewAttached) {
        view?.hideLoading();
      }
    }
  }

  @override
  void startResendTimer() {
    _countdownTimer?.cancel();
    _secondsRemaining = 60;
    view?.updateResendCountdown(_secondsRemaining);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        if (isViewAttached) {
          view?.updateResendCountdown(_secondsRemaining);
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void disposeTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  @override
  void detachView() {
    disposeTimer();
    super.detachView();
  }
}
