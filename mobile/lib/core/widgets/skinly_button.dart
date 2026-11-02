import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum SkinlyButtonVariant {
  primaryPink,
  primaryTeal,
  secondary,
  outline,
  ghost,
}

class SkinlyButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final SkinlyButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double height;
  final EdgeInsetsGeometry padding;

  const SkinlyButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = SkinlyButtonVariant.primaryPink,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 52.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  });

  @override
  State<SkinlyButton> createState() => _SkinlyButtonState();
}

class _SkinlyButtonState extends State<SkinlyButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  Color _getBackgroundColor() {
    if (widget.onPressed == null) return AppColors.neutral200;
    switch (widget.variant) {
      case SkinlyButtonVariant.primaryPink:
        return AppColors.accentButton; // #F76A9B
      case SkinlyButtonVariant.primaryTeal:
        return AppColors.primaryDark;   // #327E76
      case SkinlyButtonVariant.secondary:
        return AppColors.primaryBackground;
      case SkinlyButtonVariant.outline:
      case SkinlyButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color _getTextColor() {
    if (widget.onPressed == null) return AppColors.neutral500;
    switch (widget.variant) {
      case SkinlyButtonVariant.primaryPink:
      case SkinlyButtonVariant.primaryTeal:
        return AppColors.white;
      case SkinlyButtonVariant.secondary:
        return AppColors.primaryDark;
      case SkinlyButtonVariant.outline:
        return AppColors.primaryDark;
      case SkinlyButtonVariant.ghost:
        return AppColors.textSecondary;
    }
  }

  Border? _getBorder() {
    if (widget.variant == SkinlyButtonVariant.outline) {
      return Border.all(
        color: widget.onPressed != null ? AppColors.primaryDark : AppColors.neutral300,
        width: 1.5,
      );
    }
    return null;
  }

  List<BoxShadow> _getShadow() {
    if (widget.onPressed == null) return [];
    switch (widget.variant) {
      case SkinlyButtonVariant.primaryPink:
        return [
          BoxShadow(
            color: AppColors.accentButton.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];
      case SkinlyButtonVariant.primaryTeal:
        return [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final content = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: disableAnimations ? 1.0 : _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.isLoading ? null : widget.onPressed,
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(28),
            border: _getBorder(),
            boxShadow: _getShadow(),
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      widget.icon!,
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: AppTextStyles.button.copyWith(
                        color: _getTextColor(),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    return content;
  }
}
