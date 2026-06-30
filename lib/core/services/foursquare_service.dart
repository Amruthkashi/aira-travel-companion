import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/travel_models.dart';

class FoursquareException implements Exception {
  final String message;
  const FoursquareException(this.message);

  @override
  String toString() => message;
}

class FoursquareService {
  final http.Client _client;
  static const String _apiKey = 'QQHNICHDMBVUGGW55WP0PVFMFXY0PKYCALPME5VSJJNLZ00P';

  FoursquareService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<ExplorePlaceItem>> fetchNearbyPlaces(double lat, double lon, String cityName) async {
    // Foursquare Places Search v3 fields
    const fields = 'fsq_id,name,location,categories,rating,description,photos';
    
    final uri = Uri.https(
      'api.foursquare.com',
      '/v3/places/search',
      {
        'll': '$lat,$lon',
        'radius': '15000',
        'limit': '50',
        'fields': fields,
      },
    );

    final authKey = _apiKey.startsWith('fsq3_') ? _apiKey : 'fsq3_$_apiKey';
    final response = await _client.get(
      uri,
      headers: {
        'Authorization': authKey,
        'accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FoursquareException('Failed to fetch attractions (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FoursquareException('Invalid response structure for attractions.');
    }

    final results = decoded['results'];
    if (results is! List) {
      return const [];
    }

    final List<ExplorePlaceItem> items = [];
    int index = 0;

    for (final p in results) {
      if (p is! Map<String, dynamic>) continue;
      final name = p['name']?.toString() ?? '';
      
      // Exclude unnamed places
      if (name.isEmpty) continue;

      final categories = p['categories'] as List? ?? [];
      final genre = _categorizeFoursquarePlace(categories);
      
      final location = p['location'] as Map<String, dynamic>? ?? {};
      final address = location['formatted_address']?.toString() ?? location['address']?.toString() ?? cityName;
      
      // Rating: scale 10-point Foursquare rating to 5-stars
      double rating = 4.0;
      final rawRating = p['rating'];
      if (rawRating is num) {
        rating = double.parse((rawRating / 2.0).toStringAsFixed(1));
      } else {
        // Deterministic pseudo-random rating based on name
        rating = double.parse((4.0 + (name.hashCode.abs() % 11) * 0.1).toStringAsFixed(1));
      }

      // Photos: Build high-quality photo URL if available
      String imageUrl = '';
      final photos = p['photos'];
      if (photos is List && photos.isNotEmpty) {
        final firstPhoto = photos.first;
        if (firstPhoto is Map<String, dynamic>) {
          final prefix = firstPhoto['prefix']?.toString() ?? '';
          final suffix = firstPhoto['suffix']?.toString() ?? '';
          if (prefix.isNotEmpty && suffix.isNotEmpty) {
            imageUrl = '${prefix}500x300$suffix';
          }
        }
      }
      if (imageUrl.isEmpty) {
        imageUrl = 'https://loremflickr.com/400/300/${Uri.encodeComponent(name)}';
      }

      // Description
      final description = p['description']?.toString() ?? 'A popular $genre attraction in $cityName. Known as "$name", it is a great destination for travelers exploring the local highlights and culture.';

      // Duration & Cost estimates based on genre
      final durationMin = _getDurationForGenre(genre);
      final durationStr = '${(durationMin / 60).toStringAsFixed(0)} hrs';
      final costStr = _getCostForGenre(genre);

      items.add(ExplorePlaceItem(
        id: 'fsq-place-${p['fsq_id'] ?? index++}',
        name: name,
        genre: genre,
        imageUrl: imageUrl,
        description: description,
        rating: rating,
        estimatedDuration: durationStr,
        estimatedCost: costStr,
        address: address,
        durationMinutes: durationMin,
      ));
    }

    return items;
  }

  String _categorizeFoursquarePlace(List<dynamic> categories) {
    if (categories.isEmpty) return 'Adventure';
    
    for (final cat in categories) {
      if (cat is! Map<String, dynamic>) continue;
      final int? id = cat['id'] as int?;
      final String name = (cat['name']?.toString() ?? '').toLowerCase();
      
      if (id == null) continue;
      
      // Nightlife (Bars, Nightclubs, Pubs)
      if (id == 13003 || (id >= 13006 && id <= 13025) || id == 10032 || name.contains('nightclub') || name.contains('bar') || name.contains('pub') || name.contains('brewery')) {
        return 'Nightlife';
      }
      
      // Food & Culinary (Restaurants, Cafes, Diners)
      if ((id >= 13000 && id <= 13347) || name.contains('restaurant') || name.contains('cafe') || name.contains('bakery') || name.contains('food') || name.contains('coffee')) {
        return 'Food & Culinary';
      }
      
      // Shopping (Malls, Shops, Markets)
      if ((id >= 17000 && id <= 17143) || name.contains('shopping') || name.contains('mall') || name.contains('store') || name.contains('boutique') || name.contains('market')) {
        return 'Shopping';
      }
      
      // Religious (Temples, Churches, Mosques, Shrines)
      if (id == 12097 || (id >= 12098 && id <= 12112) || name.contains('temple') || name.contains('church') || name.contains('mosque') || name.contains('shrine') || name.contains('synagogue') || name.contains('religious') || name.contains('place of worship')) {
        return 'Religious';
      }
      
      // Kids & Family (Amusement parks, Zoos, Aquariums, Playgrounds)
      if (id == 10001 || id == 10002 || id == 10056 || name.contains('zoo') || name.contains('aquarium') || name.contains('amusement park') || name.contains('theme_park') || name.contains('playground') || name.contains('water park') || name.contains('family')) {
        return 'Kids & Family';
      }
      
      // Culture & History (Museums, Art Galleries, Historical sites, Monuments, Castles)
      if (id == 10027 || id == 10004 || id == 16026 || name.contains('museum') || name.contains('monument') || name.contains('art gallery') || name.contains('historic') || name.contains('castle') || name.contains('ruins') || name.contains('heritage') || name.contains('theatre') || name.contains('exhibition')) {
        return 'Culture & History';
      }
      
      // Summer & Beach (Beaches, Lakes, Waterfronts, Swimming pools)
      if (id == 16003 || id == 16028 || id == 16043 || id == 16049 || name.contains('beach') || name.contains('waterfront') || name.contains('lake') || name.contains('swimming pool') || name.contains('sea') || name.contains('ocean') || name.contains('park') || name.contains('garden')) {
        return 'Summer & Beach';
      }
    }
    
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

  Future<List<ExplorePlaceItem>> fetchHotelsAndLodgings(double lat, double lon, String cityName) async {
    const fields = 'fsq_id,name,location,categories,rating,description,photos';
    
    final uri = Uri.https(
      'api.foursquare.com',
      '/v3/places/search',
      {
        'll': '$lat,$lon',
        'categories': '19014', // Lodging/Hotel
        'radius': '15000',
        'limit': '15',
        'fields': fields,
      },
    );

    final authKey = _apiKey.startsWith('fsq3_') ? _apiKey : 'fsq3_$_apiKey';
    final response = await _client.get(
      uri,
      headers: {
        'Authorization': authKey,
        'accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FoursquareException('Failed to fetch hotels (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FoursquareException('Invalid response structure for hotels.');
    }

    final results = decoded['results'];
    if (results is! List) {
      return const [];
    }

    final List<ExplorePlaceItem> items = [];
    int index = 0;

    for (final p in results) {
      if (p is! Map<String, dynamic>) continue;
      final name = p['name']?.toString() ?? '';
      if (name.isEmpty) continue;

      final categories = p['categories'] as List? ?? [];
      final genre = 'Hotel';
      
      final location = p['location'] as Map<String, dynamic>? ?? {};
      final address = location['formatted_address']?.toString() ?? location['address']?.toString() ?? cityName;
      
      double rating = 4.0;
      final rawRating = p['rating'];
      if (rawRating is num) {
        rating = double.parse((rawRating / 2.0).toStringAsFixed(1));
      } else {
        rating = double.parse((4.0 + (name.hashCode.abs() % 11) * 0.1).toStringAsFixed(1));
      }

      String imageUrl = '';
      final photos = p['photos'];
      if (photos is List && photos.isNotEmpty) {
        final firstPhoto = photos.first;
        if (firstPhoto is Map<String, dynamic>) {
          final prefix = firstPhoto['prefix']?.toString() ?? '';
          final suffix = firstPhoto['suffix']?.toString() ?? '';
          if (prefix.isNotEmpty && suffix.isNotEmpty) {
            imageUrl = '${prefix}500x300$suffix';
          }
        }
      }
      if (imageUrl.isEmpty) {
        imageUrl = 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=500&q=80'; // default hotel
      }

      final description = p['description']?.toString() ?? 'A highly recommended stay in $cityName. Known as "$name", it offers premium lodging amenities and standard guest accommodations.';

      final double price = 80.0 + (name.hashCode.abs() % 17) * 10;

      items.add(ExplorePlaceItem(
        id: 'fsq-hotel-${p['fsq_id'] ?? index++}',
        name: name,
        genre: genre,
        imageUrl: imageUrl,
        description: description,
        rating: rating,
        estimatedDuration: '${price.toInt()} per night',
        estimatedCost: '\$${price.toInt()}',
        address: address,
        durationMinutes: price.toInt(),
      ));
    }

    return items;
  }

  Future<List<ExplorePlaceItem>> fetchCruisesAndBoats(double lat, double lon, String cityName) async {
    const fields = 'fsq_id,name,location,categories,rating,description,photos';
    
    final uri = Uri.https(
      'api.foursquare.com',
      '/v3/places/search',
      {
        'll': '$lat,$lon',
        'categories': '19021,19015', // Cruise ship, Pier/port
        'radius': '15000',
        'limit': '10',
        'fields': fields,
      },
    );

    final authKey = _apiKey.startsWith('fsq3_') ? _apiKey : 'fsq3_$_apiKey';
    final response = await _client.get(
      uri,
      headers: {
        'Authorization': authKey,
        'accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FoursquareException('Failed to fetch cruises (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FoursquareException('Invalid response structure for cruises.');
    }

    final results = decoded['results'];
    if (results is! List) {
      return const [];
    }

    final List<ExplorePlaceItem> items = [];
    int index = 0;

    for (final p in results) {
      if (p is! Map<String, dynamic>) continue;
      final name = p['name']?.toString() ?? '';
      if (name.isEmpty) continue;

      final categories = p['categories'] as List? ?? [];
      final genre = 'Cruise';
      
      final location = p['location'] as Map<String, dynamic>? ?? {};
      final address = location['formatted_address']?.toString() ?? location['address']?.toString() ?? cityName;
      
      double rating = 4.0;
      final rawRating = p['rating'];
      if (rawRating is num) {
        rating = double.parse((rawRating / 2.0).toStringAsFixed(1));
      } else {
        rating = double.parse((4.0 + (name.hashCode.abs() % 11) * 0.1).toStringAsFixed(1));
      }

      String imageUrl = '';
      final photos = p['photos'];
      if (photos is List && photos.isNotEmpty) {
        final firstPhoto = photos.first;
        if (firstPhoto is Map<String, dynamic>) {
          final prefix = firstPhoto['prefix']?.toString() ?? '';
          final suffix = firstPhoto['suffix']?.toString() ?? '';
          if (prefix.isNotEmpty && suffix.isNotEmpty) {
            imageUrl = '${prefix}500x300$suffix';
          }
        }
      }
      if (imageUrl.isEmpty) {
        imageUrl = 'https://images.unsplash.com/photo-1548574505-5e239809ee19?auto=format&fit=crop&w=500&q=80'; // default cruise ship
      }

      final description = p['description']?.toString() ?? 'A scenic maritime voyage departing from $cityName. Enjoy a premium $name experience with outstanding water views and amenities.';

      final double price = 50.0 + (name.hashCode.abs() % 13) * 15;

      items.add(ExplorePlaceItem(
        id: 'fsq-cruise-${p['fsq_id'] ?? index++}',
        name: name,
        genre: genre,
        imageUrl: imageUrl,
        description: description,
        rating: rating,
        estimatedDuration: '${price.toInt()} per passenger',
        estimatedCost: '\$${price.toInt()}',
        address: address,
        durationMinutes: price.toInt(),
      ));
    }

    return items;
  }
}
