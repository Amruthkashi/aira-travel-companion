import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Timer? _reminderTimer;

  bool _useMockTime = false;
  DateTime? _mockTime;
  bool _isShowingAlert = false;
  final Set<String> _dismissedActivityAlerts = {};

  DateTime get _nowTime {
    if (_useMockTime && _mockTime != null) {
      return _mockTime!;
    }
    return DateTime.now();
  }

  @override
  void initState() {
    super.initState();
    _reminderTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {});
        _checkExceededAlerts();
      }
    });
  }

  void _checkExceededAlerts() {
    if (_isShowingAlert) return;
    
    final itinerary = ref.read(itineraryProvider);
    if (itinerary.isEmpty) return;
    
    final bookings = ref.read(tripBookingsProvider);
    final startDate = bookings.startDate;

    final now = _nowTime;
    final nowMin = now.hour * 60 + now.minute;

    int currentDayIdx = -1;
    if (startDate != null && startDate.isNotEmpty) {
      try {
        final start = DateTime.parse(startDate);
        final diff = DateTime(now.year, now.month, now.day)
            .difference(DateTime(start.year, start.month, start.day))
            .inDays;
        if (diff >= 0 && diff < itinerary.length) {
          currentDayIdx = diff;
        }
      } catch (_) {}
    }

    if (currentDayIdx == -1) {
      return; // Today is not a trip day, do not check alerts
    }

    final dayObj = itinerary[currentDayIdx];

    for (int i = 0; i < dayObj.activities.length; i++) {
      final act = dayObj.activities[i];
      if (act.activity.contains('Awaiting Departure') || act.activity.contains('Trip Completed')) {
        continue;
      }
      
      final startMin = parseTimeToMinutes(act.time);
      final regExp = RegExp(r'(\d+)\s*min');
      final match = regExp.firstMatch(act.placeDetails);
      final duration = match != null ? (int.tryParse(match.group(1)!) ?? 60) : 60;
      final endMin = startMin + duration;

      if (nowMin > endMin && nowMin <= endMin + 30) {
        final alertId = '${currentDayIdx}_${act.activity}_${act.time}';
        if (!_dismissedActivityAlerts.contains(alertId)) {
          _isShowingAlert = true;
          _dismissedActivityAlerts.add(alertId);

          ActivityItem? nextAct;
          for (int j = i + 1; j < dayObj.activities.length; j++) {
            final next = dayObj.activities[j];
            if (!next.activity.contains('Transfer') && 
                !next.activity.contains('Return to') && 
                !next.activity.contains('Awaiting') && 
                !next.activity.contains('Trip Completed')) {
              nextAct = next;
              break;
            }
          }

          final nextStr = nextAct != null 
              ? '\n\nNext Destination: "${nextAct.activity}" scheduled at ${nextAct.time}.'
              : '';

          Future.microtask(() {
            if (!mounted) return;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AlertDialog(
                  backgroundColor: const Color(0xFF0A1628),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Time Limit Exceeded',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  content: Text(
                    'You have exceeded the time slot allotted for "${act.activity}". Please complete this activity. You have to leave now to visit your next destination.$nextStr',
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                  ),
                  actions: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _isShowingAlert = false;
                      },
                      child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                );
              },
            );
          });
          break;
        }
      }
    }
  }

  void _showTimeSimulatorDialog() {
    final now = DateTime.now();
    final hourCtrl = TextEditingController(text: _mockTime != null ? _mockTime!.hour.toString() : now.hour.toString());
    final minCtrl = TextEditingController(text: _mockTime != null ? _mockTime!.minute.toString() : now.minute.toString());
    bool tempSimulate = _useMockTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0A1628),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Simulate Active Time', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: const Text('Enable Time Simulation', style: TextStyle(color: Colors.white, fontSize: 14)),
                    value: tempSimulate,
                    activeColor: const Color(0xFF2563EB),
                    onChanged: (val) {
                      setStateDialog(() {
                        tempSimulate = val ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: hourCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Hour (0-23)',
                            labelStyle: TextStyle(color: Colors.white54),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: minCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Minute (0-59)',
                            labelStyle: TextStyle(color: Colors.white54),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                  onPressed: () {
                    final h = int.tryParse(hourCtrl.text) ?? now.hour;
                    final m = int.tryParse(minCtrl.text) ?? now.minute;
                    setState(() {
                      _useMockTime = tempSimulate;
                      if (_useMockTime) {
                        _mockTime = DateTime(now.year, now.month, now.day, h, m);
                      } else {
                        _mockTime = null;
                      }
                    });
                    Navigator.pop(context);
                    _checkExceededAlerts();
                  },
                  child: const Text('Apply', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showShareItineraryDialog() {
    final itinerary = ref.read(itineraryProvider);
    if (itinerary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No itinerary available to share.')),
      );
      return;
    }

    final htmlContent = _generateHtmlItinerary(itinerary);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A1628),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Export & Share Itinerary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.share_rounded, size: 48, color: Color(0xFF00B4D8)),
              const SizedBox(height: 16),
              const Text(
                'Download your beautifully styled itinerary as an HTML file or open it to print/save as a PDF.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              Container(
                constraints: const BoxConstraints(maxHeight: 100),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2744),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const SingleChildScrollView(
                  child: Text(
                    'Your exported plan includes detailed timings, maps, attire recommendations, transport details, and budget allocations wrapped in a premium design.',
                    style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.35),
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E7C86),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (kIsWeb) {
                  try {
                    js.context.callMethod('eval', [
                      '''
                      (function(content, filename) {
                        const blob = new Blob([content], { type: 'text/html' });
                        const url = URL.createObjectURL(blob);
                        const a = document.createElement('a');
                        a.href = url;
                        a.download = filename;
                        document.body.appendChild(a);
                        a.click();
                        document.body.removeChild(a);
                        URL.revokeObjectURL(url);
                      })(${js.context['JSON'].callMethod('stringify', [htmlContent])}, 'aira_itinerary.html');
                      '''
                    ]);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('HTML file download started!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error downloading: $e')),
                    );
                  }
                } else {
                  Clipboard.setData(ClipboardData(text: htmlContent));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Itinerary HTML copied to clipboard (Downloads are web-only).')),
                  );
                }
                Navigator.pop(context);
              },
              icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
              label: const Text('Download HTML', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (kIsWeb) {
                  try {
                    js.context.callMethod('eval', [
                      '''
                      (function(content) {
                        const win = window.open('', '_blank');
                        if (win) {
                          win.document.write(content);
                          win.document.close();
                        } else {
                          alert('Please allow popups to open print version.');
                        }
                      })(${js.context['JSON'].callMethod('stringify', [htmlContent])});
                      '''
                    ]);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error opening print preview: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Print preview is only supported in web mode.')),
                  );
                }
                Navigator.pop(context);
              },
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.white),
              label: const Text('Save as PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  String _generateHtmlItinerary(List<ItineraryDay> itinerary) {
    final buffer = StringBuffer();
    buffer.write('''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Your Aira Travel Itinerary</title>
  <style>
    :root {
      --bg-color: #0B132B;
      --card-bg: #1C2541;
      --accent-blue: #3A86C8;
      --accent-cyan: #00B4D8;
      --accent-purple: #818CF8;
      --text-color: #F8FAFC;
      --text-muted: #94A3B8;
      --border-color: #334155;
    }
    
    body {
      font-family: 'Outfit', 'Segoe UI', system-ui, -apple-system, sans-serif;
      background-color: var(--bg-color);
      color: var(--text-color);
      margin: 0;
      padding: 0;
      line-height: 1.5;
    }
    
    .container {
      max-width: 800px;
      margin: 40px auto;
      padding: 0 20px;
    }
    
    header {
      text-align: center;
      margin-bottom: 40px;
      background: linear-gradient(135deg, #1E293B, #0F172A);
      padding: 30px;
      border-radius: 24px;
      border: 1px solid var(--border-color);
    }
    
    header h1 {
      margin: 0;
      font-size: 2.2em;
      font-weight: 800;
      letter-spacing: -0.5px;
      background: linear-gradient(135deg, #38BDF8, #818CF8);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    
    header p {
      color: var(--text-muted);
      margin: 10px 0 0 0;
      font-size: 1.1em;
    }
    
    .day-card {
      background-color: var(--card-bg);
      border-radius: 24px;
      padding: 24px;
      margin-bottom: 24px;
      border: 1px solid var(--border-color);
      box-shadow: 0 10px 30px rgba(0, 0, 0, 0.25);
    }
    
    .day-title {
      font-size: 1.4em;
      font-weight: 800;
      color: var(--accent-cyan);
      margin-top: 0;
      margin-bottom: 4px;
      letter-spacing: -0.3px;
    }
    
    .day-theme {
      font-size: 1.05em;
      color: var(--text-muted);
      margin-bottom: 24px;
      font-weight: 500;
    }
    
    .timeline {
      position: relative;
      border-left: 2px solid var(--border-color);
      padding-left: 24px;
      margin-left: 10px;
    }
    
    .activity-item {
      position: relative;
      margin-bottom: 28px;
    }
    
    .activity-item:last-child {
      margin-bottom: 0;
    }
    
    .timeline-dot {
      position: absolute;
      left: -33px;
      top: 4px;
      width: 16px;
      height: 16px;
      border-radius: 50%;
      background-color: var(--accent-purple);
      border: 4px solid var(--card-bg);
    }
    
    .activity-time {
      font-weight: 700;
      font-size: 0.95em;
      color: var(--accent-purple);
      margin-bottom: 4px;
    }
    
    .activity-name {
      font-size: 1.15em;
      font-weight: 700;
      color: #FFFFFF;
      margin-bottom: 6px;
    }
    
    .activity-desc {
      color: #CBD5E1;
      font-size: 0.95em;
      margin-bottom: 8px;
    }
    
    .meta-tags {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin-top: 8px;
    }
    
    .tag {
      background-color: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(255, 255, 255, 0.1);
      padding: 4px 10px;
      border-radius: 12px;
      font-size: 0.8em;
      font-weight: 600;
      color: var(--text-muted);
      display: inline-flex;
      align-items: center;
      gap: 4px;
    }
    
    .tag-location { color: var(--accent-cyan); border-color: rgba(0, 180, 216, 0.2); }
    .tag-cost { color: #F59E0B; border-color: rgba(245, 158, 11, 0.2); }
    .tag-attire { color: #EC4899; border-color: rgba(236, 72, 153, 0.2); }
    .tag-transport { color: #10B981; border-color: rgba(16, 185, 129, 0.2); }
    
    @media print {
      body {
        background-color: #FFFFFF;
        color: #0F172A;
      }
      .container {
        margin: 0;
        max-width: 100%;
        padding: 0;
      }
      header {
        background: #F1F5F9;
        border: 1px solid #CBD5E1;
      }
      header h1 {
        background: none;
        -webkit-text-fill-color: #0F172A;
        color: #0F172A;
      }
      .day-card {
        background-color: #FFFFFF;
        border: 1px solid #CBD5E1;
        box-shadow: none;
        page-break-inside: avoid;
        margin-bottom: 30px;
      }
      .day-title {
        color: #0284C7;
      }
      .activity-name {
        color: #0F172A;
      }
      .activity-desc {
        color: #334155;
      }
      .tag {
        background: #F8FAFC;
        border: 1px solid #E2E8F0;
        color: #475569;
      }
      .timeline-dot {
        border-color: #FFFFFF;
      }
    }
  </style>
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;700;800&display=swap" rel="stylesheet">
</head>
<body>
  <div class="container">
    <header>
      <h1>YOUR TRIP ITINERARY</h1>
      <p>Custom travel plan powered by Aira Travel Companion</p>
    </header>
''');

    for (final day in itinerary) {
      buffer.write('    <div class="day-card">\n');
      buffer.write('      <div class="day-title">Day ${day.day}</div>\n');
      buffer.write('      <div class="day-theme">${day.theme}</div>\n');
      buffer.write('      <div class="timeline">\n');
      for (final act in day.activities) {
        buffer.write('        <div class="activity-item">\n');
        buffer.write('          <div class="timeline-dot"></div>\n');
        buffer.write('          <div class="activity-time">${act.time}</div>\n');
        buffer.write('          <div class="activity-name">${act.activity}</div>\n');
        if (act.description.isNotEmpty) {
          buffer.write('          <div class="activity-desc">${act.description}</div>\n');
        }
        
        final metaTags = <String>[];
        if (act.locationName.isNotEmpty) {
          metaTags.add('<span class="tag tag-location">📍 ${act.locationName}</span>');
        }
        if (act.cost.isNotEmpty && act.cost != '-') {
          metaTags.add('<span class="tag tag-cost">💰 ${act.cost}</span>');
        }
        if (act.suggestedAttire.isNotEmpty) {
          metaTags.add('<span class="tag tag-attire">👚 ${act.suggestedAttire}</span>');
        }
        if (act.transport.isNotEmpty && act.transport != '-') {
          metaTags.add('<span class="tag tag-transport">🚇 ${act.transport}</span>');
        }
        
        if (metaTags.isNotEmpty) {
          buffer.write('          <div class="meta-tags">\n');
          for (final tag in metaTags) {
            buffer.write('            $tag\n');
          }
          buffer.write('          </div>\n');
        }
        buffer.write('        </div>\n');
      }
      buffer.write('      </div>\n');
      buffer.write('    </div>\n');
    }

    buffer.write('''
  </div>
</body>
</html>
''');
    return buffer.toString();
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
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
    const isDark = true;
    const bgColor = Color(0xFF0A1628);
    const cardColor = Color(0xFF1A2744);
    const textColor = Colors.white;
    const mutedTextColor = Color(0xFF94A3B8);
    const borderColor = Color(0xFF334155);
    const pillActive = Color(0xFF2563EB);
    const pillInactive = Color(0xFF1A2744);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom high-fidelity Header matching user request
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
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Share Itinerary (HTML)',
                        icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                        onPressed: _showShareItineraryDialog,
                      ),
                      IconButton(
                        tooltip: 'Simulate Time',
                        icon: Icon(
                          Icons.more_time_rounded,
                          color: _useMockTime ? Colors.amberAccent : Colors.white,
                          size: 20,
                        ),
                        onPressed: _showTimeSimulatorDialog,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Horizontal Day Tabs (Day 1 - Day 5) matching styling from reference image
            _buildHorizontalDayTabs(itinerary, pillActive, pillInactive, borderColor, textColor, mutedTextColor),

            // The main body list
            Expanded(
              child: _buildItineraryBody(itinerary, cardColor, textColor, mutedTextColor, borderColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalDayTabs(
    List<ItineraryDay> itinerary,
    Color activeBg,
    Color inactiveBg,
    Color borderCol,
    Color activeTxt,
    Color inactiveTxt,
  ) {
    if (itinerary.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 16),
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
                color: active ? activeBg : inactiveBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active ? activeBg : borderCol,
                  width: 1.2,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: activeBg.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Text(
                'Day ${idx + 1}',
                style: TextStyle(
                  color: active ? Colors.white : inactiveTxt,
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

  Widget _buildTransportSyncCard(ItineraryDay dayObj, Color textColor, Color mutedTextColor) {
    const isDark = true;

    // Detect primary event type of the day
    String syncTitle = 'DAY ${_activeDay + 1} ACTIVITY SYNC';
    String syncHeadline = 'Sightseeing Highlight';
    String syncDetails = 'No bookings registered for today.';
    IconData syncIcon = Icons.auto_awesome;
    Color titleCol = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8);
    Color cardBg = isDark ? const Color(0xFF0F1E36) : const Color(0xFFEFF6FF);
    Color borderCol = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE);

    ActivityItem? transportAct;
    ActivityItem? hotelAct;

    for (final act in dayObj.activities) {
      final actLower = act.activity.toLowerCase();
      if (actLower.contains('flight') || 
          actLower.contains('airport') || 
          actLower.contains('transit') || 
          actLower.contains('train') || 
          actLower.contains('shinkansen') || 
          actLower.contains('shuttle') || 
          actLower.contains('transport')) {
        transportAct = act;
        break;
      }
    }

    for (final act in dayObj.activities) {
      final actLower = act.activity.toLowerCase();
      if (actLower.contains('hotel') || 
          actLower.contains('check-in') || 
          actLower.contains('stay') || 
          actLower.contains('checkout') || 
          actLower.contains('lodging')) {
        hotelAct = act;
        break;
      }
    }

    if (transportAct != null) {
      // Transport Sync Card (Green theme)
      cardBg = isDark ? const Color(0xFF132A1C) : const Color(0xFFECFDF5);
      borderCol = isDark ? const Color(0xFF0F5132) : const Color(0xFFD1FAE5);
      titleCol = isDark ? const Color(0xFF75F8A9) : const Color(0xFF065F46);
      syncTitle = 'DAY ${_activeDay + 1} TRANSPORT SYNC';
      syncIcon = Icons.flight_takeoff;
      syncHeadline = transportAct.activity;
      syncDetails = 'Scheduled at ${transportAct.time} • Location: ${transportAct.locationName.isNotEmpty ? transportAct.locationName : 'Transit Station'}';
    } else if (hotelAct != null) {
      // Hotel Sync Card (Orange/Amber theme)
      cardBg = isDark ? const Color(0xFF2D1F10) : const Color(0xFFFFFBEB);
      borderCol = isDark ? const Color(0xFF6B470F) : const Color(0xFFFEF3C7);
      titleCol = isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
      syncTitle = 'DAY ${_activeDay + 1} STAY SYNC';
      syncIcon = Icons.hotel_rounded;
      syncHeadline = hotelAct.activity;
      syncDetails = 'Scheduled at ${hotelAct.time} • Destination: ${hotelAct.locationName.isNotEmpty ? hotelAct.locationName : 'Hotel Lodge'}';
    } else if (dayObj.activities.isNotEmpty) {
      // General Activity Sync Card (Blue/Purple theme)
      final primaryAct = dayObj.activities.first;
      cardBg = isDark ? const Color(0xFF1E1E38) : const Color(0xFFF5F3FF);
      borderCol = isDark ? const Color(0xFF3B0764) : const Color(0xFFEDE9FE);
      titleCol = isDark ? const Color(0xFFC084FC) : const Color(0xFF6D28D9);
      syncTitle = 'DAY ${_activeDay + 1} ITINERARY SYNC';
      syncIcon = Icons.auto_awesome_rounded;
      syncHeadline = primaryAct.activity;
      syncDetails = 'Highlight at ${primaryAct.time} • Location: ${primaryAct.locationName.isNotEmpty ? primaryAct.locationName : 'Sightseeing Area'}';
    }

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.2) : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(syncIcon, color: titleCol, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  syncTitle,
                  style: TextStyle(
                    color: titleCol,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  syncHeadline,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  syncDetails,
                  style: TextStyle(
                    color: mutedTextColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateDayNotesCard(int dayIdx, String notesText, Color cardColor, Color textColor, Color mutedTextColor, Color borderColor) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('📝', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    'Private Day Notes',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _showEditNotesDialog(dayIdx, notesText),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      color: Color(0xFF4F46E5),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notesText.isEmpty ? 'Tap Edit to add private notes for this day...' : notesText,
            style: TextStyle(
              color: notesText.isEmpty ? mutedTextColor : textColor.withOpacity(0.85),
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNotesDialog(int dayIdx, String currentNotes) {
    final notesCtrl = TextEditingController(text: currentNotes);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A1628),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Day Notes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: notesCtrl,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter notes for this day...',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2563EB))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              onPressed: () {
                ref.read(itineraryProvider.notifier).updateNotes(dayIdx, notesCtrl.text);
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget? _buildLiveReminder(List<ItineraryDay> itinerary) {
    if (itinerary.isEmpty) return null;

    final bookings = ref.read(tripBookingsProvider);
    final startDate = bookings.startDate;

    int currentDayIdx = -1;
    if (startDate != null && startDate.isNotEmpty) {
      try {
        final start = DateTime.parse(startDate);
        final today = _nowTime;
        final diff = DateTime(today.year, today.month, today.day)
            .difference(DateTime(start.year, start.month, start.day))
            .inDays;
        if (diff >= 0 && diff < itinerary.length) {
          currentDayIdx = diff;
        }
      } catch (_) {}
    }

    if (currentDayIdx == -1) {
      return null; // Today is not a trip day, do not show live reminder
    }

    final dayObj = itinerary[currentDayIdx];
    final now = _nowTime;
    final nowMin = now.hour * 60 + now.minute;

    ActivityItem? currentAct;
    ActivityItem? nextAct;
    int currentActDuration = 60;

    for (int i = 0; i < dayObj.activities.length; i++) {
      final act = dayObj.activities[i];
      if (act.activity.contains('Awaiting Departure') || act.activity.contains('Trip Completed')) {
        continue;
      }
      
      final startMin = parseTimeToMinutes(act.time);
      final regExp = RegExp(r'(\d+)\s*min');
      final match = regExp.firstMatch(act.placeDetails);
      final duration = match != null ? (int.tryParse(match.group(1)!) ?? 60) : 60;
      final endMin = startMin + duration;

      if (nowMin >= startMin && nowMin < endMin) {
        currentAct = act;
        currentActDuration = duration;
        for (int j = i + 1; j < dayObj.activities.length; j++) {
          final next = dayObj.activities[j];
          if (!next.activity.contains('Transfer') && 
              !next.activity.contains('Return to') && 
              !next.activity.contains('Awaiting') && 
              !next.activity.contains('Trip Completed')) {
            nextAct = next;
            break;
          }
        }
        break;
      }
    }

    if (currentAct != null && nextAct != null) {
      final startMin = parseTimeToMinutes(currentAct.time);
      final endMin = startMin + currentActDuration;
      
      if (nowMin >= endMin - 15) {
        return Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7F1D1D), Color(0xFF991B1B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.alarm_on, color: Color(0xFFFCA5A5), size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'TIME IS UP! LEAVE NOW',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ALERT',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'According to your plan, you should leave "${currentAct.activity}" now. It is time to travel to your next destination: "${nextAct.activity}" (scheduled at ${nextAct.time}).',
                style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF7F1D1D),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () {
                      context.push('/navigation');
                    },
                    icon: const Icon(Icons.near_me, size: 14),
                    label: const Text('Start Transit / Launch Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    }
    
    return null;
  }

  Widget _buildItineraryBody(List<ItineraryDay> itinerary, Color cardColor, Color textColor, Color mutedTextColor, Color borderColor) {
    const isDark = true;
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
                  ref.read(currentTabProvider.notifier).state = 0;
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

    final reminderWidget = _buildLiveReminder(itinerary);
    final hasReminder = reminderWidget != null;
    final int headerOffset = (hasReminder ? 1 : 0) + 3;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: dayObj.activities.length + headerOffset + 1,
      itemBuilder: (context, idx) {
        int currentIdx = idx;
        
        if (hasReminder) {
          if (currentIdx == 0) return reminderWidget!;
          currentIdx--;
        }
        
        if (currentIdx == 0) {
          return _buildTransportSyncCard(dayObj, textColor, mutedTextColor);
        }
        
        if (currentIdx == 1) {
          // General daily theme header
          return Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THEME: ${dayObj.theme.toUpperCase()}',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Toggle checklist to track your walk. Rearrange with arrow tags, add new spots, or delete unwanted slots live.',
                  style: TextStyle(
                    color: mutedTextColor,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
        }
        
        if (currentIdx == 2) {
          return _buildPrivateDayNotesCard(_activeDay, dayObj.notes, cardColor, textColor, mutedTextColor, borderColor);
        }
        
        final activityIdx = currentIdx - 3;
        
        if (activityIdx == dayObj.activities.length) {
          // Add custom itinerary item button
          return Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 32.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  foregroundColor: const Color(0xFF00B4D8),
                  backgroundColor: cardColor,
                ),
                onPressed: () => _showActivityAddModal(_activeDay),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Custom Itinerary Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          );
        }
        
        final act = dayObj.activities[activityIdx];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: act.checked ? 0.65 : 1.0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Activity Details Card matching the style of reference image
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card Header Row with custom checkbox, carets and delete button
                      Row(
                        children: [
                          // Styled Checkbox from reference image
                          GestureDetector(
                            onTap: () {
                              ref.read(itineraryProvider.notifier).toggleActivityCheck(_activeDay, activityIdx);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: act.checked ? const Color(0xFF4F46E5) : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: act.checked ? const Color(0xFF4F46E5) : mutedTextColor,
                                  width: 1.8,
                                ),
                              ),
                              child: act.checked
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          
                          // Time & Booking state label (Free/Booked)
                          Text(
                            '${act.time}  (${act.cost.contains('\$') || act.cost.contains('¥') || act.cost.contains('Booked') ? 'Booked' : 'Free'})',
                            style: const TextStyle(
                              color: Color(0xFF818CF8),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          
                          // Caret up button for reordering
                          if (activityIdx > 0)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(Icons.keyboard_arrow_up, size: 20, color: mutedTextColor),
                              onPressed: () {
                                ref.read(itineraryProvider.notifier).reorderActivity(_activeDay, activityIdx, activityIdx - 1);
                                setState(() {});
                              },
                            ),
                          
                          // Caret down button for reordering
                          if (activityIdx < dayObj.activities.length - 1)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(Icons.keyboard_arrow_down, size: 20, color: mutedTextColor),
                              onPressed: () {
                                ref.read(itineraryProvider.notifier).reorderActivity(_activeDay, activityIdx, activityIdx + 1);
                                setState(() {});
                              },
                            ),

                          const SizedBox(width: 4),

                          // Trash/Delete action button
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                            onPressed: () {
                              ref.read(itineraryProvider.notifier).deleteActivity(_activeDay, activityIdx);
                              setState(() {});
                            },
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
                          color: textColor,
                          decoration: act.checked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // Activity Description
                      if (act.description.isNotEmpty) ...[
                        Text(
                          act.description,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: textColor.withOpacity(0.75),
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
                              color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor),
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
                      
                      // Detail rows matching formatting in the reference image (pink, orange, green tags)
                      if (act.suggestedAttire.isNotEmpty) ...[
                        _buildDetailRow(
                          emoji: '👚',
                          label: 'Outfit:',
                          labelColor: const Color(0xFFEC4899),
                          text: act.suggestedAttire,
                          textColor: textColor,
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      if (act.placeDetails.isNotEmpty) ...[
                        _buildDetailRow(
                          emoji: '🍜',
                          label: 'Food:',
                          labelColor: const Color(0xFFF97316),
                          text: act.placeDetails,
                          textColor: textColor,
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      if (act.ticketInfo.isNotEmpty) ...[
                        _buildDetailRow(
                          emoji: '💡',
                          label: 'Tip:',
                          labelColor: const Color(0xFF10B981),
                          text: act.ticketInfo,
                          textColor: textColor,
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      if (act.transport.isNotEmpty) ...[
                        _buildDetailRow(
                          emoji: '🚇',
                          label: 'Transport:',
                          labelColor: const Color(0xFF06B6D4),
                          text: act.transport,
                          textColor: textColor,
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      const SizedBox(height: 4),
                      Divider(color: borderColor, height: 1),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => ref.read(itineraryProvider.notifier).swapActivityWithAi(_activeDay, activityIdx),
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

                if (activityIdx == 0 && _activeDay == 3)
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
    );
  }

  Widget _buildDetailRow({
    required String emoji,
    required String label,
    required Color labelColor,
    required String text,
    required Color textColor,
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
            style: TextStyle(
              fontSize: 12,
              color: textColor.withOpacity(0.75),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
