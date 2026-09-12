import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skolaapp/data/repositories/auth_repository.dart';
import 'package:skolaapp/features/auth/forgot_password_contract.dart';
import 'package:skolaapp/features/auth/forgot_password_presenter.dart';
import 'package:skolaapp/features/auth/widgets/otp_input_field.dart';

class FakeAuthRepository extends AuthRepository {
  bool shouldThrowOtpError = false;
  bool shouldThrowRateLimit = false;
  bool returnValidSession = true;

  String? lastVerifyEmail;
  String? lastVerifyOtp;
  String? lastResendEmail;

  @override
  User? get currentUser => returnValidSession
      ? const User(
          id: 'mock-user-id',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-01-01',
        )
      : null;

  @override
  Future<AuthResponse> verifyRecoveryOtp({
    required String email,
    required String token,
  }) async {
    if (shouldThrowOtpError) {
      throw const AuthException('Token has expired or is invalid');
    }
    lastVerifyEmail = email;
    lastVerifyOtp = token;

    final user = returnValidSession
        ? const User(
            id: 'mock-user-id',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: '2026-01-01',
          )
        : null;

    final session = returnValidSession
        ? Session(
            accessToken: 'mock-token',
            tokenType: 'bearer',
            user: const User(
              id: 'mock-user-id',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: '2026-01-01',
            ),
          )
        : null;

    return AuthResponse(session: session, user: user);
  }

  @override
  Future<void> resetPasswordForEmail({
    required String email,
    String? redirectTo,
  }) async {
    if (shouldThrowRateLimit) {
      throw const AuthException('Over email rate limit. Too many requests.');
    }
    lastResendEmail = email;
  }
}

class MockVerifyOtpView implements VerifyOtpViewContract {
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;
  bool isOtpVerified = false;
  bool isOtpResent = false;
  int secondsRemaining = 0;

  @override
  void showLoading() => isLoading = true;

  @override
  void hideLoading() => isLoading = false;

  @override
  void showError(String message) => errorMessage = message;

  @override
  void showSuccess(String message) => successMessage = message;

  @override
  void onOtpVerified() => isOtpVerified = true;

  @override
  void onOtpResent() => isOtpResent = true;

  @override
  void updateResendCountdown(int secondsRemaining) {
    this.secondsRemaining = secondsRemaining;
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

  group('VerifyOtpPresenter Tests', () {
    late FakeAuthRepository fakeRepo;
    late VerifyOtpPresenter presenter;
    late MockVerifyOtpView mockView;

    setUp(() {
      fakeRepo = FakeAuthRepository();
      presenter = VerifyOtpPresenter(authRepo: fakeRepo);
      mockView = MockVerifyOtpView();
      presenter.attachView(mockView);
    });

    tearDown(() {
      presenter.detachView();
    });

    test('validasi format kode OTP: kurang dari 6 digit', () async {
      await presenter.verifyOtp(email: 'test@example.com', otp: '12345');
      expect(mockView.errorMessage, 'Masukkan 6 digit kode OTP yang valid.');
      expect(mockView.isOtpVerified, isFalse);
      expect(fakeRepo.lastVerifyOtp, isNull);
    });

    test('validasi format kode OTP: mengandung huruf', () async {
      await presenter.verifyOtp(email: 'test@example.com', otp: '12345A');
      expect(mockView.errorMessage, 'Masukkan 6 digit kode OTP yang valid.');
      expect(mockView.isOtpVerified, isFalse);
      expect(fakeRepo.lastVerifyOtp, isNull);
    });

    test('verifikasi OTP sukses dengan 6 digit valid', () async {
      await presenter.verifyOtp(email: 'test@example.com', otp: '123456');
      expect(mockView.isOtpVerified, isTrue);
      expect(fakeRepo.lastVerifyEmail, equals('test@example.com'));
      expect(fakeRepo.lastVerifyOtp, equals('123456'));
      expect(mockView.successMessage, 'Kode OTP berhasil diverifikasi.');
    });

    test('verifikasi OTP gagal ketika kode salah atau kadaluarsa', () async {
      fakeRepo.shouldThrowOtpError = true;
      await presenter.verifyOtp(email: 'test@example.com', otp: '999999');
      expect(mockView.isOtpVerified, isFalse);
      expect(mockView.errorMessage, 'Kode OTP salah atau telah kadaluarsa.');
    });

    test('kirim ulang OTP (resend) berhasil dan menjalankan countdown timer', () async {
      await presenter.resendOtp('test@example.com');
      expect(fakeRepo.lastResendEmail, equals('test@example.com'));
      expect(mockView.isOtpResent, isTrue);
      expect(mockView.secondsRemaining, 60);
      expect(mockView.successMessage, 'Kode OTP baru telah dikirimkan ke email Anda.');
    });

    test('kirim ulang OTP menangani rate limit', () async {
      fakeRepo.shouldThrowRateLimit = true;
      await presenter.resendOtp('test@example.com');
      expect(mockView.isOtpResent, isFalse);
      expect(
        mockView.errorMessage,
        contains('Terlalu sering meminta kode'),
      );
    });
  });

  group('OtpInputField Widget Tests', () {
    testWidgets('Merender 6 kotak input dengan benar', (WidgetTester tester) async {
      String completedOtp = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpInputField(
              length: 6,
              onCompleted: (code) => completedOtp = code,
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsNWidgets(6));
      expect(completedOtp, isEmpty);
    });
  });
}
