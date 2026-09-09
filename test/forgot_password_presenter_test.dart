import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skolaapp/data/repositories/auth_repository.dart';
import 'package:skolaapp/features/auth/forgot_password_contract.dart';
import 'package:skolaapp/features/auth/forgot_password_presenter.dart';

// Fake AuthRepository untuk unit test tanpa bergantung pada backend Supabase
class FakeAuthRepository extends AuthRepository {
  bool shouldThrowRateLimit = false;
  bool shouldThrowPasswordError = false;
  bool hasActiveUser = true;

  String? lastResetEmail;
  String? lastRedirectTo;
  String? lastUpdatedPassword;
  bool didSignOut = false;

  @override
  User? get currentUser => hasActiveUser
      ? const User(
          id: 'mock-user-123',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-01-01',
        )
      : null;

  @override
  Future<void> resetPasswordForEmail({
    required String email,
    String? redirectTo,
  }) async {
    if (shouldThrowRateLimit) {
      throw const AuthException('Rate limit exceeded. Too many requests.');
    }
    lastResetEmail = email;
    lastRedirectTo = redirectTo;
  }

  @override
  Future<UserResponse> updateUserPassword({required String newPassword}) async {
    if (shouldThrowPasswordError) {
      throw const AuthException('Password update failed.');
    }
    lastUpdatedPassword = newPassword;
    return UserResponse.fromJson({
      'user': {
        'id': 'mock-user-123',
        'app_metadata': {},
        'user_metadata': {},
        'aud': 'authenticated',
        'created_at': '2026-01-01',
      },
    });
  }

  @override
  Future<void> signOut() async {
    didSignOut = true;
  }
}

// Mock Views
class MockForgotPasswordView implements ForgotPasswordViewContract {
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;
  String? sentEmail;

  @override
  void showLoading() => isLoading = true;
  @override
  void hideLoading() => isLoading = false;
  @override
  void showError(String message) => errorMessage = message;
  @override
  void showSuccess(String message) => successMessage = message;
  @override
  void onRecoveryEmailSent(String email) => sentEmail = email;
}

class MockResetPasswordView implements ResetPasswordViewContract {
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;
  String? resetSuccessMessage;
  bool didNavigateToLogin = false;

  @override
  void showLoading() => isLoading = true;
  @override
  void hideLoading() => isLoading = false;
  @override
  void showError(String message) => errorMessage = message;
  @override
  void showSuccess(String message) => successMessage = message;
  @override
  void onPasswordResetSuccess(String message) => resetSuccessMessage = message;
  @override
  void navigateToLogin([String? message]) {
    didNavigateToLogin = true;
    if (message != null) successMessage = message;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://xyzcompany.supabase.co
SUPABASE_ANON_KEY=public-anon-key-placeholder
''',
    );
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
      ),
    );
  });

  group('ForgotPasswordPresenter Tests (Native Recovery Flow)', () {
    late FakeAuthRepository fakeRepo;
    late MockForgotPasswordView mockView;
    late ForgotPasswordPresenter presenter;

    setUp(() {
      fakeRepo = FakeAuthRepository();
      mockView = MockForgotPasswordView();
      presenter = ForgotPasswordPresenter(authRepo: fakeRepo);
      presenter.attachView(mockView);
    });

    test(
      'sendRecoveryEmail with invalid email shows error and does not call repo',
      () async {
        await presenter.sendRecoveryEmail('invalid-email');
        expect(mockView.errorMessage, contains('Format email tidak valid'));
        expect(fakeRepo.lastResetEmail, isNull);
      },
    );

    test(
      'sendRecoveryEmail with valid email sends recovery link and triggers callback',
      () async {
        await presenter.sendRecoveryEmail('guru@sekolah.sch.id');
        expect(fakeRepo.lastResetEmail, equals('guru@sekolah.sch.id'));
        expect(
          mockView.successMessage,
          contains('Link pemulihan password telah dikirim'),
        );
        expect(mockView.sentEmail, equals('guru@sekolah.sch.id'));
      },
    );

    test(
      'sendRecoveryEmail handles rate limit exception with friendly message',
      () async {
        fakeRepo.shouldThrowRateLimit = true;
        await presenter.sendRecoveryEmail('guru@sekolah.sch.id');
        expect(
          mockView.errorMessage,
          contains('Terlalu banyak permintaan pemulihan'),
        );
        expect(mockView.sentEmail, isNull);
      },
    );
  });

  group('ResetPasswordPresenter Tests (Password Validations & Update)', () {
    late FakeAuthRepository fakeRepo;
    late MockResetPasswordView mockView;
    late ResetPasswordPresenter presenter;

    setUp(() {
      fakeRepo = FakeAuthRepository();
      mockView = MockResetPasswordView();
      presenter = ResetPasswordPresenter(authRepo: fakeRepo);
      presenter.attachView(mockView);
    });

    test('resetPassword with empty password shows error', () async {
      await presenter.resetPassword(newPassword: '', confirmPassword: '');
      expect(mockView.errorMessage, contains('Kata sandi baru wajib diisi'));
    });

    test(
      'resetPassword with less than 8 chars shows error (min 8 chars)',
      () async {
        await presenter.resetPassword(
          newPassword: '1234567',
          confirmPassword: '1234567',
        );
        expect(mockView.errorMessage, contains('minimal 8 karakter'));
      },
    );

    test('resetPassword with empty confirm password shows error', () async {
      await presenter.resetPassword(
        newPassword: 'password123',
        confirmPassword: '',
      );
      expect(
        mockView.errorMessage,
        contains('Konfirmasi kata sandi wajib diisi'),
      );
    });

    test('resetPassword with mismatched confirmation shows error', () async {
      await presenter.resetPassword(
        newPassword: 'password123',
        confirmPassword: 'different123',
      );
      expect(
        mockView.errorMessage,
        contains('Konfirmasi kata sandi tidak sama'),
      );
    });

    test(
      'resetPassword without active recovery session shows error and navigates to login',
      () async {
        fakeRepo.hasActiveUser = false;
        await presenter.resetPassword(
          newPassword: 'password123',
          confirmPassword: 'password123',
        );
        expect(
          mockView.errorMessage,
          contains('Sesi pemulihan telah berakhir'),
        );
        expect(mockView.didNavigateToLogin, isTrue);
        expect(fakeRepo.lastUpdatedPassword, isNull);
      },
    );

    test(
      'resetPassword with valid password updates password, signs out and navigates to login',
      () async {
        await presenter.resetPassword(
          newPassword: 'newValidPassword123',
          confirmPassword: 'newValidPassword123',
        );
        expect(fakeRepo.lastUpdatedPassword, equals('newValidPassword123'));
        expect(fakeRepo.didSignOut, isTrue);
        expect(
          mockView.resetSuccessMessage,
          contains('Password berhasil diperbarui'),
        );
        expect(mockView.didNavigateToLogin, isTrue);
      },
    );
  });
}
