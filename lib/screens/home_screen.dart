import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/theme_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/travel_providers.dart';
import '../core/utils/sound_synthesizer.dart';
import '../core/services/ai_service.dart';
import '../core/models/travel_models.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String selectedCategory = '👤 Solo Traveler';
  final Set<String> likedDestinations = {"Santorini", "Amalfi Coast"};
  final Set<String> _connectedBuddies = {};

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileState = ref.watch(userProfileProvider);
    final isDark = ref.watch(isDarkProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Top Decorative Ambient Travel Banner
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 240,
            child: ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  colors: isDark 
                      ? [Colors.black, Colors.black, Colors.transparent]
                      : [Colors.white, Colors.white, Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: Image.network(
                'https://images.unsplash.com/photo-1540959733332-eab4deceeaf7?w=800&auto=format&fit=crop&q=80', // Scramble Crossing Neon Night
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(),
              ),
            ),
          ),
          
          // 2. Dark linear gradient filter for top image blend
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 240,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    TriaColors.scaffoldBg(isDark).withValues(alpha: 0.1),
                    TriaColors.scaffoldBg(isDark).withValues(alpha: 0.7),
                    TriaColors.scaffoldBg(isDark),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3. Ambient Purple glow circle behind cards
          Positioned(
            top: 130,
            right: -60,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF7B2FF7).withValues(alpha: 0.14) : Colors.transparent, // Violet glow
                ),
              ),
            ),
          ),

          // 4. Ambient Teal glow circle near middle
          Positioned(
            top: 480,
            left: -80,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 85, sigmaY: 85),
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF0EA5E9).withValues(alpha: 0.08) : Colors.transparent, // Teal glow
                ),
              ),
            ),
          ),

          // 5. Scrollable Contents
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header (Glassmorphic layout)
                    _buildHeader(context, ref, userProfileState),
                    const SizedBox(height: 20),

                    // Metrics Pills Row
                    _buildMetricsPills(userProfileState),
                    const SizedBox(height: 22),

                    // Upcoming Trip Summary Box
                    _buildUpcomingTripSummaryBox(context, ref),
                    const SizedBox(height: 20),

                    // Portal Buttons (Create Itinerary & Previous Itinerary)
                    _buildPortalButtons(context, ref),
                    const SizedBox(height: 26),

                    // Quick Actions Bento Grid
                    _buildQuickActionsGrid(context, ref),
                    const SizedBox(height: 26),

                    // Discover Places
                    _buildDiscoverPlaces(),
                    const SizedBox(height: 26),

                    // AI Picks For You
                    _buildAiPicksList(context, ref),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, UserProfileState userProfileState) {
    final isDark = ref.read(isDarkProvider);
    final name = userProfileState.profile['fullName'] ?? 'Traveler';
    final firstName = name.split(' ').first;
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: TriaColors.cardBg(isDark).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TriaColors.border(isDark).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [

          // Compass Explorer branding logo badge
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF312E81).withValues(alpha: 0.6), // Indigo 900
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.explore, color: Color(0xFF00B4D8), size: 18),
          ),
          
          // Avatar with gradient & glow
          GestureDetector(
            onTap: () {
              ref.read(currentTabProvider.notifier).state = 4; // Switch to Profile tab
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
              ),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7B2FF7), Color(0xFFFF477E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials.isNotEmpty ? initials : 'TR',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Greeting text
          Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(currentTabProvider.notifier).state = 4; // Switch to Profile tab
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WELCOME BACK',
                    style: TextStyle(
                      color: Color(0xFF00B4D8), // Indigo 400
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    '$firstName 👋',
                    style: TextStyle(
                      color: TriaColors.textPrimary(isDark),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Action buttons (Dark Theme styling)
          _buildHeaderActionButton(
            icon: Icons.notifications_none_outlined,
            onTap: () => context.push('/alerts'),
            hasBadge: true,
          ),
          const SizedBox(width: 8),
          _buildHeaderActionButton(
            icon: Icons.favorite,
            iconColor: const Color(0xFFFF477E),
            onTap: () => context.push('/memories'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white70,
    bool hasBadge = false,
  }) {
    final isDark = ref.read(isDarkProvider);
    final col = iconColor == Colors.white70 ? TriaColors.textSecondary(isDark) : iconColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: TriaColors.cardBg(isDark),
          shape: BoxShape.circle,
          border: Border.all(color: TriaColors.border(isDark)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: col, size: 18),
            if (hasBadge)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsPills(UserProfileState userProfileState) {
    final upcomingTrip = userProfileState.profile['upcomingTrip'];
    final city = upcomingTrip != null ? upcomingTrip['city'] ?? 'Tokyo' : (userProfileState.profile['city'] ?? 'Tokyo');
    
    final String temp;
    final String lowercaseCity = city.toLowerCase();
    if (lowercaseCity.contains('tokyo') || lowercaseCity.contains('shibuya')) {
      temp = '22°C';
    } else if (lowercaseCity.contains('kyoto')) {
      temp = '18°C';
    } else if (lowercaseCity.contains('paris')) {
      temp = '20°C';
    } else if (lowercaseCity.contains('rome')) {
      temp = '26°C';
    } else if (lowercaseCity.contains('bali')) {
      temp = '30°C';
    } else {
      temp = '24°C';
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildMetricPill(
            icon: Icons.cloud_queue,
            iconColor: Colors.amber,
            text: '$city • $temp',
          ),
          const SizedBox(width: 8),
          _buildMetricPill(
            icon: Icons.military_tech_outlined,
            iconColor: const Color(0xFFFBBF24), // Gold
            text: 'Gold Member',
          ),
          const SizedBox(width: 8),
          _buildMetricPill(
            icon: Icons.auto_awesome_outlined,
            iconColor: const Color(0xFF34D399), // Emerald
            text: '${userProfileState.xpPoints} XP',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    final isDark = ref.read(isDarkProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: TriaColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: iconColor.withValues(alpha: 0.45), width: 1.2), // Neon border glow
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.08),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: TriaColors.textPrimary(isDark),
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCountdownCard(BuildContext context, WidgetRef ref) {
    final userProfileState = ref.watch(userProfileProvider);
    final upcomingTrip = userProfileState.profile['upcomingTrip'];
    final isDark = ref.watch(isDarkProvider);

    if (upcomingTrip == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: TriaColors.cardBg(isDark).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.explore_outlined, color: Color(0xFF00B4D8), size: 48),
            const SizedBox(height: 16),
            Text(
              'No Active Journey',
              style: TextStyle(
                color: TriaColors.textPrimary(isDark),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask Tria to plan your next itinerary or search locations to get started.',
              style: TextStyle(
                color: TriaColors.textSecondary(isDark),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                ref.read(currentTabProvider.notifier).state = 1; // Explore / Chat tab
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: const Text(
                'Ask Tria to Plan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final checklist = ref.watch(checklistProvider);
    final completed = checklist.where((item) => item.checked).length;
    final total = checklist.length;
    final progress = total > 0 ? completed / total : 0.0;

    String formatDateRange(String? start, String? end) {
      if (start == null || end == null) return 'Jun 15 - Jun 20';
      try {
        final sDate = DateTime.parse(start);
        final eDate = DateTime.parse(end);
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${months[sDate.month - 1]} ${sDate.day} - ${months[eDate.month - 1]} ${eDate.day}';
      } catch (e) {
        return '$start - $end';
      }
    }

    int daysRemaining(String? start) {
      if (start == null) return 13;
      try {
        final sDate = DateTime.parse(start);
        final now = DateTime.now();
        final diff = sDate.difference(DateTime(now.year, now.month, now.day)).inDays;
        return diff < 0 ? 0 : diff;
      } catch (e) {
        return 13;
      }
    }

    final city = upcomingTrip['city'] ?? 'Tokyo';
    final startDateStr = upcomingTrip['startDate'];
    final endDateStr = upcomingTrip['endDate'];

    Map<String, String> getTripDetails(String cityName) {
      final normCity = cityName.toLowerCase();
      String flight = 'SQ-638';
      String airline = 'Singapore Airlines';
      String hotel = 'Skyline Godzilla Hotel';
      String seat = '14A';
      String gate = 'T3, Gate 14B';
      String pnr = 'NH-782Y9W';

      if (normCity.contains('kyoto')) {
        flight = 'JL-738';
        airline = 'Japan Airlines';
        hotel = 'Kyoto Traditional Ryokan & Spa';
        seat = '18C';
        gate = 'T2, Gate 6B';
        pnr = 'JL-889X8W';
      } else if (normCity.contains('tokyo') || normCity.contains('shibuya')) {
        flight = 'SQ-638';
        airline = 'Singapore Airlines';
        hotel = 'Skyline Godzilla Hotel';
        seat = '14A';
        gate = 'T3, Gate 14B';
        pnr = 'NH-782Y9W';
      } else if (normCity.contains('paris')) {
        flight = 'AF-022';
        airline = 'Air France';
        hotel = 'Le Bristol Paris Luxury Hotel';
        seat = '10D';
        gate = 'T2E, Gate K33';
        pnr = 'AF-982B3X';
      } else if (normCity.contains('rome')) {
        flight = 'AZ-402';
        airline = 'ITA Airways';
        hotel = 'Hotel de Russie Rome';
        seat = '12A';
        gate = 'T1, Gate B12';
        pnr = 'AZ-772L9P';
      } else if (normCity.contains('bali')) {
        flight = 'GA-841';
        airline = 'Garuda Indonesia';
        hotel = 'Ubud Hanging Gardens Resort';
        seat = '21K';
        gate = 'Gate D4';
        pnr = 'GA-993T2Y';
      } else if (normCity.contains('london')) {
        flight = 'BA-112';
        airline = 'British Airways';
        hotel = 'The Savoy Hotel London';
        seat = '15F';
        gate = 'T5, Gate A14';
        pnr = 'BA-102K8M';
      } else if (normCity.contains('barcelona')) {
        flight = 'VY-1284';
        airline = 'Vueling Airlines';
        hotel = 'W Barcelona Beach Hotel';
        seat = '08F';
        gate = 'T1, Gate C30';
        pnr = 'VY-663R9A';
      } else if (normCity.contains('santorini')) {
        flight = 'GQ-230';
        airline = 'Sky Express';
        hotel = 'Grace Hotel Santorini';
        seat = '04C';
        gate = 'Gate 5';
        pnr = 'GQ-552K3Q';
      } else if (normCity.contains('venice')) {
        flight = 'LH-328';
        airline = 'Lufthansa';
        hotel = 'Belmond Hotel Cipriani';
        seat = '11A';
        gate = 'Gate A18';
        pnr = 'LH-883F2D';
      } else if (normCity.contains('amalfi')) {
        flight = 'EN-8290';
        airline = 'Air Dolomiti';
        hotel = 'Hotel Santa Caterina';
        seat = '09D';
        gate = 'Gate 12';
        pnr = 'AD-490K8W';
      } else if (normCity.contains('dubai')) {
        flight = 'EK-201';
        airline = 'Emirates';
        hotel = 'Burj Al Arab Jumeirah';
        seat = '22A';
        gate = 'T3, Gate B24';
        pnr = 'EK-772L3P';
      } else if (normCity.contains('orlando')) {
        flight = 'UA-2042';
        airline = 'United Airlines';
        hotel = 'Four Seasons Resort Orlando';
        seat = '16B';
        gate = 'T1, Gate B10';
        pnr = 'UA-882K3Y';
      } else if (normCity.contains('bangkok')) {
        flight = 'TG-640';
        airline = 'Thai Airways';
        hotel = 'Mandarin Oriental Bangkok';
        seat = '12F';
        gate = 'Gate E8';
        pnr = 'TG-993L2D';
      } else if (normCity.contains('hanoi')) {
        flight = 'VN-512';
        airline = 'Vietnam Airlines';
        hotel = 'Sofitel Legend Metropole Hanoi';
        seat = '15A';
        gate = 'Gate A3';
        pnr = 'VN-773M9L';
      } else if (normCity.contains('milan')) {
        flight = 'AZ-290';
        airline = 'ITA Airways';
        hotel = 'Armani Hotel Milano';
        seat = '08D';
        gate = 'Gate B4';
        pnr = 'AZ-883K1P';
      } else if (normCity.contains('new york')) {
        flight = 'DL-412';
        airline = 'Delta Air Lines';
        hotel = 'The Plaza Hotel New York';
        seat = '14C';
        gate = 'T4, Gate B20';
        pnr = 'DL-993T8X';
      } else if (normCity.contains('costa rica')) {
        flight = 'AA-952';
        airline = 'American Airlines';
        hotel = 'Nayara Tented Camp Costa Rica';
        seat = '19F';
        gate = 'Gate D14';
        pnr = 'AA-443T9M';
      } else if (normCity.contains('serengeti')) {
        flight = 'KQ-482';
        airline = 'Kenya Airways';
        hotel = 'Four Seasons Safari Lodge Serengeti';
        seat = '11C';
        gate = 'Gate 2A';
        pnr = 'KQ-882T9W';
      } else {
        flight = 'UA-839';
        airline = 'United Airlines';
        hotel = 'Luxury Premium Suites';
        seat = '12B';
        gate = 'Gate B18';
        pnr = 'UA-102T9X';
      }

      return {
        'flight': flight,
        'airline': airline,
        'hotel': hotel,
        'seat': seat,
        'gate': gate,
        'pnr': pnr,
      };
    }

    final tripDetails = getTripDetails(city);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: TriaColors.cardBg(isDark).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.45), width: 1.2), // Indigo glowing border
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF312E81), // Indigo 900
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.flight_takeoff, color: Color(0xFFC7D2FE), size: 14),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$city Adventure',
                      style: TextStyle(
                        color: TriaColors.textPrimary(isDark),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF312E81), // Indigo 900
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'UPCOMING',
                    style: TextStyle(
                      color: Color(0xFFC7D2FE), // Indigo 200
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              daysRemaining(startDateStr) == 0 ? 'Departing Today!' : 'Departing in ${daysRemaining(startDateStr)} Days',
              style: TextStyle(
                color: TriaColors.textPrimary(isDark),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          
          // Ticket stub visual cutout line
          Row(
            children: [
              Container(
                height: 14,
                width: 7,
                decoration: BoxDecoration(
                  color: TriaColors.scaffoldBg(isDark),
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Flex(
                      direction: Axis.horizontal,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        (constraints.constrainWidth() / 8).floor(),
                        (index) => SizedBox(
                          width: 4,
                          height: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: TriaColors.textMuted(isDark).withValues(alpha: 0.15)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                height: 14,
                width: 7,
                decoration: BoxDecoration(
                  color: TriaColors.scaffoldBg(isDark),
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          
          // Flight details box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TriaColors.scaffoldBg(isDark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TriaColors.border(isDark)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Color(0xFF64748B), size: 14),
                          const SizedBox(width: 6),
                          Text(
                            formatDateRange(startDateStr, endDateStr),
                            style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        tripDetails['pnr'] ?? 'NH-782Y9W',
                        style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 10.5, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  Divider(color: TriaColors.border(isDark).withValues(alpha: 0.5), height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Flight ${tripDetails['flight'] ?? 'SQ-638'} (${tripDetails['airline'] ?? 'SIA'})',
                        style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 10.5),
                      ),
                      Text(
                        'Seat ${tripDetails['seat'] ?? '14A'}',
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Checklist progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trip Checklist Progress',
                  style: TextStyle(
                    color: TriaColors.textSecondary(isDark),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$completed of $total tasks',
                  style: const TextStyle(
                    color: Color(0xFF00B4D8), // Indigo 400
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: TriaColors.scaffoldBg(isDark),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                minHeight: 5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Visual barcode strip at the bottom of boarding pass
          Container(
            height: 30,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                36,
                (index) {
                  final width = (index % 3 == 0) ? 3.0 : ((index % 5 == 0) ? 1.0 : 2.0);
                  final space = (index % 4 == 0) ? 3.0 : 1.5;
                  return Container(
                    width: width,
                    height: double.infinity,
                    margin: EdgeInsets.only(right: space),
                    color: isDark 
                        ? Colors.white.withValues(alpha: index % 6 == 0 ? 0.04 : 0.2)
                        : Colors.black.withValues(alpha: index % 6 == 0 ? 0.04 : 0.2),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, WidgetRef ref) {
    final List<Map<String, dynamic>> items = [
      {
        'title': 'Travel Buddies',
        'icon': Icons.people_outline,
        'color1': const Color(0xFF2563EB),
        'color2': const Color(0xFF00B4D8), // Indigo gradient
        'onTap': () {
          _showTravelBuddiesModal();
        },
      },
      {
        'title': 'Translator',
        'icon': Icons.translate,
        'color1': const Color(0xFF334155),
        'color2': const Color(0xFF64748B), // Metallic slate gradient
        'onTap': () => context.push('/translator'),
      },
      {
        'title': 'Trip Bookings',
        'icon': Icons.work_outline,
        'color1': const Color(0xFF7C3AED),
        'color2': const Color(0xFFA78BFA), // Violet gradient
        'onTap': () => context.push('/bookings-hub'),
      },
      {
        'title': 'Audio Guide',
        'icon': Icons.headphones,
        'color1': const Color(0xFFFF477E),
        'color2': const Color(0xFFF472B6), // Rose gradient
        'onTap': () => context.push('/audio-guide'),
      },
      {
        'title': 'Travel Squads',
        'icon': Icons.groups_outlined,
        'color1': const Color(0xFF2563EB),
        'color2': const Color(0xFF7B2FF7), // Premium violet glow
        'onTap': () {
          _showTravelSquadsModal(context, ref);
        },
      },
      {
        'title': 'Scrapbook',
        'icon': Icons.photo_camera_outlined,
        'color1': const Color(0xFFD97706),
        'color2': const Color(0xFFFBBF24), // Amber gradient
        'onTap': () => context.push('/memories'),
      },
    ];

    final isDark = ref.watch(isDarkProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            color: TriaColors.textMuted(isDark),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemCount: items.length,
          itemBuilder: (context, idx) {
            final item = items[idx];
            return GestureDetector(
              onTap: () {
                SoundSynthesizer.playTone(
                  frequency: 720,
                  durationSeconds: 0.1,
                  name: 'action_tap.wav',
                );
                item['onTap']();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: TriaColors.cardBg(isDark).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TriaColors.border(isDark)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Gradient Icon box
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [item['color1'] as Color, item['color2'] as Color],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (item['color1'] as Color).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(item['icon'], color: Colors.white, size: 18),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        item['title'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: TriaColors.textPrimary(isDark),
                          fontWeight: FontWeight.bold,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUpcomingTripSummaryBox(BuildContext context, WidgetRef ref) {
    final rawTrips = ref.watch(upcomingTripsProvider);
    final isDark = ref.watch(isDarkProvider);

    // Sort to show the nearest upcoming trip chronologically
    final trips = List<UpcomingTrip>.from(rawTrips);
    trips.sort((a, b) {
      try {
        final dateA = DateTime.parse(a.startDate);
        final dateB = DateTime.parse(b.startDate);
        return dateA.compareTo(dateB);
      } catch (_) {
        return a.startDate.compareTo(b.startDate);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'UPCOMING TRIP',
              style: TextStyle(
                color: isDark ? Colors.white30 : const Color(0xFF64748B),
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            if (trips.isNotEmpty)
              GestureDetector(
                onTap: () => context.push('/upcoming-trips'),
                child: const Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 14, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            if (trips.isNotEmpty) {
              context.push('/itinerary-detail/${trips.first.tripId}');
            } else {
              context.push('/upcoming-trips');
            }
          },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: TriaColors.cardBg(isDark).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.25 : 0.12),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: trips.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.calendar_today_outlined,
                            color: Color(0xFF2563EB),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No Upcoming Journeys',
                                style: TextStyle(
                                  color: TriaColors.textPrimary(isDark),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Tap to plan your next adventure with Tria AI.',
                                style: TextStyle(
                                  color: TriaColors.textMuted(isDark),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Elegant Trip Details Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.08 : 0.04),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.card_membership_outlined, color: Color(0xFF2563EB), size: 13),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${trips.first.itinerary.length} DAYS JOURNEY',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                _formatTripDates(trips.first.startDate, trips.first.endDate),
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Source and Destination abbreviations
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        trips.first.source.toUpperCase().substring(0, trips.first.source.length >= 3 ? 3 : trips.first.source.length),
                                        style: TextStyle(
                                          color: TriaColors.textPrimary(isDark),
                                          fontSize: 26,
                                          fontFamily: 'Outfit',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        trips.first.source,
                                        style: TextStyle(
                                          color: TriaColors.textMuted(isDark),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Plane Line Icon separator
                                Expanded(
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              height: 1.5,
                                              color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                            ),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 6),
                                            child: Icon(Icons.flight_takeoff, color: Color(0xFF2563EB), size: 18),
                                          ),
                                          Expanded(
                                            child: Container(
                                              height: 1.5,
                                              color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'TRIP ID: ${trips.first.tripId}',
                                        style: TextStyle(
                                          color: TriaColors.textMuted(isDark),
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        trips.first.destination.toUpperCase().substring(0, trips.first.destination.length >= 3 ? 3 : trips.first.destination.length),
                                        style: TextStyle(
                                          color: TriaColors.textPrimary(isDark),
                                          fontSize: 26,
                                          fontFamily: 'Outfit',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        trips.first.destination,
                                        style: TextStyle(
                                          color: TriaColors.textMuted(isDark),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            // Dotted Divider
                            const SizedBox(height: 18),
                            Row(
                              children: List.generate(
                                30,
                                (index) => Expanded(
                                  child: Container(
                                    color: index % 2 == 0 ? Colors.transparent : TriaColors.border(isDark),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            
                            // 2x2 Details Bento Grid
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left details column (Airline & budget)
                                Expanded(
                                  child: Column(
                                    children: [
                                      // Airline carrier
                                      _buildTripDetailItem(
                                        icon: Icons.flight,
                                        iconColor: const Color(0xFF00B4D8),
                                        title: 'FLIGHTS & TRANSIT',
                                        value: _getAirline(trips.first),
                                        isDark: isDark,
                                      ),
                                      const SizedBox(height: 14),
                                      // Estimated Budget
                                      _buildTripDetailItem(
                                        icon: Icons.monetization_on_outlined,
                                        iconColor: const Color(0xFF10B981),
                                        title: 'ESTIMATED BUDGET',
                                        value: _getEstimatedBudget(trips.first),
                                        isDark: isDark,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Right details column (Hotel & activities count)
                                Expanded(
                                  child: Column(
                                    children: [
                                      // Accommodation
                                      _buildTripDetailItem(
                                        icon: Icons.hotel_class_outlined,
                                        iconColor: const Color(0xFFF59E0B),
                                        title: 'STAY / HOTEL',
                                        value: _getHotel(trips.first),
                                        isDark: isDark,
                                      ),
                                      const SizedBox(height: 14),
                                      // Activities Count
                                      _buildTripDetailItem(
                                        icon: Icons.event_available_outlined,
                                        iconColor: const Color(0xFF8B5CF6),
                                        title: 'PLANNED EVENTS',
                                        value: '${_getTotalActivities(trips.first)} Activities scheduled',
                                        isDark: isDark,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            // Places visiting bottom section
                            const SizedBox(height: 18),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.pin_drop_outlined, color: Color(0xFFEF4444), size: 16),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'HIGHLIGHTS & KEY SPOTS',
                                        style: TextStyle(
                                          color: TriaColors.textMuted(isDark),
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: _getMainPlaces(trips.first).map((place) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: (isDark ? Colors.white24 : Colors.black12),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              place,
                                              style: TextStyle(
                                                color: TriaColors.textSecondary(isDark),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTripDetailItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: TriaColors.textMuted(isDark),
                  fontSize: 7.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: TriaColors.textPrimary(isDark),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getAirline(UpcomingTrip trip) {
    for (var day in trip.itinerary) {
      for (var act in day.activities) {
        final activity = act.activity;
        final desc = act.description;
        final transport = act.transport;
        final ticket = act.ticketInfo;

        final isFlight = transport.toLowerCase() == 'flight' ||
            activity.contains('✈️') ||
            ticket.toLowerCase().contains('pnr') ||
            activity.toLowerCase().contains('flight') ||
            desc.toLowerCase().contains('flight') ||
            desc.toLowerCase().contains('airline') ||
            desc.toLowerCase().contains('flying');

        if (isFlight) {
          final descLower = desc.toLowerCase();
          final landsIndex = descLower.indexOf(' lands at');
          if (landsIndex != -1) {
            final possibleAirline = desc.substring(0, landsIndex).trim();
            if (possibleAirline.isNotEmpty) return possibleAirline;
          }
          final departsIndex = descLower.indexOf(' departs from');
          if (departsIndex != -1) {
            final possibleAirline = desc.substring(0, departsIndex).trim();
            if (possibleAirline.isNotEmpty) return possibleAirline;
          }

          // Search in hardcoded list
          final airlines = ['emirates', 'singapore', 'qatar', 'ana', 'jal', 'indigo', 'delta', 'united', 'lufthansa', 'british airways', 'air france', 'air india', 'klm', 'cathay', 'etihad', 'qantas', 'ryanair', 'easyjet', 'spicejet', 'akasa', 'vistara'];
          for (var airline in airlines) {
            if (descLower.contains(airline) || activity.toLowerCase().contains(airline)) {
              return airline == 'ana' || airline == 'jal' || airline == 'klm'
                  ? airline.toUpperCase()
                  : airline.split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
            }
          }

          if (ticket.isNotEmpty) {
            final cleanedPnr = ticket.replaceAll('PNR:', '').trim();
            if (cleanedPnr.isNotEmpty) {
              return 'Scheduled Flight ($cleanedPnr)';
            }
          }
          return 'Scheduled Flight';
        }
      }
    }
    return 'No Flights Booked';
  }

  String _getHotel(UpcomingTrip trip) {
    for (var day in trip.itinerary) {
      for (var act in day.activities) {
        final title = act.activity;
        final desc = act.description;
        final loc = act.locationName;
        final text = '$title $desc $loc'.toLowerCase();
        if (text.contains('hotel') || text.contains('resort') || text.contains('stay') || text.contains('check-in') || text.contains('check in') || text.contains('hostel') || text.contains('airbnb') || text.contains('lodging')) {
          if (loc.isNotEmpty && (loc.toLowerCase().contains('hotel') || loc.toLowerCase().contains('resort') || loc.toLowerCase().contains('stay') || loc.toLowerCase().contains('inn') || loc.toLowerCase().contains('hostel') || loc.toLowerCase().contains('suites') || loc.toLowerCase().contains('villa') || loc.toLowerCase().contains('lodge'))) {
            return loc;
          }
          if (title.toLowerCase().contains('hotel') || title.toLowerCase().contains('resort') || title.toLowerCase().contains('hostel') || title.toLowerCase().contains('stay at') || title.toLowerCase().contains('stay in')) {
            return title.replaceAll(RegExp(r'check-in\s+(?:at|to|in)\s+|stay\s+(?:at|in)\s+|check\s+in\s+(?:at|to|in)\s+', caseSensitive: false), '').trim();
          }
          if (loc.isNotEmpty) return loc;
          return title;
        }
      }
    }
    return 'No Hotel Booked';
  }

  String _getEstimatedBudget(UpcomingTrip trip) {
    double total = 0;
    for (var day in trip.itinerary) {
      for (var act in day.activities) {
        final costStr = act.cost.replaceAll(RegExp(r'[^0-9.]'), '');
        if (costStr.isNotEmpty) {
          try {
            total += double.parse(costStr);
          } catch (_) {}
        }
      }
    }
    return total > 0 ? '\$${total.toStringAsFixed(0)} Est.' : 'TBA / Free';
  }

  int _getTotalActivities(UpcomingTrip trip) {
    int count = 0;
    for (var day in trip.itinerary) {
      count += day.activities.length;
    }
    return count;
  }

  List<String> _getMainPlaces(UpcomingTrip trip) {
    final List<String> places = [];
    
    // First pass: try to get actual tourist/important attractions (highly filtered)
    for (var day in trip.itinerary) {
      for (var act in day.activities) {
        final title = act.activity;
        final titleLower = title.toLowerCase();
        
        final isGeneric = titleLower.contains('flight') ||
            titleLower.contains('hotel') ||
            titleLower.contains('check-in') ||
            titleLower.contains('check in') ||
            titleLower.contains('checkout') ||
            titleLower.contains('check out') ||
            titleLower.contains('airport') ||
            titleLower.contains('dinner') ||
            titleLower.contains('breakfast') ||
            titleLower.contains('lunch') ||
            titleLower.contains('rest') ||
            titleLower.contains('arrive') ||
            titleLower.contains('depart') ||
            titleLower.contains('preparation') ||
            titleLower.contains('prep') ||
            titleLower.contains('transfer') ||
            titleLower.contains('transit') ||
            titleLower.contains('taxi') ||
            titleLower.contains('cab') ||
            titleLower.contains('shuttle') ||
            titleLower.contains('ride') ||
            titleLower.contains('drive') ||
            titleLower.contains('wake up') ||
            titleLower.contains('leisure') ||
            titleLower.contains('free time') ||
            titleLower.contains('packing') ||
            titleLower.contains('travel to') ||
            titleLower.contains('walk to') ||
            titleLower.contains('heading to') ||
            titleLower.contains('stay at') ||
            titleLower.contains('inn') ||
            titleLower.contains('suites') ||
            titleLower.contains('resort') ||
            titleLower.contains('lodging');

        if (!isGeneric && !places.contains(title) && title.length < 32 && title.isNotEmpty) {
          places.add(title);
          if (places.length >= 3) break;
        }
      }
      if (places.length >= 3) break;
    }
    
    // Second pass: if we have fewer than 3, add other non-transit/non-airport activities
    if (places.length < 3) {
      for (var day in trip.itinerary) {
        for (var act in day.activities) {
          final title = act.activity;
          final titleLower = title.toLowerCase();
          
          final isTransit = titleLower.contains('flight') ||
              titleLower.contains('transfer') ||
              titleLower.contains('transit') ||
              titleLower.contains('airport') ||
              titleLower.contains('arrive') ||
              titleLower.contains('depart') ||
              titleLower.contains('taxi') ||
              titleLower.contains('cab') ||
              titleLower.contains('shuttle') ||
              titleLower.contains('ride') ||
              titleLower.contains('drive') ||
              titleLower.contains('travel to');
              
          if (!isTransit && !places.contains(title) && title.length < 32 && title.isNotEmpty) {
            places.add(title);
            if (places.length >= 3) break;
          }
        }
        if (places.length >= 3) break;
      }
    }
    
    // Third pass fallback: just fill up with any activity titles that aren't empty
    if (places.length < 3) {
      for (var day in trip.itinerary) {
        for (var act in day.activities) {
          final title = act.activity;
          if (!places.contains(title) && title.length < 32 && title.isNotEmpty) {
            places.add(title);
            if (places.length >= 3) break;
          }
        }
        if (places.length >= 3) break;
      }
    }

    if (places.isEmpty) {
      return ['Sightseeing & Explore'];
    }
    return places;
  }

  Widget _buildPortalButtons(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _buildGradientPortalCard(
          title: 'Create New Itinerary',
          subtitle: 'AI-assisted custom route planner',
          icon: Icons.auto_awesome,
          onTap: () {
            context.push('/create-itinerary');
          },
        ),
        const SizedBox(height: 10),
        _buildPortalCard(
          title: 'Previously Travelled',
          subtitle: 'Completed stays & travel memories',
          icon: Icons.history,
          iconColor: const Color(0xFF94A3B8),
          onTap: () => context.push('/past-trips'),
        ),
      ],
    );
  }

  String _formatTripDates(String startStr, String endStr) {
    try {
      final start = DateTime.parse(startStr);
      final end = DateTime.parse(endStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[start.month - 1]} ${start.day} - ${months[end.month - 1]} ${end.day}';
    } catch (_) {
      return '$startStr to $endStr';
    }
  }

  Widget _buildPortalCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isDark = ref.read(isDarkProvider);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TriaColors.cardBg(isDark).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TriaColors.border(isDark)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: TriaColors.textPrimary(isDark),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: TriaColors.textSecondary(isDark),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: TriaColors.textMuted(isDark), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientPortalCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverPlaces() {
    final isDark = ref.watch(isDarkProvider);
    final List<String> categories = [
      "👤 Solo Traveler",
      "👩‍❤️‍👨 Couple / Romantic",
      "☀️  Summer Beach",
      "👨‍👩‍👦 Family Fun"
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DISCOVER PLACES',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: TriaColors.textMuted(isDark),
                letterSpacing: 1.0,
              ),
            ),
            Text(
              'SWIPE CATEGORIES',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: TriaColors.textSecondary(isDark),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Choice Chips category list (Dark/Light Styling)
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            itemBuilder: (context, idx) {
              final cat = categories[idx];
              final isSelected = selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = cat;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2563EB) : TriaColors.cardBg(isDark),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2563EB) : TriaColors.border(isDark),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.white : TriaColors.textSecondary(isDark),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        // Horizontal Destination Cards Carousel (Premium styling)
        SizedBox(
          height: 255,
          child: ref.watch(discoverPlacesProvider(selectedCategory)).when(
            data: (places) {
              return places.isEmpty
                  ? Center(child: Text("No destinations found", style: TextStyle(color: TriaColors.textSecondary(isDark))))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: places.length,
                      itemBuilder: (context, idx) {
                        final item = places[idx];
                        final name = item['name'] as String;
                        final isLiked = likedDestinations.contains(name);
                        final countryCode = item['countryCode'] ?? 'GLO';
                        final tags = item['tags'] as List<dynamic>? ?? [];

                        return Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 14, bottom: 8, top: 2),
                          decoration: BoxDecoration(
                            color: TriaColors.cardBg(isDark).withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: TriaColors.border(isDark)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Thumbnail Image Stack with Shader Gradient overlay
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                                    child: Image.network(
                                      item['image'] ?? 'https://images.unsplash.com/photo-1540959733332-eab4deceeaf7?w=400',
                                      height: 110,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        height: 110,
                                        color: TriaColors.scaffoldBg(isDark),
                                        child: Icon(Icons.image, color: TriaColors.textMuted(isDark).withValues(alpha: 0.3)),
                                      ),
                                    ),
                                  ),
                                  // Gradient Overlay to ensure text readability
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withValues(alpha: 0.35),
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: 0.45),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Rating Badge (Glowing)
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: TriaColors.cardBg(isDark).withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: TriaColors.border(isDark)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 10),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${item['rating'] ?? 4.8}',
                                            style: TextStyle(
                                              color: TriaColors.textPrimary(isDark),
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Favorite Heart Toggle Button
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (isLiked) {
                                            likedDestinations.remove(name);
                                          } else {
                                            likedDestinations.add(name);
                                          }
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: TriaColors.cardBg(isDark).withValues(alpha: 0.8),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: TriaColors.border(isDark)),
                                        ),
                                        child: Icon(
                                          isLiked ? Icons.favorite : Icons.favorite_border,
                                          color: isLiked ? const Color(0xFFEF4444) : TriaColors.textMuted(isDark),
                                          size: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Content Info
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: TriaColors.textPrimary(isDark),
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            '$countryCode • ${item['country'] ?? ""}',
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              color: Color(0xFF00B4D8), // Indigo 400
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          // Description Preview
                                          Text(
                                            item['desc'] ?? '',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: TriaColors.textSecondary(isDark),
                                              fontSize: 9.5,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Destination Tags & Explore Button Row
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Tags
                                          if (tags.isNotEmpty)
                                            Row(
                                              children: tags.take(1).map((tag) => Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: TriaColors.scaffoldBg(isDark),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: TriaColors.border(isDark)),
                                                ),
                                                child: Text(
                                                  '#$tag',
                                                  style: const TextStyle(
                                                    color: Color(0xFFC7D2FE), // Indigo 200
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              )).toList(),
                                            ),
                                          
                                          // Explore Button
                                          GestureDetector(
                                            onTap: () => _showPlaceDetailModal(item),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFF2563EB), Color(0xFF00B4D8)],
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'Explore',
                                                    style: TextStyle(
                                                      fontSize: 8.5,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(width: 2),
                                                  Icon(
                                                    Icons.chevron_right,
                                                    color: Colors.white,
                                                    size: 10,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
            },
            loading: () {
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, idx) {
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 14, bottom: 8, top: 2),
                    decoration: BoxDecoration(
                      color: TriaColors.cardBg(isDark).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: TriaColors.border(isDark).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 110,
                          decoration: const BoxDecoration(
                            color: Color(0x11FFFFFF),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Color(0xFF00B4D8), strokeWidth: 2),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 120,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: const Color(0x11FFFFFF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 80,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0x11FFFFFF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: 150,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0x11FFFFFF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 130,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0x11FFFFFF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            error: (err, stack) {
              return Center(
                child: Text(
                  "Failed to load: $err",
                  style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showPlaceDetailModal(Map<String, dynamic> item) {
    final isDark = ref.read(isDarkProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: TriaColors.dialogBg(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final countryCode = item['countryCode'] ?? 'GLO';
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  (item['image'] != null && item['image'].toString().isNotEmpty)
                      ? item['image']
                      : 'https://images.unsplash.com/photo-1540959733332-eab4deceeaf7?w=400',
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    color: TriaColors.cardBg(isDark),
                    child: Icon(Icons.image, color: TriaColors.textMuted(isDark).withValues(alpha: 0.3), size: 40),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['name'],
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TriaColors.textPrimary(isDark)),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${item['rating']}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TriaColors.textPrimary(isDark)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '$countryCode • ${item['country']}',
                style: TextStyle(color: TriaColors.textSecondary(isDark), fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                item['desc'],
                style: TextStyle(fontSize: 13, height: 1.4, color: TriaColors.textPrimary(isDark)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close Details',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _showTravelBuddiesModal() {
    final isDark = ref.read(isDarkProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: TriaColors.dialogBg(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final upcomingTrip = ref.read(userProfileProvider).profile['upcomingTrip'];
            final String tripCity = upcomingTrip != null ? upcomingTrip['city'] ?? 'Tokyo' : 'Tokyo';
            final String startStr = upcomingTrip != null ? upcomingTrip['startDate'] ?? '2026-06-15' : '2026-06-15';
            final String endStr = upcomingTrip != null ? upcomingTrip['endDate'] ?? '2026-06-20' : '2026-06-20';

            String formatCustomDateRange(String? start, String? end) {
              if (start == null || end == null) return 'Jun 15 - Jun 20';
              try {
                final sDate = DateTime.parse(start);
                final eDate = DateTime.parse(end);
                final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                return '${months[sDate.month - 1]} ${sDate.day} - ${months[eDate.month - 1]} ${eDate.day}';
              } catch (e) {
                return '$start - $end';
              }
            }
            final dateRangeStr = formatCustomDateRange(startStr, endStr);

            final List<Map<String, dynamic>> buddies = [
              {
                'name': 'Kenji Tanaka',
                'compatibility': '98%',
                'overlap': 'Same dates: $dateRangeStr',
                'vibe': 'Gourmet Netrunner',
                'tags': ['Street Food', 'Sightseeing', 'Transit'],
                'image': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                'itinerary': [
                  {'time': '04:00 PM', 'activity': 'Sky View Deck view', 'location': 'Sky View Deck'},
                  {'time': '07:00 PM', 'activity': 'Geek Town themed café tour', 'location': 'Geek Town'},
                ],
              },
              {
                'name': 'Elena Rostova',
                'compatibility': '94%',
                'overlap': 'Same dates: $dateRangeStr',
                'vibe': 'Cultural Shogun',
                'tags': ['Photography', 'Temples', 'Local Food'],
                'image': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
                'itinerary': [
                  {'time': '09:00 AM', 'activity': 'Senso-ji temple stroll', 'location': 'Asakusa'},
                  {'time': '06:00 PM', 'activity': 'West Central Tokyo golden gai bar hop', 'location': 'West Central Tokyo'},
                ],
              },
              {
                'name': 'David Chen',
                'compatibility': '89%',
                'overlap': 'Same dates: $dateRangeStr',
                'vibe': 'Digital Nomad Explorer',
                'tags': ['Retro Games', 'Tech', 'Sushi'],
                'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
                'itinerary': [
                  {'time': '10:00 AM', 'activity': 'Seafood Street Market Sushi Tour', 'location': 'Seafood Market'},
                  {'time': '02:00 PM', 'activity': 'Retro game shopping', 'location': 'Geek Town Retro Game Shop'},
                ],
              },
            ];

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: TriaColors.border(isDark),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Travel Buddies Matches',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: TriaColors.textPrimary(isDark),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Matching destination & dates: $tripCity • $dateRangeStr',
                    style: TextStyle(
                      color: TriaColors.textSecondary(isDark),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Buddies list
                  Column(
                    children: buddies.map((buddy) {
                      final isConnected = _connectedBuddies.contains(buddy['name']);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: TriaColors.cardBg(isDark),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: TriaColors.border(isDark)),
                        ),
                        child: Row(
                          children: [
                            // Avatar with compatibility score overlay
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundImage: NetworkImage(buddy['image']),
                                ),
                                Positioned(
                                  bottom: -4,
                                  right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF065F46), // Green 800
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: TriaColors.cardBg(isDark), width: 1.5),
                                    ),
                                    child: Text(
                                      buddy['compatibility'],
                                      style: const TextStyle(
                                        color: Color(0xFF34D399),
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    buddy['name'],
                                    style: TextStyle(
                                      color: TriaColors.textPrimary(isDark),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    buddy['vibe'],
                                    style: const TextStyle(
                                      color: Color(0xFF00B4D8), // Indigo 400
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    buddy['overlap'],
                                    style: TextStyle(
                                      color: TriaColors.textSecondary(isDark),
                                      fontSize: 9.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Tags
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: (buddy['tags'] as List<String>).map((tag) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: TriaColors.scaffoldBg(isDark),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          tag,
                                          style: TextStyle(
                                            color: TriaColors.textSecondary(isDark),
                                            fontSize: 8,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Actions Column
                            Column(
                              children: [
                                // Connect button
                                SizedBox(
                                  width: 80,
                                  height: 28,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isConnected ? TriaColors.scaffoldBg(isDark) : const Color(0xFF2563EB),
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      side: isConnected ? BorderSide(color: TriaColors.border(isDark)) : null,
                                    ),
                                    onPressed: () {
                                      SoundSynthesizer.playTone(
                                        frequency: 880,
                                        durationSeconds: 0.15,
                                        name: 'connect_success.wav',
                                      );
                                      setState(() {
                                        if (isConnected) {
                                          _connectedBuddies.remove(buddy['name']);
                                        } else {
                                          _connectedBuddies.add(buddy['name']);
                                        }
                                      });
                                      setModalState(() {});
                                    },
                                    child: Text(
                                      isConnected ? 'Pending' : 'Connect',
                                      style: TextStyle(
                                        color: isConnected ? TriaColors.textSecondary(isDark) : Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Compare Itinerary link
                                GestureDetector(
                                  onTap: () {
                                    _showBuddyItineraryModal(buddy);
                                  },
                                  child: const Text(
                                    'Itinerary ➔',
                                    style: TextStyle(
                                      color: Color(0xFF00B4D8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBuddyItineraryModal(Map<String, dynamic> buddy) {
    final isDark = ref.read(isDarkProvider);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: TriaColors.dialogBg(isDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            '${buddy['name']}\'s Overlapping Itinerary',
            style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activities that match your dates:',
                  style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 12),
                ),
                const SizedBox(height: 12),
                Column(
                  children: (buddy['itinerary'] as List<Map<String, dynamic>>).map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: TriaColors.scaffoldBg(isDark),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.amberAccent[200], size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['activity']!,
                                  style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '📍 ${item['location']!}',
                                  style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFF00B4D8), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAiPicksList(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'AI PICKS FOR YOU',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: TriaColors.textSecondary(isDark),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF065F46), // Emerald 800
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PERSONALIZED',
                style: TextStyle(
                  color: Color(0xFF34D399), // Emerald 400
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ref.watch(personalizedRecommendationsProvider).when(
          data: (places) {
            final List<Map<String, dynamic>> items = places.isNotEmpty ? places : [
              {
                'name': 'Geek Town Pop Culture Tour',
                'match': '99%',
                'isBest': true,
                'cost': '\$40',
                'image': 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=200',
                'vibe': 'Tech & Anime Heritage',
                'tag': 'Shopping',
                'prompt': 'Tell me more about the Geek Town Pop Culture Tour and help me book it.'
              },
              {
                'name': 'Scramble Crossing Neon Night Stroll',
                'match': '96%',
                'isBest': true,
                'cost': '\$30',
                'image': 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=200',
                'vibe': 'Cityscape Photography',
                'tag': 'Nightlife',
                'prompt': 'Tell me more about the Scramble Crossing Neon Night Stroll and when is the best time to visit.'
              },
            ];

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, idx) {
                final rec = items[idx];
                final name = rec['name'] as String? ?? 'Scenic Spot';
                final matchStr = rec['match'] ?? (rec['rating'] != null ? '${(rec['rating'] * 20).toInt()}%' : '92%');
                final isBest = rec['isBest'] ?? (idx == 0);
                final costStr = rec['cost'] ?? (rec['avgCost'] ?? 'Free');
                final image = rec['image'] as String? ?? 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=200';
                final vibeStr = rec['vibe'] ?? (rec['desc'] ?? (rec['description'] ?? 'Tailored experience'));
                final tagStr = rec['tag'] ?? (((rec['tags'] as List<dynamic>?)?.firstOrNull) ?? 'Culture');
                final promptStr = rec['prompt'] ?? 'Tell me more about $name and help me book it.';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TriaColors.cardBg(isDark).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: TriaColors.border(isDark)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              image,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 72,
                                height: 72,
                                color: TriaColors.scaffoldBg(isDark),
                                child: Icon(Icons.explore, color: TriaColors.textMuted(isDark)),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                              ),
                              child: Text(
                                matchStr.toString().contains('MATCH') ? matchStr.toString() : '$matchStr MATCH',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          if (isBest == true)
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'BEST',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 6.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                                color: TriaColors.textPrimary(isDark),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              vibeStr,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF00B4D8),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: TriaColors.scaffoldBg(isDark),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    tagStr,
                                    style: TextStyle(
                                      color: TriaColors.textSecondary(isDark),
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Cost: $costStr',
                                  style: TextStyle(
                                    color: TriaColors.textSecondary(isDark),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          SoundSynthesizer.playTone(
                            frequency: 880,
                            durationSeconds: 0.1,
                            name: 'concierge_chat.wav',
                          );
                          ref.read(chatMessagesProvider.notifier).sendChatMessage(
                            promptStr,
                            'user',
                          );
                          ref.read(currentTabProvider.notifier).state = 1;
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFF312E81),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF4338CA)),
                          ),
                          child: const Center(
                            child: Icon(Icons.arrow_forward, size: 15, color: Color(0xFFC7D2FE)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            ),
          ),
          error: (err, stack) => Center(
            child: Text('Error loading personalized recommendations', style: TextStyle(color: TriaColors.textSecondary(isDark))),
          ),
        ),
      ],
    );
  }

  // ======== TRAVEL SQUADS MODAL & SHEETS ========
  void _showTravelSquadsModal(BuildContext context, WidgetRef ref) {
    final profile = ref.read(userProfileProvider).profile;
    final userIdVal = profile['id'] ?? profile['email'] ?? '';
    final userId = userIdVal.toString().trim().isEmpty ? 'shreyas' : userIdVal;
    final joinCodeController = TextEditingController();
    final isDark = ref.read(isDarkProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TriaColors.dialogBg(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        List<Map<String, dynamic>> squads = [];
        bool loading = true;

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isDark = ref.watch(isDarkProvider);
            if (loading) {
              AiService.getUserSquads(userId).then((list) {
                if (modalCtx.mounted) {
                  setModalState(() {
                    squads = list;
                    loading = false;
                  });
                }
              }).catchError((_) {
                if (modalCtx.mounted) {
                  setModalState(() {
                    loading = false;
                  });
                }
              });
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: TriaColors.border(isDark),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF7B2FF7)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.groups, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'TRAVEL SQUADS',
                        style: TextStyle(
                          color: TriaColors.textPrimary(isDark),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      // Create squad button
                      GestureDetector(
                        onTap: () {
                          _showCreateSquadSheet(context, ref, () {
                            setModalState(() {
                              loading = true; // Trigger reload
                            });
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF7B2FF7)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Create',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Join squad button
                      GestureDetector(
                        onTap: () {
                          _showJoinSquadSheet(context, ref, joinCodeController, () {
                            setModalState(() {
                              loading = true; // Trigger reload
                            });
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: TriaColors.cardBg(isDark),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: TriaColors.border(isDark)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.login, color: TriaColors.textSecondary(isDark), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Join',
                                style: TextStyle(
                                  color: TriaColors.textSecondary(isDark),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    )
                  else if (squads.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: TriaColors.cardBg(isDark).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: TriaColors.border(isDark)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.group_add, color: Color(0xFF2563EB), size: 36),
                          const SizedBox(height: 10),
                          Text(
                            'No Travel Squads Found',
                            style: TextStyle(
                              color: TriaColors.textPrimary(isDark),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create a squad or join one with an invite code!',
                            style: TextStyle(
                              color: TriaColors.textSecondary(isDark),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: squads.length,
                        itemBuilder: (context, i) {
                          final s = squads[i];
                          final members = (s['members'] as List?) ?? [];
                          final daysAway = _calcDaysAway(s['startDate'] ?? '');
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  TriaColors.cardBg(isDark).withValues(alpha: 0.95),
                                  TriaColors.scaffoldBg(isDark).withValues(alpha: 0.85),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: TriaColors.border(isDark),
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Text(
                                  s['name'] ?? '',
                                  style: TextStyle(
                                    color: TriaColors.textPrimary(isDark),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Color(0xFFFFD166), size: 13),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          s['destination'] ?? '',
                                          style: const TextStyle(
                                            color: Color(0xFFFFD166),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00B4D8).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${members.length}👥',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF00B4D8),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (daysAway > 0) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '${daysAway}d away',
                                        style: TextStyle(
                                          color: TriaColors.textMuted(isDark),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                onTap: () async {
                                  Navigator.pop(ctx);
                                  await context.push('/squad/${s['id']}');
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  int _calcDaysAway(String dateStr) {
    if (dateStr.isEmpty) return 0;
    try {
      return DateTime.parse(dateStr).difference(DateTime.now()).inDays;
    } catch (_) {
      return 0;
    }
  }

  void _showCreateSquadSheet(BuildContext context, WidgetRef ref, VoidCallback onSquadCreated) {
    final nameCtrl = TextEditingController();
    final destCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    final isDark = ref.read(isDarkProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TriaColors.dialogBg(isDark),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: TriaColors.border(isDark), borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 16),
                Text('CREATE TRAVEL SQUAD', style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text('Rally your crew for an epic trip!', style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 12)),
                const SizedBox(height: 16),
                _squadField('Squad Name', nameCtrl, 'e.g. Tokyo Crew 2026', isDark),
                _squadField('Destination', destCtrl, 'e.g. Tokyo, Japan', isDark),
                _squadField('Description', descCtrl, 'Optional: purpose of the trip', isDark),
                _squadDateField(ctx, 'Start Date', startCtrl, isDark),
                _squadDateField(ctx, 'End Date', endCtrl, isDark),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty || destCtrl.text.trim().isEmpty) return;
                      final profile = ref.read(userProfileProvider).profile;
                      final creatorIdVal = profile['id'] ?? profile['email'] ?? '';
                      final creatorId = creatorIdVal.toString().trim().isEmpty ? 'shreyas' : creatorIdVal;
                      final creatorNameVal = profile['fullName'] ?? '';
                      final creatorName = creatorNameVal.toString().trim().isEmpty ? 'Shreyas Aswini' : creatorNameVal;
                      try {
                        await AiService.createSquad({
                          'name': nameCtrl.text.trim(),
                          'destination': destCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'startDate': startCtrl.text.trim(),
                          'endDate': endCtrl.text.trim(),
                          'creatorId': creatorId,
                          'creatorName': creatorName,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        onSquadCreated();
                      } catch (e) {
                        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                      }
                    },
                    icon: const Icon(Icons.rocket_launch, size: 18),
                    label: const Text('Launch Squad', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showJoinSquadSheet(BuildContext context, WidgetRef ref, TextEditingController joinCodeController, VoidCallback onSquadJoined) {
    final isDark = ref.read(isDarkProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: TriaColors.dialogBg(isDark),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: TriaColors.border(isDark), borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 16),
              Text('JOIN A SQUAD', style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text('Enter the 6-character invite code', style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 12)),
              const SizedBox(height: 16),
              TextField(
                controller: joinCodeController,
                style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 6),
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: 'XXXXXX',
                  hintStyle: TextStyle(color: TriaColors.textMuted(isDark).withValues(alpha: 0.35), fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 6),
                  filled: true,
                  fillColor: TriaColors.scaffoldBg(isDark),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final code = joinCodeController.text.trim();
                    if (code.length != 6) return;
                    final profile = ref.read(userProfileProvider).profile;
                    final userIdVal = profile['id'] ?? profile['email'] ?? '';
                    final userId = userIdVal.toString().trim().isEmpty ? 'shreyas' : userIdVal;
                    final userNameVal = profile['fullName'] ?? '';
                    final userName = userNameVal.toString().trim().isEmpty ? 'Shreyas Aswini' : userNameVal;
                    try {
                      await AiService.joinSquadByCode(
                        code,
                        userId,
                        userName,
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      onSquadJoined();
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Joined the squad! 🎉'), backgroundColor: Color(0xFF06D6A0)),
                      );
                    } catch (e) {
                      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red));
                    }
                  },
                  icon: const Icon(Icons.group_add, size: 18),
                  label: const Text('Join Squad', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B4D8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _squadField(String label, TextEditingController ctrl, String hint, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 12),
          hintText: hint,
          hintStyle: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 13),
          filled: true,
          fillColor: TriaColors.cardBg(isDark),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _squadDateField(BuildContext context, String label, TextEditingController ctrl, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        readOnly: true,
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2035),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: const Color(0xFF2563EB), // Royal Blue
                    onPrimary: Colors.white,
                    surface: TriaColors.cardBg(isDark),
                    onSurface: TriaColors.textPrimary(isDark),
                  ),
                  dialogTheme: DialogThemeData(
                    backgroundColor: TriaColors.dialogBg(isDark),
                  ),
                  datePickerTheme: DatePickerThemeData(
                    backgroundColor: TriaColors.dialogBg(isDark),
                    headerBackgroundColor: TriaColors.scaffoldBg(isDark),
                    headerForegroundColor: TriaColors.textPrimary(isDark),
                    rangePickerHeaderBackgroundColor: TriaColors.scaffoldBg(isDark),
                    rangePickerHeaderForegroundColor: TriaColors.textPrimary(isDark),
                    confirmButtonStyle: ButtonStyle(
                      foregroundColor: WidgetStateProperty.all(const Color(0xFF60A5FA)),
                      textStyle: WidgetStateProperty.all(const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    cancelButtonStyle: ButtonStyle(
                      foregroundColor: WidgetStateProperty.all(TriaColors.textSecondary(isDark)),
                      textStyle: WidgetStateProperty.all(const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            final y = picked.year;
            final m = picked.month.toString().padLeft(2, '0');
            final d = picked.day.toString().padLeft(2, '0');
            ctrl.text = '$y-$m-$d';
          }
        },
        style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 12),
          hintText: 'Tap to select date',
          hintStyle: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 13),
          suffixIcon: const Icon(Icons.calendar_month, color: Color(0xFF2563EB), size: 18),
          filled: true,
          fillColor: TriaColors.cardBg(isDark),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
