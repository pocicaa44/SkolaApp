import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skolaapp/app_theme.dart';
import 'package:skolaapp/core/widgets/app_drawer.dart';
import 'package:skolaapp/data/models/teacher_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    dotenv.testLoad(fileInput: 'SUPABASE_URL=https://mock.co\nSUPABASE_ANON_KEY=mock\n');
    SharedPreferences.setMockInitialValues({});
  });

  const testTeacher = TeacherModel(
    id: 't-1',
    profileId: 'p-1',
    teacherCode: 'GUR-01',
    name: 'Budi Santoso, S.Pd.',
    email: 'budi@sekolah.sch.id',
    status: 'ACTIVE',
  );

  Widget createTestWidget({
    AppDrawerRoute currentRoute = AppDrawerRoute.dashboard,
    VoidCallback? onScheduleTap,
    VoidCallback? onLogoutTap,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        drawer: AppDrawer(
          currentRoute: currentRoute,
          teacher: testTeacher,
          onScheduleTap: onScheduleTap,
          onLogoutTap: onLogoutTap,
        ),
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            child: const Text('Buka Drawer'),
          ),
        ),
      ),
    );
  }

  group('AppDrawer Widget Tests', () {
    testWidgets('Renders teacher info and navigation menu items in drawer', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Buka drawer
      await tester.tap(find.text('Buka Drawer'));
      await tester.pumpAndSettle();

      // Verifikasi identitas aplikasi & guru
      expect(find.text('Skola App'), findsOneWidget);
      expect(find.text('Budi Santoso, S.Pd.'), findsOneWidget);
      expect(find.text('GUR-01'), findsOneWidget);
      expect(find.text('AKTIF'), findsOneWidget);
      expect(find.text('budi@sekolah.sch.id'), findsOneWidget);

      // Verifikasi item menu navigasi
      expect(find.text('Dasbor'), findsOneWidget);
      expect(find.text('Jadwal Mengajar'), findsOneWidget);
      expect(find.text('Presensi Siswa'), findsOneWidget);
      expect(find.text('Profil Guru'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);
    });

    testWidgets('Tapping on menu item invokes callback and closes drawer', (tester) async {
      bool didTapSchedule = false;
      await tester.pumpWidget(createTestWidget(
        onScheduleTap: () => didTapSchedule = true,
      ));
      await tester.pumpAndSettle();

      // Buka drawer
      await tester.tap(find.text('Buka Drawer'));
      await tester.pumpAndSettle();

      // Tekan Jadwal Mengajar
      await tester.tap(find.text('Jadwal Mengajar'));
      await tester.pumpAndSettle();

      expect(didTapSchedule, isTrue);
    });

    testWidgets('Tapping Keluar displays confirmation dialog', (tester) async {
      bool didLogout = false;
      await tester.pumpWidget(createTestWidget(
        onLogoutTap: () => didLogout = true,
      ));
      await tester.pumpAndSettle();

      // Buka drawer
      await tester.tap(find.text('Buka Drawer'));
      await tester.pumpAndSettle();

      // Tekan Keluar
      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();

      // Verifikasi dialog konfirmasi
      expect(find.text('Konfirmasi Keluar'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      // Tekan tombol konfirmasi Keluar di dialog
      final confirmButton = find.widgetWithText(ElevatedButton, 'Keluar');
      expect(confirmButton, findsOneWidget);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(didLogout, isTrue);
    });
  });
}
