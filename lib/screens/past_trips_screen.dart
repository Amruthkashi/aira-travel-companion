import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/theme_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/travel_providers.dart';
import '../core/utils/sound_synthesizer.dart';

class PastTripsScreen extends ConsumerWidget {
  const PastTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pastTrips = ref.watch(pastTripsProvider);
    final isDark = ref.watch(isDarkProvider);

    return Scaffold(
      backgroundColor: AiraColors.scaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: AiraColors.cardBg(isDark),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AiraColors.scaffoldBg(isDark),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.arrow_back, color: AiraColors.textPrimary(isDark), size: 18),
                onPressed: () {
                  SoundSynthesizer.playTone(
                    frequency: 600,
                    durationSeconds: 0.08,
                    name: 'back_tap.wav',
                  );
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ),
        title: Text(
          'PAST JOURNEYS',
          style: TextStyle(
            color: AiraColors.textPrimary(isDark),
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 1.5,
            fontFamily: 'monospace',
          ),
        ),
        centerTitle: true,
        actions: [
          if (pastTrips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                ),
                onPressed: () {
                  SoundSynthesizer.playTone(
                    frequency: 400,
                    durationSeconds: 0.15,
                    name: 'delete_all.wav',
                  );
                  ref.read(pastTripsProvider.notifier).clearTrips();
                },
                icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                label: const Text(
                  'Clear All',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: pastTrips.isEmpty
          ? _buildEmptyState(context, isDark)
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: pastTrips.length,
              itemBuilder: (context, index) {
                final trip = pastTrips[index];
                return _buildTripCard(context, ref, trip, isDark);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Styled Graphic Container representing "Not Yet Travelled"
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AiraColors.cardBg(isDark).withValues(alpha: 0.4),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.luggage_outlined,
                size: 80,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Not Yet Travelled',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AiraColors.textPrimary(isDark),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You haven\'t completed any past journeys yet. Once you finish an itinerary or archive past bookings, they will show up here as travel history.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AiraColors.textSecondary(isDark),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: () {
                SoundSynthesizer.playUnlockChime();
                Navigator.pop(context);
                context.push('/create-itinerary');
              },
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text(
                'Plan a New Trip with Aira',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, WidgetRef ref, PastTrip trip, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AiraColors.cardBg(isDark), // Card background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AiraColors.border(isDark), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Polaroid-styled Header Image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  trip.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF0A1628),
                    child: const Icon(Icons.image_not_supported, color: Colors.white30, size: 40),
                  ),
                ),
                // Blur Gradient at bottom
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                // City Name Overlay
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Text(
                    trip.destination,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Activities Completed Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B4D8).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${trip.activitiesCount} spots visited',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dates Range
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: Color(0xFF00B4D8), size: 14),
                    const SizedBox(width: 8),
                    Text(
                      trip.dates,
                      style: TextStyle(
                        color: AiraColors.textPrimary(isDark),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Theme details
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AiraColors.scaffoldBg(isDark),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AiraColors.border(isDark)),
                  ),
                  child: Row(
                    children: [
                      const Text('🎨', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Theme: ${trip.theme}',
                          style: TextStyle(
                            color: AiraColors.textSecondary(isDark),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Highlight / Journal notes
                Text(
                  trip.highlight,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                
                const SizedBox(height: 12),
                Divider(color: AiraColors.border(isDark), height: 1),
                const SizedBox(height: 12),
                
                // Card Actions (Delete & View Details)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent.withValues(alpha: 0.85)),
                      onPressed: () {
                        SoundSynthesizer.playTone(
                          frequency: 300,
                          durationSeconds: 0.1,
                          name: 'delete_trip.wav',
                        );
                        ref.read(pastTripsProvider.notifier).removeTrip(trip.id);
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Delete Log', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AiraColors.scaffoldBg(isDark),
                        foregroundColor: const Color(0xFF00B4D8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: AiraColors.border(isDark)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        SoundSynthesizer.playTone(
                          frequency: 720,
                          durationSeconds: 0.08,
                          name: 'view_trip.wav',
                        );
                        // Open Scrapbook/Memories specifically for this past trip context!
                        context.push('/memories');
                      },
                      icon: const Icon(Icons.photo_library_outlined, size: 14),
                      label: const Text('View Scrapbook', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
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
}

