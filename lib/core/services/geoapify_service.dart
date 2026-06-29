import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/hotel_place.dart';
import '../models/travel_models.dart';

class GeoapifyException implements Exception {
  const GeoapifyException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GeoapifyService {
  GeoapifyService({
    http.Client? client,
    String? apiKey,
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey ?? _defaultApiKey;

  static const String _defaultApiKey = String.fromEnvironment(
    'GEOAPIFY_API_KEY',
    defaultValue: '05e71547d11d4d3aa21ce97cad23c007',
  );

  final http.Client _client;
  final String _apiKey;

  Future<List<HotelPlace>> searchHotels(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) {
      return const [];
    }

    final uri = Uri.https(
      'api.geoapify.com',
      '/v1/geocode/autocomplete',
      {
        'text': trimmedQuery,
        'limit': '8',
        'format': 'geojson',
        'apiKey': _apiKey,
      },
    );

    final response = await _client.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GeoapifyException(
        'Hotel search failed (${response.statusCode}). Please try again.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const GeoapifyException('Geoapify returned an invalid response.');
    }

    final features = decoded['features'];
    if (features is! List) {
      return const [];
    }

    return features
        .whereType<Map<String, dynamic>>()
        .map(HotelPlace.fromGeoapifyFeature)
        .toList(growable: false);
  }

  Future<Map<String, double>?> geocodeCity(String cityName) async {
    final query = cityName.trim();
    if (query.isEmpty) return null;

    final uri = Uri.https(
      'api.geoapify.com',
      '/v1/geocode/search',
      {
        'text': query,
        'limit': '1',
        'apiKey': _apiKey,
      },
    );

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      final features = decoded['features'];
      if (features is! List || features.isEmpty) return null;

      final first = features.first;
      final properties = first['properties'];
      if (properties is! Map<String, dynamic>) return null;

      final lat = properties['lat'];
      final lon = properties['lon'];
      if (lat is num && lon is num) {
        return {'lat': lat.toDouble(), 'lon': lon.toDouble()};
      }
    } catch (_) {}
    return null;
  }

  Future<List<ExplorePlaceItem>> fetchNearbyPlaces(double lat, double lon, String cityName) async {
    final categories = [
      'tourism.attraction',
      'tourism.sights',
      'leisure.park',
      'leisure.playground',
      'entertainment',
      'catering.restaurant',
      'catering.cafe',
      'catering.bar',
      'catering.pub',
      'commercial.shopping_mall',
      'commercial.department_store',
      'commercial.gift_and_souvenir',
      'religion'
    ].join(',');

    final uri = Uri.https(
      'api.geoapify.com',
      '/v2/places',
      {
        'categories': categories,
        'filter': 'circle:$lon,$lat,15000',
        'bias': 'proximity:$lon,$lat',
        'limit': '150',
        'apiKey': _apiKey,
      },
    );

    final response = await _client.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GeoapifyException('Failed to fetch local attractions (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const GeoapifyException('Invalid places response from Geoapify.');
    }

    final features = decoded['features'];
    if (features is! List) {
      return const [];
    }

    final List<ExplorePlaceItem> items = [];
    int index = 0;

    for (final f in features) {
      if (f is! Map<String, dynamic>) continue;
      final properties = f['properties'] as Map<String, dynamic>? ?? {};
      final name = properties['name']?.toString() ?? '';
      
      // Exclude unnamed places
      if (name.isEmpty) continue;

      final placeCategories = properties['categories'] as List? ?? [];
      final genre = _categorizePlace(placeCategories);
      final address = properties['formatted']?.toString() ?? properties['street']?.toString() ?? cityName;
      
      // Pseudo-random deterministic rating
      final double rating = 4.3 + (name.hashCode.abs() % 7) * 0.1;
      
      // Select image based on name (LoremFlickr fallback)
      final imageUrl = 'https://loremflickr.com/400/300/${Uri.encodeComponent(name)}';

      // Duration & Cost estimates based on genre
      final durationMin = _getDurationForGenre(genre);
      final durationStr = '${(durationMin / 60).toStringAsFixed(0)} hrs';
      final costStr = _getCostForGenre(genre);

      items.add(ExplorePlaceItem(
        id: 'geo-place-${properties['place_id'] ?? index++}',
        name: name,
        genre: genre,
        imageUrl: imageUrl,
        description: properties['description']?.toString() ?? 'A highly rated $genre spot in $cityName. Known as "$name", it is a popular destination for visitors looking to experience local sights, activities, and highlights of the area.',
        rating: double.parse(rating.toStringAsFixed(1)),
        estimatedDuration: durationStr,
        estimatedCost: costStr,
        address: address,
        durationMinutes: durationMin,
      ));
    }

    return items;
  }

  String _categorizePlace(List<dynamic> categories) {
    final catSet = categories.map((c) => c.toString()).toSet();

    // Nightlife
    if (catSet.any((c) => c.startsWith('catering.bar') || c.startsWith('catering.pub') || c.startsWith('entertainment.nightclub') || c == 'adult.nightclub')) {
      return 'Nightlife';
    }

    // Food & Culinary
    if (catSet.any((c) => c.startsWith('catering.restaurant') || c.startsWith('catering.cafe') || c.startsWith('catering.fast_food'))) {
      return 'Food & Culinary';
    }

    // Shopping
    if (catSet.any((c) => c.startsWith('commercial'))) {
      return 'Shopping';
    }

    // Religious
    if (catSet.any((c) => c.startsWith('religion'))) {
      return 'Religious';
    }

    // Kids & Family
    if (catSet.any((c) => c.contains('zoo') || c.contains('aquarium') || c.contains('theme_park') || c.contains('playground') || c.contains('water_park'))) {
      return 'Kids & Family';
    }

    // Culture & History
    if (catSet.any((c) => c.contains('museum') || c.contains('heritage') || c.contains('sights') || c.contains('monument') || c.contains('historic') || c.contains('artwork') || c.contains('castle') || c.contains('ruins') || c.contains('archaeological_site'))) {
      return 'Culture & History';
    }

    // Summer & Beach
    if (catSet.any((c) => c.contains('beach') || c.contains('water') || c.contains('park') || c.contains('lake') || c.contains('sea')) && !catSet.any((c) => c.contains('theme_park') || c.contains('water_park'))) {
      return 'Summer & Beach';
    }

    // Default or Adventure
    return 'Adventure';
  }

  String _getImageForGenre(String genre) {
    switch (genre) {
      case 'Summer & Beach':
        return 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400';
      case 'Kids & Family':
        return 'https://images.unsplash.com/photo-1534567153574-2b12153a63f0?w=400';
      case 'Religious':
        return 'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400';
      case 'Adventure':
        return 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=400';
      case 'Food & Culinary':
        return 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400';
      case 'Culture & History':
        return 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400';
      case 'Shopping':
        return 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400';
      case 'Nightlife':
        return 'https://images.unsplash.com/photo-1532236204992-f5e85c024202?w=400';
      default:
        return 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400';
    }
  }

  int _getDurationForGenre(String genre) {
    switch (genre) {
      case 'Summer & Beach':
        return 150;
      case 'Kids & Family':
        return 180;
      case 'Religious':
        return 60;
      case 'Adventure':
        return 120;
      case 'Food & Culinary':
        return 90;
      case 'Culture & History':
        return 120;
      case 'Shopping':
        return 120;
      case 'Nightlife':
        return 150;
      default:
        return 90;
    }
  }

  String _getCostForGenre(String genre) {
    switch (genre) {
      case 'Summer & Beach':
        return 'Free';
      case 'Kids & Family':
        return '\$15';
      case 'Religious':
        return 'Free';
      case 'Adventure':
        return '\$25';
      case 'Food & Culinary':
        return '\$18';
      case 'Culture & History':
        return '\$10';
      case 'Shopping':
        return 'Free';
      case 'Nightlife':
        return '\$20';
      default:
        return 'Free';
    }
  }

  void dispose() {
    _client.close();
  }
}
