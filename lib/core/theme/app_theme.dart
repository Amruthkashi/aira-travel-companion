import 'package:flutter/material.dart';

class AppTheme {
  // Brand Color Palette Tokens — Travel-Inspired Design System
  static const Color darkBg = Color(0xFF080D1A); // Premium Obsidian Midnight Background
  static const Color darkSurface = Color(0xFF131A2D); // Amethyst Black Card Surface
  static const Color lightBg = Color(0xFFF4F3F8); // Warm Light Lavender/Blush Background
  static const Color lightSurface = Colors.white; // Pure White Surface
  
  static const Color primary = Color(0xFFFF6B35); // Sunset Orange (Primary Accent)
  static const Color secondary = Color(0xFF00B4D8); // Ocean Teal (Secondary Accent)
  static const Color tropical = Color(0xFF06D6A0); // Tropical Green (Success)
  static const Color gold = Color(0xFFFFD166); // Warm Gold (Rewards)
  static const Color coral = Color(0xFFFF477E); // Coral Pink (Hearts/Favorites)
  static const Color royal = Color(0xFF7B2FF7); // Royal Violet (Premium)
  static const Color roseRed = Color(0xFFEF4444); // Error/Emergency
  
  static const Color textDarkPrimary = Color(0xFF0A1628);
  static const Color textDarkSecondary = Color(0xFF475569);
  static const Color textLightPrimary = Colors.white;
  static const Color textLightSecondary = Color(0xFF94A3B8);

  // Sunset gradient palette
  static const List<Color> sunsetGradient = [
    Color(0xFFFF6B35), // Sunset Orange
    Color(0xFFFF477E), // Coral Pink
  ];

  // Ocean gradient palette
  static const List<Color> oceanGradient = [
    Color(0xFF00B4D8), // Ocean Teal
    Color(0xFF06D6A0), // Tropical Green
  ];

  // Tropical gradient palette
  static const List<Color> tropicalGradient = [
    Color(0xFF06D6A0), // Tropical Green
    Color(0xFFFFD166), // Warm Gold
  ];

  // Sunset aurora background gradient (dark screens)
  static const List<Color> sunsetAuroraGradient = [
    Color(0xFF080D1A), 
    Color(0xFF130E26), 
    Color(0xFF0C191C), 
  ];

  // Aurora background gradient (dark screens)
  static const List<Color> auroraGradient = [
    Color(0xFF080D1A), 
    Color(0xFF130E26), 
    Color(0xFF0C191C), 
  ];

  static const List<Color> auroraGlow = [
    Color(0xFFFF6B35),
    Color(0xFFFF477E),
    Color(0xFF7B2FF7),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: lightSurface,
        error: roseRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: textDarkPrimary,
        elevation: 0.5,
        centerTitle: true,
      ),
      fontFamily: 'sans-serif',
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: darkSurface,
        error: roseRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: textLightPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      fontFamily: 'sans-serif',
    );
  }

  // Premium Glassmorphic / Card styles helper
  static BoxDecoration glassDecoration({
    required bool isDark,
    double radius = 24.0,
    double opacity = 0.08,
  }) {
    return BoxDecoration(
      color: isDark 
          ? const Color(0xFF1A2744).withValues(alpha: 0.55) 
          : Colors.white.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.12) 
            : Colors.white.withValues(alpha: 0.5),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.15)
              : const Color(0xFF4F46E5).withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 8),
        )
      ],
    );
  }

  // Sunset aurora background gradient
  static BoxDecoration auroraBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF080D1A), Color(0xFF130E26), Color(0xFF0C191C)],
      ),
    );
  }

  // Glowing card decoration with color border
  static BoxDecoration glowCard({
    Color color = primary,
    double radius = 16.0,
  }) {
    return BoxDecoration(
      color: const Color(0xFF1A2744).withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.1),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Gradient pill decoration (for tags / badges)
  static BoxDecoration gradientPill({
    List<Color> colors = sunsetGradient,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(colors: colors),
      borderRadius: BorderRadius.circular(20),
    );
  }
}

/// Centralized dynamic color tokens for Dark/Light theme support.
/// Usage: `AiraColors.scaffoldBg(isDark)` — returns the correct color for the current mode.
class AiraColors {
  AiraColors._(); // Private constructor — use static methods only

  // ── Backgrounds ──
  static Color scaffoldBg(bool isDark) =>
      isDark ? const Color(0xFF080D1A) : const Color(0xFFF4F3F8);

  static Color cardBg(bool isDark) =>
      isDark ? const Color(0xFF161F38).withValues(alpha: 0.65) : Colors.white.withValues(alpha: 0.85);

  static Color cardBgAlt(bool isDark) =>
      isDark ? const Color(0xFF1E2744).withValues(alpha: 0.65) : const Color(0xFFF1F0F6).withValues(alpha: 0.85);

  static Color surfaceElevated(bool isDark) =>
      isDark ? const Color(0xFF080D1A) : const Color(0xFFF4F3F8);

  static Color dialogBg(bool isDark) =>
      isDark ? const Color(0xFF0D1527) : Colors.white;

  // ── Borders ──
  static Color border(bool isDark) =>
      isDark ? const Color(0xFF1E2D4A) : const Color(0xFFE2E8F0);

  static Color borderSubtle(bool isDark) =>
      isDark ? const Color(0xFF1E3A5F) : const Color(0xFFCBD5E1);

  // ── Text ──
  static Color textPrimary(bool isDark) =>
      isDark ? Colors.white : const Color(0xFF0A1628);

  static Color textSecondary(bool isDark) =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  static Color textMuted(bool isDark) =>
      isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  // ── Navigation ──
  static Color navBarBg(bool isDark) =>
      isDark ? const Color(0xFF040814) : Colors.white;

  static Color navBarBorderColor(bool isDark) =>
      isDark ? const Color(0xFFFF6B35) : const Color(0xFFE2E8F0);

  static Color navBarShadow(bool isDark) =>
      isDark ? const Color(0xFFFF6B35) : const Color(0xFF94A3B8);

  // ── Icons ──
  static Color iconDefault(bool isDark) =>
      isDark ? Colors.white70 : const Color(0xFF475569);

  static Color iconMuted(bool isDark) =>
      isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  // ── Shimmer / Loading ──
  static Color shimmer(bool isDark) =>
      isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  // ── Gradients ──
  static List<Color> scaffoldGradient(bool isDark) => isDark
      ? const [Color(0xFF080D1A), Color(0xFF130E26), Color(0xFF0C191C)]
      : const [
          Color(0xFFF3EDFA), // Soft Lavender Mist
          Color(0xFFE4F5F8), // Soft Glacier Cyan
          Color(0xFFFFF5E6), // Soft Sun-bleached Cream
        ];

  static List<Color> headerGradient(bool isDark) => isDark
      ? const [Color(0xFF080D1A), Color(0xFF161F38)]
      : const [Color(0xFFFFFFFF), Color(0xFFF1F0F6)];

  static List<Color> overlayGradient(bool isDark) => isDark
      ? [const Color(0xFF080D1A).withValues(alpha: 0.1), const Color(0xFF080D1A).withValues(alpha: 0.7), const Color(0xFF080D1A)]
      : [const Color(0xFFF4F3F8).withValues(alpha: 0.1), const Color(0xFFF4F3F8).withValues(alpha: 0.7), const Color(0xFFF4F3F8)];

  // ── Nav item styles ──
  static Color navActiveGradientStart(bool isDark) =>
      isDark ? const Color(0xFFFF6B35) : const Color(0xFFFF6B35);

  static Color navActiveGradientEnd(bool isDark) =>
      isDark ? const Color(0xFFFF477E) : const Color(0xFFFF477E);

  static Color navActiveBorder(bool isDark) =>
      isDark ? const Color(0xFF00B4D8) : const Color(0xFF93C5FD);

  static Color navActiveText(bool isDark) =>
      isDark ? const Color(0xFFE0E7FF) : Colors.white;

  static Color navInactiveIcon(bool isDark) =>
      isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  // ── Glassmorphic helpers ──
  static BoxDecoration glassCard({
    required bool isDark,
    double radius = 24.0,
  }) {
    return BoxDecoration(
      color: isDark
          ? const Color(0xFF161F38).withValues(alpha: 0.55)
          : Colors.white.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.5),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.15)
              : const Color(0xFF4F46E5).withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 8),
        )
      ],
    );
  }

  static BoxDecoration auroraBackgroundDynamic(bool isDark) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: scaffoldGradient(isDark),
      ),
    );
  }

  static BoxDecoration glowCardDynamic({
    required bool isDark,
    Color color = AppTheme.primary,
    double radius = 16.0,
  }) {
    return BoxDecoration(
      color: isDark
          ? const Color(0xFF161F38).withValues(alpha: 0.6)
          : Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark
            ? color.withValues(alpha: 0.3)
            : color.withValues(alpha: 0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? color.withValues(alpha: 0.1)
              : color.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
