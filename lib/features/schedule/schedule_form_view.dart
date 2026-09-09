import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../core/utils/period_helper.dart';
import '../../data/models/class_model.dart';
import '../../data/models/schedule_model.dart';
import '../../data/models/subject_model.dart';
import '../../data/repositories/schedule_repository.dart';
import 'schedule_contract.dart';
import 'schedule_presenter.dart';
import 'widgets/jp_selector_grid.dart';

class ScheduleFormView extends StatefulWidget {
  final ScheduleModel? existingSchedule;

  const ScheduleFormView({super.key, this.existingSchedule});

  @override
  State<ScheduleFormView> createState() => _ScheduleFormViewState();
}

class _ScheduleFormViewState extends State<ScheduleFormView>
    implements ScheduleFormViewContract {
  late final SchedulePresenter _presenter;

  final _formKey = GlobalKey<FormState>();
  final _roomController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  List<ClassModel> _classes = [];
  List<SubjectModel> _subjects = [];

  String? _selectedClassId;
  String? _selectedSubjectId;
  int _selectedDayOfWeek = 1; // 1 = Senin
  int _selectedStartPeriod = 1;
  int _selectedEndPeriod = 2;

  Set<int> _occupiedPeriods = {};

  @override
  void initState() {
    super.initState();
    _presenter = SchedulePresenter();
    _presenter.attachView(this);

    if (widget.existingSchedule != null) {
      final s = widget.existingSchedule!;
      _selectedClassId = s.classId;
      _selectedSubjectId = s.subjectId;
      _selectedDayOfWeek = s.dayOfWeek;
      _selectedStartPeriod = s.periodStart;
      _selectedEndPeriod = s.periodEnd;
      _roomController.text = s.room;
    }

    _presenter.loadFormData();
  }

  @override
  void dispose() {
    _presenter.detachView();
    _roomController.dispose();
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Informasi Jadwal'),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
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
  void updateFormData({
    required List<ClassModel> classes,
    required List<SubjectModel> subjects,
  }) {
    if (!mounted) return;
    setState(() {
      _classes = classes;
      _subjects = subjects;

      if (_selectedClassId == null && classes.isNotEmpty) {
        _selectedClassId = classes.first.id;
      }
      if (_selectedSubjectId == null && subjects.isNotEmpty) {
        _selectedSubjectId = subjects.first.id;
      }
    });

    _recalculateOccupiedPeriods();
  }

  @override
  void updateOccupiedPeriods(OccupiedPeriodsResult occupiedResult) {
    if (!mounted) return;
    setState(() {
      _occupiedPeriods = occupiedResult.occupiedPeriods;

      // Auto-adjust selected JP if it lands on occupied slots
      if (_occupiedPeriods.contains(_selectedStartPeriod) ||
          _occupiedPeriods.contains(_selectedEndPeriod)) {
        for (int p = 1; p <= 10; p++) {
          if (!_occupiedPeriods.contains(p)) {
            _selectedStartPeriod = p;
            _selectedEndPeriod = p;
            break;
          }
        }
      }
    });
  }

  @override
  void onScheduleSaved() {
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _recalculateOccupiedPeriods() {
    if (_selectedClassId == null) return;
    _presenter.computeOccupiedPeriods(
      classId: _selectedClassId!,
      dayOfWeek: _selectedDayOfWeek,
      excludeScheduleId: widget.existingSchedule?.id,
    );
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null || _selectedSubjectId == null) {
      showError('Pilih kelas dan mata pelajaran');
      return;
    }

    _presenter.saveSchedule(
      id: widget.existingSchedule?.id,
      classId: _selectedClassId!,
      subjectId: _selectedSubjectId!,
      dayOfWeek: _selectedDayOfWeek,
      periodStart: _selectedStartPeriod,
      periodEnd: _selectedEndPeriod,
      room: _roomController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingSchedule != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Jadwal Mengajar' : 'Tambah Jadwal Mengajar'),
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Pilihan Hari
                        const Text(
                          'Hari Mengajar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(5, (index) {
                              final dayNum = index + 1; // Senin s/d Jumat
                              final isSelected = _selectedDayOfWeek == dayNum;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(PeriodHelper.getDayName(dayNum)),
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
                                    color: isSelected
                                        ? AppTheme.primary
                                        : AppTheme.border,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusButton,
                                    ),
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(
                                        () => _selectedDayOfWeek = dayNum,
                                      );
                                      _recalculateOccupiedPeriods();
                                    }
                                  },
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: AppTheme.space20),

                        // Dropdown Kelas
                        const Text(
                          'Pilih Kelas',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedClassId,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(
                              Icons.meeting_room_outlined,
                              size: 20,
                            ),
                          ),
                          items: _classes.map((cls) {
                            return DropdownMenuItem<String>(
                              value: cls.id,
                              child: Text(cls.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedClassId = val);
                              _recalculateOccupiedPeriods();
                            }
                          },
                          validator: (val) =>
                              val == null ? 'Pilih kelas' : null,
                        ),
                        const SizedBox(height: AppTheme.space16),

                        // Dropdown Mapel
                        const Text(
                          'Pilih Mata Pelajaran',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedSubjectId,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.book_outlined, size: 20),
                          ),
                          items: _subjects.map((sub) {
                            return DropdownMenuItem<String>(
                              value: sub.id,
                              child: Text(sub.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedSubjectId = val);
                            }
                          },
                          validator: (val) =>
                              val == null ? 'Pilih mata pelajaran' : null,
                        ),
                        const SizedBox(height: AppTheme.space16),

                        // Input Ruangan (Opsional)
                        const Text(
                          'Ruangan (Opsional)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space6),
                        TextFormField(
                          controller: _roomController,
                          decoration: const InputDecoration(
                            hintText: 'mis. Lab Komputer 1 / Ruang 10A',
                            prefixIcon: Icon(
                              Icons.location_on_outlined,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.space20),

                        // Grid Pemilihan JP
                        JpSelectorGrid(
                          dayOfWeek: _selectedDayOfWeek,
                          selectedStart: _selectedStartPeriod,
                          selectedEnd: _selectedEndPeriod,
                          occupiedPeriods: _occupiedPeriods,
                          onRangeSelected: (start, end) {
                            setState(() {
                              _selectedStartPeriod = start;
                              _selectedEndPeriod = end;
                            });
                          },
                        ),
                        const SizedBox(height: AppTheme.space16),

                        // Dropdown Mulai & Selesai JP untuk fine-tuning
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'JP Mulai',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  DropdownButtonFormField<int>(
                                    initialValue: _selectedStartPeriod,
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    items: List.generate(10, (i) => i + 1).map((
                                      p,
                                    ) {
                                      final isOccupied = _occupiedPeriods
                                          .contains(p);
                                      return DropdownMenuItem<int>(
                                        value: p,
                                        enabled: !isOccupied,
                                        child: Text(
                                          'JP $p ${isOccupied ? "(Terisi)" : ""}',
                                          style: TextStyle(
                                            color: isOccupied
                                                ? AppTheme.textMuted
                                                : AppTheme.textPrimary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedStartPeriod = val;
                                          if (_selectedEndPeriod < val) {
                                            _selectedEndPeriod = val;
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'JP Selesai',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  DropdownButtonFormField<int>(
                                    initialValue: _selectedEndPeriod,
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    items: List.generate(10, (i) => i + 1).map((
                                      p,
                                    ) {
                                      final isOccupied = _occupiedPeriods
                                          .contains(p);
                                      return DropdownMenuItem<int>(
                                        value: p,
                                        enabled: !isOccupied,
                                        child: Text(
                                          'JP $p ${isOccupied ? "(Terisi)" : ""}',
                                          style: TextStyle(
                                            color: isOccupied
                                                ? AppTheme.textMuted
                                                : AppTheme.textPrimary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedEndPeriod = val;
                                          if (_selectedStartPeriod > val) {
                                            _selectedStartPeriod = val;
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.space32),

                        // Tombol Simpan
                        ElevatedButton(
                          onPressed: _isSaving ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.space16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusButton,
                              ),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  isEdit
                                      ? 'Simpan Perubahan Jadwal'
                                      : 'Simpan Jadwal Baru',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
