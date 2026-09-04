import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';
import 'dashboard_page.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _handleSplashNavigation();
  }

  Future<void> _handleSplashNavigation() async {
    final supabase = Supabase.instance.client;
    final initialSession = supabase.auth.currentSession;

    // Jika di Web dan sudah ada sesi (misal baru redirect dari Google OAuth),
    // langsung arahkan ke Dashboard tanpa menunggu jeda splash
    if (kIsWeb && initialSession != null) {
      await _validateAndNavigate(initialSession);
      return;
    }

    // Delay splash normal (1 detik di Web, 3 detik di mobile)
    await Future.delayed(Duration(seconds: kIsWeb ? 1 : 3));

    if (!mounted) return;

    final session = supabase.auth.currentSession;
    if (session != null) {
      await _validateAndNavigate(session);
    } else {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  Future<void> _validateAndNavigate(Session session) async {
    final supabase = Supabase.instance.client;
    try {
      final profile = await supabase
          .from('profiles')
          .select('status')
          .eq('id', session.user.id)
          .maybeSingle();

      if (profile != null && profile['status'] == 'DELETED') {
        await supabase.auth.signOut();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const LoginPage(
              errorMessage: 'Akun Anda telah dihapus oleh pihak sekolah.',
            ),
          ),
        );
        return;
      }
    } catch (_) {
      // Continue to dashboard if network fails or check fails
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardPage()),
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
