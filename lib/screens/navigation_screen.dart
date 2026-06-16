import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/sound_synthesizer.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  const NavigationScreen({super.key});

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  bool _isNavigating = false;
  int _currentStepIndex = 0;
  double _progress = 0.0;
  Timer? _navTimer;

  final List<Map<String, dynamic>> _steps = [
    {
      'instruction': 'Walk out of Nine Hours Capsule stay and turn right toward West Central Tokyo Dori.',
      'distance': '150m',
      'icon': Icons.directions_walk,
    },
    {
      'instruction': 'Turn left onto West Central Tokyo Dori and walk straight past the convenience store.',
      'distance': '450m',
      'icon': Icons.turn_left,
    },
    {
      'instruction': 'Descend into West Central Station Entrance 3 and head to Tokyo Central Ring Line Platform 14.',
      'distance': '200m',
      'icon': Icons.subway,
    },
    {
      'instruction': 'Board the Tokyo Central Ring Line Train toward Crossing District/Shinagawa (3 stops).',
      'distance': '4.2 km',
      'icon': Icons.train,
    },
    {
      'instruction': 'De-board at Crossing District Station. Head toward Hachiko Exit.',
      'distance': '100m',
      'icon': Icons.directions_railway,
    },
    {
      'instruction': 'Walk across Famous Scramble Crossing toward Sky View Deck entrance.',
      'distance': '250m',
      'icon': Icons.transfer_within_a_station,
    },
    {
      'instruction': 'Arrive at Sky View Deck. Take the high-speed elevator to the deck.',
      'distance': '50m',
      'icon': Icons.pin_drop,
    },
  ];

  double _distanceRemaining = 5.4; // km
  int _timeRemaining = 18; // mins

  void _startNavigation() {
    SoundSynthesizer.playTone(frequency: 660, durationSeconds: 0.2, name: 'nav_start.wav');
    setState(() {
      _isNavigating = true;
      _currentStepIndex = 0;
      _progress = 0.0;
      _distanceRemaining = 5.4;
      _timeRemaining = 18;
    });

    _navTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() {
        if (_currentStepIndex < _steps.length - 1) {
          _currentStepIndex++;
          _progress = _currentStepIndex / (_steps.length - 1);
          _distanceRemaining = (_distanceRemaining - 0.7).clamp(0.0, 10.0);
          _timeRemaining = (_timeRemaining - 2).clamp(0, 30);
          SoundSynthesizer.playTone(frequency: 800, durationSeconds: 0.1, name: 'nav_step.wav');
        } else {
          _isNavigating = false;
          _progress = 1.0;
          _distanceRemaining = 0.0;
          _timeRemaining = 0;
          _navTimer?.cancel();
          SoundSynthesizer.playUnlockChime(); // Success chime
          _showArrivalDialog();
        }
      });
    });
  }

  void _stopNavigation() {
    _navTimer?.cancel();
    SoundSynthesizer.playDisconnectTone();
    setState(() {
      _isNavigating = false;
    });
  }

  void _showArrivalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF818CF8)),
            SizedBox(width: 10),
            Text('Arrived Safely', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'AI Travel Companion confirms you have reached Sky View Deck. Scanning gate voucher or prepaid transit card recommended.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss', style: TextStyle(color: Color(0xFF818CF8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
            onPressed: () {
              Navigator.pop(context);
              // Switch to bookings tab (index 2 / or redirect to utilities)
              Navigator.pop(context);
            },
            child: const Text('Open Passes', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Midnight Blue
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI Real-Time Guidance',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.gps_fixed, color: Color(0xFF818CF8)),
            onPressed: () {
              SoundSynthesizer.playTone(frequency: 520, durationSeconds: 0.15, name: 'gps_sync.wav');
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Map Visual simulation box
          Expanded(
            child: Stack(
              children: [
                // Simulated Vector Map Grid
                Container(
                  width: double.infinity,
                  color: const Color(0xFF030712), // Deepest charcoal
                  child: CustomPaint(
                    painter: MapSimPainter(
                      progress: _progress,
                      currentStepIndex: _currentStepIndex,
                      totalSteps: _steps.length,
                    ),
                  ),
                ),
                
                // Compass Overlay
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Icon(Icons.compass_calibration_outlined, color: Colors.white70, size: 24),
                  ),
                ),

                // Map Legend Overlay
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        const Text('GPS Signal Locked', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),

                // HUD Stats overlay
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.glassDecoration(isDark: true, radius: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _hudItem('REMAINING', '${_distanceRemaining.toStringAsFixed(1)} km', Icons.route),
                        Container(width: 1, height: 30, color: Colors.white10),
                        _hudItem('EST. TIME', '$_timeRemaining mins', Icons.timer_outlined),
                        Container(width: 1, height: 30, color: Colors.white10),
                        _hudItem('SPEED', _isNavigating ? '4.8 km/h' : '0.0 km/h', Icons.speed),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Directions Card & Control Deck
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Active Step Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'STEP ${_currentStepIndex + 1} OF ${_steps.length}',
                      style: const TextStyle(color: Color(0xFF818CF8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    if (_isNavigating)
                      const Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(color: Color(0xFF10B981), strokeWidth: 2),
                          ),
                          SizedBox(width: 6),
                          Text('LIVE NAVIGATION ACTIVE', style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Direction Instruction Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF1E293B),
                      child: Icon(_steps[_currentStepIndex]['icon'], color: const Color(0xFF818CF8), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _steps[_currentStepIndex]['instruction'],
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, height: 1.4),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Next action in ${_steps[_currentStepIndex]['distance']}',
                            style: const TextStyle(color: Colors.white30, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Progress Indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: const Color(0xFF1E293B),
                    color: const Color(0xFF4F46E5),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons Panel
                Row(
                  children: [
                    if (!_isNavigating)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _startNavigation,
                          icon: const Icon(Icons.navigation, color: Colors.white),
                          label: const Text('Simulate Walk Journey', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      )
                    else
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _stopNavigation,
                          icon: const Icon(Icons.stop, color: Colors.white),
                          label: const Text('Stop Navigation Simulation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hudItem(String title, String val, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF818CF8), size: 16),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(color: Colors.white30, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class MapSimPainter extends CustomPainter {
  final double progress;
  final int currentStepIndex;
  final int totalSteps;

  MapSimPainter({
    required this.progress,
    required this.currentStepIndex,
    required this.totalSteps,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    // Draw Grid Lines
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Draw main route path line
    final pathPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final activePathPaint = Paint()
      ..color = const Color(0xFF4F46E5)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    // Generate simulated road nodes
    final List<Offset> points = [
      Offset(size.width * 0.15, size.height * 0.75),
      Offset(size.width * 0.25, size.height * 0.65),
      Offset(size.width * 0.45, size.height * 0.65),
      Offset(size.width * 0.55, size.height * 0.45),
      Offset(size.width * 0.55, size.height * 0.25),
      Offset(size.width * 0.75, size.height * 0.25),
      Offset(size.width * 0.85, size.height * 0.15),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, pathPaint);

    // Draw active portion of route path
    final Path activePath = Path();
    activePath.moveTo(points[0].dx, points[0].dy);
    
    // Find how far we are
    int segmentIndex = (progress * (points.length - 1)).floor();
    double segmentProgress = (progress * (points.length - 1)) - segmentIndex;

    for (int i = 1; i <= segmentIndex; i++) {
      activePath.lineTo(points[i].dx, points[i].dy);
    }
    if (segmentIndex < points.length - 1) {
      final lastPoint = points[segmentIndex];
      final nextPoint = points[segmentIndex + 1];
      final currentPos = Offset(
        lastPoint.dx + (nextPoint.dx - lastPoint.dx) * segmentProgress,
        lastPoint.dy + (nextPoint.dy - lastPoint.dy) * segmentProgress,
      );
      activePath.lineTo(currentPos.dx, currentPos.dy);
    }
    canvas.drawPath(activePath, activePathPaint);

    // Draw nodes/stations
    final nodePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    final nodeOutlinePaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final activeNodePaint = Paint()
      ..color = const Color(0xFF818CF8)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final isCurrent = i == currentStepIndex;
      final isPassed = i < currentStepIndex;
      
      canvas.drawCircle(points[i], isCurrent ? 8 : 5, isPassed ? activeNodePaint : nodePaint);
      canvas.drawCircle(points[i], isCurrent ? 8 : 5, isCurrent ? (Paint()..color = const Color(0xFF10B981)) : nodeOutlinePaint);
    }

    // Current position indicator pulse
    if (currentStepIndex < points.length) {
      final currentPos = points[currentStepIndex];
      final pulsePaint = Paint()
        ..color = const Color(0xFF818CF8).withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(currentPos, 18.0, pulsePaint);
    }
  }

  @override
  bool shouldRepaint(covariant MapSimPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.currentStepIndex != currentStepIndex;
  }
}
