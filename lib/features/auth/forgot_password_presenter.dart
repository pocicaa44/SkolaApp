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
          'Link pemulihan password telah dikirim ke email Anda. Silakan periksa kotak masuk email Anda.',
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
        } else {
          view?.showError('Gagal mengirimkan link pemulihan: ${e.message}');
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
