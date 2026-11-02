import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/skinly_button.dart';
import '../../../core/widgets/skinly_mascot.dart';
import '../../../core/router/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 3 Slide sesuai tepat dengan mockup Figma
  final List<_WalkthroughSlide> _slides = const [
    _WalkthroughSlide(
      title: 'Hai! Aku Skinly, teman\nperawatan kulitmu.',
      description: null,
      mascotVariant: SkinlyMascotVariant.slide1,
    ),
    _WalkthroughSlide(
      title: 'Analisis Kulit Instan dengan AI',
      description:
          'Cukup foto wajahmu dan biarkan AI mendeteksi kondisi kulitmu secara akurat.',
      mascotVariant: SkinlyMascotVariant.slide2,
    ),
    _WalkthroughSlide(
      title: 'Kulit Sehat Dimulai dari Sini!',
      description:
          'Analisis jenis kulitmu sekarang dan dapatkan rekomendasi terbaiknya',
      mascotVariant: SkinlyMascotVariant.slide3,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('skinly_has_seen_onboarding', true);
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Tombol Lewati di pojok kanan atas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isLastPage)
                      TextButton(
                        onPressed: _finishOnboarding,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textLight,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: Text(
                          'Lewati',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Konten Carousel 3 Slide
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 1),

                        // Maskot Bunga Teal sesuai slide
                        SkinlyMascot(
                          width: 210,
                          height: 210,
                          variant: slide.mascotVariant,
                          animated: true,
                        ),
                        const SizedBox(height: 36),

                        // Judul Slide
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.displayMedium.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                            height: 1.35,
                          ),
                        ),

                        if (slide.description != null) ...[
                          const SizedBox(height: 14),
                          // Deskripsi Slide
                          Text(
                            slide.description!,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],

                        const Spacer(flex: 2),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bagian Bawah: Navigasi sesuai Figma
            // Slide 1 & 2: Dot indicator di kiri, tombol panah bulat di kanan
            // Slide 3: Dot indicator di tengah, tombol pill pink lebar di bawahnya
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
              child: isLastPage
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Dot indicators di tengah
                        _buildDotIndicators(),
                        const SizedBox(height: 24),
                        // Tombol Mulai Sekarang (Pill Pink Lebar)
                        SkinlyButton(
                          text: 'Mulai Sekarang',
                          variant: SkinlyButtonVariant.secondary,
                          onPressed: _finishOnboarding,
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Dot indicators di kiri
                        _buildDotIndicators(),

                        // Tombol panah bulat di kanan
                        GestureDetector(
                          onTap: _nextPage,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF3B82F6), // Biru seperti di mockup Figma
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotIndicators() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_slides.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF3B82F6) // Biru aktif seperti di Figma
                : const Color(0xFFE2E8F0), // Abu-abu muda
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _WalkthroughSlide {
  final String title;
  final String? description;
  final SkinlyMascotVariant mascotVariant;

  const _WalkthroughSlide({
    required this.title,
    this.description,
    required this.mascotVariant,
  });
}
