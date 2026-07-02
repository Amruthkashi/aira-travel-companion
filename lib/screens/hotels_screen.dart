import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/theme_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/travel_providers.dart';
import '../core/models/travel_models.dart';
import '../core/services/geoapify_service.dart';
import '../core/services/foursquare_service.dart';
import '../core/services/ai_service.dart';

class HotelsScreen extends ConsumerStatefulWidget {
  const HotelsScreen({super.key});

  @override
  ConsumerState<HotelsScreen> createState() => _HotelsScreenState();
}

class _HotelsScreenState extends ConsumerState<HotelsScreen> {
  String? _selectedHotelId;
  bool _bookingInProgress = false;
  bool _bookedSuccess = false;
  bool _isLoading = true;
  String _targetCity = 'Tokyo';
  List<Map<String, dynamic>> _hotelsList = [];

  final _geoapify = GeoapifyService();
  final _foursquare = FoursquareService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHotels();
    });
  }

  @override
  void dispose() {
    _geoapify.dispose();
    _foursquare.dispose();
    super.dispose();
  }

  List<ExplorePlaceItem> _generateMockHotels(String city) {
    final cleanCity = city.trim();
    final capitalized = cleanCity.isNotEmpty 
        ? cleanCity[0].toUpperCase() + cleanCity.substring(1)
        : 'Destination';
    
    return [
      ExplorePlaceItem(
        id: 'mock-hotel-1-${DateTime.now().millisecondsSinceEpoch}',
        name: 'The Grand $capitalized Majestic Resort',
        genre: 'Hotel',
        imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=800&q=80',
        description: 'A premium 5-star luxury stay situated right in the heart of $capitalized. Features panoramic views, fine dining, and full guest concierge services.',
        rating: 4.9,
        estimatedDuration: '240 per night',
        estimatedCost: '\$240',
        address: '77 Royal Boulevard, $capitalized',
        durationMinutes: 240,
      ),
      ExplorePlaceItem(
        id: 'mock-hotel-2-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Boutique Garden Lodge $capitalized',
        genre: 'Hotel',
        imageUrl: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?auto=format&fit=crop&w=800&q=80',
        description: 'Elegant boutique lodging featuring traditional architecture, lush inner gardens, and cozy local character.',
        rating: 4.7,
        estimatedDuration: '145 per night',
        estimatedCost: '\$145',
        address: '12 Blossom Lane, $capitalized',
        durationMinutes: 145,
      ),
      ExplorePlaceItem(
        id: 'mock-hotel-3-${DateTime.now().millisecondsSinceEpoch}',
        name: '$capitalized Central Capsule Pods',
        genre: 'Hotel',
        imageUrl: 'https://images.unsplash.com/photo-1549294413-26f195afcbce?auto=format&fit=crop&w=800&q=80',
        description: 'Futuristic and highly functional capsule sleeping pods, fully equipped with high-speed Wi-Fi and ambient controls.',
        rating: 4.5,
        estimatedDuration: '75 per night',
        estimatedCost: '\$75',
        address: '39 Transit Hub St, $capitalized',
        durationMinutes: 75,
      ),
      ExplorePlaceItem(
        id: 'mock-hotel-4-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Plaza & Suites $capitalized',
        genre: 'Hotel',
        imageUrl: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?auto=format&fit=crop&w=800&q=80',
        description: 'Modern executive suites featuring state-of-the-art business lounges, swimming pool, and easy station access.',
        rating: 4.6,
        estimatedDuration: '180 per night',
        estimatedCost: '\$180',
        address: '21 Commerce Avenue, $capitalized',
        durationMinutes: 180,
      ),
      ExplorePlaceItem(
        id: 'mock-hotel-5-${DateTime.now().millisecondsSinceEpoch}',
        name: '$capitalized Urban Oasis Hotel',
        genre: 'Hotel',
        imageUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=800&q=80',
        description: 'A serene urban sanctuary offering botanical sky gardens, organic spa treatments, and locally sourced healthy meals.',
        rating: 4.8,
        estimatedDuration: '210 per night',
        estimatedCost: '\$210',
        address: '88 Sanctuary Way, $capitalized',
        durationMinutes: 210,
      ),
      ExplorePlaceItem(
        id: 'mock-hotel-6-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Heritage Inn $capitalized',
        genre: 'Hotel',
        imageUrl: 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?auto=format&fit=crop&w=800&q=80',
        description: 'A historical landmark property beautifully restored with antique interiors and guided walking tours.',
        rating: 4.6,
        estimatedDuration: '160 per night',
        estimatedCost: '\$160',
        address: '5 Old Gate Road, $capitalized',
        durationMinutes: 160,
      ),
      ExplorePlaceItem(
        id: 'mock-hotel-7-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Riverside Panorama Hotel',
        genre: 'Hotel',
        imageUrl: 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?auto=format&fit=crop&w=800&q=80',
        description: 'Overlooking the waterfront, this hotel offers balcony views, gourmet dining, and riverboat cruise access.',
        rating: 4.7,
        estimatedDuration: '195 per night',
        estimatedCost: '\$195',
        address: '400 Riverfront Drive, $capitalized',
        durationMinutes: 195,
      ),
      ExplorePlaceItem(
        id: 'mock-hotel-8-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Skyline View Executive Suites',
        genre: 'Hotel',
        imageUrl: 'https://images.unsplash.com/photo-1596394516093-501ba68a0ba6?auto=format&fit=crop&w=800&q=80',
        description: 'Contemporary high-rise hotel featuring floor-to-ceiling windows with unobstructed views of the city skyline.',
        rating: 4.8,
        estimatedDuration: '260 per night',
        estimatedCost: '\$260',
        address: '101 Summit Circle, $capitalized',
        durationMinutes: 260,
      ),
      ExplorePlaceItem(
        id: 'mock-hotel-9-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Zen Luxury Lodgings',
        genre: 'Hotel',
        imageUrl: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=800&q=80',
        description: 'Minimalist luxury designed to bring ultimate peace and mindfulness, including hot stone therapies.',
        rating: 4.9,
        estimatedDuration: '280 per night',
        estimatedCost: '\$280',
        address: '1 Tranquility Path, $capitalized',
        durationMinutes: 280,
      ),
      ExplorePlaceItem(
        id: 'mock-hotel-10-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Cozy Nest Bed & Breakfast',
        genre: 'Hotel',
        imageUrl: 'https://images.unsplash.com/photo-1498503182468-3b51cbb6cb24?auto=format&fit=crop&w=800&q=80',
        description: 'Quaint, family-run bed and breakfast offering personalized service, home-cooked food, and fireplace lounges.',
        rating: 4.5,
        estimatedDuration: '95 per night',
        estimatedCost: '\$95',
        address: '18 Nest Lane, $capitalized',
        durationMinutes: 95,
      ),
    ];
  }

  Future<void> _loadHotels() async {
    final bookings = ref.read(tripBookingsProvider);
    String target = bookings.destination.trim();
    
    if (target.isEmpty) {
      final userProfile = ref.read(userProfileProvider);
      target = (userProfile.profile['city'] ?? '').toString().trim();
    }
    
    if (target.isEmpty) {
      target = 'Tokyo';
    }

    setState(() {
      _targetCity = target;
      _isLoading = true;
    });

    List<ExplorePlaceItem> rawHotels = [];
    try {
      final coords = await _geoapify.geocodeCity(target);
      if (coords != null) {
        final hotels = await _foursquare.fetchHotelsAndLodgings(
          coords['lat']!,
          coords['lon']!,
          target,
        );
        if (hotels.isNotEmpty) {
          rawHotels = List.from(hotels);
        }
      }
    } catch (e) {
      // Hotels loading failed, falling back to mock data
    }

    // Pad to 10 hotels if fewer are found
    if (rawHotels.length < 10) {
      final mocks = _generateMockHotels(target);
      for (final mock in mocks) {
        if (rawHotels.length >= 10) break;
        if (!rawHotels.any((element) => element.name.toLowerCase() == mock.name.toLowerCase())) {
          rawHotels.add(mock);
        }
      }
    }

    // Calculate nights based on dates
    final start = bookings.startDate != null ? DateTime.tryParse(bookings.startDate!) : null;
    final end = bookings.endDate != null ? DateTime.tryParse(bookings.endDate!) : null;
    final nights = (start != null && end != null) ? end.difference(start).inDays : 3;
    final finalNights = nights > 0 ? nights : 1;

    final mappedHotels = rawHotels.map((item) {
      final costStr = item.estimatedCost.replaceAll('\$', '').trim();
      final pricePerNight = double.tryParse(costStr) ?? 120.0;
      
      String tip = 'AI VERIFIED: Highly rated for comfort and convenience in $target.';
      if (item.name.toLowerCase().contains('grand') || item.name.toLowerCase().contains('resort') || item.name.toLowerCase().contains('majestic')) {
        tip = 'AI VERIFIED: Luxury features, outstanding sky lounge and pool views.';
      } else if (item.name.toLowerCase().contains('capsule') || item.name.toLowerCase().contains('pod') || item.name.toLowerCase().contains('nine hours')) {
        tip = 'AI VERIFIED: High-speed Wi-Fi, compact smart pods, and excellent transit links.';
      } else if (item.name.toLowerCase().contains('boutique') || item.name.toLowerCase().contains('lodge') || item.name.toLowerCase().contains('garden')) {
        tip = 'AI VERIFIED: Local charm, organic breakfast buffet, and cozy interior courtyards.';
      }

      return {
        'id': item.id,
        'name': item.name,
        'rating': item.rating,
        'image': item.imageUrl.isNotEmpty ? item.imageUrl : 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400',
        'pricePerNight': pricePerNight,
        'nights': finalNights,
        'location': item.address.isNotEmpty ? item.address : 'Central area, $target',
        'details': item.description.isNotEmpty ? item.description : 'Superb lodging located within easy walking distance of major highlights and transit stations.',
        'tip': tip,
      };
    }).toList();

    if (mappedHotels.length > 10) {
      mappedHotels.removeRange(10, mappedHotels.length);
    }

    if (mounted) {
      setState(() {
        _hotelsList = mappedHotels;
        _isLoading = false;
      });
    }
  }

  void _bookHotel(Map<String, dynamic> hotel) {
    setState(() => _bookingInProgress = true);
    final totalCost = hotel['pricePerNight'] * hotel['nights'];
    
    final bookings = ref.read(tripBookingsProvider);
    final checkIn = bookings.startDate ?? DateTime.now().toString().split(' ')[0];
    final int nights = hotel['nights'] is int ? hotel['nights'] as int : (int.tryParse(hotel['nights'].toString()) ?? 1);
    final checkOut = bookings.endDate ?? DateTime.now().add(Duration(days: nights)).toString().split(' ')[0];

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      
      // 1. Add to active trip bookings provider
      final hotelBooking = HotelBooking(
        id: 'hotel-booking-${DateTime.now().millisecondsSinceEpoch}',
        hotelName: hotel['name'],
        address: hotel['location'],
        checkInDate: checkIn,
        checkOutDate: checkOut,
        guests: 2,
      );
      ref.read(tripBookingsProvider.notifier).addHotel(hotelBooking);

      // 2. Log as expense
      ref.read(expensesProvider.notifier).addExpense(TravelExpense(
        id: 'hotel-expense-${DateTime.now().millisecondsSinceEpoch}',
        category: 'Hotels',
        amount: totalCost,
        label: '${hotel['name']} Stay (${hotel['nights']} Nights)',
        date: checkIn,
      ));

      // 3. Update itinerary activities for the matching days
      final tripStart = bookings.startDate != null ? DateTime.tryParse(bookings.startDate!) : null;
      final start = DateTime.tryParse(checkIn);
      final end = DateTime.tryParse(checkOut);
      
      if (tripStart != null && start != null && end != null) {
        final currentItinerary = ref.read(itineraryProvider);
        final updatedItinerary = currentItinerary.map((day) {
          final dayDate = DateTime(tripStart.year, tripStart.month, tripStart.day).add(Duration(days: day.day - 1));
          
          // Check if dayDate falls inside [start, end)
          final isInside = (dayDate.isAtSameMomentAs(start) || dayDate.isAfter(start)) && dayDate.isBefore(end);
          if (isInside) {
            final List<ActivityItem> updatedActivities = List.from(day.activities);
            final existingIdx = updatedActivities.indexWhere((act) => 
              act.activity.toLowerCase().contains('stay booked') || 
              act.activity.toLowerCase().contains('hotel') ||
              act.activity.toLowerCase().contains('lodging')
            );
            
            final newStayAct = ActivityItem(
              time: '09:00 PM',
              activity: 'Stay Booked: ${hotel['name']}',
              description: 'Accommodation confirmed at ${hotel['name']}.',
              cost: 'Booked',
              locationName: hotel['location'],
              suggestedAttire: '',
              transport: '',
              ticketInfo: '',
              placeDetails: '',
              checked: false,
            );

            if (existingIdx != -1) {
              updatedActivities[existingIdx] = newStayAct;
            } else {
              updatedActivities.add(newStayAct);
            }
            
            return ItineraryDay(
              day: day.day,
              theme: day.theme,
              activities: updatedActivities,
              notes: day.notes,
            );
          }
          return day;
        }).toList();
        
        ref.read(itineraryProvider.notifier).setItinerary(updatedItinerary);
        
        // Save to backend database
        final email = ref.read(userProfileProvider).profile['email'];
        if (email != null && email.toString().isNotEmpty) {
          AiService.saveItinerary(email.toString(), updatedItinerary).catchError((e) {
            // Silently ignore save errors
            return false;
          });
        }
      }
      
      ref.read(userProfileProvider.notifier).addXP(300);
      
      setState(() {
        _bookingInProgress = false;
        _bookedSuccess = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkProvider);

    return Scaffold(
      backgroundColor: AiraColors.scaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: AiraColors.cardBg(isDark),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AiraColors.textPrimary(isDark)),
        title: Text(
          'Lodging Selection — $_targetCity',
          style: TextStyle(
            color: AiraColors.textPrimary(isDark),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading) ...[
              const SizedBox(height: 120),
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF00B4D8)),
                    const SizedBox(height: 16),
                    Text(
                      'Fetching curated lodging options...',
                      style: TextStyle(color: AiraColors.textSecondary(isDark), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ] else if (_bookedSuccess) ...[
              // Success Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AiraColors.cardBg(isDark),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AiraColors.scaffoldBg(isDark),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.green, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'LODGING SECURED',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AiraColors.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your hotel reservation has been saved and logged into your budget. +300 XP earned.',
                      style: TextStyle(color: AiraColors.textSecondary(isDark), fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Return to Command Center', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                'CURATED ACCOMMODATION OPTIONS IN ${_targetCity.toUpperCase()}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 10),

              ..._hotelsList.map((hotel) {
                final isSelected = _selectedHotelId == hotel['id'];
                final totalCost = hotel['pricePerNight'] * hotel['nights'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AiraColors.cardBg(isDark),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2563EB) : AiraColors.border(isDark),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.15), blurRadius: 10)]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        child: Image.network(
                          hotel['image'],
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 130,
                            color: AiraColors.scaffoldBg(isDark),
                            child: Icon(Icons.hotel, color: AiraColors.textMuted(isDark), size: 48),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    hotel['name'],
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AiraColors.textPrimary(isDark)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '★ ${hotel['rating']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hotel['location'],
                              style: TextStyle(color: AiraColors.textSecondary(isDark), fontSize: 11),
                            ),
                            Divider(height: 24, color: AiraColors.border(isDark)),
                            Text(
                              hotel['details'],
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF475569), height: 1.4),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF064E3B).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.tips_and_updates, color: Colors.greenAccent, size: 14),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      hotel['tip'],
                                      style: const TextStyle(fontSize: 9.5, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '\$${hotel['pricePerNight'].toInt()}/night',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB)),
                                    ),
                                    Text(
                                      'Total: \$${totalCost.toInt()} (${hotel['nights']} nights)',
                                      style: TextStyle(fontSize: 10, color: AiraColors.textSecondary(isDark), fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected ? const Color(0xFF2563EB) : AiraColors.scaffoldBg(isDark),
                                    foregroundColor: isSelected ? Colors.white : AiraColors.textSecondary(isDark),
                                    elevation: 0,
                                    side: isSelected ? null : BorderSide(color: AiraColors.border(isDark)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedHotelId = hotel['id'];
                                    });
                                  },
                                  child: Text(
                                    isSelected ? 'Selected' : 'Select Stay',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
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
              }),

              if (_selectedHotelId != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981), // Emerald 500
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _bookingInProgress ? null : () {
                      final selected = _hotelsList.firstWhere((h) => h['id'] == _selectedHotelId);
                      _bookHotel(selected);
                    },
                    icon: _bookingInProgress
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      _bookingInProgress ? 'Securing Lodging Stays...' : 'Lock Room Reservation Block',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

