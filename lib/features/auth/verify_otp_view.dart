import 'package:flutter/material.dart';
import '../../app_theme.dart';
import 'forgot_password_contract.dart';
import 'forgot_password_presenter.dart';
import 'reset_password_view.dart';
import 'widgets/otp_input_field.dart';

class VerifyOtpView extends StatefulWidget {
  final String email;

  const VerifyOtpView({super.key, required this.email});

  @override
  State<VerifyOtpView> createState() => _VerifyOtpViewState();
}

class _VerifyOtpViewState extends State<VerifyOtpView>
    implements VerifyOtpViewContract {
  late final VerifyOtpPresenter _presenter;
  final GlobalKey<OtpInputFieldState> _otpKey = GlobalKey<OtpInputFieldState>();

  String _currentOtp = '';
  bool _isLoading = false;
  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    _presenter = VerifyOtpPresenter();
    _presenter.attachView(this);
    // Mulai hitung mundur kirim ulang saat halaman pertama kali dibuka
    _presenter.startResendTimer();
  }

  @override
  void dispose() {
    _presenter.detachView();
    super.dispose();
  }

  @override
  void showLoading() => setState(() => _isLoading = true);

  @override
  void hideLoading() {
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void onOtpVerified() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResetPasswordView(email: widget.email),
      ),
    );
  }

  @override
  void onOtpResent() {
    _otpKey.currentState?.clear();
    setState(() => _currentOtp = '');
  }

  @override
  void updateResendCountdown(int secondsRemaining) {
    if (mounted) {
      setState(() => _secondsRemaining = secondsRemaining);
    }
  }

  void _handleVerify() {
    if (_currentOtp.length != 6) {
      showError('Masukkan 6 digit kode OTP secara lengkap.');
      return;
    }
    _presenter.verifyOtp(email: widget.email, otp: _currentOtp);
  }

  void _handleResend() {
    if (_secondsRemaining > 0 || _isLoading) return;
    _presenter.resendOtp(widget.email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Verifikasi OTP'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySurface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Icon(
                        Icons.mark_email_unread_outlined,
                        size: 40,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space20),
                  const Text(
                    'Masukkan Kode OTP',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'Kami telah mengirimkan 6 digit kode verifikasi ke email:\n${widget.email}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space32),

                  // Form Input 6 Kotak Digit
                  OtpInputField(
                    key: _otpKey,
                    length: 6,
                    enabled: !_isLoading,
                    onChanged: (val) => setState(() => _currentOtp = val),
                    onCompleted: (val) {
                      _currentOtp = val;
                      _handleVerify();
                    },
                  ),
                  const SizedBox(height: AppTheme.space24),

                  // Tombol Verifikasi
                  ElevatedButton(
                    onPressed: (_isLoading || _currentOtp.length != 6)
                        ? null
                        : _handleVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.5),
                      disabledForegroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.space16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusButton,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Verifikasi Kode',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(height: AppTheme.space20),

                  // Hitung Mundur Kirim Ulang
                  Center(
                    child: _secondsRemaining > 0
                        ? Text(
                            'Kirim ulang kode dalam ${_secondsRemaining.toString().padLeft(2, '0')} detik',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : TextButton(
                            onPressed: _isLoading ? null : _handleResend,
                            child: const Text(
                              'Tidak menerima kode? Kirim Ulang',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: AppTheme.space12),

                  // Kembali / Ganti Email
                  TextButton.icon(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text(
                      'Ganti Email atau Kembali',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
