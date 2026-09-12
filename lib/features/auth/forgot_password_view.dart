import 'package:flutter/material.dart';
import '../../app_theme.dart';
import 'forgot_password_contract.dart';
import 'forgot_password_presenter.dart';
import 'verify_otp_view.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView>
    implements ForgotPasswordViewContract {
  late final ForgotPasswordPresenter _presenter;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String _sentEmail = '';

  @override
  void initState() {
    super.initState();
    _presenter = ForgotPasswordPresenter();
    _presenter.attachView(this);
  }

  @override
  void dispose() {
    _presenter.detachView();
    _emailController.dispose();
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
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  @override
  void showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.success),
    );
  }

  @override
  void onRecoveryEmailSent(String email) {
    setState(() {
      _emailSent = true;
      _sentEmail = email;
    });
    // Langsung arahkan ke halaman verifikasi kode OTP
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerifyOtpView(email: email),
      ),
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;
    _presenter.sendRecoveryEmail(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Lupa Password'),
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
              child: _emailSent ? _buildSuccessView() : _buildFormView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
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
                Icons.lock_reset_outlined,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space20),
          const Text(
            'Lupa Password',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          const Text(
            'Masukkan email yang terdaftar.\nKami akan mengirimkan 6 digit kode OTP untuk mereset password Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppTheme.space32),

          // Input Email
          const Text(
            'Email',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.space6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'user@gmail.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email wajib diisi';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Format email tidak valid';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.space24),

          // Tombol Kirim Kode OTP
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusButton),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Kirim Kode OTP',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
          ),
          const SizedBox(height: AppTheme.space20),

          // Kembali ke Login
          TextButton.icon(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text(
              'Kembali ke Halaman Masuk',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(AppTheme.space16),
            decoration: BoxDecoration(
              color: AppTheme.successSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 40,
              color: AppTheme.success,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.space20),
        const Text(
          'Kode OTP Terkirim',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.space8),
        Text(
          'Kami telah mengirimkan 6 digit kode OTP ke email:\n$_sentEmail\n\nSilakan periksa kotak masuk atau spam email Anda, lalu masukkan kode tersebut untuk mereset kata sandi.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppTheme.space32),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VerifyOtpView(email: _sentEmail),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Masukkan Kode OTP',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.surface,
            foregroundColor: AppTheme.textPrimary,
            padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
              side: const BorderSide(color: AppTheme.border),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Kembali ke Halaman Masuk',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
              _emailController.clear();
            });
          },
          child: const Text(
            'Kirim Ulang ke Email Lain',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

