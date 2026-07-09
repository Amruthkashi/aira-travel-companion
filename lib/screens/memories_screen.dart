import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/theme_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/sound_synthesizer.dart';

class MemoriesScreen extends ConsumerStatefulWidget {
  const MemoriesScreen({super.key});

  @override
  ConsumerState<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends ConsumerState<MemoriesScreen> {
  final List<Map<String, dynamic>> _memories = [
    {
      'id': 'mem-1',
      'title': 'Godzilla Roar at Skyline Godzilla Hotel',
      'date': 'June 4, 2026',
      'image': 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=800&q=80',
      'journal': 'Watched the massive Godzilla head roar on the 8th floor terrace exactly on the hour. The neon lights reflecting off the wet pavement felt straight out of a sci-fi set.',
      'tags': ['West Central Tokyo', 'Godzilla', 'Cyberpunk'],
      'voiceSeconds': 12,
      'isPlayingVoice': false,
    },
    {
      'id': 'mem-2',
      'title': 'Quiet Zen Walk through Asakusa',
      'date': 'June 3, 2026',
      'image': 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?auto=format&fit=crop&w=800&q=80',
      'journal': 'Woke up at 6:00 AM to visit Senso-ji Temple before the crowds arrived. Hearing the soft chime of the wind bells and smelling the incense in the cool morning air was therapeutic.',
      'tags': ['Asakusa', 'Zen', 'Morning'],
      'voiceSeconds': 24,
      'isPlayingVoice': false,
    }
  ];

  // Recording Simulation State
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  String? _currentlyPlayingVoiceId;
  Timer? _playProgressTimer;
  double _voicePlayProgress = 0.0;

  final TextEditingController _journalTitleCtrl = TextEditingController();
  final TextEditingController _journalBodyCtrl = TextEditingController();

  void _startVoiceRecording() async {
    await SoundSynthesizer.playTone(frequency: 880, durationSeconds: 0.1, name: 'rec_start.wav');
    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
    });

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _recordSeconds++;
        if (_recordSeconds >= 5) {
          _stopVoiceRecording(save: true);
        }
      });
    });
  }

  void _stopVoiceRecording({required bool save}) async {
    _recordTimer?.cancel();
    await SoundSynthesizer.playTone(frequency: 440, durationSeconds: 0.15, name: 'rec_stop.wav');
    setState(() {
      _isRecording = false;
    });
  }

  void _playVoiceMemo(String memoryId, int totalSeconds) async {
    if (_currentlyPlayingVoiceId == memoryId) {
      // Toggle off
      _playProgressTimer?.cancel();
      setState(() {
        _currentlyPlayingVoiceId = null;
        _voicePlayProgress = 0.0;
      });
      return;
    }

    // Stop previous
    _playProgressTimer?.cancel();
    SoundSynthesizer.playTone(frequency: 600, endFrequency: 900, durationSeconds: 0.35, name: 'play_chime.wav');
    
    setState(() {
      _currentlyPlayingVoiceId = memoryId;
      _voicePlayProgress = 0.0;
    });

    _playProgressTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) return;
      setState(() {
        _voicePlayProgress += 0.2 / totalSeconds;
        if (_voicePlayProgress >= 1.0) {
          _voicePlayProgress = 0.0;
          _currentlyPlayingVoiceId = null;
          _playProgressTimer?.cancel();
          SoundSynthesizer.playTone(frequency: 500, durationSeconds: 0.1, name: 'playback_done.wav');
        }
      });
    });
  }

  void _showAddMemorySheet() {
    final isDark = ref.read(isDarkProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TriaColors.dialogBg(isDark),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'JOURNAL NEW MEMORY',
                    style: TextStyle(color: Color(0xFF00B4D8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _journalTitleCtrl,
                    style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 14, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'Give your memory a title...',
                      hintStyle: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 14),
                      fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _journalBodyCtrl,
                    style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 12),
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'What happened? Reflect on your experience...',
                      hintStyle: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 12),
                      fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Voice Recording simulator section
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: TriaColors.border(isDark)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VOICE MEMO SNAPSHOT',
                              style: TextStyle(
                                color: TriaColors.textSecondary(isDark),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isRecording ? 'Recording audio... 0:0$_recordSeconds' : 'Click mic to record 5s clip',
                              style: TextStyle(color: _isRecording ? Colors.redAccent : TriaColors.textMuted(isDark), fontSize: 10),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            if (_isRecording) {
                              _stopVoiceRecording(save: true);
                              setSheetState(() {});
                            } else {
                              _startVoiceRecording();
                              setSheetState(() {});
                              // Periodic redraw inside sheets is tricky, let's keep timer ticks updating
                              Timer.periodic(const Duration(milliseconds: 500), (t) {
                                if (!_isRecording) {
                                  t.cancel();
                                }
                                setSheetState(() {});
                              });
                            }
                          },
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: _isRecording ? Colors.redAccent : const Color(0xFF2563EB),
                            child: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                      onPressed: () {
                        if (_journalTitleCtrl.text.isEmpty) return;
                        
                        setState(() {
                          _memories.insert(0, {
                            'id': 'mem-${DateTime.now().millisecondsSinceEpoch}',
                            'title': _journalTitleCtrl.text,
                            'date': 'Today',
                            'image': 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?auto=format&fit=crop&w=800&q=80',
                            'journal': _journalBodyCtrl.text,
                            'tags': ['Travels', 'Memories'],
                            'voiceSeconds': _recordSeconds > 0 ? _recordSeconds : 10,
                            'isPlayingVoice': false,
                          });
                        });
                        
                        _journalTitleCtrl.clear();
                        _journalBodyCtrl.clear();
                        Navigator.pop(context);
                        SoundSynthesizer.playUnlockChime();
                      },
                      child: const Text('Save Polaroid Scrapbook Memory', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
  void dispose() {
    _recordTimer?.cancel();
    _playProgressTimer?.cancel();
    _journalTitleCtrl.dispose();
    _journalBodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkProvider);

    return Scaffold(
      backgroundColor: TriaColors.scaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: TriaColors.cardBg(isDark),
        elevation: 0.5,
        iconTheme: IconThemeData(color: TriaColors.textPrimary(isDark)),
        title: Text(
          'Scrapbook & Memories',
          style: TextStyle(
            color: TriaColors.textPrimary(isDark),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _memories.length,
        itemBuilder: (context, index) {
          final item = _memories[index];
          final memoryId = item['id'] as String;
          final isPlayingVoice = _currentlyPlayingVoiceId == memoryId;

          return Card(
            color: TriaColors.cardBg(isDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: TriaColors.border(isDark)),
            ),
            margin: const EdgeInsets.only(bottom: 20),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Box with Polaroid Styling
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    children: [
                      Image.network(
                        item['image'],
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      // Date Badge overlay
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item['date'],
                            style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Polaroid tags row
                      Row(
                        children: (item['tags'] as List<String>).map((tag) {
                          return Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00B4D8).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        item['title'],
                        style: TextStyle(
                          color: TriaColors.textPrimary(isDark),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['journal'],
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          fontSize: 11.5,
                          height: 1.45,
                        ),
                      ),
                      Divider(height: 24, color: TriaColors.border(isDark)),

                      // Voice Note wave play card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: TriaColors.border(isDark)),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _playVoiceMemo(memoryId, item['voiceSeconds'] as int),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: isPlayingVoice ? Colors.green : TriaColors.scaffoldBg(isDark),
                                child: Icon(
                                  isPlayingVoice ? Icons.pause : Icons.play_arrow,
                                  color: TriaColors.textPrimary(isDark),
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'VOICE JOURNAL MEMO',
                                    style: TextStyle(
                                      color: TriaColors.textMuted(isDark),
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  
                                  // Simulated Waveform slider / progress bar
                                  isPlayingVoice
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(2),
                                          child: LinearProgressIndicator(
                                            value: _voicePlayProgress,
                                            backgroundColor: Colors.white12,
                                            color: const Color(0xFF00B4D8),
                                            minHeight: 4,
                                          ),
                                        )
                                      : _drawMockWaveform(isDark),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '0:${(item['voiceSeconds'] as int).toString().padLeft(2, '0')}',
                              style: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 10),
                            ),
                          ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMemorySheet,
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text('Journal Memory', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _drawMockWaveform(bool isDark) {
    return Row(
      children: List.generate(24, (index) {
        // Pseudo heights for waveform bars
        final heights = [4, 12, 18, 6, 8, 22, 14, 8, 16, 26, 12, 6, 18, 12, 8, 22, 6, 14, 18, 8, 10, 4, 12, 6];
        final h = heights[index % heights.length];
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            height: h.toDouble(),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black26,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      }),
    );
  }
}

