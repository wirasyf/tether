import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';

/// Glassmorphism styled card with blur effect
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final double blur;
  final Color? borderColor;
  
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.blur = 10,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.glassGradient,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
