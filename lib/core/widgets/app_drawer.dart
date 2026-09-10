import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../data/models/teacher_model.dart';

enum AppDrawerRoute {
  dashboard,
  schedule,
  attendance,
  profile,
  about,
}

class AppDrawer extends StatelessWidget {
  final AppDrawerRoute currentRoute;
  final TeacherModel? teacher;
  final VoidCallback? onDashboardTap;
  final VoidCallback? onScheduleTap;
  final VoidCallback? onAttendanceTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onAboutTap;
  final VoidCallback? onLogoutTap;

  const AppDrawer({
    super.key,
    required this.currentRoute,
    this.teacher,
    this.onDashboardTap,
    this.onScheduleTap,
    this.onAttendanceTap,
    this.onProfileTap,
    this.onAboutTap,
    this.onLogoutTap,
  });

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        title: Row(
          children: const [
            Icon(Icons.logout_rounded, color: AppTheme.error, size: 24),
            SizedBox(width: 8),
            Text(
              'Konfirmasi Keluar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun Skola App?',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Tutup dialog
              Navigator.of(context).pop(); // Tutup drawer
              onLogoutTap?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusButton),
              ),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = teacher;
    final teacherName = (t != null && t.name.isNotEmpty) ? t.name : 'Guru';
    final teacherCode = (t != null && t.teacherCode.isNotEmpty) ? t.teacherCode : 'GUR';
    final teacherEmail = (t != null && t.email.isNotEmpty) ? t.email : '';
    final isInactive = t?.isInactive ?? false;

    return Drawer(
      backgroundColor: AppTheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Drawer: Logo & Branding
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space20,
                AppTheme.space16,
                AppTheme.space20,
                AppTheme.space12,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Skola App',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'Administrasi Guru',
                          style: TextStyle(
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

            // Card Profil Guru
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppTheme.space16,
                vertical: AppTheme.space8,
              ),
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primary,
                    child: Text(
                      teacherName.isNotEmpty ? teacherName[0].toUpperCase() : 'G',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teacherName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                teacherCode,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isInactive
                                    ? AppTheme.warningSurface
                                    : AppTheme.successSurface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isInactive ? 'NONAKTIF' : 'AKTIF',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isInactive
                                      ? AppTheme.warning
                                      : AppTheme.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (teacherEmail.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            teacherEmail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.space8),
            const Divider(height: 1, color: AppTheme.border),

            // Daftar Menu Navigasi
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                  vertical: AppTheme.space8,
                ),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Text(
                      'MENU UTAMA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    title: 'Dasbor',
                    isSelected: currentRoute == AppDrawerRoute.dashboard,
                    onTap: () {
                      Navigator.of(context).pop();
                      if (currentRoute != AppDrawerRoute.dashboard) {
                        onDashboardTap?.call();
                      }
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.calendar_today_outlined,
                    activeIcon: Icons.calendar_today_rounded,
                    title: 'Jadwal Mengajar',
                    isSelected: currentRoute == AppDrawerRoute.schedule,
                    onTap: () {
                      Navigator.of(context).pop();
                      if (currentRoute != AppDrawerRoute.schedule) {
                        onScheduleTap?.call();
                      }
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.fact_check_outlined,
                    activeIcon: Icons.fact_check_rounded,
                    title: 'Presensi Siswa',
                    isSelected: currentRoute == AppDrawerRoute.attendance,
                    onTap: () {
                      Navigator.of(context).pop();
                      onAttendanceTap?.call();
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    title: 'Profil Guru',
                    isSelected: currentRoute == AppDrawerRoute.profile,
                    onTap: () {
                      Navigator.of(context).pop();
                      if (currentRoute != AppDrawerRoute.profile) {
                        onProfileTap?.call();
                      }
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.info_outline_rounded,
                    activeIcon: Icons.info_rounded,
                    title: 'Tentang Aplikasi',
                    isSelected: currentRoute == AppDrawerRoute.about,
                    onTap: () {
                      Navigator.of(context).pop();
                      if (currentRoute != AppDrawerRoute.about) {
                        onAboutTap?.call();
                      }
                    },
                  ),
                ],
              ),
            ),

            // Footer Drawer: Tombol Keluar (Logout)
            const Divider(height: 1, color: AppTheme.border),
            Padding(
              padding: const EdgeInsets.all(AppTheme.space12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                ),
                leading: const Icon(
                  Icons.logout_rounded,
                  color: AppTheme.error,
                  size: 22,
                ),
                title: const Text(
                  'Keluar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.error,
                  ),
                ),
                onTap: () => _showLogoutDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: AppTheme.primaryLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        ),
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
