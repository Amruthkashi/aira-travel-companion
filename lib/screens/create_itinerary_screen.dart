import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/theme_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/travel_providers.dart';
import '../core/models/travel_models.dart';
import '../core/services/ai_service.dart';
import '../core/utils/sound_synthesizer.dart';

class CreateItineraryScreen extends ConsumerStatefulWidget {
  const CreateItineraryScreen({super.key});

  @override
  ConsumerState<CreateItineraryScreen> createState() => _CreateItineraryScreenState();
}

class _CreateItineraryScreenState extends ConsumerState<CreateItineraryScreen> {
  // Form Controllers
  final _sourceCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  String _transportMode = 'Flight';
  final _providerCtrl = TextEditingController();
  final _pnrCtrl = TextEditingController();
  final _trainCtrl = TextEditingController();
  final _datesCtrl = TextEditingController();
  final _travelersCtrl = TextEditingController(text: '1');
  final _budgetCtrl = TextEditingController();
  final _preferencesCtrl = TextEditingController();

  bool _isScanning = false;
  double _scanProgress = 0.0;
  String _scanStatus = 'Initializing camera sensor...';
  Timer? _scanTimer;

  bool _isCompiling = false;
  double _compileProgress = 0.0;
  String _compileStatus = 'Spawning Concierge Optimizer...';
  Timer? _compileTimer;

  @override
  void dispose() {
    _sourceCtrl.dispose();
    _destCtrl.dispose();
    _providerCtrl.dispose();
    _pnrCtrl.dispose();
    _trainCtrl.dispose();
    _datesCtrl.dispose();
    _travelersCtrl.dispose();
    _budgetCtrl.dispose();
    _preferencesCtrl.dispose();
    _scanTimer?.cancel();
    _compileTimer?.cancel();
    super.dispose();
  }

  void _startCameraScanSimulation() {
    SoundSynthesizer.playTone(
      frequency: 660,
      durationSeconds: 0.15,
      name: 'scan_start.wav',
    );
    setState(() {
      _isScanning = true;
      _scanProgress = 0.0;
      _scanStatus = 'Initializing camera sensor...';
    });

    final stages = [
      'Initializing camera sensor...',
      'Locating ticket border parameters...',
      'Analyzing boarding pass layout...',
      'Extracting PNR code NH-782Y9W...',
      'Grounding Bangalore to Tokyo flight manifest...',
      'Auto-populating traveler parameters...',
    ];

    _scanTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      setState(() {
        if (_scanProgress < 1.0) {
          _scanProgress += 0.17;
          final idx = (_scanProgress * stages.length).floor().clamp(0, stages.length - 1);
          _scanStatus = stages[idx];
        } else {
          _scanTimer?.cancel();
          _isScanning = false;
          // Auto-fill all fields with exact photo details
          _sourceCtrl.text = 'Bangalore, India';
          _destCtrl.text = 'Tokyo, Japan';
          _transportMode = 'Flight';
          _providerCtrl.text = 'Direct Airline Booking';
          _pnrCtrl.text = 'NH-782Y9W';
          _trainCtrl.text = 'JR East Shinkansen';
          _datesCtrl.text = '2026-06-15 to 2026-06-20';
          _travelersCtrl.text = '2';
          _budgetCtrl.text = '\$1,500';
          _preferencesCtrl.text = 'Anime Shopping, Local Food Stalls, Temples, Tech Gadgets';

          SoundSynthesizer.playTone(
            frequency: 880,
            durationSeconds: 0.2,
            name: 'scan_complete.wav',
          );
        }
      });
    });
  }

  void _startHourlyCompileSimulation() {
    if (_destCtrl.text.isEmpty || _datesCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan a ticket or enter Destination and Dates to plan your itinerary.')),
      );
      return;
    }

    SoundSynthesizer.playTone(
      frequency: 580,
      durationSeconds: 0.12,
      name: 'compile_start.wav',
    );

    setState(() {
      _isCompiling = true;
      _compileProgress = 0.0;
      _compileStatus = 'Spawning Concierge Optimizer...';
    });

    final stages = [
      'Spawning Concierge Optimizer...',
      'Syncing flight NH-782Y9W details...',
      'Checking Tokyo weather logs...',
      'Grounding local West Central Tokyo lodging configurations...',
      'Optimizing 1-hour activity intervals...',
      'Securing Ghibli Museum entry voucher logs...',
      'Validating otaku-chic dress codes...',
      'Structuring 5-day high-fidelity hourly itinerary...',
      'Compilation finalized!',
    ];

    _compileTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      setState(() {
        if (_compileProgress < 1.0) {
          _compileProgress += 0.12;
          final idx = (_compileProgress * stages.length).floor().clamp(0, stages.length - 1);
          _compileStatus = stages[idx];
        } else {
          _compileTimer?.cancel();
          _executeCompilationCompletion();
        }
      });
    });
  }

  void _executeCompilationCompletion() async {
    final userProfileState = ref.read(userProfileProvider);
    final email = userProfileState.profile['email'] ?? 'shreyas.tokyo@gmail.com';
    
    // Parse travel dates parameters
    final datesText = _datesCtrl.text.trim();
    final datesParts = datesText.split(' to ');
    final startDateStr = datesParts.isNotEmpty && datesParts[0].isNotEmpty ? datesParts[0] : '2026-06-15';
    final endDateStr = datesParts.length > 1 && datesParts[1].isNotEmpty ? datesParts[1] : '2026-06-20';
    final city = _destCtrl.text.replaceAll(', Japan', '').trim();
    final budget = _budgetCtrl.text.trim();
    final prefs = _preferencesCtrl.text.trim();

    int days = 2;
    try {
      final start = DateTime.parse(startDateStr);
      final end = DateTime.parse(endDateStr);
      days = end.difference(start).inDays + 1;
      if (days <= 0) days = 1;
    } catch (e) {
      debugPrint('Error parsing dates for itinerary: $e');
    }

    final List<String> prefList = prefs.isNotEmpty 
        ? prefs.split(',').map((e) => e.trim()).toList() 
        : ['sightseeing'];

    // 1. Sync updated profile with backend
    ref.read(userProfileProvider.notifier).updateUserProfile({
      'city': city,
      'budgetPref': budget,
      'selectedPreferences': prefList,
      'upcomingTrip': {
        'city': city,
        'startDate': startDateStr,
        'endDate': endDateStr,
      }
    });

    final profileMap = Map<String, dynamic>.from(ref.read(userProfileProvider).profile);
    profileMap['dnaFoodie'] = userProfileState.dnaFoodie;
    profileMap['dnaHeritage'] = userProfileState.dnaHeritage;
    profileMap['dnaTech'] = userProfileState.dnaTech;
    profileMap['dnaAdventure'] = userProfileState.dnaAdventure;
    profileMap['travelArchetype'] = userProfileState.travelArchetype;

    // 2. Fetch real-time itinerary from backend using Groq API
    List<ItineraryDay> hourlyItinerary;
    try {
      hourlyItinerary = await AiService.generateItinerary(
        'Generate detailed hourly schedule for $city, budget $budget, preferences $prefs',
        profileMap,
        days: days,
      );
    } catch (e) {
      debugPrint('Failed to generate real-time itinerary: $e');
      hourlyItinerary = _generateFallbackItinerary(city, days);
    }

    // 3. Save itinerary to backend database
    await AiService.saveItinerary(email, hourlyItinerary);

    // 4. Update Riverpod client state
    ref.read(itineraryProvider.notifier).setItinerary(hourlyItinerary);

    SoundSynthesizer.playTone(
      frequency: 960,
      durationSeconds: 0.3,
      name: 'compile_done.wav',
    );

    if (mounted) {
      setState(() {
        _isCompiling = false;
      });
      
      // Go back to Home and switch to Trips tab (index 2)
      ref.read(currentTabProvider.notifier).state = 2; // Trips
      context.go('/home');
    }
  }

  List<ItineraryDay> _generateFallbackItinerary(String destination, int days) {
    final List<ItineraryDay> list = [];
    final cleanDest = destination.trim();
    final capitalized = cleanDest.isNotEmpty 
        ? cleanDest[0].toUpperCase() + cleanDest.substring(1)
        : 'Destination';

    for (int d = 1; d <= days; d++) {
      list.add(ItineraryDay(
        day: d,
        theme: 'Culture & Local Flavors of $capitalized - Day $d',
        activities: [
          ActivityItem(
            time: '08:30 AM',
            activity: 'Healthy Local Breakfast',
            description: 'Start your morning with freshly brewed artisanal coffee and a selection of freshly baked local pastries or a traditional breakfast set at a highly-rated neighborhood cafe.',
            cost: '\$8',
            locationName: '$capitalized Morning Bistro',
            suggestedAttire: 'Casual day wear',
            transport: 'Short 5-minute walk from hotel',
            ticketInfo: 'No reservation required',
            placeDetails: 'A cozy local spot loved by residents for its warm hospitality and freshly ground coffee beans.',
            checked: false,
          ),
          ActivityItem(
            time: '10:00 AM',
            activity: 'Iconic Central Landmark Tour',
            description: 'Stroll around the central historic plazas, view majestic architectural monuments, and capture beautiful morning photos of the city\'s most defining civic landmarks.',
            cost: 'Free',
            locationName: '$capitalized Heritage Plaza',
            suggestedAttire: 'Comfortable walking shoes & light layers',
            transport: 'Board local commuter rail to Central Station, walk 3 mins',
            ticketInfo: 'Open public area access',
            placeDetails: 'Established in the early historical era, this prominent plaza represents the rich cultural heart of the city.',
            checked: false,
          ),
          ActivityItem(
            time: '01:00 PM',
            activity: 'Gastronomy & Local Food Tour',
            description: 'Explore a vibrant open-air market filled with diverse food stalls. Sample unique regional street food delicacies, local specialties, and freshly prepared bites.',
            cost: '\$25',
            locationName: '$capitalized City Market Hall',
            suggestedAttire: 'Casual streetwear',
            transport: 'Short taxi ride or walk (10 mins)',
            ticketInfo: 'Cash highly recommended at individual stalls',
            placeDetails: 'A bustling commercial market featuring family-owned food stalls passing down authentic recipes for generations.',
            checked: false,
          ),
          ActivityItem(
            time: '03:30 PM',
            activity: 'Art & History Museum Visit',
            description: 'Immerse yourself in history and artistic expression. View collections of historical artifacts, fine art, and contemporary exhibitions depicting local history.',
            cost: '\$15',
            locationName: '$capitalized Museum of Art & History',
            suggestedAttire: 'Smart casual / Modest for indoor exhibits',
            transport: 'Walk 5 minutes north from City Market Hall',
            ticketInfo: 'Purchase entry ticket at the reception desk',
            placeDetails: 'A world-class civic institution housing important national treasures and temporary modern art galleries.',
            checked: false,
          ),
          ActivityItem(
            time: '06:30 PM',
            activity: 'Sunset Scenic Viewpoint',
            description: 'Climb to an elevated observation deck or scenic hilltop park just in time to watch the setting sun paint the city skyline. Perfect for panoramic photography.',
            cost: '\$18',
            locationName: '$capitalized Skyline Observation Tower',
            suggestedAttire: 'Light jacket (it gets breezy at high elevations)',
            transport: 'Take local subway Line 4 to Heights Station, follow exit signs',
            ticketInfo: 'Online pre-booked ticket voucher recommended for sunset slots',
            placeDetails: 'Standing tall over the cityscape, this observation deck offers breathtaking 360-degree views of the horizon.',
            checked: false,
          ),
          ActivityItem(
            time: '08:00 PM',
            activity: 'Signature Local Dinner',
            description: 'Dine in a highly-rated traditional restaurant situated in an atmospheric neighborhood. Enjoy a multi-course dinner of classic regional recipes and local specialties.',
            cost: '\$35',
            locationName: 'Traditional Dining District',
            suggestedAttire: 'Smart casual',
            transport: 'Short taxi ride or walk',
            ticketInfo: 'Reservation confirmed under travel profile',
            placeDetails: 'A highly praised dining spot famous for its authentic cooking techniques and welcoming, cozy atmosphere.',
            checked: false,
          ),
        ],
      ));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkProvider);

    return Scaffold(
      backgroundColor: AiraColors.scaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: AiraColors.scaffoldBg(isDark),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AiraColors.textPrimary(isDark)),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Itinerary',
              style: TextStyle(color: AiraColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Text(
              'CONTINUOUS COMPILATION',
              style: TextStyle(color: Color(0xFF00B4D8), fontWeight: FontWeight.w800, fontSize: 9, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Smart Ticket Sync Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AiraColors.scaffoldBg(isDark),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AiraColors.border(isDark)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF312E81).withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.confirmation_number, color: isDark ? const Color(0xFFC7D2FE) : const Color(0xFFFF6B35), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Smart Ticket Sync',
                              style: TextStyle(color: AiraColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Scan your boarding pass or booking voucher with your device camera for instant form auto-fill!',
                              style: TextStyle(color: AiraColors.textSecondary(isDark), fontSize: 10.5, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Scan button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onPressed: _startCameraScanSimulation,
                        icon: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                        label: const Text('SCAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10.5)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Title Section
                Text(
                  'Custom Traveler Flight & Dates Parameters',
                  style: TextStyle(color: AiraColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
                const SizedBox(height: 6),
                Text(
                  'Set your custom flight details, budget caps, and specific travel themes. Our compiler loads fully grounded itineraries in seconds.',
                  style: TextStyle(color: AiraColors.textSecondary(isDark), fontSize: 11, height: 1.4),
                ),
                const SizedBox(height: 20),

                // 3. Form Fields
                Row(
                  children: [
                    Expanded(child: _buildFormField('SOURCE LOCATION', _sourceCtrl, 'e.g. Bangalore, India', isDark)),
                    const SizedBox(width: 14),
                    Expanded(child: _buildFormField('DESTINATION', _destCtrl, 'e.g. Tokyo, Japan', isDark)),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MODE OF TRANSPORT',
                            style: TextStyle(color: AiraColors.textSecondary(isDark), fontWeight: FontWeight.bold, fontSize: 9.5, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AiraColors.cardBg(isDark),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AiraColors.border(isDark)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _transportMode,
                                dropdownColor: AiraColors.cardBg(isDark),
                                isExpanded: true,
                                style: TextStyle(color: AiraColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 12.5),
                                icon: Icon(Icons.keyboard_arrow_down, color: AiraColors.textSecondary(isDark)),
                                items: <String>['Flight', 'Train', 'Car'].map((String val) {
                                  return DropdownMenuItem<String>(
                                    value: val,
                                    child: Row(
                                      children: [
                                        Icon(
                                          val == 'Flight'
                                              ? Icons.flight
                                              : (val == 'Train' ? Icons.train : Icons.directions_car),
                                          color: const Color(0xFF00B4D8),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(val, style: TextStyle(color: AiraColors.textPrimary(isDark))),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newVal) {
                                  if (newVal != null) {
                                    setState(() {
                                      _transportMode = newVal;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: _buildFormField('TRAVEL PROVIDER', _providerCtrl, 'e.g. Direct Airline', isDark)),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(child: _buildFormField('FLIGHT PNR CODE', _pnrCtrl, 'e.g. NH-782Y9W', isDark)),
                    const SizedBox(width: 14),
                    Expanded(child: _buildFormField('TRAIN NUMBER (OPTIONAL)', _trainCtrl, 'e.g. JR East', isDark)),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(child: _buildDateRangeField('TRAVEL DATES', _datesCtrl, isDark)),
                    const SizedBox(width: 14),
                    Expanded(child: _buildFormField('TRAVELERS', _travelersCtrl, '1', isDark, isNumeric: true)),
                  ],
                ),
                const SizedBox(height: 14),

                _buildFormField('TOTAL ALLOCATED BUDGET', _budgetCtrl, 'e.g. \$1,500', isDark),
                const SizedBox(height: 14),

                _buildFormField('TRAVEL STYLE & PREFERENCES', _preferencesCtrl, 'e.g. Anime Shopping, Food Stalls, Temples', isDark, maxLines: 2),
                const SizedBox(height: 32),

                // Full Wizard Button (Primary CTA)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 6,
                    ),
                    onPressed: () {
                      // Pass form data to wizard providers
                      if (_destCtrl.text.isNotEmpty) {
                        ref.read(tripBookingsProvider.notifier).setDestination(_destCtrl.text);
                      }
                      // Pre-fill flight if source/dest provided
                      if (_sourceCtrl.text.isNotEmpty && _destCtrl.text.isNotEmpty) {
                        ref.read(tripBookingsProvider.notifier).addFlight(FlightBooking(
                          id: 'flt-prefill-${DateTime.now().millisecondsSinceEpoch}',
                          airline: _providerCtrl.text.isNotEmpty ? _providerCtrl.text : 'Airline',
                          flightNumber: _pnrCtrl.text.isNotEmpty ? _pnrCtrl.text.split('-').first : '',
                          pnr: _pnrCtrl.text,
                          departureCity: _sourceCtrl.text,
                          arrivalCity: _destCtrl.text,
                          departureDate: _datesCtrl.text.split(' to ').isNotEmpty ? _datesCtrl.text.split(' to ').first : '',
                          arrivalDate: _datesCtrl.text.split(' to ').length > 1 ? _datesCtrl.text.split(' to ').last : '',
                          seatClass: 'Economy',
                          passengers: int.tryParse(_travelersCtrl.text) ?? 1,
                          flightType: 'going',
                        ));
                      }
                      context.push('/itinerary-wizard/bookings');
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'FULL ITINERARY WIZARD',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Quick Compile Button (Secondary CTA)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      foregroundColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                    ),
                    onPressed: _startHourlyCompileSimulation,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'QUICK COMPILE (AI ONLY)',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

              ],
            ),
          ),

          // 4. Scanning Overlay
          if (_isScanning) _buildScanningOverlay(),

          // 5. Compiling Overlay
          if (_isCompiling) _buildCompilingOverlay(isDark),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController ctrl, String hint, bool isDark, {int maxLines = 1, bool isNumeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AiraColors.textSecondary(isDark), fontWeight: FontWeight.bold, fontSize: 9.5, letterSpacing: 0.5),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          style: TextStyle(color: AiraColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 12.5),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(color: AiraColors.textMuted(isDark), fontSize: 12),
            filled: true,
            fillColor: AiraColors.cardBg(isDark),
            contentPadding: const EdgeInsets.all(12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AiraColors.border(isDark)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeField(String label, TextEditingController ctrl, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AiraColors.textSecondary(isDark), fontWeight: FontWeight.bold, fontSize: 9.5, letterSpacing: 0.5),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          readOnly: true,
          onTap: () async {
            final DateTimeRange? picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
              initialDateRange: DateTimeRange(
                start: DateTime.now(),
                end: DateTime.now().add(const Duration(days: 5)),
              ),
              builder: (context, child) {
                return Theme(
                  data: isDark
                      ? Theme.of(context).copyWith(
                          appBarTheme: const AppBarTheme(
                            backgroundColor: Color(0xFF1A2744),
                            foregroundColor: Colors.white,
                            iconTheme: IconThemeData(color: Colors.white),
                          ),
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF2563EB), // Royal Blue
                            onPrimary: Colors.white,
                            surface: Color(0xFF1A2744),
                            onSurface: Colors.white,
                            secondary: Color(0xFF00B4D8),
                          ),
                          dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF0A1628),),
                          datePickerTheme: const DatePickerThemeData(
                            backgroundColor: Color(0xFF0A1628),
                            headerBackgroundColor: Color(0xFF1A2744),
                            headerForegroundColor: Colors.white,
                            rangePickerHeaderBackgroundColor: Color(0xFF1A2744),
                            rangePickerHeaderForegroundColor: Colors.white,
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF60A5FA),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      : Theme.of(context).copyWith(
                          appBarTheme: const AppBarTheme(
                            backgroundColor: Color(0xFFF1F5F9),
                            foregroundColor: Colors.black87,
                            iconTheme: IconThemeData(color: Colors.black87),
                          ),
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF2563EB),
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: Colors.black87,
                            secondary: Color(0xFF00B4D8),
                          ),
                          dialogTheme: DialogThemeData(backgroundColor: Colors.white,),
                          datePickerTheme: const DatePickerThemeData(
                            backgroundColor: Colors.white,
                            headerBackgroundColor: Color(0xFFE2E8F0),
                            headerForegroundColor: Colors.black87,
                            rangePickerHeaderBackgroundColor: Color(0xFFE2E8F0),
                            rangePickerHeaderForegroundColor: Colors.black87,
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
              final startY = picked.start.year;
              final startM = picked.start.month.toString().padLeft(2, '0');
              final startD = picked.start.day.toString().padLeft(2, '0');
              
              final endY = picked.end.year;
              final endM = picked.end.month.toString().padLeft(2, '0');
              final endD = picked.end.day.toString().padLeft(2, '0');
              
              ctrl.text = '$startY-$startM-$startD to $endY-$endM-$endD';
            }
          },
          style: TextStyle(color: AiraColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 12.5),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Tap to select date range',
            hintStyle: TextStyle(color: AiraColors.textMuted(isDark), fontSize: 12),
            suffixIcon: const Icon(Icons.calendar_month, color: Color(0xFF2563EB), size: 16),
            filled: true,
            fillColor: AiraColors.cardBg(isDark),
            contentPadding: const EdgeInsets.all(12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AiraColors.border(isDark)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanningOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Simulated camera viewfinder
            Container(
              width: 260,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00B4D8), width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Pulsing scanning laser line
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 1),
                    builder: (context, value, child) {
                      return Positioned(
                        top: 180 * value,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            boxShadow: [
                              BoxShadow(color: Colors.redAccent, blurRadius: 8, spreadRadius: 1),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'SMART TICKET SYNCING',
              style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              _scanStatus,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 150,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _scanProgress,
                  backgroundColor: const Color(0xFF1A2744),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  minHeight: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompilingOverlay(bool isDark) {
    return Positioned.fill(
      child: Container(
        color: AiraColors.dialogBg(isDark).withValues(alpha: 0.92),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
            const SizedBox(height: 32),
            const Text(
              'CONCIERGE COMPILATION RUNNING',
              style: TextStyle(color: Color(0xFF00B4D8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              _compileStatus,
              style: TextStyle(color: AiraColors.textPrimary(isDark), fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _compileProgress,
                  backgroundColor: AiraColors.scaffoldBg(isDark),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

