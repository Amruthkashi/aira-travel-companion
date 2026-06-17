import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/travel_providers.dart';
import '../core/utils/sound_synthesizer.dart';
import '../core/services/ai_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String selectedCategory = '👤 Solo Traveler';
  final Set<String> likedDestinations = {"Santorini", "Amalfi Coast"};
  final Set<String> _connectedBuddies = {};

  final Map<String, List<Map<String, dynamic>>> _destinationsDb = {
    "👤 Solo Traveler": [
      {
        "name": "Tokyo Crossing District",
        "country": "Japan",
        "countryCode": "JPN",
        "rating": 4.9,
        "image": "https://images.unsplash.com/photo-1540959733332-eab4deceeaf7?w=400",
        "desc": "Bustling neon streets, capsule hotels, retro arcades, and solo-friendly sushi counters.",
        "tags": ["Neon", "Tech", "Solo-Friendly"]
      },
      {
        "name": "Reykjavik",
        "country": "Iceland",
        "countryCode": "ISL",
        "rating": 4.8,
        "image": "https://images.unsplash.com/photo-1504829857797-ddff28127792?w=400",
        "desc": "The safest country for solo explorers, featuring hot springs, waterfalls, and northern lights.",
        "tags": ["Nature", "Safety", "Adventure"]
      },
      {
        "name": "Berlin Kreuzberg",
        "country": "Germany",
        "countryCode": "DEU",
        "rating": 4.7,
        "image": "https://images.unsplash.com/photo-1560969184-10fe8719e047?w=400",
        "desc": "A vibrant hub of art, cafes, historic hostels, and open-minded nightlife perfect for solo travelers.",
        "tags": ["Art", "Nightlife", "Hostels"]
      },
      {
        "name": "Chiang Mai",
        "country": "Thailand",
        "countryCode": "THA",
        "rating": 4.8,
        "image": "https://images.unsplash.com/photo-1508009603885-50cf7c579365?w=400",
        "desc": "A peaceful digital nomad haven surrounded by mist-covered mountains and ancient temples.",
        "tags": ["Nomad", "Temples", "Budget"]
      },
      {
        "name": "Queenstown",
        "country": "New Zealand",
        "countryCode": "NZL",
        "rating": 4.9,
        "image": "https://images.unsplash.com/photo-1589871190903-5182103f677d?w=400",
        "desc": "The adventure capital of the world. Great social scenes, bungee jumps, and lake cruises.",
        "tags": ["Extreme", "Social", "Scenic"]
      }
    ],
    "👩‍❤️‍👨 Couple / Romantic": [
      {
        "name": "Oia Santorini",
        "country": "Greece",
        "countryCode": "GRC",
        "rating": 4.9,
        "image": "https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=400",
        "desc": "Iconic whitewashed houses with blue domes perched high on volcanic cliffs overlooking the sunset.",
        "tags": ["Romantic", "Sunset", "Luxury"]
      },
      {
        "name": "Positano Coast",
        "country": "Italy",
        "countryCode": "ITA",
        "rating": 4.9,
        "image": "https://images.unsplash.com/photo-1533105079780-92b9be482077?w=400",
        "desc": "Cliffside pastel villages cascade down to turquoise waters. Famous for romance and limoncello.",
        "tags": ["Scenic", "Cozy", "Dining"]
      },
      {
        "name": "Paris Seine",
        "country": "France",
        "countryCode": "FRA",
        "rating": 4.9,
        "image": "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=400",
        "desc": "Crowning destination of love. Candlelit dinners, Seine river cruises, and cozy street cafes.",
        "tags": ["Art", "Dining", "Romantic"]
      },
      {
        "name": "Kyoto Arashiyama",
        "country": "Japan",
        "countryCode": "JPN",
        "rating": 4.8,
        "image": "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400",
        "desc": "Ethereal bamboo paths, peaceful wooden shrines, traditional tea ceremonies, and hot spring ryokans.",
        "tags": ["Zen", "Culture", "Scenic"]
      },
      {
        "name": "Bora Bora Lagoon",
        "country": "French Polynesia",
        "countryCode": "PYF",
        "rating": 4.9,
        "image": "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400",
        "desc": "Overwater bungalows, crystal clear lagoons, and private dinners on white coral beaches.",
        "tags": ["Private", "Tropical", "Lagoon"]
      }
    ],
    "☀️ Summer Beach": [
      {
        "name": "Uluwatu Temple",
        "country": "Indonesia",
        "countryCode": "IDN",
        "rating": 4.8,
        "image": "https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=400",
        "desc": "Spectacular sea-cliff temple views, legendary surf breaks, and fiery sunset fire dances.",
        "tags": ["Tropical", "Surf", "Culture"]
      },
      {
        "name": "Maui Wailea",
        "country": "Hawaii",
        "countryCode": "USA",
        "rating": 4.9,
        "image": "https://images.unsplash.com/photo-1505872289599-1348b76e6a4d?w=400",
        "desc": "Stunning resort beaches, volcanic snorkeling trails, and coastal road trip loops.",
        "tags": ["Volcano", "Snorkel", "Resorts"]
      },
      {
        "name": "Ibiza Old Town",
        "country": "Spain",
        "countryCode": "ESP",
        "rating": 4.7,
        "image": "https://images.unsplash.com/photo-1518005020951-eccb494ad742?w=400",
        "desc": "Pristine sandy coves, legendary sunset cafes, and historical castle walk paths.",
        "tags": ["Beaches", "Sunset", "Music"]
      },
      {
        "name": "Maldives Atolls",
        "country": "Maldives",
        "countryCode": "MDV",
        "rating": 4.9,
        "image": "https://images.unsplash.com/photo-1439066615861-d1af74d74000?w=400",
        "desc": "Lush turquoise waters, private islands, diving with manta rays, and white sandbar walks.",
        "tags": ["Luxury", "Snorkel", "Pristine"]
      },
      {
        "name": "Phuket Kata",
        "country": "Thailand",
        "countryCode": "THA",
        "rating": 4.8,
        "image": "https://images.unsplash.com/photo-1589308078059-be1415eab4c3?w=400",
        "desc": "Beautiful beaches, buzzing street markets, water sports, and beach clubs.",
        "tags": ["Active", "Food", "Beaches"]
      }
    ],
    "👨‍👩‍👦 Family Fun": [
      {
        "name": "Disneyland Tokyo",
        "country": "Japan",
        "countryCode": "JPN",
        "rating": 4.8,
        "image": "https://images.unsplash.com/photo-1505761671935-60b6a7453620?w=400",
        "desc": "A magical, high-service theme park featuring classic fairy tales and warm customer care.",
        "tags": ["Theme Park", "Kids", "Magic"]
      },
      {
        "name": "Surfers Paradise",
        "country": "Australia",
        "countryCode": "AUS",
        "rating": 4.7,
        "image": "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400",
        "desc": "Golden sandy beaches, family theme parks, and active surf breaks perfect for kids.",
        "tags": ["Surf", "Adventure", "Parks"]
      },
      {
        "name": "Orlando Universal",
        "country": "USA",
        "countryCode": "USA",
        "rating": 4.9,
        "image": "https://images.unsplash.com/photo-1560089000-7433a4ebbd64?w=400",
        "desc": "The ultimate theme park capital with world-famous rides, movie sets, and family water parks.",
        "tags": ["Rides", "Coasters", "Movies"]
      },
      {
        "name": "Singapore Sentosa",
        "country": "Singapore",
        "countryCode": "SGP",
        "rating": 4.8,
        "image": "https://images.unsplash.com/photo-1525625293386-3fb8a40332f3?w=400",
        "desc": "Incredibly clean, featuring Gardens by the Bay, Universal Studios, and cable cars.",
        "tags": ["Clean", "Gardens", "Safety"]
      },
      {
        "name": "Vancouver Stanley",
        "country": "Canada",
        "countryCode": "CAN",
        "rating": 4.8,
        "image": "https://images.unsplash.com/photo-1559511260-66a654ae982a?w=400",
        "desc": "Huge rainforest city park, public aquariums, and easy, scenic family bike trails.",
        "tags": ["Forest", "Bikes", "Scenic"]
      }
    ]
  };

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileState = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628), // Slate 900
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
                return const LinearGradient(
                  colors: [Colors.black, Colors.black, Colors.transparent],
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
                    const Color(0xFF0A1628).withValues(alpha: 0.1),
                    const Color(0xFF0A1628).withValues(alpha: 0.7),
                    const Color(0xFF0A1628),
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
                  color: const Color(0xFF7B2FF7).withValues(alpha: 0.14), // Violet glow
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
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.08), // Teal glow
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

                    // Trip Countdown Boarding Pass Card
                    _buildTripCountdownCard(context, ref),
                    const SizedBox(height: 24),

                    // Quick Actions Bento Grid
                    _buildQuickActionsGrid(context, ref),
                    const SizedBox(height: 26),

                    // My Global Travel Desks (CORE PORTAL)
                    _buildGlobalTravelDesks(context, ref),
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
    final name = userProfileState.profile['fullName'] ?? 'Traveler';
    final firstName = name.split(' ').first;
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x991E293B), // Glassmorphic Slate 800 (60% opacity)
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.4)),
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
          Container(
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
          const SizedBox(width: 10),
          // Greeting text
          Expanded(
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2744), // Slate 800
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF334155)), // Slate 700
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
            Icon(icon, color: iconColor, size: 18),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744), // Slate 800
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
            style: const TextStyle(
              color: Color(0xFFF8FAFC), // White
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

    if (upcomingTrip == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xCC1E293B), // Slate 800 80% opacity
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
            const Text(
              'No Active Journey',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask Aira to plan your next itinerary or search locations to get started.',
              style: TextStyle(
                color: Color(0xFF94A3B8),
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
                'Ask Aira to Plan',
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
        color: const Color(0xCC1E293B), // Slate 800 80% opacity
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
                      style: const TextStyle(
                        color: Colors.white,
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
              style: const TextStyle(
                color: Colors.white,
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
                decoration: const BoxDecoration(
                  color: Color(0xFF0A1628),
                  borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
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
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15)),
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
                decoration: const BoxDecoration(
                  color: Color(0xFF0A1628),
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
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
                color: const Color(0xFF0A1628), // Slate 900
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1A2744)),
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
                            style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        tripDetails['pnr'] ?? 'NH-782Y9W',
                        style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 10.5, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Flight ${tripDetails['flight'] ?? 'SQ-638'} (${tripDetails['airline'] ?? 'SIA'})',
                        style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10.5),
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
                const Text(
                  'Trip Checklist Progress',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
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
                backgroundColor: const Color(0xFF0A1628), // Slate 900
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
                    color: Colors.white.withValues(alpha: index % 6 == 0 ? 0.04 : 0.2),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK ACTIONS',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            color: Color(0xFF94A3B8), // Slate 400
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
                  color: const Color(0xCC1E293B), // Slate 800 with 80% opacity
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)), // Slate 700
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
                        style: const TextStyle(
                          color: Colors.white,
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

  Widget _buildGlobalTravelDesks(BuildContext context, WidgetRef ref) {
    final userProfileState = ref.watch(userProfileProvider);
    final upcomingTrip = userProfileState.profile['upcomingTrip'];
    final String tripSubtitle;

    if (upcomingTrip == null) {
      tripSubtitle = 'No active journey. Plan one with Aira!';
    } else {
      final city = upcomingTrip['city'] ?? 'Tokyo';
      final startDate = upcomingTrip['startDate'];
      int days = 13;
      try {
        if (startDate != null) {
          final sDate = DateTime.parse(startDate);
          final now = DateTime.now();
          final diff = sDate.difference(DateTime(now.year, now.month, now.day)).inDays;
          days = diff < 0 ? 0 : diff;
        }
      } catch (e) {
        // ignore
      }
      tripSubtitle = days == 0 ? '$city Adventure starts today!' : '$city starts in $days days';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'GLOBAL TRAVEL DESKS',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8), // Slate 400
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF312E81), // Indigo 900
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'CORE PORTAL',
                    style: TextStyle(
                      color: Color(0xFFC7D2FE), // Indigo 200
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            // Floating Safe Zone Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF065F46), // Emerald 800
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF047857).withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, color: Color(0xFF34D399), size: 11),
                  SizedBox(width: 4),
                  Text(
                    'SAFE ZONE',
                    style: TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Previously Travelled stays
        _buildPortalCard(
          title: 'Previously Travelled',
          subtitle: 'Completed stays & travel memories',
          icon: Icons.history,
          iconColor: const Color(0xFF94A3B8),
          onTap: () => context.push('/memories'),
        ),
        const SizedBox(height: 10),
        // Create new Itinerary (indigo highlight gradient)
        _buildGradientPortalCard(
          title: 'Create New Itinerary',
          subtitle: 'AI-assisted custom route planner',
          icon: Icons.auto_awesome,
          onTap: () {
            context.push('/create-itinerary');
          },
        ),
        const SizedBox(height: 10),
        // Upcoming Trips
        _buildPortalCard(
          title: 'Upcoming Trips',
          subtitle: tripSubtitle,
          icon: Icons.calendar_today_outlined,
          iconColor: const Color(0xFF00B4D8),
          onTap: () {
            ref.read(currentTabProvider.notifier).state = 2;
          },
        ),
      ],
    );
  }

  Widget _buildPortalCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xCC1E293B), // Slate 800 with 80% opacity
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155)), // Slate 700
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8), // Slate 400
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF64748B), size: 18),
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
    final List<String> categories = [
      "👤 Solo Traveler",
      "👩‍❤️‍👨 Couple / Romantic",
      "☀️ Summer Beach",
      "👨‍👩‍👦 Family Fun"
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DISCOVER PLACES',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFF94A3B8), // Slate 400
                letterSpacing: 1.0,
              ),
            ),
            Text(
              'SWIPE CATEGORIES',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Choice Chips category list (Dark Styling)
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
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1A2744), // Slate 800 unselected
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF334155), // Slate 700 unselected
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
                          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
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
                  ? const Center(child: Text("No destinations found", style: TextStyle(color: Colors.white70)))
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
                            color: const Color(0xCC1E293B), // Slate 800 (80% opacity)
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFF334155)), // Slate 700
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
                                        color: const Color(0xFF1A2744),
                                        child: const Icon(Icons.image, color: Colors.white24),
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
                                        color: const Color(0xFF0A1628).withValues(alpha: 0.8), // Semi-transparent Slate 900
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF334155)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 10),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${item['rating'] ?? 4.8}',
                                            style: const TextStyle(
                                              color: Colors.white,
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
                                          color: const Color(0xFF0A1628).withValues(alpha: 0.8), // Semi-transparent Slate 900
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFF334155)),
                                        ),
                                        child: Icon(
                                          isLiked ? Icons.favorite : Icons.favorite_border,
                                          color: isLiked ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
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
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Colors.white,
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
                                            style: const TextStyle(
                                              color: Color(0xFF94A3B8), // Slate 400
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
                                                  color: const Color(0xFF0A1628), // Slate 900
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: const Color(0xFF334155)),
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
                      color: const Color(0x22FFFFFF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.3)),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1628), // Slate 900
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
                    color: const Color(0xFF1A2744),
                    child: const Icon(Icons.image, color: Colors.white24, size: 40),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['name'],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${item['rating']}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '$countryCode • ${item['country']}',
                style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                item['desc'],
                style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFFE2E8F0)), // Slate 200
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
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1628), // Slate 900
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
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Travel Buddies Matches',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Matching destination & dates: $tripCity • $dateRangeStr',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
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
                          color: const Color(0xFF1A2744), // Slate 800
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF334155)), // Slate 700
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
                                      border: Border.all(color: const Color(0xFF1A2744), width: 1.5),
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
                                    style: const TextStyle(
                                      color: Colors.white,
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
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8), // Slate 400
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
                                          color: const Color(0xFF0A1628),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          tag,
                                          style: const TextStyle(
                                            color: Color(0xFFC7D2FE),
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
                                      backgroundColor: isConnected ? const Color(0xFF0A1628) : const Color(0xFF2563EB),
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      side: isConnected ? const BorderSide(color: Color(0xFF334155)) : null,
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
                                        color: isConnected ? const Color(0xFF94A3B8) : Colors.white,
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A2744), // Slate 800
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            '${buddy['name']}\'s Overlapping Itinerary',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Activities that match your dates:',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
                const SizedBox(height: 12),
                Column(
                  children: (buddy['itinerary'] as List<Map<String, String>>).map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1628), // Slate 900
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
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '📍 ${item['location']!}',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'AI PICKS FOR YOU',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFF94A3B8), // Slate 400
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
                    color: const Color(0xCC1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155)),
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
                                color: const Color(0xFF0A1628),
                                child: const Icon(Icons.explore, color: Colors.white60),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                                color: Colors.white,
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
                                    color: const Color(0xFF0A1628),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    tagStr,
                                    style: const TextStyle(
                                      color: Color(0xFFC7D2FE),
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Cost: $costStr',
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
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
          error: (err, stack) => const Center(
            child: Text('Error loading personalized recommendations', style: TextStyle(color: Colors.white70)),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF020617), // Slate 950
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        List<Map<String, dynamic>> squads = [];
        bool loading = true;

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
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
                        color: const Color(0xFF334155),
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
                      const Text(
                        'TRAVEL SQUADS',
                        style: TextStyle(
                          color: Colors.white,
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
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.login, color: Colors.white70, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Join',
                                style: TextStyle(
                                  color: Colors.white70,
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
                        color: const Color(0xFF1A2744).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.group_add, color: Color(0xFF2563EB), size: 36),
                          SizedBox(height: 10),
                          Text(
                            'No Travel Squads Found',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Create a squad or join one with an invite code!',
                            style: TextStyle(
                              color: Colors.white54,
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
                                  const Color(0xFF0A1628).withValues(alpha: 0.9),
                                  const Color(0xFF312E81).withValues(alpha: 0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
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
                                  style: const TextStyle(
                                    color: Colors.white,
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
                                        style: const TextStyle(
                                          color: Colors.white38,
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A1628),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 16),
                const Text('CREATE TRAVEL SQUAD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                const SizedBox(height: 4),
                const Text('Rally your crew for an epic trip!', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 16),
                _squadField('Squad Name', nameCtrl, 'e.g. Tokyo Crew 2026'),
                _squadField('Destination', destCtrl, 'e.g. Tokyo, Japan'),
                _squadField('Description', descCtrl, 'Optional: purpose of the trip'),
                _squadDateField(ctx, 'Start Date', startCtrl),
                _squadDateField(ctx, 'End Date', endCtrl),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1628),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 16),
              const Text('JOIN A SQUAD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
              const SizedBox(height: 4),
              const Text('Enter the 6-character invite code', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 16),
              TextField(
                controller: joinCodeController,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 6),
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: 'XXXXXX',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 6),
                  filled: true,
                  fillColor: const Color(0xFF1A2744),
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
                      if (ctx.mounted) Navigator.pop(ctx);
                      onSquadJoined();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Joined the squad! 🎉'), backgroundColor: Color(0xFF06D6A0)),
                        );
                      }
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

  Widget _squadField(String label, TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
          filled: true,
          fillColor: const Color(0xFF1A2744),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _squadDateField(BuildContext context, String label, TextEditingController ctrl) {
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
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF2563EB), // Royal Blue
                    onPrimary: Colors.white,
                    surface: Color(0xFF1A2744),
                    onSurface: Colors.white,
                  ),
                  dialogBackgroundColor: const Color(0xFF0A1628),
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
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
          hintText: 'Tap to select date',
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
          suffixIcon: const Icon(Icons.calendar_month, color: Color(0xFF2563EB), size: 18),
          filled: true,
          fillColor: const Color(0xFF1A2744),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
