import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../core/providers/theme_provider.dart';
import '../core/theme/app_theme.dart';
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
  bool _loadingLocation = true;
  String? _locationError;
  double? _latitude;
  double? _longitude;
  
  List<Map<String, dynamic>> _weatherAlerts = [];
  final List<Map<String, dynamic>> _transitAlerts = [
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

  @override
  void initState() {
    super.initState();
    _loadLocationAndWeather();
  }

  Future<void> _loadLocationAndWeather() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });

    try {
      final position = await _determinePosition().timeout(const Duration(seconds: 6));
      if (position != null) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
        await _fetchWeatherAlerts(position.latitude, position.longitude);
      } else {
        // Fallback to Tokyo default coordinates
        setState(() {
          _latitude = 35.6762;
          _longitude = 139.6503;
          _locationError = 'Location permission denied or unavailable. Showing Tokyo default weather.';
        });
        await _fetchWeatherAlerts(35.6762, 139.6503);
      }
    } catch (e) {
      setState(() {
        _latitude = 35.6762;
        _longitude = 139.6503;
        _locationError = 'Timeout obtaining location. Displaying Tokyo default weather.';
      });
      await _fetchWeatherAlerts(35.6762, 139.6503);
    } finally {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
        });
      }
    }
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
      ),
    );
  }

  Future<void> _fetchWeatherAlerts(double lat, double lon) async {
    try {
      final dio = Dio();
      final url = 'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code,wind_speed_10m';
      final response = await dio.get(url);
      
      if (response.statusCode == 200 && response.data != null) {
        final current = response.data['current'];
        if (current != null) {
          final double temp = (current['temperature_2m'] as num).toDouble();
          final double windSpeed = (current['wind_speed_10m'] as num).toDouble();
          final int weatherCode = current['weather_code'] as int;

          final List<Map<String, dynamic>> tempAlerts = [];

          // 1. Heavy Wind Alert
          if (windSpeed > 20.0) {
            tempAlerts.add({
              'id': 'w-wind',
              'title': 'Heavy Wind Alert (${windSpeed.toStringAsFixed(1)} km/h)',
              'level': 'WARNING',
              'icon': Icons.air,
              'color': Colors.orangeAccent,
              'description': 'High velocity winds detected in your area. Secure loose items and expect potential delays in light transit/ferries.',
              'impact': 'Outdoor aerial sights and boat tours may be affected.',
              'canReroute': false,
            });
          }

          // 2. Heavy Rain Alert
          final isRainy = [51, 53, 55, 61, 63, 65, 80, 81, 82, 95, 96, 99].contains(weatherCode);
          if (isRainy) {
            tempAlerts.add({
              'id': 'w-rain',
              'title': 'Heavy Rain Advisory (Precipitation Active)',
              'level': 'CRITICAL',
              'icon': Icons.thunderstorm,
              'color': Colors.redAccent,
              'description': 'Active rainstorm system detected at your coordinates. Heavy downpours may lead to low visibility.',
              'impact': 'Walking tours and open-air activities are highly impacted. We recommend weather-proof locations.',
              'canReroute': true,
            });
          }

          // 3. Very Sunny / Heat Alert
          final isSunny = [0, 1, 2].contains(weatherCode);
          if (isSunny && temp > 28.0) {
            tempAlerts.add({
              'id': 'w-sun',
              'title': 'Extreme Sunlight & Heat Warning (${temp.toStringAsFixed(1)}°C)',
              'level': 'WARNING',
              'icon': Icons.wb_sunny_rounded,
              'color': Colors.amber,
              'description': 'High temperature and intense solar radiation index detected. Ensure high hydration levels and wear sunscreen.',
              'impact': 'Mid-day outdoor walks are highly demanding. Take frequent shade breaks.',
              'canReroute': false,
            });
          }

          // 4. Default Optimal Weather Alert (calm weather)
          if (tempAlerts.isEmpty) {
            String desc = 'Clear sky conditions detected.';
            if (weatherCode == 3) {
              desc = 'Overcast sky conditions.';
            } else if ([45, 48].contains(weatherCode)) {
              desc = 'Foggy conditions detected.';
            }

            tempAlerts.add({
              'id': 'w-calm',
              'title': 'Optimal Weather Alert (${temp.toStringAsFixed(1)}°C)',
              'level': 'INFO',
              'icon': Icons.cloud_done_outlined,
              'color': Colors.teal,
              'description': '$desc Local weather parameters indicate normal/excellent conditions for sightseeing and transit.',
              'impact': 'Excellent opportunities for all outdoor walking tours and photography.',
              'canReroute': false,
            });
          }

          if (mounted) {
            setState(() {
              _weatherAlerts = tempAlerts;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching open-meteo weather: $e');
    }
  }

  void _triggerAiReroute() {
    setState(() {
      _reroutingInProgress = true;
    });

    SoundSynthesizer.playTone(frequency: 580, durationSeconds: 0.3, endFrequency: 980, name: 'reroute_search.wav');

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;

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

      ref.read(itineraryProvider.notifier).applyAiReroute(1, indoorActivities, 'Indoor Digital Art & Culinary (Weather Optimized)');
      ref.read(userProfileProvider.notifier).addXP(150);

      setState(() {
        _reroutingInProgress = false;
        _rerouteApplied = true;
      });

      SoundSynthesizer.playUnlockChime();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkProvider);
    final userProfile = ref.watch(userProfileProvider).profile;
    final visaExpiry = userProfile['visaExpiry'] as String? ?? '';
    final visaCountry = userProfile['visaCountry'] as String? ?? 'Destination Country';
    final List<Map<String, dynamic>> visaAlerts = [];

    if (visaExpiry.isNotEmpty) {
      try {
        final expiryDate = DateTime.parse(visaExpiry);
        final today = DateTime(2026, 7, 8); // matching system clock reference
        final difference = expiryDate.difference(today).inDays;
        if (difference <= 0) {
          visaAlerts.add({
            'id': 'visa-expired',
            'title': 'Expired Visa Action Required',
            'level': 'CRITICAL',
            'icon': Icons.dangerous_rounded,
            'color': Colors.red,
            'description': 'Your Travel Visa for $visaCountry expired on $visaExpiry. You must renew or obtain a new visa immediately to avoid detention, deportation, or border denial.',
            'impact': 'Cannot enter or stay in $visaCountry.',
            'canReroute': false,
          });
        } else if (difference <= 21) {
          final weeks = (difference / 7).toStringAsFixed(1);
          visaAlerts.add({
            'id': 'visa-expiry-warning',
            'title': 'Visa Expiration Warning ($visaCountry)',
            'level': 'WARNING',
            'icon': Icons.warning_amber_rounded,
            'color': Colors.redAccent,
            'description': 'Your Travel Visa for $visaCountry is expiring in $difference days ($weeks weeks) on $visaExpiry. Please take immediate action if you are currently in or planning to travel to $visaCountry.',
            'impact': 'Risk of overstay fines or entry denial.',
            'canReroute': false,
          });
        }
      } catch (_) {}
    }

    final allAlerts = [...visaAlerts, ..._weatherAlerts, ..._transitAlerts];

    return Scaffold(
      backgroundColor: TriaColors.scaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: TriaColors.cardBg(isDark),
        elevation: 0.5,
        iconTheme: IconThemeData(color: TriaColors.textPrimary(isDark)),
        title: Text(
          'Real-Time Crisis Alerts',
          style: TextStyle(
            color: TriaColors.textPrimary(isDark),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top status card with live location readout
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TriaColors.cardBg(isDark),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: TriaColors.border(isDark)),
                  ),
                  child: Column(
                    children: [
                      Row(
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Crisis Hub Active',
                                  style: TextStyle(
                                    color: TriaColors.textPrimary(isDark),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Scanning weather & transit databases for current location anomalies.',
                                  style: TextStyle(
                                    color: TriaColors.textMuted(isDark),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_latitude != null && _longitude != null) ...[
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Color(0xFF00B4D8)),
                                const SizedBox(width: 6),
                                Text(
                                  'Present Location:',
                                  style: TextStyle(
                                    color: TriaColors.textMuted(isDark),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${_latitude!.toStringAsFixed(4)}°, ${_longitude!.toStringAsFixed(4)}°',
                              style: TextStyle(
                                color: TriaColors.textPrimary(isDark),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_locationError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _locationError!,
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ACTIVE ALERTS & RADAR DISRUPTIONS',
                      style: TextStyle(
                        color: isDark ? Colors.white30 : const Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (_loadingLocation)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF00B4D8)),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _loadLocationAndWeather,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_loadingLocation && allAlerts.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(color: Color(0xFF00B4D8)),
                          const SizedBox(height: 16),
                          Text(
                            'Requesting Location Access...',
                            style: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...allAlerts.map((alert) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: TriaColors.cardBg(isDark),
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
                                    style: TextStyle(
                                      color: TriaColors.textPrimary(isDark),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
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
                          Divider(height: 24, color: TriaColors.border(isDark)),
                          Text(
                            alert['description'],
                            style: TextStyle(
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Color(0xFF00B4D8), size: 14),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Impact: ${alert['impact']}',
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFFC7D2FE) : const Color(0xFF312E81),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                    ),
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
                color: isDark ? Colors.black87 : Colors.white.withValues(alpha: 0.9),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF00B4D8)),
                    const SizedBox(height: 20),
                    Text(
                      'COMPUTING SAFE CLOUD PATHS...',
                      style: TextStyle(
                        color: TriaColors.textPrimary(isDark),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Updating itinerary blocks with weather-proof indoor activities.',
                      style: TextStyle(
                        color: TriaColors.textSecondary(isDark),
                        fontSize: 10,
                      ),
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
