import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../core/utils/period_helper.dart';
import '../../core/widgets/app_drawer.dart';
import '../../data/models/schedule_model.dart';
import '../../data/models/teacher_model.dart';
import '../attendance/attendance_view.dart';
import '../auth/login_view.dart';
import '../profile/profile_view.dart';
import '../schedule/schedule_view.dart';
import 'dashboard_contract.dart';
import 'dashboard_presenter.dart';
import 'widgets/active_session_card.dart';
import 'widgets/realtime_clock_badge.dart';
import 'widgets/today_schedule_tile.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView>
    implements DashboardViewContract {
  late final DashboardPresenter _presenter;

  bool _isLoading = true;

  TeacherModel _teacher = const TeacherModel(
    id: '',
    profileId: '',
    teacherCode: 'GUR',
    name: 'Guru',
    status: 'ACTIVE',
  );

  List<ScheduleModel> _todaySchedules = [];

  @override
  void initState() {
    super.initState();
    _presenter = DashboardPresenter();
    _presenter.attachView(this);
    _presenter.loadDashboardData();
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
  void updateDashboardData({
    required TeacherModel teacher,
    required List<ScheduleModel> todaySchedules,
  }) {
    if (!mounted) return;
    setState(() {
      _teacher = teacher;
      _todaySchedules = todaySchedules;
    });
  }

  @override
  void navigateToSchedule() {
    if (!mounted) return;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ScheduleView()))
        .then((_) => _presenter.refreshData());
  }

  @override
  void navigateToAttendance(ScheduleModel schedule) {
    if (!mounted) return;
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (_) => AttendanceView(schedule: schedule)),
        )
        .then((_) => _presenter.refreshData());
  }

  @override
  void navigateToProfile() {
    if (!mounted) return;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfileView()))
        .then((_) => _presenter.refreshData());
  }

  @override
  void onLoggedOut() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  ScheduleModel? get _activeOrNextSchedule {
    final now = DateTime.now();
    for (var s in _todaySchedules) {
      if (s.getStatus(now) == SessionState.open) return s;
    }
    for (var s in _todaySchedules) {
      if (s.getStatus(now) == SessionState.locked) return s;
    }
    return _todaySchedules.isNotEmpty ? _todaySchedules.first : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space6),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
              ),
              child: Image.asset(
                'assets/logo.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: AppTheme.space8),
            const Text('Skola App'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profil',
            onPressed: navigateToProfile,
          ),
        ],
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _presenter.refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Warning jika Akun Inactive
                    if (_teacher.isInactive)
                      Container(
                        margin: const EdgeInsets.only(bottom: AppTheme.space16),
                        padding: const EdgeInsets.all(AppTheme.space12),
                        decoration: BoxDecoration(
                          color: AppTheme.warningSurface,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusCard,
                          ),
                          border: Border.all(color: AppTheme.warning),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: AppTheme.warning,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Akun Anda berstatus Nonaktif. Hubungi Admin sekolah.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Header Salam & Jam Realtime
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_getGreeting()},',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _teacher.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                PeriodHelper.formatDateIndonesian(
                                  DateTime.now(),
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const RealtimeClockBadge(),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space24),

                    // Sesi Pembelajaran Aktif Hari Ini
                    const Text(
                      'Sesi Pembelajaran Hari Ini',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),

                    if (_activeOrNextSchedule != null)
                      ActiveSessionCard(
                        schedule: _activeOrNextSchedule!,
                        onTap: () => _presenter.onActiveSessionTapped(
                          _activeOrNextSchedule!,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(AppTheme.space20),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusCard,
                          ),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.event_available,
                                size: 36,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Tidak ada jadwal mengajar hari ini.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: navigateToSchedule,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Kelola / Tambah Jadwal'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: AppTheme.space24),

                    // Daftar Semua Jadwal Hari Ini
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Jadwal Hari Ini',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: navigateToSchedule,
                          child: const Text('Lihat Semua'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space8),

                    if (_todaySchedules.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: AppTheme.space16,
                        ),
                        child: Center(
                          child: Text(
                            'Belum ada jadwal mengajar hari ini.',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _todaySchedules.length,
                        itemBuilder: (context, index) {
                          final schedule = _todaySchedules[index];
                          return TodayScheduleTile(
                            schedule: schedule,
                            onTap: () =>
                                _presenter.onScheduleSelected(schedule),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
      drawer: AppDrawer(
        currentRoute: AppDrawerRoute.dashboard,
        teacher: _teacher,
        onDashboardTap: () {},
        onScheduleTap: navigateToSchedule,
        onAttendanceTap: () {
          if (_activeOrNextSchedule != null) {
            navigateToAttendance(_activeOrNextSchedule!);
          } else {
            navigateToSchedule();
          }
        },
        onProfileTap: navigateToProfile,
        onLogoutTap: () => _presenter.logout(),
      ),
    );
  }
}
