import 'dart:io' show Platform, SocketException;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';
import 'login_page.dart';

class SubjectItem {
  final String id;
  final String name;
  final String code;

  const SubjectItem({
    required this.id,
    required this.name,
    required this.code,
  });
}

class ProfilePage extends StatefulWidget {
  final bool isInitialSetup;

  const ProfilePage({super.key, this.isInitialSetup = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoggingOut = false;

  String _email = '';
  String _teacherCode = '';
  String _accountStatus = 'ACTIVE';
  String? _teacherId;

  List<SubjectItem> _allSubjects = [];
  final List<String> _selectedSubjectIds = [];

  @override
  void initState() {
    super.initState();
    _loadTeacherProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherProfile() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      _email = user.email ?? '-';

      // 1. Fetch all subjects
      final subjectsData = await supabase.from('subjects').select('id, name, code').order('name');
      final List<SubjectItem> subjectList = [];
      for (var row in subjectsData) {
        subjectList.add(SubjectItem(
          id: row['id'] as String,
          name: row['name'] as String,
          code: row['code'] as String? ?? '',
        ));
      }
      _allSubjects = subjectList;

      // 2. Fetch teacher profile
      final teacherRes = await supabase
          .from('teachers')
          .select('id, teacher_code, name, status, subject_ids')
          .eq('profile_id', user.id)
          .maybeSingle();

      if (teacherRes != null) {
        _teacherId = teacherRes['id'] as String?;
        _nameController.text = teacherRes['name'] as String? ?? '';
        _teacherCode = teacherRes['teacher_code'] as String? ?? '';
        _accountStatus = teacherRes['status'] as String? ?? 'ACTIVE';

        final rawSubjects = teacherRes['subject_ids'];
        if (rawSubjects is List) {
          _selectedSubjectIds.clear();
          for (var s in rawSubjects) {
            if (s != null) _selectedSubjectIds.add(s.toString());
          }
        }
      } else {
        // Fallback default name
        final defaultName = user.userMetadata?['full_name'] ??
            user.userMetadata?['username'] ??
            user.email?.split('@').first ??
            '';
        _nameController.text = defaultName;
        _teacherCode = 'GURU-${user.id.substring(0, 6).toUpperCase()}';
      }
    } catch (_) {
      // Continue gracefully
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openSubjectPickerModal() {
    final tempSelectedIds = List<String>.from(_selectedSubjectIds);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pilih Mata Pelajaran',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pilih maksimal 2 mata pelajaran (${tempSelectedIds.length}/2 dipilih)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: tempSelectedIds.length == 2 ? AppTheme.primary : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textMuted),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const Divider(color: AppTheme.border),
                  const SizedBox(height: AppTheme.space12),
                  if (_allSubjects.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppTheme.space24),
                      child: Center(
                        child: Text(
                          'Belum ada data mata pelajaran dari sekolah.',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _allSubjects.length,
                        itemBuilder: (context, index) {
                          final subject = _allSubjects[index];
                          final isSelected = tempSelectedIds.contains(subject.id);

                          return Container(
                            margin: const EdgeInsets.only(bottom: AppTheme.space8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primarySurface : AppTheme.surface,
                              borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                              border: Border.all(
                                color: isSelected ? AppTheme.primary : AppTheme.border,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: CheckboxListTile(
                              value: isSelected,
                              activeColor: AppTheme.primary,
                              title: Text(
                                subject.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? AppTheme.primaryDark : AppTheme.textPrimary,
                                ),
                              ),
                              subtitle: subject.code.isNotEmpty
                                  ? Text(
                                      'Kode: ${subject.code}',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                    )
                                  : null,
                              onChanged: (_) {
                                setModalState(() {
                                  if (isSelected) {
                                    tempSelectedIds.remove(subject.id);
                                  } else {
                                    if (tempSelectedIds.length >= 2) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Maksimal 2 mata pelajaran yang dapat diampu.'),
                                          backgroundColor: AppTheme.warning,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }
                                    tempSelectedIds.add(subject.id);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: AppTheme.space16),
                  ElevatedButton(
                    onPressed: () {
                      if (tempSelectedIds.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pilih minimal 1 mata pelajaran yang Anda ampu.'),
                            backgroundColor: AppTheme.warning,
                          ),
                        );
                        return;
                      }
                      setState(() {
                        _selectedSubjectIds.clear();
                        _selectedSubjectIds.addAll(tempSelectedIds);
                      });
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Simpan Pilihan'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSubjectIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 mata pelajaran yang Anda ampu.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final updatedName = _nameController.text.trim();

      // 1. Update profiles table
      await supabase.from('profiles').upsert(
        {
          'id': user.id,
          'username': updatedName,
          'email': user.email,
          'role': 'teacher',
        },
        onConflict: 'id',
      );

      // 2. Update teachers table
      final teacherPayload = {
        'profile_id': user.id,
        'teacher_code': _teacherCode.isNotEmpty ? _teacherCode : 'GURU-${user.id.substring(0, 6).toUpperCase()}',
        'name': updatedName,
        'subject_ids': _selectedSubjectIds,
      };

      if (_teacherId != null) {
        await supabase
            .from('teachers')
            .update(teacherPayload)
            .eq('id', _teacherId!);
      } else {
        final inserted = await supabase
            .from('teachers')
            .upsert(
              teacherPayload,
              onConflict: 'profile_id',
            )
            .select('id')
            .maybeSingle();
        if (inserted != null) {
          _teacherId = inserted['id'] as String?;
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui.'),
          backgroundColor: AppTheme.success,
        ),
      );

      if (widget.isInitialSetup) {
        Navigator.of(context).pop(true);
      }
    } on PostgrestException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan profil ke database. Silakan coba lagi.'),
          backgroundColor: AppTheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (!kIsWeb && e is SocketException) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal terhubung ke server. Periksa koneksi internet lalu coba lagi.'),
            backgroundColor: AppTheme.error,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan profil. Silakan coba lagi.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusDialog)),
        title: const Text(
          'Konfirmasi Logout',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun Skola App?',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
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
              minimumSize: const Size(100, 42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusButton)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoggingOut = true);

    try {
      if (!kIsWeb) {
        try {
          final webClientId = dotenv.env['WEB_CLIENT'];
          final iosClientId = dotenv.env['IOS_CLIENT'];
          final clientId = Platform.isIOS ? iosClientId : null;
          final GoogleSignIn googleSignIn = GoogleSignIn(
            clientId: clientId,
            serverClientId: webClientId,
          );
          await googleSignIn.signOut();
        } catch (_) {}
      }

      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal keluar dari sesi. Silakan coba lagi.'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.isInitialSetup ? 'Lengkapi Profil Guru' : 'Profil Guru'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.space20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Inactive Status Warning Banner
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
                                  'Akun Anda saat ini berstatus NONAKTIF. Anda tidak dapat melakukan perubahan jadwal atau presensi sampai akun diaktifkan oleh admin.',
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
                        const SizedBox(height: AppTheme.space20),
                      ],

                      // Profile Header Card
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
                              radius: 30,
                              backgroundColor: AppTheme.primarySurface,
                              child: Text(
                                _nameController.text.isNotEmpty
                                    ? _nameController.text[0].toUpperCase()
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
                                    _nameController.text.isNotEmpty ? _nameController.text : 'Guru',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.space4),
                                  Text(
                                    _email,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.space8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _accountStatus == 'ACTIVE'
                                          ? AppTheme.successSurface
                                          : AppTheme.warningSurface,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                                    ),
                                    child: Text(
                                      _accountStatus == 'ACTIVE' ? 'AKUN AKTIF' : 'NONAKTIF',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _accountStatus == 'ACTIVE'
                                            ? AppTheme.success
                                            : AppTheme.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.space24),

                      // Profile Details Form Section
                      const Text(
                        'Data Pribadi',
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
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nama Lengkap',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppTheme.space8),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                hintText: 'Masukkan nama lengkap',
                                prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted, size: 20),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Nama tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTheme.space16),

                            const Text(
                              'Kode Guru (NIP / Identitas)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppTheme.space8),
                            TextFormField(
                              initialValue: _teacherCode,
                              readOnly: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppTheme.surfaceMuted,
                                hintText: 'Kode Guru',
                                prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.textMuted, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.space24),

                      // Subject Assignment Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mata Pelajaran yang Diampu',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _selectedSubjectIds.isEmpty
                                  ? AppTheme.warning.withValues(alpha: 0.1)
                                  : AppTheme.primarySurface,
                              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                            ),
                            child: Text(
                              '${_selectedSubjectIds.length}/2 Mapel',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _selectedSubjectIds.isEmpty ? AppTheme.warning : AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space8),
                      const Text(
                        'Pilih maksimal 2 mata pelajaran yang Anda ampu dari master data sekolah.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space12),

                      // Card Ringkasan Mapel Diampu
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTheme.space16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedSubjectIds.isEmpty)
                              Row(
                                children: [
                                  Icon(Icons.info_outline, size: 20, color: AppTheme.warning),
                                  const SizedBox(width: AppTheme.space8),
                                  const Expanded(
                                    child: Text(
                                      'Belum ada mata pelajaran yang dipilih. (Wajib 1 - 2 mapel)',
                                      style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Wrap(
                                spacing: AppTheme.space8,
                                runSpacing: AppTheme.space8,
                                children: _selectedSubjectIds.map((id) {
                                  final subject = _allSubjects.where((s) => s.id == id).firstOrNull;
                                  final subjectName = subject?.name ?? id;
                                  final subjectCode = subject?.code;

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.space12,
                                      vertical: AppTheme.space8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primarySurface,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                                      border: Border.all(
                                        color: AppTheme.primary.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.menu_book_rounded,
                                          size: 16,
                                          color: AppTheme.primary,
                                        ),
                                        const SizedBox(width: AppTheme.space8),
                                        Text(
                                          subjectName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryDark,
                                          ),
                                        ),
                                        if (subjectCode != null && subjectCode.isNotEmpty) ...[
                                          const SizedBox(width: AppTheme.space4),
                                          Text(
                                            '($subjectCode)',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.primary.withValues(alpha: 0.8),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            const SizedBox(height: AppTheme.space16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Pilih / Ubah Mapel'),
                                onPressed: _allSubjects.isEmpty ? null : _openSubjectPickerModal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.space32),

                      // Save Profile Action
                      ElevatedButton(
                        onPressed: _isSaving ? null : _handleSaveProfile,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Simpan Perubahan'),
                      ),
                      const SizedBox(height: AppTheme.space16),

                      // Logout Button
                      if (!widget.isInitialSetup) ...[
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.error),
                            foregroundColor: AppTheme.error,
                          ),
                          onPressed: _isLoggingOut ? null : _handleLogout,
                          icon: _isLoggingOut
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.error),
                                )
                              : const Icon(Icons.logout, size: 18),
                          label: const Text('Keluar dari Akun (Logout)'),
                        ),
                        const SizedBox(height: AppTheme.space24),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
