import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Theme mode notifier that manages dark/light theme state.
/// Persists user preference to Hive storage.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _loadFromHive();
  }

  void _loadFromHive() {
    try {
      final authBox = Hive.box('auth_box');
      final savedTheme = authBox.get('themeMode', defaultValue: 'dark');
      state = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;
    } catch (e) {
      // If Hive fails, default to dark
      state = ThemeMode.dark;
    }
  }

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _persistToHive();
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _persistToHive();
  }

  void _persistToHive() {
    try {
      final authBox = Hive.box('auth_box');
      authBox.put('themeMode', state == ThemeMode.dark ? 'dark' : 'light');
    } catch (e) {
      // Silent fail — preference will reset on next launch
    }
  }

  bool get isDark => state == ThemeMode.dark;
}

/// Global theme mode provider — watch this in any screen to get reactive theme changes.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Convenience provider — returns true if dark mode is active.
final isDarkProvider = Provider<bool>((ref) {
  return ref.watch(themeModeProvider) == ThemeMode.dark;
});
