import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/skinly_card.dart';
import '../../../core/widgets/skinly_button.dart';
import '../../../core/widgets/skinly_dialog.dart';
import '../../../core/widgets/skinly_mascot.dart';
import '../../../core/router/app_router.dart';
import '../../auth/presentation/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await SkinlyDialog.show(
      context: context,
      title: 'Keluar dari Akun?',
      message: 'Kamu perlu login kembali untuk mengakses riwayat dan rekomendasi kulitmu.',
      confirmText: 'Keluar',
      cancelText: 'Batal',
      isDestructive: true,
      icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 40),
    );

    if (confirm == true) {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SkinlyMascot(width: 80, height: 80),
              const SizedBox(height: 14),
              Text(
                'Skinly v1.0.0',
                style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark, fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                'Aplikasi pendeteksi jenis kulit wajah berbasis Machine Learning (MobileNetV2 Transfer Learning).',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Dibuat dengan ❤️ untuk membantu merawat kulit sehatmu.',
                style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              SkinlyButton(
                text: 'Tutup',
                variant: SkinlyButtonVariant.primaryTeal,
                width: double.infinity,
                height: 46,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final name = user?.name ?? 'Pengguna Skinly';
    final username = user?.username ?? 'skinly_user';
    final email = user?.email ?? '-';

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Profil Saya',
          style: AppTextStyles.h2.copyWith(color: AppColors.white, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            children: [
              // Kartu Profil Utama
              SkinlyCard(
                padding: const EdgeInsets.all(22),
                borderRadius: 24,
                child: Column(
                  children: [
                    // Avatar Bulat
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.35),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryDark, width: 2.5),
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'S',
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.primaryDark,
                            fontSize: 32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Nama Lengkap
                    Text(
                      name,
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),

                    // Username
                    Text(
                      '@$username',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Email
                    Text(
                      email,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Menu Opsi
              SkinlyCard(
                padding: const EdgeInsets.symmetric(vertical: 8),
                borderRadius: 22,
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Beri Masukan & Ulasan',
                      subtitle: 'Saran dan penilaian kepuasan fitur',
                      onTap: () => context.push(AppRoutes.feedback),
                    ),
                    const Divider(height: 1, indent: 64, endIndent: 20),
                    _buildMenuItem(
                      icon: Icons.lightbulb_outline_rounded,
                      title: 'Panduan Contoh Foto Scan',
                      subtitle: 'Tips pencahayaan & posisi wajah yang benar',
                      onTap: () => context.push(AppRoutes.scanExample),
                    ),
                    const Divider(height: 1, indent: 64, endIndent: 20),
                    _buildMenuItem(
                      icon: Icons.info_outline_rounded,
                      title: 'Tentang Skinly',
                      subtitle: 'Versi aplikasi dan teknologi model ML',
                      onTap: () => _showAboutDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Logout
              SkinlyButton(
                text: 'Keluar Akun Ini',
                variant: SkinlyButtonVariant.outline,
                icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                onPressed: () => _handleLogout(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.primaryDark, size: 22),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.neutral400),
      onTap: onTap,
    );
  }
}
