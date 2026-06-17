import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/travel_providers.dart';
import '../core/models/travel_models.dart';

class FlightsScreen extends ConsumerStatefulWidget {
  const FlightsScreen({super.key});

  @override
  ConsumerState<FlightsScreen> createState() => _FlightsScreenState();
}

class _FlightsScreenState extends ConsumerState<FlightsScreen> {
  String? _selectedFlightId;
  bool _bookingInProgress = false;
  bool _bookedSuccess = false;

  final List<Map<String, dynamic>> _flightsList = [
    {
      'id': 'fl-1',
      'airline': 'Skyline Airlines Tokyo',
      'code': 'ZG-052',
      'price': 590.00,
      'badge': 'BUDGET FOCUS',
      'duration': '7h 15m (Direct)',
      'times': '11:45 AM - 07:00 PM',
      'details': 'Eco-comfort capsule seat, standard cabin luggage allocation.',
    },
    {
      'id': 'fl-2',
      'airline': 'All Nippon Airways (ANA)',
      'code': 'NH-820',
      'price': 890.00,
      'badge': 'RECOMMENDED',
      'duration': '6h 50m (Direct)',
      'times': '08:20 AM - 03:10 PM',
      'details': 'Premium economy shell seat, organic meal service, lounge check-in.',
    },
  ];

  void _bookFlight(Map<String, dynamic> flight) {
    setState(() => _bookingInProgress = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      ref.read(expensesProvider.notifier).addExpense(TravelExpense(
        id: 'flight-booking-${DateTime.now().millisecondsSinceEpoch}',
        category: 'Flights',
        amount: flight['price'],
        label: '${flight['airline']} Flight ${flight['code']} (${flight['times']})',
        date: '2026-06-04',
      ));
      ref.read(userProfileProvider.notifier).addXP(250);
      setState(() {
        _bookingInProgress = false;
        _bookedSuccess = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2744),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Flight Procurement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2744),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFF2563EB), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AI Budget Engine Enforced: Search parameters aligned to moderate \$1,500 cap.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_bookedSuccess) ...[
              // Success card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2744),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFF1E293B),
                      child: Icon(Icons.check, color: Colors.green, size: 32),
                    ),
                    const SizedBox(height: 16),
                    const Text('FLIGHT BOOKED SECURELY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 6),
                    const Text(
                      'Your flight has been ticketed and logged into your dashboard timeline. +250 XP earned.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
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
              const Text('AVAILABLE OUTBOUND BLOCKS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Colors.white70)),
              const SizedBox(height: 10),

              ..._flightsList.map((flight) {
                final isSelected = _selectedFlightId == flight['id'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2744),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF334155),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.15), blurRadius: 10)]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF0A1628) : const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: Text(
                              flight['badge'],
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          Text(
                            '\$${flight['price'].toInt()}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.flight_takeoff, color: Color(0xFF94A3B8), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${flight['airline']} • ${flight['code']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${flight['times']} (${flight['duration']})',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Color(0xFF334155)),
                      Text(
                        flight['details'],
                        style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.35),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? const Color(0xFF2563EB) : const Color(0xFF0A1628),
                            foregroundColor: isSelected ? Colors.white : const Color(0xFF94A3B8),
                            side: isSelected ? null : const BorderSide(color: Color(0xFF334155)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedFlightId = flight['id'];
                            });
                          },
                          child: Text(
                            isSelected ? 'Selected Outbound Option' : 'Select Outbound Option',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              if (_selectedFlightId != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06D6A0), // Emerald 500
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _bookingInProgress ? null : () {
                      final selected = _flightsList.firstWhere((f) => f['id'] == _selectedFlightId);
                      _bookFlight(selected);
                    },
                    icon: _bookingInProgress
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.payment_outlined, size: 18),
                    label: Text(
                      _bookingInProgress ? 'Securing Flight Tickets...' : 'Procure & Book selected Flight Package',
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
