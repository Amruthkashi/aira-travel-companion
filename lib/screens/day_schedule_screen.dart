import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/travel_providers.dart';
import '../core/providers/theme_provider.dart';
import '../core/models/travel_models.dart';
import '../core/utils/timeline_validator.dart';
import '../core/theme/app_theme.dart';

class TimelineItem {
  final String id;
  final String time;
  final String endTime;
  final String title;
  final String description;
  final bool isBooking;
  final String icon;
  final DayScheduleItem? activity;
  final String? placeDetails;
  final String? transport;
  final String? ticketInfo;
  final String? cost;
  final List<String>? warnings;

  TimelineItem({
    required this.id,
    required this.time,
    required this.endTime,
    required this.title,
    required this.description,
    required this.isBooking,
    required this.icon,
    this.activity,
    this.placeDetails,
    this.transport,
    this.ticketInfo,
    this.cost,
    this.warnings,
  });
}

class DayScheduleScreen extends ConsumerStatefulWidget {
  const DayScheduleScreen({super.key});

  @override
  ConsumerState<DayScheduleScreen> createState() => _DayScheduleScreenState();
}

class _DayScheduleScreenState extends ConsumerState<DayScheduleScreen> {
  int _activeDay = 0;
  bool _isTimelineCalendarView = false;
  late ScrollController _timelineScrollController;

  @override
  void initState() {
    super.initState();
    _timelineScrollController = ScrollController(
      initialScrollOffset: 8 * 90.0, // Scroll to 8 AM on startup
    );
  }

  @override
  void dispose() {
    _timelineScrollController.dispose();
    super.dispose();
  }

  void _showTimePicker(int dayIndex, String placeId, String currentTime) {
    final isDark = ref.read(isDarkProvider);
    final timeCtrl = TextEditingController(text: currentTime);
    final schedule = ref.read(dayScheduleProvider);
    final item = schedule[dayIndex].firstWhere((i) => i.place.id == placeId);
    final durationMin = item.place.durationMinutes;

    // Calculate which preset times are blocked
    final presetTimes = [
      '08:00 AM', '09:00 AM', '10:00 AM', '10:30 AM',
      '11:00 AM', '12:00 PM', '01:00 PM', '02:00 PM',
      '03:00 PM', '04:00 PM', '05:00 PM', '06:00 PM',
      '07:00 PM', '08:00 PM', '09:00 PM',
    ];

    String? selectedPreset = currentTime;

    showModalBottomSheet(
      context: context,
      backgroundColor: TriaColors.dialogBg(isDark),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 5,
                      decoration: BoxDecoration(
                        color: TriaColors.border(isDark),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('SET ACTIVITY TIME',
                        style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${durationMin}min needed',
                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(item.place.name,
                    style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  // Quick time presets with availability indicators
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presetTimes.map((t) {
                      final startMin = parseTimeToMinutes(t);
                      final isFree = ref.read(dayScheduleProvider.notifier).isTimeSlotFree(
                        dayIndex, startMin, durationMin, excludePlaceId: placeId,
                      );
                      final isSelected = selectedPreset == t;

                      return GestureDetector(
                        onTap: () {
                          if (!isFree) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.block, color: Colors.white, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text('$t is blocked — another activity occupies this slot')),
                                  ],
                                ),
                                backgroundColor: const Color(0xFFEF4444),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          setModalState(() => selectedPreset = t);
                          timeCtrl.text = t;
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: !isFree
                                ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                                : isSelected
                                    ? const Color(0xFF2563EB)
                                    : TriaColors.cardBg(isDark),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: !isFree
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                                  : isSelected
                                      ? const Color(0xFF2563EB)
                                      : TriaColors.border(isDark),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isFree)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(Icons.lock, size: 10, color: Color(0xFFEF4444)),
                                ),
                              Text(t,
                                style: TextStyle(
                                  color: !isFree
                                      ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                                      : isSelected
                                          ? Colors.white
                                          : TriaColors.textSecondary(isDark),
                                  fontWeight: FontWeight.bold, fontSize: 11,
                                  decoration: !isFree ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: timeCtrl,
                    style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Custom time (e.g. 10:30 AM)',
                      hintStyle: TextStyle(color: TriaColors.textMuted(isDark)),
                      filled: true,
                      fillColor: TriaColors.cardBg(isDark),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: TriaColors.border(isDark)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: TriaColors.border(isDark)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final success = ref.read(dayScheduleProvider.notifier).updateTime(dayIndex, placeId, timeCtrl.text);
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.warning_amber, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Expanded(child: Text('Time conflict! Another activity is scheduled during this time slot.')),
                                ],
                              ),
                              backgroundColor: Color(0xFFEF4444),
                              duration: Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                      },
                      child: const Text('Set Time', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDayOptionsSheet(int currentDay, int targetDay, String placeId) {
    final isDark = ref.read(isDarkProvider);
    final schedule = ref.read(dayScheduleProvider);
    final bookings = ref.read(tripBookingsProvider);
    final item = schedule[currentDay].firstWhere((i) => i.place.id == placeId);
    final targetItems = schedule[targetDay];
    
    final notifier = ref.read(dayScheduleProvider.notifier);
    final hasFreeSlot = notifier.findFreeSlotForPlace(targetDay, item.place, bookings, excludePlaceId: placeId) >= 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: TriaColors.dialogBg(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 5,
                  decoration: BoxDecoration(
                    color: TriaColors.border(isDark),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('DAY ${targetDay + 1} OPTIONS',
                style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text('Move or swap: ${item.place.name}',
                style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 12),
              ),
              const SizedBox(height: 20),
              
              // Option 1: Move to first free slot
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasFreeSlot ? const Color(0xFF2563EB) : TriaColors.border(isDark),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: !hasFreeSlot ? null : () {
                    final success = notifier.moveToDay(currentDay, targetDay, placeId, bookings);
                    if (success) {
                      Navigator.pop(ctx); // Close option sheet
                      Navigator.pop(context); // Close day selection sheet
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Successfully moved ${item.place.name} to Day ${targetDay + 1}'),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.forward, color: Colors.white, size: 18),
                  label: Text(
                    hasFreeSlot ? 'Move to First Free Slot' : 'No Free Slots Available',
                    style: TextStyle(color: hasFreeSlot ? Colors.white : TriaColors.textMuted(isDark), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
              if (targetItems.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('SWAP WITH EXISTING ACTIVITY',
                  style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: targetItems.length,
                    itemBuilder: (context, index) {
                      final targetAct = targetItems[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            final success = notifier.swapActivities(
                              currentDay,
                              placeId,
                              targetDay,
                              targetAct.place.id,
                            );
                            if (success) {
                              Navigator.pop(ctx); // Close option sheet
                              Navigator.pop(context); // Close day selection sheet
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Swapped ${item.place.name} with ${targetAct.place.name}!'),
                                  backgroundColor: const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.warning, color: Colors.white, size: 16),
                                      SizedBox(width: 8),
                                      Expanded(child: Text('Cannot swap: Swapping causes time conflict with other activities.')),
                                    ],
                                  ),
                                  backgroundColor: Color(0xFFEF4444),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: TriaColors.cardBg(isDark),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: TriaColors.border(isDark)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.swap_horiz, color: Color(0xFFF59E0B), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(targetAct.place.name,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text('${targetAct.scheduledTime} (${targetAct.place.durationMinutes} min)',
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showMoveToDaySheet(int currentDay, String placeId) {
    final isDark = ref.read(isDarkProvider);
    final schedule = ref.read(dayScheduleProvider);
    final bookings = ref.read(tripBookingsProvider);
    final item = schedule[currentDay].firstWhere((i) => i.place.id == placeId);

    showModalBottomSheet(
      context: context,
      backgroundColor: TriaColors.dialogBg(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 5,
                  decoration: BoxDecoration(
                    color: TriaColors.border(isDark),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('MOVE TO ANOTHER DAY',
                style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text('${item.place.name} (${item.place.durationMinutes} min)',
                style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 12),
              ),
              const SizedBox(height: 16),
              ...List.generate(schedule.length, (idx) {
                final isCurrent = idx == currentDay;
                // Check if target day has a free slot
                final notifier = ref.read(dayScheduleProvider.notifier);
                final hasFreeSlot = isCurrent ? true :
                    notifier.findFreeSlotForPlace(idx, item.place, bookings, excludePlaceId: placeId) >= 0;
                final dayItemCount = schedule[idx].length;
                final isFull = !isCurrent && !hasFreeSlot;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCurrent
                            ? TriaColors.border(isDark)
                            : isFull
                                ? const Color(0xFFFBBF24).withValues(alpha: 0.1)
                                : TriaColors.cardBg(isDark),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isCurrent
                                ? TriaColors.textMuted(isDark)
                                : isFull
                                    ? const Color(0xFFFBBF24).withValues(alpha: 0.3)
                                    : TriaColors.border(isDark),
                          ),
                        ),
                      ),
                      onPressed: isCurrent ? null : () {
                        if (dayItemCount == 0) {
                          final success = ref.read(dayScheduleProvider.notifier).moveToDay(currentDay, idx, placeId, bookings);
                          if (success) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Moved ${item.place.name} to Day ${idx + 1}'),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } else {
                          _showDayOptionsSheet(currentDay, idx, placeId);
                        }
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? const Color(0xFF475569)
                                  : isFull
                                      ? const Color(0xFFFBBF24).withValues(alpha: 0.2)
                                      : const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text('${idx + 1}',
                                style: TextStyle(
                                  color: isCurrent ? const Color(0xFF94A3B8) : Colors.white,
                                  fontWeight: FontWeight.w900, fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Day ${idx + 1}',
                                  style: TextStyle(
                                    color: isCurrent ? const Color(0xFF64748B) : Colors.white,
                                    fontWeight: FontWeight.bold, fontSize: 14,
                                  ),
                                ),
                                Text('$dayItemCount activities',
                                  style: TextStyle(
                                    color: isCurrent ? const Color(0xFF475569) : const Color(0xFF64748B),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF475569),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('current',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            )
                          else if (isFull)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.swap_calls, color: Color(0xFFFBBF24), size: 14),
                                const SizedBox(width: 4),
                                const Text('Swap',
                                  style: TextStyle(color: Color(0xFFFBBF24), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          else
                            const Icon(Icons.arrow_forward, color: Color(0xFF60A5FA), size: 16),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }  void _showAttractionActionSheet(int dayIdx, DayScheduleItem item) {
    final isDark = ref.read(isDarkProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: TriaColors.dialogBg(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 5,
                  decoration: BoxDecoration(
                    color: TriaColors.border(isDark),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: (item.place.imageUrl.isNotEmpty && (item.place.imageUrl.startsWith('http://') || item.place.imageUrl.startsWith('https://')))
                        ? Image.network(
                            item.place.imageUrl,
                            width: 48, height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => Container(
                              width: 48, height: 48,
                              color: TriaColors.border(isDark),
                              child: Icon(Icons.image, color: TriaColors.textMuted(isDark), size: 20),
                            ),
                          )
                        : Container(
                            width: 48, height: 48,
                            color: TriaColors.border(isDark),
                            child: Icon(Icons.image, color: TriaColors.textMuted(isDark), size: 20),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.place.name,
                          style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${item.place.genre} • ${item.place.durationMinutes} mins',
                          style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Action 1: Change Time
              ListTile(
                leading: const Icon(Icons.schedule, color: Color(0xFF60A5FA)),
                title: Text('Change Time Slot', style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Currently: ${item.scheduledTime} – ${item.endTime}', style: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showTimePicker(dayIdx, item.place.id, item.scheduledTime);
                },
                tileColor: TriaColors.cardBg(isDark),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              const SizedBox(height: 10),
 
              // Action 2: Move to Another Day
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Color(0xFFF59E0B)),
                title: Text('Move to Another Day', style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Currently on Day ${dayIdx + 1}', style: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showMoveToDaySheet(dayIdx, item.place.id);
                },
                tileColor: TriaColors.cardBg(isDark),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              const SizedBox(height: 10),
 
              // Action 3: Remove from Schedule
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                title: const Text('Remove from Day', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Unschedule place and return it to pool', style: TextStyle(color: Color(0xFF7F1D1D), fontSize: 11)),
                onTap: () {
                  ref.read(dayScheduleProvider.notifier).removeFromDay(dayIdx, item.place.id);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Removed ${item.place.name} from schedule'),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                tileColor: const Color(0xFF7F1D1D).withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  List<TimelineItem> _insertFreeTimeSlots(int dayIdx, List<TimelineItem> items, TripBookings bookings) {
    if (items.isEmpty) return items;

    final List<TimelineItem> result = [];
    final dayEarliestStart = getDayEarliestStart(dayIdx, bookings);
    
    // Find returning flight
    final returnFlight = getReturnFlight(bookings);
    final baseStart = getBaseStartDate(bookings);
    final dayDate = baseStart.add(Duration(days: dayIdx));
    
    DateTime? returnDeparture;
    if (returnFlight != null) {
      returnDeparture = parseFlightDateTime(
        returnFlight.departureDate,
        returnFlight.departureTime.isNotEmpty ? returnFlight.departureTime : '06:00 PM',
      );
    }
    
    int dayLatestEnd = 1500; // 01:00 AM next day default (for Nightlife)
    if (returnDeparture != null &&
        dayDate.year == returnDeparture.year &&
        dayDate.month == returnDeparture.month &&
        dayDate.day == returnDeparture.day) {
      final depMin = returnDeparture.hour * 60 + returnDeparture.minute;
      dayLatestEnd = depMin - 165; // Airport transfer start
    }

    int currentPointer = dayEarliestStart;

    for (final item in items) {
      final itemStart = parseTimeToMinutes(item.time);
      final itemEnd = parseTimeToMinutes(item.endTime);

      // If there is a gap between current pointer and item start
      if (itemStart > currentPointer + 15) { // gap of at least 15 minutes
        result.add(TimelineItem(
          id: 'free-slot-$dayIdx-$currentPointer-$itemStart',
          time: minutesToTimeString(currentPointer),
          endTime: minutesToTimeString(itemStart),
          title: '✨ Free Time Available',
          description: 'You have some open hours here. Tap to schedule a place.',
          isBooking: false,
          icon: '✨',
          placeDetails: 'Duration: ${itemStart - currentPointer} mins',
          cost: 'free-slot', // marker
        ));
      }

      result.add(item);
      
      if (itemEnd > currentPointer) {
        currentPointer = itemEnd;
      }
    }

    if (dayLatestEnd > currentPointer + 15) {
      result.add(TimelineItem(
        id: 'free-slot-$dayIdx-$currentPointer-$dayLatestEnd',
        time: minutesToTimeString(currentPointer),
        endTime: minutesToTimeString(dayLatestEnd),
        title: '✨ Free Time Available',
        description: 'You have some open hours here. Tap to schedule a place.',
        isBooking: false,
        icon: '✨',
        placeDetails: 'Duration: ${dayLatestEnd - currentPointer} mins',
        cost: 'free-slot',
      ));
    }

    return result;
  }

  Widget _freeSlotItemCard(TimelineItem item, {required Key key}) {
    final isDark = ref.watch(isDarkProvider);
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: TriaColors.cardBgAlt(isDark).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TriaColors.border(isDark),
          style: BorderStyle.solid,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00B4D8).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wb_sunny_outlined,
              color: Color(0xFF00B4D8),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        color: TriaColors.textPrimary(isDark),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B4D8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.time} – ${item.endTime}',
                        style: const TextStyle(
                          color: Color(0xFF00B4D8),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: TextStyle(
                    color: TriaColors.textSecondary(isDark),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => _showAddPlaceToSlotSheet(_activeDay, item),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Add Place',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPlaceToSlotSheet(int dayIdx, TimelineItem slotItem) {
    final isDark = ref.read(isDarkProvider);
    final selectedPlaces = ref.read(selectedPlacesProvider);
    final schedule = ref.read(dayScheduleProvider);
    
    // Find unassigned places
    final assignedIds = <String>{};
    for (final day in schedule) {
      for (final i in day) {
        assignedIds.add(i.place.id);
      }
    }
    final unassigned = selectedPlaces.where((p) => !assignedIds.contains(p.id)).toList();
    final slotStartMin = parseTimeToMinutes(slotItem.time);
    final slotEndMin = parseTimeToMinutes(slotItem.endTime);
    final slotDuration = slotEndMin - slotStartMin;

    showModalBottomSheet(
      context: context,
      backgroundColor: TriaColors.dialogBg(isDark),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 5,
                      decoration: BoxDecoration(
                        color: TriaColors.border(isDark),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.add_circle, color: Color(0xFF00B4D8), size: 20),
                      const SizedBox(width: 12),
                      Text('SCHEDULE PLACE IN SLOT',
                        style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Available interval: ${slotItem.time} – ${slotItem.endTime} ($slotDuration mins free)',
                    style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 11),
                  ),
                  const SizedBox(height: 20),
                  if (unassigned.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No unassigned places in pool. Add some from the Explore screen first!',
                          style: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: unassigned.length,
                        itemBuilder: (context, index) {
                          final place = unassigned[index];
                          final fits = place.durationMinutes <= slotDuration;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: !fits ? null : () {
                                ref.read(dayScheduleProvider.notifier).addToDayAtTime(
                                  dayIdx,
                                  place,
                                  slotItem.time,
                                );
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Scheduled ${place.name} at ${slotItem.time}!'),
                                    backgroundColor: const Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Opacity(
                                opacity: fits ? 1.0 : 0.4,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: TriaColors.cardBg(isDark),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: fits ? TriaColors.border(isDark) : const Color(0xFF7F1D1D).withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: (place.imageUrl.isNotEmpty && (place.imageUrl.startsWith('http://') || place.imageUrl.startsWith('https://')))
                                            ? Image.network(
                                                place.imageUrl,
                                                width: 40, height: 40,
                                                fit: BoxFit.cover,
                                                errorBuilder: (ctx, err, st) => Container(
                                                  width: 40, height: 40,
                                                  color: TriaColors.border(isDark),
                                                  child: Icon(Icons.image, color: TriaColors.textMuted(isDark), size: 20),
                                                ),
                                              )
                                            : Container(
                                                width: 40, height: 40,
                                                color: TriaColors.border(isDark),
                                                child: Icon(Icons.image, color: TriaColors.textMuted(isDark), size: 20),
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              place.name,
                                              style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '${place.genre} • Need: ${place.durationMinutes} min',
                                              style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!fits)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF7F1D1D),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'Too long',
                                            style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 8, fontWeight: FontWeight.bold),
                                          ),
                                        )
                                      else
                                        const Icon(Icons.add_circle_outline, color: Color(0xFF10B981), size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkProvider);
    final schedule = ref.watch(dayScheduleProvider);
    final selectedPlaces = ref.watch(selectedPlacesProvider);
    final bookings = ref.watch(tripBookingsProvider);

    // Find unassigned places
    final assignedIds = <String>{};
    for (final day in schedule) {
      for (final item in day) {
        assignedIds.add(item.place.id);
      }
    }
    final unassigned = selectedPlaces.where((p) => !assignedIds.contains(p.id)).toList();

    final currentDayItems = (_activeDay >= 0 && _activeDay < schedule.length)
        ? schedule[_activeDay]
        : <DayScheduleItem>[];

    final Map<String, List<String>> dayWarnings = validateDayScheduleItems(
      _activeDay,
      currentDayItems,
      bookings,
    );
    final bool hasConflicts = dayWarnings.isNotEmpty;
    final rawTimelineItems = buildTimelineItems(
      _activeDay,
      currentDayItems,
      bookings,
      dayWarnings,
    );
    final timelineItems = _insertFreeTimeSlots(
      _activeDay,
      rawTimelineItems,
      bookings,
    );

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
            Text('Day Planner', style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 18)),
            const Text('STEP 3 — SCHEDULE ACTIVITIES', style: TextStyle(color: Color(0xFF00B4D8), fontWeight: FontWeight.w800, fontSize: 9, letterSpacing: 0.5)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.looks_3, color: Color(0xFF60A5FA), size: 14),
                SizedBox(width: 4),
                Text('3/4', style: TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.bold, fontSize: 11)),
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
                _stepLine(true),
                _stepDot(true, 'Explore'),
                _stepLine(true),
                _stepDot(true, 'Schedule'),
                _stepLine(false),
                _stepDot(false, 'Preview'),
              ],
            ),
          ),

          // Day Tabs
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: schedule.length,
              itemBuilder: (ctx, idx) {
                final active = _activeDay == idx;
                final dayItemCount = schedule[idx].length;
                return GestureDetector(
                  onTap: () => setState(() => _activeDay = idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF2563EB) : TriaColors.cardBg(isDark),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: active ? const Color(0xFF2563EB) : TriaColors.border(isDark),
                      ),
                      boxShadow: active ? [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                          blurRadius: 8, offset: const Offset(0, 3),
                        ),
                      ] : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Day ${idx + 1}',
                          style: TextStyle(
                            color: active ? Colors.white : TriaColors.textSecondary(isDark),
                            fontWeight: FontWeight.bold, fontSize: 13,
                          ),
                        ),
                        if (dayItemCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: active ? Colors.white.withValues(alpha: 0.2) : TriaColors.border(isDark),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$dayItemCount',
                              style: TextStyle(
                                color: active ? Colors.white : TriaColors.textMuted(isDark),
                                fontWeight: FontWeight.bold, fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          if (hasConflicts)
            Container(
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFF87171), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Timeline conflicts detected!',
                          style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Activities overlap with bookings or operating hours.',
                          style: TextStyle(color: TriaColors.textPrimary(isDark).withValues(alpha: 0.6), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final changes = ref.read(dayScheduleProvider.notifier).resolveConflictsForDay(_activeDay, bookings);
                      _showResolutionPopup(changes);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Resolve',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),


          // AI Suggest button + time summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('DAY ${_activeDay + 1} SCHEDULE',
                  style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                ),
                const SizedBox(width: 8),
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    _isTimelineCalendarView ? Icons.format_list_bulleted : Icons.calendar_view_day,
                    color: const Color(0xFF00B4D8),
                    size: 20,
                  ),
                  tooltip: _isTimelineCalendarView ? 'Switch to List View' : 'Switch to Hourly Timeline',
                  onPressed: () => setState(() => _isTimelineCalendarView = !_isTimelineCalendarView),
                ),
                const Spacer(),
                if (currentDayItems.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      final changes = ref.read(dayScheduleProvider.notifier).autoSuggestTimings(_activeDay, bookings);
                      _showResolutionPopup(changes);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: hasConflicts ? const Color(0xFFEF4444).withValues(alpha: 0.15) : const Color(0xFF00B4D8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: hasConflicts ? const Color(0xFFEF4444).withValues(alpha: 0.3) : const Color(0xFF00B4D8).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(hasConflicts ? Icons.healing : Icons.auto_awesome, size: 14, color: hasConflicts ? const Color(0xFFF87171) : const Color(0xFF00B4D8)),
                          const SizedBox(width: 4),
                          Text(hasConflicts ? 'Resolve Conflicts' : 'AI Suggest Times',
                            style: TextStyle(color: hasConflicts ? const Color(0xFFF87171) : const Color(0xFF00B4D8), fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),

              ],
            ),
          ),

          // Time summary bar
          if (currentDayItems.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: TriaColors.cardBgAlt(isDark).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timeline, size: 14, color: Color(0xFF60A5FA)),
                  const SizedBox(width: 6),
                  Text(
                    '${currentDayItems.first.scheduledTime} — ${currentDayItems.last.endTime}',
                    style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${currentDayItems.fold<int>(0, (sum, item) => sum + item.place.durationMinutes)} min total',
                    style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),

          // Scheduled items for current day (Visual chronological timeline + bookings + activities)
          Expanded(
            child: timelineItems.isEmpty && unassigned.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today, size: 48, color: Color(0xFF334155)),
                        const SizedBox(height: 12),
                        const Text('No activities scheduled',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text('Assign places from below',
                          style: TextStyle(color: Color(0xFF475569), fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : _isTimelineCalendarView
                    ? _buildHourlyCalendarTimeline(timelineItems, unassigned)
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        buildDefaultDragHandles: false,
                        itemCount: timelineItems.length + (unassigned.isNotEmpty ? 1 + unassigned.length : 0),
                        onReorderItem: (oldIndex, newIndex) {
                          if (oldIndex < timelineItems.length) {
                            final draggedItem = timelineItems[oldIndex];
                            if (draggedItem.isBooking || draggedItem.cost == 'free-slot') return; // Locked

                            final List<TimelineItem> listCopy = List.from(timelineItems);
                            final item = listCopy.removeAt(oldIndex);
                            final clampedNewIndex = newIndex.clamp(0, listCopy.length);
                            listCopy.insert(clampedNewIndex, item);

                            int targetActivityIndex = 0;
                            for (int i = 0; i < clampedNewIndex; i++) {
                              final currentItem = listCopy[i];
                              if (!currentItem.isBooking && currentItem.cost != 'free-slot') {
                                targetActivityIndex++;
                              }
                            }

                            final oldActivityIndex = currentDayItems.indexWhere(
                              (item) => item.place.id == draggedItem.activity!.place.id,
                            );
                            if (oldActivityIndex >= 0) {
                              ref.read(dayScheduleProvider.notifier).reorderAttractionsInDay(
                                _activeDay,
                                oldActivityIndex,
                                targetActivityIndex,
                                bookings,
                              );
                            }
                          }
                        },
                        itemBuilder: (ctx, idx) {
                          // Unified timeline items
                          if (idx < timelineItems.length) {
                            final item = timelineItems[idx];
                            if (item.cost == 'free-slot') {
                              return _freeSlotItemCard(item, key: ValueKey(item.id));
                            } else if (item.isBooking) {
                              return _bookingItemCard(item, key: ValueKey(item.id));
                            } else {
                              final activity = item.activity!;
                              final warnings = dayWarnings[activity.place.id];
                              final displayIdx = currentDayItems.indexWhere(
                                (x) => x.place.id == activity.place.id,
                              );
                              return _scheduledItemCard(activity, idx, displayIdx, warnings, key: ValueKey(activity.place.id));
                            }
                          }

                          // Separator header
                          if (idx == timelineItems.length && unassigned.isNotEmpty) {
                            return Container(
                              key: const ValueKey('unassigned-header'),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                children: [
                                  Container(
                                    height: 1,
                                    width: 30,
                                    color: TriaColors.border(isDark),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('UNASSIGNED PLACES',
                                      style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: TriaColors.border(isDark),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Unassigned items
                          final unassignedIdx = idx - timelineItems.length - 1;
                          if (unassignedIdx >= 0 && unassignedIdx < unassigned.length) {
                            final place = unassigned[unassignedIdx];
                            return _unassignedCard(place, key: ValueKey('unassigned-${place.id}'));
                          }

                          return const SizedBox.shrink(key: ValueKey('empty'));
                        },
                      ),
          ),

          // Bottom bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TriaColors.dialogBg(isDark),
              border: Border(top: BorderSide(color: TriaColors.border(isDark))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Stats
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: unassigned.isEmpty
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          unassigned.isEmpty ? Icons.check_circle : Icons.warning,
                          color: unassigned.isEmpty ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          unassigned.isEmpty ? 'All assigned' : '${unassigned.length} unassigned',
                          style: TextStyle(
                            color: unassigned.isEmpty ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            fontWeight: FontWeight.bold, fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          // Build draft itinerary
                          final draft = DraftItinerary(
                            bookings: bookings,
                            daySchedules: schedule,
                          );
                          ref.read(draftItineraryProvider.notifier).state = draft;
                          context.push('/itinerary-wizard/preview');
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('PREVIEW DRAFT',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.3),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduledItemCard(DayScheduleItem item, int timelineIndex, int displayIndex, List<String>? warnings, {required Key key}) {
    final isDark = ref.watch(isDarkProvider);
    final hasWarning = warnings != null && warnings.isNotEmpty;
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: hasWarning ? const Color(0xFF7F1D1D).withValues(alpha: 0.2) : TriaColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hasWarning ? const Color(0xFFEF4444).withValues(alpha: 0.8) : TriaColors.border(isDark)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Drag handle + Timeline
              Container(
                width: 44,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    ReorderableDragStartListener(
                      index: timelineIndex,
                      child: const Icon(Icons.drag_handle, color: Color(0xFF64748B), size: 20),
                    ),
                    const SizedBox(height: 8),
                    Text('${displayIndex + 1}',
                      style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ],
                ),
              ),
              // Photo thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: (item.place.imageUrl.isNotEmpty && (item.place.imageUrl.startsWith('http://') || item.place.imageUrl.startsWith('https://')))
                    ? Image.network(
                        item.place.imageUrl,
                        width: 56, height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => Container(
                          width: 56, height: 56,
                          color: TriaColors.border(isDark),
                          child: Icon(Icons.image, color: TriaColors.textMuted(isDark), size: 24),
                        ),
                      )
                    : Container(
                        width: 56, height: 56,
                        color: TriaColors.border(isDark),
                        child: Icon(Icons.image, color: TriaColors.textMuted(isDark), size: 24),
                      ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.place.name,
                      style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasWarning) ...[
                      const SizedBox(height: 4),
                      ...warnings.map((w) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFFCA5A5), size: 10),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                w,
                                style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Time range button
                        GestureDetector(
                          onTap: () => _showTimePicker(_activeDay, item.place.id, item.scheduledTime),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule, size: 11, color: Color(0xFF60A5FA)),
                                const SizedBox(width: 3),
                                Text('${item.scheduledTime} – ${item.endTime}',
                                  style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${item.place.durationMinutes}min',
                            style: const TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              Column(
                children: [
                  GestureDetector(
                    onTap: () => _showMoveToDaySheet(_activeDay, item.place.id),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.swap_horiz, color: Color(0xFFF59E0B), size: 18),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ref.read(dayScheduleProvider.notifier).removeFromDay(_activeDay, item.place.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.remove_circle_outline, color: Color(0xFFEF4444), size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          // Duration bar (visual time-block indicator)
          Container(
            margin: const EdgeInsets.only(left: 44, right: 8, bottom: 8),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2563EB),
                  const Color(0xFF2563EB).withValues(alpha: 0.3),
                ],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Show proportional bar (max 4 hours = 240 min)
                final fraction = (item.place.durationMinutes / 240).clamp(0.1, 1.0);
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyCalendarTimeline(List<TimelineItem> timelineItems, List<ExplorePlaceItem> unassigned) {
    final isDark = ref.watch(isDarkProvider);
    const double hourHeight = 90.0;

    // Sort and calculate overlap columns for side-by-side display of non-free-slot items
    final positionedItems = timelineItems.where((item) => item.cost != 'free-slot').toList();
    positionedItems.sort((a, b) {
      final startA = parseTimeToMinutes(a.time);
      final startB = parseTimeToMinutes(b.time);
      if (startA != startB) return startA.compareTo(startB);
      final endA = parseTimeToMinutes(a.endTime);
      final endB = parseTimeToMinutes(b.endTime);
      return (endB - startB).compareTo(endA - startA);
    });

    final Map<TimelineItem, int> itemColIndex = {};
    final Map<TimelineItem, int> itemTotalCols = {};
    final List<List<TimelineItem>> groups = [];
    List<TimelineItem> currentGroup = [];
    int currentGroupMaxEnd = 0;

    for (final item in positionedItems) {
      final start = parseTimeToMinutes(item.time);
      final end = parseTimeToMinutes(item.endTime);
      
      if (currentGroup.isEmpty) {
        currentGroup = [item];
        currentGroupMaxEnd = end;
        groups.add(currentGroup);
      } else if (start < currentGroupMaxEnd) {
        currentGroup.add(item);
        if (end > currentGroupMaxEnd) {
          currentGroupMaxEnd = end;
        }
      } else {
        currentGroup = [item];
        currentGroupMaxEnd = end;
        groups.add(currentGroup);
      }
    }

    for (final group in groups) {
      final List<int> colEndTimes = [];
      for (final item in group) {
        final start = parseTimeToMinutes(item.time);
        final end = parseTimeToMinutes(item.endTime);
        
        int col = 0;
        while (col < colEndTimes.length && colEndTimes[col] > start) {
          col++;
        }
        
        if (col < colEndTimes.length) {
          colEndTimes[col] = end;
        } else {
          colEndTimes.add(end);
        }
        
        itemColIndex[item] = col;
      }
      
      final totalCols = colEndTimes.length;
      for (final item in group) {
        itemTotalCols[item] = totalCols;
      }
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _timelineScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hour labels column
                Column(
                  children: List.generate(26, (index) {
                    final hour = index;
                    final displayHour = hour == 0
                        ? '12 AM'
                        : hour == 12
                            ? '12 PM'
                            : hour == 24
                                ? '12 AM*'
                                : hour == 25
                                    ? '1 AM*'
                                    : hour > 24
                                        ? '${hour - 24} AM*'
                                        : hour > 12
                                            ? '${hour - 12} PM'
                                            : '$hour AM';
                    return Container(
                      height: hourHeight,
                      width: 50,
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.only(right: 8, top: 4),
                      child: Text(
                        displayHour,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                ),
                
                // Timeline grid and items column
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double totalWidth = constraints.maxWidth;
                      double safeTotalWidth = totalWidth;
                      if (safeTotalWidth.isInfinite || safeTotalWidth.isNaN || safeTotalWidth <= 0) {
                        safeTotalWidth = 350.0;
                      }
                      return Stack(
                        children: [
                          // Horizontal grid lines as DragTargets
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: List.generate(26, (hourIndex) {
                              return Builder(
                                builder: (rowContext) {
                                  return DragTarget<Object>(
                                    onWillAcceptWithDetails: (details) {
                                      return details.data is ExplorePlaceItem || details.data is DayScheduleItem;
                                    },
                                    onAcceptWithDetails: (details) {
                                      final renderObject = rowContext.findRenderObject();
                                      if (renderObject is! RenderBox) return;
                                      final RenderBox renderBox = renderObject;
                                      final localOffset = renderBox.globalToLocal(details.offset);
                                      final dy = localOffset.dy;
                                      final minuteOffset = dy < 45.0 ? 0 : 30;
                                      final targetStartMin = hourIndex * 60 + minuteOffset;
                                      final targetTimeStr = minutesToTimeString(targetStartMin);
                                      
                                      final data = details.data;
                                      if (data is ExplorePlaceItem) {
                                        final place = data;
                                        final duration = place.durationMinutes;
                                        final isFree = ref.read(dayScheduleProvider.notifier).isTimeSlotFree(
                                          _activeDay, targetStartMin, duration,
                                        );
                                        
                                        if (isFree) {
                                          ref.read(dayScheduleProvider.notifier).addToDayAtTime(
                                            _activeDay, place, targetTimeStr,
                                          );
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Scheduled ${place.name} at $targetTimeStr'),
                                              backgroundColor: const Color(0xFF10B981),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        } else {
                                          // Find overlapping items
                                          final activeDayItems = ref.read(dayScheduleProvider)[_activeDay];
                                          final conflicts = activeDayItems.where((i) {
                                            final sMin = i.startMinutes;
                                            final eMin = i.endMinutes;
                                            return targetStartMin < eMin && (targetStartMin + duration) > sMin;
                                          }).toList();
                                          
                                          if (conflicts.length == 1) {
                                            final conflictItem = conflicts.first;
                                            ref.read(dayScheduleProvider.notifier).removeFromDay(_activeDay, conflictItem.place.id);
                                            ref.read(dayScheduleProvider.notifier).addToDayAtTime(_activeDay, place, targetTimeStr);
                                            
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Replaced ${conflictItem.place.name} with ${place.name} at $targetTimeStr'),
                                                backgroundColor: const Color(0xFF10B981),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: const Text('Slot occupied by multiple activities'),
                                                backgroundColor: const Color(0xFFEF4444),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                      } else if (data is DayScheduleItem) {
                                        final item = data;
                                        final duration = item.place.durationMinutes;
                                        final placeId = item.place.id;
                                        final isFree = ref.read(dayScheduleProvider.notifier).isTimeSlotFree(
                                          _activeDay, targetStartMin, duration, excludePlaceId: placeId,
                                        );
                                        
                                        if (isFree) {
                                          final success = ref.read(dayScheduleProvider.notifier).updateTime(
                                            _activeDay, placeId, targetTimeStr,
                                          );
                                          if (success) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Moved ${item.place.name} to $targetTimeStr'),
                                                backgroundColor: const Color(0xFF10B981),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        } else {
                                          // Find overlapping items excluding self
                                          final activeDayItems = ref.read(dayScheduleProvider)[_activeDay];
                                          final conflicts = activeDayItems.where((i) {
                                            if (i.place.id == placeId) return false;
                                            final sMin = i.startMinutes;
                                            final eMin = i.endMinutes;
                                            return targetStartMin < eMin && (targetStartMin + duration) > sMin;
                                          }).toList();
                                          
                                          if (conflicts.length == 1) {
                                            final conflictItem = conflicts.first;
                                            final success = ref.read(dayScheduleProvider.notifier).swapActivities(
                                              _activeDay, placeId, _activeDay, conflictItem.place.id,
                                            );
                                            if (success) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Swapped ${item.place.name} and ${conflictItem.place.name}'),
                                                  backgroundColor: const Color(0xFF10B981),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: const Text('Cannot swap — new times would overlap other activities'),
                                                  backgroundColor: const Color(0xFFEF4444),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: const Text('Slot occupied by multiple activities'),
                                                backgroundColor: const Color(0xFFEF4444),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    builder: (context, candidateData, rejectedData) {
                                      final isOver = candidateData.isNotEmpty;
                                      return Container(
                                        height: hourHeight,
                                        decoration: BoxDecoration(
                                          color: isOver ? const Color(0xFF00B4D8).withValues(alpha: 0.1) : null,
                                          border: const Border(
                                            top: BorderSide(color: Color(0xFF1A2744), width: 1),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            }),
                          ),
                          
                          // Positioned cards
                          ...timelineItems.map((item) {
                            final startMin = parseTimeToMinutes(item.time);
                            final endMin = parseTimeToMinutes(item.endTime);
                            final duration = endMin - startMin;
                            // Clamp visual duration to at least 30 minutes (45 pixels height) to prevent text overflow warnings
                            final visualDuration = duration.clamp(30, 1440);
                            
                            final top = startMin * (hourHeight / 60.0);
                            final height = visualDuration * (hourHeight / 60.0);
                            
                            final baseCard = _buildTimelineCalendarCard(item);

                            Widget dragTargetCard = baseCard;

                            // Wrap non-booking cards in DragTargets so drops directly onto cards work
                            if (!item.isBooking) {
                              dragTargetCard = DragTarget<Object>(
                                onWillAcceptWithDetails: (details) {
                                  final data = details.data;
                                  if (data is ExplorePlaceItem) return true;
                                  if (data is DayScheduleItem) {
                                    // Exclude dropping onto itself
                                    if (item.activity != null && item.activity!.place.id == data.place.id) {
                                      return false;
                                    }
                                    return true;
                                  }
                                  return false;
                                },
                                onAcceptWithDetails: (details) {
                                  final data = details.data;
                                  if (item.cost == 'free-slot') {
                                    final targetTimeStr = item.time;
                                    final targetStartMin = parseTimeToMinutes(targetTimeStr);
                                    if (data is ExplorePlaceItem) {
                                      final isFree = ref.read(dayScheduleProvider.notifier).isTimeSlotFree(
                                        _activeDay, targetStartMin, data.durationMinutes,
                                      );
                                      if (isFree) {
                                        ref.read(dayScheduleProvider.notifier).addToDayAtTime(
                                          _activeDay, data, targetTimeStr,
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Scheduled ${data.name} at $targetTimeStr'),
                                            backgroundColor: const Color(0xFF10B981),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      } else {
                                        final activeDayItems = ref.read(dayScheduleProvider)[_activeDay];
                                        final conflicts = activeDayItems.where((i) {
                                          final sMin = i.startMinutes;
                                          final eMin = i.endMinutes;
                                          return targetStartMin < eMin && (targetStartMin + data.durationMinutes) > sMin;
                                        }).toList();
                                        
                                        if (conflicts.length == 1) {
                                          final conflictItem = conflicts.first;
                                          ref.read(dayScheduleProvider.notifier).removeFromDay(_activeDay, conflictItem.place.id);
                                          ref.read(dayScheduleProvider.notifier).addToDayAtTime(_activeDay, data, targetTimeStr);
                                          
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Replaced ${conflictItem.place.name} with ${data.name} at $targetTimeStr'),
                                              backgroundColor: const Color(0xFF10B981),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text('Slot occupied by multiple activities'),
                                              backgroundColor: const Color(0xFFEF4444),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      }
                                    } else if (data is DayScheduleItem) {
                                      final isFree = ref.read(dayScheduleProvider.notifier).isTimeSlotFree(
                                        _activeDay, targetStartMin, data.place.durationMinutes, excludePlaceId: data.place.id,
                                      );
                                      if (isFree) {
                                        final success = ref.read(dayScheduleProvider.notifier).updateTime(
                                          _activeDay, data.place.id, targetTimeStr,
                                        );
                                        if (success) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Moved ${data.place.name} to $targetTimeStr'),
                                              backgroundColor: const Color(0xFF10B981),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      } else {
                                        final activeDayItems = ref.read(dayScheduleProvider)[_activeDay];
                                        final conflicts = activeDayItems.where((i) {
                                          if (i.place.id == data.place.id) return false;
                                          final sMin = i.startMinutes;
                                          final eMin = i.endMinutes;
                                          return targetStartMin < eMin && (targetStartMin + data.place.durationMinutes) > sMin;
                                        }).toList();
                                        
                                        if (conflicts.length == 1) {
                                          final conflictItem = conflicts.first;
                                          final success = ref.read(dayScheduleProvider.notifier).swapActivities(
                                            _activeDay, data.place.id, _activeDay, conflictItem.place.id,
                                          );
                                          if (success) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Swapped ${data.place.name} and ${conflictItem.place.name}'),
                                                backgroundColor: const Color(0xFF10B981),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: const Text('Cannot swap — new times would overlap other activities'),
                                                backgroundColor: const Color(0xFFEF4444),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text('Slot occupied by multiple activities'),
                                              backgroundColor: const Color(0xFFEF4444),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  } else if (item.activity != null) {
                                    final targetActivity = item.activity!;
                                    final targetTimeStr = targetActivity.scheduledTime;
                                    if (data is ExplorePlaceItem) {
                                      ref.read(dayScheduleProvider.notifier).removeFromDay(_activeDay, targetActivity.place.id);
                                      ref.read(dayScheduleProvider.notifier).addToDayAtTime(_activeDay, data, targetTimeStr);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Replaced ${targetActivity.place.name} with ${data.name}'),
                                          backgroundColor: const Color(0xFF10B981),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    } else if (data is DayScheduleItem) {
                                      final success = ref.read(dayScheduleProvider.notifier).swapActivities(
                                        _activeDay, data.place.id, _activeDay, targetActivity.place.id,
                                      );
                                      if (success) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Swapped ${data.place.name} and ${targetActivity.place.name}'),
                                            backgroundColor: const Color(0xFF10B981),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Cannot swap — new times would overlap other activities'),
                                            backgroundColor: const Color(0xFFEF4444),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                                builder: (context, candidateData, rejectedData) {
                                  final isOver = candidateData.isNotEmpty;
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: isOver ? [
                                        BoxShadow(
                                          color: const Color(0xFF00B4D8).withValues(alpha: 0.4),
                                          blurRadius: 6,
                                          spreadRadius: 2,
                                        )
                                      ] : null,
                                    ),
                                    child: baseCard,
                                  );
                                },
                              );
                            }

                            Widget finalCard = dragTargetCard;

                            // Wrap visual activities in Draggable
                            if (item.activity != null && !item.isBooking) {
                              finalCard = Draggable<DayScheduleItem>(
                                data: item.activity!,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: SizedBox(
                                    width: 280,
                                    height: height,
                                    child: _buildTimelineCalendarCard(item),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: _buildTimelineCalendarCard(item),
                                ),
                                child: dragTargetCard,
                              );
                            }
                            
                            // Visual horizontal column layout side-by-side positioning
                            final isFreeSlot = item.cost == 'free-slot';
                            final col = isFreeSlot ? 0 : (itemColIndex[item] ?? 0);
                            final total = isFreeSlot ? 1 : (itemTotalCols[item] ?? 1);
                            
                            final int safeTotal = total <= 0 ? 1 : total;
                            final double colWidth = ((safeTotalWidth - 8) / safeTotal).clamp(0.0, double.infinity);
                            final double left = 4 + col * colWidth;

                            return Positioned(
                              top: top,
                              left: left,
                              width: colWidth,
                              height: height,
                              child: finalCard,
                            );
                          }),
                        ],
                      );
                    }
                  ),
                ),
              ],
            ),
          ),
        ),
        if (unassigned.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(height: 1, width: 30, color: TriaColors.border(isDark)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('UNASSIGNED PLACES',
                    style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                  ),
                ),
                Expanded(child: Container(height: 1, color: TriaColors.border(isDark))),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: unassigned.length,
              itemBuilder: (ctx, uidx) {
                final place = unassigned[uidx];
                return _unassignedCard(place, key: ValueKey('unassigned-${place.id}'));
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimelineCalendarCard(TimelineItem item) {
    final isDark = ref.watch(isDarkProvider);
    final startMin = parseTimeToMinutes(item.time);
    final endMin = parseTimeToMinutes(item.endTime);
    final duration = endMin - startMin;
    final isCompact = duration < 50;

    if (item.cost == 'free-slot') {
      return Container(
        decoration: BoxDecoration(
          color: TriaColors.cardBg(isDark).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: TriaColors.border(isDark).withValues(alpha: 0.4),
            style: BorderStyle.solid,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showAddPlaceToSlotSheet(_activeDay, item),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.wb_sunny_outlined, color: Color(0xFF00B4D8), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isCompact ? 'Free slot (${duration}m)' : 'Free Time Available ($duration mins)',
                      style: const TextStyle(color: Color(0xFF00B4D8), fontWeight: FontWeight.bold, fontSize: 10.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isCompact) ...[
                    const SizedBox(width: 6),
                    Text(
                      '${item.time} – ${item.endTime}',
                      style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.add, color: Color(0xFF00B4D8), size: 14),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    final isBooking = item.isBooking;
    final warningList = item.warnings;
    final hasWarning = warningList != null && warningList.isNotEmpty;

    if (isBooking) {
      return Container(
        decoration: BoxDecoration(
          color: TriaColors.cardBg(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TriaColors.border(isDark).withValues(alpha: 0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            children: [
              Icon(
                item.icon == '✈️' ? Icons.flight_land :
                item.icon == '🏨' ? Icons.hotel :
                item.icon == '🚕' ? Icons.local_taxi :
                item.icon == '💼' ? Icons.work : Icons.lock,
                color: const Color(0xFF60A5FA).withValues(alpha: 0.8),
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isCompact && item.description.isNotEmpty)
                      Text(
                        item.description,
                        style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 9.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${item.time} – ${item.endTime}',
                style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    final activity = item.activity;
    if (activity == null) {
      return Container(
        decoration: BoxDecoration(
          color: TriaColors.cardBg(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TriaColors.border(isDark).withValues(alpha: 0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: TriaColors.textMuted(isDark), size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 11.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${item.time} – ${item.endTime}',
                style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: hasWarning ? const Color(0xFF7F1D1D).withValues(alpha: 0.2) : TriaColors.cardBg(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasWarning ? const Color(0xFFEF4444).withValues(alpha: 0.8) : TriaColors.border(isDark)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAttractionActionSheet(_activeDay, activity),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                if (!isCompact) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: (activity.place.imageUrl.isNotEmpty && (activity.place.imageUrl.startsWith('http://') || activity.place.imageUrl.startsWith('https://')))
                        ? Image.network(
                            activity.place.imageUrl,
                            width: 32, height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => Container(
                              width: 32, height: 32,
                              color: TriaColors.border(isDark),
                              child: Icon(Icons.image, color: TriaColors.textMuted(isDark), size: 16),
                            ),
                          )
                        : Container(
                            width: 32, height: 32,
                            color: TriaColors.border(isDark),
                            child: Icon(Icons.image, color: TriaColors.textMuted(isDark), size: 16),
                          ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        activity.place.name,
                        style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 11.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isCompact && hasWarning)
                        Text(
                          warningList.first,
                          style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 9, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        )
                      else if (!isCompact)
                        Text(
                          '${activity.place.durationMinutes} mins',
                          style: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 9),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.time} – ${item.endTime}',
                        style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),

                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<TimelineItem> buildTimelineItems(int dayIdx, List<DayScheduleItem> dayItems, TripBookings bookings, Map<String, List<String>> dayWarnings) {
    final List<TimelineItem> items = [];
    final baseStart = getBaseStartDate(bookings);
    final dayDate = baseStart.add(Duration(days: dayIdx));
    final dateStr = '${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}';

    final arrivingFlights = bookings.flights.where((f) {
      final arrD = f.arrivalDate.isNotEmpty ? f.arrivalDate : f.departureDate;
      return arrD == dateStr;
    }).toList();

    final departingFlights = bookings.flights.where((f) => f.departureDate == dateStr).toList();
    final checkingInHotels = bookings.hotels.where((h) => h.checkInDate == dateStr).toList();
    final checkingOutHotels = bookings.hotels.where((h) => h.checkOutDate == dateStr).toList();

    final activeHotelsForNight = bookings.hotels.where((h) {
      try {
        final checkIn = DateTime.parse(h.checkInDate);
        final checkOut = DateTime.parse(h.checkOutDate);
        final dDate = DateTime(dayDate.year, dayDate.month, dayDate.day);
        final ci = DateTime(checkIn.year, checkIn.month, checkIn.day);
        final co = DateTime(checkOut.year, checkOut.month, checkOut.day);
        return (dDate.isAtSameMomentAs(ci) || dDate.isAfter(ci)) && dDate.isBefore(co);
      } catch (_) {
        return false;
      }
    }).toList();

    final prevDayDate = dayDate.subtract(const Duration(days: 1));
    final activeHotelsForPrevNight = bookings.hotels.where((h) {
      try {
        final checkIn = DateTime.parse(h.checkInDate);
        final checkOut = DateTime.parse(h.checkOutDate);
        final dDate = DateTime(prevDayDate.year, prevDayDate.month, prevDayDate.day);
        final ci = DateTime(checkIn.year, checkIn.month, checkIn.day);
        final co = DateTime(checkOut.year, checkOut.month, checkOut.day);
        return (dDate.isAtSameMomentAs(ci) || dDate.isAfter(ci)) && dDate.isBefore(co);
      } catch (_) {
        return false;
      }
    }).toList();

    // 1. Day 1 Flight Arrival Start Constraint
    if (dayIdx == 0 && arrivingFlights.isNotEmpty) {
      final flight = arrivingFlights.first;
      final arrivalTimeStr = flight.arrivalTime.isNotEmpty ? flight.arrivalTime : '10:00 AM';
      final arrMin = parseTimeToMinutes(arrivalTimeStr);

      items.add(TimelineItem(
        id: 'flight-arr-${flight.pnr}',
        time: arrivalTimeStr,
        endTime: arrivalTimeStr,
        title: '✈️ Flight Arrival: ${flight.airline}',
        description: 'Flight arrives at ${flight.arrivalCity} Airport.',
        isBooking: true,
        icon: '✈️',
        placeDetails: '${flight.seatClass} Class • ${flight.passengers} Passengers',
        ticketInfo: flight.pnr.isNotEmpty ? 'PNR: ${flight.pnr}' : null,
      ));

      items.add(TimelineItem(
        id: 'airport-proc-${flight.pnr}',
        time: arrivalTimeStr,
        endTime: minutesToTimeString(arrMin + 60),
        title: '✈️ Airport Customs & Baggage',
        description: 'Baggage collection, immigration checks, and terminal clearance.',
        isBooking: true,
        icon: '✈️',
        placeDetails: '60-min airport processing buffer',
      ));

      final destinationHotel = checkingInHotels.isNotEmpty 
          ? checkingInHotels.first 
          : (activeHotelsForNight.isNotEmpty ? activeHotelsForNight.first : null);

      if (destinationHotel != null) {
        items.add(TimelineItem(
          id: 'airport-transfer-${destinationHotel.hotelName}',
          time: minutesToTimeString(arrMin + 60),
          endTime: minutesToTimeString(arrMin + 105),
          title: '🚕 Transfer to Hotel',
          description: 'Commute to ${destinationHotel.hotelName}.',
          isBooking: true,
          icon: '🚕',
          placeDetails: '45-min transit time',
          cost: '\$25-40 estimated cost',
          transport: 'Taxi / Airport Shuttle',
        ));

        final hotelCheckInMin = parseTimeToMinutes(destinationHotel.checkInTime.isNotEmpty ? destinationHotel.checkInTime : '03:00 PM');
        if (arrMin + 105 < hotelCheckInMin) {
          items.add(TimelineItem(
            id: 'luggage-drop-${destinationHotel.hotelName}',
            time: minutesToTimeString(arrMin + 105),
            endTime: minutesToTimeString(arrMin + 135),
            title: '💼 Luggage Drop at Hotel',
            description: 'Arrived early before official check-in time. Store luggage at front desk.',
            isBooking: true,
            icon: '💼',
            placeDetails: '30-min settlement',
          ));

          items.add(TimelineItem(
            id: 'hotel-ci-${destinationHotel.hotelName}',
            time: minutesToTimeString(hotelCheckInMin),
            endTime: minutesToTimeString(hotelCheckInMin + 30),
            title: '🏨 Hotel Check-in: ${destinationHotel.hotelName}',
            description: 'Room key pickup at ${destinationHotel.hotelName}. Room: ${destinationHotel.roomType}',
            isBooking: true,
            icon: '🏨',
            placeDetails: 'Official check-in window opens',
            ticketInfo: destinationHotel.confirmationCode.isNotEmpty ? 'Ref: ${destinationHotel.confirmationCode}' : null,
          ));
        } else {
          items.add(TimelineItem(
            id: 'hotel-ci-${destinationHotel.hotelName}',
            time: minutesToTimeString(arrMin + 105),
            endTime: minutesToTimeString(arrMin + 135),
            title: '🏨 Hotel Check-in: ${destinationHotel.hotelName}',
            description: 'Check-in at ${destinationHotel.hotelName}. Room: ${destinationHotel.roomType}',
            isBooking: true,
            icon: '🏨',
            placeDetails: '30-min check-in',
            ticketInfo: destinationHotel.confirmationCode.isNotEmpty ? 'Ref: ${destinationHotel.confirmationCode}' : null,
          ));
        }
      } else {
        items.add(TimelineItem(
          id: 'airport-transfer-city',
          time: minutesToTimeString(arrMin + 60),
          endTime: minutesToTimeString(arrMin + 105),
          title: '🚕 Transfer to City Center',
          description: 'Commute from airport to downtown ${flight.arrivalCity}.',
          isBooking: true,
          icon: '🚕',
          placeDetails: '45-min transit time',
          cost: '\$15-30 estimated cost',
          transport: 'Metro / Taxi',
        ));
      }
    } else {
      // Normal Morning Prep
      if (dayIdx > 0) {
        if (activeHotelsForPrevNight.isNotEmpty) {
          final prevHotel = activeHotelsForPrevNight.first;
          items.add(TimelineItem(
            id: 'morning-prep-${prevHotel.hotelName}',
            time: '08:00 AM',
            endTime: '09:00 AM',
            title: '🌅 Morning breakfast at Hotel',
            description: 'Breakfast and preparation at ${prevHotel.hotelName}.',
            isBooking: true,
            icon: '🌅',
          ));
        } else {
          items.add(TimelineItem(
            id: 'morning-prep-general',
            time: '08:00 AM',
            endTime: '09:00 AM',
            title: '🌅 Morning Preparation',
            description: 'Prepare for the day ahead.',
            isBooking: true,
            icon: '🌅',
          ));
        }
      }
    }

    // 2. Hotel Check-outs
    for (final hotel in checkingOutHotels) {
      final coTimeStr = hotel.checkOutTime.isNotEmpty ? hotel.checkOutTime : '11:00 AM';
      final coMin = parseTimeToMinutes(coTimeStr);

      if (checkingInHotels.isNotEmpty) {
        // Hotel change transition
        final hotelB = checkingInHotels.first;
        items.add(TimelineItem(
          id: 'hotel-co-${hotel.hotelName}',
          time: minutesToTimeString(coMin),
          endTime: minutesToTimeString(coMin + 30),
          title: '🏨 Hotel Check-out: ${hotel.hotelName}',
          description: 'Settle final bills and checkout.',
          isBooking: true,
          icon: '🏨',
        ));

        items.add(TimelineItem(
          id: 'packing-transition',
          time: minutesToTimeString(coMin + 30),
          endTime: minutesToTimeString(coMin + 60),
          title: '💼 Pack Bags & Transition',
          description: 'Organize luggage and prepare for hotel swap.',
          isBooking: true,
          icon: '💼',
        ));

        items.add(TimelineItem(
          id: 'hotel-to-hotel-transfer',
          time: minutesToTimeString(coMin + 60),
          endTime: minutesToTimeString(coMin + 90),
          title: '🚕 Transfer between Hotels',
          description: 'Transit from ${hotel.hotelName} to ${hotelB.hotelName}.',
          isBooking: true,
          icon: '🚕',
          cost: '\$15-25 estimated cost',
          transport: 'Taxi / Metro',
        ));

        items.add(TimelineItem(
          id: 'luggage-drop-${hotelB.hotelName}',
          time: minutesToTimeString(coMin + 90),
          endTime: minutesToTimeString(coMin + 120),
          title: '💼 Luggage Drop at new Hotel',
          description: 'Drop bags at front desk of ${hotelB.hotelName} before rooms are ready.',
          isBooking: true,
          icon: '💼',
        ));

        final ciMinB = parseTimeToMinutes(hotelB.checkInTime.isNotEmpty ? hotelB.checkInTime : '03:00 PM');
        items.add(TimelineItem(
          id: 'hotel-ci-${hotelB.hotelName}',
          time: minutesToTimeString(ciMinB),
          endTime: minutesToTimeString(ciMinB + 30),
          title: '🏨 Hotel Check-in: ${hotelB.hotelName}',
          description: 'Check-in and key pickup. Room: ${hotelB.roomType}',
          isBooking: true,
          icon: '🏨',
          ticketInfo: hotelB.confirmationCode.isNotEmpty ? 'Ref: ${hotelB.confirmationCode}' : null,
        ));
      } else {
        // Simple Checkout
        items.add(TimelineItem(
          id: 'hotel-co-${hotel.hotelName}',
          time: minutesToTimeString(coMin),
          endTime: minutesToTimeString(coMin + 30),
          title: '🏨 Hotel Check-out: ${hotel.hotelName}',
          description: 'Checkout and settle bills from ${hotel.hotelName}.',
          isBooking: true,
          icon: '🏨',
        ));
      }
    }

    // 3. Normal Hotel Check-in (when not covered by arriving flight & no hotel swap)
    if (dayIdx == 0 && arrivingFlights.isEmpty && checkingInHotels.isNotEmpty) {
      for (final hotel in checkingInHotels) {
        final ciTimeStr = hotel.checkInTime.isNotEmpty ? hotel.checkInTime : '03:00 PM';
        final ciMin = parseTimeToMinutes(ciTimeStr);
        items.add(TimelineItem(
          id: 'hotel-ci-normal-${hotel.hotelName}',
          time: ciTimeStr,
          endTime: minutesToTimeString(ciMin + 30),
          title: '🏨 Hotel Check-in: ${hotel.hotelName}',
          description: 'Check-in and settle bags at ${hotel.hotelName}. Room: ${hotel.roomType}',
          isBooking: true,
          icon: '🏨',
          ticketInfo: hotel.confirmationCode.isNotEmpty ? 'Ref: ${hotel.confirmationCode}' : null,
        ));
      }
    }

    // 4. Departing Flight
    if (departingFlights.isNotEmpty) {
      final flight = departingFlights.first;
      final depTimeStr = flight.departureTime.isNotEmpty ? flight.departureTime : '06:00 PM';
      final depMin = parseTimeToMinutes(depTimeStr);

      items.add(TimelineItem(
        id: 'airport-transfer-dep',
        time: minutesToTimeString(depMin - 165),
        endTime: minutesToTimeString(depMin - 120),
        title: '🚕 Transfer to Airport',
        description: 'Commute to ${flight.departureCity} Airport for flight departure.',
        isBooking: true,
        icon: '🚕',
        placeDetails: '45-min transit time',
        cost: '\$25-40 estimated cost',
        transport: 'Airport Shuttle / Taxi',
      ));

      items.add(TimelineItem(
        id: 'airport-security-dep',
        time: minutesToTimeString(depMin - 120),
        endTime: depTimeStr,
        title: '✈️ Airport Check-in & Security',
        description: 'Flight check-in, bag drop, security checks, and gate boarding procedures.',
        isBooking: true,
        icon: '✈️',
        placeDetails: '120-min departure safety buffer',
      ));

      items.add(TimelineItem(
        id: 'flight-dep-${flight.pnr}',
        time: depTimeStr,
        endTime: depTimeStr,
        title: '✈️ Flight Departure: ${flight.airline}',
        description: 'Depart from ${flight.departureCity}. Flight to ${flight.arrivalCity}.',
        isBooking: true,
        icon: '✈️',
        placeDetails: '${flight.seatClass} Class',
        ticketInfo: flight.pnr.isNotEmpty ? 'PNR: ${flight.pnr}' : null,
      ));
    }

    // 5. Attractions (Activities)
    for (final act in dayItems) {
      final warnings = dayWarnings[act.place.id];
      items.add(TimelineItem(
        id: act.place.id,
        time: act.scheduledTime,
        endTime: act.endTime,
        title: act.place.name,
        description: act.place.description,
        isBooking: false,
        icon: '⛩️',
        activity: act,
        warnings: warnings,
      ));
    }

    // 6. Return to Hotel / Evening rest
    if (departingFlights.isEmpty && dayItems.isNotEmpty) {
      // Find the end time of the last activity
      final sortedDayItems = List<DayScheduleItem>.from(dayItems)
        ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
      final lastEndMin = sortedDayItems.last.endMinutes;

      final activeHotel = activeHotelsForNight.isNotEmpty 
          ? activeHotelsForNight.first 
          : (checkingInHotels.isNotEmpty ? checkingInHotels.first : null);

      if (activeHotel != null) {
        items.add(TimelineItem(
          id: 'return-hotel-transfer',
          time: minutesToTimeString(lastEndMin),
          endTime: minutesToTimeString(lastEndMin + 30),
          title: '🚕 Transfer to Hotel',
          description: 'Commute back to ${activeHotel.hotelName} after sightseeing.',
          isBooking: true,
          icon: '🚕',
          placeDetails: '30-min transfer',
        ));

        items.add(TimelineItem(
          id: 'evening-rest',
          time: minutesToTimeString(lastEndMin + 30),
          endTime: '11:00 PM',
          title: '🏨 Return to ${activeHotel.hotelName}',
          description: 'Evening wind-down and rest near accommodation.',
          isBooking: true,
          icon: '🏨',
        ));
      } else {
        items.add(TimelineItem(
          id: 'no-hotel-warning',
          time: minutesToTimeString(lastEndMin),
          endTime: '11:00 PM',
          title: '⚠️ No hotel booked for tonight',
          description: 'No active stay registered. Actions recommended.',
          isBooking: true,
          icon: '⚠️',
        ));
      }
    }

    // Sort chronologically by start time
    items.sort((a, b) => parseTimeToMinutes(a.time).compareTo(parseTimeToMinutes(b.time)));
    return items;
  }

  Widget _bookingItemCard(TimelineItem item, {required Key key}) {
    final isDark = ref.watch(isDarkProvider);
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TriaColors.cardBgAlt(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TriaColors.border(isDark)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon == '✈️' ? Icons.flight_land :
                  item.icon == '🏨' ? Icons.hotel :
                  item.icon == '🚕' ? Icons.local_taxi :
                  item.icon == '💼' ? Icons.work : Icons.lock,
                  color: const Color(0xFF60A5FA).withValues(alpha: 0.8),
                  size: 18,
                ),
                const SizedBox(height: 4),
                Icon(Icons.lock_outline, color: TriaColors.textMuted(isDark), size: 11),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: TriaColors.textPrimary(isDark),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: TextStyle(
                      color: TriaColors.textSecondary(isDark),
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: TriaColors.scaffoldBg(isDark),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, size: 9, color: TriaColors.textSecondary(isDark)),
                          const SizedBox(width: 4),
                          Text(
                            item.time == item.endTime ? item.time : '${item.time} – ${item.endTime}',
                            style: TextStyle(
                              color: TriaColors.textSecondary(isDark),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.placeDetails != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.placeDetails!,
                          style: const TextStyle(
                            color: Color(0xFF60A5FA),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (item.ticketInfo != null || item.cost != null || item.transport != null) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (item.ticketInfo != null)
                        _badge(Icons.confirmation_number_outlined, item.ticketInfo!, const Color(0xFF10B981)),
                      if (item.cost != null)
                        _badge(Icons.monetization_on_outlined, item.cost!, const Color(0xFFF59E0B)),
                      if (item.transport != null)
                        _badge(Icons.directions_bus_outlined, item.transport!, const Color(0xFF8B5CF6)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showResolutionPopup(Map<String, String> changes) {
    if (changes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Schedule is already fully optimized!'),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isDark = ref.read(isDarkProvider);
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: TriaColors.dialogBg(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: TriaColors.border(isDark)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SCHEDULE OPTIMIZED',
                            style: TextStyle(
                              color: TriaColors.textPrimary(isDark),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'AI Auto-Resolution Changes',
                            style: TextStyle(
                              color: TriaColors.textSecondary(isDark),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'The following activity timings were automatically adjusted to avoid overlapping logistics & operating hours:',
                  style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 11, height: 1.4),
                ),
                const SizedBox(height: 16),
                Container(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: changes.length,
                    itemBuilder: (context, index) {
                      final key = changes.keys.elementAt(index);
                      final val = changes[key]!;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 4, right: 8),
                              child: Icon(Icons.circle, size: 6, color: Color(0xFF10B981)),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    key,
                                    style: TextStyle(
                                      color: TriaColors.textPrimary(isDark),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    val,
                                    style: const TextStyle(
                                      color: Color(0xFF60A5FA),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Awesome, thanks!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _unassignedCard(ExplorePlaceItem place, {required Key key}) {
    final isDark = ref.watch(isDarkProvider);
    final cardWidget = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TriaColors.cardBg(isDark).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TriaColors.border(isDark)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: (place.imageUrl.isNotEmpty && (place.imageUrl.startsWith('http://') || place.imageUrl.startsWith('https://')))
                ? Image.network(
                    place.imageUrl,
                    width: 40, height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => Container(
                      width: 40, height: 40,
                      color: TriaColors.border(isDark),
                      child: Icon(Icons.image, color: TriaColors.textMuted(isDark), size: 20),
                    ),
                  )
                : Container(
                    width: 40, height: 40,
                    color: TriaColors.border(isDark),
                    child: Icon(Icons.image, color: TriaColors.textMuted(isDark), size: 20),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.name,
                  style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(place.genre,
                      style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 10),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: TriaColors.border(isDark).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('${place.durationMinutes}min',
                        style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Quick assign buttons for each day
          ...List.generate(
            ref.read(dayScheduleProvider).length > 4 ? 4 : ref.read(dayScheduleProvider).length,
            (dayIdx) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: GestureDetector(
                onTap: () {
                   final bookings = ref.read(tripBookingsProvider);
                   final notifier = ref.read(dayScheduleProvider.notifier);
                   final freeSlot = notifier.findFreeSlotForPlace(dayIdx, place, bookings);
                   if (freeSlot < 0) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                         content: Row(
                           children: [
                             const Icon(Icons.block, color: Colors.white, size: 16),
                             const SizedBox(width: 8),
                             Expanded(child: Text('No available free time slots on Day ${dayIdx + 1} that can fit this place.')),
                           ],
                         ),
                         backgroundColor: const Color(0xFFEF4444),
                         behavior: SnackBarBehavior.floating,
                       ),
                     );
                     return;
                   }
                   notifier.addToDay(
                     dayIdx,
                     DayScheduleItem(place: place, dayNumber: dayIdx + 1),
                     bookings,
                   );
                },
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: dayIdx == _activeDay
                        ? const Color(0xFF2563EB)
                        : TriaColors.border(isDark),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('D${dayIdx + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Draggable<ExplorePlaceItem>(
      key: key,
      data: place,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 300,
          child: cardWidget,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: cardWidget,
      ),
      child: cardWidget,
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
            color: active ? const Color(0xFF60A5FA) : TriaColors.textMuted(isDark),
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
}
