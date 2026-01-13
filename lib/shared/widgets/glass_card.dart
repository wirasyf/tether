import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';

/// Premium glassmorphism styled card with enhanced blur and glow effects
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final double blur;
  final Color? borderColor;
  final bool enableGlow;
  final Color? glowColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24,
    this.blur = 20,
    this.borderColor,
    this.enableGlow = true,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: enableGlow
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: (glowColor ?? AppColors.primary).withValues(
                    alpha: 0.15,
                  ),
                  blurRadius: 30,
                  spreadRadius: -5,
                  offset: const Offset(0, 10),
                ),
              ],
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Premium gradient button with glow effect
class GradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final List<Color>? gradientColors;
  final double borderRadius;
  final EdgeInsets? padding;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.gradientColors,
    this.borderRadius = 16,
    this.padding,
    this.isLoading = false,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        widget.gradientColors ?? [AppColors.primary, AppColors.secondary];

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                onTap: widget.isLoading ? null : widget.onPressed,
                onTapDown: (_) => _controller.forward(),
                onTapUp: (_) => _controller.reverse(),
                onTapCancel: () => _controller.reverse(),
                child: Padding(
                  padding:
                      widget.padding ??
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                  child: Center(
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : DefaultTextStyle(
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                            child: widget.child,
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Outline button with gradient border
class GradientOutlineButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final List<Color>? gradientColors;
  final double borderRadius;
  final EdgeInsets? padding;

  const GradientOutlineButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.gradientColors,
    this.borderRadius = 16,
    this.padding,
  });

  @override
  State<GradientOutlineButton> createState() => _GradientOutlineButtonState();
}

class _GradientOutlineButtonState extends State<GradientOutlineButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        widget.gradientColors ?? [AppColors.primary, AppColors.secondary];

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(widget.borderRadius - 2),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(widget.borderRadius - 2),
                  onTap: widget.onPressed,
                  onTapDown: (_) => _controller.forward(),
                  onTapUp: (_) => _controller.reverse(),
                  onTapCancel: () => _controller.reverse(),
                  child: Padding(
                    padding:
                        widget.padding ??
                        const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                    child: Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) =>
                            LinearGradient(colors: colors).createShader(bounds),
                        child: DefaultTextStyle(
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          child: widget.child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Glowing code display box
class CodeBox extends StatelessWidget {
  final String character;
  final bool isActive;

  const CodeBox({super.key, required this.character, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    // Get screen width and calculate responsive box size
    final screenWidth = MediaQuery.of(context).size.width;
    final boxWidth =
        (screenWidth - 48 - 40) /
        6; // 48 = horizontal padding, 40 = gaps between boxes
    final constrainedWidth = boxWidth.clamp(36.0, 44.0); // Min 36, max 44

    return Container(
      width: constrainedWidth,
      height: constrainedWidth * 1.25, // Maintain aspect ratio
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.3),
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: -3,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          character,
          style: TextStyle(
            fontSize: constrainedWidth * 0.55, // Responsive font size
            fontWeight: FontWeight.bold,
            color: isActive ? AppColors.primary : AppColors.textPrimary,
            shadows: isActive
                ? [
                    Shadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
