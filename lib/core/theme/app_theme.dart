import 'package:flutter/material.dart';

class AppTheme {
  // Brand Color Palette Tokens â€” Travel-Inspired Design System
  static const Color darkBg = Color(0xFF090A0F); // Premium Obsidian Midnight Background
  static const Color darkSurface = Color(0xFF141624); // Amethyst Black Card Surface
  static const Color lightBg = Color(0xFFFFF8F0); // Warm Cream Background
  static const Color lightSurface = Colors.white; // Pure White Surface
  
  static const Color primary = Color(0xFF2563EB); // Royal Blue (Primary)
  static const Color secondary = Color(0xFF00B4D8); // Ocean Teal (Secondary)
  static const Color tropical = Color(0xFF06D6A0); // Tropical Green (Success)
  static const Color gold = Color(0xFFFFD166); // Warm Gold (Rewards)
  static const Color coral = Color(0xFFFF477E); // Coral Pink (Hearts/Favorites)
  static const Color royal = Color(0xFF7B2FF7); // Royal Violet (Premium)
  static const Color roseRed = Color(0xFFEF4444); // Error/Emergency
  
  static const Color textDarkPrimary = Color(0xFF0F172A);
  static const Color textDarkSecondary = Color(0xFF475569);
  static const Color textLightPrimary = Colors.white;
  static const Color textLightSecondary = Color(0xFF94A3B8);

  // Sunset gradient palette
  static const List<Color> sunsetGradient = [
    Color(0xFF2563EB), // Royal Blue
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
    Color(0xFF090A0F), // Premium Midnight Obsidian
    Color(0xFF141624), // Amethyst Card Surface
    Color(0xFF05050A), // Extra Deep Black
  ];

  // Aurora background gradient (dark screens)
  static const List<Color> auroraGradient = [
    Color(0xFF090A0F), // Premium Midnight Obsidian
    Color(0xFF141624), // Amethyst Card Surface
    Color(0xFF05050A), // Extra Deep Black
  ];

  static const List<Color> auroraGlow = [
    Color(0xFF2563EB),
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
          ? const Color(0xFF1A2744).withValues(alpha: 0.6) 
          : Colors.white.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.08) 
            : const Color(0xFFE2E8F0).withValues(alpha: 0.8),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
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
        colors: [Color(0xFF0A1628), Color(0xFF1A2744), Color(0xFF0D1B2A)],
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
