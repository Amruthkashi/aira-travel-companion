import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/theme_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/travel_providers.dart';
import '../core/models/travel_models.dart';
import '../core/services/aviationstack_service.dart';
import '../core/models/aviation_flight.dart';

class FlightsScreen extends ConsumerStatefulWidget {
  const FlightsScreen({super.key});

  @override
  ConsumerState<FlightsScreen> createState() => _FlightsScreenState();
}

class _FlightsScreenState extends ConsumerState<FlightsScreen> {
  final TextEditingController _searchController = TextEditingController(text: 'NH820');
  final AviationstackService _aviationService = AviationstackService();
  
  List<AviationFlight> _apiFlights = [];
  bool _isLoading = false;
  String? _error;
  bool _bookedSuccess = false;

  @override
  void initState() {
    super.initState();
    _searchFlights('NH820');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _aviationService.dispose();
    super.dispose();
  }

  Future<void> _searchFlights(String query) async {
    final trimmed = query.trim().toUpperCase();
    if (trimmed.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _bookedSuccess = false;
    });

    try {
      final results = await _aviationService.searchFlights(trimmed);
      setState(() {
        _apiFlights = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showBookingDialog(AviationFlight flight) {
    final isDark = ref.read(isDarkProvider);
    final nameCtrl = TextEditingController(text: 'Alex Mercer');
    final passengersCtrl = TextEditingController(text: '1');
    String seatClass = 'Economy';
    String flightType = 'going'; 

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: TriaColors.dialogBg(isDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.flight_takeoff, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(
                'Book Flight ${flight.flightNumber}',
                style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogField('Passenger Name', nameCtrl, isDark),
                _dialogField('Passengers Count', passengersCtrl, isDark, isNumeric: true),
                const SizedBox(height: 12),
                _dropdownField(
                  label: 'Seat Class',
                  value: seatClass,
                  items: const ['Economy', 'Premium Economy', 'Business', 'First Class'],
                  onChanged: (val) => setDlgState(() => seatClass = val!),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _dropdownField(
                  label: 'Flight Direction / Type',
                  value: flightType == 'going' ? 'Outbound (going)' : flightType == 'return' ? 'Inbound (return)' : 'Internal (other)',
                  items: const ['Outbound (going)', 'Inbound (return)', 'Internal (other)'],
                  onChanged: (val) {
                    setDlgState(() {
                      if (val == 'Outbound (going)') {
                        flightType = 'going';
                      } else if (val == 'Inbound (return)') {
                        flightType = 'return';
                      } else {
                        flightType = 'other';
                      }
                    });
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final passengerCount = int.tryParse(passengersCtrl.text) ?? 1;
                final basePrice = 450.0 + (flight.flightNumber.hashCode.abs() % 350);
                final totalPrice = basePrice * passengerCount;

                // 1. Add flight booking to Wizard
                ref.read(tripBookingsProvider.notifier).addFlight(FlightBooking(
                  id: 'fl-${DateTime.now().millisecondsSinceEpoch}',
                  airline: flight.airlineName,
                  flightNumber: flight.flightNumber,
                  pnr: 'PNR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                  departureCity: flight.departureCity,
                  arrivalCity: flight.arrivalCity,
                  departureDate: flight.departureDate,
                  arrivalDate: flight.arrivalDate,
                  departureTime: flight.departureTime,
                  arrivalTime: flight.arrivalTime,
                  seatClass: seatClass,
                  passengers: passengerCount,
                  flightType: flightType,
                ));

                // 2. Add expense
                ref.read(expensesProvider.notifier).addExpense(TravelExpense(
                  id: 'flight-booking-${DateTime.now().millisecondsSinceEpoch}',
                  category: 'Flights',
                  amount: totalPrice,
                  label: '${flight.airlineName} Flight ${flight.flightNumber} (${flight.departureIata} → ${flight.arrivalIata})',
                  date: flight.departureDate,
                ));

                ref.read(userProfileProvider.notifier).addXP(250);

                Navigator.pop(ctx);
                setState(() {
                  _bookedSuccess = true;
                });
              },
              child: const Text('Confirm Book', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl, bool isDark, {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: TriaColors.textSecondary(isDark))),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            style: TextStyle(fontSize: 13, color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: TriaColors.scaffoldBg(isDark),
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: TriaColors.border(isDark)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF2563EB)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: TriaColors.textSecondary(isDark))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: TriaColors.scaffoldBg(isDark),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: TriaColors.border(isDark)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: TriaColors.dialogBg(isDark),
              style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 13, fontWeight: FontWeight.bold),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: TextStyle(color: TriaColors.textPrimary(isDark))),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkProvider);

    return Scaffold(
      backgroundColor: TriaColors.scaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: TriaColors.cardBg(isDark),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: TriaColors.textPrimary(isDark)),
        title: Text(
          'Flight procurement',
          style: TextStyle(
            color: TriaColors.textPrimary(isDark),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: Column(
        children: [
          // Premium Search Panel
          Container(
            padding: const EdgeInsets.all(16),
            color: TriaColors.cardBg(isDark),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search Flight (e.g. NH820, SQ12)',
                      hintStyle: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 12),
                      isDense: true,
                      filled: true,
                      fillColor: TriaColors.scaffoldBg(isDark),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB), size: 18),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: TriaColors.border(isDark)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
                      ),
                    ),
                    onSubmitted: (val) => _searchFlights(val),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onPressed: () => _searchFlights(_searchController.text),
                  child: const Text('Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Main Results Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_bookedSuccess) ...[
                    // Success card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: TriaColors.cardBg(isDark),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: TriaColors.scaffoldBg(isDark),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.green, size: 32),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'FLIGHT BOOKED SECURELY',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: TriaColors.textPrimary(isDark),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your flight has been ticketed and logged into your dashboard timeline. +250 XP earned.',
                            style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                            onPressed: () {
                              setState(() {
                                _bookedSuccess = false;
                              });
                            },
                            child: const Text('Search More Flights', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                        ),
                      )
                    else if (_error != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                          child: Text(
                            'Error: $_error',
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                      )
                    else if (_apiFlights.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                          child: Text(
                            'No flights found. Enter a flight number like NH820 to search.',
                            style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 12),
                          ),
                        ),
                      )
                    else ...[
                      Text(
                        'SEARCHED FLIGHT OPTIONS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._apiFlights.map((flight) {
                        final price = 450.0 + (flight.flightNumber.hashCode.abs() % 350);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: TriaColors.cardBg(isDark),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: TriaColors.border(isDark)),
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
                                      color: TriaColors.scaffoldBg(isDark),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: TriaColors.border(isDark)),
                                    ),
                                    child: Text(
                                      flight.flightStatus.toUpperCase(),
                                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                    ),
                                  ),
                                  Text(
                                    '\$${price.toInt()}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.flight_takeoff, color: TriaColors.textMuted(isDark), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${flight.airlineName} • ${flight.flightNumber}',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: TriaColors.textPrimary(isDark)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${flight.departureCity} (${flight.departureIata}) → ${flight.arrivalCity} (${flight.arrivalIata})',
                                          style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Dept: ${flight.departureDate} at ${flight.departureTime} | Arr: ${flight.arrivalDate} at ${flight.arrivalTime}',
                                          style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Divider(height: 24, color: TriaColors.border(isDark)),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: Colors.orangeAccent, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Terminal: Dep: ${flight.departureAirport} | Arr: ${flight.arrivalAirport}',
                                      style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => _showBookingDialog(flight),
                                  child: const Text(
                                    'Procure & Book Flight',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

