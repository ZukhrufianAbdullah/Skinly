import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/skinly_button.dart';
import '../../../core/widgets/skinly_card.dart';

class ScanExampleScreen extends StatelessWidget {
  const ScanExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Contoh Foto Scan',
          style: AppTextStyles.h2.copyWith(fontSize: 20, color: AppColors.white),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Panduan Foto Wajah yang Tepat',
                style: AppTextStyles.h2.copyWith(color: AppColors.textTealDark),
              ),
              const SizedBox(height: 6),
              Text(
                'Ikuti petunjuk di bawah ini agar model Machine Learning dapat mendeteksi jenis kulitmu dengan akurasi optimal.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // Kartu Foto yang Benar
              SkinlyCard(
                padding: const EdgeInsets.all(18),
                borderRadius: 22,
                border: Border.all(color: AppColors.success.withOpacity(0.3), width: 1.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, color: AppColors.success, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Contoh Foto yang Benar ✅',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.success,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildExampleItem(
                      Icons.wb_sunny_rounded,
                      'Pencahayaan terang & merata',
                      'Gunakan cahaya alami dekat jendela atau nyalakan lampu ruangan.',
                    ),
                    _buildExampleItem(
                      Icons.face_retouching_natural_rounded,
                      'Wajah lurus menghadap kamera',
                      'Posisikan seluruh wajah berada di dalam bingkai oval panduan.',
                    ),
                    _buildExampleItem(
                      Icons.no_photography_rounded,
                      'Tanpa kacamata hitam, topi, atau masker',
                      'Pastikan kulit pipi, dahi, hidung, dan dagu terlihat jelas.',
                    ),
                    _buildExampleItem(
                      Icons.auto_fix_off_rounded,
                      'Tanpa filter & makeup tebal',
                      'Foto alami agar tekstur dan kilap kulit terdeteksi sesuai kondisi asli.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Kartu Foto yang Salah
              SkinlyCard(
                padding: const EdgeInsets.all(18),
                borderRadius: 22,
                border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: AppColors.error, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Contoh Foto yang Salah ❌',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.error,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildExampleItem(
                      Icons.dark_mode_outlined,
                      'Foto terlalu gelap',
                      'Sistem akan menolak foto yang kurang cahaya (underexposed).',
                    ),
                    _buildExampleItem(
                      Icons.blur_on_rounded,
                      'Foto goyang atau buram',
                      'Pegang ponsel dengan stabil agar fokus tajam.',
                    ),
                    _buildExampleItem(
                      Icons.turn_left_rounded,
                      'Posisi wajah miring atau terlalu jauh',
                      'Pastikan wajah memenuhi area tengah frame.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Tombol Mulai Foto
              SkinlyButton(
                text: 'Saya Mengerti, Mulai Scan',
                variant: SkinlyButtonVariant.primaryPink,
                width: double.infinity,
                height: 52,
                onPressed: () => context.pop(),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExampleItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
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
