import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/routing/app_router.dart';

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

class AiraTravelApp extends StatelessWidget {
  const AiraTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Aira â€” Your Premium AI Travel Companion',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light, // Base light theme for standard pages
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF2563EB), // Royal Blue (Primary)
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
          secondary: const Color(0xFF06D6A0), // Tropical Green (Secondary)
          surface: Colors.white,
          error: const Color(0xFFEF4444),
        ),
        fontFamily: 'sans-serif',
      ),
      routerConfig: appRouter,
    );
  }
}
