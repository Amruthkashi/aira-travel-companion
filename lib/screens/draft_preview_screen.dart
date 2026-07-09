import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/theme_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/travel_providers.dart';
import '../core/models/travel_models.dart';
import '../core/services/ai_service.dart';
import '../core/utils/timeline_validator.dart';

class DraftPreviewScreen extends ConsumerStatefulWidget {
  const DraftPreviewScreen({super.key});

  @override
  ConsumerState<DraftPreviewScreen> createState() => _DraftPreviewScreenState();
}

class _DraftPreviewScreenState extends ConsumerState<DraftPreviewScreen> {
  bool _isAccepting = false;
  double _acceptProgress = 0.0;

  /// Build the complete list of activities for a day, including logistics
  DateTime getBaseStartDate(TripBookings bookings) {
    if (bookings.startDate != null && bookings.startDate!.isNotEmpty) {
      try {
        return DateTime.parse(bookings.startDate!);
      } catch (_) {}
    }
    if (bookings.hotels.isNotEmpty) {
      try {
        return DateTime.parse(bookings.hotels.first.checkInDate);
      } catch (_) {}
    }
    if (bookings.flights.isNotEmpty) {
      try {
        return DateTime.parse(bookings.flights.first.departureDate);
      } catch (_) {}
    }
    return DateTime.now();
  }

  Future<void> _acceptItinerary() async {
    final draft = ref.read(draftItineraryProvider);
    if (draft == null) return;

    setState(() {
      _isAccepting = true;
      _acceptProgress = 0.0;
    });

    // Simulate progress
    for (int i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        setState(() => _acceptProgress = i / 10.0);
      }
    }

    final resolvedResult = validateAndResolveItinerary(draft);
    final allDaysActivities = resolvedResult.resolvedDays;

    // Convert draft schedule to ItineraryDay list WITH logistics
    final List<ItineraryDay> itineraryDays = [];
    for (int d = 0; d < draft.daySchedules.length; d++) {
      final dayItems = draft.daySchedules[d];
      final isFirstDay = d == 0;
      final isLastDay = d == draft.daySchedules.length - 1;

      // Auto-generate theme from genres + logistics
      final genres = dayItems.map((item) => item.place.genre).toSet();
      String theme;
      if (isFirstDay) {
        theme = 'Day ${d + 1}: Arrival${genres.isNotEmpty ? ' & ${genres.first}' : ''}';
      } else if (isLastDay) {
        theme = 'Day ${d + 1}: ${genres.isNotEmpty ? '${genres.first} & ' : ''}Departure';
      } else {
        theme = genres.isNotEmpty
            ? 'Day ${d + 1}: ${genres.take(2).join(' & ')}'
            : 'Day ${d + 1}: Free Exploration';
      }

      final activities = allDaysActivities[d].where((a) => !a.activity.startsWith('✨')).toList();

      itineraryDays.add(ItineraryDay(
        day: d + 1,
        theme: theme,
        activities: activities,
      ));
    }

    // Save to providers and backend
    ref.read(itineraryProvider.notifier).setItinerary(itineraryDays);

    final userProfile = ref.read(userProfileProvider);
    final email = userProfile.profile['email'] ?? '';
    if (email.toString().isNotEmpty) {
      await AiService.saveItinerary(email.toString(), itineraryDays);
    }

    // Save to upcomingTripsProvider persistent store
    final bookings = draft.bookings;
    String sourceCity = 'Bangalore, India';
    if (bookings.flights.isNotEmpty) {
      sourceCity = bookings.flights.first.departureCity;
    } else {
      final userCity = userProfile.profile['city'];
      if (userCity != null && userCity.toString().isNotEmpty) {
        sourceCity = userCity.toString();
      }
    }

    final uniqueId = 'TRIP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    ref.read(upcomingTripsProvider.notifier).addTrip(
      UpcomingTrip(
        tripId: uniqueId,
        source: sourceCity,
        destination: bookings.destination.isNotEmpty ? bookings.destination : 'Tokyo, Japan',
        startDate: bookings.startDate ?? DateTime.now().toString().split(' ').first,
        endDate: bookings.endDate ?? DateTime.now().add(const Duration(days: 3)).toString().split(' ').first,
        itinerary: itineraryDays,
      ),
    );

    // Reset wizard state
    ref.read(tripBookingsProvider.notifier).reset();
    ref.read(selectedPlacesProvider.notifier).state = [];
    ref.read(dayScheduleProvider.notifier).reset();
    ref.read(draftItineraryProvider.notifier).state = null;

    if (mounted) {
      setState(() => _isAccepting = false);
      
      // Navigate to trips tab
      ref.read(currentTabProvider.notifier).state = 2;
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(draftItineraryProvider);
    final isDark = ref.watch(isDarkProvider);

    if (draft == null) {
      return Scaffold(
        backgroundColor: TriaColors.scaffoldBg(isDark),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
              const SizedBox(height: 16),
              Text('No draft available', style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final resolvedResult = validateAndResolveItinerary(draft);
    final allDaysActivities = resolvedResult.resolvedDays;
    final validationReport = resolvedResult.report;

    final bookings = draft.bookings;
    final daySchedules = draft.daySchedules;
    final baseStart = getBaseStartDate(bookings);

    // Compute gap nights (nights without a hotel booking)
    int gapNights = 0;
    for (int d = 0; d < daySchedules.length; d++) {
      final dayDate = baseStart.add(Duration(days: d));
      final dateStr = '${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}';
      
      final departingFlights = bookings.flights.where((f) => f.departureDate == dateStr).toList();
      if (departingFlights.isNotEmpty) continue; // Flying out tonight, no hotel check needed

      final activeHotelsForNight = bookings.hotels.where((h) {
        try {
          final checkIn = DateTime.parse(h.checkInDate);
          final checkOut = DateTime.parse(h.checkOutDate);
          final dDate = DateTime(dayDate.year, dayDate.month, dayDate.day);
          final ci = DateTime(checkIn.year, checkIn.month, checkIn.day);
          final co = DateTime(checkOut.year, checkOut.month, checkOut.day);
          return (dDate.isAtSameMomentAs(ci) || dDate.isAfter(ci)) && dDate.isBefore(co);
        } catch (_) {
          return false;
        }
      }).toList();

      if (activeHotelsForNight.isEmpty) {
        gapNights++;
      }
    }

    // Compute totals
    int totalActivities = 0;
    double totalCostEstimate = 0;
    for (final day in daySchedules) {
      totalActivities += day.length;
      for (final item in day) {
        final costStr = item.place.estimatedCost
            .replaceAll('\$', '')
            .replaceAll(',', '')
            .replaceAll('+', '')
            .trim();
        totalCostEstimate += double.tryParse(costStr) ?? 0;
      }
    }

    return Scaffold(
      backgroundColor: TriaColors.scaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: TriaColors.scaffoldBg(isDark),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: TriaColors.textPrimary(isDark)),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Draft Preview', style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 18)),
            const Text('STEP 4 — REVIEW & ACCEPT', style: TextStyle(color: Color(0xFF00B4D8), fontWeight: FontWeight.w800, fontSize: 9, letterSpacing: 0.5)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.looks_4, color: Color(0xFF10B981), size: 14),
                SizedBox(width: 4),
                Text('4/4', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Progress indicator
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    _stepDot(true, 'Bookings', isDark),
                    _stepLine(true, isDark),
                    _stepDot(true, 'Explore', isDark),
                    _stepLine(true, isDark),
                    _stepDot(true, 'Schedule', isDark),
                    _stepLine(true, isDark),
                    _stepDot(true, 'Preview', isDark),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                              blurRadius: 16, offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.flight_takeoff, color: Colors.white70, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    bookings.destination.isNotEmpty ? bookings.destination : 'Your Trip',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('COMPLETE ITINERARY',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _summaryPill(Icons.calendar_today, '${daySchedules.length} Days', Colors.white.withValues(alpha: 0.15)),
                                const SizedBox(width: 8),
                                _summaryPill(Icons.place, '$totalActivities Places', Colors.white.withValues(alpha: 0.15)),
                                const SizedBox(width: 8),
                                _summaryPill(Icons.attach_money, '\$${totalCostEstimate.toStringAsFixed(0)}', Colors.white.withValues(alpha: 0.15)),
                              ],
                            ),
                            if (bookings.flights.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                '${bookings.flights.first.departureCity} → ${bookings.flights.first.arrivalCity}  •  ${bookings.flights.first.airline}',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                            if (bookings.hotels.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '🏨 ${bookings.hotels.first.hotelName}  •  ${bookings.hotels.first.checkInDate} → ${bookings.hotels.first.checkOutDate}',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildValidationReportCard(validationReport, isDark),

                      if (gapNights > 0) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.6) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.3) : const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Missing accommodations: $gapNights night${gapNights > 1 ? 's' : ''} do not have hotel stays.',
                                  style: TextStyle(color: isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.push('/hotels');
                                },
                                child: Text('Resolve', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF991B1B), fontSize: 11, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Day-by-day breakdown with logistics
                      ...List.generate(daySchedules.length, (dayIdx) {
                        final dayItems = daySchedules[dayIdx];
                        final isFirstDay = dayIdx == 0;
                        final isLastDay = dayIdx == daySchedules.length - 1;
                        final genres = dayItems.map((item) => item.place.genre).toSet();

                        final dayDate = baseStart.add(Duration(days: dayIdx));
                        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                        final dateNice = '${months[dayDate.month - 1]} ${dayDate.day}, ${dayDate.year}';

                        String dayTheme;
                        if (isFirstDay) {
                          dayTheme = 'Arrival${genres.isNotEmpty ? ' & ${genres.first}' : ''}';
                        } else if (isLastDay) {
                          dayTheme = '${genres.isNotEmpty ? '${genres.first} & ' : ''}Departure';
                        } else {
                          dayTheme = genres.isNotEmpty
                              ? genres.take(2).join(' & ')
                              : 'Free Day';
                        }

                        double dayCost = 0;
                        for (final item in dayItems) {
                          final costStr = item.place.estimatedCost
                              .replaceAll('\$', '')
                              .replaceAll(',', '')
                              .replaceAll('+', '')
                              .trim();
                          dayCost += double.tryParse(costStr) ?? 0;
                        }

                        // Build the full day timeline with logistics
                        final allActivities = allDaysActivities[dayIdx];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Day header
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isDark ? const Color(0xFF2563EB).withValues(alpha: 0.3) : TriaColors.border(isDark)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text('${dayIdx + 1}',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Day ${dayIdx + 1} — $dateNice',
                                          style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        Text(dayTheme,
                                          style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${allActivities.length} activities',
                                        style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                      if (dayCost > 0)
                                        Text('~\$${dayCost.toStringAsFixed(0)}',
                                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Timeline items — full logistics timeline
                            ...allActivities.asMap().entries.map((entry) {
                              final activity = entry.value;
                              final isLast = entry.key == allActivities.length - 1;
                              final isLogistic = activity.activity.startsWith('✈️') ||
                                  activity.activity.startsWith('🚕') ||
                                  activity.activity.startsWith('🏨') ||
                                  activity.activity.startsWith('🌅');
                              final isWarning = activity.activity.contains('⚠️');
                              final isFreeTime = activity.activity.startsWith('✨');

                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Timeline line
                                    SizedBox(
                                      width: 40,
                                      child: Column(
                                        children: [
                                          Container(
                                            width: isWarning ? 12 : (isLogistic ? 8 : 10),
                                            height: isWarning ? 12 : (isLogistic ? 8 : 10),
                                            decoration: BoxDecoration(
                                              color: isWarning
                                                  ? const Color(0xFFEF4444)
                                                  : (isLogistic
                                                      ? const Color(0xFFF59E0B)
                                                      : (isFreeTime
                                                          ? const Color(0xFF00B4D8)
                                                          : const Color(0xFF2563EB))),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isWarning
                                                    ? const Color(0xFFF87171)
                                                    : (isLogistic
                                                        ? const Color(0xFFFBBF24)
                                                        : (isFreeTime
                                                            ? const Color(0xFF60A5FA)
                                                            : const Color(0xFF60A5FA))),
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          if (!isLast)
                                            Expanded(
                                              child: Container(
                                                width: (isLogistic || isFreeTime) ? 1 : 2,
                                                color: isWarning
                                                    ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                                                    : (isFreeTime
                                                        ? const Color(0xFF00B4D8).withValues(alpha: 0.3)
                                                        : (isLogistic
                                                            ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                                                            : TriaColors.border(isDark))),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Activity card
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: isWarning
                                            ? () => context.push('/hotels')
                                            : (isFreeTime
                                                ? () => context.pop() // takes the user back to step 3 Day Planner
                                                : null),
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isWarning
                                                ? (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.4) : const Color(0xFFFFF1F2))
                                                : (isFreeTime
                                                    ? (isDark ? const Color(0xFF0F1E36).withValues(alpha: 0.4) : const Color(0xFFECFDF5))
                                                    : (isLogistic
                                                        ? (isDark ? const Color(0xFF1E3A5F).withValues(alpha: 0.5) : const Color(0xFFF1F5F9))
                                                        : TriaColors.cardBg(isDark))),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: isWarning
                                                  ? (isDark ? const Color(0xFFEF4444).withValues(alpha: 0.4) : const Color(0xFFFDA4AF))
                                                  : (isFreeTime
                                                      ? (isDark ? const Color(0xFF00B4D8).withValues(alpha: 0.3) : const Color(0xFF34D399))
                                                      : (isLogistic
                                                          ? (isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.2) : const Color(0xFFFBBF24).withValues(alpha: 0.5))
                                                          : TriaColors.border(isDark))),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  if (!isLogistic && !isWarning && !isFreeTime)
                                                    Padding(
                                                      padding: const EdgeInsets.only(right: 10),
                                                      child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(8),
                                                        child: Image.network(
                                                          // Find matching place image
                                                          dayItems.where((di) => di.place.name == activity.activity).isNotEmpty
                                                              ? dayItems.firstWhere((di) => di.place.name == activity.activity).place.imageUrl
                                                              : '',
                                                          width: 48, height: 48,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (ctx, err, st) => Container(
                                                            width: 48, height: 48,
                                                            color: TriaColors.border(isDark),
                                                            child: Icon(Icons.image, color: TriaColors.textMuted(isDark), size: 20),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  if (isFreeTime)
                                                    Padding(
                                                      padding: const EdgeInsets.only(right: 10),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(8),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFF00B4D8).withValues(alpha: 0.1),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.wb_sunny_outlined,
                                                          color: Color(0xFF00B4D8),
                                                          size: 20,
                                                        ),
                                                      ),
                                                    ),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(activity.activity,
                                                          style: TextStyle(
                                                            color: isWarning
                                                                ? const Color(0xFFF87171)
                                                                : (isFreeTime
                                                                    ? const Color(0xFF00B4D8)
                                                                    : (isLogistic ? const Color(0xFFFBBF24) : TriaColors.textPrimary(isDark))),
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: (isLogistic || isFreeTime) ? 12 : 13,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(activity.description,
                                                          style: TextStyle(
                                                            color: isWarning
                                                                ? const Color(0xFFFCA5A5)
                                                                : (isFreeTime
                                                                    ? TriaColors.textSecondary(isDark).withValues(alpha: 0.7)
                                                                    : TriaColors.textSecondary(isDark)),
                                                            fontSize: 10,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isWarning
                                                          ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                                          : (isFreeTime
                                                              ? const Color(0xFF00B4D8).withValues(alpha: 0.15)
                                                              : (isLogistic
                                                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                                                  : const Color(0xFF2563EB).withValues(alpha: 0.15))),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(activity.time,
                                                      style: TextStyle(
                                                        color: isWarning
                                                            ? const Color(0xFFF87171)
                                                            : (isFreeTime
                                                                ? const Color(0xFF00B4D8)
                                                                : (isLogistic ? const Color(0xFFFBBF24) : const Color(0xFF60A5FA))),
                                                        fontSize: 9, fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  if (activity.placeDetails.isNotEmpty && !isFreeTime) ...[
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Text(activity.placeDetails,
                                                        style: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 9),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                  if (isFreeTime) ...[
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Text(
                                                        activity.placeDetails.replaceAll('free-slot', ''),
                                                        style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 9, fontWeight: FontWeight.bold),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                  if (activity.cost != '-' && !isFreeTime) ...[
                                                    const SizedBox(width: 6),
                                                    Text(activity.cost,
                                                      style: TextStyle(
                                                        color: isWarning ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              if (isWarning) ...[
                                                const SizedBox(height: 8),
                                                ElevatedButton.icon(
                                                  onPressed: () => context.push('/hotels'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFFEF4444),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    minimumSize: Size.zero,
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                  icon: const Icon(Icons.add_shopping_cart, size: 12, color: Colors.white),
                                                  label: const Text('Book Hotel', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                          ],
                        );
                      }),
                      const SizedBox(height: 80), // Space for bottom bar
                    ],
                  ),
                ),
              ),

              // Bottom action bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TriaColors.cardBg(isDark),
                  border: Border(top: BorderSide(color: TriaColors.border(isDark))),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Edit button
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: TriaColors.border(isDark)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            foregroundColor: TriaColors.textSecondary(isDark),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Create Another
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: TriaColors.border(isDark)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            foregroundColor: const Color(0xFFF59E0B),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: () {
                            ref.read(tripBookingsProvider.notifier).reset();
                            ref.read(selectedPlacesProvider.notifier).state = [];
                            ref.read(dayScheduleProvider.notifier).reset();
                            ref.read(draftItineraryProvider.notifier).state = null;
                            context.go('/itinerary-wizard/bookings');
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('New', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Accept button
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isAccepting ? null : _acceptItinerary,
                            icon: const Icon(Icons.check_circle, size: 18, color: Colors.white),
                            label: const Text('Accept & Start Trip',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Accepting overlay
          if (_isAccepting)
            Positioned.fill(
              child: Container(
                color: TriaColors.scaffoldBg(isDark).withValues(alpha: 0.95),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.rocket_launch, color: Color(0xFF10B981), size: 48),
                    const SizedBox(height: 24),
                    const Text('FINALIZING YOUR TRIP',
                      style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _acceptProgress < 0.3 ? 'Saving itinerary...'
                          : _acceptProgress < 0.6 ? 'Syncing with backend...'
                          : _acceptProgress < 0.9 ? 'Generating day themes...'
                          : 'Launching your trip!',
                      style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _acceptProgress,
                          backgroundColor: TriaColors.cardBg(isDark),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                          minHeight: 6,
                        ),
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

  Widget _summaryPill(IconData icon, String text, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _stepDot(bool active, String label, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF2563EB) : TriaColors.cardBg(isDark),
              shape: BoxShape.circle,
              border: Border.all(color: active ? const Color(0xFF2563EB) : TriaColors.border(isDark), width: 2),
            ),
            child: active ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            color: active ? const Color(0xFF60A5FA) : TriaColors.textMuted(isDark),
            fontSize: 9, fontWeight: FontWeight.bold,
          )),
        ],
      ),
    );
  }

  Widget _stepLine(bool active, bool isDark) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: active ? const Color(0xFF2563EB) : TriaColors.border(isDark),
      ),
    );
  }

  Widget _buildValidationReportCard(ValidationReport report, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1E36) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.5) : TriaColors.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFF00B4D8), size: 18),
              const SizedBox(width: 8),
              Text(
                '🛡️ TIMELINE VALIDATION PASS',
                style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PASS',
                  style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Horizontal/Grid checklist of checks
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _validationCheckItem('Flights Validated', report.flightsValidated, isDark),
              _validationCheckItem('Hotels Validated', report.hotelsValidated, isDark),
              _validationCheckItem('Transfers Validated', report.transfersValidated, isDark),
              _validationCheckItem('Attractions Validated', report.attractionsValidated, isDark),
              _validationCheckItem('Timeline Validated', report.timelineValidated, isDark),
            ],
          ),
          if (report.conflictsFixed.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: TriaColors.border(isDark)),
            ),
            const Text(
              'CONFLICTS FIXED:',
              style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            ...report.conflictsFixed.map((conflict) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔧 ', style: TextStyle(fontSize: 11)),
                  Expanded(
                    child: Text(
                      conflict,
                      style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 11, height: 1.3),
                    ),
                  ),
                ],
              ),
            )),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: TriaColors.border(isDark)),
            ),
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 14),
                const SizedBox(width: 6),
                Text(
                  'No timing conflicts detected. All schedules are real-world ready!',
                  style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _validationCheckItem(String label, bool isValid, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.error_outline,
          color: isValid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

