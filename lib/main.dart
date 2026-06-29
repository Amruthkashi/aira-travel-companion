import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/routing/app_router.dart';
import 'core/providers/travel_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('auth_box');
  
  runApp(
    const ProviderScope(
      child: AiraTravelApp(),
    ),
  );
}

class AiraTravelApp extends ConsumerWidget {
  const AiraTravelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Aira — Your Premium AI Travel Companion',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: const Color(0xFF4F46E5), // Indigo matching the design
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Light slate bg
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.light,
          primary: const Color(0xFF4F46E5),
          secondary: const Color(0xFF10B981),
          surface: Colors.white,
          error: const Color(0xFFEF4444),
        ),
        fontFamily: 'sans-serif',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF2563EB),
        scaffoldBackgroundColor: const Color(0xFF0A1628),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.dark,
          primary: const Color(0xFF2563EB),
          secondary: const Color(0xFF06D6A0),
          surface: const Color(0xFF1A2744),
          error: const Color(0xFFEF4444),
        ),
        fontFamily: 'sans-serif',
      ),
      routerConfig: appRouter,
    );
  }
}
