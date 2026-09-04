import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';
import 'schedule_page.dart';

enum AttendanceStatus {
  present('present', 'Hadir', 'H', AppTheme.success, AppTheme.successSurface),
  permission('permission', 'Izin', 'I', AppTheme.info, AppTheme.infoSurface),
  sick('sick', 'Sakit', 'S', AppTheme.warning, AppTheme.warningSurface),
  absent('absent', 'Alpa', 'A', AppTheme.error, AppTheme.errorSurface);

  final String dbCode;
  final String label;
  final String shortCode;
  final Color color;
  final Color surfaceColor;

  const AttendanceStatus(this.dbCode, this.label, this.shortCode, this.color, this.surfaceColor);

  static AttendanceStatus? fromDb(String? code) {
    if (code == null) return null;
    for (var s in AttendanceStatus.values) {
      if (s.dbCode == code.toLowerCase()) return s;
    }
    return null;
  }
}

class StudentItem {
  final String id;
  final String studentCode;
  final String name;
  final String gender;

  StudentItem({
    required this.id,
    required this.studentCode,
    required this.name,
    required this.gender,
  });
}

class AttendancePage extends StatefulWidget {
  final TeacherSchedule? schedule;

  const AttendancePage({super.key, this.schedule});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSessionLocked = false;
  bool _hasTriggeredEndDialog = false;

  TeacherSchedule? _activeSchedule;
  List<TeacherSchedule> _availableSchedules = [];

  Timer? _countdownTimer;
  DateTime _currentTime = DateTime.now();

  final _searchController = TextEditingController();
  final _materiController = TextEditingController();
  final _notesController = TextEditingController();

  List<StudentItem> _students = [];
  final Map<String, AttendanceStatus?> _attendanceMap = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _activeSchedule = widget.schedule;
    _loadInitialData();

    // 1-second countdown & status updater
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _currentTime = DateTime.now();
      });

      if (_activeSchedule != null) {
        final remaining = _activeSchedule!.getRemainingDuration(_currentTime);
        if (!_isSessionLocked && !_hasTriggeredEndDialog && remaining == Duration.zero) {
          _hasTriggeredEndDialog = true;
          _showSessionExpiredNotice();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _materiController.dispose();
    _notesController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // If schedule not passed directly, load today's schedules for teacher
      if (_activeSchedule == null) {
        final teacherRes = await supabase
            .from('teachers')
            .select('id')
            .eq('profile_id', user.id)
            .maybeSingle();

        if (teacherRes != null) {
          final teacherId = teacherRes['id'] as String;
          final today = DateTime.now().weekday;
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
              .eq('teacher_id', teacherId)
              .eq('day_of_week', today)
              .order('start_time');

          final List<TeacherSchedule> list = [];
          for (var item in schedulesData) {
            final id = item['id'] as String;
            final classMap = item['classes'] as Map<String, dynamic>?;
            final subjectMap = item['subjects'] as Map<String, dynamic>?;
            final classId = item['class_id'] as String? ?? '';
            final className = classMap?['name'] as String? ?? 'Kelas';
            final subjectId = item['subject_id'] as String? ?? '';
            final subjectName = subjectMap?['name'] as String? ?? 'Mata Pelajaran';
            final room = item['room'] as String? ?? 'Ruang Kelas';
            final dayOfWeek = item['day_of_week'] as int? ?? today;
            final periodStart = item['period_start'] as int? ?? 1;
            final periodEnd = item['period_end'] as int? ?? 2;

            final rawStart = item['start_time'] as String? ?? '07:00:00';
            final rawEnd = item['end_time'] as String? ?? '08:30:00';
            final startTime = rawStart.length >= 5 ? rawStart.substring(0, 5) : rawStart;
            final endTime = rawEnd.length >= 5 ? rawEnd.substring(0, 5) : rawEnd;

            list.add(TeacherSchedule(
              id: id,
              teacherId: teacherId,
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
            ));
          }
          _availableSchedules = list;
          if (_availableSchedules.isNotEmpty) {
            _activeSchedule = _availableSchedules.first;
          }
        }
      }

      if (_activeSchedule != null) {
        await _loadScheduleStudentsAndAttendance(_activeSchedule!);
      }
    } catch (_) {
      // Continue
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadScheduleStudentsAndAttendance(TeacherSchedule schedule) async {
    final supabase = Supabase.instance.client;
    final todayStr = DateTime.now().toIso8601String().split('T').first;

    _attendanceMap.clear();
    _isSessionLocked = false;

    // 1. Fetch teaching session record (journal/notes, lock status)
    try {
      final sessionRes = await supabase
          .from('teaching_sessions')
          .select('status, is_locked, notes')
          .eq('schedule_id', schedule.id)
          .eq('session_date', todayStr)
          .maybeSingle();

      if (sessionRes != null) {
        _isSessionLocked = sessionRes['is_locked'] == true || sessionRes['status'] == 'completed';
        final notes = sessionRes['notes'] as String?;
        if (notes != null) {
          if (notes.contains('|||')) {
            final parts = notes.split('|||');
            _materiController.text = parts[0].trim();
            _notesController.text = parts.length > 1 ? parts[1].trim() : '';
          } else {
            _materiController.text = notes;
          }
        }
      }
    } catch (_) {}

    // 2. Fetch class students
    final studentsData = await supabase
        .from('students')
        .select('id, student_code, name, gender')
        .eq('class_id', schedule.classId)
        .order('name');

    final List<StudentItem> studentList = [];
    for (var row in studentsData) {
      final s = StudentItem(
        id: row['id'] as String,
        studentCode: row['student_code'] as String? ?? '-',
        name: row['name'] as String,
        gender: row['gender'] as String? ?? 'male',
      );
      studentList.add(s);
      // Initial state: BELUM_DIISI (null)
      _attendanceMap[s.id] = null;
    }

    // 3. Fetch existing attendance records if any
    try {
      final attendanceData = await supabase
          .from('attendance')
          .select('student_id, status')
          .eq('schedule_id', schedule.id)
          .eq('attendance_date', todayStr);

      for (var row in attendanceData) {
        final sId = row['student_id'] as String?;
        final statusStr = row['status'] as String?;
        if (sId != null && statusStr != null) {
          _attendanceMap[sId] = AttendanceStatus.fromDb(statusStr);
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _students = studentList;
      });
    }
  }

  void _showSessionExpiredNotice() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusDialog)),
        title: const Text(
          'Waktu Sesi Berakhir',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Waktu jam pelajaran sesi ini telah selesai. Data presensi dan jurnal sekarang berada dalam mode arsip/read-only.',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSaveAttendance({bool markCompleted = false}) async {
    if (_activeSchedule == null) return;

    // Validation: All students must have attendance status (no BELUM_DIISI)
    final unassignedCount = _students.where((s) => _attendanceMap[s.id] == null).length;
    if (unassignedCount > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusDialog)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 24),
              SizedBox(width: 8),
              Text('Presensi Belum Lengkap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          content: Text(
            'Masih ada $unassignedCount siswa yang berstatus "Belum diisi".\n\nSeluruh siswa wajib memiliki status presensi (Hadir, Izin, Sakit, atau Alpa) sebelum sesi dapat disimpan.',
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Lengkapi Presensi'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final supabase = Supabase.instance.client;
      final todayStr = DateTime.now().toIso8601String().split('T').first;

      // 1. Upsert attendance records for all students
      final List<Map<String, dynamic>> records = [];
      for (var s in _students) {
        final status = _attendanceMap[s.id];
        if (status != null) {
          records.add({
            'schedule_id': _activeSchedule!.id,
            'student_id': s.id,
            'attendance_date': todayStr,
            'status': status.dbCode,
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      }

      await supabase.from('attendance').upsert(
        records,
        onConflict: 'schedule_id, student_id, attendance_date',
      );

      // 2. Upsert teaching session record with optional journal
      final materi = _materiController.text.trim();
      final notes = _notesController.text.trim();
      String combinedNotes = '';
      if (materi.isNotEmpty || notes.isNotEmpty) {
        combinedNotes = '$materi|||$notes';
      }

      final existingSession = await supabase
          .from('teaching_sessions')
          .select('id')
          .eq('schedule_id', _activeSchedule!.id)
          .eq('session_date', todayStr)
          .maybeSingle();

      final sessionPayload = {
        'schedule_id': _activeSchedule!.id,
        'session_date': todayStr,
        'status': markCompleted ? 'completed' : 'active',
        'is_locked': markCompleted,
        'notes': combinedNotes.isNotEmpty ? combinedNotes : null,
        'ended_at': markCompleted ? DateTime.now().toIso8601String() : null,
      };

      if (existingSession != null) {
        await supabase
            .from('teaching_sessions')
            .update(sessionPayload)
            .eq('id', existingSession['id'] as String);
      } else {
        await supabase.from('teaching_sessions').insert(sessionPayload);
      }

      if (markCompleted) {
        _isSessionLocked = true;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(markCompleted ? 'Sesi pembelajaran berhasil diselesaikan!' : 'Presensi & jurnal berhasil disimpan.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan presensi: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildSummaryCard() {
    int total = _students.length;
    int present = 0;
    int permission = 0;
    int sick = 0;
    int absent = 0;
    int unassigned = 0;

    for (var s in _students) {
      final status = _attendanceMap[s.id];
      if (status == AttendanceStatus.present) {
        present++;
      } else if (status == AttendanceStatus.permission) {
        permission++;
      } else if (status == AttendanceStatus.sick) {
        sick++;
      } else if (status == AttendanceStatus.absent) {
        absent++;
      } else {
        unassigned++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ringkasan Presensi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Total: $total Siswa',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Row(
            children: [
              _buildSummaryPill('Hadir', present, AppTheme.success, AppTheme.successSurface),
              const SizedBox(width: AppTheme.space8),
              _buildSummaryPill('Izin', permission, AppTheme.info, AppTheme.infoSurface),
              const SizedBox(width: AppTheme.space8),
              _buildSummaryPill('Sakit', sick, AppTheme.warning, AppTheme.warningSurface),
              const SizedBox(width: AppTheme.space8),
              _buildSummaryPill('Alpa', absent, AppTheme.error, AppTheme.errorSurface),
              const SizedBox(width: AppTheme.space8),
              _buildSummaryPill(
                'Belum',
                unassigned,
                unassigned > 0 ? AppTheme.error : AppTheme.textMuted,
                unassigned > 0 ? AppTheme.errorSurface : AppTheme.surfaceMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPill(String label, int count, Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Presensi Siswa')),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_activeSchedule == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Presensi Siswa')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.event_busy_outlined, size: 54, color: AppTheme.textMuted),
                SizedBox(height: AppTheme.space16),
                Text(
                  'Tidak ada jadwal mengajar aktif hari ini',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                SizedBox(height: 8),
                Text(
                  'Silakan buat atau pilih jadwal mengajar untuk melakukan presensi siswa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final sessionStatus = _activeSchedule!.getStatus(_currentTime);
    final isLocked = _isSessionLocked || sessionStatus == SessionState.closed;
    final isUpcoming = sessionStatus == SessionState.locked;

    final filteredStudents = _students.where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(q) || s.studentCode.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Presensi Pembelajaran'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Session Header Card
              Container(
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLocked
                                ? AppTheme.surfaceMuted
                                : isUpcoming
                                    ? AppTheme.warningSurface
                                    : AppTheme.successSurface,
                            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          ),
                          child: Text(
                            isLocked
                                ? 'SESI SELESAI (READ-ONLY)'
                                : isUpcoming
                                    ? 'BELUM MULAI (TERKUNCI)'
                                    : 'SEDANG BERLANGSUNG',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isLocked
                                  ? AppTheme.textMuted
                                  : isUpcoming
                                      ? AppTheme.warning
                                      : AppTheme.success,
                            ),
                          ),
                        ),
                        Text(
                          'JP ${_activeSchedule!.periodStart}–${_activeSchedule!.periodEnd}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space12),
                    Text(
                      _activeSchedule!.subjectName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_activeSchedule!.className} • Ruang ${_activeSchedule!.room}',
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
                          '${_activeSchedule!.startTime} – ${_activeSchedule!.endTime}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (!isLocked && !isUpcoming)
                          Builder(builder: (_) {
                            final rem = _activeSchedule!.getRemainingDuration(_currentTime);
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
                          }),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space16),

              // Locked Warning Notice
              if (isLocked) ...[
                Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    color: AppTheme.infoSurface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                    border: Border.all(color: AppTheme.info),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: AppTheme.info, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Sesi pembelajaran telah selesai. Data presensi dan jurnal bersifat arsip/read-only.',
                          style: TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
              ],

              // Summary Breakdown
              _buildSummaryCard(),
              const SizedBox(height: AppTheme.space20),

              // Student Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari nama atau NIS siswa...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
              const SizedBox(height: AppTheme.space16),

              // Student Attendance List Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftar Presensi Siswa',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  Text(
                    '${filteredStudents.length} Siswa',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space12),

              if (filteredStudents.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.space24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Center(
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'Tidak ada siswa yang sesuai pencarian'
                          : 'Belum ada data siswa untuk kelas ini. Hubungi admin sekolah.',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ),
                ),
              ] else ...[
                ...filteredStudents.map((student) {
                  final currentStatus = _attendanceMap[student.id];

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppTheme.space12),
                    padding: const EdgeInsets.all(AppTheme.space16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(
                        color: currentStatus != null ? currentStatus.color.withValues(alpha: 0.5) : AppTheme.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppTheme.surfaceMuted,
                              child: Text(
                                student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.space12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${student.studentCode} • ${student.gender == 'male' ? 'Laki-laki' : 'Perempuan'}',
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
                        const SizedBox(height: AppTheme.space12),

                        // Status Selection Buttons (Hadir, Izin, Sakit, Alpa)
                        Row(
                          children: AttendanceStatus.values.map((status) {
                            final isSelected = currentStatus == status;
                            return Expanded(
                              child: Container(
                                height: 40,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: isSelected ? status.color : AppTheme.surface,
                                    foregroundColor: isSelected ? Colors.white : status.color,
                                    side: BorderSide(
                                      color: isSelected ? status.color : AppTheme.borderStrong,
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                                    ),
                                  ),
                                  onPressed: (isLocked || isUpcoming)
                                      ? null
                                      : () {
                                          setState(() {
                                            _attendanceMap[student.id] = status;
                                          });
                                        },
                                  child: Text(
                                    status.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: AppTheme.space24),

              // Optional Journal Section
              Container(
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Jurnal Pembelajaran',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '(Opsional)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space12),

                    const Text(
                      'Materi / Topik Pembelajaran',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    TextFormField(
                      controller: _materiController,
                      enabled: !isLocked && !isUpcoming,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Persamaan Kuadrat & Penerapannya',
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),

                    const Text(
                      'Catatan Kejadian / Catatan Khusus',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    TextFormField(
                      controller: _notesController,
                      enabled: !isLocked && !isUpcoming,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Siswa A izin pulang lebih awal pada jam ke-2...',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space24),

              // Actions: Simpan Draf & Selesaikan Sesi
              if (!isLocked && !isUpcoming) ...[
                ElevatedButton(
                  onPressed: _isSaving ? null : () => _handleSaveAttendance(markCompleted: false),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Simpan Presensi'),
                ),
                const SizedBox(height: AppTheme.space12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.success,
                    side: const BorderSide(color: AppTheme.success),
                  ),
                  onPressed: _isSaving ? null : () => _handleSaveAttendance(markCompleted: true),
                  child: const Text('Selesaikan & Kunci Sesi Ini'),
                ),
                const SizedBox(height: AppTheme.space24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
