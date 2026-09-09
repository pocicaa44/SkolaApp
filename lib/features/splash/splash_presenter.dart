import 'package:flutter/foundation.dart';
import '../../core/base/base_presenter.dart';
import '../../core/utils/session_manager.dart';
import '../../data/repositories/auth_repository.dart';
import 'splash_contract.dart';

class SplashPresenter extends BasePresenter<SplashViewContract>
    implements SplashPresenterContract {
  final AuthRepository _authRepo;

  SplashPresenter({AuthRepository? authRepo})
    : _authRepo = authRepo ?? AuthRepository();

  @override
  Future<void> checkInitialSession() async {
    // Jika aplikasi dibuka dengan link pemulihan password (recovery fragment/URL di web)
    if (kIsWeb && Uri.base.fragment.contains('type=recovery')) {
      SessionManager.instance.isPasswordRecoveryActive = true;
      return;
    }

    if (SessionManager.instance.isPasswordRecoveryActive) {
      final email =
          SessionManager.instance.pendingRecoveryEmail ??
          _authRepo.currentUser?.email ??
          '';
      view?.navigateToResetPassword(email: email);
      return;
    }

    final initialSession = _authRepo.currentSession;

    // Web fast-path jika baru redirect dari OAuth
    if (kIsWeb && initialSession != null) {
      await _validateAndRoute(initialSession.user.id);
      return;
    }

    // Delay splash (1s web, 2.5s mobile)
    await Future.delayed(Duration(milliseconds: kIsWeb ? 800 : 2500));
    if (!isViewAttached) return;

    if (SessionManager.instance.isPasswordRecoveryActive) {
      final email =
          SessionManager.instance.pendingRecoveryEmail ??
          _authRepo.currentUser?.email ??
          '';
      view?.navigateToResetPassword(email: email);
      return;
    }

    final session = _authRepo.currentSession;
    if (session != null) {
      await _validateAndRoute(session.user.id);
    } else {
      await SessionManager.instance.clearSession();
      view?.navigateToLogin();
    }
  }

  Future<void> _validateAndRoute(String userId) async {
    // 1. Cek validitas sesi harian (apakah hari telah berganti / melewati pukul 00:00)
    final isValidSession = await SessionManager.instance
        .isSessionValidForToday();
    if (!isValidSession) {
      await _authRepo.signOut();
      await SessionManager.instance.clearSession();
      if (!isViewAttached) return;
      view?.navigateToLogin(
        errorMessage:
            'Sesi harian Anda telah berakhir (pukul 00:00). Silakan masuk kembali.',
      );
      return;
    }

    // 2. Cek status akun
    final status = await _authRepo.checkAccountStatus(userId);
    if (!isViewAttached) return;

    if (status != null && status.toUpperCase() == 'DELETED') {
      await _authRepo.signOut();
      await SessionManager.instance.clearSession();
      if (!isViewAttached) return;
      view?.navigateToLogin(
        errorMessage:
            'Akun Anda telah dinonaktifkan/dihapus oleh pihak sekolah.',
      );
      return;
    }

    // Mulai watcher 00:00
    SessionManager.instance.startMidnightWatcher();
    view?.navigateToDashboard();
  }
}
