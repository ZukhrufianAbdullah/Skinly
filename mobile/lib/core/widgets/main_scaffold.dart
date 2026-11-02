import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../router/app_router.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRoutes.history)) return 1;
    if (location.startsWith(AppRoutes.knowledge)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0; // home
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.history);
        break;
      case 2:
        context.go(AppRoutes.knowledge);
        break;
      case 3:
        context.go(AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      body: child,
      extendBody: true,
      bottomNavigationBar: _SkinlyFloatingBottomNav(
        currentIndex: currentIndex,
        onTap: (i) => _onTap(context, i),
        onScanTap: () => context.push(AppRoutes.scan),
      ),
    );
  }
}

class _SkinlyFloatingBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onScanTap;

  const _SkinlyFloatingBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.onScanTap,
  });

  @override
  State<_SkinlyFloatingBottomNav> createState() => _SkinlyFloatingBottomNavState();
}

class _SkinlyFloatingBottomNavState extends State<_SkinlyFloatingBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          // Batasi lebar agar proporsional di web/tablet.
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: SizedBox(
              height: 78,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  // ──────────────────────────────────────────
                  // Bar pill teal melayang (sesuai Figma)
                  // ──────────────────────────────────────────
                  Container(
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NavItem(
                          icon: Icons.home_rounded,
                          label: 'Beranda',
                          isActive: widget.currentIndex == 0,
                          onTap: () => widget.onTap(0),
                        ),
                        _NavItem(
                          icon: Icons.history_edu_rounded,
                          label: 'Riwayat',
                          isActive: widget.currentIndex == 1,
                          onTap: () => widget.onTap(1),
                        ),
                        // Ruang untuk tombol kamera yang menonjol
                        const SizedBox(width: 72),
                        _NavItem(
                          icon: Icons.menu_book_rounded,
                          label: 'Edukasi',
                          isActive: widget.currentIndex == 2,
                          onTap: () => widget.onTap(2),
                        ),
                        _NavItem(
                          imageAsset: 'assets/images/logo_profil.png',
                          icon: Icons.person_rounded,
                          label: 'Profil',
                          isActive: widget.currentIndex == 3,
                          onTap: () => widget.onTap(3),
                        ),
                      ],
                    ),
                  ),

                  // ──────────────────────────────────────────
                  // Tombol kamera bulat menonjol di tengah
                  // ──────────────────────────────────────────
                  Positioned(
                    top: 0,
                    child: Semantics(
                      button: true,
                      label: 'Scan wajah',
                      child: GestureDetector(
                        onTap: widget.onScanTap,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: disableAnimations ? 1.0 : _pulseAnimation.value,
                              child: child,
                            );
                          },
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryDark.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(5),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/logo_kamera.png',
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.contain,
                                  excludeFromSemantics: true,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.camera_alt_outlined,
                                    color: AppColors.textDark,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
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

/// Satu item navigasi: lingkaran 40px dengan area sentuh 48px.
/// Tidak aktif = lingkaran putih + ikon gelap. Aktif = lingkaran teal gelap + ikon putih.
class _NavItem extends StatelessWidget {
  final String? imageAsset;
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    this.imageAsset,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = imageAsset != null
        // Aset profil sudah berupa lingkaran hitam + siluet putih (dari Figma),
        // ditampilkan apa adanya tanpa tint.
        ? ClipOval(
            child: Image.asset(
              imageAsset!,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => Icon(
                icon,
                size: 22,
                color: isActive ? AppColors.white : AppColors.textDark,
              ),
            ),
          )
        : Icon(
            icon,
            size: 22,
            color: isActive ? AppColors.white : AppColors.textDark,
          );

    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: imageAsset != null
                    ? Colors.transparent
                    : (isActive ? AppColors.primaryDark : AppColors.white),
                shape: BoxShape.circle,
                // Penanda aktif untuk item profil (yang tidak punya latar sendiri)
                border: imageAsset != null && isActive
                    ? Border.all(color: AppColors.white, width: 2.5)
                    : null,
              ),
              alignment: Alignment.center,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
