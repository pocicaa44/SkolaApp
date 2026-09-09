import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skolaapp/core/utils/session_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionManager Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'isSessionValidForToday returns false when no session date stored',
      () async {
        final manager = SessionManager.instance;
        final isValid = await manager.isSessionValidForToday();
        expect(isValid, isFalse);
      },
    );

    test(
      'isSessionValidForToday returns true when session date is today',
      () async {
        final manager = SessionManager.instance;
        await manager.recordLoginDate(DateTime.now());
        final isValid = await manager.isSessionValidForToday();
        expect(isValid, isTrue);
      },
    );

    test(
      'isSessionValidForToday returns false when session date is from yesterday',
      () async {
        final manager = SessionManager.instance;
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        await manager.recordLoginDate(yesterday);
        final isValid = await manager.isSessionValidForToday();
        expect(isValid, isFalse);
      },
    );

    test('clearSession removes stored date', () async {
      final manager = SessionManager.instance;
      await manager.recordLoginDate(DateTime.now());
      expect(await manager.isSessionValidForToday(), isTrue);

      await manager.clearSession();
      expect(await manager.isSessionValidForToday(), isFalse);
    });
  });
}
