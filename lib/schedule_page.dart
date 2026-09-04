import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';

enum SessionState {
  locked,
  open,
  closed,
}

class TeacherSchedule {
  final String id;
  final String teacherId;
  final String classId;
  final String className;
  final String subjectId;
  final String subjectName;
  final String room;
  final int dayOfWeek; // 1 = Senin ... 7 = Minggu
  final int periodStart;
  final int periodEnd;
  final String startTime; // "07:00"
  final String endTime; // "08:30"
  final int studentCount;
  final bool isCompletedToday;
  final bool isLocked;

  const TeacherSchedule({
    required this.id,
    required this.teacherId,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    required this.room,
    required this.dayOfWeek,
    required this.periodStart,
    required this.periodEnd,
    required this.startTime,
    required this.endTime,
    this.studentCount = 0,
    this.isCompletedToday = false,
    this.isLocked = false,
  });

  SessionState getStatus(DateTime now) {
    if (isCompletedToday || isLocked) {
      return SessionState.closed;
    }
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    if (startParts.length < 2 || endParts.length < 2) return SessionState.locked;

    final startDt = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );
    final endDt = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );

    if (now.isBefore(startDt)) {
      return SessionState.locked;
    } else if (now.isAfter(endDt)) {
      return SessionState.closed;
    } else {
      return SessionState.open;
    }
  }

  Duration getRemainingDuration(DateTime now) {
    final endParts = endTime.split(':');
    if (endParts.length < 2) return Duration.zero;
    final endDt = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );
    final diff = endDt.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }
}

class SchoolPeriodHelper {
  // Default durations per day (Senin s/d Jumat):
  static Map<int, int> periodDurations = {
    1: 45, // Senin
    2: 30, // Selasa
    3: 30, // Rabu
    4: 30, // Kamis
    5: 40, // Jumat
  };

  static Map<String, String> calculateTimes({
    required int dayOfWeek,
    required int startPeriod,
    required int endPeriod,
    int? customDurationMinutes,
  }) {
    final duration = customDurationMinutes ?? periodDurations[dayOfWeek] ?? 45;
    const baseHour = 7;
    const baseMinute = 0;

    final startMinutesOffset = (startPeriod - 1) * duration;
    final totalStartMinutes = baseHour * 60 + baseMinute + startMinutesOffset;
    final startH = (totalStartMinutes ~/ 60) % 24;
    final startM = totalStartMinutes % 60;

    final endMinutesOffset = endPeriod * duration;
    final totalEndMinutes = baseHour * 60 + baseMinute + endMinutesOffset;
    final endH = (totalEndMinutes ~/ 60) % 24;
    final endM = totalEndMinutes % 60;

    final startStr =
        '${startH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')}';
    final endStr =
        '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';

    return {
      'startTime': startStr,
      'endTime': endStr,
      'periodDuration': '$duration',
      'totalDuration': '${(endPeriod - startPeriod + 1) * duration}',
    };
  }
}

class SchedulePage extends StatefulWidget {
  final Function(TeacherSchedule schedule)? onStartAttendance;

  const SchedulePage({super.key, this.onStartAttendance});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late int _selectedDay;
  bool _isLoading = true;
  String? _teacherId;

  List<TeacherSchedule> _allSchedules = [];

  // Operasional sekolah: 5 hari kerja (Senin s/d Jumat)
  final List<String> _days = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'
  ];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().weekday;
    _selectedDay = today > 5 ? 1 : today;
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 1. Fetch teacher record
      final teacherRes = await supabase
          .from('teachers')
          .select('id')
          .eq('profile_id', user.id)
          .maybeSingle();

      if (teacherRes != null) {
        _teacherId = teacherRes['id'] as String?;
      }

      if (_teacherId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 2. Fetch teacher schedules
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
          .order('period_start');

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
        final dayOfWeek = item['day_of_week'] as int? ?? 1;
        final periodStart = item['period_start'] as int? ?? 1;
        final periodEnd = item['period_end'] as int? ?? 2;

        final rawStart = item['start_time'] as String? ?? '07:00:00';
        final rawEnd = item['end_time'] as String? ?? '08:30:00';
        final startTime = rawStart.length >= 5 ? rawStart.substring(0, 5) : rawStart;
        final endTime = rawEnd.length >= 5 ? rawEnd.substring(0, 5) : rawEnd;

        // Count students
        int studentCount = 0;
        if (classId.isNotEmpty) {
          final countRes = await supabase
              .from('students')
              .select('id')
              .eq('class_id', classId);
          studentCount = countRes.length;
        }

        list.add(TeacherSchedule(
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
        ));
      }

      if (mounted) {
        setState(() {
          _allSchedules = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openScheduleFormModal({TeacherSchedule? existingSchedule}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ScheduleFormModal(
        teacherId: _teacherId ?? '',
        existingSchedule: existingSchedule,
        initialDayOfWeek: _selectedDay,
        onSaved: () {
          _loadSchedules();
        },
      ),
    );
  }

  Future<void> _handleDeleteSchedule(TeacherSchedule schedule) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusDialog)),
        title: const Text(
          'Hapus Jadwal',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus jadwal ${schedule.subjectName} (${schedule.className}) pada hari ${_days[schedule.dayOfWeek - 1]}?\n\nCatatan: Riwayat sesi presensi yang telah selesai tidak akan terhapus.',
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(90, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusButton)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('schedules').delete().eq('id', schedule.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal berhasil dihapus.'),
          backgroundColor: AppTheme.success,
        ),
      );
      _loadSchedules();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menghapus jadwal. Silakan coba lagi.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredSchedules = _allSchedules.where((s) => s.dayOfWeek == _selectedDay).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header & Add Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Jadwal Mengajar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(130, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () => _openScheduleFormModal(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah Jadwal'),
                  ),
                ],
              ),
            ),

            // Day Selector Chips (Horizontal Scroll)
            Container(
              height: 44,
              margin: const EdgeInsets.only(bottom: AppTheme.space16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
                itemCount: _days.length,
                itemBuilder: (context, index) {
                  final dayIndex = index + 1;
                  final isSelected = _selectedDay == dayIndex;
                  final countForDay = _allSchedules.where((s) => s.dayOfWeek == dayIndex).length;

                  return Container(
                    margin: const EdgeInsets.only(right: AppTheme.space8),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text(
                        '${_days[index]} ($countForDay)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                      selectedColor: AppTheme.primary,
                      backgroundColor: AppTheme.surface,
                      side: BorderSide(
                        color: isSelected ? AppTheme.primary : AppTheme.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      ),
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedDay = dayIndex);
                        }
                      },
                    ),
                  );
                },
              ),
            ),

            // Schedules List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : filteredSchedules.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.space32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.event_note_outlined, size: 54, color: AppTheme.textMuted),
                                const SizedBox(height: AppTheme.space16),
                                Text(
                                  'Belum ada jadwal pada hari ${_days[_selectedDay - 1]}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.space8),
                                const Text(
                                  'Klik tombol "Tambah Jadwal" di atas untuk menambahkan jadwal mengajar baru.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space8),
                          itemCount: filteredSchedules.length,
                          itemBuilder: (context, index) {
                            final schedule = filteredSchedules[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: AppTheme.space12),
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
                                          color: AppTheme.primarySurface,
                                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                                        ),
                                        child: Text(
                                          'JP ${schedule.periodStart}–${schedule.periodEnd}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.primaryDark,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.textSecondary),
                                            tooltip: 'Edit Jadwal',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _openScheduleFormModal(existingSchedule: schedule),
                                          ),
                                          const SizedBox(width: AppTheme.space12),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                                            tooltip: 'Hapus Jadwal',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _handleDeleteSchedule(schedule),
                                          ),
                                        ],
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
                                    '${schedule.className} • Ruang ${schedule.room} • ${schedule.studentCount} Siswa',
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
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (widget.onStartAttendance != null &&
                                          schedule.dayOfWeek == DateTime.now().weekday)
                                        TextButton(
                                          onPressed: () => widget.onStartAttendance!(schedule),
                                          child: const Text('Presensi Hari Ini'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleFormModal extends StatefulWidget {
  final String teacherId;
  final TeacherSchedule? existingSchedule;
  final int initialDayOfWeek;
  final VoidCallback onSaved;

  const _ScheduleFormModal({
    required this.teacherId,
    this.existingSchedule,
    required this.initialDayOfWeek,
    required this.onSaved,
  });

  @override
  State<_ScheduleFormModal> createState() => _ScheduleFormModalState();
}

class _ScheduleFormModalState extends State<_ScheduleFormModal> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;

  String? _selectedSubjectId;
  String? _selectedClassId;
  late int _selectedDayOfWeek;
  final _roomController = TextEditingController(text: 'Ruang Kelas');

  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _classes = [];

  // JP availability tracking
  Set<int> _occupiedPeriods = {};
  int _selectedStartPeriod = 1;
  int _selectedEndPeriod = 2;
  static const int _maxPeriods = 10;

  @override
  void initState() {
    super.initState();
    final initialDay = widget.existingSchedule?.dayOfWeek ?? widget.initialDayOfWeek;
    _selectedDayOfWeek = initialDay > 5 ? 1 : initialDay;
    if (widget.existingSchedule != null) {
      _selectedSubjectId = widget.existingSchedule!.subjectId;
      _selectedClassId = widget.existingSchedule!.classId;
      _selectedStartPeriod = widget.existingSchedule!.periodStart;
      _selectedEndPeriod = widget.existingSchedule!.periodEnd;
      _roomController.text = widget.existingSchedule!.room;
    }
    _loadFormData();
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // 1. Fetch teacher's assigned subjects or all subjects
      final teacherRes = await supabase
          .from('teachers')
          .select('subject_ids')
          .eq('id', widget.teacherId)
          .maybeSingle();

      List<String> teacherSubjectIds = [];
      if (teacherRes != null && teacherRes['subject_ids'] is List) {
        for (var s in teacherRes['subject_ids']) {
          if (s != null) teacherSubjectIds.add(s.toString());
        }
      }

      final subjectsData = await supabase.from('subjects').select('id, name, code').order('name');
      final List<Map<String, dynamic>> subjList = [];
      for (var row in subjectsData) {
        final id = row['id'] as String;
        // Prioritize teacher subjects if specified
        if (teacherSubjectIds.isEmpty || teacherSubjectIds.contains(id)) {
          subjList.add(row);
        }
      }
      if (subjList.isEmpty && subjectsData.isNotEmpty) {
        subjList.addAll(subjectsData);
      }

      // 2. Fetch classes
      final classesData = await supabase.from('classes').select('id, name, grade').order('name');

      _subjects = subjList;
      _classes = classesData;

      if (_selectedSubjectId == null && _subjects.isNotEmpty) {
        _selectedSubjectId = _subjects.first['id'] as String;
      }
      if (_selectedClassId == null && _classes.isNotEmpty) {
        _selectedClassId = _classes.first['id'] as String;
      }

      // 3. Compute occupied JP for current (class_id + day_of_week)
      await _computeOccupiedPeriods();
    } catch (_) {
      // Continue
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _computeOccupiedPeriods() async {
    if (_selectedClassId == null) return;

    try {
      final supabase = Supabase.instance.client;
      var query = supabase
          .from('schedules')
          .select('id, period_start, period_end')
          .eq('class_id', _selectedClassId!)
          .eq('day_of_week', _selectedDayOfWeek);

      if (widget.existingSchedule != null) {
        query = query.neq('id', widget.existingSchedule!.id);
      }

      final schedulesData = await query;
      final Set<int> occupied = {};
      for (var row in schedulesData) {
        final pStart = row['period_start'] as int? ?? 1;
        final pEnd = row['period_end'] as int? ?? 1;
        for (int p = pStart; p <= pEnd; p++) {
          occupied.add(p);
        }
      }

      if (mounted) {
        setState(() {
          _occupiedPeriods = occupied;
          // Ensure default selected periods are valid and consecutive
          if (_occupiedPeriods.contains(_selectedStartPeriod) || _occupiedPeriods.contains(_selectedEndPeriod)) {
            // Find first free slot
            for (int p = 1; p < _maxPeriods; p++) {
              if (!_occupiedPeriods.contains(p) && !_occupiedPeriods.contains(p + 1)) {
                _selectedStartPeriod = p;
                _selectedEndPeriod = p + 1;
                break;
              }
            }
          }
        });
      }
    } catch (_) {}
  }

  bool _isRangeValid(int start, int end) {
    if (start > end) return false;
    for (int p = start; p <= end; p++) {
      if (_occupiedPeriods.contains(p)) return false;
    }
    return true;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSubjectId == null || _selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih mata pelajaran dan kelas.'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    if (_selectedDayOfWeek < 1 || _selectedDayOfWeek > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal pembelajaran hanya dapat dibuat untuk hari operasional (Senin - Jumat).'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    if (!_isRangeValid(_selectedStartPeriod, _selectedEndPeriod)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal tidak dapat disimpan. JP yang dipilih sudah digunakan oleh jadwal lain pada kelas tersebut.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;

      // Double-check conflict in database using stored function or query
      final conflictRes = await supabase.rpc(
        'check_schedule_conflict',
        params: {
          'p_schedule_id': widget.existingSchedule?.id,
          'p_class_id': _selectedClassId,
          'p_day_of_week': _selectedDayOfWeek,
          'p_period_start': _selectedStartPeriod,
          'p_period_end': _selectedEndPeriod,
        },
      );

      if (conflictRes == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jadwal tidak dapat disimpan. JP yang dipilih sudah digunakan oleh jadwal lain pada kelas tersebut.'),
            backgroundColor: AppTheme.error,
          ),
        );
        setState(() => _isSaving = false);
        return;
      }

      // Calculate start and end times from school period config
      final times = SchoolPeriodHelper.calculateTimes(
        dayOfWeek: _selectedDayOfWeek,
        startPeriod: _selectedStartPeriod,
        endPeriod: _selectedEndPeriod,
      );

      final payload = {
        'teacher_id': widget.teacherId,
        'class_id': _selectedClassId,
        'subject_id': _selectedSubjectId,
        'day_of_week': _selectedDayOfWeek,
        'period_start': _selectedStartPeriod,
        'period_end': _selectedEndPeriod,
        'start_time': '${times['startTime']!}:00',
        'end_time': '${times['endTime']!}:00',
        'room': _roomController.text.trim().isNotEmpty ? _roomController.text.trim() : 'Ruang Kelas',
      };

      if (widget.existingSchedule != null) {
        await supabase.from('schedules').update(payload).eq('id', widget.existingSchedule!.id);
      } else {
        await supabase.from('schedules').insert(payload);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingSchedule != null ? 'Jadwal berhasil diperbarui.' : 'Jadwal berhasil dibuat.'),
          backgroundColor: AppTheme.success,
        ),
      );

      widget.onSaved();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan jadwal: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final times = SchoolPeriodHelper.calculateTimes(
      dayOfWeek: _selectedDayOfWeek,
      startPeriod: _selectedStartPeriod,
      endPeriod: _selectedEndPeriod,
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusSheet)),
      ),
      padding: EdgeInsets.only(
        top: AppTheme.space20,
        left: AppTheme.space20,
        right: AppTheme.space20,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.space20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sheet Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.existingSchedule != null ? 'Edit Jadwal Mengajar' : 'Tambah Jadwal Mengajar',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.textMuted),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.border),
                    const SizedBox(height: AppTheme.space16),

                    // Subject Dropdown
                    const Text(
                      'Mata Pelajaran',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSubjectId,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.menu_book_outlined, color: AppTheme.textMuted, size: 20),
                      ),
                      items: _subjects.map((s) {
                        return DropdownMenuItem<String>(
                          value: s['id'] as String,
                          child: Text(s['name'] as String),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedSubjectId = val),
                    ),
                    const SizedBox(height: AppTheme.space16),

                    // Class Dropdown
                    const Text(
                      'Kelas',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedClassId,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.class_outlined, color: AppTheme.textMuted, size: 20),
                      ),
                      items: _classes.map((c) {
                        return DropdownMenuItem<String>(
                          value: c['id'] as String,
                          child: Text('${c['name']} (${c['grade']})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedClassId = val);
                        _computeOccupiedPeriods();
                      },
                    ),
                    const SizedBox(height: AppTheme.space16),

                    // Day Selector
                    const Text(
                      'Hari',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedDayOfWeek,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.calendar_today_outlined, color: AppTheme.textMuted, size: 20),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Senin')),
                        DropdownMenuItem(value: 2, child: Text('Selasa')),
                        DropdownMenuItem(value: 3, child: Text('Rabu')),
                        DropdownMenuItem(value: 4, child: Text('Kamis')),
                        DropdownMenuItem(value: 5, child: Text('Jumat')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedDayOfWeek = val);
                          _computeOccupiedPeriods();
                        }
                      },
                    ),
                    const SizedBox(height: AppTheme.space20),

                    // JP Availability Engine Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pilih Jam Pelajaran (JP)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                        Text(
                          'Durasi: ${times['periodDuration']} m/JP',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space8),
                    const Text(
                      'JP yang telah digunakan oleh jadwal lain pada kelas ini akan dinonaktifkan.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: AppTheme.space12),

                    // JP Period Selector Grid
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Mulai Dari (JP Awal)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<int>(
                                      initialValue: _selectedStartPeriod,
                                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                      items: List.generate(_maxPeriods, (i) {
                                        final p = i + 1;
                                        final isOccupied = _occupiedPeriods.contains(p);
                                        return DropdownMenuItem<int>(
                                          value: p,
                                          enabled: !isOccupied,
                                          child: Text(
                                            'JP $p ${isOccupied ? "(Terpakai)" : ""}',
                                            style: TextStyle(
                                              color: isOccupied ? AppTheme.textDisabled : AppTheme.textPrimary,
                                            ),
                                          ),
                                        );
                                      }),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _selectedStartPeriod = val;
                                            if (_selectedEndPeriod < val) _selectedEndPeriod = val;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppTheme.space12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Sampai (JP Akhir)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<int>(
                                      initialValue: _selectedEndPeriod,
                                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                      items: List.generate(_maxPeriods, (i) {
                                        final p = i + 1;
                                        final isOccupied = _occupiedPeriods.contains(p);
                                        final isBeforeStart = p < _selectedStartPeriod;
                                        return DropdownMenuItem<int>(
                                          value: p,
                                          enabled: !isOccupied && !isBeforeStart,
                                          child: Text(
                                            'JP $p ${isOccupied ? "(Terpakai)" : ""}',
                                            style: TextStyle(
                                              color: (isOccupied || isBeforeStart) ? AppTheme.textDisabled : AppTheme.textPrimary,
                                            ),
                                          ),
                                        );
                                      }),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _selectedEndPeriod = val);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space12),
                          // Calculated Time Preview Card
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.primarySurface,
                              borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                              border: Border.all(color: AppTheme.primaryLight),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.schedule, size: 18, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Waktu Sesi: ${times['startTime']} – ${times['endTime']} (${times['totalDuration']} menit)',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),

                    // Room field
                    const Text(
                      'Ruangan / Lokasi',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    TextFormField(
                      controller: _roomController,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Lab Komputer 1 / Ruang XI PPLG',
                        prefixIcon: Icon(Icons.room_outlined, color: AppTheme.textMuted, size: 20),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(widget.existingSchedule != null ? 'Perbarui Jadwal' : 'Simpan Jadwal'),
                    ),
                    const SizedBox(height: AppTheme.space12),
                  ],
                ),
              ),
            ),
    );
  }
}
