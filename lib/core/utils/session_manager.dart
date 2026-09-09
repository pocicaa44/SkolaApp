import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository.dart';
import '../../features/auth/login_view.dart';
import '../../features/auth/reset_password_view.dart';

class SessionManager with WidgetsBindingObserver {
  static final SessionManager _instance = SessionManager._internal();
  static SessionManager get instance => _instance;

  SessionManager._internal();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static const String _keySessionDate = 'user_session_date';

  Timer? _midnightTimer;
  Timer? _periodicCheckTimer;
  StreamSubscription<AuthState>? _authSubscription;
  String? _currentSessionDate;
  bool _isObserverRegistered = false;
  bool isPasswordRecoveryActive = false;
  String? pendingRecoveryEmail;

  String _formatTodayDate([DateTime? date]) {
    final d = date ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Inisialisasi awal saat aplikasi mulai
  void init() {
    if (!_isObserverRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _isObserverRegistered = true;
    }

    _setupAuthStateListener();
  }

  /// Listener auth event recovery dari Supabase (deep link & OTP recovery)
  void _setupAuthStateListener() {
    _authSubscription ??= AuthRepository().onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        isPasswordRecoveryActive = true;
        final email = data.session?.user.email ?? '';
        pendingRecoveryEmail = email;
        navigateToResetPasswordIfReady();
      }
    });
  }

  /// Navigasi ke ResetPasswordView jika navigatorKey sudah siap terpasang
  bool navigateToResetPasswordIfReady() {
    final nav = navigatorKey.currentState;
    if (nav != null && nav.mounted && isPasswordRecoveryActive) {
      final email =
          pendingRecoveryEmail ?? AuthRepository().currentUser?.email ?? '';
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => ResetPasswordView(email: email)),
        (route) => false,
      );
      return true;
    }
    return false;
  }

  /// Catat tanggal login hari ini
  Future<void> recordLoginDate([DateTime? date]) async {
    final todayStr = _formatTodayDate(date);
    _currentSessionDate = todayStr;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySessionDate, todayStr);
    startMidnightWatcher();
  }

  /// Cek apakah sesi login masih berlaku untuk hari ini
  Future<bool> isSessionValidForToday() async {
    final prefs = await SharedPreferences.getInstance();
    final storedDate = prefs.getString(_keySessionDate);
    final todayStr = _formatTodayDate();

    if (storedDate == null || storedDate.isEmpty) {
      return false;
    }

    if (storedDate != todayStr) {
      return false;
    }

    _currentSessionDate = storedDate;
    return true;
  }

  /// Hapus sesi saat logout
  Future<void> clearSession() async {
    _stopTimers();
    _currentSessionDate = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySessionDate);
  }

  /// Mulai pemantau pergantian hari / pukul 00.00
  void startMidnightWatcher() {
    _stopTimers();

    final now = DateTime.now();
    _currentSessionDate ??= _formatTodayDate(now);

    // 1. Hitung durasi tepat menuju pergantian hari pukul 00:00:01
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 1);
    final durationUntilMidnight = nextMidnight.difference(now);

    _midnightTimer = Timer(durationUntilMidnight, () {
      _handleDayChangeLogout();
    });

    // 2. Timer periodik setiap 15 detik untuk menangani jika perangkat sleep / clock jump
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkDateChange();
    });
  }

  void _checkDateChange() {
    final todayStr = _formatTodayDate();
    if (_currentSessionDate != null && _currentSessionDate != todayStr) {
      _handleDayChangeLogout();
    }
  }

  void _stopTimers() {
    _midnightTimer?.cancel();
    _midnightTimer = null;
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = null;
  }

  /// Logout otomatis saat pergantian hari
  Future<void> _handleDayChangeLogout() async {
    _stopTimers();
    await clearSession();

    try {
      final authRepo = AuthRepository();
      if (authRepo.currentUser != null) {
        await authRepo.signOut();
      }
    } catch (_) {}

    final nav = navigatorKey.currentState;
    if (nav != null && nav.mounted) {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginView(
            errorMessage:
                'Sesi harian berakhir (pukul 00:00). Silakan masuk kembali.',
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Saat aplikasi kembali dibuka dari background, periksa apakah hari telah berganti
      _checkDateChange();
    }
  }

  void dispose() {
    _stopTimers();
    _authSubscription?.cancel();
    _authSubscription = null;
    if (_isObserverRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _isObserverRegistered = false;
    }
  }
}
