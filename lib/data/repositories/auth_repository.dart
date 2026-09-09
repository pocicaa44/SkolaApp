import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'http://localhost:3000',
        queryParams: {'access_type': 'offline', 'prompt': 'consent'},
      );
      return;
    }

    final webClientId = dotenv.env['WEB_CLIENT'];
    final iosClientId = dotenv.env['IOS_CLIENT'];
    final clientId = Platform.isIOS ? iosClientId : null;

    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: clientId,
      serverClientId: webClientId,
    );

    try {
      await googleSignIn.signOut();
    } catch (_) {}

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw 'Google Sign In dibatalkan oleh pengguna.';
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw 'ID Token tidak ditemukan dari Google Sign In.';
    }

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<String?> checkAccountStatus(String userId) async {
    try {
      final res = await _supabase
          .from('profiles')
          .select('status')
          .eq('id', userId)
          .maybeSingle();

      if (res != null) {
        return res['status'] as String?;
      }
    } catch (_) {}
    return null;
  }

  /// Kirim email pemulihan kata sandi (recovery link) ke email pengguna
  Future<void> resetPasswordForEmail({
    required String email,
    String? redirectTo,
  }) async {
    final effectiveRedirect =
        redirectTo ??
        (kIsWeb ? Uri.base.origin : 'io.supabase.skolaapp://login-callback');
    await _supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: effectiveRedirect,
    );
  }

  /// Perbarui kata sandi pengguna pada sesi aktif/recovery saat ini
  Future<UserResponse> updateUserPassword({required String newPassword}) async {
    return await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      }
    } catch (_) {}
    await _supabase.auth.signOut();
  }
}
