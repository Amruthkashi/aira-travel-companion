import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/theme_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/travel_providers.dart';
import '../core/models/travel_models.dart';
import '../core/models/aviation_flight.dart';
import '../core/services/aviationstack_service.dart';
import '../core/widgets/hotel_search_field.dart';


const List<String> _popularAirlines = [
  'ANA (All Nippon Airways)',
  'Japan Airlines (JAL)',
  'Singapore Airlines',
  'Emirates',
  'Qatar Airways',
  'Delta Air Lines',
  'United Airlines',
  'American Airlines',
  'Lufthansa',
  'Air France',
  'British Airways',
  'Cathay Pacific',
  'Qantas',
  'Air India',
  'Skyline Airlines Tokyo',
  'Indigo',
  'AirAsia',
  'Korean Air',
  'Etihad Airways',
];

FlightBooking parseFlightExpense(TravelExpense expense) {
  String airline = 'Unknown Airline';
  String flightNum = '';
  String depTime = '12:00 PM';
  String arrTime = '04:00 PM';
  
  final regex = RegExp(r'^(.*?)\s+Flight\s+(.*?)\s*\((.*?)\)$', caseSensitive: false);
  final match = regex.firstMatch(expense.label);
  if (match != null) {
    airline = match.group(1)?.trim() ?? airline;
    flightNum = match.group(2)?.trim() ?? '';
    final times = match.group(3)?.split('-') ?? [];
    if (times.length == 2) {
      depTime = times[0].trim();
      arrTime = times[1].trim();
    }
  } else {
    if (expense.label.contains('Flight')) {
      final parts = expense.label.split('Flight');
      airline = parts[0].trim();
      flightNum = parts[1].split('(')[0].trim();
    } else {
      airline = expense.label;
    }
  }
  
  return FlightBooking(
    id: 'flt-imported-${expense.id}',
    airline: airline,
    flightNumber: flightNum,
    pnr: 'IMP-PNR',
    departureCity: 'Bangalore',
    arrivalCity: 'Tokyo',
    departureDate: expense.date.contains('Day') ? '2026-06-19' : expense.date,
    arrivalDate: expense.date.contains('Day') ? '2026-06-19' : expense.date,
    departureTime: depTime,
    arrivalTime: arrTime,
  );
}

HotelBooking parseHotelExpense(TravelExpense expense) {
  String hotelName = expense.label;
  int nights = 1;
  
  final regex = RegExp(r'^(.*?)\s+Stay\s*\((\d+)\s*Nights?\)$', caseSensitive: false);
  final match = regex.firstMatch(expense.label);
  if (match != null) {
    hotelName = match.group(1)?.trim() ?? hotelName;
    nights = int.tryParse(match.group(2) ?? '1') ?? 1;
  } else {
    if (hotelName.toLowerCase().endsWith(' stay')) {
      hotelName = hotelName.substring(0, hotelName.length - 5).trim();
    }
  }
  
  final checkIn = expense.date.contains('Day') ? '2026-06-19' : expense.date;
  String checkOut = checkIn;
  try {
    final dt = DateTime.parse(checkIn);
    final dtOut = dt.add(Duration(days: nights));
    checkOut = '${dtOut.year}-${dtOut.month.toString().padLeft(2, '0')}-${dtOut.day.toString().padLeft(2, '0')}';
  } catch (_) {}

  return HotelBooking(
    id: 'htl-imported-${expense.id}',
    hotelName: hotelName,
    address: 'Tokyo Center',
    checkInDate: checkIn,
    checkOutDate: checkOut,
    roomType: 'Standard Room',
    guests: 1,
    confirmationCode: 'IMP-HTL',
  );
}

class BookingUploadScreen extends ConsumerStatefulWidget {
  const BookingUploadScreen({super.key});

  @override
  ConsumerState<BookingUploadScreen> createState() => _BookingUploadScreenState();
}

class _BookingUploadScreenState extends ConsumerState<BookingUploadScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showFlightModal() {
    final isDark = ref.read(isDarkProvider);
    final aviationService = AviationstackService();
    final flightSearchCtrl = TextEditingController();
    final flightSearchDateCtrl = TextEditingController(
      text: ref.read(tripBookingsProvider).startDate ?? DateTime.now().toString().split(' ')[0],
    );
    final flightNumCtrl = TextEditingController();
    final pnrCtrl = TextEditingController();
    final depCityCtrl = TextEditingController();
    final arrCityCtrl = TextEditingController();
    final depDateCtrl = TextEditingController();
    final arrDateCtrl = TextEditingController();
    final depTimeCtrl = TextEditingController(text: '12:00 PM');
    final arrTimeCtrl = TextEditingController(text: '04:00 PM');
    String seatClass = 'Economy';
    String flightType = 'going';
    final passCtrl = TextEditingController(text: '1');

    final List<String> airlinesList = List.from(_popularAirlines);
    String selectedAirline = airlinesList.first;

    List<AviationFlight> flightSuggestions = [];
    bool isFlightLoading = false;
    String? flightError;
    bool hasFlightSearched = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TriaColors.scaffoldBg(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _modalHandle(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.2 : 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.flight, color: Color(0xFF60A5FA), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text('ADD FLIGHT BOOKING',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: TriaColors.textPrimary(isDark), letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Search Flight Number section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _modalField('Search Flight Number', flightSearchCtrl, 'e.g. SQ322 or LH123'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _datePicker('Flight Date', flightSearchDateCtrl, ctx),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              onPressed: isFlightLoading
                                  ? null
                                  : () async {
                                      final number = flightSearchCtrl.text.trim();
                                      if (number.length < 2) return;
                                      setModalState(() {
                                        isFlightLoading = true;
                                        flightError = null;
                                        hasFlightSearched = true;
                                        flightSuggestions = [];
                                      });
                                      try {
                                        final results = await aviationService.searchFlights(number);
                                        // Shift dates of results to match target flightSearchDateCtrl
                                        final targetDate = flightSearchDateCtrl.text;
                                        final adjustedResults = results.map((f) {
                                          try {
                                            final target = DateTime.parse(targetDate);
                                            final origDep = DateTime.parse(f.departureDate);
                                            final origArr = DateTime.parse(f.arrivalDate);
                                            final diffDays = target.difference(origDep).inDays;
                                            final newDep = origDep.add(Duration(days: diffDays));
                                            final newArr = origArr.add(Duration(days: diffDays));
                                            return AviationFlight(
                                              flightNumber: f.flightNumber,
                                              airlineName: f.airlineName,
                                              flightStatus: f.flightStatus,
                                              departureCity: f.departureCity,
                                              arrivalCity: f.arrivalCity,
                                              departureAirport: f.departureAirport,
                                              departureIata: f.departureIata,
                                              arrivalAirport: f.arrivalAirport,
                                              arrivalIata: f.arrivalIata,
                                              departureTime: f.departureTime,
                                              departureDate: '${newDep.year}-${newDep.month.toString().padLeft(2, '0')}-${newDep.day.toString().padLeft(2, '0')}',
                                              arrivalTime: f.arrivalTime,
                                              arrivalDate: '${newArr.year}-${newArr.month.toString().padLeft(2, '0')}-${newArr.day.toString().padLeft(2, '0')}',
                                            );
                                          } catch (_) {
                                            return f;
                                          }
                                        }).toList();

                                        setModalState(() {
                                          flightSuggestions = adjustedResults;
                                          isFlightLoading = false;
                                        });
                                      } catch (err) {
                                        setModalState(() {
                                          isFlightLoading = false;
                                          flightError = err.toString();
                                        });
                                      }
                                    },
                              child: isFlightLoading
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.search, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (flightError != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.1 : 0.05),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.3 : 0.15)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                flightError!,
                                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (!isFlightLoading && hasFlightSearched && flightSuggestions.isEmpty && flightError == null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: TriaColors.cardBg(isDark),
                          border: Border.all(color: TriaColors.border(isDark)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_off, color: TriaColors.textSecondary(isDark), size: 16),
                            const SizedBox(width: 8),
                            Text('No active/scheduled flights found.', style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 11)),
                          ],
                        ),
                      ),
                    ],

                    if (flightSuggestions.isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: TriaColors.cardBg(isDark),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: TriaColors.border(isDark)),
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: flightSuggestions.length,
                            separatorBuilder: (context, index) => Divider(height: 1, color: TriaColors.border(isDark)),
                            itemBuilder: (context, index) {
                              final flt = flightSuggestions[index];
                              return Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.flight_takeoff, color: Color(0xFF60A5FA), size: 16),
                                  title: Text(
                                    '${flt.flightNumber} • ${flt.airlineName}',
                                    style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  subtitle: Text(
                                    'Date: ${flt.departureDate}  |  ${flt.departureIata} → ${flt.arrivalIata}  |  ${flt.flightStatus.toUpperCase()}',
                                    style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 10),
                                  ),
                                  onTap: () {
                                    setModalState(() {
                                      if (!airlinesList.contains(flt.airlineName)) {
                                        airlinesList.add(flt.airlineName);
                                      }
                                      selectedAirline = flt.airlineName;
                                      flightNumCtrl.text = flt.flightNumber;
                                      depCityCtrl.text = flt.departureCity;
                                      arrCityCtrl.text = flt.arrivalCity;
                                      depDateCtrl.text = flt.departureDate;
                                      arrDateCtrl.text = flt.arrivalDate;
                                      depTimeCtrl.text = flt.departureTime;
                                      arrTimeCtrl.text = flt.arrivalTime;
  
                                      // Clear results
                                      flightSuggestions = [];
                                      hasFlightSearched = false;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AIRLINE NAME', style: TextStyle(color: TriaColors.textSecondary(isDark), fontWeight: FontWeight.bold, fontSize: 9.5, letterSpacing: 0.5)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: TriaColors.cardBg(isDark),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: TriaColors.border(isDark)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedAirline,
                              dropdownColor: TriaColors.cardBg(isDark),
                              isExpanded: true,
                              style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 12.5),
                              items: airlinesList
                                  .map((a) => DropdownMenuItem(value: a, child: Text(a, style: TextStyle(color: TriaColors.textPrimary(isDark)))))
                                  .toList(),
                              onChanged: (v) => setModalState(() => selectedAirline = v!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                    Row(children: [
                      Expanded(child: _modalField('Flight Number', flightNumCtrl, 'e.g. SQ322')),
                      const SizedBox(width: 12),
                      Expanded(child: _modalField('PNR Code', pnrCtrl, 'e.g. ABC123')),
                    ]),
                    Row(children: [
                      Expanded(child: _modalField('Departure City', depCityCtrl, 'e.g. Bangalore')),
                      const SizedBox(width: 12),
                      Expanded(child: _modalField('Arrival City', arrCityCtrl, 'e.g. Tokyo')),
                    ]),
                    Row(children: [
                      Expanded(child: _datePicker('Departure Date', depDateCtrl, ctx)),
                      const SizedBox(width: 12),
                      Expanded(child: _datePicker('Arrival Date', arrDateCtrl, ctx)),
                    ]),
                    Row(children: [
                      Expanded(child: _timePicker('Dep. Time', depTimeCtrl, ctx)),
                      const SizedBox(width: 12),
                      Expanded(child: _timePicker('Arr. Time', arrTimeCtrl, ctx)),
                    ]),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FLIGHT DIRECTION / TYPE', style: TextStyle(color: TriaColors.textSecondary(isDark), fontWeight: FontWeight.bold, fontSize: 9.5, letterSpacing: 0.5)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: TriaColors.cardBg(isDark),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: TriaColors.border(isDark)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: flightType,
                              dropdownColor: TriaColors.cardBg(isDark),
                              isExpanded: true,
                              style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 12.5),
                              items: [
                                DropdownMenuItem(value: 'going', child: Text('🛫 Going Flight (Outbound)', style: TextStyle(color: TriaColors.textPrimary(isDark)))),
                                DropdownMenuItem(value: 'return', child: Text('🛬 Return Flight (Inbound)', style: TextStyle(color: TriaColors.textPrimary(isDark)))),
                                DropdownMenuItem(value: 'other', child: Text('✈️ Internal / Other Flight', style: TextStyle(color: TriaColors.textPrimary(isDark)))),
                              ],
                              onChanged: (v) => setModalState(() => flightType = v!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                    Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CLASS', style: TextStyle(color: TriaColors.textSecondary(isDark), fontWeight: FontWeight.bold, fontSize: 9.5, letterSpacing: 0.5)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: TriaColors.cardBg(isDark),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: TriaColors.border(isDark)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: seatClass,
                                  dropdownColor: TriaColors.cardBg(isDark),
                                  isExpanded: true,
                                  style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 12.5),
                                  items: ['Economy', 'Premium Economy', 'Business', 'First']
                                      .map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: TriaColors.textPrimary(isDark)))))
                                      .toList(),
                                  onChanged: (v) => setModalState(() => seatClass = v!),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _modalField('Passengers', passCtrl, '1', isNumeric: true)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: TriaColors.border(isDark)),
                            foregroundColor: TriaColors.textSecondary(isDark),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            aviationService.dispose();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            if (selectedAirline.isNotEmpty && depCityCtrl.text.isNotEmpty) {
                              ref.read(tripBookingsProvider.notifier).addFlight(FlightBooking(
                                id: 'flt-${DateTime.now().millisecondsSinceEpoch}',
                                airline: selectedAirline,
                                flightNumber: flightNumCtrl.text,
                                pnr: pnrCtrl.text,
                                departureCity: depCityCtrl.text,
                                arrivalCity: arrCityCtrl.text,
                                departureDate: depDateCtrl.text,
                                arrivalDate: arrDateCtrl.text,
                                departureTime: depTimeCtrl.text,
                                arrivalTime: arrTimeCtrl.text,
                                seatClass: seatClass,
                                passengers: int.tryParse(passCtrl.text) ?? 1,
                                flightType: flightType,
                              ));
                              if (flightType != 'return' && arrCityCtrl.text.isNotEmpty) {
                                ref.read(tripBookingsProvider.notifier).setDestination(arrCityCtrl.text);
                              }
                              aviationService.dispose();
                              Navigator.pop(ctx);
                            }
                          },
                          child: const Text('Add Flight', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPnrImportModal() {
    final isDark = ref.read(isDarkProvider);
    final pnrCtrl = TextEditingController();
    bool isPnrLoading = false;
    String? pnrError;
    Map<String, dynamic>? foundFlight;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TriaColors.scaffoldBg(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _modalHandle(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.cloud_download, color: Color(0xFF34D399), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text('IMPORT FLIGHT VIA PNR',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: TriaColors.textPrimary(isDark), letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _modalField('Enter PNR Code', pnrCtrl, 'e.g. XX24X4 or HHE333'),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              onPressed: isPnrLoading
                                  ? null
                                  : () async {
                                      final code = pnrCtrl.text.trim().toUpperCase();
                                      if (code.isEmpty) return;
                                      setModalState(() {
                                        isPnrLoading = true;
                                        pnrError = null;
                                        foundFlight = null;
                                      });
                                      try {
                                        final response = await http.get(Uri.parse('https://6a4236f27602860e652113bd.mockapi.io/api/v1/Flights'))
                                            .timeout(const Duration(seconds: 8));
                                        if (response.statusCode >= 200 && response.statusCode < 300) {
                                          final List<dynamic> data = jsonDecode(response.body);
                                          final match = data.firstWhere(
                                            (item) => item['pnr']?.toString().toUpperCase() == code,
                                            orElse: () => null,
                                          );
                                          if (match != null) {
                                            setModalState(() {
                                              foundFlight = match;
                                            });
                                          } else {
                                            setModalState(() {
                                              pnrError = 'No booking found matching PNR "$code".';
                                            });
                                          }
                                        } else {
                                          setModalState(() {
                                            pnrError = 'Failed to fetch flight list (${response.statusCode}).';
                                          });
                                        }
                                      } catch (err) {
                                        setModalState(() {
                                          pnrError = 'Network error or timeout. Please check connection.';
                                        });
                                      } finally {
                                        setModalState(() {
                                          isPnrLoading = false;
                                        });
                                      }
                                    },
                              child: isPnrLoading
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.search, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (pnrError != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.1 : 0.05),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.3 : 0.15)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                pnrError!,
                                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (foundFlight != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: TriaColors.cardBg(isDark),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: TriaColors.border(isDark)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${foundFlight!['airline']} • ${foundFlight!['flight_number']}',
                                  style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (foundFlight!['status'] == 'Confirmed')
                                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                        : const Color(0xFFEF4444).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    foundFlight!['status'] ?? 'Unknown',
                                    style: TextStyle(
                                      color: (foundFlight!['status'] == 'Confirmed')
                                          ? const Color(0xFF34D399)
                                          : const Color(0xFFF87171),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow('Passenger', foundFlight!['passenger_name'] ?? 'N/A'),
                            _buildInfoRow('PNR Code', foundFlight!['pnr'] ?? 'N/A'),
                            _buildInfoRow('Cabin Class', foundFlight!['class'] ?? 'N/A'),
                            _buildInfoRow('Seat Number', foundFlight!['seat'] ?? 'N/A'),
                            _buildInfoRow('Duration', foundFlight!['duration'] ?? 'N/A'),
                            _buildInfoRow('Meal Pref.', foundFlight!['meal_preference'] ?? 'N/A'),
                            _buildInfoRow('Baggage', foundFlight!['baggage_allowance'] ?? 'N/A'),
                            Divider(color: TriaColors.border(isDark), height: 24),
                            Text(
                              'ITINERARY LEGS',
                              style: TextStyle(color: TriaColors.textSecondary(isDark), fontWeight: FontWeight.bold, fontSize: 9.5, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 8),
                            ...((foundFlight!['itinerary'] as List? ?? []).map((leg) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.circle, size: 6, color: Color(0xFF60A5FA)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Leg ${leg['leg']}: ${leg['flight']} (${leg['from']} → ${leg['to']}) at ${leg['dep']} - ${leg['arr']}',
                                        style: TextStyle(color: TriaColors.textPrimary(isDark).withValues(alpha: 0.8), fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: TriaColors.border(isDark)),
                                foregroundColor: TriaColors.textSecondary(isDark),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () {
                                final flight = foundFlight!;
                                final itineraryLegs = flight['itinerary'] as List? ?? [];
                                if (itineraryLegs.isNotEmpty) {
                                  // Parse main flight date
                                  String flightDate = '';
                                  try {
                                    final depRaw = flight['departure']?.toString() ?? '';
                                    if (depRaw.contains(' ')) {
                                      flightDate = depRaw.split(' ')[0];
                                    } else {
                                      flightDate = depRaw;
                                    }
                                    DateTime.parse(flightDate);
                                  } catch (_) {
                                    flightDate = DateTime.now().toString().split(' ')[0];
                                  }

                                  // Determine if the entire PNR is a going or return journey
                                  String determinedType = 'going';
                                  bool isRoundTrip = false;
                                  if (itineraryLegs.isNotEmpty) {
                                    final firstLeg = itineraryLegs.first;
                                    final lastLeg = itineraryLegs.last;
                                    final pnrStartCity = firstLeg['from']?.toString().trim().toLowerCase() ?? '';
                                    final pnrEndCity = lastLeg['to']?.toString().trim().toLowerCase() ?? '';
                                    final currentDest = ref.read(tripBookingsProvider).destination.trim().toLowerCase();
                                    
                                    if (pnrStartCity.isNotEmpty && pnrEndCity.isNotEmpty && pnrStartCity == pnrEndCity) {
                                      isRoundTrip = true;
                                    } else {
                                      if (currentDest.isNotEmpty) {
                                        if (pnrEndCity.contains(currentDest) || currentDest.contains(pnrEndCity)) {
                                          determinedType = 'going';
                                        } else if (pnrStartCity.contains(currentDest) || currentDest.contains(pnrStartCity)) {
                                          determinedType = 'return';
                                        } else {
                                          final hasGoing = ref.read(tripBookingsProvider).flights.any((f) => f.flightType == 'going');
                                          determinedType = hasGoing ? 'return' : 'going';
                                        }
                                      } else {
                                        final hasGoing = ref.read(tripBookingsProvider).flights.any((f) => f.flightType == 'going');
                                        determinedType = hasGoing ? 'return' : 'going';
                                      }
                                    }
                                  }

                                  for (int i = 0; i < itineraryLegs.length; i++) {
                                    final leg = itineraryLegs[i];
                                    final legNo = leg['leg']?.toString() ?? (i + 1).toString();
                                    
                                    // Map direction
                                    String directionType = determinedType;
                                    if (isRoundTrip) {
                                      if (i == 0) {
                                        directionType = 'going';
                                      } else if (i == itineraryLegs.length - 1) {
                                        directionType = 'return';
                                      } else {
                                        directionType = 'other';
                                      }
                                    }

                                    ref.read(tripBookingsProvider.notifier).addFlight(FlightBooking(
                                      id: 'flt-pnr-$legNo-${flight['pnr']}-${DateTime.now().millisecondsSinceEpoch}',
                                      airline: flight['airline'] ?? 'Unknown Airline',
                                      flightNumber: leg['flight'] ?? flight['flight_number'] ?? '',
                                      pnr: flight['pnr'] ?? '',
                                      departureCity: leg['from'] ?? '',
                                      arrivalCity: leg['to'] ?? '',
                                      departureDate: flightDate,
                                      arrivalDate: flightDate,
                                      departureTime: leg['dep'] ?? '',
                                      arrivalTime: leg['arr'] ?? '',
                                      seatClass: flight['class'] ?? 'Economy',
                                      passengers: 1,
                                      flightType: directionType,
                                    ));
                                  }

                                  // Set destination city to final arrival city of the flight
                                  final lastLeg = itineraryLegs.last;
                                  final finalCity = lastLeg['to']?.toString() ?? '';
                                  if (finalCity.isNotEmpty) {
                                    ref.read(tripBookingsProvider.notifier).setDestination(finalCity);
                                  }

                                  // Update trip dates
                                  ref.read(tripBookingsProvider.notifier).setTripDates(flightDate, flightDate);

                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Successfully imported flight for ${flight['passenger_name']}!'),
                                      backgroundColor: const Color(0xFF10B981),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Confirm & Import', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final isDark = ref.read(isDarkProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 11)),
          Text(value, style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }


  void _showHotelModal() {
    final isDark = ref.read(isDarkProvider);
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final checkInCtrl = TextEditingController();
    final checkOutCtrl = TextEditingController();
    final checkInTimeCtrl = TextEditingController(text: '03:00 PM');
    final checkOutTimeCtrl = TextEditingController(text: '11:00 AM');
    final roomCtrl = TextEditingController(text: 'Standard');
    final guestsCtrl = TextEditingController(text: '1');
    final confCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TriaColors.scaffoldBg(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _modalHandle(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withValues(alpha: isDark ? 0.2 : 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.hotel, color: Color(0xFFA78BFA), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text('ADD HOTEL BOOKING',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: TriaColors.textPrimary(isDark), letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    HotelSearchField(
                      controller: nameCtrl,
                      onHotelSelected: (hotel) {
                        setModalState(() {
                          addressCtrl.text = hotel.formattedAddress;
                        });
                      },
                    ),
                    _modalField('Address', addressCtrl, 'e.g. 3-7-1-2 Nishi Shinjuku'),
                    Row(children: [
                      Expanded(child: _datePicker('Check-in Date', checkInCtrl, ctx)),
                      const SizedBox(width: 12),
                      Expanded(child: _datePicker('Check-out Date', checkOutCtrl, ctx)),
                    ]),
                    Row(children: [
                      Expanded(child: _timePicker('Check-in Time', checkInTimeCtrl, ctx)),
                      const SizedBox(width: 12),
                      Expanded(child: _timePicker('Check-out Time', checkOutTimeCtrl, ctx)),
                    ]),
                    Row(children: [
                      Expanded(child: _modalField('Room Type', roomCtrl, 'Standard')),
                      const SizedBox(width: 12),
                      Expanded(child: _modalField('Guests', guestsCtrl, '1', isNumeric: true)),
                    ]),
                    _modalField('Confirmation Code', confCtrl, 'e.g. HTL-9847ZR'),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: TriaColors.border(isDark)),
                            foregroundColor: TriaColors.textSecondary(isDark),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            if (nameCtrl.text.isNotEmpty) {
                              ref.read(tripBookingsProvider.notifier).addHotel(HotelBooking(
                                id: 'htl-${DateTime.now().millisecondsSinceEpoch}',
                                hotelName: nameCtrl.text,
                                address: addressCtrl.text,
                                checkInDate: checkInCtrl.text,
                                checkOutDate: checkOutCtrl.text,
                                checkInTime: checkInTimeCtrl.text,
                                checkOutTime: checkOutTimeCtrl.text,
                                roomType: roomCtrl.text,
                                guests: int.tryParse(guestsCtrl.text) ?? 1,
                                confirmationCode: confCtrl.text,
                              ));
                              Navigator.pop(ctx);
                            }
                          },
                          child: const Text('Add Hotel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showOtherBookingModal() {
    final isDark = ref.read(isDarkProvider);
    final titleCtrl = TextEditingController();
    String bookingType = 'activity';
    final dateCtrl = TextEditingController();
    final confCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TriaColors.scaffoldBg(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _modalHandle(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: isDark ? 0.2 : 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.confirmation_number, color: Color(0xFF34D399), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text('ADD OTHER BOOKING',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: TriaColors.textPrimary(isDark), letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _modalField('Booking Title', titleCtrl, 'e.g. Ghibli Museum Tickets'),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BOOKING TYPE', style: TextStyle(color: TriaColors.textSecondary(isDark), fontWeight: FontWeight.bold, fontSize: 9.5, letterSpacing: 0.5)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: TriaColors.cardBg(isDark),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: TriaColors.border(isDark)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: bookingType,
                              dropdownColor: TriaColors.cardBg(isDark),
                              isExpanded: true,
                              style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 12.5),
                              items: ['activity', 'tour', 'pass', 'transport']
                                  .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t[0].toUpperCase() + t.substring(1), style: TextStyle(color: TriaColors.textPrimary(isDark))),
                                  ))
                                  .toList(),
                              onChanged: (v) => setModalState(() => bookingType = v!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                    _datePicker('Date', dateCtrl, ctx),
                    _modalField('Confirmation Code', confCtrl, 'Optional'),
                    _modalField('Notes', notesCtrl, 'Any additional details...', maxLines: 2),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: TriaColors.border(isDark)),
                            foregroundColor: TriaColors.textSecondary(isDark),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            if (titleCtrl.text.isNotEmpty) {
                              ref.read(tripBookingsProvider.notifier).addOther(OtherBooking(
                                id: 'oth-${DateTime.now().millisecondsSinceEpoch}',
                                title: titleCtrl.text,
                                type: bookingType,
                                date: dateCtrl.text,
                                confirmationCode: confCtrl.text,
                                notes: notesCtrl.text,
                              ));
                              Navigator.pop(ctx);
                            }
                          },
                          child: const Text('Add Booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _modalHandle() {
    final isDark = ref.read(isDarkProvider);
    return Center(
      child: Container(
        width: 40, height: 5,
        decoration: BoxDecoration(
          color: TriaColors.border(isDark),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _modalField(String label, TextEditingController ctrl, String hint, {int maxLines = 1, bool isNumeric = false}) {
    final isDark = ref.read(isDarkProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(color: TriaColors.textSecondary(isDark), fontWeight: FontWeight.bold, fontSize: 9.5, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 12.5),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 12),
              filled: true,
              fillColor: TriaColors.cardBg(isDark),
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: TriaColors.border(isDark)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF2563EB)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _datePicker(String label, TextEditingController ctrl, BuildContext ctx) {
    final isDark = ref.read(isDarkProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(color: TriaColors.textSecondary(isDark), fontWeight: FontWeight.bold, fontSize: 9.5, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            readOnly: true,
            onTap: () async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
                builder: (c, child) => Theme(
                  data: isDark
                      ? ThemeData.dark().copyWith(
                          appBarTheme: const AppBarTheme(
                            backgroundColor: Color(0xFF1A2744),
                            foregroundColor: Colors.white,
                            iconTheme: IconThemeData(color: Colors.white),
                          ),
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF2563EB),
                            onPrimary: Colors.white,
                            surface: Color(0xFF1A2744),
                            onSurface: Colors.white,
                            secondary: Color(0xFF00B4D8),
                          ),
                          dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF0A1628),),
                          datePickerTheme: DatePickerThemeData(
                            backgroundColor: const Color(0xFF0A1628),
                            headerBackgroundColor: const Color(0xFF1A2744),
                            headerForegroundColor: Colors.white,
                            rangePickerHeaderBackgroundColor: const Color(0xFF1A2744),
                            rangePickerHeaderForegroundColor: Colors.white,
                            confirmButtonStyle: ButtonStyle(
                              foregroundColor: WidgetStateProperty.all(const Color(0xFF60A5FA)),
                              textStyle: WidgetStateProperty.all(const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            cancelButtonStyle: ButtonStyle(
                              foregroundColor: WidgetStateProperty.all(const Color(0xFF94A3B8)),
                              textStyle: WidgetStateProperty.all(const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF60A5FA),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      : ThemeData.light().copyWith(
                          appBarTheme: const AppBarTheme(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF0A1628),
                            iconTheme: IconThemeData(color: Color(0xFF0A1628)),
                          ),
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF2563EB),
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: Color(0xFF0A1628),
                            secondary: Color(0xFF2563EB),
                          ),
                          dialogTheme: DialogThemeData(backgroundColor: Colors.white,),
                          datePickerTheme: DatePickerThemeData(
                            backgroundColor: Colors.white,
                            headerBackgroundColor: const Color(0xFF2563EB),
                            headerForegroundColor: Colors.white,
                            confirmButtonStyle: ButtonStyle(
                              foregroundColor: WidgetStateProperty.all(const Color(0xFF2563EB)),
                              textStyle: WidgetStateProperty.all(const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            cancelButtonStyle: ButtonStyle(
                              foregroundColor: WidgetStateProperty.all(const Color(0xFF64748B)),
                              textStyle: WidgetStateProperty.all(const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF2563EB),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                  child: child!,
                ),
              );
              if (picked != null) {
                ctrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
              }
            },
            style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 12.5),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Select date',
              hintStyle: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 12),
              suffixIcon: const Icon(Icons.calendar_month, color: Color(0xFF2563EB), size: 16),
              filled: true,
              fillColor: TriaColors.cardBg(isDark),
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: TriaColors.border(isDark)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF2563EB)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timePicker(String label, TextEditingController ctrl, BuildContext ctx) {
    final isDark = ref.read(isDarkProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(color: TriaColors.textSecondary(isDark), fontWeight: FontWeight.bold, fontSize: 9.5, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            readOnly: true,
            onTap: () async {
              TimeOfDay initialTime = const TimeOfDay(hour: 12, minute: 0);
              if (ctrl.text.isNotEmpty) {
                try {
                  final minutes = parseTimeToMinutes(ctrl.text);
                  initialTime = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
                } catch (_) {}
              }
              final picked = await showTimePicker(
                context: ctx,
                initialTime: initialTime,
                builder: (c, child) => Theme(
                  data: isDark
                      ? ThemeData.dark().copyWith(
                          appBarTheme: const AppBarTheme(
                            backgroundColor: Color(0xFF1A2744),
                            foregroundColor: Colors.white,
                            iconTheme: IconThemeData(color: Colors.white),
                          ),
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF2563EB),
                            onPrimary: Colors.white,
                            surface: Color(0xFF1A2744),
                            onSurface: Colors.white,
                            secondary: Color(0xFF00B4D8),
                          ),
                          dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF0A1628),),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF60A5FA),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      : ThemeData.light().copyWith(
                          appBarTheme: const AppBarTheme(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF0A1628),
                            iconTheme: IconThemeData(color: Color(0xFF0A1628)),
                          ),
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF2563EB),
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: Color(0xFF0A1628),
                            secondary: Color(0xFF2563EB),
                          ),
                          dialogTheme: DialogThemeData(backgroundColor: Colors.white,),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF2563EB),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                  child: child!,
                ),
              );
              if (picked != null) {
                final totalMinutes = picked.hour * 60 + picked.minute;
                ctrl.text = minutesToTimeString(totalMinutes);
              }
            },
            style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 12.5),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Select time',
              hintStyle: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 12),
              suffixIcon: const Icon(Icons.access_time, color: Color(0xFF2563EB), size: 16),
              filled: true,
              fillColor: TriaColors.cardBg(isDark),
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: TriaColors.border(isDark)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF2563EB)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelectorCard(TripBookings bookings) {
    final isDark = ref.read(isDarkProvider);
    final hasDates = bookings.startDate != null &&
        bookings.endDate != null &&
        bookings.startDate!.isNotEmpty &&
        bookings.endDate!.isNotEmpty;

    String dateText = 'No dates selected';
    if (hasDates) {
      try {
        final start = DateTime.parse(bookings.startDate!);
        final end = DateTime.parse(bookings.endDate!);
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        dateText = '${months[start.month - 1]} ${start.day}, ${start.year} - ${months[end.month - 1]} ${end.day}, ${end.year}';
      } catch (_) {
        dateText = '${bookings.startDate} - ${bookings.endDate}';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TriaColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasDates ? const Color(0xFF00B4D8).withValues(alpha: 0.4) : TriaColors.border(isDark),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month,
                color: hasDates ? const Color(0xFF00B4D8) : TriaColors.textSecondary(isDark),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'TRIP DATES',
                style: TextStyle(
                  color: TriaColors.textPrimary(isDark),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (hasDates)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B4D8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${bookings.tripDays} Days',
                    style: const TextStyle(
                      color: Color(0xFF00B4D8),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  hasDates ? dateText : 'Set dates to customize itinerary length',
                  style: TextStyle(
                    color: hasDates ? TriaColors.textPrimary(isDark) : TriaColors.textSecondary(isDark),
                    fontWeight: hasDates ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasDates ? TriaColors.border(isDark) : const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final initialRange = hasDates
                      ? DateTimeRange(
                          start: DateTime.parse(bookings.startDate!),
                          end: DateTime.parse(bookings.endDate!),
                        )
                      : null;
                  
                  final picked = await showDateRangePicker(
                    context: context,
                    initialDateRange: initialRange,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    builder: (context, child) {
                      return Theme(
                        data: isDark
                            ? ThemeData.dark().copyWith(
                                appBarTheme: const AppBarTheme(
                                  backgroundColor: Color(0xFF1A2744),
                                  foregroundColor: Colors.white,
                                  iconTheme: IconThemeData(color: Colors.white),
                                ),
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFF2563EB),
                                  onPrimary: Colors.white,
                                  surface: Color(0xFF1A2744),
                                  onSurface: Colors.white,
                                  secondary: Color(0xFF00B4D8),
                                ),
                                dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF0A1628),),
                                datePickerTheme: DatePickerThemeData(
                                  backgroundColor: const Color(0xFF0A1628),
                                  headerBackgroundColor: const Color(0xFF1A2744),
                                  headerForegroundColor: Colors.white,
                                  rangePickerHeaderBackgroundColor: const Color(0xFF1A2744),
                                  rangePickerHeaderForegroundColor: Colors.white,
                                  confirmButtonStyle: ButtonStyle(
                                    foregroundColor: WidgetStateProperty.all(const Color(0xFF60A5FA)),
                                    textStyle: WidgetStateProperty.all(const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  cancelButtonStyle: ButtonStyle(
                                    foregroundColor: WidgetStateProperty.all(const Color(0xFF94A3B8)),
                                    textStyle: WidgetStateProperty.all(const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF60A5FA),
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )
                            : ThemeData.light().copyWith(
                                appBarTheme: const AppBarTheme(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Color(0xFF0A1628),
                                  iconTheme: IconThemeData(color: Color(0xFF0A1628)),
                                ),
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF2563EB),
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Color(0xFF0A1628),
                                  secondary: Color(0xFF2563EB),
                                ),
                                dialogTheme: DialogThemeData(backgroundColor: Colors.white,),
                                datePickerTheme: DatePickerThemeData(
                                  backgroundColor: Colors.white,
                                  headerBackgroundColor: const Color(0xFF2563EB),
                                  headerForegroundColor: Colors.white,
                                  rangePickerHeaderBackgroundColor: const Color(0xFF2563EB),
                                  rangePickerHeaderForegroundColor: Colors.white,
                                  confirmButtonStyle: ButtonStyle(
                                    foregroundColor: WidgetStateProperty.all(const Color(0xFF2563EB)),
                                    textStyle: WidgetStateProperty.all(const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  cancelButtonStyle: ButtonStyle(
                                    foregroundColor: WidgetStateProperty.all(const Color(0xFF64748B)),
                                    textStyle: WidgetStateProperty.all(const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF2563EB),
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                        child: child!,
                      );
                    },
                  );

                  if (picked != null) {
                    final startStr = '${picked.start.year}-${picked.start.month.toString().padLeft(2, '0')}-${picked.start.day.toString().padLeft(2, '0')}';
                    final endStr = '${picked.end.year}-${picked.end.month.toString().padLeft(2, '0')}-${picked.end.day.toString().padLeft(2, '0')}';
                    ref.read(tripBookingsProvider.notifier).setTripDates(startStr, endStr);
                  }
                },
                child: Text(
                  hasDates ? 'Change' : 'Select Dates',
                  style: TextStyle(
                    color: hasDates ? TriaColors.textPrimary(isDark) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showImportModal(List<TravelExpense> flights, List<TravelExpense> hotels) {
    final isDark = ref.read(isDarkProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TriaColors.scaffoldBg(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _modalHandle(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.download, color: Color(0xFF34D399), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('IMPORT APP BOOKINGS',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: TriaColors.textPrimary(isDark), letterSpacing: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Import flights and hotels you already reserved in the app\'s booking sections directly into this itinerary wizard.',
                  style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 11, height: 1.3),
                ),
                const SizedBox(height: 20),
                if (flights.isNotEmpty) ...[
                  Text('AVAILABLE FLIGHTS', style: TextStyle(color: TriaColors.textSecondary(isDark), fontWeight: FontWeight.bold, fontSize: 9.5, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  ...flights.map((f) => _buildImportExpenseRow(f, true, ctx)),
                  const SizedBox(height: 16),
                ],
                if (hotels.isNotEmpty) ...[
                  Text('AVAILABLE HOTEL RESERVATIONS', style: TextStyle(color: TriaColors.textSecondary(isDark), fontWeight: FontWeight.bold, fontSize: 9.5, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  ...hotels.map((h) => _buildImportExpenseRow(h, false, ctx)),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      for (var f in flights) {
                        ref.read(tripBookingsProvider.notifier).addFlight(parseFlightExpense(f));
                      }
                      for (var h in hotels) {
                        ref.read(tripBookingsProvider.notifier).addHotel(parseHotelExpense(h));
                      }
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All bookings imported successfully!'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    },
                    child: const Text('Import All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImportExpenseRow(TravelExpense expense, bool isFlight, BuildContext ctx) {
    final isDark = ref.read(isDarkProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: TriaColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TriaColors.border(isDark)),
      ),
      child: Row(
        children: [
          Icon(
            isFlight ? Icons.flight_takeoff : Icons.hotel,
            color: isFlight ? const Color(0xFF60A5FA) : const Color(0xFFA78BFA),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.label,
                  style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Price: \$${expense.amount.toInt()}  |  Date: ${expense.date}',
                  style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (isFlight) {
                ref.read(tripBookingsProvider.notifier).addFlight(parseFlightExpense(expense));
              } else {
                ref.read(tripBookingsProvider.notifier).addHotel(parseHotelExpense(expense));
              }
              if (isFlight) {
                final flight = parseFlightExpense(expense);
                if (flight.flightType != 'return' && flight.arrivalCity.isNotEmpty) {
                  ref.read(tripBookingsProvider.notifier).setDestination(flight.arrivalCity);
                }
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Imported "${expense.label}" successfully!'),
                  backgroundColor: const Color(0xFF2563EB),
                ),
              );
            },
            child: const Text('Import', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(tripBookingsProvider);
    final isDark = ref.watch(isDarkProvider);

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
            Text('Itinerary Wizard', style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 18)),
            const Text('STEP 1 — UPLOAD BOOKINGS', style: TextStyle(color: Color(0xFF00B4D8), fontWeight: FontWeight.w800, fontSize: 9, letterSpacing: 0.5)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.looks_one, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB), size: 14),
                const SizedBox(width: 4),
                Text('1/4', style: TextStyle(color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _stepDot(true, 'Bookings'),
                _stepLine(false),
                _stepDot(false, 'Explore'),
                _stepLine(false),
                _stepDot(false, 'Schedule'),
                _stepLine(false),
                _stepDot(false, 'Preview'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (ctx, child) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    const Color(0xFF1E3A5F).withValues(alpha: 0.8 + _pulseController.value * 0.2),
                                    const Color(0xFF0A1628),
                                  ]
                                : [
                                    const Color(0xFFDCE9F9).withValues(alpha: 0.8 + _pulseController.value * 0.2),
                                    const Color(0xFFF8FAFC),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.3 : 0.15)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.upload_file, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB), size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Upload Your Bookings',
                                    style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Add your flight tickets, hotel reservations, and any pre-booked activities to build your trip.',
                                    style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 11, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Date Range Selector
                  _buildDateSelectorCard(bookings),
                  const SizedBox(height: 16),

                  // Import App Bookings section if any exist
                  (() {
                    final expenses = ref.watch(expensesProvider);
                    final flightExpenses = expenses.where((e) => e.category == 'Flights').toList();
                    final hotelExpenses = expenses.where((e) => e.category == 'Hotels').toList();

                    final existingFlightIds = bookings.flights.map((f) => f.id).toSet();
                    final existingHotelIds = bookings.hotels.map((h) => h.id).toSet();

                    final importableFlights = flightExpenses.where((e) => !existingFlightIds.contains('flt-imported-${e.id}')).toList();
                    final importableHotels = hotelExpenses.where((e) => !existingHotelIds.contains('htl-imported-${e.id}')).toList();

                    final hasImportable = importableFlights.isNotEmpty || importableHotels.isNotEmpty;

                    if (!hasImportable) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F2D24) : const Color(0xFFE6F4EA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.4 : 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.download,
                                color: Color(0xFF34D399),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'IMPORT AVAILABLE BOOKINGS',
                                style: TextStyle(
                                  color: TriaColors.textPrimary(isDark),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${importableFlights.length + importableHotels.length} Found',
                                  style: const TextStyle(
                                    color: Color(0xFF34D399),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You have active hotel/flight bookings in the app. Import them to build your itinerary automatically.',
                            style: TextStyle(
                              color: TriaColors.textSecondary(isDark),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () => _showImportModal(importableFlights, importableHotels),
                              icon: const Icon(Icons.download, size: 16, color: Colors.white),
                              label: const Text(
                                'Review & Import Bookings',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  })(),

                  // FLIGHTS SECTION
                  _sectionHeader('Flights', Icons.flight, const Color(0xFF2563EB), bookings.flights.length),
                  const SizedBox(height: 12),
                  ...bookings.flights.map((f) => _flightCard(f)),
                  Row(
                    children: [
                      Expanded(
                        child: _addButton('Add Flight Booking', const Color(0xFF2563EB), Icons.add, _showFlightModal),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _addButton('Import via PNR', const Color(0xFF10B981), Icons.cloud_download, _showPnrImportModal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // HOTELS SECTION
                  _sectionHeader('Hotels', Icons.hotel, const Color(0xFF7C3AED), bookings.hotels.length),
                  const SizedBox(height: 12),
                  ...bookings.hotels.map((h) => _hotelCard(h)),
                  _addButton('Add Hotel Booking', const Color(0xFF7C3AED), Icons.hotel, _showHotelModal),
                  const SizedBox(height: 24),

                  // OTHER BOOKINGS
                  _sectionHeader('Other Bookings', Icons.confirmation_number, const Color(0xFF059669), bookings.others.length),
                  const SizedBox(height: 12),
                  ...bookings.others.map((o) => _otherCard(o)),
                  _addButton('Add Other Booking', const Color(0xFF059669), Icons.confirmation_number, _showOtherBookingModal),
                  const SizedBox(height: 24),

                  // Trip Summary
                  if (bookings.flights.isNotEmpty || bookings.hotels.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF1E3A5F), const Color(0xFF0F2847)]
                              : [const Color(0xFFE6F0FA), const Color(0xFFDCE9F9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.3 : 0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TRIP SUMMARY',
                            style: TextStyle(color: TriaColors.textSecondary(isDark), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _summaryChip(Icons.place, bookings.destination.isEmpty ? 'Not set' : bookings.destination, const Color(0xFF2563EB)),
                              const SizedBox(width: 10),
                              _summaryChip(Icons.calendar_today, '${bookings.tripDays} Days', const Color(0xFF7C3AED)),
                              const SizedBox(width: 10),
                              _summaryChip(Icons.receipt_long, '${bookings.flights.length + bookings.hotels.length + bookings.others.length} Bookings', const Color(0xFF059669)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (bookings.flights.isNotEmpty || bookings.hotels.isNotEmpty)
                            ? const Color(0xFF2563EB)
                            : TriaColors.border(isDark),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      onPressed: (bookings.flights.isNotEmpty || bookings.hotels.isNotEmpty)
                          ? () => context.push('/itinerary-wizard/explore')
                          : null,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('CONTINUE TO EXPLORE PLACES',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepDot(bool active, String label) {
    final isDark = ref.watch(isDarkProvider);
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
            color: active ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)) : TriaColors.textSecondary(isDark),
            fontSize: 9, fontWeight: FontWeight.bold,
          )),
        ],
      ),
    );
  }

  Widget _stepLine(bool active) {
    final isDark = ref.watch(isDarkProvider);
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: active ? const Color(0xFF2563EB) : TriaColors.border(isDark),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color, int count) {
    final isDark = ref.watch(isDarkProvider);
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title.toUpperCase(),
          style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
        ),
        const Spacer(),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count added', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
          ),
      ],
    );
  }

  Map<String, dynamic> _getRouteDetailsForFlight(FlightBooking target, List<FlightBooking> allFlights) {
    if (target.pnr.isEmpty) {
      return {
        'fromCity': target.departureCity,
        'destinationCity': target.arrivalCity,
        'layovers': <String>[],
      };
    }
    final samePnrFlights = allFlights.where((flight) => 
      flight.pnr.toLowerCase() == target.pnr.toLowerCase() && 
      flight.flightType == target.flightType
    ).toList();
    
    if (samePnrFlights.length <= 1) {
      return {
        'fromCity': target.departureCity,
        'destinationCity': target.arrivalCity,
        'layovers': <String>[],
      };
    }

    // Sort samePnrFlights by departure date & time
    samePnrFlights.sort((a, b) {
      final cmp = a.departureDate.compareTo(b.departureDate);
      if (cmp != 0) return cmp;
      return a.departureTime.compareTo(b.departureTime);
    });

    final origin = samePnrFlights.first.departureCity;
    final destination = samePnrFlights.last.arrivalCity;
    final List<String> layovers = [];
    for (int i = 0; i < samePnrFlights.length - 1; i++) {
      final arr = samePnrFlights[i].arrivalCity;
      if (arr.isNotEmpty && 
          arr.toLowerCase() != origin.toLowerCase() && 
          arr.toLowerCase() != destination.toLowerCase()) {
        layovers.add(arr);
      }
    }

    return {
      'fromCity': origin,
      'destinationCity': destination,
      'layovers': layovers,
    };
  }

  Widget _flightCard(FlightBooking f) {
    final isDark = ref.watch(isDarkProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TriaColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.3 : 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flight_takeoff, color: Color(0xFF60A5FA), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${f.airline}${f.pnr.isNotEmpty ? ' (PNR: ${f.pnr})' : ''}',
                        style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: f.flightType == 'going'
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : (f.flightType == 'return'
                                ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                                : const Color(0xFF64748B).withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: f.flightType == 'going'
                              ? const Color(0xFF10B981).withValues(alpha: 0.4)
                              : (f.flightType == 'return'
                                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.4)
                                  : const Color(0xFF64748B).withValues(alpha: 0.4)),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        f.flightType == 'going'
                            ? '🛫 Going'
                            : (f.flightType == 'return' ? '🛬 Return' : '✈️ Other'),
                        style: TextStyle(
                          color: f.flightType == 'going'
                              ? const Color(0xFF34D399)
                              : (f.flightType == 'return' ? const Color(0xFFA78BFA) : const Color(0xFF94A3B8)),
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final bookings = ref.read(tripBookingsProvider);
                  final routeDetails = _getRouteDetailsForFlight(f, bookings.flights);
                  context.push('/flight-map', extra: routeDetails);
                },
                child: const Icon(Icons.map, color: Color(0xFF00B4D8), size: 16),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => ref.read(tripBookingsProvider.notifier).removeFlight(f.id),
                child: const Icon(Icons.close, color: Color(0xFFEF4444), size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.departureCity, style: TextStyle(color: TriaColors.textPrimary(isDark).withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(f.departureDate, style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 10)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: TriaColors.textMuted(isDark), size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(f.arrivalCity, style: TextStyle(color: TriaColors.textPrimary(isDark).withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(f.arrivalDate, style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          if (f.pnr.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.1 : 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('PNR: ${f.pnr}  |  ${f.seatClass}  |  ${f.passengers} pax',
                style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _hotelCard(HotelBooking h) {
    final isDark = ref.watch(isDarkProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TriaColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: isDark ? 0.3 : 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hotel, color: Color(0xFFA78BFA), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(h.hotelName,
                  style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              GestureDetector(
                onTap: () => ref.read(tripBookingsProvider.notifier).removeHotel(h.id),
                child: const Icon(Icons.close, color: Color(0xFFEF4444), size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${h.checkInDate} → ${h.checkOutDate}',
            style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 11, fontWeight: FontWeight.bold),
          ),
          if (h.confirmationCode.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Confirmation: ${h.confirmationCode}  |  ${h.roomType}  |  ${h.guests} guests',
              style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  Widget _otherCard(OtherBooking o) {
    final isDark = ref.watch(isDarkProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TriaColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF059669).withValues(alpha: isDark ? 0.3 : 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.confirmation_number, color: Color(0xFF34D399), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.title, style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 13)),
                Text('${o.type.toUpperCase()}${o.date.isNotEmpty ? '  •  ${o.date}' : ''}',
                  style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(tripBookingsProvider.notifier).removeOther(o.id),
            child: const Icon(Icons.close, color: Color(0xFFEF4444), size: 16),
          ),
        ],
      ),
    );
  }

  Widget _addButton(String label, Color color, IconData icon, VoidCallback onTap) {
    final isDark = ref.read(isDarkProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color.withValues(alpha: isDark ? 0.4 : 0.2)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            foregroundColor: color,
            backgroundColor: color.withValues(alpha: isDark ? 0.05 : 0.03),
          ),
          onPressed: onTap,
          icon: Icon(icon, size: 16, color: color),
          label: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
        ),
      ),
    );
  }

  Widget _summaryChip(IconData icon, String text, Color color) {
    final isDark = ref.read(isDarkProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }
}

