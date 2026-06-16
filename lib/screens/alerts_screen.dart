import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/travel_providers.dart';
import '../core/models/travel_models.dart';
import '../core/utils/sound_synthesizer.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  bool _reroutingInProgress = false;
  bool _rerouteApplied = false;

  final List<Map<String, dynamic>> _alerts = [
    {
      'id': 'alert-1',
      'title': 'Heavy Rain Advisory (Tokyo Area)',
      'level': 'CRITICAL',
      'icon': Icons.thunderstorm,
      'color': Colors.redAccent,
      'description': 'Severe rainstorm system detected moving over Kanto region. Expect heavy downpours and low visibility from 02:00 PM to 06:00 PM.',
      'impact': 'Outdoor walking tours (Senso-ji, Nakamise Street) are highly impacted.',
      'canReroute': true,
    },
    {
      'id': 'alert-2',
      'title': 'Tokyo Central Ring Line Transit Delay',
      'level': 'WARNING',
      'icon': Icons.warning_amber_rounded,
      'color': Colors.amber,
      'description': 'Signal maintenance near Meguro Station causing 10-15 minute delays in both directions on Tokyo Central Ring Loop.',
      'impact': 'Expect minor delays on commutes between West Central Tokyo and Crossing District.',
      'canReroute': false,
    }
  ];

  void _triggerAiReroute() {
    setState(() {
      _reroutingInProgress = true;
    });

    SoundSynthesizer.playTone(frequency: 580, durationSeconds: 0.3, endFrequency: 980, name: 'reroute_search.wav');

    // Simulate AI routing engine calculating
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;

      // New safe/indoor activities for Day 2 to avoid the rain!
      final indoorActivities = [
        ActivityItem(
          time: '09:00 AM',
          activity: 'Planets Digital Art Museum Tokyo (Indoor)',
          description: 'A museum where you walk through water, and a garden where you become one with the flowers. 100% weather-proof.',
          cost: '\$32',
          locationName: 'Waterfront Bay',
          suggestedAttire: 'Shorts/pants that can be rolled up to knees',
        ),
        ActivityItem(
          time: '01:30 PM',
          activity: 'Tokyo Station Underground Ramen Street',
          description: 'Taste gourmet local ramen within the completely enclosed subterranean station dining arcade.',
          cost: '\$14',
          locationName: 'Tokyo Station B1F',
          suggestedAttire: 'Casual attire',
        ),
        ActivityItem(
          time: '04:30 PM',
          activity: 'National Garden Greenhouse tour',
          description: 'Visit the large premium indoor greenhouse containing thousands of rare tropical flora.',
          cost: '\$5',
          locationName: 'Central National Garden',
          suggestedAttire: 'Comfortable indoor walking shoes',
        ),
      ];

      // Day Index 1 is Day 2 (Day 1 is 0)
      ref.read(itineraryProvider.notifier).applyAiReroute(1, indoorActivities, 'Indoor Digital Art & Culinary (Weather Optimized)');
      ref.read(userProfileProvider.notifier).addXP(150);

      setState(() {
        _reroutingInProgress = false;
        _rerouteApplied = true;
      });

      SoundSynthesizer.playUnlockChime(); // Play premium success chime
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Midnight Blue
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        elevation: 0.5,
        title: const Text('Real-Time Crisis Alerts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top status card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1628),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.security, color: Colors.redAccent, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Crisis Hub Active',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Constantly scanning weather, transit, and city databases for safety anomalies.',
                              style: TextStyle(color: Colors.white30, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text('ACTIVE ALERTS & RADAR DISRUPTIONS', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 12),

                ..._alerts.map((alert) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1628),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: alert['color'].withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(alert['icon'], color: alert['color'], size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  alert['title'],
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: alert['color'].withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                alert['level'],
                                style: TextStyle(color: alert['color'], fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: Colors.white10),
                        Text(
                          alert['description'],
                          style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Color(0xFF00B4D8), size: 14),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Impact: ${alert['impact']}',
                                  style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 10.5, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (alert['canReroute']) ...[
                          const SizedBox(height: 16),
                          if (_rerouteApplied)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'AI WEATHER REROUTE ENFORCED',
                                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ],
                              ),
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _reroutingInProgress ? null : _triggerAiReroute,
                                icon: const Icon(Icons.auto_awesome, size: 16),
                                label: const Text('Enforce AI Reroute (Weather-proof)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // Loading overlay
          if (_reroutingInProgress)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00B4D8)),
                    SizedBox(height: 20),
                    Text(
                      'COMPUTING SAFE CLOUD PATHS...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2.0),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Updating itinerary blocks with weather-proof indoor activities.',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
