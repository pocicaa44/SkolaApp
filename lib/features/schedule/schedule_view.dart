import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../core/utils/period_helper.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../data/models/schedule_model.dart';
import 'schedule_contract.dart';
import 'schedule_form_view.dart';
import 'schedule_presenter.dart';

class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView>
    implements ScheduleViewContract {
  late final SchedulePresenter _presenter;

  bool _isLoading = true;
  List<ScheduleModel> _schedules = [];
  int _selectedDayTab = 1; // 1 = Senin ... 5 = Jumat

  @override
  void initState() {
    super.initState();
    _presenter = SchedulePresenter();
    _presenter.attachView(this);
    _presenter.loadTeacherSchedules();
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
  void updateScheduleList(List<ScheduleModel> schedules) {
    if (!mounted) return;
    setState(() {
      _schedules = schedules;
    });
  }

  @override
  void onScheduleDeleted() {
    _presenter.loadTeacherSchedules();
  }

  void _navigateToAddSchedule() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ScheduleFormView()));
    if (result == true) {
      _presenter.loadTeacherSchedules();
    }
  }

  void _navigateToEditSchedule(ScheduleModel schedule) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScheduleFormView(existingSchedule: schedule),
      ),
    );
    if (result == true) {
      _presenter.loadTeacherSchedules();
    }
  }

  void _confirmDeleteSchedule(ScheduleModel schedule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Jadwal'),
        content: Text(
          'Apakah Anda yakin ingin menghapus jadwal ${schedule.subjectName} di kelas ${schedule.className}?\n\nData historis presensi dan jurnal yang sudah terlaksana tidak akan hilang.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _presenter.deleteSchedule(schedule.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredSchedules = _schedules
        .where((s) => s.dayOfWeek == _selectedDayTab)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Jadwal Mengajar'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primary),
            tooltip: 'Tambah Jadwal',
            onPressed: _navigateToAddSchedule,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
      ),
      body: Column(
        children: [
          // Filter Hari Tabs
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space16,
              vertical: AppTheme.space8,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(5, (index) {
                  final dayNum = index + 1;
                  final isSelected = _selectedDayTab == dayNum;
                  final dayCount = _schedules
                      .where((s) => s.dayOfWeek == dayNum)
                      .length;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        '${PeriodHelper.getDayName(dayNum)} ($dayCount)',
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryLight,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.textPrimary,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primary : AppTheme.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusButton,
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedDayTab = dayNum);
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),

          // Konten Jadwal
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _presenter.loadTeacherSchedules,
                    child: filteredSchedules.isEmpty
                        ? EmptyStateView(
                            icon: Icons.event_busy,
                            title: 'Belum Ada Jadwal',
                            message:
                                'Tidak ada jadwal mengajar pada hari ${PeriodHelper.getDayName(_selectedDayTab)}.',
                            actionLabel: 'Tambah Jadwal Hari Ini',
                            onAction: _navigateToAddSchedule,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(AppTheme.space16),
                            itemCount: filteredSchedules.length,
                            itemBuilder: (context, index) {
                              final s = filteredSchedules[index];
                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(
                                  bottom: AppTheme.space12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusCard,
                                  ),
                                  side: const BorderSide(
                                    color: AppTheme.border,
                                  ),
                                ),
                                color: AppTheme.surface,
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    AppTheme.space16,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppTheme.space8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryLight,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppTheme.radiusBadge,
                                                  ),
                                            ),
                                            child: Text(
                                              PeriodHelper.formatPeriodRange(
                                                s.dayOfWeek,
                                                s.periodStart,
                                                s.periodEnd,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.primary,
                                              ),
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: const Icon(
                                              Icons.more_vert,
                                              size: 18,
                                              color: AppTheme.textMuted,
                                            ),
                                            onSelected: (val) {
                                              if (val == 'edit') {
                                                _navigateToEditSchedule(s);
                                              } else if (val == 'delete') {
                                                _confirmDeleteSchedule(s);
                                              }
                                            },
                                            itemBuilder: (ctx) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.edit_outlined,
                                                      size: 16,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text('Edit Jadwal'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.delete_outline,
                                                      size: 16,
                                                      color: AppTheme.error,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Hapus Jadwal',
                                                      style: TextStyle(
                                                        color: AppTheme.error,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppTheme.space8),
                                      Text(
                                        s.subjectName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.meeting_room_outlined,
                                            size: 15,
                                            color: AppTheme.textMuted,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            s.className,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (s.room.isNotEmpty) ...[
                                            const SizedBox(width: 12),
                                            const Icon(
                                              Icons.location_on_outlined,
                                              size: 15,
                                              color: AppTheme.textMuted,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              s.room,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddSchedule,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Jadwal Baru'),
      ),
    );
  }
}
