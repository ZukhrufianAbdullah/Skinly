// lib/features/home/presentation/home_screen.dart
// Homepage Skinly – mengikuti frame "homepage" di Figma:
// logo + judul, hero card "Mulai scan wajah", lalu daftar "Jenis Kulit".
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Data satu kartu jenis kulit.
/// Label memakai bahasa Inggris sesuai desain Figma (Dry, Normal, Oily).
class _SkinTypeItem {
  final String label;
  final IconData icon;
  const _SkinTypeItem(this.label, this.icon);
}

// Model backend mengklasifikasikan 4 kelas (normal, oily, dry, combination),
// jadi daftar ini memuat 4 kartu agar jumlahnya sesuai kemampuan model.
const List<_SkinTypeItem> _skinTypes = [
  _SkinTypeItem('Dry', Icons.wb_sunny_rounded),
  _SkinTypeItem('Normal', Icons.sentiment_satisfied_alt_rounded),
  _SkinTypeItem('Oily', Icons.water_drop_rounded),
  _SkinTypeItem('Combination', Icons.contrast_rounded),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Center(
          // Batasi lebar agar tetap proporsional ponsel saat dibuka di web/tablet.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              // Padding bawah menyisakan ruang untuk bottom nav melayang.
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HomeHeader()
                      .animate()
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: -0.1, end: 0),
                  const SizedBox(height: 20),
                  _ScanHeroCard(
                    onScan: () => context.push(AppRoutes.scan),
                  )
                      .animate()
                      .fadeIn(delay: 80.ms, duration: 400.ms)
                      .slideY(begin: 0.08, end: 0),
                  const SizedBox(height: 22),
                  const _SkinTypeSectionTitle()
                      .animate()
                      .fadeIn(delay: 160.ms, duration: 350.ms),
                  const SizedBox(height: 12),
                  for (var i = 0; i < _skinTypes.length; i++)
                    _SkinTypeCard(
                      item: _skinTypes[i],
                      onTap: () => context.go(AppRoutes.knowledge),
                    )
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: 220 + i * 70),
                          duration: 350.ms,
                        )
                        .slideY(begin: 0.08, end: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Header: logo maskot + "Skinly" + tagline
// ──────────────────────────────────────────────────────────
class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/maskot_full.png',
          width: 54,
          height: 54,
          fit: BoxFit.contain,
          semanticLabel: 'Logo Skinly',
          errorBuilder: (_, _, _) => const Icon(
            Icons.eco_rounded,
            color: AppColors.primary,
            size: 40,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skinly',
              style: AppTextStyles.displayMedium.copyWith(
                color: AppColors.accent,
                fontSize: 32,
                height: 1.05,
              ),
            ),
            Text(
              'klasifikasi jenis kulit ai',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primaryDark,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
// Hero card teal: ajakan scan wajah
// ──────────────────────────────────────────────────────────
class _ScanHeroCard extends StatelessWidget {
  final VoidCallback onScan;
  const _ScanHeroCard({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Cek kondisi kulit\nkamu sekarang !',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Kenali jenis kulit dan dapatkan rekomendasi\nperawatan kulit yang tepat',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.white,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          // Tombol putih "Mulai scan wajah"
          Semantics(
            button: true,
            label: 'Mulai scan wajah',
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onScan,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/tekan_tombol.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.touch_app_outlined,
                            color: AppColors.textDark,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Mulai scan wajah',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontSize: 15,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Judul bagian "Jenis Kulit"
// ──────────────────────────────────────────────────────────
class _SkinTypeSectionTitle extends StatelessWidget {
  const _SkinTypeSectionTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jenis Kulit',
          style: AppTextStyles.displayMedium.copyWith(
            color: AppColors.skinSectionBlue,
            fontSize: 30,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${_skinTypes.length} klasifikasi jenis kulit oleh model ai',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.accent,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
// Kartu biru satu jenis kulit
// ──────────────────────────────────────────────────────────
class _SkinTypeCard extends StatelessWidget {
  final _SkinTypeItem item;
  final VoidCallback onTap;
  const _SkinTypeCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Jenis kulit ${item.label}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.skinCardBlue,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.skinCardShadow.withValues(alpha: 0.55),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Kotak putih di kiri (area ilustrasi di Figma)
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      size: 30,
                      color: AppColors.skinSectionBlue,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.displaySmall.copyWith(
                            color: AppColors.white,
                            fontSize: 26,
                            height: 1.1,
                            shadows: const [
                              Shadow(
                                color: Color(0x40000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '4 klasifikasi yang terdeteksi oleh model ai',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
