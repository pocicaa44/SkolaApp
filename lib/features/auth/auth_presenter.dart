import 'dart:io' show SocketException;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/base/base_presenter.dart';
import '../../core/utils/session_manager.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_contract.dart';

class AuthPresenter extends BasePresenter<AuthViewContract>
    implements AuthPresenterContract {
  final AuthRepository _authRepo;

  AuthPresenter({AuthRepository? authRepo})
    : _authRepo = authRepo ?? AuthRepository();

  String _parseAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials')) {
      return 'Email atau kata sandi salah. Silakan periksa kembali.';
    } else if (lower.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi. Periksa kotak masuk email Anda.';
    } else if (lower.contains('user not found')) {
      return 'Akun dengan email ini tidak ditemukan.';
    } else if (lower.contains('user already registered') ||
        lower.contains('already exists')) {
      return 'Email ini sudah terdaftar. Silakan masuk atau gunakan email lain.';
    }
    return 'Terjadi kesalahan autentikasi: $message';
  }

  @override
  Future<void> loginWithEmail(String email, String password) async {
    if (!isViewAttached) return;
    view?.showLoading();

    try {
      final res = await _authRepo.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = res.user;
      if (user != null) {
        final status = await _authRepo.checkAccountStatus(user.id);
        if (status != null && status.toUpperCase() == 'DELETED') {
          await _authRepo.signOut();
          await SessionManager.instance.clearSession();
          if (isViewAttached) {
            view?.showError('Akun Anda telah dinonaktifkan permanen/dihapus.');
          }
          return;
        }
      }

      await SessionManager.instance.recordLoginDate();

      if (isViewAttached) {
        view?.onAuthSuccess('Berhasil masuk! Selamat datang di Skola App.');
        view?.navigateToDashboard();
      }
    } on AuthException catch (e) {
      if (isViewAttached) {
        view?.showError(_parseAuthError(e.message));
      }
    } catch (e) {
      if (isViewAttached) {
        if (!kIsWeb && e is SocketException) {
          view?.showError(
            'Gagal terhubung ke server. Periksa koneksi internet lalu coba lagi.',
          );
        } else {
          view?.showError('Terjadi kesalahan saat masuk: ${e.toString()}');
        }
      }
    } finally {
      if (isViewAttached) {
        view?.hideLoading();
      }
    }
  }

  @override
  Future<void> registerWithEmail(
    String fullName,
    String email,
    String password,
  ) async {
    if (!isViewAttached) return;
    view?.showLoading();

    try {
      final res = await _authRepo.signUp(
        email: email.trim(),
        password: password,
        fullName: fullName.trim(),
      );

      if (isViewAttached) {
        if (res.session != null) {
          await SessionManager.instance.recordLoginDate();
          view?.onAuthSuccess(
            'Pendaftaran berhasil! Selamat datang di Skola App.',
          );
          view?.navigateToDashboard();
        } else {
          view?.onAuthSuccess(
            'Pendaftaran berhasil! Silakan periksa email Anda untuk konfirmasi.',
          );
          view?.navigateToLogin();
        }
      }
    } on AuthException catch (e) {
      if (isViewAttached) {
        view?.showError(_parseAuthError(e.message));
      }
    } catch (e) {
      if (isViewAttached) {
        view?.showError('Gagal melakukan pendaftaran: ${e.toString()}');
      }
    } finally {
      if (isViewAttached) {
        view?.hideLoading();
      }
    }
  }

  @override
  Future<void> loginWithGoogle() async {
    if (!isViewAttached) return;
    view?.showGoogleLoading();

    try {
      await _authRepo.signInWithGoogle();
      if (isViewAttached && !kIsWeb) {
        await SessionManager.instance.recordLoginDate();
        view?.onAuthSuccess('Berhasil masuk dengan Google!');
        view?.navigateToDashboard();
      }
    } catch (e) {
      if (isViewAttached) {
        final err = e.toString();
        if (!err.contains('dibatalkan')) {
          view?.showError('Gagal masuk dengan Google: $err');
        }
      }
    } finally {
      if (isViewAttached) {
        view?.hideGoogleLoading();
      }
    }
  }
}
