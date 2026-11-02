import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum SkinlyMascotVariant {
  standard, // maskot_skinly.png (bunga teal happy)
  full,     // maskot_full.png (bunga teal curious mata bulat)
  slide1,   // maskot_slide1.png (bunga + bintang biru/pink)
  slide2,   // maskot_slide2.png (bunga + kilau pink)
  slide3,   // maskot_slide3.png (bunga + tanda seru pink !!)
  splash,   // maskot_splash.png (bunga setengah badan splash peek)
}

class SkinlyMascot extends StatefulWidget {
  final double width;
  final double height;
  final SkinlyMascotVariant variant;
  final bool animated;
  final BoxFit fit;

  const SkinlyMascot({
    super.key,
    this.width = 160,
    this.height = 160,
    this.variant = SkinlyMascotVariant.standard,
    this.animated = false,
    this.fit = BoxFit.contain,
  });

  @override
  State<SkinlyMascot> createState() => _SkinlyMascotState();
}

class _SkinlyMascotState extends State<SkinlyMascot> with SingleTickerProviderStateMixin {
  AnimationController? _animController;
  Animation<double>? _floatAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.animated) {
      _animController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
      )..repeat(reverse: true);

      _floatAnimation = Tween<double>(begin: 0.0, end: -10.0).animate(
        CurvedAnimation(
          parent: _animController!,
          curve: Curves.easeInOutSine,
        ),
      );
    }
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String assetPath;
    switch (widget.variant) {
      case SkinlyMascotVariant.slide1:
        assetPath = 'assets/images/maskot_slide1.png';
        break;
      case SkinlyMascotVariant.slide2:
        assetPath = 'assets/images/maskot_slide2.png';
        break;
      case SkinlyMascotVariant.slide3:
        assetPath = 'assets/images/maskot_slide3.png';
        break;
      case SkinlyMascotVariant.splash:
        assetPath = 'assets/images/maskot_splash.png';
        break;
      case SkinlyMascotVariant.full:
        assetPath = 'assets/images/maskot_full.png';
        break;
      case SkinlyMascotVariant.standard:
      default:
        assetPath = 'assets/images/maskot_skinly.png';
        break;
    }

    Widget imageWidget = Image.asset(
      assetPath,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        // Fallback anggun jika aset gambar gagal dimuat
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.face_retouching_natural_rounded,
              size: widget.width * 0.45,
              color: AppColors.primaryDark,
            ),
          ),
        );
      },
    );

    if (widget.animated && _floatAnimation != null && !MediaQuery.of(context).disableAnimations) {
      return AnimatedBuilder(
        animation: _floatAnimation!,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation!.value),
            child: child,
          );
        },
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
