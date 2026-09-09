import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skolaapp/app_theme.dart';
import 'package:skolaapp/features/auth/forgot_password_view.dart';
import 'package:skolaapp/features/auth/login_view.dart';
import 'package:skolaapp/features/auth/reset_password_view.dart';

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

  Widget createTestWidget(Widget child) {
    return MaterialApp(theme: AppTheme.lightTheme, home: child);
  }

  group('Forgot Password Widget Tests (Native Recovery Flow)', () {
    testWidgets('LoginView renders Lupa Password? link button', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginView()));
      await tester.pumpAndSettle();

      final forgotButton = find.text('Lupa Password?');
      expect(forgotButton, findsOneWidget);
    });

    testWidgets(
      'ForgotPasswordView renders title, email field, and Kirim Link Reset button',
      (tester) async {
        await tester.pumpWidget(createTestWidget(const ForgotPasswordView()));
        await tester.pumpAndSettle();

        expect(find.text('Lupa Password'), findsWidgets);
        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.text('Kirim Link Reset'), findsOneWidget);
      },
    );

    testWidgets(
      'ResetPasswordView renders new password and confirm password fields',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            const ResetPasswordView(email: 'test@sekolah.sch.id'),
          ),
        );
        await tester.pump();

        expect(find.text('Buat Kata Sandi Baru'), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.text('Simpan Password'), findsOneWidget);
      },
    );
  });
}
