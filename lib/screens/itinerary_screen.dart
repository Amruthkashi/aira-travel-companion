import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/travel_providers.dart';
import '../core/models/travel_models.dart';

class ItineraryScreen extends ConsumerStatefulWidget {
  const ItineraryScreen({super.key});

  @override
  ConsumerState<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends ConsumerState<ItineraryScreen> {
  int _activeDay = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showActivityEditModal(int dayIdx, int actIdx, ActivityItem act) {
    final titleCtrl = TextEditingController(text: act.activity);
    final timeCtrl = TextEditingController(text: act.time);
    final descCtrl = TextEditingController(text: act.description);
    final costCtrl = TextEditingController(text: act.cost);
    final locCtrl = TextEditingController(text: act.locationName);
    final attireCtrl = TextEditingController(text: act.suggestedAttire);
    final transportCtrl = TextEditingController(text: act.transport);
    final ticketCtrl = TextEditingController(text: act.ticketInfo);
    final placeCtrl = TextEditingController(text: act.placeDetails);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A1628), // Slate 900
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
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
                const Text(
                  'EDIT ACTIVITY DETAILS',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0),
                ),
                const SizedBox(height: 16),
                _modalField('Activity Title', titleCtrl),
                _modalField('Scheduled Time', timeCtrl),
                _modalField('Location Name', locCtrl),
                _modalField('Attire Suggested / Dress Code', attireCtrl),
                _modalField('Local Transport Directions', transportCtrl),
                _modalField('Ticketing & Booking Info', ticketCtrl),
                _modalField(r'Activity Expense Cost (e.g. $20 or ¥3,000)', costCtrl),
                _modalField('Place Details / Fun Facts', placeCtrl, maxLines: 2),
                _modalField('Description Notes', descCtrl, maxLines: 3),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF334155)),
                          foregroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          ref.read(itineraryProvider.notifier).updateActivity(
                            dayIdx,
                            actIdx,
                            activity: titleCtrl.text,
                            time: timeCtrl.text,
                            description: descCtrl.text,
                            cost: costCtrl.text,
                            locationName: locCtrl.text,
                            suggestedAttire: attireCtrl.text,
                            transport: transportCtrl.text,
                            ticketInfo: ticketCtrl.text,
                            placeDetails: placeCtrl.text,
                          );
                          Navigator.pop(context);
                        },
                        child: const Text('Save Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showActivityAddModal(int dayIdx) {
    final titleCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '09:00 AM');
    final descCtrl = TextEditingController();
    final costCtrl = TextEditingController(text: 'Free');
    final locCtrl = TextEditingController();
    final attireCtrl = TextEditingController(text: 'Casual clothing');
    final transportCtrl = TextEditingController();
    final ticketCtrl = TextEditingController();
    final placeCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A1628), // Slate 900
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
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
                const Text(
                  'ADD NEW TRIP ACTIVITY',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0),
                ),
                const SizedBox(height: 16),
                _modalField('Activity Title', titleCtrl),
                _modalField('Scheduled Time', timeCtrl),
                _modalField('Location Name', locCtrl),
                _modalField('Attire Suggested / Dress Code', attireCtrl),
                _modalField('Local Transport Directions', transportCtrl),
                _modalField('Ticketing Info', ticketCtrl),
                _modalField('Activity Expense Cost', costCtrl),
                _modalField('Place Details', placeCtrl),
                _modalField('Description Notes', descCtrl, maxLines: 3),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF334155)),
                          foregroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (titleCtrl.text.isNotEmpty) {
                            ref.read(itineraryProvider.notifier).addActivity(
                              dayIdx,
                              ActivityItem(
                                time: timeCtrl.text,
                                activity: titleCtrl.text,
                                description: descCtrl.text,
                                cost: costCtrl.text,
                                locationName: locCtrl.text,
                                suggestedAttire: attireCtrl.text,
                                transport: transportCtrl.text,
                                ticketInfo: ticketCtrl.text,
                                placeDetails: placeCtrl.text,
                              ),
                            );
                          }
                          Navigator.pop(context);
                        },
                        child: const Text('Add Activity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _modalField(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFF1A2744), // Slate 800
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF334155)),
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

  @override
  Widget build(BuildContext context) {
    final itinerary = ref.watch(itineraryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628), // Slate 900
      body: SafeArea(
        child: Column(
          children: [

            // Custom high-fidelity Header
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.schedule, color: Color(0xFF2563EB), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'HOURLY SCHEDULE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.train, color: Color(0xFF15803D), size: 12),
                        SizedBox(width: 4),
                        Text(
                          'TRANSIT INCLUDED',
                          style: TextStyle(
                            color: Color(0xFF15803D),
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Day Tabs (Day 1 - Day 5)
            _buildHorizontalDayTabs(itinerary),

            // The main body list
            Expanded(
              child: _buildItineraryBody(itinerary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalDayTabs(List<ItineraryDay> itinerary) {
    if (itinerary.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itinerary.length,
        itemBuilder: (context, idx) {
          final active = _activeDay == idx;
          return GestureDetector(
            onTap: () {
              setState(() {
                _activeDay = idx;
              });
            },
            child: Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF2563EB) : const Color(0xFF1A2744),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: active ? const Color(0xFF2563EB) : const Color(0xFF334155),
                  width: 1,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Text(
                'Day ${idx + 1}',
                style: TextStyle(
                  color: active ? Colors.white : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItineraryBody(List<ItineraryDay> itinerary) {
    if (itinerary.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.map_outlined, size: 64, color: Color(0xFF2563EB)),
              const SizedBox(height: 16),
              const Text(
                'No Itinerary Planned Yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a new itinerary using the "Chat Concierge" or "Ask Aira to Plan" option on the Home screen to populate your journey.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white54, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () {
                  ref.read(currentScreenProvider.notifier).state = '/home';
                  ref.read(currentTabProvider.notifier).state = 0; // go home tab
                },
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 16),
                label: const Text('Go Plan with Aira', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    if (_activeDay >= itinerary.length) {
      _activeDay = 0;
    }
    final dayObj = itinerary[_activeDay];

    // Calculate progression metrics
    final totalActs = dayObj.activities.length;
    final checkedActs = dayObj.activities.where((a) => a.checked).length;
    final progress = totalActs > 0 ? (checkedActs / totalActs) : 0.0;

    return Column(
      children: [
        // Day Theme Card with custom purple gradient and progress bar
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DAY ${_activeDay + 1} THEME',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      '$totalActs ACTIVITIES   /   $checkedActs DONE',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  dayObj.theme,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                // Custom Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        color: Colors.white.withOpacity(0.15),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 6,
                        width: MediaQuery.of(context).size.width * 0.8 * progress,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),        // Activities Timeline
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: dayObj.activities.length + 1,
            itemBuilder: (context, idx) {
              if (idx == dayObj.activities.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 32.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF334155)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        foregroundColor: const Color(0xFF00B4D8),
                        backgroundColor: const Color(0xFF1A2744),
                      ),
                      onPressed: () => _showActivityAddModal(_activeDay),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Custom Itinerary Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                );
              }

              final act = dayObj.activities[idx];

              return Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: act.checked ? 0.65 : 1.0,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Activity Details Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2744),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF334155)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card Header Row
                            Row(
                              children: [
                                // Inline Checkbox
                                GestureDetector(
                                  onTap: () {
                                    ref.read(itineraryProvider.notifier).toggleActivityCheck(_activeDay, idx);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: act.checked ? const Color(0xFF2563EB) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: act.checked ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: act.checked
                                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                
                                // Time
                                Text(
                                  act.time,
                                  style: const TextStyle(
                                    color: Color(0xFF818CF8),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                
                                // Status
                                Text(
                                  act.cost.isEmpty ? 'Free' : act.cost,
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                
                                // Edit button
                                GestureDetector(
                                  onTap: () => _showActivityEditModal(_activeDay, idx, act),
                                  child: const Icon(Icons.edit, size: 16, color: Color(0xFFF97316)), // Orange
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Activity Title
                            Text(
                              act.activity,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                decoration: act.checked ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            
                            // Activity Description
                            if (act.description.isNotEmpty) ...[
                              Text(
                                act.description,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            
                            // Location chip
                            if (act.locationName.isNotEmpty) ...[
                              GestureDetector(
                                onTap: () => context.push('/navigation'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0A1628),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF334155)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.location_on, size: 13, color: Color(0xFF00B4D8)),
                                      const SizedBox(width: 4),
                                      Text(
                                        act.locationName,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF00B4D8),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            
                            // Detail rows
                            if (act.suggestedAttire.isNotEmpty) ...[
                              _buildDetailRow(
                                emoji: '👚',
                                label: 'Outfit:',
                                labelColor: const Color(0xFFEC4899),
                                text: act.suggestedAttire,
                              ),
                              const SizedBox(height: 8),
                            ],
                            
                            if (act.placeDetails.isNotEmpty) ...[
                              _buildDetailRow(
                                emoji: '🍜',
                                label: 'Food:',
                                labelColor: const Color(0xFFF97316),
                                text: act.placeDetails,
                              ),
                              const SizedBox(height: 8),
                            ],
                            
                            if (act.ticketInfo.isNotEmpty) ...[
                              _buildDetailRow(
                                emoji: '💡',
                                label: 'Tip:',
                                labelColor: const Color(0xFF10B981),
                                text: act.ticketInfo,
                              ),
                              const SizedBox(height: 8),
                            ],
                            
                            if (act.transport.isNotEmpty) ...[
                              _buildDetailRow(
                                emoji: '🚇',
                                label: 'Transport:',
                                labelColor: const Color(0xFF06B6D4),
                                text: act.transport,
                              ),
                              const SizedBox(height: 8),
                            ],
                            
                            const SizedBox(height: 4),
                            const Divider(color: Color(0xFF334155), height: 1),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => ref.read(itineraryProvider.notifier).swapActivityWithAi(_activeDay, idx),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.auto_awesome, size: 14, color: Color(0xFF00B4D8)),
                                        SizedBox(width: 4),
                                        Text(
                                          'Swap with AI',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF00B4D8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => context.push('/navigation'),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.near_me, size: 14, color: Colors.tealAccent),
                                        SizedBox(width: 4),
                                        Text(
                                          'Launch Map',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.tealAccent,
                                          ),
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

                      // Floating Siren Alert Badge (only on specific items)
                      if (idx == 0 && _activeDay == 3)
                        Positioned(
                          bottom: 24,
                          right: -10,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFEF4444),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                )
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.notifications_active, color: Colors.white, size: 15),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required String emoji,
    required String label,
    required Color labelColor,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: labelColor,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
