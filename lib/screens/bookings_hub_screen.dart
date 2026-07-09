import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/theme_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/travel_providers.dart';
import '../core/models/travel_models.dart';
import '../core/services/geoapify_service.dart';
import '../core/services/foursquare_service.dart';

class BookingsHubScreen extends ConsumerStatefulWidget {
  const BookingsHubScreen({super.key});

  @override
  ConsumerState<BookingsHubScreen> createState() => _BookingsHubScreenState();
}

class _BookingsHubScreenState extends ConsumerState<BookingsHubScreen> {
  String _activeTab = 'flights'; // 'flights', 'hotels', 'cruise', 'bus', 'cabs', 'tickets'

  // Real-time API search services & states
  final _geoapify = GeoapifyService();
  final _foursquare = FoursquareService();

  // Search hotel states
  final TextEditingController _hotelSearchCtrl = TextEditingController();
  List<ExplorePlaceItem> _searchedHotels = [];
  bool _searchingHotels = false;
  String? _hotelSearchError;
  String? _hotelSearchCity;

  // Search cruise states
  final TextEditingController _cruiseSearchCtrl = TextEditingController();
  List<ExplorePlaceItem> _searchedCruises = [];
  bool _searchingCruises = false;
  String? _cruiseSearchError;
  String? _cruiseSearchCity;

  // Cab states
  String? _selectedCabType;
  bool _cabDispatching = false;
  bool _cabDispatched = false;

  final List<Map<String, dynamic>> _cabOptions = [
    {'type': 'Standard Taxi', 'eta': '4 mins', 'cost': '\$18', 'icon': Icons.local_taxi},
    {'type': 'Tesla Model Y', 'eta': '6 mins', 'cost': '\$26', 'icon': Icons.electric_car},
    {'type': 'VIP Executive Shuttle', 'eta': '9 mins', 'cost': '\$45', 'icon': Icons.airport_shuttle},
  ];

  // Cruise states
  String? _selectedCruiseType;
  bool _cruiseBooking = false;
  bool _bookingAnotherCruise = false;

  final List<Map<String, dynamic>> _cruiseOptions = [
    {'type': 'Tokyo Bay Dinner Cruise', 'duration': '2h Evening', 'cost': '\$77', 'icon': Icons.directions_boat},
    {'type': 'Yokohama Royal Suite Voyage', 'duration': 'Overnight Stay', 'cost': '\$180', 'icon': Icons.sailing},
  ];

  // Bus states
  String? _selectedBusType;
  bool _busBooking = false;
  bool _bookingAnotherBus = false;

  final List<Map<String, dynamic>> _busOptions = [
    {'type': 'Tokyo International Airport Limousine Bus', 'duration': 'Direct Crossing District (55m)', 'cost': '\$9', 'icon': Icons.directions_bus},
    {'type': 'Willer Sleeper Express', 'duration': 'Tokyo to Kyoto Sleeper', 'cost': '\$42', 'icon': Icons.departure_board},
  ];

  final List<Map<String, dynamic>> _landmarkTickets = [
    {'name': 'Sky View Deck Pass', 'time': '13:00', 'cost': '\$20', 'code': 'QR-SHB-7729', 'status': 'Active'},
    {'name': 'Tokyo Disneyland Ticket', 'time': '09:00', 'cost': '\$82', 'code': 'QR-DSN-4012', 'status': 'Active'},
  ];

  void _dispatchCab(String type, String cost) {
    setState(() => _cabDispatching = true);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      
      final clean = cost.replaceAll(r'$', '').trim();
      final parsed = double.tryParse(clean) ?? 0.0;
      
      ref.read(expensesProvider.notifier).addExpense(TravelExpense(
        id: 'cab-ride-${DateTime.now().millisecondsSinceEpoch}',
        category: 'Commute',
        amount: parsed,
        label: '$type Ride Dispatch (Crossing District Area)',
        date: '2026-06-04',
      ));

      setState(() {
        _cabDispatching = false;
        _cabDispatched = true;
      });
    });
  }

  void _bookCruise(String type, String cost) {
    setState(() => _cruiseBooking = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      final clean = cost.replaceAll(r'$', '').trim();
      final parsed = double.tryParse(clean) ?? 0.0;
      ref.read(expensesProvider.notifier).addExpense(TravelExpense(
        id: 'cruise-booking-${DateTime.now().millisecondsSinceEpoch}',
        category: 'Cruise',
        amount: parsed,
        label: '$type Voyage Reservation',
        date: '2026-06-04',
      ));
      ref.read(userProfileProvider.notifier).addXP(150);
      setState(() {
        _cruiseBooking = false;
        _bookingAnotherCruise = false;
        _selectedCruiseType = null;
      });
    });
  }

  void _bookBus(String type, String cost) {
    setState(() => _busBooking = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final clean = cost.replaceAll(r'$', '').trim();
      final parsed = double.tryParse(clean) ?? 0.0;
      ref.read(expensesProvider.notifier).addExpense(TravelExpense(
        id: 'bus-booking-${DateTime.now().millisecondsSinceEpoch}',
        category: 'Bus',
        amount: parsed,
        label: '$type Ticket Reservation',
        date: '2026-06-04',
      ));
      ref.read(userProfileProvider.notifier).addXP(80);
      setState(() {
        _busBooking = false;
        _bookingAnotherBus = false;
        _selectedBusType = null;
      });
    });
  }

  @override
  void dispose() {
    _hotelSearchCtrl.dispose();
    _cruiseSearchCtrl.dispose();
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
    ];
  }

  List<ExplorePlaceItem> _generateMockCruises(String city) {
    final cleanCity = city.trim();
    final capitalized = cleanCity.isNotEmpty 
        ? cleanCity[0].toUpperCase() + cleanCity.substring(1)
        : 'Destination';
        
    return [
      ExplorePlaceItem(
        id: 'mock-cruise-1-${DateTime.now().millisecondsSinceEpoch}',
        name: '$capitalized Royal Harbor Ocean Cruise',
        genre: 'Cruise',
        imageUrl: 'https://images.unsplash.com/photo-1548574505-5e239809ee19?auto=format&fit=crop&w=800&q=80',
        description: 'Set sail on a scenic maritime adventure departing from the main ports of $capitalized. Exceptional service and sunset views.',
        rating: 4.8,
        estimatedDuration: '180 per passenger',
        estimatedCost: '\$180',
        address: 'Terminal Pier 3, $capitalized Port',
        durationMinutes: 180,
      ),
      ExplorePlaceItem(
        id: 'mock-cruise-2-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Emerald Water Star Voyager',
        genre: 'Cruise',
        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
        description: 'Enjoy a delightful coastal cruise experience exploring the local waters and landmark vistas of $capitalized.',
        rating: 4.6,
        estimatedDuration: '95 per passenger',
        estimatedCost: '\$95',
        address: 'Marina Gateway East, $capitalized',
        durationMinutes: 95,
      ),
    ];
  }

  void _searchHotelsForCity(String cityQuery) async {
    if (cityQuery.trim().isEmpty) return;
    setState(() {
      _searchingHotels = true;
      _hotelSearchError = null;
      _searchedHotels = [];
      _hotelSearchCity = cityQuery;
    });

    try {
      final coords = await _geoapify.geocodeCity(cityQuery);
      if (coords == null) {
        setState(() {
          _searchedHotels = _generateMockHotels(cityQuery);
          _searchingHotels = false;
        });
        return;
      }

      final hotels = await _foursquare.fetchHotelsAndLodgings(
        coords['lat']!,
        coords['lon']!,
        cityQuery,
      );

      setState(() {
        _searchedHotels = hotels.isNotEmpty ? hotels : _generateMockHotels(cityQuery);
        _searchingHotels = false;
      });
    } catch (e) {
      debugPrint('Hotel search error, falling back: $e');
      setState(() {
        _searchedHotels = _generateMockHotels(cityQuery);
        _searchingHotels = false;
      });
    }
  }

  void _searchCruisesForCity(String cityQuery) async {
    if (cityQuery.trim().isEmpty) return;
    setState(() {
      _searchingCruises = true;
      _cruiseSearchError = null;
      _searchedCruises = [];
      _cruiseSearchCity = cityQuery;
    });

    try {
      final coords = await _geoapify.geocodeCity(cityQuery);
      if (coords == null) {
        setState(() {
          _searchedCruises = _generateMockCruises(cityQuery);
          _searchingCruises = false;
        });
        return;
      }

      final cruises = await _foursquare.fetchCruisesAndBoats(
        coords['lat']!,
        coords['lon']!,
        cityQuery,
      );

      setState(() {
        _searchedCruises = cruises.isNotEmpty ? cruises : _generateMockCruises(cityQuery);
        _searchingCruises = false;
      });
    } catch (e) {
      debugPrint('Cruise search error, falling back: $e');
      setState(() {
        _searchedCruises = _generateMockCruises(cityQuery);
        _searchingCruises = false;
      });
    }
  }

  void _showBookingDialog(ExplorePlaceItem item, String category) {
    final TextEditingController nameCtrl = TextEditingController(text: 'John Doe');
    final TextEditingController nightsCtrl = TextEditingController(text: '3');
    final TextEditingController guestsCtrl = TextEditingController(text: '2');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    final isDark = ref.read(isDarkProvider);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: TriaColors.dialogBg(isDark),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: TriaColors.border(isDark))),
              title: Row(
                children: [
                  Icon(category == 'Hotels' ? Icons.hotel_rounded : Icons.directions_boat_rounded, color: const Color(0xFF2563EB), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'BOOK ${category.toUpperCase()}',
                      style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(item.address, style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 10.5)),
                    Divider(height: 20, color: TriaColors.border(isDark)),
                    
                    Text('Guest Name', style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 12),
                      decoration: InputDecoration(
                        fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(category == 'Hotels' ? 'Nights' : 'Tickets', style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: nightsCtrl,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 12),
                                decoration: InputDecoration(
                                  fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                  filled: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Guests', style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: guestsCtrl,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 12),
                                decoration: InputDecoration(
                                  fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                  filled: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    Text('Departure / Check-in Date', style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: isDark
                                  ? ThemeData.dark().copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: Color(0xFF2563EB),
                                        surface: Color(0xFF0A1628),
                                        onSurface: Colors.white,
                                      ),
                                    )
                                  : ThemeData.light().copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFF2563EB),
                                        surface: Colors.white,
                                        onSurface: Colors.black87,
                                      ),
                                    ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                              style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 12),
                            ),
                            Icon(Icons.calendar_today, color: TriaColors.textSecondary(isDark), size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: TriaColors.textSecondary(isDark))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                  onPressed: () {
                    final qty = int.tryParse(nightsCtrl.text) ?? 1;
                    final pricePerUnit = item.durationMinutes.toDouble();
                    final totalCost = pricePerUnit * qty;

                    ref.read(expensesProvider.notifier).addExpense(TravelExpense(
                      id: '${category.toLowerCase()}-${DateTime.now().millisecondsSinceEpoch}',
                      category: category,
                      amount: totalCost,
                      label: category == 'Hotels'
                          ? '${item.name} Stay ($qty Nights for ${nameCtrl.text})'
                          : '${item.name} Voyage ($qty Tickets for ${nameCtrl.text})',
                      date: '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                    ));

                    ref.read(userProfileProvider.notifier).addXP(category == 'Hotels' ? 300 : 150);

                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: TriaColors.dialogBg(isDark),
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Successfully booked ${item.name}! logged in budget.',
                              style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ));
                  },
                  child: const Text('Confirm Book', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesProvider);
    final isDark = ref.watch(isDarkProvider);
    
    final bookedFlights = expenses.where((e) => e.category == 'Flights').toList();
    final bookedHotels = expenses.where((e) => e.category == 'Hotels').toList();
    final bookedCruises = expenses.where((e) => e.category == 'Cruise').toList();
    final bookedBuses = expenses.where((e) => e.category == 'Bus' || (e.category == 'Commute' && e.label.contains('Bus'))).toList();

    return Scaffold(
      backgroundColor: TriaColors.scaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: TriaColors.cardBg(isDark),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: TriaColors.textPrimary(isDark)),
        title: Text('Unified Bookings Hub', style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Column(
        children: [
          // Sub-Tab Switcher
          Container(
            color: TriaColors.cardBg(isDark),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _tabItem('flights', '✈️ Flights', bookedFlights.isNotEmpty, isDark),
                  const SizedBox(width: 8),
                  _tabItem('hotels', '🏨 Stays', bookedHotels.isNotEmpty, isDark),
                  const SizedBox(width: 8),
                  _tabItem('cruise', '🚢 Cruises', bookedCruises.isNotEmpty, isDark),
                  const SizedBox(width: 8),
                  _tabItem('bus', '🚌 Bus Stops', bookedBuses.isNotEmpty, isDark),
                  const SizedBox(width: 8),
                  _tabItem('cabs', '🚕 Cab Dispatch', _cabDispatched, isDark),
                  const SizedBox(width: 8),
                  _tabItem('tickets', '🎫  Tickets', true, isDark),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildActiveTabContent(bookedFlights, bookedHotels, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabItem(String tabId, String label, bool activeIndicator, bool isDark) {
    final isSelected = _activeTab == tabId;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (activeIndicator) ...[
            const SizedBox(width: 4),
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _activeTab = tabId),
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: TriaColors.scaffoldBg(isDark),
      disabledColor: TriaColors.scaffoldBg(isDark),
      side: BorderSide(color: isSelected ? const Color(0xFF2563EB) : TriaColors.border(isDark)),
      labelStyle: TextStyle(
        fontSize: 11,
        color: isSelected ? Colors.white : TriaColors.textSecondary(isDark),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildActiveTabContent(List<TravelExpense> flights, List<TravelExpense> hotels, bool isDark) {
    final expenses = ref.watch(expensesProvider);

    if (_activeTab == 'flights') {
      if (flights.isEmpty) {
        return _buildEmptyState('No Flight reservations found.', 'Browse outbound flight packages and book one to register.', '/flights', isDark);
      }
      return Column(
        children: flights.map((f) => _buildBookingCard(f.label, 'Class: Economy • Gate: Terminal 1', Icons.flight_takeoff, isDark)).toList(),
      );
    }

    if (_activeTab == 'hotels') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // API Search Area
          const Text(
            'SEARCH REAL-TIME HOTELS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Color(0xFF00B4D8)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _hotelSearchCtrl,
                  style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Enter city (e.g. London, Singapore, Tokyo)',
                    hintStyle: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 13),
                    fillColor: TriaColors.cardBg(isDark),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: TriaColors.border(isDark)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2563EB)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    suffixIcon: _hotelSearchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: TriaColors.textMuted(isDark), size: 16),
                            onPressed: () {
                              _hotelSearchCtrl.clear();
                              setState(() {
                                _searchedHotels = [];
                                _hotelSearchError = null;
                              });
                            },
                          )
                        : null,
                  ),
                  onSubmitted: _searchHotelsForCity,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _searchHotelsForCity(_hotelSearchCtrl.text),
                child: const Icon(Icons.search, color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Loading & States
          if (_searchingHotels)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00B4D8)),
                    SizedBox(height: 10),
                    Text('Searching hotels...', style: TextStyle(color: Color(0xFF00B4D8), fontSize: 11)),
                  ],
                ),
              ),
            ),

          if (_hotelSearchError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(_hotelSearchError!, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
              ),
            ),

          if (_searchedHotels.isNotEmpty) ...[
            Text(
              'REAL HOTELS IN ${_hotelSearchCity?.toUpperCase()}',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: TriaColors.textSecondary(isDark)),
            ),
            const SizedBox(height: 10),
            ..._searchedHotels.map((hotel) => _buildApiPlaceSearchCard(hotel, 'Hotels', isDark)),
            const SizedBox(height: 16),
          ],

          // Confirmed Stays Section
          const Text(
            'CONFIRMED RESERVATIONS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Color(0xFF00B4D8)),
          ),
          const SizedBox(height: 10),
          if (hotels.isEmpty)
            _buildEmptyState('No hotel lodgings confirmed yet.', 'Search a city above and book a stay, or register an external stay.', '/hotels', isDark)
          else
            Column(
              children: hotels.map((h) => _buildBookingCard(h.label, 'Scheduled: ${h.date} • Secured Room', Icons.hotel, isDark)).toList(),
            ),
        ],
      );
    }

    if (_activeTab == 'cruise') {
      final cruiseExpenses = expenses.where((e) => e.category == 'Cruise').toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cruise search bar
          const Text(
            'SEARCH REAL-TIME CRUISES',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Color(0xFF00B4D8)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cruiseSearchCtrl,
                  style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Enter coastal city (e.g. Miami, Singapore, Yokohama)',
                    hintStyle: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 13),
                    fillColor: TriaColors.cardBg(isDark),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: TriaColors.border(isDark)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF2563EB)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    suffixIcon: _cruiseSearchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: TriaColors.textMuted(isDark), size: 16),
                            onPressed: () {
                              _cruiseSearchCtrl.clear();
                              setState(() {
                                _searchedCruises = [];
                                _cruiseSearchError = null;
                              });
                            },
                          )
                        : null,
                  ),
                  onSubmitted: _searchCruisesForCity,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _searchCruisesForCity(_cruiseSearchCtrl.text),
                child: const Icon(Icons.search, color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Loading & States
          if (_searchingCruises)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00B4D8)),
                    SizedBox(height: 10),
                    Text('Searching coastal routes and cruises near port...', style: TextStyle(color: Color(0xFF00B4D8), fontSize: 11)),
                  ],
                ),
              ),
            ),

          if (_cruiseSearchError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(_cruiseSearchError!, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
              ),
            ),

          if (_searchedCruises.isNotEmpty) ...[
            Text(
              'CRUISES & PORTS IN ${_cruiseSearchCity?.toUpperCase()}',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: TriaColors.textSecondary(isDark)),
            ),
            const SizedBox(height: 10),
            ..._searchedCruises.map((cruise) => _buildApiPlaceSearchCard(cruise, 'Cruise', isDark)),
            const SizedBox(height: 16),
          ],

          // Confirmed cruises
          const Text(
            'CONFIRMED CRUISE EXPEDITIONS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Color(0xFF00B4D8)),
          ),
          const SizedBox(height: 10),
          if (cruiseExpenses.isEmpty && !_bookingAnotherCruise) ...[
            _buildEmptyState('No cruise expeditions confirmed yet.', 'Search a port city above or select from default packages.', '', isDark),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF2563EB))),
              onPressed: () => setState(() {
                _bookingAnotherCruise = true;
                _selectedCruiseType = null;
              }),
              child: const Text('View Cruise Offers Packages', style: TextStyle(color: Color(0xFF2563EB))),
            ),
          ] else if (_bookingAnotherCruise) ...[
            // show mock cruise selectors
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('MOCK OFFERS SELECTOR', style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 11, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => setState(() => _bookingAnotherCruise = false),
                  child: const Text('Back to search', style: TextStyle(color: Color(0xFF00B4D8), fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._cruiseOptions.map((c) {
              final isSelected = _selectedCruiseType == c['type'];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TriaColors.cardBg(isDark),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? const Color(0xFF2563EB) : TriaColors.border(isDark), width: isSelected ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Icon(c['icon'], color: isSelected ? const Color(0xFF2563EB) : Colors.grey, size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['type'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: TriaColors.textPrimary(isDark))),
                          Text('Duration: ${c['duration']}', style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 10)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(c['cost'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB))),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCruiseType = c['type'];
                            });
                          },
                          child: Text(isSelected ? 'Selected' : 'Select', style: TextStyle(fontSize: 10, color: isSelected ? const Color(0xFF00B4D8) : Colors.grey, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ],
                ),
              );
            }),
            if (_selectedCruiseType != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                  onPressed: _cruiseBooking ? null : () {
                    final cost = _cruiseOptions.firstWhere((c) => c['type'] == _selectedCruiseType)['cost'];
                    _bookCruise(_selectedCruiseType!, cost);
                  },
                  icon: _cruiseBooking
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.payment_outlined, color: Colors.white),
                  label: Text(
                    _cruiseBooking ? 'Reserving Cruise Suite...' : 'Confirm Cruise Reservation Block',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ]
          ] else ...[
            ...cruiseExpenses.map((c) => _buildBookingCard(c.label, 'Scheduled: ${c.date} • Port Terminal Entrance', Icons.directions_boat, isDark)),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF2563EB))),
              onPressed: () => setState(() {
                _bookingAnotherCruise = true;
                _selectedCruiseType = null;
              }),
              child: const Text('Book Another Cruise Offer', style: TextStyle(color: Color(0xFF2563EB))),
            ),
          ],
        ],
      );
    }

    if (_activeTab == 'bus') {
      final busExpenses = expenses.where((e) => e.category == 'Bus' || (e.category == 'Commute' && e.label.contains('Bus'))).toList();
      if (busExpenses.isNotEmpty && !_bookingAnotherBus) {
        return Column(
          children: [
            ...busExpenses.map((b) => _buildBookingCard(b.label, 'Status: Confirmed • Seat: Row 5', Icons.directions_bus, isDark)),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF2563EB))),
              onPressed: () => setState(() {
                _bookingAnotherBus = true;
                _selectedBusType = null;
              }),
              child: const Text('Book Another Bus Ticket', style: TextStyle(color: Color(0xFF2563EB))),
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SELECT BUS BLOCK COMMUTE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Color(0xFF00B4D8))),
          const SizedBox(height: 10),
          ..._busOptions.map((b) {
            final isSelected = _selectedBusType == b['type'];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TriaColors.cardBg(isDark),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? const Color(0xFF2563EB) : TriaColors.border(isDark), width: isSelected ? 2 : 1),
              ),
              child: Row(
                children: [
                  Icon(b['icon'], color: isSelected ? const Color(0xFF2563EB) : Colors.grey, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b['type'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: TriaColors.textPrimary(isDark))),
                        Text('Details: ${b['duration']}', style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 10)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(b['cost'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB))),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedBusType = b['type'];
                          });
                        },
                        child: Text(isSelected ? 'Selected' : 'Select', style: TextStyle(fontSize: 10, color: isSelected ? const Color(0xFF00B4D8) : Colors.grey, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ],
              ),
            );
          }),

          if (_selectedBusType != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                onPressed: _busBooking ? null : () {
                  final cost = _busOptions.firstWhere((b) => b['type'] == _selectedBusType)['cost'];
                  _bookBus(_selectedBusType!, cost);
                },
                icon: _busBooking
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.directions_bus, color: Colors.white),
                label: Text(
                  _busBooking ? 'Issuing Bus Pass...' : 'Confirm Bus Ticket Reservation',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ]
        ],
      );
    }

    if (_activeTab == 'cabs') {
      if (_cabDispatched) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: TriaColors.cardBg(isDark),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: TriaColors.border(isDark)),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: isDark ? const Color(0xFF1A2744) : const Color(0xFFE2E8F0),
                child: const Icon(Icons.airport_shuttle, color: Color(0xFF00B4D8), size: 32),
              ),
              const SizedBox(height: 16),
              Text('TAXI EN ROUTE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: TriaColors.textPrimary(isDark))),
              const SizedBox(height: 6),
              Text(
                '$_selectedCabType has been dispatched to Famous Scramble Crossing. Estimated ETA: 4 mins.',
                style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                onPressed: () => setState(() {
                  _cabDispatched = false;
                  _selectedCabType = null;
                }),
                child: const Text('Cancel Dispatch Request', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DISPATCH LOCAL TRIA TAXI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Color(0xFF00B4D8))),
          const SizedBox(height: 10),
          ..._cabOptions.map((cab) {
            final isSelected = _selectedCabType == cab['type'];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TriaColors.cardBg(isDark),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? const Color(0xFF2563EB) : TriaColors.border(isDark), width: isSelected ? 2 : 1),
              ),
              child: Row(
                children: [
                  Icon(cab['icon'], color: isSelected ? const Color(0xFF2563EB) : Colors.grey, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cab['type'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: TriaColors.textPrimary(isDark))),
                        Text('ETA: ${cab['eta']}', style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 10)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(cab['cost'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB))),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCabType = cab['type'];
                          });
                        },
                        child: Text(isSelected ? 'Selected' : 'Select', style: TextStyle(fontSize: 10, color: isSelected ? const Color(0xFF00B4D8) : Colors.grey, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ],
              ),
            );
          }),

          if (_selectedCabType != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                onPressed: _cabDispatching ? null : () {
                  final cost = _cabOptions.firstWhere((c) => c['type'] == _selectedCabType)['cost'];
                  _dispatchCab(_selectedCabType!, cost);
                },
                icon: _cabDispatching
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.near_me, color: Colors.white),
                label: Text(
                  _cabDispatching ? 'Contacting Dispatcher...' : 'Confirm Cab Dispatch Now',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ]
        ],
      );
    }

    // tickets tab
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ACTIVE LANDMARK PASSES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Color(0xFF00B4D8))),
        const SizedBox(height: 10),
        ..._landmarkTickets.map((t) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: TriaColors.cardBg(isDark), borderRadius: BorderRadius.circular(16), border: Border.all(color: TriaColors.border(isDark))),
            child: Row(
              children: [
                Icon(Icons.qr_code_2, color: TriaColors.textPrimary(isDark), size: 40),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: TriaColors.textPrimary(isDark))),
                      Text('Scheduled: ${t['time']} • code: ${t['code']}', style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 10)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: const Text('ACTIVE', style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBookingCard(String title, String details, IconData icon, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TriaColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TriaColors.border(isDark)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05), blurRadius: 6)],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.2), child: Icon(icon, color: const Color(0xFF2563EB))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: TriaColors.textPrimary(isDark))),
                const SizedBox(height: 2),
                Text(details, style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg, String cta, String route, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: TriaColors.cardBg(isDark), borderRadius: BorderRadius.circular(20), border: Border.all(color: TriaColors.border(isDark))),
      child: Column(
        children: [
          Icon(Icons.info_outline, color: TriaColors.textSecondary(isDark), size: 32),
          const SizedBox(height: 12),
          Text(msg, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: TriaColors.textPrimary(isDark))),
          const SizedBox(height: 4),
          Text(cta, style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 10), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            onPressed: () => context.push(route),
            child: const Text('Procure Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildApiPlaceSearchCard(ExplorePlaceItem item, String category, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: TriaColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TriaColors.border(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                child: Image.network(
                  item.imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 140,
                    color: TriaColors.scaffoldBg(isDark),
                    child: Icon(Icons.image_not_supported, color: TriaColors.textMuted(isDark), size: 40),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${item.rating}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: TriaColors.textPrimary(isDark)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF00B4D8), size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.address,
                        style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 10.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Divider(height: 20, color: TriaColors.border(isDark)),
                Text(
                  item.description,
                  style: TextStyle(fontSize: 11, color: TriaColors.textSecondary(isDark), height: 1.45),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.estimatedCost,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF00B4D8)),
                        ),
                        Text(
                          category == 'Hotels' ? 'Estimated price / night' : 'Estimated ticket price',
                          style: TextStyle(fontSize: 9, color: TriaColors.textMuted(isDark)),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => _showBookingDialog(item, category),
                      icon: const Icon(Icons.add_shopping_cart, size: 12),
                      label: Text(
                        category == 'Hotels' ? 'Book Stay' : 'Book Voyage',
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
  }
}
