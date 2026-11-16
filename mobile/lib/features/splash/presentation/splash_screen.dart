import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/skinly_mascot.dart';
import '../../../core/router/app_router.dart';
import '../../auth/presentation/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _animController.forward();
    _checkNextScreen();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkNextScreen() async {
    // Beri waktu animasi splash berjalan
    await Future.delayed(const Duration(milliseconds: 1400));

    // Periksa status auth. Jika storage/jaringan bermasalah, jangan sampai
    // splash menggantung: perlakukan sebagai belum login.
    var isAuthenticated = false;
    try {
      await ref
          .read(authControllerProvider.notifier)
          .checkAuthStatus()
          .timeout(const Duration(seconds: 6));
      isAuthenticated = ref.read(authControllerProvider).isAuthenticated;
    } catch (e) {
      debugPrint('Splash: cek auth gagal — $e');
      isAuthenticated = false;
    }

    // Flag onboarding juga dibaca secara defensif (plugin storage bisa gagal
    // pada build yang tidak bersih).
    var hasSeenOnboarding = false;
    try {
      hasSeenOnboarding = await ref
          .read(authStorageProvider)
          .hasSeenOnboarding()
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Splash: baca flag onboarding gagal — $e');
      hasSeenOnboarding = false;
    }

    if (!mounted) return;

    if (isAuthenticated) {
      context.go(AppRoutes.home);
    } else if (!hasSeenOnboarding) {
      context.go(AppRoutes.onboarding);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Konten Tengah: Logo Teks "Skinly"
            Center(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Skinly',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: AppColors.primary,
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // Bagian Bawah: Bunga Maskot setengah badan menyembul dari bawah layar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.4),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animController,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  );
                },
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: SkinlyMascot(
                    width: 200,
                    height: 140,
                    variant: SkinlyMascotVariant.splash,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
