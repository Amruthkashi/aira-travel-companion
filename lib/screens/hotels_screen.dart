import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/travel_providers.dart';
import '../core/models/travel_models.dart';

class HotelsScreen extends ConsumerStatefulWidget {
  const HotelsScreen({super.key});

  @override
  ConsumerState<HotelsScreen> createState() => _HotelsScreenState();
}

class _HotelsScreenState extends ConsumerState<HotelsScreen> {
  String? _selectedHotelId;
  bool _bookingInProgress = false;
  bool _bookedSuccess = false;

  final List<Map<String, dynamic>> _hotelsList = [
    {
      'id': 'ht-1',
      'name': 'Skyline Godzilla Hotel',
      'rating': 4.8,
      'image': 'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=400',
      'pricePerNight': 110.00,
      'nights': 4,
      'location': '900m from West Central Station East Exit',
      'details': 'Sleek rooms located next to Tokyo Landmarks. Highlights: Godzilla skyline viewing deck, premium rain shower head, smart IoT lights.',
      'tip': 'AI VERIFIED: Godzilla roars on the hour. Floors 20-30 are best.',
    },
    {
      'id': 'ht-2',
      'name': 'Nine Hours Capsule Stay',
      'rating': 4.5,
      'image': 'https://images.unsplash.com/photo-1549294413-26f195afcbce?w=400',
      'pricePerNight': 88.00,
      'nights': 5,
      'location': '300m from West Central Tokyo Transit Grid',
      'details': 'Immersive futuristic capsule beds, high-speed mesh networks, sound-dampened sleeping units.',
      'tip': 'AI VERIFIED: Includes NFC capsule unlock and smart alarm.',
    },
  ];

  void _bookHotel(Map<String, dynamic> hotel) {
    setState(() => _bookingInProgress = true);
    final totalCost = hotel['pricePerNight'] * hotel['nights'];
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      ref.read(expensesProvider.notifier).addExpense(TravelExpense(
        id: 'hotel-booking-${DateTime.now().millisecondsSinceEpoch}',
        category: 'Hotels',
        amount: totalCost,
        label: '${hotel['name']} Stay (${hotel['nights']} Nights)',
        date: '2026-06-04',
      ));
      ref.read(userProfileProvider.notifier).addXP(300);
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
        title: const Text('Lodging Selection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_bookedSuccess) ...[
              // Success Card
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
                    const Text('LODGING SECURED', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 6),
                    const Text(
                      'Your hotel reservation has been saved and logged into your budget. +300 XP earned.',
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
              const Text('CURATED ACCOMMODATION OPTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Colors.white70)),
              const SizedBox(height: 10),

              ..._hotelsList.map((hotel) {
                final isSelected = _selectedHotelId == hotel['id'];
                final totalCost = hotel['pricePerNight'] * hotel['nights'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
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
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        child: Image.network(hotel['image'], height: 130, width: double.infinity, fit: BoxFit.cover),
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
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
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
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                            const Divider(height: 24, color: Color(0xFF334155)),
                            Text(
                              hotel['details'],
                              style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.4),
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
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected ? const Color(0xFF2563EB) : const Color(0xFF0A1628),
                                    foregroundColor: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                    elevation: 0,
                                    side: isSelected ? null : const BorderSide(color: Color(0xFF334155)),
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
