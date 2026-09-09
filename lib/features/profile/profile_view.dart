import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../data/models/subject_model.dart';
import '../../data/models/teacher_model.dart';
import '../auth/login_view.dart';
import 'profile_contract.dart';
import 'profile_presenter.dart';
import 'widgets/subject_multiselect_dialog.dart';

class ProfileView extends StatefulWidget {
  final bool isInitialSetup;

  const ProfileView({super.key, this.isInitialSetup = false});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    implements ProfileViewContract {
  late final ProfilePresenter _presenter;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoggingOut = false;

  TeacherModel? _teacher;
  List<SubjectModel> _allSubjects = [];
  List<String> _selectedSubjectIds = [];

  @override
  void initState() {
    super.initState();
    _presenter = ProfilePresenter();
    _presenter.attachView(this);
    _presenter.loadProfile();
  }

  @override
  void dispose() {
    _presenter.detachView();
    _nameController.dispose();
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
  void showLoggingOut() => setState(() => _isLoggingOut = true);

  @override
  void hideLoggingOut() {
    if (mounted) setState(() => _isLoggingOut = false);
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
  void updateProfileData({
    required TeacherModel teacher,
    required List<SubjectModel> allSubjects,
    required List<String> selectedSubjectIds,
  }) {
    if (!mounted) return;
    setState(() {
      _teacher = teacher;
      _allSubjects = allSubjects;
      _selectedSubjectIds = selectedSubjectIds;
      if (_nameController.text.isEmpty) {
        _nameController.text = teacher.name;
      }
    });
  }

  @override
  void onProfileSaved() {
    if (widget.isInitialSetup) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  void onLoggedOut() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun Skola App?',
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
              _presenter.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _openSubjectSelector() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => SubjectMultiSelectDialog(
        allSubjects: _allSubjects,
        initialSelectedIds: _selectedSubjectIds,
        maxSelection: 2,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedSubjectIds = result;
      });
      _presenter.setSelectedSubjects(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Map selected subject models
    final selectedSubjectModels = _allSubjects
        .where((s) => _selectedSubjectIds.contains(s.id))
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Profil Pengajar'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          if (!widget.isInitialSetup)
            IconButton(
              icon: _isLoggingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout, color: AppTheme.error),
              tooltip: 'Keluar Akun',
              onPressed: (_isSaving || _isLoggingOut) ? null : _confirmLogout,
            ),
        ],
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
                        // Card Header Profil
                        Container(
                          padding: const EdgeInsets.all(AppTheme.space20),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusCard,
                            ),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: AppTheme.primaryLight,
                                child: Text(
                                  _nameController.text.isNotEmpty
                                      ? _nameController.text
                                            .substring(0, 1)
                                            .toUpperCase()
                                      : 'G',
                                  style: const TextStyle(
                                    fontSize: 24,
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
                                      _nameController.text.isNotEmpty
                                          ? _nameController.text
                                          : 'Guru',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _teacher?.email ?? '-',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppTheme.space8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryLight,
                                            borderRadius: BorderRadius.circular(
                                              AppTheme.radiusBadge,
                                            ),
                                          ),
                                          child: Text(
                                            _teacher?.teacherCode ?? 'GUR',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppTheme.space8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _teacher?.isActive == true
                                                ? AppTheme.successSurface
                                                : AppTheme.errorSurface,
                                            borderRadius: BorderRadius.circular(
                                              AppTheme.radiusBadge,
                                            ),
                                          ),
                                          child: Text(
                                            _teacher?.status ?? 'ACTIVE',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: _teacher?.isActive == true
                                                  ? AppTheme.success
                                                  : AppTheme.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.space20),

                        // Input Nama
                        const Text(
                          'Nama Lengkap',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space6),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'Nama lengkap beserta gelar',
                            prefixIcon: Icon(Icons.person_outline, size: 20),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Nama tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.space24),

                        // Pilihan Mata Pelajaran (Dropdown Checkbox dengan Konfirmasi)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Mata Pelajaran yang Diampu',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedSubjectIds.length > 2
                                    ? AppTheme.errorSurface
                                    : AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusBadge,
                                ),
                              ),
                              child: Text(
                                '${_selectedSubjectIds.length}/2 Terpilih',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _selectedSubjectIds.length > 2
                                      ? AppTheme.error
                                      : AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.space6),
                        const Text(
                          'Pilih maksimal 2 mata pelajaran yang Anda ajarkan di sekolah.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space10),

                        // Trigger Dropdown Checkbox Selector
                        InkWell(
                          onTap: _allSubjects.isEmpty
                              ? null
                              : _openSubjectSelector,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusInput,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space16,
                              vertical: AppTheme.space12,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusInput,
                              ),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.menu_book_outlined,
                                  size: 20,
                                  color: AppTheme.primary,
                                ),
                                const SizedBox(width: AppTheme.space12),
                                Expanded(
                                  child: Text(
                                    _selectedSubjectIds.isEmpty
                                        ? 'Klik untuk memilih mata pelajaran...'
                                        : '${_selectedSubjectIds.length} mata pelajaran dipilih',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _selectedSubjectIds.isEmpty
                                          ? AppTheme.textMuted
                                          : AppTheme.textPrimary,
                                      fontWeight: _selectedSubjectIds.isEmpty
                                          ? FontWeight.w400
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: AppTheme.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.space10),

                        // Daftar Badge Mapel Terpilih
                        if (selectedSubjectModels.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: selectedSubjectModels.map((sub) {
                              return Chip(
                                label: Text(sub.name),
                                backgroundColor: AppTheme.primaryLight,
                                deleteIcon: const Icon(Icons.close, size: 16),
                                deleteIconColor: AppTheme.primary,
                                onDeleted: () =>
                                    _presenter.toggleSubject(sub.id),
                                labelStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                                side: const BorderSide(color: AppTheme.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusButton,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: AppTheme.space32),

                        // Tombol Simpan
                        ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () => _presenter.saveProfile(
                                  _nameController.text,
                                ),
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
                              : const Text(
                                  'Simpan Perubahan',
                                  style: TextStyle(
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
