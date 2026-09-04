import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';
import 'attendance_page.dart';
import 'profile_page.dart';
import 'schedule_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentNavIndex = 0;
  bool _isLoading = true;
  Timer? _periodicTimer;
  DateTime _currentTime = DateTime.now();

  String _teacherName = 'Guru';
  String _accountStatus = 'ACTIVE';
  String? _teacherId;

  List<TeacherSchedule> _todaySchedules = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();

    // 1-second periodic ticker for realtime session timer & state update
    _periodicTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  String _getDayName(int day) {
    switch (day) {
      case 1:
        return 'Senin';
      case 2:
        return 'Selasa';
      case 3:
        return 'Rabu';
      case 4:
        return 'Kamis';
      case 5:
        return 'Jumat';
      case 6:
        return 'Sabtu';
      case 7:
        return 'Minggu';
      default:
        return '';
    }
  }

  String _formatDateIndonesian(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${_getDayName(date.weekday)}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 1. Fetch lesson period configs from Supabase
      try {
        final configs = await supabase
            .from('lesson_period_configs')
            .select('day_of_week, period_duration_minutes');
        for (var row in configs) {
          final d = row['day_of_week'] as int?;
          final dur = row['period_duration_minutes'] as int?;
          if (d != null && dur != null) {
            SchoolPeriodHelper.periodDurations[d] = dur;
          }
        }
      } catch (_) {}

      // 2. Fetch or ensure teacher profile
      final teacherRes = await supabase
          .from('teachers')
          .select('id, name, status, subject_ids')
          .eq('profile_id', user.id)
          .maybeSingle();

      if (teacherRes != null) {
        _teacherId = teacherRes['id'] as String?;
        _teacherName = teacherRes['name'] as String? ?? 'Guru';
        _accountStatus = teacherRes['status'] as String? ?? 'ACTIVE';

        // Check if teacher needs to complete profile
        final subjects = teacherRes['subject_ids'] as List?;
        if (_teacherName.isEmpty || subjects == null || subjects.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showCompleteProfilePrompt();
          });
        }
      } else {
        final defaultName = user.userMetadata?['username'] ??
            user.userMetadata?['full_name'] ??
            user.email?.split('@').first ??
            'Guru';

        // Ensure profile exists first before teacher record to satisfy foreign key constraint
        await supabase.from('profiles').upsert(
          {
            'id': user.id,
            'username': defaultName,
            'email': user.email,
            'role': 'teacher',
            'status': 'ACTIVE',
          },
          onConflict: 'id',
        );

        final newTeacher = await supabase
            .from('teachers')
            .upsert(
              {
                'profile_id': user.id,
                'teacher_code': 'GURU-${user.id.substring(0, 6).toUpperCase()}',
                'name': defaultName,
                'status': 'ACTIVE',
              },
              onConflict: 'profile_id',
            )
            .select('id, name')
            .single();
        _teacherId = newTeacher['id'] as String?;
        _teacherName = newTeacher['name'] as String? ?? defaultName;
        _accountStatus = 'ACTIVE';

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showCompleteProfilePrompt();
        });
      }

      if (_teacherId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 3. Current day of week (1=Senin ... 7=Minggu)
      final now = DateTime.now();
      final currentDayOfWeek = now.weekday;

      // 4. Fetch today's completed/locked sessions
      final todayStr = now.toIso8601String().split('T').first;
      final sessionRecords = await supabase
          .from('teaching_sessions')
          .select('schedule_id, status, is_locked')
          .eq('session_date', todayStr);

      final Map<String, bool> completedMap = {};
      for (var s in sessionRecords) {
        final schedId = s['schedule_id'] as String?;
        final isCompleted = s['status'] == 'completed' || s['is_locked'] == true;
        if (schedId != null) {
          completedMap[schedId] = isCompleted;
        }
      }

      // 5. Fetch schedules for today
      final schedulesData = await supabase
          .from('schedules')
          .select('''
            id,
            teacher_id,
            class_id,
            subject_id,
            day_of_week,
            start_time,
            end_time,
            room,
            period_start,
            period_end,
            classes (id, name),
            subjects (id, name)
          ''')
          .eq('teacher_id', _teacherId!)
          .eq('day_of_week', currentDayOfWeek)
          .order('start_time');

      final List<TeacherSchedule> list = [];
      TeacherSchedule? foundActive;

      for (var item in schedulesData) {
        final id = item['id'] as String;
        final classMap = item['classes'] as Map<String, dynamic>?;
        final subjectMap = item['subjects'] as Map<String, dynamic>?;
        final classId = item['class_id'] as String? ?? '';
        final className = classMap?['name'] as String? ?? 'Kelas';
        final subjectId = item['subject_id'] as String? ?? '';
        final subjectName = subjectMap?['name'] as String? ?? 'Mata Pelajaran';
        final room = item['room'] as String? ?? 'Ruang Kelas';
        final dayOfWeek = item['day_of_week'] as int? ?? currentDayOfWeek;
        final periodStart = item['period_start'] as int? ?? 1;
        final periodEnd = item['period_end'] as int? ?? 2;

        final rawStart = item['start_time'] as String? ?? '07:00:00';
        final rawEnd = item['end_time'] as String? ?? '08:30:00';
        final startTime = rawStart.length >= 5 ? rawStart.substring(0, 5) : rawStart;
        final endTime = rawEnd.length >= 5 ? rawEnd.substring(0, 5) : rawEnd;

        // Fetch student count for class
        int studentCount = 0;
        if (classId.isNotEmpty) {
          final countRes = await supabase
              .from('students')
              .select('id')
              .eq('class_id', classId);
          studentCount = countRes.length;
        }

        final isCompleted = completedMap[id] ?? false;

        final schedule = TeacherSchedule(
          id: id,
          teacherId: _teacherId!,
          classId: classId,
          className: className,
          subjectId: subjectId,
          subjectName: subjectName,
          room: room,
          dayOfWeek: dayOfWeek,
          periodStart: periodStart,
          periodEnd: periodEnd,
          startTime: startTime,
          endTime: endTime,
          studentCount: studentCount,
          isCompletedToday: isCompleted,
          isLocked: isCompleted,
        );

        list.add(schedule);

        if (schedule.getStatus(now) == SessionState.open && foundActive == null) {
          foundActive = schedule;
        }
      }

      if (mounted) {
        setState(() {
          _todaySchedules = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCompleteProfilePrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusDialog)),
        title: const Text(
          'Lengkapi Profil Guru',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Selamat datang! Sebelum memulai kegiatan belajar mengajar, silakan lengkapi mata pelajaran yang Anda ampu.',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfilePage(isInitialSetup: true),
                ),
              ).then((_) => _loadDashboardData());
            },
            child: const Text('Lengkapi Sekarang'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionStateBadge(SessionState state) {
    switch (state) {
      case SessionState.open:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.successSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.play_circle_fill, color: AppTheme.success, size: 14),
              SizedBox(width: 4),
              Text(
                'SEDANG BERLANGSUNG',
                style: TextStyle(
                  color: AppTheme.success,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      case SessionState.locked:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceMuted,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 14),
              SizedBox(width: 4),
              Text(
                'TERKUNCI (BELUM MULAI)',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      case SessionState.closed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primarySurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle_outline, color: AppTheme.primary, size: 14),
              SizedBox(width: 4),
              Text(
                'SELESAI',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildDashboardHome() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    final openSchedule = _todaySchedules.where((s) => s.getStatus(_currentTime) == SessionState.open).firstOrNull;

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Inactive Account Warning Banner
            if (_accountStatus == 'INACTIVE') ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: BoxDecoration(
                  color: AppTheme.warningSurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(color: AppTheme.warning),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 24),
                    SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Text(
                        'Akun Anda berstatus NONAKTIF. Anda hanya dapat melihat data pembelajaran dalam mode baca.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space16),
            ],

            // Greeting & Identity Header
            Container(
              padding: const EdgeInsets.all(AppTheme.space20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.primarySurface,
                    child: Text(
                      _teacherName.isNotEmpty ? _teacherName[0].toUpperCase() : 'G',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()},',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _teacherName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateIndonesian(_currentTime),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space24),

            // Active / Open Session Callout (Hero Emphasis)
            if (openSchedule != null) ...[
              const Text(
                'Sesi Sedang Berlangsung',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.space12),

              Container(
                padding: const EdgeInsets.all(AppTheme.space20),
                decoration: BoxDecoration(
                  color: AppTheme.primarySurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(color: AppTheme.primary, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSessionStateBadge(SessionState.open),
                        Text(
                          'JP ${openSchedule.periodStart}–${openSchedule.periodEnd}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space16),
                    Text(
                      openSchedule.subjectName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${openSchedule.className} • Ruang ${openSchedule.room}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space12),
                    Row(
                      children: [
                        const Icon(Icons.access_time_filled, color: AppTheme.primary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${openSchedule.startTime} – ${openSchedule.endTime}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Builder(
                          builder: (_) {
                            final rem = openSchedule.getRemainingDuration(_currentTime);
                            final m = rem.inMinutes;
                            final s = rem.inSeconds % 60;
                            return Text(
                              'Sisa: ${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryDark,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AttendancePage(schedule: openSchedule),
                          ),
                        ).then((_) => _loadDashboardData());
                      },
                      icon: const Icon(Icons.fact_check_outlined, size: 18),
                      label: const Text('Mulai Presensi Siswa'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space24),
            ],

            // Today's Schedules List
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
                Text(
                  '${_todaySchedules.length} Sesi',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),

            if (_todaySchedules.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.space32),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.event_busy_outlined, size: 48, color: AppTheme.textMuted),
                    const SizedBox(height: AppTheme.space12),
                    Text(
                      _currentTime.weekday > 5
                          ? 'Hari Libur Akhir Pekan (${_getDayName(_currentTime.weekday)})'
                          : 'Tidak ada jadwal mengajar hari ini',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentTime.weekday > 5
                          ? 'Kegiatan belajar mengajar aktif pada hari kerja (Senin s/d Jumat). Anda dapat meninjau jadwal mingguan di menu Jadwal.'
                          : 'Periksa menu Jadwal untuk melihat atau membuat jadwal mengajar mingguan Anda.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ..._todaySchedules.map((schedule) {
                final status = schedule.getStatus(_currentTime);
                final isOpen = status == SessionState.open;

                return Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.space12),
                  padding: const EdgeInsets.all(AppTheme.space16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    border: Border.all(
                      color: isOpen ? AppTheme.primary : AppTheme.border,
                      width: isOpen ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSessionStateBadge(status),
                          Text(
                            'JP ${schedule.periodStart}–${schedule.periodEnd}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space12),
                      Text(
                        schedule.subjectName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${schedule.className} • ${schedule.studentCount} Siswa',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space12),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: AppTheme.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            '${schedule.startTime} – ${schedule.endTime}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AttendancePage(schedule: schedule),
                                ),
                              ).then((_) => _loadDashboardData());
                            },
                            child: Text(
                              isOpen
                                  ? 'Isi Presensi'
                                  : status == SessionState.closed
                                      ? 'Lihat Hasil'
                                      : 'Lihat Sesi',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: AppTheme.space24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Skola App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              ).then((_) => _loadDashboardData());
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildDashboardHome(),
          SchedulePage(
            onStartAttendance: (schedule) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AttendancePage(schedule: schedule)),
              ).then((_) => _loadDashboardData());
            },
          ),
          const AttendancePage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: NavigationBar(
          selectedIndex: _currentNavIndex,
          onDestinationSelected: (idx) {
            setState(() => _currentNavIndex = idx);
            if (idx == 0) _loadDashboardData();
          },
          backgroundColor: AppTheme.surface,
          indicatorColor: AppTheme.primaryLight,
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppTheme.primaryDark),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today, color: AppTheme.primaryDark),
              label: 'Jadwal',
            ),
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check, color: AppTheme.primaryDark),
              label: 'Presensi',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppTheme.primaryDark),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
