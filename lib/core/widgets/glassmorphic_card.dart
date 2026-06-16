import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blur;
  final double borderOpacity;
  final double bgOpacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.radius = 20.0,
    this.blur = 10.0,
    this.borderOpacity = 0.08,
    this.bgOpacity = 0.06,
    this.padding,
    this.margin,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A2744).withValues(alpha: bgOpacity)
                  : Colors.white.withValues(alpha: bgOpacity * 1.5 + 0.1),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: borderColor ?? (isDark
                    ? Colors.white.withValues(alpha: borderOpacity)
                    : const Color(0xFFE2E8F0).withValues(alpha: borderOpacity * 2)),
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
