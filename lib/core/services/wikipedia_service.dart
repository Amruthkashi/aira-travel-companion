import 'dart:convert';
import 'package:http/http.dart' as http;

class WikipediaSummary {
  final String title;
  final String description;
  final String? thumbnailUrl;

  WikipediaSummary({
    required this.title,
    required this.description,
    this.thumbnailUrl,
  });

  factory WikipediaSummary.fromJson(Map<String, dynamic> json) {
    String? thumb;
    final thumbnail = json['thumbnail'];
    if (thumbnail is Map<String, dynamic>) {
      thumb = thumbnail['source']?.toString();
    }

    return WikipediaSummary(
      title: json['title']?.toString() ?? '',
      description: json['extract']?.toString() ?? json['description']?.toString() ?? '',
      thumbnailUrl: thumb,
    );
  }
}

class WikipediaService {
  final http.Client _client;

  WikipediaService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches the Wikipedia page summary for the given place name.
  /// Uses a fallback search strategy to find the best match if a direct lookup fails.
  /// Returns `null` if the page does not exist or if the request fails.
  Future<WikipediaSummary?> fetchPageSummary(String placeName, {String? cityName}) async {
    try {
      String cleanedName = placeName.split('(').first.split(',').first.trim();
      if (cleanedName.isEmpty) return null;

      // Helper to query page summary by title
      Future<WikipediaSummary?> getSummaryByTitle(String title) async {
        final uri = Uri.parse('https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(title)}');
        final response = await _client.get(
          uri,
          headers: {
            'accept': 'application/json; charset=utf-8',
            'User-Agent': 'AiraTravelCompanion/1.0 (https://github.com/aira-travel; support@airatravel.com)',
          },
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (decoded is Map<String, dynamic>) {
            return WikipediaSummary.fromJson(decoded);
          }
        }
        return null;
      }

      // Helper to search Wikipedia search API
      Future<String?> searchArticle(String query) async {
        final searchUri = Uri.https('en.wikipedia.org', '/w/api.php', {
          'action': 'query',
          'list': 'search',
          'srsearch': query,
          'utf8': '1',
          'format': 'json',
          'origin': '*',
          'limit': '1',
        });
        final response = await _client.get(searchUri).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (decoded is Map<String, dynamic>) {
            final queryRes = decoded['query'];
            if (queryRes is Map<String, dynamic>) {
              final searchList = queryRes['search'];
              if (searchList is List && searchList.isNotEmpty) {
                final firstResult = searchList.first;
                if (firstResult is Map<String, dynamic>) {
                  return firstResult['title']?.toString();
                }
              }
            }
          }
        }
        return null;
      }

      // 1. Try fetching directly
      var summary = await getSummaryByTitle(cleanedName);
      if (summary != null && summary.description.isNotEmpty) {
        return summary;
      }

      // 2. Try searching by cleaned name
      final searchTitle = await searchArticle(cleanedName);
      if (searchTitle != null) {
        summary = await getSummaryByTitle(searchTitle);
        if (summary != null && summary.description.isNotEmpty) {
          return summary;
        }
      }

      // 3. Try searching with city name context (e.g. "Lalbagh Bangalore")
      if (cityName != null && cityName.isNotEmpty) {
        final searchTitleWithCity = await searchArticle('$cleanedName $cityName');
        if (searchTitleWithCity != null) {
          summary = await getSummaryByTitle(searchTitleWithCity);
          if (summary != null && summary.description.isNotEmpty) {
            return summary;
          }
        }
      }

      return null;
    } catch (e) {
      print('Error fetching Wikipedia summary for $placeName: $e');
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
