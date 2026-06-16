import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'AI Travel Planning',
      'desc': 'Simply state your trip desires in natural speech. Aira curates details, routes, and bookings instantly, eliminating complex search forms.',
      'step': '01',
    },
    {
      'title': 'Smart Alerts & Routing',
      'desc': 'Tokyo Central Ring Line delays? Typhoon approaching? Aira automatically mutates your schedule, alerts your phone, and maps alternative ways.',
      'step': '02',
    },
    {
      'title': 'Budget Intelligence',
      'desc': 'Define parameters and lock down airline tickets and capsules inside a single budget-enforced visual ledger. Avoid surprise expenses.',
      'step': '03',
    },
    {
      'title': 'Complete Travel Companion',
      'desc': 'Access real-time translations, timezone converters, custom etiquette instructions, and local emergency dispatch services anywhere.',
      'step': '04',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628), // Slate 900
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'BENEFIT HIGHLIGHTS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).primaryColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              
              // Slide content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemCount: _slides.length,
                  itemBuilder: (context, idx) {
                    final slide = _slides[idx];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Slide Number Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            slide['step']!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: Color(0xFF00B4D8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        
                        // Slide Title
                        Text(
                          slide['title']!,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        
                        // Slide Description
                        Text(
                          slide['desc']!,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                            height: 1.6,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              
              // Dots Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (idx) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: _currentPage == idx ? 28 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _currentPage == idx
                          ? Theme.of(context).primaryColor
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              
              // CTA Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    if (_currentPage < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      context.go('/login');
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage < _slides.length - 1 ? 'Next Benefit' : 'Continue',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
