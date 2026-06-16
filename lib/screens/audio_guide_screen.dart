import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/travel_providers.dart';
import '../core/utils/sound_synthesizer.dart';

class AudioGuideScreen extends ConsumerStatefulWidget {
  const AudioGuideScreen({super.key});

  @override
  ConsumerState<AudioGuideScreen> createState() => _AudioGuideScreenState();
}

class _AudioGuideScreenState extends ConsumerState<AudioGuideScreen> with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _tracks = [
    {
      'id': 'aud-1',
      'title': 'Famous Crossing History & Lore',
      'location': 'Famous Scramble Crossing',
      'duration': '3:45',
      'seconds': 225,
      'description': 'Discover the design principles and history behind the worlds busiest pedestrian crossing, and the Hachiko statue memorial.',
      'frequency': 440.0,
    },
    {
      'id': 'aud-2',
      'title': 'Incense & Rituals of Senso-ji',
      'location': 'Asakusa Temple',
      'duration': '5:20',
      'seconds': 320,
      'description': 'Learn about the purification ceremonies, fortune omikuji papers, and centuries-old wooden shrines of Tokyos oldest temple.',
      'frequency': 520.0,
    },
    {
      'id': 'aud-3',
      'title': 'Otaku Culture & Electric Geek Town',
      'location': 'Geek Town District',
      'duration': '4:12',
      'seconds': 252,
      'description': 'Step through the transition of Geek Town from a post-war black market radio parts hub into the global capital of electronic gaming and anime subculture.',
      'frequency': 600.0,
    }
  ];

  late AnimationController _pulseController;
  Timer? _progressTimer;
  double _playbackSpeed = 1.0;
  bool _beaconScanning = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _togglePlayTrack(Map<String, dynamic> track) {
    final guideState = ref.read(audioGuideProvider);
    final isCurrent = guideState.activeTrackId == track['id'];

    if (isCurrent && guideState.isPlaying) {
      // Pause
      _progressTimer?.cancel();
      _pulseController.stop();
      ref.read(audioGuideProvider.notifier).playAudioTrack(track['id']);
      SoundSynthesizer.playTone(frequency: 440, durationSeconds: 0.15, name: 'audio_pause.wav');
    } else {
      // Play
      _progressTimer?.cancel();
      ref.read(audioGuideProvider.notifier).playAudioTrack(track['id']);
      _pulseController.repeat();
      SoundSynthesizer.playTone(frequency: track['frequency'], endFrequency: track['frequency'] + 200, durationSeconds: 0.3, name: 'audio_play.wav');

      // Progress Simulation
      double currentProgress = isCurrent ? guideState.progress : 0.0;
      _progressTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
        if (!mounted) return;
        currentProgress += (1.0 / track['seconds']) * _playbackSpeed;
        if (currentProgress >= 1.0) {
          currentProgress = 0.0;
          _progressTimer?.cancel();
          _pulseController.stop();
          ref.read(audioGuideProvider.notifier).playAudioTrack(track['id']); // Reset play state
          SoundSynthesizer.playUnlockChime(); // Play complete chime
        } else {
          ref.read(audioGuideProvider.notifier).updateAudioProgress(currentProgress);
        }
      });
    }
  }

  void _scanBluetoothBeacon() {
    setState(() {
      _beaconScanning = true;
    });
    SoundSynthesizer.playTone(frequency: 700, durationSeconds: 0.4, name: 'beacon_scan.wav');
    
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() {
        _beaconScanning = false;
      });
      SoundSynthesizer.playUnlockChime();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Crossing District Beacon Found! Suggested guide locked to top.'),
          backgroundColor: Color(0xFF4F46E5),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final guideState = ref.watch(audioGuideProvider);
    final activeTrack = guideState.activeTrackId != null
        ? _tracks.firstWhere((t) => t['id'] == guideState.activeTrackId)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Midnight Blue
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
        title: const Text('AR Audio Guides', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _beaconScanning
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFF818CF8), strokeWidth: 2))
                : const Icon(Icons.bluetooth_searching, color: Color(0xFF818CF8)),
            onPressed: _beaconScanning ? null : _scanBluetoothBeacon,
          ),
        ],
      ),
      body: Column(
        children: [
          // Visual Pulse Wave Area
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            color: const Color(0xFF030712),
            child: Column(
              children: [
                // Pulse Circles
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer pulse circle
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final scale = 1.0 + (_pulseController.value * 0.4);
                          final opacity = (1.0 - _pulseController.value).clamp(0.0, 1.0);
                          return Transform.scale(
                            scale: guideState.isPlaying ? scale : 1.0,
                            child: Opacity(
                              opacity: guideState.isPlaying ? opacity : 0.05,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4F46E5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // Mid pulse circle
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final scale = 1.0 + (_pulseController.value * 0.2);
                          final opacity = (0.7 - _pulseController.value * 0.5).clamp(0.0, 1.0);
                          return Transform.scale(
                            scale: guideState.isPlaying ? scale : 1.0,
                            child: Opacity(
                              opacity: guideState.isPlaying ? opacity : 0.1,
                              child: Container(
                                width: 110,
                                height: 110,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF818CF8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Core Sphere
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFF0F172A),
                        child: Icon(
                          guideState.isPlaying ? Icons.hearing : Icons.hearing_disabled,
                          color: guideState.isPlaying ? const Color(0xFF818CF8) : Colors.white24,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Playing detail texts
                Text(
                  activeTrack != null
                      ? 'NOW PLAYING: ${activeTrack['title'].toUpperCase()}'
                      : 'SELECT AN AUDIO GUIDE BLOCK',
                  style: const TextStyle(color: Color(0xFF818CF8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  activeTrack != null ? 'Location: ${activeTrack['location']}' : 'Stand near landmarks to activate guides',
                  style: const TextStyle(color: Colors.white30, fontSize: 11),
                ),
                
                // Track progress slider
                if (activeTrack != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('0:00', style: TextStyle(color: Colors.white30, fontSize: 10)),
                      Expanded(
                        child: Slider(
                          value: guideState.progress,
                          onChanged: (_) {},
                          activeColor: const Color(0xFF4F46E5),
                          inactiveColor: Colors.white10,
                        ),
                      ),
                      Text(activeTrack['duration'], style: const TextStyle(color: Colors.white30, fontSize: 10)),
                    ],
                  ),
                  
                  // Speed controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _speedButton(1.0),
                      const SizedBox(width: 12),
                      _speedButton(1.25),
                      const SizedBox(width: 12),
                      _speedButton(1.5),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Guides Lists
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _tracks.length,
              itemBuilder: (context, index) {
                final track = _tracks[index];
                final trackId = track['id'] as String;
                final isCurrent = guideState.activeTrackId == trackId;
                final isPlaying = isCurrent && guideState.isPlaying;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCurrent ? const Color(0xFF4F46E5) : Colors.white.withValues(alpha: 0.05),
                      width: isCurrent ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => _togglePlayTrack(track),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: isPlaying ? const Color(0xFF10B981) : const Color(0xFF1E293B),
                              child: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track['title'],
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${track['location']} • ${track['duration']}',
                                  style: const TextStyle(color: Colors.white30, fontSize: 10.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: Colors.white10),
                      Text(
                        track['description'],
                        style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _speedButton(double speed) {
    final active = _playbackSpeed == speed;
    return ChoiceChip(
      label: Text('${speed}x', style: TextStyle(fontSize: 10, color: active ? Colors.white : Colors.white70, fontWeight: FontWeight.bold)),
      selected: active,
      selectedColor: const Color(0xFF4F46E5),
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      onSelected: (_) {
        setState(() {
          _playbackSpeed = speed;
        });
      },
    );
  }
}
