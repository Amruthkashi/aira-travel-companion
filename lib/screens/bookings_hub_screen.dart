import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/travel_providers.dart';
import '../core/models/travel_models.dart';

class BookingsHubScreen extends ConsumerStatefulWidget {
  const BookingsHubScreen({super.key});

  @override
  ConsumerState<BookingsHubScreen> createState() => _BookingsHubScreenState();
}

class _BookingsHubScreenState extends ConsumerState<BookingsHubScreen> {
  String _activeTab = 'flights'; // 'flights', 'hotels', 'cruise', 'bus', 'cabs', 'tickets'

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
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesProvider);
    
    final bookedFlights = expenses.where((e) => e.category == 'Flights').toList();
    final bookedHotels = expenses.where((e) => e.category == 'Hotels').toList();
    final bookedCruises = expenses.where((e) => e.category == 'Cruise').toList();
    final bookedBuses = expenses.where((e) => e.category == 'Bus' || (e.category == 'Commute' && e.label.contains('Bus'))).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2744),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Unified Bookings Hub', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Column(
        children: [
          // Sub-Tab Switcher
          Container(
            color: const Color(0xFF1A2744),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _tabItem('flights', '✈️ Flights', bookedFlights.isNotEmpty),
                  const SizedBox(width: 8),
                  _tabItem('hotels', '🏨 Stays', bookedHotels.isNotEmpty),
                  const SizedBox(width: 8),
                  _tabItem('cruise', '🚢 Cruises', bookedCruises.isNotEmpty),
                  const SizedBox(width: 8),
                  _tabItem('bus', '🚌 Bus Stops', bookedBuses.isNotEmpty),
                  const SizedBox(width: 8),
                  _tabItem('cabs', '🚕 Cab Dispatch', _cabDispatched),
                  const SizedBox(width: 8),
                  _tabItem('tickets', '🎫 Tickets', true),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildActiveTabContent(bookedFlights, bookedHotels),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabItem(String tabId, String label, bool activeIndicator) {
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
      backgroundColor: const Color(0xFF0A1628),
      disabledColor: const Color(0xFF0A1628),
      side: BorderSide(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF334155)),
      labelStyle: TextStyle(
        fontSize: 11,
        color: isSelected ? Colors.white : const Color(0xFF94A3B8),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildActiveTabContent(List<TravelExpense> flights, List<TravelExpense> hotels) {
    final expenses = ref.watch(expensesProvider);

    if (_activeTab == 'flights') {
      if (flights.isEmpty) {
        return _buildEmptyState('No Flight reservations found.', 'Browse outbound flight packages and book one to register.', '/flights');
      }
      return Column(
        children: flights.map((f) => _buildBookingCard(f.label, 'Class: Economy • Gate: Terminal 1', Icons.flight_takeoff)).toList(),
      );
    }

    if (_activeTab == 'hotels') {
      if (hotels.isEmpty) {
        return _buildEmptyState('No hotel lodgings confirmed.', 'Find your optimal capsules or design stays and lock a room.', '/hotels');
      }
      return Column(
        children: hotels.map((h) => _buildBookingCard(h.label, 'Check-in: 03:00 PM • Room: 402', Icons.hotel)).toList(),
      );
    }

    if (_activeTab == 'cruise') {
      final cruiseExpenses = expenses.where((e) => e.category == 'Cruise').toList();
      if (cruiseExpenses.isNotEmpty && !_bookingAnotherCruise) {
        return Column(
          children: [
            ...cruiseExpenses.map((c) => _buildBookingCard(c.label, 'Boarding: 06:00 PM • Dock: Pier 3', Icons.directions_boat)),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF2563EB))),
              onPressed: () => setState(() {
                _bookingAnotherCruise = true;
                _selectedCruiseType = null;
              }),
              child: const Text('Book Another Cruise', style: TextStyle(color: Color(0xFF2563EB))),
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SELECT CRUISE VOYAGE STAY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Colors.white70)),
          const SizedBox(height: 10),
          ..._cruiseOptions.map((c) {
            final isSelected = _selectedCruiseType == c['type'];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2744),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF334155), width: isSelected ? 2 : 1),
              ),
              child: Row(
                children: [
                  Icon(c['icon'], color: isSelected ? const Color(0xFF2563EB) : Colors.grey, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['type'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                        Text('Duration: ${c['duration']}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
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
            )
          ]
        ],
      );
    }

    if (_activeTab == 'bus') {
      final busExpenses = expenses.where((e) => e.category == 'Bus' || (e.category == 'Commute' && e.label.contains('Bus'))).toList();
      if (busExpenses.isNotEmpty && !_bookingAnotherBus) {
        return Column(
          children: [
            ...busExpenses.map((b) => _buildBookingCard(b.label, 'Status: Confirmed • Seat: Row 5', Icons.directions_bus)),
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
          const Text('SELECT BUS BLOCK COMMUTE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Colors.white70)),
          const SizedBox(height: 10),
          ..._busOptions.map((b) {
            final isSelected = _selectedBusType == b['type'];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2744),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF334155), width: isSelected ? 2 : 1),
              ),
              child: Row(
                children: [
                  Icon(b['icon'], color: isSelected ? const Color(0xFF2563EB) : Colors.grey, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b['type'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                        Text('Details: ${b['duration']}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
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
            color: const Color(0xFF1A2744),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFF1E293B),
                child: Icon(Icons.airport_shuttle, color: Color(0xFF00B4D8), size: 32),
              ),
              const SizedBox(height: 16),
              const Text('TAXI EN ROUTE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 6),
              Text(
                '$_selectedCabType has been dispatched to Famous Scramble Crossing. Estimated ETA: 4 mins.',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
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
          const Text('DISPATCH LOCAL AIRA TAXI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Colors.white70)),
          const SizedBox(height: 10),
          ..._cabOptions.map((cab) {
            final isSelected = _selectedCabType == cab['type'];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2744),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF334155), width: isSelected ? 2 : 1),
              ),
              child: Row(
                children: [
                  Icon(cab['icon'], color: isSelected ? const Color(0xFF2563EB) : Colors.grey, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cab['type'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                        Text('ETA: ${cab['eta']}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
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
        const Text('ACTIVE LANDMARK PASSES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Colors.white70)),
        const SizedBox(height: 10),
        ..._landmarkTickets.map((t) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1A2744), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF334155))),
            child: Row(
              children: [
                const Icon(Icons.qr_code_2, color: Colors.white, size: 40),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                      Text('Scheduled: ${t['time']} • code: ${t['code']}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
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

  Widget _buildBookingCard(String title, String details, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.2), child: Icon(icon, color: const Color(0xFF2563EB))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                const SizedBox(height: 2),
                Text(details, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg, String cta, String route) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF1A2744), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF334155))),
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF94A3B8), size: 32),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
          const SizedBox(height: 4),
          Text(cta, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10), textAlign: TextAlign.center),
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
}
