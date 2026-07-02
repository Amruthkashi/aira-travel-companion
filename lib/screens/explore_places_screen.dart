import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/travel_providers.dart';
import '../core/providers/theme_provider.dart';
import '../core/models/travel_models.dart';
import '../core/services/geoapify_service.dart';
import '../core/services/foursquare_service.dart';
import '../core/services/wikipedia_service.dart';
import '../core/theme/app_theme.dart';

class ExplorePlacesScreen extends ConsumerStatefulWidget {
  const ExplorePlacesScreen({super.key});

  @override
  ConsumerState<ExplorePlacesScreen> createState() => _ExplorePlacesScreenState();
}

class _ExplorePlacesScreenState extends ConsumerState<ExplorePlacesScreen>
    with SingleTickerProviderStateMixin {
  int _activeGenre = 0;
  String? _expandedPlaceId;
  late String _destinationName;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _genres = [
    {'icon': Icons.beach_access, 'label': 'Summer & Beach', 'color': const Color(0xFF0EA5E9)},
    {'icon': Icons.child_care, 'label': 'Kids & Family', 'color': const Color(0xFFF59E0B)},
    {'icon': Icons.temple_buddhist, 'label': 'Religious', 'color': const Color(0xFFEF4444)},
    {'icon': Icons.terrain, 'label': 'Adventure', 'color': const Color(0xFF10B981)},
    {'icon': Icons.restaurant, 'label': 'Food & Culinary', 'color': const Color(0xFFF97316)},
    {'icon': Icons.museum, 'label': 'Culture & History', 'color': const Color(0xFF8B5CF6)},
    {'icon': Icons.shopping_bag, 'label': 'Shopping', 'color': const Color(0xFFEC4899)},
    {'icon': Icons.nightlife, 'label': 'Nightlife', 'color': const Color(0xFF6366F1)},
  ];

  // Attractions per genre loaded dynamically based on destination
  final Map<String, List<ExplorePlaceItem>> _placesByGenre = {};
  bool _isLoading = true;
  String? _errorMessage;

  // Wikipedia integration
  final WikipediaService _wikipediaService = WikipediaService();
  final Map<String, WikipediaSummary?> _wikiSummaries = {};
  final Map<String, bool> _wikiLoading = {};

  @override
  void initState() {
    super.initState();
    final bookings = ref.read(tripBookingsProvider);
    final destination = bookings.destination.isNotEmpty ? bookings.destination : 'Tokyo';
    _destinationName = destination;
    _loadPlaces(destination);
  }

  @override
  void dispose() {
    _wikipediaService.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchWikipediaSummaryFor(ExplorePlaceItem place) async {
    final placeId = place.id;
    if (_wikiSummaries.containsKey(placeId) || (_wikiLoading[placeId] ?? false)) {
      return;
    }

    setState(() {
      _wikiLoading[placeId] = true;
    });

    try {
      final summary = await _wikipediaService.fetchPageSummary(place.name, cityName: _destinationName);
      if (mounted) {
        setState(() {
          _wikiSummaries[placeId] = summary;
          _wikiLoading[placeId] = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching Wikipedia summary in screen: $e');
      if (mounted) {
        setState(() {
          _wikiLoading[placeId] = false;
        });
      }
    }
  }

  void _preloadWikipediaForActiveGenre() {
    if (_activeGenre < 0 || _activeGenre >= _genres.length) return;
    final activeLabel = _genres[_activeGenre]['label'] as String;
    final currentPlaces = _placesByGenre[activeLabel] ?? [];
    for (final place in currentPlaces) {
      _fetchWikipediaSummaryFor(place);
    }
  }

  void _selectFirstNonEmptyGenre() {
    for (int i = 0; i < _genres.length; i++) {
      final label = _genres[i]['label'] as String;
      if (_placesByGenre[label] != null && _placesByGenre[label]!.isNotEmpty) {
        _activeGenre = i;
        break;
      }
    }
  }

  Map<String, List<ExplorePlaceItem>> _convertGroupedPlaces(Map<int, List<ExplorePlaceItem>> original) {
    final Map<String, List<ExplorePlaceItem>> converted = {};
    final List<String> originalLabels = [
      'Summer & Beach',
      'Kids & Family',
      'Religious',
      'Adventure',
      'Food & Culinary',
      'Culture & History',
      'Shopping',
      'Nightlife'
    ];
    for (final label in originalLabels) {
      converted[label] = [];
    }
    original.forEach((key, value) {
      if (key >= 0 && key < originalLabels.length) {
        converted[originalLabels[key]] = value;
      }
    });
    return converted;
  }

  void _sortGenresByPlacesCount() {
    // Keep a copy of the currently active genre label to restore selection after sorting
    String? currentlyActiveLabel;
    if (_activeGenre >= 0 && _activeGenre < _genres.length) {
      currentlyActiveLabel = _genres[_activeGenre]['label'] as String;
    }

    _genres.sort((a, b) {
      final labelA = a['label'] as String;
      final labelB = b['label'] as String;
      final countA = _placesByGenre[labelA]?.length ?? 0;
      final countB = _placesByGenre[labelB]?.length ?? 0;
      
      // Sort primarily by places count (descending)
      if (countA != countB) {
        return countB.compareTo(countA);
      }
      
      // If count is same, keep original order by comparing index in static labels
      final List<String> originalLabels = [
        'Summer & Beach',
        'Kids & Family',
        'Religious',
        'Adventure',
        'Food & Culinary',
        'Culture & History',
        'Shopping',
        'Nightlife'
      ];
      return originalLabels.indexOf(labelA).compareTo(originalLabels.indexOf(labelB));
    });

    // Restore correct active genre index
    if (currentlyActiveLabel != null) {
      final newIndex = _genres.indexWhere((g) => g['label'] == currentlyActiveLabel);
      if (newIndex != -1) {
        _activeGenre = newIndex;
      }
    }
  }

  Future<void> _loadPlaces(String destination) async {
    final cleanDest = destination.trim().toLowerCase();

    // 1. Check if we have hardcoded data for major cities to bypass API requests and save quota
    bool isHardcoded = cleanDest.contains('paris') ||
        cleanDest.contains('london') ||
        cleanDest.contains('new york') ||
        cleanDest.contains('nyc') ||
        cleanDest.contains('singapore') ||
        cleanDest.contains('sg') ||
        cleanDest.contains('tokyo') ||
        cleanDest.contains('japan');

    if (isHardcoded) {
      if (mounted) {
        setState(() {
          _placesByGenre.addAll(_convertGroupedPlaces(_buildPlacesData(destination)));
          _sortGenresByPlacesCount();
          _selectFirstNonEmptyGenre();
          _isLoading = false;
        });
        _preloadWikipediaForActiveGenre();
      }
      return;
    }

    // 2. Fetch dynamically
    try {
      final geoService = GeoapifyService();
      final coords = await geoService.geocodeCity(destination);
      if (coords == null) {
        throw Exception("Could not geocode destination city '$destination'");
      }

      List<ExplorePlaceItem> fetchedPlaces = [];
      String? sourceMessage;

      // Try Foursquare first
      try {
        final foursquareService = FoursquareService();
        final fsqPlaces = await foursquareService.fetchNearbyPlaces(
          coords['lat']!,
          coords['lon']!,
          destination,
        );
        foursquareService.dispose();
        if (fsqPlaces.length >= 5) {
          fetchedPlaces = fsqPlaces;
          sourceMessage = "Loaded real-time local attractions.";
        } else {
          throw Exception("Foursquare returned too few places (${fsqPlaces.length})");
        }
      } catch (fsqError) {
        debugPrint("Foursquare fetch failed, falling back to Geoapify: $fsqError");
        // Fallback to Geoapify Places search
        try {
          final geoPlaces = await geoService.fetchNearbyPlaces(
            coords['lat']!,
            coords['lon']!,
            destination,
          );
          if (geoPlaces.length >= 5) {
            fetchedPlaces = geoPlaces;
            sourceMessage = "Loaded local attractions.";
          } else {
            throw Exception("Geoapify returned too few places (${geoPlaces.length})");
          }
        } catch (geoError) {
          debugPrint("Geoapify fetch failed as well: $geoError");
          rethrow;
        }
      }

      geoService.dispose();

      // Group into genres
      final Map<String, List<ExplorePlaceItem>> grouped = {};
      for (final g in _genres) {
        grouped[g['label'] as String] = [];
      }

      for (final p in fetchedPlaces) {
        final label = p.genre;
        if (grouped.containsKey(label)) {
          grouped[label]?.add(p);
        } else {
          grouped['Adventure']?.add(p);
        }
      }

      if (mounted) {
        setState(() {
          _placesByGenre.addAll(grouped);
          _sortGenresByPlacesCount();
          _selectFirstNonEmptyGenre();
          _errorMessage = sourceMessage;
          _isLoading = false;
        });
        _preloadWikipediaForActiveGenre();
      }
    } catch (e) {
      debugPrint('Real-time Places Fetch Failed completely: $e');
      // Graceful fallback to generic places
      if (mounted) {
        setState(() {
          _placesByGenre.addAll(_convertGroupedPlaces(_buildPlacesData(destination)));
          _sortGenresByPlacesCount();
          _selectFirstNonEmptyGenre();
          _errorMessage = "Using local offline suggestions for '$destination'.";
          _isLoading = false;
        });
        _preloadWikipediaForActiveGenre();
      }
    }
  }


  Map<int, List<ExplorePlaceItem>> _buildPlacesData(String destination) {
    final cleanDest = destination.trim().toLowerCase();

    if (cleanDest.contains('paris')) {
      return _buildParisPlaces();
    }
    if (cleanDest.contains('london')) {
      return _buildLondonPlaces();
    }
    if (cleanDest.contains('new york') || cleanDest.contains('nyc')) {
      return _buildNYCPlaces();
    }
    if (cleanDest.contains('singapore') || cleanDest.contains('sg')) {
      return _buildSingaporePlaces();
    }
    if (cleanDest.contains('tokyo') || cleanDest.contains('japan')) {
      return _buildTokyoPlaces();
    }

    // Generic destination
    final name = cleanDest.isNotEmpty
        ? destination[0].toUpperCase() + destination.substring(1)
        : 'Destination';
    return _buildGenericPlaces(name);
  }

  // =============================================
  // PARIS — 8-10 places per genre
  // =============================================
  Map<int, List<ExplorePlaceItem>> _buildParisPlaces() {
    return {
      0: [ // Summer & Beach
        ExplorePlaceItem(id: 'paris-beach-1', name: 'Paris Plages (Seine Riverfront)', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400', description: 'Every summer, the banks of the Seine are transformed into artificial beaches with lounge chairs, palm trees, and ice cream stalls.', rating: 4.5, estimatedDuration: '2-3 hrs', estimatedCost: 'Free', address: 'Voie Georges Pompidou, Paris', durationMinutes: 150),
        ExplorePlaceItem(id: 'paris-beach-2', name: 'Bassin de la Villette', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'An outdoor swimming canal with floating pools, kayaking, and waterside dining during hot summer months.', rating: 4.6, estimatedDuration: '2-3 hrs', estimatedCost: 'Free', address: 'Quai de la Loire, Paris', durationMinutes: 150),
        ExplorePlaceItem(id: 'paris-beach-3', name: 'Aquaboulevard Water Park', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=400', description: 'The largest urban water park in Europe with wave pools, giant slides, sandy beaches, and outdoor spas.', rating: 4.4, estimatedDuration: '3-4 hrs', estimatedCost: '\$25', address: 'Rue Louis Armand, Paris', durationMinutes: 210),
        ExplorePlaceItem(id: 'paris-beach-4', name: 'Jardin des Tuileries Splash Fountains', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400', description: 'Cool off near the elegant fountains and rent wooden sailboats in the historic garden beside the Louvre.', rating: 4.5, estimatedDuration: '1-2 hrs', estimatedCost: 'Free', address: 'Rue de Rivoli, Paris', durationMinutes: 90),
        ExplorePlaceItem(id: 'paris-beach-5', name: 'Piscine Joséphine Baker', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=400', description: 'A floating swimming pool on the Seine with a retractable glass roof, perfect for sunny summer laps.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: '\$8', address: 'Port de la Gare, Paris', durationMinutes: 120),
        ExplorePlaceItem(id: 'paris-beach-6', name: 'Canal Saint-Martin Picnic', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Bring wine, cheese, and baguettes and picnic along the tree-lined canal, watching the iron footbridges and locks.', rating: 4.4, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Canal Saint-Martin, Paris', durationMinutes: 120),
        ExplorePlaceItem(id: 'paris-beach-7', name: 'Bois de Vincennes Lake Boating', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400', description: 'Rent rowboats on Lac Daumesnil in the east side of Paris surrounded by lush greenery and a Buddhist temple.', rating: 4.3, estimatedDuration: '2 hrs', estimatedCost: '\$12', address: 'Bois de Vincennes, Paris', durationMinutes: 120),
        ExplorePlaceItem(id: 'paris-beach-8', name: 'Parc de la Villette Splash Pads', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=400', description: 'Fun interactive water features and splash pads in this enormous urban park, perfect for hot summer days.', rating: 4.3, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'Av Jean Jaurès, Paris', durationMinutes: 90),
      ],
      1: [ // Kids & Family
        ExplorePlaceItem(id: 'paris-kids-1', name: 'Disneyland Paris', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1624601573012-efb68931cc8f?w=400', description: 'Experience the magic of Disney with Sleeping Beauty Castle, classic rides, live shows, and character meetups.', rating: 4.9, estimatedDuration: '8-10 hrs', estimatedCost: '\$85', address: 'Marne-la-Vallée', durationMinutes: 480),
        ExplorePlaceItem(id: 'paris-kids-2', name: 'Jardin du Luxembourg Playground', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400', description: 'Fabulous vintage playground where kids can rent wooden toy sailboats to sail on the grand octagonal basin.', rating: 4.7, estimatedDuration: '2-3 hrs', estimatedCost: '\$3', address: 'Rue de Médicis, Paris', durationMinutes: 150),
        ExplorePlaceItem(id: 'paris-kids-3', name: 'Cité des Sciences', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1534567153574-2b12153a63f0?w=400', description: 'Hands-on kids science museum with a planetarium, a submarine to explore, and interactive experiment zones.', rating: 4.8, estimatedDuration: '3-4 hrs', estimatedCost: '\$14', address: 'Avenue Corentin Cariou, Paris', durationMinutes: 210),
        ExplorePlaceItem(id: 'paris-kids-4', name: 'Jardin d\'Acclimatation', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1624601573012-efb68931cc8f?w=400', description: 'A gorgeous amusement park and garden with rides, puppet shows, a zip-line, and a farm with animals.', rating: 4.6, estimatedDuration: '3-4 hrs', estimatedCost: '\$15', address: 'Bois de Boulogne, Paris', durationMinutes: 210),
        ExplorePlaceItem(id: 'paris-kids-5', name: 'Parc Astérix', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400', description: 'French theme park based on Astérix comics, with roller coasters, water rides, and hilarious Gaulish shows.', rating: 4.7, estimatedDuration: '6-8 hrs', estimatedCost: '\$55', address: 'Plailly, near Paris', durationMinutes: 420),
        ExplorePlaceItem(id: 'paris-kids-6', name: 'Aquarium de Paris', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1534567153574-2b12153a63f0?w=400', description: 'Located beneath Trocadéro gardens, featuring sharks, jellyfish, and an interactive touch pool for kids.', rating: 4.4, estimatedDuration: '2 hrs', estimatedCost: '\$22', address: 'Avenue Albert de Mun, Paris', durationMinutes: 120),
        ExplorePlaceItem(id: 'paris-kids-7', name: 'Musée Grévin (Wax Museum)', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1624601573012-efb68931cc8f?w=400', description: 'Take selfies with lifelike wax figures of celebrities, sports stars, and historical French figures.', rating: 4.3, estimatedDuration: '1.5 hrs', estimatedCost: '\$27', address: 'Boulevard Montmartre, Paris', durationMinutes: 90),
        ExplorePlaceItem(id: 'paris-kids-8', name: 'Natural History Museum Paris', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400', description: 'Marvel at the Grande Galerie de l\'Évolution with its stampede of taxidermied animals and dinosaur bones.', rating: 4.7, estimatedDuration: '2-3 hrs', estimatedCost: '\$12', address: 'Jardin des Plantes, Paris', durationMinutes: 150),
      ],
      2: [ // Religious
        ExplorePlaceItem(id: 'paris-rel-1', name: 'Notre-Dame Cathedral', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400', description: 'The gothic masterpiece of Paris, famous for its gargoyles, stunning rose windows, and historic bells.', rating: 4.9, estimatedDuration: '1-2 hrs', estimatedCost: 'Free', address: 'Île de la Cité, Paris', durationMinutes: 90),
        ExplorePlaceItem(id: 'paris-rel-2', name: 'Sacré-Cœur Basilica', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=400', description: 'The famous white dome crowning Montmartre hill, offering panoramic views and quiet reflection.', rating: 4.8, estimatedDuration: '1-2 hrs', estimatedCost: 'Free', address: 'Montmartre, Paris', durationMinutes: 90),
        ExplorePlaceItem(id: 'paris-rel-3', name: 'Sainte-Chapelle', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=400', description: 'A royal medieval chapel with 1,113 stained-glass windows depicting biblical history in glowing light.', rating: 4.8, estimatedDuration: '1 hr', estimatedCost: '\$13', address: 'Boulevard du Palais, Paris', durationMinutes: 60),
        ExplorePlaceItem(id: 'paris-rel-4', name: 'Saint-Germain-des-Prés Church', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400', description: 'The oldest church in Paris, dating back to the 6th century, with beautiful Romanesque architecture.', rating: 4.5, estimatedDuration: '45 min', estimatedCost: 'Free', address: 'Place Saint-Germain-des-Prés, Paris', durationMinutes: 45),
        ExplorePlaceItem(id: 'paris-rel-5', name: 'Église de la Madeleine', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=400', description: 'A grand neoclassical church resembling a Greek temple, with stunning interior columns and a pipe organ.', rating: 4.5, estimatedDuration: '45 min', estimatedCost: 'Free', address: 'Place de la Madeleine, Paris', durationMinutes: 45),
        ExplorePlaceItem(id: 'paris-rel-6', name: 'Grande Mosquée de Paris', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=400', description: 'Beautiful Hispano-Moorish architecture with serene gardens, a hammam, and a traditional tea salon.', rating: 4.6, estimatedDuration: '1-2 hrs', estimatedCost: '\$5', address: 'Rue Geoffrey Saint-Hilaire, Paris', durationMinutes: 90),
        ExplorePlaceItem(id: 'paris-rel-7', name: 'Panthéon', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400', description: 'A majestic former church now housing the tombs of France\'s greatest citizens, with Foucault\'s Pendulum.', rating: 4.7, estimatedDuration: '1 hr', estimatedCost: '\$13', address: 'Place du Panthéon, Paris', durationMinutes: 60),
        ExplorePlaceItem(id: 'paris-rel-8', name: 'Saint-Sulpice Church', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=400', description: 'Featured in The Da Vinci Code, this church has the famous gnomon sundial and stunning Delacroix frescoes.', rating: 4.4, estimatedDuration: '45 min', estimatedCost: 'Free', address: 'Place Saint-Sulpice, Paris', durationMinutes: 45),
      ],
      3: [ // Adventure
        ExplorePlaceItem(id: 'paris-adv-1', name: 'Eiffel Tower Stair Climb', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400', description: 'Climb 674 steps to the second floor of the Eiffel Tower for a unique, active perspective of Paris.', rating: 4.7, estimatedDuration: '2-3 hrs', estimatedCost: '\$12', address: 'Champ de Mars, Paris', durationMinutes: 150),
        ExplorePlaceItem(id: 'paris-adv-2', name: 'Catacombs of Paris', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', description: 'Explore the spooky underground ossuary holding the remains of over six million people in a maze of tunnels.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: '\$30', address: 'Avenue du Colonel Rol-Tanguy, Paris', durationMinutes: 120),
        ExplorePlaceItem(id: 'paris-adv-3', name: 'Hot Air Balloon at Parc André Citroën', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400', description: 'Float 150m above Paris in a tethered hot air balloon for breathtaking aerial views of the city.', rating: 4.5, estimatedDuration: '30 min', estimatedCost: '\$15', address: 'Parc André Citroën, Paris', durationMinutes: 30),
        ExplorePlaceItem(id: 'paris-adv-4', name: 'Seine River Kayaking', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', description: 'Paddle along the canals of Paris, passing under charming bridges and past historic buildings.', rating: 4.4, estimatedDuration: '2 hrs', estimatedCost: '\$35', address: 'Bassin de l\'Arsenal, Paris', durationMinutes: 120),
        ExplorePlaceItem(id: 'paris-adv-5', name: 'FlyView VR Flight Over Paris', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400', description: 'Strap into a jetpack simulator and soar over Paris in an immersive virtual reality experience.', rating: 4.5, estimatedDuration: '1 hr', estimatedCost: '\$20', address: 'Rue du 4 Septembre, Paris', durationMinutes: 60),
        ExplorePlaceItem(id: 'paris-adv-6', name: 'Accrobranche (Tree Climbing) Bois de Boulogne', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', description: 'Aerial adventure course through the treetops with ziplines, rope bridges, and swinging platforms.', rating: 4.4, estimatedDuration: '2-3 hrs', estimatedCost: '\$28', address: 'Bois de Boulogne, Paris', durationMinutes: 150),
        ExplorePlaceItem(id: 'paris-adv-7', name: 'Electric Scooter Tour Montmartre', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400', description: 'Zip through the winding streets and hidden stairways of Montmartre on a guided electric scooter tour.', rating: 4.3, estimatedDuration: '2 hrs', estimatedCost: '\$40', address: 'Montmartre, Paris', durationMinutes: 120),
        ExplorePlaceItem(id: 'paris-adv-8', name: 'Lock Picking & Escape Room Le Marais', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', description: 'Solve puzzles and crack codes in themed escape rooms set in historic Le Marais apartments.', rating: 4.6, estimatedDuration: '1.5 hrs', estimatedCost: '\$30', address: 'Le Marais, Paris', durationMinutes: 90),
      ],
      4: [ // Food & Culinary
        ExplorePlaceItem(id: 'paris-food-1', name: 'Rue Montorgueil Food Walk', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=400', description: 'Walk down a historic market street lined with the city\'s best bakeries, cheese shops, and cafes.', rating: 4.8, estimatedDuration: '2 hrs', estimatedCost: '\$20', address: 'Rue Montorgueil, Paris', durationMinutes: 120),
        ExplorePlaceItem(id: 'paris-food-2', name: 'Macaron & Pastry Workshop', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', description: 'Learn baking light, delicate French macarons from a professional Parisian chef.', rating: 4.9, estimatedDuration: '3 hrs', estimatedCost: '\$75', address: 'Latin Quarter, Paris', durationMinutes: 180),
        ExplorePlaceItem(id: 'paris-food-3', name: 'Le Marais Cheese & Wine Tasting', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=400', description: 'Sample 7 artisanal French cheeses paired with premium regional wines in a cozy cellar.', rating: 4.7, estimatedDuration: '2 hrs', estimatedCost: '\$55', address: 'Le Marais, Paris', durationMinutes: 120),
        ExplorePlaceItem(id: 'paris-food-4', name: 'Crêperie on Rue de Montparnasse', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', description: 'Savor authentic Breton galettes and sweet crêpes on Paris\'s famous crêpe street.', rating: 4.5, estimatedDuration: '1.5 hrs', estimatedCost: '\$18', address: 'Rue du Montparnasse, Paris', durationMinutes: 90),
        ExplorePlaceItem(id: 'paris-food-5', name: 'Parisian Boulangerie Crawl', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=400', description: 'Visit 4 of Paris\'s award-winning bakeries sampling croissants, pain au chocolat, and baguettes.', rating: 4.8, estimatedDuration: '2.5 hrs', estimatedCost: '\$15', address: 'Various, Paris', durationMinutes: 150),
        ExplorePlaceItem(id: 'paris-food-6', name: 'Marché d\'Aligre Morning Market', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', description: 'A bustling local market with fresh produce, spices, vintage items, and African-French street food.', rating: 4.4, estimatedDuration: '2 hrs', estimatedCost: '\$10', address: 'Place d\'Aligre, Paris', durationMinutes: 120),
        ExplorePlaceItem(id: 'paris-food-7', name: 'Chocolate & Hot Cocoa Tour', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=400', description: 'Visit master chocolatiers on the Left Bank, tasting ganaches, truffles, and rich hot chocolate.', rating: 4.7, estimatedDuration: '2 hrs', estimatedCost: '\$45', address: 'Saint-Germain, Paris', durationMinutes: 120),
        ExplorePlaceItem(id: 'paris-food-8', name: 'Bistro Dinner on Île Saint-Louis', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', description: 'Enjoy classic French bistro dinner—duck confit, coq au vin—on the charming island in the Seine.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: '\$50', address: 'Île Saint-Louis, Paris', durationMinutes: 120),
      ],
      5: [ // Culture & History
        ExplorePlaceItem(id: 'paris-cult-1', name: 'Louvre Museum', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', description: 'The world\'s largest art museum, home to the Mona Lisa, Winged Victory, and thousands of treasures.', rating: 4.9, estimatedDuration: '4-5 hrs', estimatedCost: '\$24', address: 'Rue de Rivoli, Paris', durationMinutes: 270),
        ExplorePlaceItem(id: 'paris-cult-2', name: 'Musée d\'Orsay', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=400', description: 'Located in a stunning former railway station, housing the world\'s largest impressionist collection.', rating: 4.8, estimatedDuration: '3 hrs', estimatedCost: '\$18', address: 'Esplanade Valéry Giscard d\'Estaing, Paris', durationMinutes: 180),
        ExplorePlaceItem(id: 'paris-cult-3', name: 'Palace of Versailles', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', description: 'The opulent royal palace with the Hall of Mirrors, Marie Antoinette\'s estate, and vast formal gardens.', rating: 4.9, estimatedDuration: '5-6 hrs', estimatedCost: '\$22', address: 'Place d\'Armes, Versailles', durationMinutes: 330),
        ExplorePlaceItem(id: 'paris-cult-4', name: 'Arc de Triomphe & Champs-Élysées', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=400', description: 'Climb to the top of Napoleon\'s triumphal arch for stunning views down the world\'s most famous avenue.', rating: 4.7, estimatedDuration: '1.5 hrs', estimatedCost: '\$16', address: 'Place Charles de Gaulle, Paris', durationMinutes: 90),
        ExplorePlaceItem(id: 'paris-cult-5', name: 'Musée de l\'Orangerie', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', description: 'Home to Monet\'s enormous Water Lilies murals displayed in two oval rooms, a truly immersive experience.', rating: 4.7, estimatedDuration: '1.5 hrs', estimatedCost: '\$14', address: 'Jardin des Tuileries, Paris', durationMinutes: 90),
        ExplorePlaceItem(id: 'paris-cult-6', name: 'Centre Pompidou', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=400', description: 'Iconic modern art museum with its inside-out architecture, housing works by Picasso, Kandinsky, and Warhol.', rating: 4.6, estimatedDuration: '2-3 hrs', estimatedCost: '\$17', address: 'Place Georges-Pompidou, Paris', durationMinutes: 150),
        ExplorePlaceItem(id: 'paris-cult-7', name: 'Musée Rodin', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', description: 'Beautiful mansion and garden showcasing Rodin\'s masterpieces including The Thinker and The Kiss.', rating: 4.6, estimatedDuration: '1.5 hrs', estimatedCost: '\$14', address: 'Rue de Varenne, Paris', durationMinutes: 90),
        ExplorePlaceItem(id: 'paris-cult-8', name: 'Conciergerie (Marie Antoinette\'s Prison)', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=400', description: 'Medieval royal palace turned prison during the French Revolution, where Marie Antoinette was held.', rating: 4.5, estimatedDuration: '1 hr', estimatedCost: '\$12', address: 'Boulevard du Palais, Paris', durationMinutes: 60),
      ],
      6: [ // Shopping
        ExplorePlaceItem(id: 'paris-shop-1', name: 'Champs-Élysées Boulevard', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', description: 'Stroll the world-famous avenue lined with luxury flagship stores, classic cinemas, and the Arc de Triomphe.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Avenue des Champs-Élysées, Paris', durationMinutes: 120),
        ExplorePlaceItem(id: 'paris-shop-2', name: 'Galeries Lafayette Haussmann', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400', description: 'A gorgeous high-end department store famous for its stunning neo-byzantine glass dome and rooftop views.', rating: 4.7, estimatedDuration: '2-3 hrs', estimatedCost: 'Free', address: 'Boulevard Haussmann, Paris', durationMinutes: 150),
        ExplorePlaceItem(id: 'paris-shop-3', name: 'Le Bon Marché', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', description: 'The world\'s first department store, now a sophisticated Left Bank destination with La Grande Epicerie food hall.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Rue de Sèvres, Paris', durationMinutes: 120),
        ExplorePlaceItem(id: 'paris-shop-4', name: 'Saint-Ouen Flea Market', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400', description: 'The world\'s largest antique market with 2,500 stalls selling vintage furniture, art, clothing, and curios.', rating: 4.5, estimatedDuration: '3 hrs', estimatedCost: 'Free', address: 'Rue des Rosiers, Saint-Ouen', durationMinutes: 180),
        ExplorePlaceItem(id: 'paris-shop-5', name: 'Rue du Faubourg Saint-Honoré', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', description: 'Paris\'s most prestigious fashion street with Hermès, Chanel, Dior, and the Élysée Palace.', rating: 4.7, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Faubourg Saint-Honoré, Paris', durationMinutes: 120),
        ExplorePlaceItem(id: 'paris-shop-6', name: 'Le Marais Boutiques', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400', description: 'Trendy independent boutiques, concept stores, and vintage shops in one of Paris\'s hippest neighborhoods.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Le Marais, Paris', durationMinutes: 120),
        ExplorePlaceItem(id: 'paris-shop-7', name: 'Rue de Rivoli Shopping', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', description: 'A long shopping street with popular international brands, souvenir shops, and direct Louvre access.', rating: 4.3, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'Rue de Rivoli, Paris', durationMinutes: 90),
        ExplorePlaceItem(id: 'paris-shop-8', name: 'Place Vendôme Jewelers', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400', description: 'The square of luxury—home to Cartier, Boucheron, Van Cleef & Arpels, and the Ritz Paris.', rating: 4.8, estimatedDuration: '1 hr', estimatedCost: 'Free', address: 'Place Vendôme, Paris', durationMinutes: 60),
      ],
      7: [ // Nightlife
        ExplorePlaceItem(id: 'paris-night-1', name: 'Moulin Rouge Cabaret Show', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400', description: 'The birthplace of the can-can, offering glamorous feathers, rhinestones, and dazzling choreography.', rating: 4.7, estimatedDuration: '2 hrs', estimatedCost: '\$110', address: 'Boulevard de Clichy, Paris', durationMinutes: 120),
        ExplorePlaceItem(id: 'paris-night-2', name: 'Seine River Dinner Cruise', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Enjoy a gourmet 3-course French dinner sailing past the illuminated monuments of Paris.', rating: 4.8, estimatedDuration: '2-3 hrs', estimatedCost: '\$80', address: 'Port de la Bourdonnais, Paris', durationMinutes: 150),
        ExplorePlaceItem(id: 'paris-night-3', name: 'Jazz Club Saint-Germain', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400', description: 'Experience live jazz in intimate Left Bank cellars where legends like Miles Davis once played.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: '\$25', address: 'Rue de la Huchette, Paris', durationMinutes: 120),
        ExplorePlaceItem(id: 'paris-night-4', name: 'Rooftop Bar at Le Perchoir', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Trendy rooftop cocktail bar with panoramic views of Paris rooftops and the Eiffel Tower at night.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: '\$20', address: 'Rue Crespin du Gast, Paris', durationMinutes: 120),
        ExplorePlaceItem(id: 'paris-night-5', name: 'Eiffel Tower Sparkling Light Show', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400', description: 'Watch the Eiffel Tower sparkle with 20,000 lights every hour from Trocadéro gardens.', rating: 4.9, estimatedDuration: '1 hr', estimatedCost: 'Free', address: 'Trocadéro, Paris', durationMinutes: 60),
        ExplorePlaceItem(id: 'paris-night-6', name: 'Oberkampf Bar Crawl', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Bar-hop through the vibrant Oberkampf neighborhood, known for eclectic cocktail bars and DJ sets.', rating: 4.4, estimatedDuration: '3 hrs', estimatedCost: '\$30', address: 'Rue Oberkampf, Paris', durationMinutes: 180),
        ExplorePlaceItem(id: 'paris-night-7', name: 'Opera Garnier Evening Tour', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400', description: 'Tour the opulent Palais Garnier after dark, seeing the Chagall ceiling and the Phantom\'s underground lake.', rating: 4.7, estimatedDuration: '1.5 hrs', estimatedCost: '\$17', address: 'Place de l\'Opéra, Paris', durationMinutes: 90),
        ExplorePlaceItem(id: 'paris-night-8', name: 'Crazy Horse Cabaret', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'An avant-garde Parisian cabaret known for artistic lighting, choreography, and spectacular staging.', rating: 4.5, estimatedDuration: '1.5 hrs', estimatedCost: '\$95', address: 'Avenue George V, Paris', durationMinutes: 90),
      ],
    };
  }

  // =============================================
  // TOKYO — 8-10 places per genre
  // =============================================
  Map<int, List<ExplorePlaceItem>> _buildTokyoPlaces() {
    return {
      0: [
        ExplorePlaceItem(id: 'tky-beach-1', name: 'Odaiba Beach', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400', description: 'Man-made beach with Rainbow Bridge views, sunset strolls, and the iconic Statue of Liberty replica.', rating: 4.4, estimatedDuration: '2-3 hrs', estimatedCost: 'Free', address: 'Odaiba, Tokyo', durationMinutes: 150),
        ExplorePlaceItem(id: 'tky-beach-2', name: 'Enoshima Island Beach', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'A tropical island vibe just 1 hour from Tokyo with surfing, caves, shrines, and fresh seafood.', rating: 4.7, estimatedDuration: '5-6 hrs', estimatedCost: '\$15', address: 'Enoshima, Kanagawa', durationMinutes: 330),
        ExplorePlaceItem(id: 'tky-beach-3', name: 'Sumida River Cruise', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400', description: 'Ride a futuristic water bus along the Sumida River, passing under 12 bridges with stunning skyline views.', rating: 4.5, estimatedDuration: '1 hr', estimatedCost: '\$10', address: 'Asakusa Pier, Tokyo', durationMinutes: 60),
        ExplorePlaceItem(id: 'tky-beach-4', name: 'Tokyo Summer Land Water Park', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=400', description: 'Massive water park with wave pools, lazy rivers, and thrilling water slides.', rating: 4.3, estimatedDuration: '4-5 hrs', estimatedCost: '\$30', address: 'Akiruno, Tokyo', durationMinutes: 270),
        ExplorePlaceItem(id: 'tky-beach-5', name: 'Kasai Rinkai Beach Park', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400', description: 'Sandy beach and bird sanctuary along Tokyo Bay with views of the Ferris wheel and aquarium.', rating: 4.3, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Edogawa, Tokyo', durationMinutes: 120),
        ExplorePlaceItem(id: 'tky-beach-6', name: 'Zushi Beach', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Laid-back beach town 50 min from Tokyo, popular with families and known for clean sand and calm waves.', rating: 4.4, estimatedDuration: '4 hrs', estimatedCost: 'Free', address: 'Zushi, Kanagawa', durationMinutes: 240),
        ExplorePlaceItem(id: 'tky-beach-7', name: 'Shinagawa Aquarium', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=400', description: 'Charming aquarium with dolphin shows, tunnel tanks, and jellyfish galleries near the waterfront.', rating: 4.4, estimatedDuration: '2 hrs', estimatedCost: '\$10', address: 'Shinagawa, Tokyo', durationMinutes: 120),
        ExplorePlaceItem(id: 'tky-beach-8', name: 'Palette Town Odaiba', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400', description: 'Entertainment complex with the giant Ferris wheel, digital art museum, and seaside boardwalk.', rating: 4.5, estimatedDuration: '3 hrs', estimatedCost: '\$15', address: 'Odaiba, Tokyo', durationMinutes: 180),
      ],
      1: [
        ExplorePlaceItem(id: 'tky-kids-1', name: 'Tokyo Disneyland', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1624601573012-efb68931cc8f?w=400', description: 'The magical kingdom with parades, fireworks, and beloved Disney rides for all ages.', rating: 4.9, estimatedDuration: '8-10 hrs', estimatedCost: '\$75', address: 'Urayasu, Chiba', durationMinutes: 480),
        ExplorePlaceItem(id: 'tky-kids-2', name: 'Ghibli Museum', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400', description: 'Enter the whimsical world of Studio Ghibli with giant Totoro, Cat Bus, and exclusive short films.', rating: 4.9, estimatedDuration: '3 hrs', estimatedCost: '\$10', address: 'Mitaka, Tokyo', durationMinutes: 180),
        ExplorePlaceItem(id: 'tky-kids-3', name: 'teamLab Borderless', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1534567153574-2b12153a63f0?w=400', description: 'Immersive digital art museum where interactive projections respond to touch and movement.', rating: 4.8, estimatedDuration: '2-3 hrs', estimatedCost: '\$20', address: 'Azabudai, Tokyo', durationMinutes: 150),
        ExplorePlaceItem(id: 'tky-kids-4', name: 'Ueno Zoo', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1624601573012-efb68931cc8f?w=400', description: 'Japan\'s oldest zoo featuring pandas, polar bears, gorillas, and a petting zoo for children.', rating: 4.5, estimatedDuration: '3 hrs', estimatedCost: '\$5', address: 'Ueno Park, Tokyo', durationMinutes: 180),
        ExplorePlaceItem(id: 'tky-kids-5', name: 'Kidzania Tokyo', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400', description: 'Indoor city where kids role-play adult jobs—pilot, firefighter, doctor—and earn play money.', rating: 4.6, estimatedDuration: '4-5 hrs', estimatedCost: '\$25', address: 'Toyosu, Tokyo', durationMinutes: 270),
        ExplorePlaceItem(id: 'tky-kids-6', name: 'National Science Museum', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1534567153574-2b12153a63f0?w=400', description: 'Dinosaur fossils, space exhibits, and hands-on science experiments in Ueno Park.', rating: 4.6, estimatedDuration: '2-3 hrs', estimatedCost: '\$5', address: 'Ueno Park, Tokyo', durationMinutes: 150),
        ExplorePlaceItem(id: 'tky-kids-7', name: 'Sanrio Puroland', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1624601573012-efb68931cc8f?w=400', description: 'Hello Kitty\'s indoor theme park with character shows, rides, and adorable photo spots.', rating: 4.5, estimatedDuration: '4 hrs', estimatedCost: '\$30', address: 'Tama, Tokyo', durationMinutes: 240),
        ExplorePlaceItem(id: 'tky-kids-8', name: 'Pokémon Center Mega Tokyo', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400', description: 'The ultimate Pokémon merchandise store with exclusive toys, plushies, and a giant Pikachu statue.', rating: 4.7, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'Ikebukuro, Tokyo', durationMinutes: 90),
      ],
      2: [
        ExplorePlaceItem(id: 'tky-rel-1', name: 'Sensō-ji Temple', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400', description: 'Tokyo\'s oldest temple with the iconic Thunder Gate, incense cauldrons, and Nakamise shopping street.', rating: 4.9, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'Asakusa, Tokyo', durationMinutes: 90),
        ExplorePlaceItem(id: 'tky-rel-2', name: 'Meiji Shrine', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=400', description: 'A serene Shinto shrine surrounded by 170,000 trees in the heart of Harajuku.', rating: 4.8, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'Shibuya, Tokyo', durationMinutes: 90),
        ExplorePlaceItem(id: 'tky-rel-3', name: 'Zōjō-ji Temple', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=400', description: 'Grand temple near Tokyo Tower with hundreds of Jizo statues and panoramic views of the tower.', rating: 4.6, estimatedDuration: '1 hr', estimatedCost: 'Free', address: 'Minato, Tokyo', durationMinutes: 60),
        ExplorePlaceItem(id: 'tky-rel-4', name: 'Nezu Shrine', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400', description: 'A hidden gem with 3,000 azalea bushes, vermillion torii gates, and beautiful traditional architecture.', rating: 4.7, estimatedDuration: '1 hr', estimatedCost: 'Free', address: 'Bunkyo, Tokyo', durationMinutes: 60),
        ExplorePlaceItem(id: 'tky-rel-5', name: 'Gotoku-ji Temple (Lucky Cat)', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=400', description: 'The birthplace of the beckoning cat (maneki-neko) with hundreds of waving cat figurines on display.', rating: 4.6, estimatedDuration: '1 hr', estimatedCost: 'Free', address: 'Setagaya, Tokyo', durationMinutes: 60),
        ExplorePlaceItem(id: 'tky-rel-6', name: 'Yasukuni Shrine', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=400', description: 'Controversial but beautiful Shinto shrine with a war museum and cherry blossoms in spring.', rating: 4.4, estimatedDuration: '1 hr', estimatedCost: 'Free', address: 'Chiyoda, Tokyo', durationMinutes: 60),
        ExplorePlaceItem(id: 'tky-rel-7', name: 'Sengaku-ji Temple', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400', description: 'Famous temple where the 47 Ronin are buried—a site steeped in samurai loyalty and honor.', rating: 4.5, estimatedDuration: '1 hr', estimatedCost: 'Free', address: 'Minato, Tokyo', durationMinutes: 60),
        ExplorePlaceItem(id: 'tky-rel-8', name: 'Hie Shrine', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=400', description: 'A hidden shrine in Akasaka with rows of vermilion torii gates leading up a forested hillside.', rating: 4.4, estimatedDuration: '45 min', estimatedCost: 'Free', address: 'Chiyoda, Tokyo', durationMinutes: 45),
      ],
      3: [
        ExplorePlaceItem(id: 'tky-adv-1', name: 'Tokyo Tower Top Deck', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400', description: 'Climb to the 250m observation deck for 360° views, especially stunning at sunset and night.', rating: 4.7, estimatedDuration: '1.5 hrs', estimatedCost: '\$15', address: 'Minato, Tokyo', durationMinutes: 90),
        ExplorePlaceItem(id: 'tky-adv-2', name: 'Go-Kart Street Racing', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', description: 'Drive go-karts through the streets of Tokyo in costumes—a real-life Mario Kart experience.', rating: 4.8, estimatedDuration: '2 hrs', estimatedCost: '\$80', address: 'Shibuya, Tokyo', durationMinutes: 120),
        ExplorePlaceItem(id: 'tky-adv-3', name: 'Tokyo Skytree', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400', description: 'The tallest tower in Japan at 634m with glass floors and views stretching to Mt. Fuji on clear days.', rating: 4.8, estimatedDuration: '2 hrs', estimatedCost: '\$20', address: 'Sumida, Tokyo', durationMinutes: 120),
        ExplorePlaceItem(id: 'tky-adv-4', name: 'Helicopter Tour Over Tokyo Bay', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', description: 'Soar above Rainbow Bridge, Tokyo Tower, and the waterfront in a thrilling helicopter flight.', rating: 4.7, estimatedDuration: '30 min', estimatedCost: '\$150', address: 'Shin-Kiba Heliport, Tokyo', durationMinutes: 30),
        ExplorePlaceItem(id: 'tky-adv-5', name: 'Mt. Takao Hiking', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400', description: 'A scenic 1-hour hike to the summit of Mt. Takao, with monkeys, a temple, and Mt. Fuji views.', rating: 4.7, estimatedDuration: '4 hrs', estimatedCost: '\$5', address: 'Hachioji, Tokyo', durationMinutes: 240),
        ExplorePlaceItem(id: 'tky-adv-6', name: 'VR Zone Shinjuku', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', description: 'State-of-the-art VR arcade with Dragon Ball, Evangelion, and horror-themed virtual reality experiences.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: '\$25', address: 'Shinjuku, Tokyo', durationMinutes: 120),
        ExplorePlaceItem(id: 'tky-adv-7', name: 'Indoor Skydiving FlyStation', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400', description: 'Experience free-fall sensation in a vertical wind tunnel without jumping from a plane.', rating: 4.4, estimatedDuration: '1 hr', estimatedCost: '\$35', address: 'Koshigaya, Saitama', durationMinutes: 60),
        ExplorePlaceItem(id: 'tky-adv-8', name: 'Sumo Wrestling Experience', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', description: 'Watch a morning sumo practice session at a stable, or try on a mawashi and enter the ring yourself.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: '\$30', address: 'Ryogoku, Tokyo', durationMinutes: 120),
      ],
      4: [
        ExplorePlaceItem(id: 'tky-food-1', name: 'Tsukiji Outer Market', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=400', description: 'Street food paradise with fresh sushi, tamagoyaki, strawberry mochi, and matcha lattes.', rating: 4.8, estimatedDuration: '2 hrs', estimatedCost: '\$20', address: 'Tsukiji, Tokyo', durationMinutes: 120),
        ExplorePlaceItem(id: 'tky-food-2', name: 'Ramen Street (Tokyo Station)', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', description: 'Underground lane of Japan\'s top ramen shops, each serving unique regional broths and noodles.', rating: 4.7, estimatedDuration: '1.5 hrs', estimatedCost: '\$12', address: 'Tokyo Station, Chiyoda', durationMinutes: 90),
        ExplorePlaceItem(id: 'tky-food-3', name: 'Sushi Making Class', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=400', description: 'Learn to make nigiri and maki rolls from a Japanese sushi master at a hands-on cooking class.', rating: 4.9, estimatedDuration: '2.5 hrs', estimatedCost: '\$60', address: 'Asakusa, Tokyo', durationMinutes: 150),
        ExplorePlaceItem(id: 'tky-food-4', name: 'Yakitori Alley (Memory Lane)', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', description: 'Narrow alley near Shinjuku station with tiny yakitori bars grilling skewered chicken over charcoal.', rating: 4.6, estimatedDuration: '1.5 hrs', estimatedCost: '\$15', address: 'Nishi-Shinjuku, Tokyo', durationMinutes: 90),
        ExplorePlaceItem(id: 'tky-food-5', name: 'Depachika (Department Store Food Halls)', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=400', description: 'Explore the stunning basement food halls of Isetan or Mitsukoshi, packed with gourmet bento, wagashi, and gifts.', rating: 4.7, estimatedDuration: '1.5 hrs', estimatedCost: '\$20', address: 'Shinjuku/Ginza, Tokyo', durationMinutes: 90),
        ExplorePlaceItem(id: 'tky-food-6', name: 'Izakaya Hopping in Yurakucho', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', description: 'Tiny lantern-lit bars under the train tracks serving yakitori, beer, and local bar snacks.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: '\$20', address: 'Yurakucho, Tokyo', durationMinutes: 120),
        ExplorePlaceItem(id: 'tky-food-7', name: 'Matcha Tasting in Uji-style Tea House', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=400', description: 'Traditional tea ceremony experience with premium ceremonial matcha, wagashi sweets, and tatami seating.', rating: 4.6, estimatedDuration: '1 hr', estimatedCost: '\$15', address: 'Aoyama, Tokyo', durationMinutes: 60),
        ExplorePlaceItem(id: 'tky-food-8', name: 'Wagyu Beef Teppanyaki Dinner', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', description: 'Watch a chef grill premium A5 wagyu beef on an iron plate, served with seasonal vegetables.', rating: 4.9, estimatedDuration: '2 hrs', estimatedCost: '\$100', address: 'Ginza, Tokyo', durationMinutes: 120),
      ],
      5: [
        ExplorePlaceItem(id: 'tky-cult-1', name: 'Tokyo National Museum', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', description: 'Japan\'s oldest and largest museum with samurai swords, kimonos, ceramics, and Buddhist sculptures.', rating: 4.8, estimatedDuration: '3 hrs', estimatedCost: '\$8', address: 'Ueno Park, Tokyo', durationMinutes: 180),
        ExplorePlaceItem(id: 'tky-cult-2', name: 'Imperial Palace East Gardens', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=400', description: 'Former site of Edo Castle, now serene gardens with moats, stone walls, and seasonal blooms.', rating: 4.6, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'Chiyoda, Tokyo', durationMinutes: 90),
        ExplorePlaceItem(id: 'tky-cult-3', name: 'Edo-Tokyo Museum', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', description: 'Walk through life-size replicas of Edo-period streets, shops, and theaters showing Tokyo\'s transformation.', rating: 4.7, estimatedDuration: '2.5 hrs', estimatedCost: '\$8', address: 'Ryogoku, Tokyo', durationMinutes: 150),
        ExplorePlaceItem(id: 'tky-cult-4', name: 'Harajuku & Takeshita Street', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=400', description: 'The epicenter of Tokyo youth fashion, cosplay culture, candy-colored crêpe shops, and quirky style.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Harajuku, Tokyo', durationMinutes: 120),
        ExplorePlaceItem(id: 'tky-cult-5', name: 'Akihabara Electric Town', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', description: 'The mecca of anime, manga, gaming, and electronics with multi-story shops and maid cafés.', rating: 4.7, estimatedDuration: '2-3 hrs', estimatedCost: 'Free', address: 'Akihabara, Tokyo', durationMinutes: 150),
        ExplorePlaceItem(id: 'tky-cult-6', name: 'Samurai Museum', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=400', description: 'Try on samurai armor, hold replica swords, and learn about Japan\'s warrior class through guided tours.', rating: 4.5, estimatedDuration: '1.5 hrs', estimatedCost: '\$15', address: 'Shinjuku, Tokyo', durationMinutes: 90),
        ExplorePlaceItem(id: 'tky-cult-7', name: 'Mori Art Museum', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', description: 'Contemporary art museum on the 53rd floor of Roppongi Hills with city views and rotating exhibitions.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: '\$18', address: 'Roppongi, Tokyo', durationMinutes: 120),
        ExplorePlaceItem(id: 'tky-cult-8', name: 'Yanaka Old Town', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=400', description: 'A preserved neighborhood from old Tokyo with wooden houses, local craftsmen, and cat-themed shops.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Yanaka, Tokyo', durationMinutes: 120),
      ],
      6: [
        ExplorePlaceItem(id: 'tky-shop-1', name: 'Ginza Shopping District', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', description: 'Tokyo\'s premier luxury shopping area with flagship stores, department stores, and designer boutiques.', rating: 4.7, estimatedDuration: '2-3 hrs', estimatedCost: 'Free', address: 'Ginza, Tokyo', durationMinutes: 150),
        ExplorePlaceItem(id: 'tky-shop-2', name: 'Shibuya 109', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400', description: 'The iconic cylindrical fashion building with 10 floors of trendy Japanese youth fashion brands.', rating: 4.5, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'Shibuya, Tokyo', durationMinutes: 90),
        ExplorePlaceItem(id: 'tky-shop-3', name: 'Omotesando Avenue', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', description: 'Tokyo\'s Champs-Élysées with tree-lined streets, architect-designed flagship stores, and concept shops.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Omotesando, Tokyo', durationMinutes: 120),
        ExplorePlaceItem(id: 'tky-shop-4', name: 'Ameyoko Market', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400', description: 'Bustling street market near Ueno station selling fresh seafood, dried fruits, sneakers, and cosmetics.', rating: 4.5, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'Ueno, Tokyo', durationMinutes: 90),
        ExplorePlaceItem(id: 'tky-shop-5', name: 'Nakamise Shopping Street', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', description: 'Historic shopping lane leading to Sensō-ji temple, selling traditional snacks, fans, and kimonos.', rating: 4.6, estimatedDuration: '1 hr', estimatedCost: 'Free', address: 'Asakusa, Tokyo', durationMinutes: 60),
        ExplorePlaceItem(id: 'tky-shop-6', name: 'Don Quijote (Mega Store)', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400', description: 'Massive discount store packed floor-to-ceiling with snacks, gadgets, costumes, and souvenirs.', rating: 4.4, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'Shibuya/Shinjuku, Tokyo', durationMinutes: 90),
        ExplorePlaceItem(id: 'tky-shop-7', name: 'Shimokitazawa Vintage Shops', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', description: 'Tokyo\'s hippest thrift neighborhood with second-hand clothing, record shops, and cozy cafes.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Shimokitazawa, Tokyo', durationMinutes: 120),
        ExplorePlaceItem(id: 'tky-shop-8', name: 'Kappabashi Kitchen Street', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400', description: 'The kitchen supply district with realistic plastic food samples, knives, ceramics, and cooking tools.', rating: 4.4, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'Taito, Tokyo', durationMinutes: 90),
      ],
      7: [
        ExplorePlaceItem(id: 'tky-night-1', name: 'Golden Gai Bar Hopping', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400', description: 'Six narrow alleys of 200+ tiny bars, each seating only 5-10 people, with unique themes and characters.', rating: 4.8, estimatedDuration: '3 hrs', estimatedCost: '\$30', address: 'Shinjuku, Tokyo', durationMinutes: 180),
        ExplorePlaceItem(id: 'tky-night-2', name: 'Shibuya Crossing at Night', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Experience the world\'s busiest intersection glowing with giant neon screens after dark.', rating: 4.7, estimatedDuration: '1 hr', estimatedCost: 'Free', address: 'Shibuya, Tokyo', durationMinutes: 60),
        ExplorePlaceItem(id: 'tky-night-3', name: 'Robot Restaurant Show', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400', description: 'A wild, neon-lit spectacle featuring giant robots, dancers, drummers, and laser shows.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: '\$80', address: 'Kabukichō, Tokyo', durationMinutes: 120),
        ExplorePlaceItem(id: 'tky-night-4', name: 'Roppongi Hills Night View', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Open-air observation deck on the rooftop of Mori Tower with stunning Tokyo Tower night views.', rating: 4.6, estimatedDuration: '1.5 hrs', estimatedCost: '\$15', address: 'Roppongi, Tokyo', durationMinutes: 90),
        ExplorePlaceItem(id: 'tky-night-5', name: 'Karaoke in Shibuya', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400', description: 'Sing your heart out in a private karaoke room with unlimited drinks and Japanese snacks.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: '\$20', address: 'Shibuya, Tokyo', durationMinutes: 120),
        ExplorePlaceItem(id: 'tky-night-6', name: 'Omoide Yokocho (Piss Alley)', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Atmospheric smoky alley near Shinjuku station with tiny yakitori and ramen stalls.', rating: 4.5, estimatedDuration: '1.5 hrs', estimatedCost: '\$15', address: 'Nishi-Shinjuku, Tokyo', durationMinutes: 90),
        ExplorePlaceItem(id: 'tky-night-7', name: 'Sumida River Yakatabune Dinner Cruise', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400', description: 'Traditional Japanese houseboat dinner cruise along the Sumida River with tempura and sake.', rating: 4.7, estimatedDuration: '2.5 hrs', estimatedCost: '\$70', address: 'Sumida, Tokyo', durationMinutes: 150),
        ExplorePlaceItem(id: 'tky-night-8', name: 'Shinjuku Ni-chōme LGBTQ Scene', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Tokyo\'s vibrant and welcoming LGBTQ bar district with drag shows, themed bars, and dance clubs.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: '\$20', address: 'Shinjuku, Tokyo', durationMinutes: 120),
      ],
    };
  }

  // =============================================
  // LONDON / NYC / SINGAPORE — 8 places per genre
  // =============================================
  Map<int, List<ExplorePlaceItem>> _buildLondonPlaces() {
    return {
      0: [
        ExplorePlaceItem(id: 'ldn-beach-1', name: 'Serpentine Lido (Hyde Park)', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400', description: 'Swim in the legendary Serpentine lake in Hyde Park, a beloved summer swimming spot since 1930.', rating: 4.4, estimatedDuration: '2 hrs', estimatedCost: '\$8', address: 'Hyde Park, London', durationMinutes: 120),
        ExplorePlaceItem(id: 'ldn-beach-2', name: 'Brighton Beach Day Trip', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Just 1 hour by train from London, enjoy Brighton\'s iconic pebble beach, Palace Pier, and seaside fish & chips.', rating: 4.6, estimatedDuration: '6-8 hrs', estimatedCost: '\$25', address: 'Brighton, Sussex', durationMinutes: 420),
        ExplorePlaceItem(id: 'ldn-beach-3', name: 'Hampstead Heath Ponds', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400', description: 'Wild swimming in open-air ponds surrounded by ancient woodland on the edge of London.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: '\$5', address: 'Hampstead, London', durationMinutes: 120),
        ExplorePlaceItem(id: 'ldn-beach-4', name: 'Victoria Park Summer Splash', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=400', description: 'East London\'s favourite park with boating lake, splash fountains, live music, and summer festivals.', rating: 4.3, estimatedDuration: '2-3 hrs', estimatedCost: 'Free', address: 'Victoria Park, London', durationMinutes: 150),
        ExplorePlaceItem(id: 'ldn-beach-5', name: 'Thames River Speedboat Ride', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Thrilling 50-minute speedboat along the Thames past Big Ben, Tower Bridge, and Greenwich.', rating: 4.7, estimatedDuration: '1 hr', estimatedCost: '\$50', address: 'Westminster Pier, London', durationMinutes: 60),
        ExplorePlaceItem(id: 'ldn-beach-6', name: 'Southend-on-Sea Beach', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400', description: 'Family beach town with the world\'s longest pleasure pier, amusement parks, and fish & chip shops.', rating: 4.3, estimatedDuration: '5-6 hrs', estimatedCost: '\$20', address: 'Southend, Essex', durationMinutes: 330),
        ExplorePlaceItem(id: 'ldn-beach-7', name: 'Regents Park Boating Lake', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=400', description: 'Row boats and pedal boats on the ornamental lake surrounded by rose gardens and London Zoo.', rating: 4.4, estimatedDuration: '1.5 hrs', estimatedCost: '\$12', address: 'Regent\'s Park, London', durationMinutes: 90),
        ExplorePlaceItem(id: 'ldn-beach-8', name: 'London Fields Lido', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400', description: 'Heated Olympic-size outdoor pool in trendy Hackney, open year-round but best in summer.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: '\$8', address: 'London Fields, London', durationMinutes: 120),
      ],
      1: [
        ExplorePlaceItem(id: 'ldn-kids-1', name: 'Warner Bros. Studio Tour', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1624601573012-efb68931cc8f?w=400', description: 'Step into the actual sets of the Harry Potter movies. See the Great Hall, Diagon Alley, and taste Butterbeer.', rating: 4.9, estimatedDuration: '4-5 hrs', estimatedCost: '\$65', address: 'Leavesden, Watford', durationMinutes: 270),
        ExplorePlaceItem(id: 'ldn-kids-2', name: 'Natural History Museum', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400', description: 'Home to dinosaur skeletons, the giant blue whale, and interactive exhibits for all ages.', rating: 4.8, estimatedDuration: '3-4 hrs', estimatedCost: 'Free', address: 'South Kensington, London', durationMinutes: 210),
        ExplorePlaceItem(id: 'ldn-kids-3', name: 'London Eye', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1624601573012-efb68931cc8f?w=400', description: 'Ride the iconic observation wheel for stunning 30-minute views of the Thames and Parliament.', rating: 4.7, estimatedDuration: '1 hr', estimatedCost: '\$35', address: 'South Bank, London', durationMinutes: 60),
        ExplorePlaceItem(id: 'ldn-kids-4', name: 'Science Museum', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1534567153574-2b12153a63f0?w=400', description: 'Free museum with flight simulators, space galleries, and an IMAX cinema in South Kensington.', rating: 4.7, estimatedDuration: '3 hrs', estimatedCost: 'Free', address: 'Exhibition Rd, London', durationMinutes: 180),
        ExplorePlaceItem(id: 'ldn-kids-5', name: 'London Zoo', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400', description: 'The world\'s oldest scientific zoo with over 750 species including tigers, gorillas, and penguins.', rating: 4.6, estimatedDuration: '3-4 hrs', estimatedCost: '\$30', address: 'Regent\'s Park, London', durationMinutes: 210),
        ExplorePlaceItem(id: 'ldn-kids-6', name: 'Shrek\'s Adventure', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1624601573012-efb68931cc8f?w=400', description: 'Interactive DreamWorks experience with Shrek, Donkey, and Princess Fiona on the South Bank.', rating: 4.3, estimatedDuration: '1.5 hrs', estimatedCost: '\$28', address: 'South Bank, London', durationMinutes: 90),
        ExplorePlaceItem(id: 'ldn-kids-7', name: 'SEA LIFE London Aquarium', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400', description: 'Over 600 marine species including sharks, rays, penguins, and a tropical rainforest zone.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: '\$30', address: 'South Bank, London', durationMinutes: 120),
        ExplorePlaceItem(id: 'ldn-kids-8', name: 'Diana Memorial Playground', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1534567153574-2b12153a63f0?w=400', description: 'A Peter Pan-themed adventure playground in Kensington Gardens with a pirate ship and teepees.', rating: 4.7, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'Kensington Gardens, London', durationMinutes: 90),
      ],
      2: [
        ExplorePlaceItem(id: 'ldn-rel-1', name: 'Westminster Abbey', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400', description: 'The coronation church since 1066. See the tombs of kings, queens, and writers in Poets\' Corner.', rating: 4.9, estimatedDuration: '2 hrs', estimatedCost: '\$32', address: 'Westminster, London', durationMinutes: 120),
        ExplorePlaceItem(id: 'ldn-rel-2', name: 'St. Paul\'s Cathedral', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=400', description: 'Sir Christopher Wren\'s masterpiece. Climb to the Whispering Gallery and Stone Gallery for city views.', rating: 4.8, estimatedDuration: '2 hrs', estimatedCost: '\$28', address: 'Ludgate Hill, London', durationMinutes: 120),
        ExplorePlaceItem(id: 'ldn-rel-3', name: 'Temple Church', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=400', description: 'Circular church built by the Knights Templar in 1185, featured in The Da Vinci Code.', rating: 4.5, estimatedDuration: '45 min', estimatedCost: '\$5', address: 'Temple, London', durationMinutes: 45),
        ExplorePlaceItem(id: 'ldn-rel-4', name: 'Southwark Cathedral', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400', description: 'Gothic cathedral near Borough Market with Shakespeare memorials and beautiful stained glass.', rating: 4.5, estimatedDuration: '45 min', estimatedCost: 'Free', address: 'Southwark, London', durationMinutes: 45),
        ExplorePlaceItem(id: 'ldn-rel-5', name: 'BAPS Shri Swaminarayan Mandir', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=400', description: 'Stunning Hindu temple carved from Italian marble and Bulgarian limestone, an architectural wonder.', rating: 4.8, estimatedDuration: '1 hr', estimatedCost: 'Free', address: 'Neasden, London', durationMinutes: 60),
        ExplorePlaceItem(id: 'ldn-rel-6', name: 'Westminster Cathedral', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=400', description: 'London\'s principal Catholic church with stunning Byzantine architecture and a bell tower with views.', rating: 4.5, estimatedDuration: '45 min', estimatedCost: 'Free', address: 'Victoria, London', durationMinutes: 45),
        ExplorePlaceItem(id: 'ldn-rel-7', name: 'St. Martin-in-the-Fields', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400', description: 'Beautiful church on Trafalgar Square known for free lunchtime concerts and a crypt café.', rating: 4.4, estimatedDuration: '45 min', estimatedCost: 'Free', address: 'Trafalgar Square, London', durationMinutes: 45),
        ExplorePlaceItem(id: 'ldn-rel-8', name: 'Bevis Marks Synagogue', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=400', description: 'Britain\'s oldest synagogue (1701) with original Queen Anne chandeliers and beautiful interior.', rating: 4.3, estimatedDuration: '30 min', estimatedCost: '\$8', address: 'City of London', durationMinutes: 30),
      ],
      3: [
        ExplorePlaceItem(id: 'ldn-adv-1', name: 'Up at The O2 Climb', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400', description: 'Climb over the roof of the O2 Arena with safety harness for stunning 360° views of London.', rating: 4.7, estimatedDuration: '2 hrs', estimatedCost: '\$45', address: 'Greenwich Peninsula', durationMinutes: 120),
        ExplorePlaceItem(id: 'ldn-adv-2', name: 'Thames Rocket Speedboat', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', description: 'High-speed boat ride down the Thames, twisting and banking to movie soundtracks.', rating: 4.8, estimatedDuration: '1 hr', estimatedCost: '\$50', address: 'London Eye Pier', durationMinutes: 60),
        ExplorePlaceItem(id: 'ldn-adv-3', name: 'The Shard Observation Deck', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400', description: 'Western Europe\'s tallest building, with open-air viewing platform on the 72nd floor.', rating: 4.7, estimatedDuration: '1.5 hrs', estimatedCost: '\$35', address: 'London Bridge', durationMinutes: 90),
        ExplorePlaceItem(id: 'ldn-adv-4', name: 'Zip World London', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', description: 'Zip along a 225m cable over the Royal Docks at 50mph—the fastest city zip wire in the world.', rating: 4.5, estimatedDuration: '1 hr', estimatedCost: '\$35', address: 'Royal Docks, London', durationMinutes: 60),
        ExplorePlaceItem(id: 'ldn-adv-5', name: 'London Kayaking Tour', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400', description: 'Paddle along the Regent\'s Canal from Little Venice to Camden Lock, seeing London from the water.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: '\$40', address: 'Little Venice, London', durationMinutes: 120),
        ExplorePlaceItem(id: 'ldn-adv-6', name: 'Emirates Air Line Cable Car', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', description: 'Soar across the Thames in a cable car with views of Canary Wharf, O2 Arena, and the docklands.', rating: 4.3, estimatedDuration: '30 min', estimatedCost: '\$8', address: 'Greenwich/Royal Docks', durationMinutes: 30),
        ExplorePlaceItem(id: 'ldn-adv-7', name: 'Jack the Ripper Walking Tour', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400', description: 'After-dark walking tour through the dark alleyways of Whitechapel, following the Ripper\'s trail.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: '\$15', address: 'Whitechapel, London', durationMinutes: 120),
        ExplorePlaceItem(id: 'ldn-adv-8', name: 'ArcelorMittal Orbit Slide', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', description: 'Ride the world\'s tallest and longest tunnel slide—178m—spiraling down the iconic Olympic sculpture.', rating: 4.5, estimatedDuration: '1 hr', estimatedCost: '\$20', address: 'Olympic Park, London', durationMinutes: 60),
      ],
      4: [
        ExplorePlaceItem(id: 'ldn-food-1', name: 'Borough Market Food Tour', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=400', description: 'Sample cheeses, meat pies, oysters, and fresh juices at London\'s oldest food market.', rating: 4.8, estimatedDuration: '2 hrs', estimatedCost: '\$20', address: 'Southwark, London', durationMinutes: 120),
        ExplorePlaceItem(id: 'ldn-food-2', name: 'Afternoon Tea at The Ritz', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', description: 'Elegant British tradition with sandwiches, scones with clotted cream, and loose-leaf teas.', rating: 4.9, estimatedDuration: '2 hrs', estimatedCost: '\$90', address: 'Piccadilly, London', durationMinutes: 120),
        ExplorePlaceItem(id: 'ldn-food-3', name: 'Brick Lane Curry Walk', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=400', description: 'Stroll through London\'s curry mile sampling tikka masala, biryani, and freshly baked naan.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: '\$18', address: 'Brick Lane, London', durationMinutes: 120),
        ExplorePlaceItem(id: 'ldn-food-4', name: 'Sunday Roast at The Blacklock', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', description: 'A proper British Sunday roast with Yorkshire pudding, roast potatoes, and unlimited gravy.', rating: 4.7, estimatedDuration: '2 hrs', estimatedCost: '\$25', address: 'Soho, London', durationMinutes: 120),
        ExplorePlaceItem(id: 'ldn-food-5', name: 'Camden Market Street Food', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=400', description: 'Eclectic street food from around the world—pad thai, arepas, dim sum, and vegan burgers.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: '\$15', address: 'Camden Town, London', durationMinutes: 120),
        ExplorePlaceItem(id: 'ldn-food-6', name: 'Fish & Chips at Poppies', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', description: 'Award-winning traditional fish & chips in a 1950s-themed diner with jukebox music.', rating: 4.6, estimatedDuration: '1 hr', estimatedCost: '\$18', address: 'Spitalfields, London', durationMinutes: 60),
        ExplorePlaceItem(id: 'ldn-food-7', name: 'Gin Distillery Tour', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=400', description: 'Tour a craft gin distillery, learn the history of London dry gin, and create your own botanical blend.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: '\$40', address: 'Bermondsey, London', durationMinutes: 120),
        ExplorePlaceItem(id: 'ldn-food-8', name: 'Maltby Street Market', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', description: 'A hidden gem under railway arches with artisan food stalls, craft beer, and gourmet sandwiches.', rating: 4.5, estimatedDuration: '1.5 hrs', estimatedCost: '\$15', address: 'Bermondsey, London', durationMinutes: 90),
      ],
      5: [
        ExplorePlaceItem(id: 'ldn-cult-1', name: 'British Museum', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', description: 'Explore human history—Rosetta Stone, Parthenon Sculptures, Egyptian mummies—all for free.', rating: 4.9, estimatedDuration: '3-4 hrs', estimatedCost: 'Free', address: 'Bloomsbury, London', durationMinutes: 210),
        ExplorePlaceItem(id: 'ldn-cult-2', name: 'Tower of London & Crown Jewels', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=400', description: 'Historic castle, royal palace, and prison. See the Crown Jewels and meet the legendary ravens.', rating: 4.8, estimatedDuration: '3 hrs', estimatedCost: '\$35', address: 'Tower Hill, London', durationMinutes: 180),
        ExplorePlaceItem(id: 'ldn-cult-3', name: 'Buckingham Palace & Changing of the Guard', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', description: 'Watch the iconic Changing of the Guard ceremony and tour the State Rooms in summer.', rating: 4.7, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Westminster, London', durationMinutes: 120),
        ExplorePlaceItem(id: 'ldn-cult-4', name: 'National Gallery', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=400', description: 'Over 2,300 paintings from the 13th to 19th centuries, including works by Van Gogh, Da Vinci, and Turner.', rating: 4.8, estimatedDuration: '2-3 hrs', estimatedCost: 'Free', address: 'Trafalgar Square, London', durationMinutes: 150),
        ExplorePlaceItem(id: 'ldn-cult-5', name: 'V&A Museum', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', description: 'World\'s leading museum of art, design, and performance, with fashion, ceramics, and furniture.', rating: 4.7, estimatedDuration: '2-3 hrs', estimatedCost: 'Free', address: 'South Kensington, London', durationMinutes: 150),
        ExplorePlaceItem(id: 'ldn-cult-6', name: 'Churchill War Rooms', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=400', description: 'The secret underground bunker where Churchill directed WWII, preserved exactly as it was.', rating: 4.8, estimatedDuration: '2 hrs', estimatedCost: '\$30', address: 'Westminster, London', durationMinutes: 120),
        ExplorePlaceItem(id: 'ldn-cult-7', name: 'Tate Modern', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', description: 'Former power station now housing Britain\'s top modern art collection—Picasso, Rothko, Warhol, and more.', rating: 4.6, estimatedDuration: '2-3 hrs', estimatedCost: 'Free', address: 'Bankside, London', durationMinutes: 150),
        ExplorePlaceItem(id: 'ldn-cult-8', name: 'Globe Theatre Tour', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=400', description: 'Faithful reconstruction of Shakespeare\'s playhouse with guided tours and live performances.', rating: 4.5, estimatedDuration: '1.5 hrs', estimatedCost: '\$20', address: 'Bankside, London', durationMinutes: 90),
      ],
      6: [
        ExplorePlaceItem(id: 'ldn-shop-1', name: 'Harrods', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', description: 'The world\'s most famous luxury department store with gorgeous food halls and designer fashion.', rating: 4.7, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Knightsbridge, London', durationMinutes: 120),
        ExplorePlaceItem(id: 'ldn-shop-2', name: 'Covent Garden Market', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400', description: 'Bustling market square with independent boutiques, street performers, and the Royal Opera House.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Covent Garden, London', durationMinutes: 120),
        ExplorePlaceItem(id: 'ldn-shop-3', name: 'Portobello Road Market', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', description: 'World-famous antiques market in Notting Hill with vintage finds, street food, and live music.', rating: 4.6, estimatedDuration: '2-3 hrs', estimatedCost: 'Free', address: 'Notting Hill, London', durationMinutes: 150),
        ExplorePlaceItem(id: 'ldn-shop-4', name: 'Oxford Street', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400', description: 'Europe\'s busiest shopping street with 300+ stores including Selfridges, John Lewis, and Primark.', rating: 4.4, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Oxford Street, London', durationMinutes: 120),
        ExplorePlaceItem(id: 'ldn-shop-5', name: 'Liberty London', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', description: 'Beautiful Tudor-style department store famous for its signature floral prints and curated fashion.', rating: 4.7, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'Regent Street, London', durationMinutes: 90),
        ExplorePlaceItem(id: 'ldn-shop-6', name: 'Carnaby Street', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400', description: 'Iconic 1960s fashion street now home to indie brands, concept stores, and trendy cafes.', rating: 4.4, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'Soho, London', durationMinutes: 90),
        ExplorePlaceItem(id: 'ldn-shop-7', name: 'Spitalfields Market', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', description: 'Covered market with independent designers, artisan food, and vintage clothing near Liverpool Street.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Spitalfields, London', durationMinutes: 120),
        ExplorePlaceItem(id: 'ldn-shop-8', name: 'King\'s Road Chelsea', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400', description: 'Birthplace of punk fashion, now a chic boulevard with designer shops and the Saatchi Gallery.', rating: 4.4, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Chelsea, London', durationMinutes: 120),
      ],
      7: [
        ExplorePlaceItem(id: 'ldn-night-1', name: 'West End Musical', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400', description: 'Catch The Lion King, Les Misérables, or Wicked in London\'s world-famous theatre district.', rating: 4.9, estimatedDuration: '3 hrs', estimatedCost: '\$60', address: 'Shaftesbury Ave, London', durationMinutes: 180),
        ExplorePlaceItem(id: 'ldn-night-2', name: 'Soho Pub & Cocktail Crawl', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Explore vibrant bars, historical pubs, and cozy jazz clubs in bohemian Soho.', rating: 4.6, estimatedDuration: '3 hrs', estimatedCost: '\$30', address: 'Soho, London', durationMinutes: 180),
        ExplorePlaceItem(id: 'ldn-night-3', name: 'Ronnie Scott\'s Jazz Club', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400', description: 'World-famous jazz venue since 1959, hosting top international and emerging artists nightly.', rating: 4.7, estimatedDuration: '2 hrs', estimatedCost: '\$35', address: 'Frith Street, Soho', durationMinutes: 120),
        ExplorePlaceItem(id: 'ldn-night-4', name: 'Roof Gardens Kensington', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Rooftop bar and club 6 floors up with flamingos, themed gardens, and skyline views.', rating: 4.4, estimatedDuration: '2 hrs', estimatedCost: '\$25', address: 'High Street Kensington', durationMinutes: 120),
        ExplorePlaceItem(id: 'ldn-night-5', name: 'Thames Night Cruise', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400', description: 'Evening cruise past illuminated Tower Bridge, Big Ben, and the London Eye with dinner on board.', rating: 4.6, estimatedDuration: '2.5 hrs', estimatedCost: '\$55', address: 'Westminster Pier', durationMinutes: 150),
        ExplorePlaceItem(id: 'ldn-night-6', name: 'KOKO Camden Live Music', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Legendary music venue in a Victorian theatre hosting live gigs, DJ nights, and club events.', rating: 4.5, estimatedDuration: '3 hrs', estimatedCost: '\$20', address: 'Camden, London', durationMinutes: 180),
        ExplorePlaceItem(id: 'ldn-night-7', name: 'Speakeasy Cocktail Bars', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400', description: 'Discover hidden bars behind unmarked doors—try Cahoots, Evans & Peel, or Nightjar.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: '\$30', address: 'Various, London', durationMinutes: 120),
        ExplorePlaceItem(id: 'ldn-night-8', name: 'Comedy Store Show', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'London\'s premier comedy venue in Leicester Square with top British and international comedians.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: '\$22', address: 'Leicester Square, London', durationMinutes: 120),
      ],
    };
  }

  Map<int, List<ExplorePlaceItem>> _buildNYCPlaces() {
    return {
      0: [
        ExplorePlaceItem(id: 'nyc-beach-1', name: 'Coney Island Beach', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400', description: 'Historic seaside with sandy beaches, boardwalks, hot dogs, and Luna Park rides.', rating: 4.5, estimatedDuration: '4-5 hrs', estimatedCost: 'Free', address: 'Brooklyn, NY', durationMinutes: 270),
        ExplorePlaceItem(id: 'nyc-beach-2', name: 'Rockaway Beach', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'NYC\'s premier surf spot with boardwalk, taco stands, and craft beer bars.', rating: 4.6, estimatedDuration: '3-4 hrs', estimatedCost: 'Free', address: 'Queens, NY', durationMinutes: 210),
        ExplorePlaceItem(id: 'nyc-beach-3', name: 'Central Park Boating Lake', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400', description: 'Rent rowboats on the lake surrounded by Manhattan skyscrapers and lush greenery.', rating: 4.5, estimatedDuration: '1.5 hrs', estimatedCost: '\$20', address: 'Central Park, NY', durationMinutes: 90),
        ExplorePlaceItem(id: 'nyc-beach-4', name: 'Brooklyn Bridge Park Pier 2', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=400', description: 'Waterfront park with kayaking, splash pads, pop-up pools, and stunning Manhattan views.', rating: 4.5, estimatedDuration: '2-3 hrs', estimatedCost: 'Free', address: 'Brooklyn, NY', durationMinutes: 150),
        ExplorePlaceItem(id: 'nyc-beach-5', name: 'Governor\'s Island Beach', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Ferry to a car-free island with hammock groves, Statue of Liberty views, and food trucks.', rating: 4.6, estimatedDuration: '3-4 hrs', estimatedCost: '\$4', address: 'Governor\'s Island, NY', durationMinutes: 210),
        ExplorePlaceItem(id: 'nyc-beach-6', name: 'The High Line Summer Walk', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400', description: 'Elevated park on old railway tracks with sundecks, water features, and city views.', rating: 4.7, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'West Side, Manhattan', durationMinutes: 90),
        ExplorePlaceItem(id: 'nyc-beach-7', name: 'Jones Beach State Park', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=400', description: 'Wide sandy beach on Long Island with a boardwalk, outdoor concerts, and family facilities.', rating: 4.4, estimatedDuration: '4-5 hrs', estimatedCost: '\$10', address: 'Wantagh, Long Island', durationMinutes: 270),
        ExplorePlaceItem(id: 'nyc-beach-8', name: 'South Street Seaport Pier 17', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400', description: 'Waterfront dining and entertainment complex with rooftop concerts and Brooklyn Bridge views.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'FiDi, Manhattan', durationMinutes: 120),
      ],
      1: [
        ExplorePlaceItem(id: 'nyc-kids-1', name: 'American Museum of Natural History', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1624601573012-efb68931cc8f?w=400', description: 'Dinosaur fossils, the giant blue whale model, and the Hayden Planetarium.', rating: 4.9, estimatedDuration: '3-4 hrs', estimatedCost: '\$28', address: 'Central Park West, NY', durationMinutes: 210),
        ExplorePlaceItem(id: 'nyc-kids-2', name: 'Central Park Zoo', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400', description: 'Charming zoo featuring snow leopards, sea lions, and penguins in the middle of Manhattan.', rating: 4.7, estimatedDuration: '2 hrs', estimatedCost: '\$20', address: 'Central Park East, NY', durationMinutes: 120),
        ExplorePlaceItem(id: 'nyc-kids-3', name: 'Intrepid Sea, Air & Space Museum', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1534567153574-2b12153a63f0?w=400', description: 'An aircraft carrier museum with jets, a submarine, the Space Shuttle Enterprise, and flight simulators.', rating: 4.7, estimatedDuration: '3 hrs', estimatedCost: '\$33', address: 'Pier 86, Hudson River', durationMinutes: 180),
        ExplorePlaceItem(id: 'nyc-kids-4', name: 'Brooklyn Children\'s Museum', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1624601573012-efb68931cc8f?w=400', description: 'The world\'s first children\'s museum with sensory play, art studios, and a rooftop nature area.', rating: 4.6, estimatedDuration: '2-3 hrs', estimatedCost: '\$13', address: 'Crown Heights, Brooklyn', durationMinutes: 150),
        ExplorePlaceItem(id: 'nyc-kids-5', name: 'NY Aquarium', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400', description: 'Sharks, sea otters, walruses, and a 4D theater at Coney Island\'s oceanside aquarium.', rating: 4.5, estimatedDuration: '2-3 hrs', estimatedCost: '\$30', address: 'Coney Island, Brooklyn', durationMinutes: 150),
        ExplorePlaceItem(id: 'nyc-kids-6', name: 'LEGOLAND Discovery Center', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1624601573012-efb68931cc8f?w=400', description: 'Indoor LEGO playground with rides, building stations, and a miniland version of NYC.', rating: 4.4, estimatedDuration: '2 hrs', estimatedCost: '\$30', address: 'Westchester, NY', durationMinutes: 120),
        ExplorePlaceItem(id: 'nyc-kids-7', name: 'Statue of Liberty & Ellis Island', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400', description: 'Ferry to Lady Liberty and the immigration museum—an inspiring journey into American history.', rating: 4.8, estimatedDuration: '3-4 hrs', estimatedCost: '\$25', address: 'Battery Park, NY', durationMinutes: 210),
        ExplorePlaceItem(id: 'nyc-kids-8', name: 'Central Park Carousel & Playground', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1534567153574-2b12153a63f0?w=400', description: 'Vintage carousel, Heckscher Playground, and boat pond in the heart of Central Park.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: '\$5', address: 'Central Park, NY', durationMinutes: 120),
      ],
      2: [
        ExplorePlaceItem(id: 'nyc-rel-1', name: 'St. Patrick\'s Cathedral', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400', description: 'Famous Neo-Gothic Roman Catholic cathedral on Fifth Avenue across from Rockefeller Center.', rating: 4.9, estimatedDuration: '1 hr', estimatedCost: 'Free', address: 'Fifth Avenue, NY', durationMinutes: 60),
        ExplorePlaceItem(id: 'nyc-rel-2', name: 'Cathedral of St. John the Divine', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=400', description: 'One of the world\'s largest cathedrals with stained glass, gothic carvings, and beautiful gardens.', rating: 4.8, estimatedDuration: '1-2 hrs', estimatedCost: 'Free', address: 'Amsterdam Ave, NY', durationMinutes: 90),
        ExplorePlaceItem(id: 'nyc-rel-3', name: 'Trinity Church Wall Street', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=400', description: 'Historic church at the head of Wall Street where Alexander Hamilton is buried.', rating: 4.5, estimatedDuration: '45 min', estimatedCost: 'Free', address: 'Wall Street, NY', durationMinutes: 45),
        ExplorePlaceItem(id: 'nyc-rel-4', name: 'Islamic Cultural Center of New York', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400', description: 'The first mosque built in NYC, a beautiful modern structure on the Upper East Side.', rating: 4.3, estimatedDuration: '30 min', estimatedCost: 'Free', address: 'Third Avenue, NY', durationMinutes: 30),
        ExplorePlaceItem(id: 'nyc-rel-5', name: 'Riverside Church', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=400', description: 'Interdenominational church with the world\'s largest carillon of 74 bells and stunning bell tower views.', rating: 4.6, estimatedDuration: '1 hr', estimatedCost: 'Free', address: 'Morningside Heights, NY', durationMinutes: 60),
        ExplorePlaceItem(id: 'nyc-rel-6', name: 'Eldridge Street Synagogue', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=400', description: 'Restored 1887 synagogue with a stunning rose window and museum about Jewish immigrant life.', rating: 4.6, estimatedDuration: '1 hr', estimatedCost: '\$14', address: 'Lower East Side, NY', durationMinutes: 60),
        ExplorePlaceItem(id: 'nyc-rel-7', name: 'St. Thomas Church Fifth Avenue', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400', description: 'Gorgeous French Gothic church renowned for its choir and stunning reredos (altar screen).', rating: 4.5, estimatedDuration: '45 min', estimatedCost: 'Free', address: 'Fifth Avenue, NY', durationMinutes: 45),
        ExplorePlaceItem(id: 'nyc-rel-8', name: '9/11 Memorial & Museum', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=400', description: 'A place of remembrance with reflecting pools on the footprints of the Twin Towers.', rating: 4.9, estimatedDuration: '2-3 hrs', estimatedCost: '\$26', address: 'World Trade Center, NY', durationMinutes: 150),
      ],
      3: [
        ExplorePlaceItem(id: 'nyc-adv-1', name: 'The Edge Observation Deck', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400', description: 'Highest outdoor sky deck in the Western Hemisphere with glass floors suspended mid-air.', rating: 4.8, estimatedDuration: '2 hrs', estimatedCost: '\$40', address: 'Hudson Yards, NY', durationMinutes: 120),
        ExplorePlaceItem(id: 'nyc-adv-2', name: 'Helicopter Flight Over NYC', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', description: 'Bird\'s eye views of the Statue of Liberty, Central Park, and Manhattan skyline.', rating: 4.9, estimatedDuration: '30 min', estimatedCost: '\$200', address: 'Downtown Heliport, NY', durationMinutes: 30),
        ExplorePlaceItem(id: 'nyc-adv-3', name: 'Top of the Rock', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400', description: 'Observation deck at 30 Rock with unobstructed views of both the Empire State Building and Central Park.', rating: 4.8, estimatedDuration: '1.5 hrs', estimatedCost: '\$40', address: 'Rockefeller Center, NY', durationMinutes: 90),
        ExplorePlaceItem(id: 'nyc-adv-4', name: 'Empire State Building', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', description: 'The iconic Art Deco skyscraper with two observation decks offering dramatic city views.', rating: 4.7, estimatedDuration: '1.5 hrs', estimatedCost: '\$44', address: 'Fifth Ave, NY', durationMinutes: 90),
        ExplorePlaceItem(id: 'nyc-adv-5', name: 'Brooklyn Bridge Walk', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400', description: 'Walk across the iconic suspension bridge with breathtaking views of the Manhattan skyline.', rating: 4.7, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'Brooklyn Bridge, NY', durationMinutes: 90),
        ExplorePlaceItem(id: 'nyc-adv-6', name: 'SUMMIT One Vanderbilt', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', description: 'Immersive multi-sensory experience on the 91st floor with mirrored rooms and glass skyboxes.', rating: 4.8, estimatedDuration: '1.5 hrs', estimatedCost: '\$39', address: 'Vanderbilt Ave, NY', durationMinutes: 90),
        ExplorePlaceItem(id: 'nyc-adv-7', name: 'Bike the Hudson River Greenway', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400', description: 'Cycle the 11-mile waterfront path from Battery Park to the George Washington Bridge.', rating: 4.5, estimatedDuration: '2-3 hrs', estimatedCost: '\$15', address: 'Hudson River, NY', durationMinutes: 150),
        ExplorePlaceItem(id: 'nyc-adv-8', name: 'Escape the Room NYC', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', description: 'Solve puzzles and crack codes in themed escape rooms—choose from spy, horror, or mystery themes.', rating: 4.5, estimatedDuration: '1 hr', estimatedCost: '\$35', address: 'Midtown, NY', durationMinutes: 60),
      ],
      4: [
        ExplorePlaceItem(id: 'nyc-food-1', name: 'Chelsea Market Food Tour', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=400', description: 'Indoor food hall with tacos, lobster rolls, and artisanal gelato in a historic biscuit factory.', rating: 4.8, estimatedDuration: '2 hrs', estimatedCost: '\$25', address: '9th Ave, NY', durationMinutes: 120),
        ExplorePlaceItem(id: 'nyc-food-2', name: 'Katz\'s Delicatessen', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', description: 'Legendary deli serving piled-high pastrami sandwiches since 1888.', rating: 4.8, estimatedDuration: '1.5 hrs', estimatedCost: '\$30', address: 'East Houston St, NY', durationMinutes: 90),
        ExplorePlaceItem(id: 'nyc-food-3', name: 'Smorgasburg Brooklyn', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=400', description: 'Huge outdoor food market with 100+ vendors selling everything from ramen burgers to Thai rolled ice cream.', rating: 4.7, estimatedDuration: '2 hrs', estimatedCost: '\$20', address: 'Williamsburg, Brooklyn', durationMinutes: 120),
        ExplorePlaceItem(id: 'nyc-food-4', name: 'Chinatown Dim Sum', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', description: 'Feast on soup dumplings, shrimp har gow, and BBQ pork buns at Nom Wah Tea Parlor since 1920.', rating: 4.6, estimatedDuration: '1.5 hrs', estimatedCost: '\$20', address: 'Chinatown, Manhattan', durationMinutes: 90),
        ExplorePlaceItem(id: 'nyc-food-5', name: 'Joe\'s Pizza Slice', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=400', description: 'The quintessential NYC pizza experience—thin crust, foldable slices, and no-nonsense service.', rating: 4.7, estimatedDuration: '30 min', estimatedCost: '\$5', address: 'Greenwich Village, NY', durationMinutes: 30),
        ExplorePlaceItem(id: 'nyc-food-6', name: 'Little Italy Walking Tour', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', description: 'Explore Mulberry Street sampling cannoli, fresh pasta, espresso, and Italian gelato.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: '\$25', address: 'Little Italy, NY', durationMinutes: 120),
        ExplorePlaceItem(id: 'nyc-food-7', name: 'Eataly NYC Flatiron', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=400', description: 'Mario Batali\'s Italian marketplace with restaurants, counters, and a rooftop beer garden.', rating: 4.6, estimatedDuration: '1.5 hrs', estimatedCost: '\$30', address: 'Flatiron, NY', durationMinutes: 90),
        ExplorePlaceItem(id: 'nyc-food-8', name: 'Harlem Soul Food Tour', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', description: 'Sample fried chicken, waffles, mac & cheese, and cornbread at iconic soul food restaurants.', rating: 4.7, estimatedDuration: '2 hrs', estimatedCost: '\$30', address: 'Harlem, NY', durationMinutes: 120),
      ],
      5: [
        ExplorePlaceItem(id: 'nyc-cult-1', name: 'Metropolitan Museum of Art', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', description: 'One of the world\'s grandest art museums covering 5,000 years of culture.', rating: 4.9, estimatedDuration: '3-4 hrs', estimatedCost: '\$30', address: 'Fifth Avenue, NY', durationMinutes: 210),
        ExplorePlaceItem(id: 'nyc-cult-2', name: 'Statue of Liberty & Ellis Island', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=400', description: 'Visit Lady Liberty and trace America\'s immigration history at Ellis Island.', rating: 4.8, estimatedDuration: '3-4 hrs', estimatedCost: '\$25', address: 'Battery Park Ferry, NY', durationMinutes: 210),
        ExplorePlaceItem(id: 'nyc-cult-3', name: 'MoMA (Museum of Modern Art)', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', description: 'Van Gogh\'s Starry Night, Warhol\'s Campbell\'s Soup, Picasso\'s Les Demoiselles—all under one roof.', rating: 4.8, estimatedDuration: '2-3 hrs', estimatedCost: '\$25', address: 'Midtown, NY', durationMinutes: 150),
        ExplorePlaceItem(id: 'nyc-cult-4', name: 'Grand Central Terminal Tour', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=400', description: 'Tour the stunning Beaux-Arts train station with its constellation ceiling and whispering gallery.', rating: 4.6, estimatedDuration: '1 hr', estimatedCost: 'Free', address: 'Midtown, NY', durationMinutes: 60),
        ExplorePlaceItem(id: 'nyc-cult-5', name: 'Guggenheim Museum', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', description: 'Frank Lloyd Wright\'s iconic spiral building with rotating exhibitions of modern and contemporary art.', rating: 4.7, estimatedDuration: '2 hrs', estimatedCost: '\$25', address: 'Upper East Side, NY', durationMinutes: 120),
        ExplorePlaceItem(id: 'nyc-cult-6', name: 'Brooklyn Museum', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=400', description: 'Major art museum with Egyptian antiquities, American art, and thought-provoking contemporary shows.', rating: 4.5, estimatedDuration: '2-3 hrs', estimatedCost: '\$16', address: 'Prospect Heights, Brooklyn', durationMinutes: 150),
        ExplorePlaceItem(id: 'nyc-cult-7', name: 'Whitney Museum', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', description: 'American art from the 20th-21st century with stunning outdoor terraces overlooking the High Line.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: '\$25', address: 'Meatpacking District, NY', durationMinutes: 120),
        ExplorePlaceItem(id: 'nyc-cult-8', name: 'Tenement Museum', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=400', description: 'Walk through restored immigrant apartments from the 1860s–1980s in the Lower East Side.', rating: 4.7, estimatedDuration: '1.5 hrs', estimatedCost: '\$30', address: 'Orchard Street, NY', durationMinutes: 90),
      ],
      6: [
        ExplorePlaceItem(id: 'nyc-shop-1', name: 'Fifth Avenue Shopping', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', description: 'Manhattan\'s premier shopping boulevard—Tiffany & Co, Saks, and flagship stores.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Fifth Ave, NY', durationMinutes: 120),
        ExplorePlaceItem(id: 'nyc-shop-2', name: 'SoHo Shopping District', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400', description: 'Cobblestone streets with designer boutiques, high-end streetwear, and art galleries.', rating: 4.7, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'SoHo, NY', durationMinutes: 120),
        ExplorePlaceItem(id: 'nyc-shop-3', name: 'Brooklyn Flea', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', description: 'Weekend flea market with vintage furniture, antiques, handmade jewelry, and artisanal food.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Williamsburg, Brooklyn', durationMinutes: 120),
        ExplorePlaceItem(id: 'nyc-shop-4', name: 'Century 21 Department Store', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400', description: 'NYC\'s famous off-price designer department store for bargain luxury fashion.', rating: 4.4, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'FiDi, NY', durationMinutes: 90),
        ExplorePlaceItem(id: 'nyc-shop-5', name: 'Times Square Flagship Stores', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', description: 'M&M\'s World, Disney Store, and massive flagship stores amid the neon glow.', rating: 4.3, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'Times Square, NY', durationMinutes: 90),
        ExplorePlaceItem(id: 'nyc-shop-6', name: 'Chinatown Street Shopping', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400', description: 'Bargain shopping for accessories, souvenirs, and authentic Asian goods along Canal Street.', rating: 4.3, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'Chinatown, NY', durationMinutes: 90),
        ExplorePlaceItem(id: 'nyc-shop-7', name: 'Chelsea Market Shops', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', description: 'Artisan shops, indie bookstores, and unique gift stores inside the historic food hall.', rating: 4.5, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'Chelsea, NY', durationMinutes: 90),
        ExplorePlaceItem(id: 'nyc-shop-8', name: 'Strand Bookstore', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400', description: 'Legendary bookstore with 18 miles of new, used, and rare books since 1927.', rating: 4.7, estimatedDuration: '1 hr', estimatedCost: 'Free', address: 'Union Square, NY', durationMinutes: 60),
      ],
      7: [
        ExplorePlaceItem(id: 'nyc-night-1', name: 'Broadway Show & Times Square', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400', description: 'World-famous Broadway musical under neon lights, then walk through the glowing canyon.', rating: 4.9, estimatedDuration: '3 hrs', estimatedCost: '\$90', address: 'Theater District, NY', durationMinutes: 180),
        ExplorePlaceItem(id: 'nyc-night-2', name: 'Rooftop at 230 Fifth', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Massive heated rooftop bar with direct Empire State Building views.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: '\$25', address: 'Fifth Ave, NY', durationMinutes: 120),
        ExplorePlaceItem(id: 'nyc-night-3', name: 'Greenwich Village Jazz Club', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400', description: 'Live jazz at legendary clubs like Blue Note or Village Vanguard in the Village.', rating: 4.7, estimatedDuration: '2 hrs', estimatedCost: '\$30', address: 'Greenwich Village, NY', durationMinutes: 120),
        ExplorePlaceItem(id: 'nyc-night-4', name: 'Comedy Cellar Show', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'NYC\'s most famous comedy club where top comedians do surprise drop-in sets.', rating: 4.8, estimatedDuration: '2 hrs', estimatedCost: '\$25', address: 'MacDougal St, NY', durationMinutes: 120),
        ExplorePlaceItem(id: 'nyc-night-5', name: 'Speakeasy Tour', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400', description: 'Find hidden bars behind phone booths and barber shops—try PDT, Please Don\'t Tell.', rating: 4.6, estimatedDuration: '3 hrs', estimatedCost: '\$35', address: 'East Village, NY', durationMinutes: 180),
        ExplorePlaceItem(id: 'nyc-night-6', name: 'Brooklyn Warehouse Party', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Industrial-chic dance parties and DJ events in Williamsburg and Bushwick warehouses.', rating: 4.4, estimatedDuration: '3 hrs', estimatedCost: '\$20', address: 'Williamsburg, Brooklyn', durationMinutes: 180),
        ExplorePlaceItem(id: 'nyc-night-7', name: 'Top of the Standard Rooftop', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400', description: 'Exclusive rooftop lounge atop The Standard hotel with Hudson River views and cocktails.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: '\$30', address: 'Meatpacking District, NY', durationMinutes: 120),
        ExplorePlaceItem(id: 'nyc-night-8', name: 'Harlem Gospel & Jazz Night', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Experience Harlem\'s soulful music scene with gospel brunches and late-night jazz sessions.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: '\$25', address: 'Harlem, NY', durationMinutes: 120),
      ],
    };
  }

  Map<int, List<ExplorePlaceItem>> _buildSingaporePlaces() {
    // Return same structure as before but with 8 places per genre — kept compact with durationMinutes
    return {
      0: [
        ExplorePlaceItem(id: 'sg-beach-1', name: 'Siloso Beach Sentosa', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400', description: 'Vibrant beach lined with bars, volleyball nets, water sports, and beautiful sand.', rating: 4.6, estimatedDuration: '3-4 hrs', estimatedCost: 'Free', address: 'Sentosa Island', durationMinutes: 210),
        ExplorePlaceItem(id: 'sg-beach-2', name: 'East Coast Park Beach', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: '15km coastline popular for cycling, BBQs, and sea-breeze walks.', rating: 4.5, estimatedDuration: '2-3 hrs', estimatedCost: 'Free', address: 'East Coast Park', durationMinutes: 150),
        ExplorePlaceItem(id: 'sg-beach-3', name: 'Palawan Beach', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400', description: 'Southernmost point of continental Asia with a rope bridge to a tiny island.', rating: 4.5, estimatedDuration: '2-3 hrs', estimatedCost: 'Free', address: 'Sentosa Island', durationMinutes: 150),
        ExplorePlaceItem(id: 'sg-beach-4', name: 'Lazarus Island', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=400', description: 'A secluded island with pristine white sand, crystal clear waters, and almost no crowds.', rating: 4.7, estimatedDuration: '4-5 hrs', estimatedCost: '\$15', address: 'Southern Islands', durationMinutes: 270),
        ExplorePlaceItem(id: 'sg-beach-5', name: 'Wild Wild Wet Water Park', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400', description: 'Asia\'s largest water park with slides, wave pools, and a lazy river.', rating: 4.4, estimatedDuration: '4-5 hrs', estimatedCost: '\$30', address: 'Pasir Ris', durationMinutes: 270),
        ExplorePlaceItem(id: 'sg-beach-6', name: 'Marina Barrage', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Green rooftop with skyline views, kite flying, and a sustainable energy gallery.', rating: 4.5, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'Marina South', durationMinutes: 90),
        ExplorePlaceItem(id: 'sg-beach-7', name: 'Adventure Cove Waterpark', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=400', description: 'Waterpark with ray bay, rainbow reef snorkeling, and high-speed water slides.', rating: 4.6, estimatedDuration: '4-5 hrs', estimatedCost: '\$35', address: 'Resorts World Sentosa', durationMinutes: 270),
        ExplorePlaceItem(id: 'sg-beach-8', name: 'Changi Beach Park', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400', description: 'Serene coastline with BBQ pits, calm waters, and views of planes landing at Changi Airport.', rating: 4.3, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Changi', durationMinutes: 120),
      ],
      1: [
        ExplorePlaceItem(id: 'sg-kids-1', name: 'Universal Studios Singapore', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1624601573012-efb68931cc8f?w=400', description: 'Theme park with 7 themed zones, rollercoasters, and shows based on hit films.', rating: 4.8, estimatedDuration: '6-8 hrs', estimatedCost: '\$60', address: 'Resorts World Sentosa', durationMinutes: 420),
        ExplorePlaceItem(id: 'sg-kids-2', name: 'Singapore Zoo & Night Safari', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400', description: 'Open-concept zoo and night safari tram ride to see nocturnal species.', rating: 4.9, estimatedDuration: '4-5 hrs', estimatedCost: '\$35', address: 'Mandai Lake Rd', durationMinutes: 270),
        ExplorePlaceItem(id: 'sg-kids-3', name: 'Gardens by the Bay', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1624601573012-efb68931cc8f?w=400', description: 'Futuristic gardens with Supertree Grove, Cloud Forest dome, and a children\'s garden.', rating: 4.9, estimatedDuration: '3-4 hrs', estimatedCost: '\$20', address: 'Marina Bay', durationMinutes: 210),
        ExplorePlaceItem(id: 'sg-kids-4', name: 'S.E.A. Aquarium', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400', description: 'World\'s largest aquarium with 800+ species and a massive viewing panel of the Open Ocean habitat.', rating: 4.7, estimatedDuration: '2-3 hrs', estimatedCost: '\$30', address: 'Resorts World Sentosa', durationMinutes: 150),
        ExplorePlaceItem(id: 'sg-kids-5', name: 'KidZania Singapore', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1624601573012-efb68931cc8f?w=400', description: 'Interactive indoor city where kids role-play 100+ careers and earn KidZos currency.', rating: 4.5, estimatedDuration: '4 hrs', estimatedCost: '\$30', address: 'Sentosa Island', durationMinutes: 240),
        ExplorePlaceItem(id: 'sg-kids-6', name: 'Science Centre Singapore', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1534567153574-2b12153a63f0?w=400', description: 'Interactive science exhibits, a KidsSTOP area, and an outdoor kinetic garden.', rating: 4.5, estimatedDuration: '3 hrs', estimatedCost: '\$12', address: 'Jurong East', durationMinutes: 180),
        ExplorePlaceItem(id: 'sg-kids-7', name: 'River Wonders', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400', description: 'Asia\'s first river-themed wildlife park with giant pandas, manatees, and a river boat ride.', rating: 4.6, estimatedDuration: '3 hrs', estimatedCost: '\$28', address: 'Mandai', durationMinutes: 180),
        ExplorePlaceItem(id: 'sg-kids-8', name: 'LEGOLAND Malaysia Day Trip', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1624601573012-efb68931cc8f?w=400', description: 'Cross the border to Johor Bahru for a full day of LEGO rides, building, and water park.', rating: 4.5, estimatedDuration: '8 hrs', estimatedCost: '\$50', address: 'Johor Bahru, Malaysia', durationMinutes: 480),
      ],
      2: [
        ExplorePlaceItem(id: 'sg-rel-1', name: 'Buddha Tooth Relic Temple', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400', description: 'Grand Tang-style Buddhist temple housing a relic tooth of the Buddha in a gold stupa.', rating: 4.8, estimatedDuration: '1 hr', estimatedCost: 'Free', address: 'Chinatown', durationMinutes: 60),
        ExplorePlaceItem(id: 'sg-rel-2', name: 'Sri Mariamman Temple', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=400', description: 'Oldest Hindu temple with a grand, colorful gopuram (tower) covered in deity sculptures.', rating: 4.7, estimatedDuration: '1 hr', estimatedCost: 'Free', address: 'South Bridge Rd', durationMinutes: 60),
        ExplorePlaceItem(id: 'sg-rel-3', name: 'Sultan Mosque', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=400', description: 'Singapore\'s most important mosque with a golden dome, in the heart of Kampong Glam.', rating: 4.7, estimatedDuration: '1 hr', estimatedCost: 'Free', address: 'Kampong Glam', durationMinutes: 60),
        ExplorePlaceItem(id: 'sg-rel-4', name: 'St. Andrew\'s Cathedral', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400', description: 'A stunning white neo-gothic Anglican cathedral in the civic district.', rating: 4.5, estimatedDuration: '45 min', estimatedCost: 'Free', address: 'City Hall', durationMinutes: 45),
        ExplorePlaceItem(id: 'sg-rel-5', name: 'Thian Hock Keng Temple', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=400', description: 'Singapore\'s oldest Hokkien temple, built without nails, with intricate carvings and paintings.', rating: 4.6, estimatedDuration: '45 min', estimatedCost: 'Free', address: 'Telok Ayer St', durationMinutes: 45),
        ExplorePlaceItem(id: 'sg-rel-6', name: 'Kong Meng San Phor Kark See Monastery', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=400', description: 'The largest Buddhist temple complex in Singapore, spread over a serene hilltop compound.', rating: 4.5, estimatedDuration: '1 hr', estimatedCost: 'Free', address: 'Bright Hill', durationMinutes: 60),
        ExplorePlaceItem(id: 'sg-rel-7', name: 'Armenian Church', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400', description: 'Singapore\'s oldest church (1835), a serene whitewashed colonial gem in the civic district.', rating: 4.3, estimatedDuration: '30 min', estimatedCost: 'Free', address: 'Hill Street', durationMinutes: 30),
        ExplorePlaceItem(id: 'sg-rel-8', name: 'Sakya Muni Buddha Gaya Temple', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=400', description: 'Temple of 1000 Lights—a 15m seated Buddha surrounded by hundreds of glowing bulbs.', rating: 4.4, estimatedDuration: '30 min', estimatedCost: 'Free', address: 'Race Course Rd', durationMinutes: 30),
      ],
      3: [
        ExplorePlaceItem(id: 'sg-adv-1', name: 'Marina Bay Sands SkyPark', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400', description: 'Observation deck 57 levels up with panoramic harbor and skyline views.', rating: 4.8, estimatedDuration: '1.5 hrs', estimatedCost: '\$20', address: 'Bayfront Ave', durationMinutes: 90),
        ExplorePlaceItem(id: 'sg-adv-2', name: 'Mega Adventure Zipline', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', description: 'Fly at 60kph over jungle and beach on a 450m zip-line.', rating: 4.7, estimatedDuration: '1.5 hrs', estimatedCost: '\$38', address: 'Imbiah Hill, Sentosa', durationMinutes: 90),
        ExplorePlaceItem(id: 'sg-adv-3', name: 'AJ Hackett Bungy Jump', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400', description: 'Bungy jump, giant swing, and skybridge at Sentosa for adrenaline junkies.', rating: 4.5, estimatedDuration: '1 hr', estimatedCost: '\$80', address: 'Siloso Beach, Sentosa', durationMinutes: 60),
        ExplorePlaceItem(id: 'sg-adv-4', name: 'Treetop Walk MacRitchie', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', description: '250m suspension bridge 25m above the rainforest canopy in MacRitchie Reservoir.', rating: 4.6, estimatedDuration: '3 hrs', estimatedCost: 'Free', address: 'MacRitchie Reservoir', durationMinutes: 180),
        ExplorePlaceItem(id: 'sg-adv-5', name: 'Indoor Skydiving iFly', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400', description: 'Experience free-fall in the world\'s largest themed wind tunnel on Sentosa.', rating: 4.5, estimatedDuration: '1 hr', estimatedCost: '\$50', address: 'Sentosa Island', durationMinutes: 60),
        ExplorePlaceItem(id: 'sg-adv-6', name: 'Skyline Luge Sentosa', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', description: 'Ride a gravity-powered go-kart down 4 different trails with city and sea views.', rating: 4.6, estimatedDuration: '1.5 hrs', estimatedCost: '\$20', address: 'Sentosa Island', durationMinutes: 90),
        ExplorePlaceItem(id: 'sg-adv-7', name: 'Pulau Ubin Cycling', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400', description: 'Bumboat to a rustic island and explore mangroves, quarries, and kampong life by bicycle.', rating: 4.6, estimatedDuration: '4 hrs', estimatedCost: '\$10', address: 'Changi Point', durationMinutes: 240),
        ExplorePlaceItem(id: 'sg-adv-8', name: 'Night Cycling Tour', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', description: 'Guided night bike tour past Marina Bay, Chinatown, and Clarke Quay under the stars.', rating: 4.5, estimatedDuration: '3 hrs', estimatedCost: '\$45', address: 'Marina Bay', durationMinutes: 180),
      ],
      4: [
        ExplorePlaceItem(id: 'sg-food-1', name: 'Lau Pa Sat Hawker Feast', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=400', description: 'Charcoal-grilled satay skewers in a Victorian-era cast iron food market.', rating: 4.8, estimatedDuration: '2 hrs', estimatedCost: '\$12', address: 'Raffles Quay', durationMinutes: 120),
        ExplorePlaceItem(id: 'sg-food-2', name: 'Newton Food Centre', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', description: 'Chilli crab, black pepper crab, and oyster omelets at a lively outdoor market.', rating: 4.7, estimatedDuration: '2 hrs', estimatedCost: '\$25', address: 'Clemenceau Ave', durationMinutes: 120),
        ExplorePlaceItem(id: 'sg-food-3', name: 'Hawker Chan (Michelin Star)', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=400', description: 'The world\'s cheapest Michelin-starred meal—soy sauce chicken rice for just \$3.', rating: 4.7, estimatedDuration: '1 hr', estimatedCost: '\$5', address: 'Chinatown Complex', durationMinutes: 60),
        ExplorePlaceItem(id: 'sg-food-4', name: 'Katong Laksa Walk', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', description: 'Sample the richest, spiciest laksa along the colorful Peranakan shophouses of Katong.', rating: 4.6, estimatedDuration: '1.5 hrs', estimatedCost: '\$8', address: 'East Coast Rd', durationMinutes: 90),
        ExplorePlaceItem(id: 'sg-food-5', name: 'Maxwell Food Centre', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=400', description: 'Historic hawker center famous for Tian Tian chicken rice and traditional kaya toast.', rating: 4.6, estimatedDuration: '1.5 hrs', estimatedCost: '\$8', address: 'Chinatown', durationMinutes: 90),
        ExplorePlaceItem(id: 'sg-food-6', name: 'Cooking Class at Food Playground', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', description: 'Learn to make laksa, roti prata, and kueh from a local Singaporean chef.', rating: 4.8, estimatedDuration: '3 hrs', estimatedCost: '\$65', address: 'Chinatown', durationMinutes: 180),
        ExplorePlaceItem(id: 'sg-food-7', name: 'Tiong Bahru Café Crawl', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=400', description: 'Hop between hip cafes, bakeries, and the traditional wet market in Singapore\'s hippest estate.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: '\$15', address: 'Tiong Bahru', durationMinutes: 120),
        ExplorePlaceItem(id: 'sg-food-8', name: 'Atlas Bar & 1-Altitude Drinks', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', description: 'Gatsby-era gin palace followed by cocktails at the world\'s highest alfresco bar.', rating: 4.7, estimatedDuration: '2 hrs', estimatedCost: '\$35', address: 'Bugis / Raffles Place', durationMinutes: 120),
      ],
      5: [
        ExplorePlaceItem(id: 'sg-cult-1', name: 'National Museum of Singapore', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', description: 'The nation\'s oldest museum with high-tech interactive galleries on Singapore\'s history.', rating: 4.8, estimatedDuration: '2-3 hrs', estimatedCost: '\$15', address: 'Stamford Rd', durationMinutes: 150),
        ExplorePlaceItem(id: 'sg-cult-2', name: 'Chinatown Heritage Centre', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=400', description: 'Recreated shophouse rooms showing the lives of early Chinese immigrants.', rating: 4.6, estimatedDuration: '1.5 hrs', estimatedCost: '\$12', address: 'Pagoda Street', durationMinutes: 90),
        ExplorePlaceItem(id: 'sg-cult-3', name: 'National Gallery Singapore', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', description: 'World\'s largest collection of Southeast Asian art housed in two beautifully restored colonial buildings.', rating: 4.7, estimatedDuration: '2-3 hrs', estimatedCost: '\$20', address: 'Padang', durationMinutes: 150),
        ExplorePlaceItem(id: 'sg-cult-4', name: 'Kampong Glam Walk', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=400', description: 'Explore Arab Street\'s textile shops, Haji Lane murals, and the Sultan Mosque precinct.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Kampong Glam', durationMinutes: 120),
        ExplorePlaceItem(id: 'sg-cult-5', name: 'Little India Heritage Trail', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', description: 'Colorful streets with spice shops, flower garlands, Tekka Market, and vibrant temples.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Little India', durationMinutes: 120),
        ExplorePlaceItem(id: 'sg-cult-6', name: 'Peranakan Museum', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=400', description: 'Discover the unique Straits Chinese culture through intricate costumes, jewelry, and artifacts.', rating: 4.5, estimatedDuration: '1.5 hrs', estimatedCost: '\$10', address: 'Armenian St', durationMinutes: 90),
        ExplorePlaceItem(id: 'sg-cult-7', name: 'Fort Canning Park', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', description: 'Historic hilltop park where Raffles first raised the British flag, now a lush green oasis.', rating: 4.4, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'River Valley', durationMinutes: 90),
        ExplorePlaceItem(id: 'sg-cult-8', name: 'ArtScience Museum', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=400', description: 'Lotus-shaped museum at Marina Bay Sands with immersive digital art exhibitions.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: '\$18', address: 'Marina Bay Sands', durationMinutes: 120),
      ],
      6: [
        ExplorePlaceItem(id: 'sg-shop-1', name: 'Orchard Road Shopping Belt', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', description: 'World-class shopping boulevard with futuristic malls and designer boutiques.', rating: 4.7, estimatedDuration: '3-4 hrs', estimatedCost: 'Free', address: 'Orchard Road', durationMinutes: 210),
        ExplorePlaceItem(id: 'sg-shop-2', name: 'Jewel Changi Airport', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400', description: 'Retail wonderland around the world\'s tallest indoor waterfall, the HSBC Rain Vortex.', rating: 4.9, estimatedDuration: '2-3 hrs', estimatedCost: 'Free', address: 'Changi Airport', durationMinutes: 150),
        ExplorePlaceItem(id: 'sg-shop-3', name: 'Bugis Street Market', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', description: 'Singapore\'s largest street shopping area with 800 stalls of bargain clothing and souvenirs.', rating: 4.3, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'Bugis', durationMinutes: 90),
        ExplorePlaceItem(id: 'sg-shop-4', name: 'VivoCity', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400', description: 'Singapore\'s largest mall with rooftop playground, cinema, and gateway to Sentosa.', rating: 4.4, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'HarbourFront', durationMinutes: 120),
        ExplorePlaceItem(id: 'sg-shop-5', name: 'ION Orchard', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', description: 'Futuristic luxury mall with high-end fashion and an observation deck on the 56th floor.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Orchard Road', durationMinutes: 120),
        ExplorePlaceItem(id: 'sg-shop-6', name: 'Haji Lane Boutiques', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400', description: 'Narrow street of indie fashion boutiques, vintage shops, and colorful street art.', rating: 4.5, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'Kampong Glam', durationMinutes: 90),
        ExplorePlaceItem(id: 'sg-shop-7', name: 'Mustafa Centre', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', description: '24-hour department store in Little India with everything from electronics to gold jewelry.', rating: 4.3, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'Little India', durationMinutes: 90),
        ExplorePlaceItem(id: 'sg-shop-8', name: 'Marina Bay Sands Shoppes', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400', description: 'Luxury shopping mall with a canal inside, gondola rides, and premium designer stores.', rating: 4.7, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Marina Bay', durationMinutes: 120),
      ],
      7: [
        ExplorePlaceItem(id: 'sg-night-1', name: 'Clarke Quay Riverfront Bars', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400', description: 'Historic riverside warehouses converted into bars, restaurants, and live music clubs.', rating: 4.7, estimatedDuration: '3 hrs', estimatedCost: '\$30', address: 'River Valley Rd', durationMinutes: 180),
        ExplorePlaceItem(id: 'sg-night-2', name: 'Cé La Vi Rooftop (MBS)', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Cocktail lounge atop Marina Bay Sands with the most iconic night views.', rating: 4.8, estimatedDuration: '2 hrs', estimatedCost: '\$25', address: 'Marina Bay Sands', durationMinutes: 120),
        ExplorePlaceItem(id: 'sg-night-3', name: 'Spectra Light & Water Show', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400', description: 'Free nightly light show at Marina Bay Sands with fountains, lasers, and music.', rating: 4.6, estimatedDuration: '30 min', estimatedCost: 'Free', address: 'Marina Bay', durationMinutes: 30),
        ExplorePlaceItem(id: 'sg-night-4', name: 'Ann Siang Hill Bar Street', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Charming cocktail bars in restored shophouses between Chinatown and the CBD.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: '\$25', address: 'Ann Siang Hill', durationMinutes: 120),
        ExplorePlaceItem(id: 'sg-night-5', name: 'Gardens by the Bay Light Show', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400', description: 'Free Garden Rhapsody light and sound show with the Supertrees lit up in dazzling colors.', rating: 4.7, estimatedDuration: '1 hr', estimatedCost: 'Free', address: 'Marina Bay', durationMinutes: 60),
        ExplorePlaceItem(id: 'sg-night-6', name: 'Zouk Singapore', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Asia\'s best nightclub (voted top 10 worldwide) with multiple rooms and world-class DJs.', rating: 4.6, estimatedDuration: '3 hrs', estimatedCost: '\$25', address: 'Clarke Quay', durationMinutes: 180),
        ExplorePlaceItem(id: 'sg-night-7', name: 'Boat Quay Craft Beer Walk', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400', description: 'Stroll along the historic riverfront sampling craft beers and cocktails at indie bars.', rating: 4.4, estimatedDuration: '2 hrs', estimatedCost: '\$20', address: 'Boat Quay', durationMinutes: 120),
        ExplorePlaceItem(id: 'sg-night-8', name: 'Night Safari Creatures of the Night', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'A unique after-dark wildlife experience with tram rides through moonlit animal habitats.', rating: 4.8, estimatedDuration: '3 hrs', estimatedCost: '\$42', address: 'Mandai', durationMinutes: 180),
      ],
    };
  }

  // =============================================
  // GENERIC DESTINATION — 8 places per genre
  // =============================================
  Map<int, List<ExplorePlaceItem>> _buildGenericPlaces(String name) {
    return {
      0: [
        ExplorePlaceItem(id: 'gen-beach-1', name: '$name Coastal Beach Park', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400', description: 'A gorgeous beach area popular with locals for relaxing walks and outdoor activities.', rating: 4.5, estimatedDuration: '2-3 hrs', estimatedCost: 'Free', address: '$name Waterfront', durationMinutes: 150),
        ExplorePlaceItem(id: 'gen-beach-2', name: '$name Marine Resort', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Coastal retreat with seaside dining, boat rentals, and ocean views.', rating: 4.6, estimatedDuration: '3-4 hrs', estimatedCost: '\$20', address: '$name Seaside Boulevard', durationMinutes: 210),
        ExplorePlaceItem(id: 'gen-beach-3', name: '$name Riverside Walk', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400', description: 'Scenic waterfront path with benches, ice cream stands, and sunset viewing spots.', rating: 4.4, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: '$name River', durationMinutes: 90),
        ExplorePlaceItem(id: 'gen-beach-4', name: '$name Lakeside Retreat', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=400', description: 'Peaceful lake with paddleboats, picnic areas, and nature trails.', rating: 4.3, estimatedDuration: '2 hrs', estimatedCost: '\$10', address: '$name Lake Park', durationMinutes: 120),
        ExplorePlaceItem(id: 'gen-beach-5', name: '$name Public Pool & Spa', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Modern public swimming complex with outdoor pools, slides, and thermal baths.', rating: 4.4, estimatedDuration: '2-3 hrs', estimatedCost: '\$12', address: '$name Sports District', durationMinutes: 150),
        ExplorePlaceItem(id: 'gen-beach-6', name: '$name Botanical Gardens Fountain', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400', description: 'Beautiful gardens with water features, splash pads, and shaded walking trails.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: '$name Gardens', durationMinutes: 120),
        ExplorePlaceItem(id: 'gen-beach-7', name: '$name Water Sports Centre', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=400', description: 'Try kayaking, paddleboarding, or windsurfing with professional instructors.', rating: 4.3, estimatedDuration: '2-3 hrs', estimatedCost: '\$30', address: '$name Harbor', durationMinutes: 150),
        ExplorePlaceItem(id: 'gen-beach-8', name: '$name Sunset Cruise', genre: 'Summer & Beach', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Relaxing evening boat cruise with stunning sunset views and refreshments.', rating: 4.6, estimatedDuration: '1.5 hrs', estimatedCost: '\$35', address: '$name Marina', durationMinutes: 90),
      ],
      1: [
        ExplorePlaceItem(id: 'gen-kids-1', name: '$name Family Theme Park', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1624601573012-efb68931cc8f?w=400', description: 'Magical park with rides, games, and entertainment for the whole family.', rating: 4.8, estimatedDuration: '5-6 hrs', estimatedCost: '\$40', address: 'Park District, $name', durationMinutes: 330),
        ExplorePlaceItem(id: 'gen-kids-2', name: '$name Science & Discovery Centre', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400', description: 'Interactive exhibits and light installations making science exciting for children.', rating: 4.7, estimatedDuration: '2-3 hrs', estimatedCost: '\$12', address: 'Science Park, $name', durationMinutes: 150),
        ExplorePlaceItem(id: 'gen-kids-3', name: '$name Zoo & Animal Park', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1624601573012-efb68931cc8f?w=400', description: 'Wide variety of animals with feeding sessions and a children\'s petting zoo.', rating: 4.6, estimatedDuration: '3-4 hrs', estimatedCost: '\$20', address: '$name Wildlife Reserve', durationMinutes: 210),
        ExplorePlaceItem(id: 'gen-kids-4', name: '$name Children\'s Museum', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400', description: 'Hands-on museum with creative play areas, building zones, and art studios.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: '\$10', address: 'Museum Quarter, $name', durationMinutes: 120),
        ExplorePlaceItem(id: 'gen-kids-5', name: '$name Aquarium', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1624601573012-efb68931cc8f?w=400', description: 'Underwater tunnels, touch pools, and marine life exhibits from around the world.', rating: 4.6, estimatedDuration: '2-3 hrs', estimatedCost: '\$18', address: '$name Waterfront', durationMinutes: 150),
        ExplorePlaceItem(id: 'gen-kids-6', name: '$name Adventure Playground', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400', description: 'Large outdoor playground with climbing walls, ziplines, and obstacle courses.', rating: 4.4, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: '$name Central Park', durationMinutes: 120),
        ExplorePlaceItem(id: 'gen-kids-7', name: '$name Puppet Theatre', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1624601573012-efb68931cc8f?w=400', description: 'Charming puppet shows and storytelling performances for younger children.', rating: 4.3, estimatedDuration: '1.5 hrs', estimatedCost: '\$8', address: 'Arts Quarter, $name', durationMinutes: 90),
        ExplorePlaceItem(id: 'gen-kids-8', name: '$name Toy Museum', genre: 'Kids & Family', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400', description: 'A nostalgic collection of vintage and modern toys from around the world.', rating: 4.3, estimatedDuration: '1 hr', estimatedCost: '\$6', address: 'Old Town, $name', durationMinutes: 60),
      ],
      2: [
        ExplorePlaceItem(id: 'gen-rel-1', name: '$name Grand Cathedral', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400', description: 'Historic house of worship representing $name\'s architectural heritage.', rating: 4.7, estimatedDuration: '1 hr', estimatedCost: 'Free', address: 'Old Quarter, $name', durationMinutes: 60),
        ExplorePlaceItem(id: 'gen-rel-2', name: '$name Ancient Sanctuary', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=400', description: 'Peaceful centuries-old sanctuary in a quiet grove, ideal for reflection.', rating: 4.6, estimatedDuration: '1-2 hrs', estimatedCost: 'Free', address: 'Sanctuary Forest, $name', durationMinutes: 90),
        ExplorePlaceItem(id: 'gen-rel-3', name: '$name Mosque', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=400', description: 'Beautiful mosque with ornate tilework and a peaceful courtyard garden.', rating: 4.5, estimatedDuration: '45 min', estimatedCost: 'Free', address: 'Cultural District, $name', durationMinutes: 45),
        ExplorePlaceItem(id: 'gen-rel-4', name: '$name Buddhist Temple', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400', description: 'Traditional temple with meditation hall, incense, and beautiful garden.', rating: 4.5, estimatedDuration: '1 hr', estimatedCost: 'Free', address: '$name Buddhist Quarter', durationMinutes: 60),
        ExplorePlaceItem(id: 'gen-rel-5', name: '$name Chapel Hill', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=400', description: 'A hilltop chapel with panoramic views and a history spanning several centuries.', rating: 4.4, estimatedDuration: '1 hr', estimatedCost: 'Free', address: '$name Hillside', durationMinutes: 60),
        ExplorePlaceItem(id: 'gen-rel-6', name: '$name Hindu Temple', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=400', description: 'Colorful temple with elaborate carvings and vibrant prayer ceremonies.', rating: 4.4, estimatedDuration: '45 min', estimatedCost: 'Free', address: '$name Temple Street', durationMinutes: 45),
        ExplorePlaceItem(id: 'gen-rel-7', name: '$name Synagogue', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400', description: 'Historic synagogue with guided tours and a small museum.', rating: 4.3, estimatedDuration: '30 min', estimatedCost: 'Free', address: 'Heritage Quarter, $name', durationMinutes: 30),
        ExplorePlaceItem(id: 'gen-rel-8', name: '$name Meditation Garden', genre: 'Religious', imageUrl: 'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=400', description: 'A serene garden designed for meditation and mindfulness practice.', rating: 4.5, estimatedDuration: '1 hr', estimatedCost: 'Free', address: '$name Zen Gardens', durationMinutes: 60),
      ],
      3: [
        ExplorePlaceItem(id: 'gen-adv-1', name: '$name Skyline Observatory', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400', description: 'Highest observation deck offering stunning 360° panoramas.', rating: 4.7, estimatedDuration: '2 hrs', estimatedCost: '\$20', address: '$name City Tower', durationMinutes: 120),
        ExplorePlaceItem(id: 'gen-adv-2', name: '$name Zipline & Wilderness Trail', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', description: 'Canopy ziplines and mountain trails right outside the city.', rating: 4.6, estimatedDuration: '3-4 hrs', estimatedCost: '\$35', address: 'Outdoors Park, $name', durationMinutes: 210),
        ExplorePlaceItem(id: 'gen-adv-3', name: '$name Rock Climbing Gym', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400', description: 'Indoor bouldering and top-rope climbing with routes for all skill levels.', rating: 4.4, estimatedDuration: '2 hrs', estimatedCost: '\$20', address: '$name Sports Complex', durationMinutes: 120),
        ExplorePlaceItem(id: 'gen-adv-4', name: '$name Cycling Tour', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', description: 'Guided cycling tour through the city\'s most scenic routes and hidden gems.', rating: 4.5, estimatedDuration: '3 hrs', estimatedCost: '\$25', address: '$name Old Town', durationMinutes: 180),
        ExplorePlaceItem(id: 'gen-adv-5', name: '$name Escape Room Experience', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400', description: 'Solve puzzles in themed rooms—mystery, horror, or adventure.', rating: 4.5, estimatedDuration: '1 hr', estimatedCost: '\$25', address: 'Entertainment Zone, $name', durationMinutes: 60),
        ExplorePlaceItem(id: 'gen-adv-6', name: '$name Paragliding', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', description: 'Tandem paragliding flight with stunning aerial views of the surrounding landscape.', rating: 4.7, estimatedDuration: '2 hrs', estimatedCost: '\$80', address: '$name Hills', durationMinutes: 120),
        ExplorePlaceItem(id: 'gen-adv-7', name: '$name River Rafting', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400', description: 'Thrilling whitewater rafting on class II-III rapids through scenic gorges.', rating: 4.4, estimatedDuration: '3 hrs', estimatedCost: '\$50', address: '$name River Valley', durationMinutes: 180),
        ExplorePlaceItem(id: 'gen-adv-8', name: '$name Hot Air Balloon Ride', genre: 'Adventure', imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400', description: 'Float gently above the countryside at sunrise for unforgettable views.', rating: 4.8, estimatedDuration: '2 hrs', estimatedCost: '\$150', address: '$name Countryside', durationMinutes: 120),
      ],
      4: [
        ExplorePlaceItem(id: 'gen-food-1', name: '$name Traditional Food Market', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=400', description: 'Famous local food market with traditional dishes and fresh produce.', rating: 4.8, estimatedDuration: '2 hrs', estimatedCost: '\$15', address: 'Downtown Market, $name', durationMinutes: 120),
        ExplorePlaceItem(id: 'gen-food-2', name: '$name Culinary Cooking Class', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', description: 'Learn traditional recipes from a local professional chef.', rating: 4.8, estimatedDuration: '3 hrs', estimatedCost: '\$45', address: 'Gourmet Atelier, $name', durationMinutes: 180),
        ExplorePlaceItem(id: 'gen-food-3', name: '$name Street Food Tour', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=400', description: 'Guided walking tour sampling the best street food in the old quarter.', rating: 4.6, estimatedDuration: '2.5 hrs', estimatedCost: '\$30', address: 'Old Town, $name', durationMinutes: 150),
        ExplorePlaceItem(id: 'gen-food-4', name: '$name Wine & Cheese Tasting', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', description: 'Sample local wines and artisanal cheeses in a cozy cellar.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: '\$40', address: 'Wine District, $name', durationMinutes: 120),
        ExplorePlaceItem(id: 'gen-food-5', name: '$name Farm-to-Table Restaurant', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=400', description: 'Seasonal menu using locally sourced organic ingredients with garden views.', rating: 4.7, estimatedDuration: '2 hrs', estimatedCost: '\$50', address: 'Countryside, $name', durationMinutes: 120),
        ExplorePlaceItem(id: 'gen-food-6', name: '$name Coffee & Café Culture Tour', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', description: 'Visit 4 independent cafes sampling specialty coffee and local pastries.', rating: 4.4, estimatedDuration: '2 hrs', estimatedCost: '\$15', address: 'Café Quarter, $name', durationMinutes: 120),
        ExplorePlaceItem(id: 'gen-food-7', name: '$name Night Food Market', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?w=400', description: 'Evening market with live cooking, neon lights, and dozens of food stalls.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: '\$15', address: 'Night Market, $name', durationMinutes: 120),
        ExplorePlaceItem(id: 'gen-food-8', name: '$name Fine Dining Experience', genre: 'Food & Culinary', imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', description: 'Multi-course tasting menu at one of $name\'s top-rated restaurants.', rating: 4.8, estimatedDuration: '2.5 hrs', estimatedCost: '\$100', address: 'Gourmet Street, $name', durationMinutes: 150),
      ],
      5: [
        ExplorePlaceItem(id: 'gen-cult-1', name: '$name National Heritage Museum', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', description: 'Rich collection of artifacts tracing the region\'s history and artistic triumphs.', rating: 4.8, estimatedDuration: '2-3 hrs', estimatedCost: '\$10', address: 'Cultural Plaza, $name', durationMinutes: 150),
        ExplorePlaceItem(id: 'gen-cult-2', name: '$name Old Town Walking Tour', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=400', description: 'Guided walk through the oldest cobblestone alleys uncovering historical legends.', rating: 4.7, estimatedDuration: '2 hrs', estimatedCost: '\$15', address: 'Old Town Square, $name', durationMinutes: 120),
        ExplorePlaceItem(id: 'gen-cult-3', name: '$name Art Gallery', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', description: 'Contemporary and classical art exhibitions featuring local and international artists.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: '\$12', address: 'Arts District, $name', durationMinutes: 120),
        ExplorePlaceItem(id: 'gen-cult-4', name: '$name Historic Castle', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=400', description: 'Medieval castle with guided tours, knight armor displays, and panoramic views.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: '\$15', address: '$name Castle Hill', durationMinutes: 120),
        ExplorePlaceItem(id: 'gen-cult-5', name: '$name Folk Music Performance', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', description: 'Live traditional music performance in a historic venue with local instruments.', rating: 4.4, estimatedDuration: '1.5 hrs', estimatedCost: '\$15', address: 'Music Hall, $name', durationMinutes: 90),
        ExplorePlaceItem(id: 'gen-cult-6', name: '$name Ethnic Quarter', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=400', description: 'Vibrant neighborhood celebrating diverse cultures with markets, temples, and street art.', rating: 4.5, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: '$name Cultural District', durationMinutes: 120),
        ExplorePlaceItem(id: 'gen-cult-7', name: '$name Archaeological Site', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', description: 'Ancient ruins and excavation sites with informative guided tours.', rating: 4.4, estimatedDuration: '2 hrs', estimatedCost: '\$10', address: '$name Outskirts', durationMinutes: 120),
        ExplorePlaceItem(id: 'gen-cult-8', name: '$name Photography Museum', genre: 'Culture & History', imageUrl: 'https://images.unsplash.com/photo-1513326738677-b964603b136d?w=400', description: 'Rotating exhibitions of world-class photography from local and international artists.', rating: 4.3, estimatedDuration: '1.5 hrs', estimatedCost: '\$8', address: 'Arts Quarter, $name', durationMinutes: 90),
      ],
      6: [
        ExplorePlaceItem(id: 'gen-shop-1', name: '$name Central Shopping Mall', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', description: 'Premier shopping destination with international brands and entertainment.', rating: 4.5, estimatedDuration: '2-3 hrs', estimatedCost: 'Free', address: 'Broadway Street, $name', durationMinutes: 150),
        ExplorePlaceItem(id: 'gen-shop-2', name: '$name Traditional Crafts Bazaar', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400', description: 'Open-air bazaar selling handmade pottery, textiles, jewelry, and souvenirs.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Artisans Market, $name', durationMinutes: 120),
        ExplorePlaceItem(id: 'gen-shop-3', name: '$name Luxury Outlet Village', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', description: 'Designer brands at discounted prices in an open-air outlet mall.', rating: 4.4, estimatedDuration: '2-3 hrs', estimatedCost: 'Free', address: 'Outlet District, $name', durationMinutes: 150),
        ExplorePlaceItem(id: 'gen-shop-4', name: '$name Vintage & Thrift District', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400', description: 'Hip neighborhood with second-hand clothing, vinyl records, and retro finds.', rating: 4.4, estimatedDuration: '2 hrs', estimatedCost: 'Free', address: 'Vintage Quarter, $name', durationMinutes: 120),
        ExplorePlaceItem(id: 'gen-shop-5', name: '$name Design District', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', description: 'Independent design stores, art print shops, and concept stores.', rating: 4.5, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'Design Quarter, $name', durationMinutes: 90),
        ExplorePlaceItem(id: 'gen-shop-6', name: '$name Farmers Market', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400', description: 'Weekend market with organic produce, artisan breads, and handmade products.', rating: 4.5, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: '$name Town Square', durationMinutes: 90),
        ExplorePlaceItem(id: 'gen-shop-7', name: '$name Bookstore District', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', description: 'Charming independent bookstores and antiquarian shops in the literary quarter.', rating: 4.3, estimatedDuration: '1.5 hrs', estimatedCost: 'Free', address: 'Book Street, $name', durationMinutes: 90),
        ExplorePlaceItem(id: 'gen-shop-8', name: '$name Souvenir Arcade', genre: 'Shopping', imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400', description: 'Indoor arcade with local crafts, magnets, clothing, and memorable keepsakes.', rating: 4.2, estimatedDuration: '1 hr', estimatedCost: 'Free', address: 'Tourist District, $name', durationMinutes: 60),
      ],
      7: [
        ExplorePlaceItem(id: 'gen-night-1', name: '$name Skyline Lounge & Rooftop', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400', description: 'Signature cocktails with the illuminated skyline stretching out before you.', rating: 4.7, estimatedDuration: '2-3 hrs', estimatedCost: '\$25', address: 'Grand Hotel Roof, $name', durationMinutes: 150),
        ExplorePlaceItem(id: 'gen-night-2', name: '$name Night Food & Music Street', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Vibrant street festival with live performances, neon lights, and food trucks.', rating: 4.6, estimatedDuration: '2 hrs', estimatedCost: '\$20', address: 'Entertainment Zone, $name', durationMinutes: 120),
        ExplorePlaceItem(id: 'gen-night-3', name: '$name Live Music Venue', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400', description: 'Intimate venue hosting local bands and international touring artists.', rating: 4.5, estimatedDuration: '2-3 hrs', estimatedCost: '\$15', address: 'Music District, $name', durationMinutes: 150),
        ExplorePlaceItem(id: 'gen-night-4', name: '$name Theatre & Performance Show', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Evening theatre performance showcasing local talent and international productions.', rating: 4.6, estimatedDuration: '2.5 hrs', estimatedCost: '\$40', address: 'Theatre Row, $name', durationMinutes: 150),
        ExplorePlaceItem(id: 'gen-night-5', name: '$name Craft Cocktail Bar Tour', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400', description: 'Visit three of the city\'s best cocktail bars with a knowledgeable guide.', rating: 4.5, estimatedDuration: '3 hrs', estimatedCost: '\$35', address: 'Bar Quarter, $name', durationMinutes: 180),
        ExplorePlaceItem(id: 'gen-night-6', name: '$name Night Market Crawl', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Browse stalls of handicrafts, snacks, and live entertainment after sunset.', rating: 4.4, estimatedDuration: '2 hrs', estimatedCost: '\$10', address: 'Night Market, $name', durationMinutes: 120),
        ExplorePlaceItem(id: 'gen-night-7', name: '$name Comedy Night', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400', description: 'Stand-up comedy in English and local language with emerging and established comedians.', rating: 4.3, estimatedDuration: '2 hrs', estimatedCost: '\$15', address: 'Comedy Club, $name', durationMinutes: 120),
        ExplorePlaceItem(id: 'gen-night-8', name: '$name Moonlight River Walk', genre: 'Nightlife', imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deecef07?w=400', description: 'Romantic evening stroll along the illuminated riverside promenade.', rating: 4.5, estimatedDuration: '1 hr', estimatedCost: 'Free', address: '$name Riverside', durationMinutes: 60),
      ],
    };
  }

  void _togglePlaceSelection(ExplorePlaceItem place) {
    final selected = List<ExplorePlaceItem>.from(ref.read(selectedPlacesProvider));
    final idx = selected.indexWhere((p) => p.id == place.id);
    if (idx >= 0) {
      selected.removeAt(idx);
      _removeFromDaySchedule(place.id);
    } else {
      selected.add(place.copyWith(isSelected: true));
    }
    ref.read(selectedPlacesProvider.notifier).state = selected;
  }

  void _removeFromDaySchedule(String placeId) {
    final schedule = ref.read(dayScheduleProvider);
    final notifier = ref.read(dayScheduleProvider.notifier);
    for (int d = 0; d < schedule.length; d++) {
      if (schedule[d].any((item) => item.place.id == placeId)) {
        notifier.removeFromDay(d, placeId);
        break;
      }
    }
  }

  void _showScheduleToDayDialog(ExplorePlaceItem place) {
    final isDark = ref.read(isDarkProvider);
    final bookings = ref.read(tripBookingsProvider);
    final numDays = bookings.tripDays;
    final startDateStr = bookings.startDate;
    DateTime? start;
    if (startDateStr != null && startDateStr.isNotEmpty) {
      try {
        start = DateTime.parse(startDateStr);
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AiraColors.dialogBg(isDark),
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
                    color: AiraColors.border(isDark),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'SCHEDULE TO DAY',
                style: TextStyle(color: AiraColors.textPrimary(isDark), fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Select a day to add and schedule ${place.name}',
                style: TextStyle(color: AiraColors.textSecondary(isDark), fontSize: 12),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: numDays,
                  itemBuilder: (context, idx) {
                    String dateLabel = '';
                    if (start != null) {
                      final dayDate = start.add(Duration(days: idx));
                      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                      dateLabel = ' • ${months[dayDate.month - 1]} ${dayDate.day}';
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AiraColors.cardBg(isDark),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: AiraColors.border(isDark)),
                            ),
                          ),
                          onPressed: () {
                            // 1. Add to selected places provider if not already there
                            final selected = List<ExplorePlaceItem>.from(ref.read(selectedPlacesProvider));
                            if (!selected.any((p) => p.id == place.id)) {
                              selected.add(place.copyWith(isSelected: true));
                              ref.read(selectedPlacesProvider.notifier).state = selected;
                            }

                            // 2. Initialize days in DaySchedule if not initialized
                            final schedule = ref.read(dayScheduleProvider);
                            if (schedule.length < numDays) {
                              ref.read(dayScheduleProvider.notifier).initDays(numDays);
                            }

                            // 3. Remove from any other day first to avoid duplicate schedules
                            _removeFromDaySchedule(place.id);

                            // 4. Add to the chosen day schedule
                            final item = DayScheduleItem(
                              place: place,
                              dayNumber: idx + 1,
                            );
                            ref.read(dayScheduleProvider.notifier).addToDay(idx, item, bookings);

                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added ${place.name} to Day ${idx + 1}$dateLabel'),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB), size: 16),
                              const SizedBox(width: 12),
                              Text(
                                'Day ${idx + 1}$dateLabel',
                                style: TextStyle(
                                  color: AiraColors.textPrimary(isDark),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.add_circle_outline, color: Color(0xFF10B981), size: 18),
                            ],
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
  }


  bool _isPlaceSelected(String placeId) {
    return ref.read(selectedPlacesProvider).any((p) => p.id == placeId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkProvider);
    final selectedPlaces = ref.watch(selectedPlacesProvider);
    final activeLabel = _genres[_activeGenre]['label'] as String;
    final allPlaces = _placesByGenre[activeLabel] ?? [];
    final currentPlaces = _searchQuery.isEmpty
        ? allPlaces
        : allPlaces
            .where((place) =>
                place.name.toLowerCase().contains(_searchQuery) ||
                place.description.toLowerCase().contains(_searchQuery))
            .toList();
    final genreInfo = _genres[_activeGenre];
    final bookings = ref.watch(tripBookingsProvider);
    final schedule = ref.watch(dayScheduleProvider);

    int? getAssignedDay(String placeId) {
      for (int d = 0; d < schedule.length; d++) {
        if (schedule[d].any((item) => item.place.id == placeId)) {
          return d + 1;
        }
      }
      return null;
    }
    
    final startDateStr = bookings.startDate;
    DateTime? start;
    if (startDateStr != null && startDateStr.isNotEmpty) {
      try {
        start = DateTime.parse(startDateStr);
      } catch (_) {}
    }


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
            Text('Explore Places', style: TextStyle(color: AiraColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 18)),
            const Text('STEP 2 — SELECT ATTRACTIONS', style: TextStyle(color: Color(0xFF00B4D8), fontWeight: FontWeight.w800, fontSize: 9, letterSpacing: 0.5)),
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
                Icon(Icons.looks_two, color: Color(0xFF60A5FA), size: 14),
                SizedBox(width: 4),
                Text('2/4', style: TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.bold, fontSize: 11)),
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
                _stepDot(true, 'Bookings', isDark),
                _stepLine(true, isDark),
                _stepDot(true, 'Explore', isDark),
                _stepLine(false, isDark),
                _stepDot(false, 'Schedule', isDark),
                _stepLine(false, isDark),
                _stepDot(false, 'Preview', isDark),
              ],
            ),
          ),

          // Genre Tabs
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _genres.length,
              itemBuilder: (ctx, idx) {
                final genre = _genres[idx];
                final active = _activeGenre == idx;
                return GestureDetector(
                  onTap: () {
                    setState(() => _activeGenre = idx);
                    _preloadWikipediaForActiveGenre();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: active ? (genre['color'] as Color) : AiraColors.cardBg(isDark),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: active ? (genre['color'] as Color) : AiraColors.border(isDark),
                      ),
                      boxShadow: active ? [
                        BoxShadow(
                          color: (genre['color'] as Color).withValues(alpha: 0.3),
                          blurRadius: 8, offset: const Offset(0, 3),
                        ),
                      ] : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(genre['icon'] as IconData, size: 14,
                          color: active ? Colors.white : AiraColors.textSecondary(isDark),
                        ),
                        const SizedBox(width: 6),
                        Text(genre['label'] as String,
                          style: TextStyle(
                            color: active ? Colors.white : AiraColors.textSecondary(isDark),
                            fontWeight: FontWeight.bold, fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(color: AiraColors.textPrimary(isDark), fontSize: 13, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search places by name...',
                hintStyle: TextStyle(color: AiraColors.textMuted(isDark), fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF60A5FA), size: 18),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, color: AiraColors.textSecondary(isDark), size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AiraColors.cardBg(isDark),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AiraColors.border(isDark)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF60A5FA)),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(height: 12),

          // Genre Header — dynamic destination name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(genreInfo['icon'] as IconData, color: genreInfo['color'] as Color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${(genreInfo['label'] as String).toUpperCase()} IN ${_destinationName.toUpperCase()}',
                    style: TextStyle(color: AiraColors.textPrimary(isDark), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text('${currentPlaces.length} places',
                  style: TextStyle(color: AiraColors.textMuted(isDark), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Places List
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFFBBF24), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Color(0xFF2563EB)),
                        const SizedBox(height: 16),
                        Text(
                          'Seeking best local attractions...',
                          style: TextStyle(color: AiraColors.textSecondary(isDark), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : currentPlaces.isEmpty
                    ? Center(
                        child: Text(
                          'No attractions found in this category.',
                          style: TextStyle(color: AiraColors.textSecondary(isDark), fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: currentPlaces.length,
                        itemBuilder: (ctx, idx) {
                final place = currentPlaces[idx];
                final isSelected = _isPlaceSelected(place.id);
                final isExpanded = _expandedPlaceId == place.id;
                final wiki = _wikiSummaries[place.id];
                final displayImageUrl = (wiki?.thumbnailUrl != null) ? wiki!.thumbnailUrl! : place.imageUrl;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AiraColors.cardBg(isDark),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF10B981)
                          : AiraColors.border(isDark),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        blurRadius: 12, offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image + overlay
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                            child: (displayImageUrl.isNotEmpty && (displayImageUrl.startsWith('http://') || displayImageUrl.startsWith('https://')))
                                ? Image.network(
                                    displayImageUrl,
                                    height: 150, width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, st) => Container(
                                      height: 150,
                                      color: (genreInfo['color'] as Color).withValues(alpha: 0.2),
                                      child: Center(
                                        child: Icon(genreInfo['icon'] as IconData,
                                          size: 48, color: (genreInfo['color'] as Color).withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    height: 150, width: double.infinity,
                                    color: (genreInfo['color'] as Color).withValues(alpha: 0.2),
                                    child: Center(
                                      child: Icon(genreInfo['icon'] as IconData,
                                        size: 48, color: (genreInfo['color'] as Color).withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                          ),
                          // Gradient overlay
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                                ),
                              ),
                            ),
                          ),
                          // Rating badge
                          Positioned(
                            top: 10, right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, color: Color(0xFFFBBF24), size: 12),
                                  const SizedBox(width: 3),
                                  Text('${place.rating}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Selected/Scheduled badge
                          if (isSelected)
                            Positioned(
                              top: 10, left: 10,
                              child: Builder(
                                builder: (ctx) {
                                  final assigned = getAssignedDay(place.id);
                                  final text = assigned != null ? 'DAY $assigned' : 'ADDED';
                                  final icon = assigned != null ? Icons.calendar_today : Icons.check_circle;
                                  
                                  String dateText = '';
                                  if (assigned != null && start != null) {
                                    final dayDate = start.add(Duration(days: assigned - 1));
                                    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                    dateText = ' (${months[dayDate.month - 1]} ${dayDate.day})';
                                  }

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: assigned != null ? const Color(0xFF2563EB) : const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(icon, color: Colors.white, size: 12),
                                        const SizedBox(width: 4),
                                        Text('$text$dateText', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9)),
                                      ],
                                    ),
                                  );
                                }
                              ),
                            ),

                        ],
                      ),

                      // Info section
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(place.name,
                              style: TextStyle(color: AiraColors.textPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _infoBadge(Icons.schedule, '${place.durationMinutes}min', const Color(0xFF64748B)),
                                const SizedBox(width: 8),
                                _infoBadge(Icons.attach_money, place.estimatedCost, const Color(0xFF10B981)),
                                const SizedBox(width: 8),
                                _infoBadge(Icons.location_on, place.address.split(',').first, const Color(0xFF60A5FA)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              wiki?.description ?? place.description,
                              style: TextStyle(color: AiraColors.textPrimary(isDark).withValues(alpha: 0.7), fontSize: 12, height: 1.4),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),

                            // Expandable details
                            if (isExpanded) ...[
                              const SizedBox(height: 12),
                              if (_wikiLoading[place.id] ?? false) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  alignment: Alignment.center,
                                  child: const Column(
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF60A5FA),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Loading Wikipedia summary...',
                                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else if (_wikiSummaries[place.id] != null) ...[
                                Builder(
                                  builder: (context) {
                                    final wiki = _wikiSummaries[place.id]!;
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AiraColors.surfaceElevated(isDark),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AiraColors.border(isDark).withValues(alpha: 0.5)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.menu_book, color: Color(0xFF60A5FA), size: 10),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'WIKIPEDIA SUMMARY',
                                                      style: TextStyle(
                                                        color: Color(0xFF60A5FA),
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 9,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Spacer(),
                                              const Text(
                                                'From Wikipedia',
                                                style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontStyle: FontStyle.italic),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      wiki.title,
                                                      style: TextStyle(
                                                        color: AiraColors.textPrimary(isDark),
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      wiki.description,
                                                      style: TextStyle(
                                                        color: AiraColors.textSecondary(isDark),
                                                        fontSize: 12,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (wiki.thumbnailUrl != null &&
                                                  wiki.thumbnailUrl!.isNotEmpty &&
                                                  (wiki.thumbnailUrl!.startsWith('http://') ||
                                                   wiki.thumbnailUrl!.startsWith('https://'))) ...[
                                                const SizedBox(width: 12),
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    wiki.thumbnailUrl!,
                                                    width: 70,
                                                    height: 70,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                ),
                              ] else ...[
                                Text(place.description,
                                  style: TextStyle(color: AiraColors.textSecondary(isDark), fontSize: 12, height: 1.4),
                                ),
                              ],
                            ],

                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // View Details / Collapse
                                GestureDetector(
                                  onTap: () {
                                    final willExpand = !isExpanded;
                                    setState(() {
                                      _expandedPlaceId = willExpand ? place.id : null;
                                    });
                                    if (willExpand) {
                                      _fetchWikipediaSummaryFor(place);
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                                        size: 16, color: const Color(0xFF60A5FA),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(isExpanded ? 'Less Details' : 'View Details',
                                        style: const TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                // Add / Remove / Schedule buttons
                                Builder(
                                  builder: (ctx) {
                                    final assigned = getAssignedDay(place.id);
                                    
                                    if (assigned != null) {
                                      // Scheduled: Show "Remove from Day" and "Change Day"
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            height: 36,
                                            child: TextButton.icon(
                                              style: TextButton.styleFrom(
                                                foregroundColor: const Color(0xFFEF4444),
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                              ),
                                              onPressed: () {
                                                _removeFromDaySchedule(place.id);
                                              },
                                              icon: const Icon(Icons.remove_circle_outline, size: 16),
                                              label: const Text('Unschedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          SizedBox(
                                            height: 36,
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF2563EB),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                              ),
                                              onPressed: () => _showScheduleToDayDialog(place),
                                              icon: const Icon(Icons.edit_calendar, size: 14, color: Colors.white),
                                              label: const Text('Move', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                            ),
                                          ),
                                        ],
                                      );
                                    } else if (isSelected) {
                                      // Selected but not scheduled: Show "Remove" and "Schedule"
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            height: 36,
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(color: Color(0xFFEF4444)),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                                foregroundColor: const Color(0xFFEF4444),
                                              ),
                                              onPressed: () => _togglePlaceSelection(place),
                                              child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            height: 36,
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF2563EB),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                              ),
                                              onPressed: () => _showScheduleToDayDialog(place),
                                              icon: const Icon(Icons.add_to_photos, size: 14, color: Colors.white),
                                              label: const Text('Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                            ),
                                          ),
                                        ],
                                      );
                                    } else {
                                      // Not selected: Show "Add to Trip" and "+ Day"
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            height: 36,
                                            child: OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(color: Color(0xFF10B981)),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                                foregroundColor: const Color(0xFF10B981),
                                              ),
                                              onPressed: () => _togglePlaceSelection(place),
                                              icon: const Icon(Icons.add, size: 14),
                                              label: const Text('Add Pool', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            height: 36,
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF10B981),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                              ),
                                              onPressed: () => _showScheduleToDayDialog(place),
                                              icon: const Icon(Icons.calendar_today, size: 14, color: Colors.white),
                                              label: const Text('+ Day', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                  }
                                ),

                              ],
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

          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F2847) : Colors.white,
              border: Border(top: BorderSide(color: AiraColors.border(isDark).withValues(alpha: 0.5))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.place, color: Color(0xFF10B981), size: 16),
                        const SizedBox(width: 4),
                        Text('${selectedPlaces.length} selected',
                          style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12),
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
                          backgroundColor: selectedPlaces.isNotEmpty
                              ? const Color(0xFF2563EB)
                              : AiraColors.border(isDark),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: selectedPlaces.isNotEmpty ? () {
                          // Initialize day schedule with trip days if not already set up
                          final bookings = ref.read(tripBookingsProvider);
                          final numDays = bookings.tripDays;
                          final schedule = ref.read(dayScheduleProvider);
                          if (schedule.isEmpty || schedule.length != numDays) {
                            ref.read(dayScheduleProvider.notifier).initDays(numDays);
                          }
                          context.push('/itinerary-wizard/schedule');
                        } : null,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('ASSIGN TO DAYS',
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

  Widget _infoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _stepDot(bool active, String label, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF2563EB) : AiraColors.cardBg(isDark),
              shape: BoxShape.circle,
              border: Border.all(color: active ? const Color(0xFF2563EB) : AiraColors.border(isDark), width: 2),
            ),
            child: active ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            color: active ? const Color(0xFF60A5FA) : AiraColors.textMuted(isDark),
            fontSize: 9, fontWeight: FontWeight.bold,
          )),
        ],
      ),
    );
  }

  Widget _stepLine(bool active, bool isDark) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: active ? const Color(0xFF2563EB) : AiraColors.border(isDark),
      ),
    );
  }
}
