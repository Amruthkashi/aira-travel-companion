import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/providers/travel_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isCheckingSession = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Dynamic AI auto-login session restoration check
    final authBox = Hive.box('auth_box');
    final email = authBox.get('email');
    final password = authBox.get('password');
    final cachedProfile = authBox.get('profile');

    if (email != null && password != null && cachedProfile != null) {
      _isCheckingSession = true;
      Future.delayed(const Duration(milliseconds: 1200), () async {
        if (!mounted) return;
        try {
          ref.read(userProfileProvider.notifier).restoreSession(
            Map<String, dynamic>.from(cachedProfile),
          );
          ref.read(userProfileProvider.notifier).fetchItineraryAndChecklist(email);

          if (mounted) {
            context.go('/home');
          }
        } catch (e) {
          print('Restoration of login session failed: $e');
          if (mounted) {
            setState(() {
              _isCheckingSession = false;
            });
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1628), // Slate 900
              Color(0xFF020617), // Slate 950
              Color(0xFF03001C), // Deep Indigo-black
            ],
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            
            // Neon Pulsing Explore Emblem
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF2563EB)], // Indigo gradients
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 6,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.explore,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 28),
            
            // Brand Title
            const Text(
              'Aira',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              'YOUR AI TRAVEL CONCIERGE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.indigo.shade300,
                letterSpacing: 4.0,
              ),
            ),
            
            const Spacer(),
            
            if (_isCheckingSession) ...[
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00B4D8)),
                    strokeWidth: 2.5,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Center(
                child: Text(
                  'Resuming secure travel session...',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              // Start Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0A1628),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => context.go('/onboarding'),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Start Journey',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              
              // Login Link
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => context.go('/login'),
                  child: const Text(
                    'Quick Log In',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
