import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../core/utils/period_helper.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/realtime_ticker_builder.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/journal_model.dart';
import '../../data/models/schedule_model.dart';
import '../../data/models/student_model.dart';
import 'attendance_contract.dart';
import 'attendance_presenter.dart';
import 'widgets/attendance_summary_card.dart';
import 'widgets/journal_bottom_sheet.dart';
import 'widgets/student_attendance_tile.dart';

class AttendanceView extends StatefulWidget {
  final ScheduleModel? schedule;

  const AttendanceView({super.key, this.schedule});

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView>
    implements AttendanceViewContract {
  late final AttendancePresenter _presenter;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLocked = false;

  ScheduleModel? _activeSchedule;
  List<ScheduleModel> _availableSchedules = [];
  List<StudentModel> _students = [];
  Map<String, AttendanceStatus> _attendanceMap = {};
  JournalModel? _journal;
  String _searchQuery = '';

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _presenter = AttendancePresenter();
    _presenter.attachView(this);
    _presenter.loadSessionData(schedule: widget.schedule);
  }

  @override
  void dispose() {
    _presenter.detachView();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void showLoading() => setState(() => _isLoading = true);

  @override
  void hideLoading() {
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void showSaving() => setState(() => _isSaving = true);

  @override
  void hideSaving() {
    if (mounted) setState(() => _isSaving = false);
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
  void updateSessionData({
    required ScheduleModel activeSchedule,
    required List<ScheduleModel> availableSchedules,
    required List<StudentModel> students,
    required Map<String, AttendanceStatus> attendanceMap,
    required JournalModel? journal,
    required bool isLocked,
  }) {
    if (!mounted) return;
    setState(() {
      _activeSchedule = activeSchedule;
      _availableSchedules = availableSchedules;
      _students = students;
      _attendanceMap = Map.from(attendanceMap);
      _journal = journal;
      _isLocked = isLocked;
    });
  }

  @override
  void updateStudentStatus(String studentId, AttendanceStatus status) {
    if (!mounted) return;
    setState(() {
      _attendanceMap[studentId] = status;
    });
  }

  @override
  void onAttendanceSaved() {
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  void showIncompleteWarning(int unfilledCount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Presensi Belum Lengkap'),
        content: Text(
          'Masih ada $unfilledCount siswa yang belum memiliki status kehadiran.\n\nSesuai aturan sekolah, seluruh siswa harus diberi status (Hadir/Izin/Sakit/Alpa) sebelum presensi dapat diselesaikan.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Lengkapi Presensi'),
          ),
        ],
      ),
    );
  }

  void _openJournalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JournalBottomSheet(
        existingJournal: _journal,
        isLocked: _isLocked,
        onSave: (material, notes) {
          _presenter.saveJournal(material: material, notes: notes);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = _students.where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(q) ||
          s.studentCode.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Presensi Pembelajaran'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Jurnal Mengajar',
            onPressed: _openJournalSheet,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeSchedule == null || _activeSchedule!.id.isEmpty
          ? const EmptyStateView(
              icon: Icons.event_busy,
              title: 'Tidak Ada Sesi Aktif',
              message:
                  'Tidak ada sesi mengajar yang aktif atau terdaftar untuk hari ini.',
            )
          : Column(
              children: [
                // Header Info Sesi & Ticker Countdown Terisolasi
                Container(
                  color: AppTheme.surface,
                  padding: const EdgeInsets.all(AppTheme.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dropdown Pemilihan Sesi (Jika ada lebih dari 1 sesi hari ini)
                      if (_availableSchedules.length > 1) ...[
                        DropdownButtonFormField<String>(
                          initialValue: _activeSchedule!.id,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            prefixIcon: Icon(Icons.school_outlined, size: 18),
                          ),
                          items: _availableSchedules.map((s) {
                            return DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                '${s.className} - ${s.subjectName} (${s.startTime})',
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              final selected = _availableSchedules.firstWhere(
                                (s) => s.id == val,
                              );
                              _presenter.loadSessionData(schedule: selected);
                            }
                          },
                        ),
                        const SizedBox(height: AppTheme.space12),
                      ],

                      RealtimeTickerBuilder(
                        builder: (context, now) {
                          final status = _activeSchedule!.getStatus(now);
                          final remaining = _activeSchedule!
                              .getRemainingDuration(now);

                          Color statusBg;
                          Color statusColor;
                          String statusText;

                          if (status == SessionState.open) {
                            statusBg = AppTheme.successSurface;
                            statusColor = AppTheme.success;
                            statusText = 'SESI SEDANG BERLANGSUNG';
                          } else if (status == SessionState.locked) {
                            statusBg = AppTheme.primaryLight;
                            statusColor = AppTheme.primary;
                            statusText = 'SESI BELUM DIMULAI (LOCKED)';
                          } else {
                            statusBg = AppTheme.background;
                            statusColor = AppTheme.textMuted;
                            statusText = 'SESI BERAKHIR (CLOSED)';
                          }

                          final remMin = remaining.inMinutes;
                          final remSec = remaining.inSeconds % 60;
                          final countdownStr =
                              '${remMin.toString().padLeft(2, "0")}:${remSec.toString().padLeft(2, "0")}';

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _activeSchedule!.subjectName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_activeSchedule!.className} • ${PeriodHelper.formatPeriodRange(_activeSchedule!.dayOfWeek, _activeSchedule!.periodStart, _activeSchedule!.periodEnd)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusBadge,
                                      ),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                  if (status == SessionState.open) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sisa waktu: $countdownStr',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.error,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppTheme.space12),

                      // Kartu Rekap Status Presensi
                      AttendanceSummaryCard(
                        attendanceMap: _attendanceMap,
                        totalStudents: _students.length,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.border),

                // Bar Pencarian & Tombol Tandai Semua Hadir
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space16,
                    vertical: AppTheme.space10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Cari nama atau NIS siswa...',
                            prefixIcon: Icon(Icons.search, size: 18),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                          ),
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                        ),
                      ),
                      if (!_isLocked) ...[
                        const SizedBox(width: AppTheme.space8),
                        OutlinedButton.icon(
                          onPressed: () => _presenter.markAllPresent(),
                          icon: const Icon(Icons.done_all, size: 16),
                          label: const Text(
                            'Semua Hadir',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.success,
                            side: const BorderSide(color: AppTheme.success),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusButton,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Daftar Siswa
                Expanded(
                  child: filteredStudents.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada siswa yang sesuai.',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space16,
                          ),
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = filteredStudents[index];
                            final status = _attendanceMap[student.id];

                            return StudentAttendanceTile(
                              index: index + 1,
                              student: student,
                              status: status,
                              isLocked: _isLocked,
                              onStatusChanged: (newStatus) {
                                _presenter.setStudentStatus(
                                  student.id,
                                  newStatus,
                                );
                              },
                            );
                          },
                        ),
                ),

                // Bottom Bar Tombol Simpan
                Container(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(top: BorderSide(color: AppTheme.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openJournalSheet,
                          icon: const Icon(Icons.note_alt_outlined, size: 18),
                          label: Text(
                            _journal != null
                                ? 'Edit Jurnal'
                                : 'Jurnal',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.space14,
                            ),
                            side: const BorderSide(color: AppTheme.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusButton,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: (_isSaving || _isLocked)
                              ? null
                              : () => _presenter.saveAttendance(),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check, size: 18),
                          label: Text(
                            _isLocked
                                ? 'Sesi Terkunci / Selesai'
                                : 'Simpan Presensi',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.space14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusButton,
                              ),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
