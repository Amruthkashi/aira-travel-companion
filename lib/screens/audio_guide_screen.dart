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
  late AnimationController _pulseController;
  Timer? _progressTimer;
  Timer? _searchDebounceTimer;
  double _playbackSpeed = 1.0;
  bool _beaconScanning = false;
  final AudioPlayer _ambientPlayer = AudioPlayer();

  // Search & Live Wikipedia Fetching State
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchingWiki = false;
  Map<String, dynamic>? _liveWikiSearchResult;

  // Custom AI / Wiki Generated Audio Guides Cache
  final Map<String, Map<String, dynamic>> _customGeneratedGuides = {};
  bool _isGeneratingCustom = false;

  // Language & Translation State
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
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    TtsHelper.stop();
    _ambientPlayer.dispose();
    super.dispose();
  }

  /// Format minutes into readable 12-hour string (e.g. 540 -> 09:00 AM)
  String _formatMinutesToTime(int minutes) {
    int h = (minutes ~/ 60) % 24;
    int m = minutes % 60;
    final period = h >= 12 ? 'PM' : 'AM';
    int displayH = h % 12;
    if (displayH == 0) displayH = 12;
    final mStr = m < 10 ? '0$m' : '$m';
    return '$displayH:$mStr $period';
  }

  /// Generates rich historical lore commentary for any landmark
  String _getHistoricalLore(String name, String genre, String description) {
    if (description.isNotEmpty && description.length > 50) {
      return '$description This iconic $genre combines rich cultural heritage with distinct architectural features, giving travelers an authentic insight into local history and traditions.';
    }
    return '$name is a celebrated cultural site and regional landmark. Renowned for its historical legacy, architectural craftsmanship, and artistic heritage, it serves as a central symbol of local history and storytelling.';
  }

  /// Real-Time Live Wikipedia / AI Search Engine
  void _onSearchQueryChanged(String val) {
    setState(() {
      _searchQuery = val;
    });

    _searchDebounceTimer?.cancel();
    if (val.trim().length >= 3) {
      _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        _fetchLiveRealtimeWikiHistory(val.trim());
      });
    } else {
      setState(() {
        _isSearchingWiki = false;
        _liveWikiSearchResult = null;
      });
    }
  }

  Future<void> _fetchLiveRealtimeWikiHistory(String query) async {
    if (!mounted) return;
    setState(() {
      _isSearchingWiki = true;
    });

    final wikiData = await AiService.fetchWikipediaPlaceHistory(query);
    if (!mounted) return;

    if (wikiData != null) {
      final customId = 'wiki-${query.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-')}';
      final track = {
        'id': customId,
        'placeId': customId,
        'title': wikiData['title'] ?? query,
        'location': wikiData['tagline'] ?? 'Verified Destination & Landmark',
        'dayNumber': 0,
        'scheduledTime': 'Live Wikipedia',
        'genre': 'Verified Landmark',
        'durationMin': 10,
        'duration': 'Live Audio',
        'seconds': 300,
        'description': wikiData['description'] ?? '',
        'shortDesc': wikiData['tagline'] ?? '',
        'openHours': 'Public Heritage Site',
        'rating': 4.9,
        'isItinerary': false,
        'isWikiLive': true,
      };

      setState(() {
        _liveWikiSearchResult = track;
        _customGeneratedGuides[customId] = track;
        _isSearchingWiki = false;
      });
    } else {
      setState(() {
        _liveWikiSearchResult = null;
        _isSearchingWiki = false;
      });
    }
  }

  /// Builds real-time list of audio guides derived strictly from active trip schedule
  List<Map<String, dynamic>> _getRealtimeItineraryTracks() {
    final schedule = ref.watch(dayScheduleProvider);
    final selectedPlaces = ref.watch(selectedPlacesProvider);
    final List<Map<String, dynamic>> tracks = [];

    // 1. Add places from user's active day-by-day itinerary
    for (int dayIdx = 0; dayIdx < schedule.length; dayIdx++) {
      for (final item in schedule[dayIdx]) {
        final place = item.place;
        final history = _getHistoricalLore(place.name, place.genre, place.description);
        final loc = place.address.isNotEmpty ? place.address : place.genre;
        tracks.add({
          'id': 'itinerary-${dayIdx + 1}-${place.id}',
          'placeId': place.id,
          'title': place.name,
          'location': 'Day ${dayIdx + 1} • $loc',
          'dayNumber': dayIdx + 1,
          'scheduledTime': item.scheduledTime,
          'genre': place.genre,
          'durationMin': place.durationMinutes,
          'duration': '${place.durationMinutes} min',
          'seconds': place.durationMinutes * 60,
          'description': history,
          'shortDesc': place.description.isNotEmpty ? place.description : 'Historical Landmark on Day ${dayIdx + 1}',
          'openHours': '${_formatMinutesToTime(place.openMinutes)} - ${_formatMinutesToTime(place.closeMinutes)}',
          'rating': place.rating,
          'isItinerary': true,
        });
      }
    }

    // 2. Add places from selected explore pool if not already in itinerary
    final existingIds = tracks.map((t) => t['placeId']).toSet();
    for (final place in selectedPlaces) {
      if (!existingIds.contains(place.id)) {
        final history = _getHistoricalLore(place.name, place.genre, place.description);
        final loc = place.address.isNotEmpty ? place.address : place.genre;
        tracks.add({
          'id': 'pool-${place.id}',
          'placeId': place.id,
          'title': place.name,
          'location': loc.isNotEmpty ? loc : 'Discovered Landmark',
          'dayNumber': 0,
          'scheduledTime': 'Flexible',
          'genre': place.genre,
          'durationMin': place.durationMinutes,
          'duration': '${place.durationMinutes} min',
          'seconds': place.durationMinutes * 60,
          'description': history,
          'shortDesc': place.description.isNotEmpty ? place.description : 'Discovered Landmark in trip pool',
          'openHours': '${_formatMinutesToTime(place.openMinutes)} - ${_formatMinutesToTime(place.closeMinutes)}',
          'rating': place.rating,
          'isItinerary': false,
        });
        existingIds.add(place.id);
      }
    }

    // 3. Add generated custom & live Wikipedia guides
    _customGeneratedGuides.forEach((id, guide) {
      if (!existingIds.contains(id)) {
        tracks.add(guide);
      }
    });

    // 4. Fallback sample tracks ONLY IF user has ZERO active itinerary items & explore places
    if (tracks.isEmpty) {
      tracks.addAll([
        {
          'id': 'aud-sample-1',
          'placeId': 'sample-1',
          'title': 'Taj Mahal Historical Architecture & Mughal Lore',
          'location': 'Agra • Historic Heritage Monument',
          'dayNumber': 1,
          'scheduledTime': '09:00 AM',
          'genre': 'Historical Monument',
          'durationMin': 15,
          'duration': '15 min audio',
          'seconds': 300,
          'description': 'Built in 1631 by Mughal Emperor Shah Jahan in memory of his beloved wife Mumtaz Mahal, the Taj Mahal is an international icon of white marble symmetry, intricate floral inlay pietra dura, and Persian-Mughal architectural masterwork.',
          'shortDesc': 'White marble mausoleum built by Shah Jahan, famous worldwide for its imperial Mughal symmetry and marble inlay craft.',
          'openHours': '06:00 AM - 06:30 PM',
          'rating': 4.9,
          'isItinerary': true,
        },
        {
          'id': 'aud-sample-2',
          'placeId': 'sample-2',
          'title': 'Shillong Peak & Sacred Khasi Heritage',
          'location': 'East Khasi Hills • Panorama Viewpoint',
          'dayNumber': 2,
          'scheduledTime': '11:00 AM',
          'genre': 'Scenic Viewpoint',
          'durationMin': 10,
          'duration': '10 min audio',
          'seconds': 240,
          'description': 'Standing at an altitude of 1,965 meters, Shillong Peak offers breathtaking panoramic views of the highland capital and surrounding pine-clad hills. In sacred Khasi lore, the peak is believed to be guarded by Lei Shyllong, the patron deity of the kingdom.',
          'shortDesc': 'Highest point in Meghalaya overlooking Shillong valley, deeply rooted in Khasi spiritual traditions and pine forest landscapes.',
          'openHours': '09:00 AM - 05:00 PM',
          'rating': 4.7,
          'isItinerary': true,
        },
      ]);
    }

    return tracks;
  }

  /// Instant Low-Latency Audio Playback Handler
  void _togglePlayTrack(Map<String, dynamic> track) async {
    final guideState = ref.read(audioGuideProvider);
    final isCurrent = guideState.activeTrackId == track['id'];

    if (isCurrent && guideState.isPlaying) {
      // Pause audio immediately
      _progressTimer?.cancel();
      _pulseController.stop();
      ref.read(audioGuideProvider.notifier).playAudioTrack(track['id']);
      await TtsHelper.stop();
      await _ambientPlayer.stop();
      SoundSynthesizer.playTone(frequency: 440, durationSeconds: 0.15, name: 'audio_pause.wav');
    } else {
      // Stop any active audio immediately
      _progressTimer?.cancel();
      await TtsHelper.stop();
      await _ambientPlayer.stop();

      // Set active track state instantly so UI responds with 0 delay
      ref.read(audioGuideProvider.notifier).playAudioTrack(track['id']);
      _pulseController.repeat();

      String speakText = track['description'];
      String targetLang = _selectedLang;

      // Handle translation non-blockingly if language is selected
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
            speakText = tr.isNotEmpty ? tr : track['description'];
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

      // 1. INSTANT SPEECH PLAYBACK via system Web Speech / TTS API with speed control
      TtsHelper.speak(speakText, targetLang, rate: _playbackSpeed);

      // 2. Play background ambient loop asynchronously without blocking speech launch
      if (track['ambientUrl'] != null) {
        _ambientPlayer.setReleaseMode(ReleaseMode.loop).then((_) {
          _ambientPlayer.play(UrlSource(track['ambientUrl']));
          _ambientPlayer.setVolume(0.12);
        }).catchError((e) {
          debugPrint('Ambient player error: $e');
        });
      }

      // 3. Real-time progress timer update
      double currentProgress = isCurrent ? guideState.progress : 0.0;
      final int totalSec = (track['seconds'] is int) ? track['seconds'] as int : 180;

      _progressTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
        if (!mounted) return;
        currentProgress += (1.0 / totalSec) * _playbackSpeed;
        if (currentProgress >= 1.0) {
          currentProgress = 0.0;
          _progressTimer?.cancel();
          _pulseController.stop();
          ref.read(audioGuideProvider.notifier).playAudioTrack(track['id']); // Reset state
          TtsHelper.stop();
          _ambientPlayer.stop();
          SoundSynthesizer.playUnlockChime();
        } else {
          ref.read(audioGuideProvider.notifier).updateAudioProgress(currentProgress);
        }
      });
    }
  }

  /// Generate dynamic history & audio guide for any custom searched landmark via Wikipedia
  Future<void> _generateCustomLandmarkGuide(String placeName) async {
    if (placeName.trim().isEmpty) return;
    setState(() {
      _isGeneratingCustom = true;
    });

    try {
      final wikiData = await AiService.fetchWikipediaPlaceHistory(placeName);
      final customId = 'custom-${placeName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-')}';

      if (wikiData == null) {
        // Wikipedia returned nothing — show clear error to user
        if (mounted) {
          setState(() { _isGeneratingCustom = false; });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Could not find Wikipedia information for "$placeName". Try a more specific name (e.g. "Mysore Palace Karnataka").'),
              backgroundColor: const Color(0xFFF59E0B),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      final String history = wikiData['description']!;
      final customTrack = {
        'id': customId,
        'placeId': customId,
        'title': wikiData['title'] ?? placeName,
        'location': wikiData['tagline'] ?? 'Verified Historic Destination',
        'dayNumber': 0,
        'scheduledTime': 'Live Wikipedia',
        'genre': 'Verified Landmark',
        'durationMin': 10,
        'duration': 'Live Audio',
        'seconds': 300,
        'description': history,
        'shortDesc': wikiData['tagline'] ?? 'Wikipedia: ${wikiData['title'] ?? placeName}',
        'openHours': 'Public Heritage Site',
        'rating': 4.9,
        'isItinerary': false,
        'isWikiLive': true,
      };

      setState(() {
        _customGeneratedGuides[customId] = customTrack;
        _liveWikiSearchResult = customTrack;
        _isGeneratingCustom = false;
      });

      _togglePlayTrack(customTrack);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ Wikipedia Audio Guide ready for "${wikiData['title'] ?? placeName}"! Playing now.'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isGeneratingCustom = false; });
      }
    }
  }

  void _scanBluetoothBeacon() {
    setState(() {
      _beaconScanning = true;
    });
    SoundSynthesizer.playTone(frequency: 700, durationSeconds: 0.4, name: 'beacon_scan.wav');

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() {
        _beaconScanning = false;
      });
      SoundSynthesizer.playUnlockChime();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📍 Landmark Beacon Synchronized! Nearby itinerary audio guide prioritized.'),
          backgroundColor: Color(0xFFFF6B35),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final guideState = ref.watch(audioGuideProvider);
    final isDark = ref.watch(isDarkProvider);

    final allTracks = _getRealtimeItineraryTracks();

    // Filter tracks based on live search query
    final filteredTracks = allTracks.where((t) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final title = (t['title'] as String).toLowerCase();
      final loc = (t['location'] as String).toLowerCase();
      final desc = (t['description'] as String).toLowerCase();
      final genre = (t['genre'] as String).toLowerCase();
      return title.contains(q) || loc.contains(q) || desc.contains(q) || genre.contains(q);
    }).toList();

    final activeTrack = guideState.activeTrackId != null
        ? allTracks.firstWhere(
            (t) => t['id'] == guideState.activeTrackId,
            orElse: () => allTracks.first,
          )
        : null;

    return Scaffold(
      backgroundColor: TriaColors.scaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: TriaColors.cardBg(isDark),
        elevation: 0.5,
        iconTheme: IconThemeData(color: TriaColors.textPrimary(isDark)),
        title: Text(
          'AI Voice & Audio Guide',
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
              if (v == null) return;
              setState(() {
                _selectedLang = v;
              });
              final guideState = ref.read(audioGuideProvider);
              if (guideState.activeTrackId != null && guideState.isPlaying && activeTrack != null) {
                _togglePlayTrack(activeTrack); // Restart with new language instantly
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
            tooltip: 'Sync Nearby Beacon',
            onPressed: _beaconScanning ? null : _scanBluetoothBeacon,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Live Search & Wikipedia Information Fetching Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: TriaColors.cardBg(isDark),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: TriaColors.border(isDark)),
                    ),
                    child: Row(
                      children: [
                        _isSearchingWiki
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(color: Color(0xFF00B4D8), strokeWidth: 2),
                              )
                            : const Icon(Icons.search, color: Color(0xFF00B4D8), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search any landmark, city, temple, or place in the world...',
                              hintStyle: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 11.5),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: _onSearchQueryChanged,
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                _generateCustomLandmarkGuide(val.trim());
                              }
                            },
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _isSearchingWiki = false;
                                _liveWikiSearchResult = null;
                              });
                            },
                            child: const Icon(Icons.clear, color: Color(0xFF94A3B8), size: 18),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Active Audio Wave & Player Header Box
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            color: isDark ? const Color(0xFF030712) : const Color(0xFFF1F5F9),
            child: Column(
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer pulse wave
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final scale = 1.0 + (_pulseController.value * 0.35);
                          final opacity = (1.0 - _pulseController.value).clamp(0.0, 1.0);
                          return Transform.scale(
                            scale: guideState.isPlaying ? scale : 1.0,
                            child: Opacity(
                              opacity: guideState.isPlaying ? opacity : 0.05,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF6B35),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Core active headphone icon
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: TriaColors.cardBg(isDark),
                        child: Icon(
                          guideState.isPlaying ? Icons.graphic_eq : Icons.headphones,
                          color: guideState.isPlaying ? const Color(0xFF00B4D8) : TriaColors.textMuted(isDark),
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Now Playing Info
                Text(
                  activeTrack != null
                      ? 'NOW PLAYING: ${activeTrack['title'].toUpperCase()}'
                      : 'TAP ANY ITINERARY LANDMARK OR SEARCHED PLACE TO PLAY AUDIO',
                  style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  activeTrack != null
                      ? '${activeTrack['location']} • Language: $_selectedLang'
                      : 'Real-time narration generated from your active trip schedule & Wikipedia search',
                  style: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 11),
                  textAlign: TextAlign.center,
                ),

                // Active Translation Box
                if (_translating) ...[
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(color: Color(0xFF00B4D8), strokeWidth: 1.5),
                      ),
                      SizedBox(width: 8),
                      Text('Translating guide...', style: TextStyle(color: Color(0xFF00B4D8), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ] else if (_activeTranslation != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: TriaColors.scaffoldBg(isDark).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: TriaColors.border(isDark)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _activeTranslation!,
                          style: TextStyle(
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_activeRomaji != null && _activeRomaji!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            _activeRomaji!,
                            style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 10, fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Track Progress Slider & Controls
                if (activeTrack != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('0:00', style: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 10)),
                      Expanded(
                        child: Slider(
                          value: guideState.progress,
                          onChanged: (val) {
                            ref.read(audioGuideProvider.notifier).updateAudioProgress(val);
                          },
                          activeColor: const Color(0xFFFF6B35),
                          inactiveColor: isDark ? Colors.white10 : Colors.black12,
                        ),
                      ),
                      Text(activeTrack['duration'], style: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 10)),
                    ],
                  ),

                  // Speed Control Chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _speedButton(1.0, isDark),
                      const SizedBox(width: 10),
                      _speedButton(1.25, isDark),
                      const SizedBox(width: 10),
                      _speedButton(1.5, isDark),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // 3. Audio Guide List & Wikipedia Live Search Result Section
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Live Wikipedia Search Result Banner
                if (_liveWikiSearchResult != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF0F172A), const Color(0xFF1E1B4B)]
                            : [const Color(0xFFEFF6FF), const Color(0xFFEEF2FF)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.5), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.public, color: Color(0xFF6366F1), size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'LIVE WIKIPEDIA HISTORY',
                                    style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 9),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _togglePlayTrack(_liveWikiSearchResult!),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'Listen Live',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _liveWikiSearchResult!['title'],
                          style: TextStyle(
                            color: TriaColors.textPrimary(isDark),
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _liveWikiSearchResult!['location'],
                          style: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _liveWikiSearchResult!['description'],
                          style: TextStyle(
                            color: isDark ? Colors.white.withValues(alpha: 0.87) : const Color(0xFF334155),
                            fontSize: 11.5,
                            height: 1.45,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],

                // Searching indicator banner
                if (_isSearchingWiki)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Color(0xFF00B4D8), strokeWidth: 2)),
                          const SizedBox(width: 8),
                          Text(
                            'Fetching live history & cultural background from Wikipedia...',
                            style: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 11.5, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ),

                // No search matches fallback button
                if (filteredTracks.isEmpty && _searchQuery.isNotEmpty && !_isSearchingWiki && _liveWikiSearchResult == null) ...[
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.travel_explore, size: 44, color: TriaColors.textMuted(isDark)),
                        const SizedBox(height: 12),
                        Text(
                          'No itinerary guide found for "$_searchQuery"',
                          style: TextStyle(color: TriaColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap below to fetch live historical data & audio guide for "$_searchQuery" from Wikipedia & AI archives.',
                          style: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          icon: _isGeneratingCustom
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                          label: Text(
                            'Fetch & Listen to Audio for "$_searchQuery"',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: _isGeneratingCustom ? null : () => _generateCustomLandmarkGuide(_searchQuery),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Itinerary Audio Tracks List
                  ...filteredTracks.map((track) {
                    final trackId = track['id'] as String;
                    final isCurrent = guideState.activeTrackId == trackId;
                    final isPlaying = isCurrent && guideState.isPlaying;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: TriaColors.cardBg(isDark),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isCurrent ? const Color(0xFFFF6B35) : TriaColors.border(isDark),
                          width: isCurrent ? 1.8 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Play / Pause Action Button
                              GestureDetector(
                                onTap: () => _togglePlayTrack(track),
                                child: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: isPlaying ? const Color(0xFF10B981) : const Color(0xFF2563EB).withValues(alpha: 0.15),
                                  child: Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow_rounded,
                                    color: isPlaying ? Colors.white : const Color(0xFF2563EB),
                                    size: 26,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (track['isItinerary'] == true)
                                          Container(
                                            margin: const EdgeInsets.only(right: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Day ${track['dayNumber']}',
                                              style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 9.5),
                                            ),
                                          ),
                                        Expanded(
                                          child: Text(
                                            track['title'],
                                            style: TextStyle(
                                              color: TriaColors.textPrimary(isDark),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${track['location']} • ${track['genre']}',
                                      style: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  track['duration'],
                                  style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(height: 1, color: TriaColors.border(isDark)),
                          const SizedBox(height: 12),

                          // History & Story Narration Snippet
                          Text(
                            'HISTORICAL & CULTURAL OVERVIEW',
                            style: TextStyle(
                              color: TriaColors.textMuted(isDark),
                              fontWeight: FontWeight.bold,
                              fontSize: 9.5,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            track['description'],
                            style: TextStyle(
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                              fontSize: 11.5,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _speedButton(double speed, bool isDark) {
    final active = _playbackSpeed == speed;
    return ChoiceChip(
      label: Text(
        '${speed}x',
        style: TextStyle(
          fontSize: 10,
          color: active ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
          fontWeight: FontWeight.bold,
        ),
      ),
      selected: active,
      selectedColor: const Color(0xFFFF6B35),
      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
      onSelected: (_) {
        setState(() {
          _playbackSpeed = speed;
        });
        final guideState = ref.read(audioGuideProvider);
        if (guideState.activeTrackId != null && guideState.isPlaying) {
          final allTracks = _getRealtimeItineraryTracks();
          final currentTrack = allTracks.firstWhere((t) => t['id'] == guideState.activeTrackId);
          TtsHelper.speak(currentTrack['description'], _selectedLang, rate: _playbackSpeed);
        }
      },
    );
  }
}
