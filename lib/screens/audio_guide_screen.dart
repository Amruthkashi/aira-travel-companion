import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../core/providers/theme_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/travel_providers.dart';
import '../core/utils/sound_synthesizer.dart';
import '../core/utils/tts_helper.dart';
import '../core/services/ai_service.dart';

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
      'ambientUrl': 'https://assets.mixkit.co/active_storage/sfx/2568/2568-84.wav',
    },
    {
      'id': 'aud-2',
      'title': 'Incense & Rituals of Senso-ji',
      'location': 'Asakusa Temple',
      'duration': '5:20',
      'seconds': 320,
      'description': 'Learn about the purification ceremonies, fortune omikuji papers, and centuries-old wooden shrines of Tokyos oldest temple.',
      'frequency': 520.0,
      'ambientUrl': 'https://assets.mixkit.co/active_storage/sfx/1659/1659-200.wav',
    },
    {
      'id': 'aud-3',
      'title': 'Otaku Culture & Electric Geek Town',
      'location': 'Geek Town District',
      'duration': '4:12',
      'seconds': 252,
      'description': 'Step through the transition of Geek Town from a post-war black market radio parts hub into the global capital of electronic gaming and anime subculture.',
      'frequency': 600.0,
      'ambientUrl': 'https://assets.mixkit.co/active_storage/sfx/2018/2018-200.wav',
    }
  ];

  late AnimationController _pulseController;
  Timer? _progressTimer;
  double _playbackSpeed = 1.0;
  bool _beaconScanning = false;
  final AudioPlayer _ambientPlayer = AudioPlayer();

  // Translation & Audio Guide State
  String _selectedLang = 'English';
  bool _translating = false;
  String? _activeTranslation;
  String? _activeRomaji;
  final Map<String, Map<String, String>> _translationCache = {};

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
    TtsHelper.stop();
    _ambientPlayer.dispose();
    super.dispose();
  }

  void _togglePlayTrack(Map<String, dynamic> track) async {
    final guideState = ref.read(audioGuideProvider);
    final isCurrent = guideState.activeTrackId == track['id'];

    if (isCurrent && guideState.isPlaying) {
      // Pause
      _progressTimer?.cancel();
      _pulseController.stop();
      ref.read(audioGuideProvider.notifier).playAudioTrack(track['id']);
      await TtsHelper.stop();
      await _ambientPlayer.stop();
      SoundSynthesizer.playTone(frequency: 440, durationSeconds: 0.15, name: 'audio_pause.wav');
    } else {
      // Play
      _progressTimer?.cancel();
      await TtsHelper.stop();
      await _ambientPlayer.stop();
      
      String speakText = track['description'];
      String targetLang = _selectedLang;
      
      if (targetLang != 'English') {
        final cacheKey = '${track['id']}_$targetLang';
        if (_translationCache.containsKey(cacheKey)) {
          final cached = _translationCache[cacheKey]!;
          setState(() {
            _activeTranslation = cached['tr'];
            _activeRomaji = cached['rom'];
          });
          speakText = cached['tr'] ?? track['description'];
        } else {
          setState(() {
            _translating = true;
          });
          try {
            final res = await AiService.translateText(
              text: track['description'],
              sourceLang: 'English',
              targetLang: targetLang,
            );
            final tr = res['translation'] ?? '';
            final rom = res['romaji'] ?? '';
            _translationCache[cacheKey] = {'tr': tr, 'rom': rom};
            if (mounted) {
              setState(() {
                _activeTranslation = tr;
                _activeRomaji = rom;
                _translating = false;
              });
            }
            speakText = tr;
          } catch (e) {
            debugPrint('Translation failed: $e');
            if (mounted) {
              setState(() {
                _translating = false;
              });
            }
          }
        }
      } else {
        setState(() {
          _activeTranslation = null;
          _activeRomaji = null;
        });
      }

      ref.read(audioGuideProvider.notifier).playAudioTrack(track['id']);
      _pulseController.repeat();
      
      // Play background ambient loop
      if (track['ambientUrl'] != null) {
        try {
          await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
          await _ambientPlayer.play(UrlSource(track['ambientUrl']));
          await _ambientPlayer.setVolume(0.15);
        } catch (e) {
          debugPrint('Ambient player error: $e');
        }
      }

      // Play real audio read-aloud via phone speaker
      await TtsHelper.speak(speakText, targetLang);

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
          TtsHelper.stop();
          _ambientPlayer.stop();
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
          backgroundColor: Color(0xFFFF6B35),
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
    final isDark = ref.watch(isDarkProvider);

    return Scaffold(
      backgroundColor: TriaColors.scaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: TriaColors.cardBg(isDark),
        elevation: 0.5,
        iconTheme: IconThemeData(color: TriaColors.textPrimary(isDark)),
        title: Text(
          'AR Audio Guides',
          style: TextStyle(
            color: TriaColors.textPrimary(isDark),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          // Dynamic translation language selector
          DropdownButton<String>(
            value: _selectedLang,
            dropdownColor: TriaColors.cardBg(isDark),
            style: const TextStyle(color: Color(0xFF00B4D8), fontWeight: FontWeight.bold, fontSize: 12),
            underline: const SizedBox(),
            onChanged: (v) {
              setState(() {
                _selectedLang = v!;
              });
              final guideState = ref.read(audioGuideProvider);
              if (guideState.activeTrackId != null && guideState.isPlaying) {
                final currentTrack = _tracks.firstWhere((t) => t['id'] == guideState.activeTrackId);
                _togglePlayTrack(currentTrack); // Pause it
                _togglePlayTrack(currentTrack); // Play in new language
              }
            },
            items: [
              DropdownMenuItem(value: 'English', child: Text('English', style: TextStyle(color: TriaColors.textPrimary(isDark)))),
              DropdownMenuItem(value: 'Japanese', child: Text('Japanese', style: TextStyle(color: TriaColors.textPrimary(isDark)))),
              DropdownMenuItem(value: 'French', child: Text('French', style: TextStyle(color: TriaColors.textPrimary(isDark)))),
              DropdownMenuItem(value: 'Spanish', child: Text('Spanish', style: TextStyle(color: TriaColors.textPrimary(isDark)))),
              DropdownMenuItem(value: 'German', child: Text('German', style: TextStyle(color: TriaColors.textPrimary(isDark)))),
              DropdownMenuItem(value: 'Italian', child: Text('Italian', style: TextStyle(color: TriaColors.textPrimary(isDark)))),
              DropdownMenuItem(value: 'Chinese', child: Text('Chinese', style: TextStyle(color: TriaColors.textPrimary(isDark)))),
              DropdownMenuItem(value: 'Korean', child: Text('Korean', style: TextStyle(color: TriaColors.textPrimary(isDark)))),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _beaconScanning
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFF00B4D8), strokeWidth: 2))
                : const Icon(Icons.bluetooth_searching, color: Color(0xFF00B4D8)),
            onPressed: _beaconScanning ? null : _scanBluetoothBeacon,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Visual Pulse Wave Area
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            color: isDark ? const Color(0xFF030712) : const Color(0xFFF1F5F9),
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
                                  color: Color(0xFFFF6B35),
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
                                  color: Color(0xFF00B4D8),
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
                        backgroundColor: TriaColors.cardBg(isDark),
                        child: Icon(
                          guideState.isPlaying ? Icons.hearing : Icons.hearing_disabled,
                          color: guideState.isPlaying ? const Color(0xFF00B4D8) : TriaColors.textMuted(isDark),
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
                  style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  activeTrack != null ? 'Location: ${activeTrack['location']}' : 'Stand near landmarks to activate guides',
                  style: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 11),
                ),
                
                // Active Translation Overlay
                if (_translating) ...[
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(color: Color(0xFF00B4D8), strokeWidth: 1.5),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Translating guide...',
                        style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ] else if (_activeTranslation != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: TriaColors.scaffoldBg(isDark).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: TriaColors.border(isDark).withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _activeTranslation!,
                          style: TextStyle(
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_activeRomaji != null && _activeRomaji!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _activeRomaji!,
                            style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 9.5, fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                
                // Track progress slider
                if (activeTrack != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('0:00', style: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 10)),
                      Expanded(
                        child: Slider(
                          value: guideState.progress,
                          onChanged: (_) {},
                          activeColor: const Color(0xFFFF6B35),
                          inactiveColor: isDark ? Colors.white10 : Colors.black12,
                        ),
                      ),
                      Text(activeTrack['duration'], style: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 10)),
                    ],
                  ),
                  
                  // Speed controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _speedButton(1.0, isDark),
                      const SizedBox(width: 12),
                      _speedButton(1.25, isDark),
                      const SizedBox(width: 12),
                      _speedButton(1.5, isDark),
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
                    color: TriaColors.cardBg(isDark),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCurrent ? const Color(0xFFFF6B35) : TriaColors.border(isDark),
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
                              backgroundColor: isPlaying ? const Color(0xFF10B981) : TriaColors.scaffoldBg(isDark),
                              child: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: isPlaying ? Colors.white : TriaColors.textPrimary(isDark),
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
                                  style: TextStyle(
                                    color: TriaColors.textPrimary(isDark),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${track['location']} • ${track['duration']}',
                                  style: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 10.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 20, color: TriaColors.border(isDark)),
                      Text(
                        track['description'],
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          fontSize: 11,
                          height: 1.4,
                        ),
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

  Widget _speedButton(double speed, bool isDark) {
    final active = _playbackSpeed == speed;
    return ChoiceChip(
      label: Text('${speed}x', style: TextStyle(fontSize: 10, color: active ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)), fontWeight: FontWeight.bold)),
      selected: active,
      selectedColor: const Color(0xFFFF6B35),
      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
      onSelected: (_) {
        setState(() {
          _playbackSpeed = speed;
        });
      },
    );
  }
}
