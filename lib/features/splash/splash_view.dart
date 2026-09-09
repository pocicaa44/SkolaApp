import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../auth/login_view.dart';
import '../auth/reset_password_view.dart';
import '../dashboard/dashboard_view.dart';
import 'splash_contract.dart';
import 'splash_presenter.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> implements SplashViewContract {
  late final SplashPresenter _presenter;

  @override
  void initState() {
    super.initState();
    _presenter = SplashPresenter();
    _presenter.attachView(this);
    _presenter.checkInitialSession();
  }

  @override
  void dispose() {
    _presenter.detachView();
    super.dispose();
  }

  @override
  void showLoading() {}

  @override
  void hideLoading() {}

  @override
  void showError(String message) {}

  @override
  void showSuccess(String message) {}

  @override
  void navigateToDashboard() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const DashboardView()));
  }

  @override
  void navigateToLogin({String? errorMessage}) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginView(errorMessage: errorMessage)),
    );
  }

  @override
  void navigateToResetPassword({required String email}) {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => ResetPasswordView(email: email)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              ),
              child: Image.asset(
                'assets/logo.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            const Text(
              'Skola App',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppTheme.space8),
            const Text(
              'Administrasi Pembelajaran Guru',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.primaryLight,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: AppTheme.space48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
