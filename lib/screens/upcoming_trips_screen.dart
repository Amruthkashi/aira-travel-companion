import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/theme_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/travel_providers.dart';
import '../core/utils/sound_synthesizer.dart';

class UpcomingTripsScreen extends ConsumerWidget {
  const UpcomingTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkProvider);
    final trips = ref.watch(upcomingTripsProvider);

    return Scaffold(
      backgroundColor: TriaColors.scaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: TriaColors.cardBg(isDark),
        elevation: 0.5,
        iconTheme: IconThemeData(color: TriaColors.textPrimary(isDark)),
        title: Text(
          'My Upcoming Trips',
          style: TextStyle(
            color: TriaColors.textPrimary(isDark),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: trips.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 64,
                    color: TriaColors.textMuted(isDark).withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Upcoming Trips Yet',
                    style: TextStyle(
                      color: TriaColors.textPrimary(isDark),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create an itinerary to schedule a future journey.',
                    style: TextStyle(
                      color: TriaColors.textMuted(isDark),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      SoundSynthesizer.playUnlockChime();
                      context.push('/create-itinerary');
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create New Itinerary', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: TriaColors.cardBg(isDark),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: TriaColors.border(isDark)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      SoundSynthesizer.playTone(
                        frequency: 600,
                        durationSeconds: 0.15,
                        name: 'trip_tap.wav',
                      );
                      context.push('/itinerary-detail/${trip.tripId}');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A8A), // Indigo 900
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  trip.tripId,
                                  style: const TextStyle(
                                    color: Color(0xFF93C5FD), // Blue 300
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  SoundSynthesizer.playTone(
                                    frequency: 440,
                                    durationSeconds: 0.25,
                                    name: 'delete_tap.wav',
                                  );
                                  _showDeleteConfirmation(context, ref, trip.tripId, trip.destination);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DEPARTING FROM',
                                      style: TextStyle(
                                        color: TriaColors.textMuted(isDark),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      trip.source,
                                      style: TextStyle(
                                        color: TriaColors.textPrimary(isDark),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Icon(
                                  Icons.arrow_forward,
                                  color: const Color(0xFF00B4D8).withValues(alpha: 0.8),
                                  size: 18,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DESTINATION',
                                      style: TextStyle(
                                        color: TriaColors.textMuted(isDark),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      trip.destination,
                                      style: TextStyle(
                                        color: TriaColors.textPrimary(isDark),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 28, color: TriaColors.border(isDark)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 14, color: Color(0xFF00B4D8)),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}',
                                    style: TextStyle(
                                      color: TriaColors.textPrimary(isDark),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    'View Itinerary',
                                    style: TextStyle(
                                      color: const Color(0xFF2563EB),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, size: 16, color: Color(0xFF2563EB)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String tripId, String destination) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A1628),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Trip?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
            'Are you sure you want to delete your trip to $destination?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                ref.read(upcomingTripsProvider.notifier).removeTrip(tripId);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
