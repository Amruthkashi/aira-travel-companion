import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/travel_models.dart';

class AiService {
  static String? _customBaseUrl;

  static String get baseUrl {
    if (_customBaseUrl != null) return _customBaseUrl!;
    try {
      final box = Hive.box('auth_box');
      final savedUrl = box.get('server_url');
      if (savedUrl != null && savedUrl.toString().isNotEmpty) {
        _customBaseUrl = savedUrl.toString();
        return _customBaseUrl!;
      }
    } catch (_) {}

    if (kDebugMode) {
      try {
        if (!kIsWeb && Platform.isAndroid) {
          return 'http://10.0.2.2:3005';
        }
      } catch (_) {}
      return 'http://localhost:3005';
    }

    if (kIsWeb) return 'https://aira-backend-m6vn.onrender.com';
    try {
      if (Platform.isAndroid) {
        return 'https://aira-backend-m6vn.onrender.com'; // Deployed Render Server
      }
      return 'https://aira-backend-m6vn.onrender.com'; // Deployed Render Server
    } catch (_) {
      return 'https://aira-backend-m6vn.onrender.com';
    }
  }

  static void updateBaseUrl(String newUrl) {
    _customBaseUrl = newUrl;
    try {
      final box = Hive.box('auth_box');
      box.put('server_url', newUrl);
    } catch (_) {}
    _dio = Dio(BaseOptions(
      baseUrl: newUrl,
      headers: {
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }
  
  static Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {
      'Content-Type': 'application/json',
    },
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Check connection to backend
  static Future<bool> checkConnection() async {
    try {
      final response = await _dio.get('/api/health');
      if (response.statusCode == 200) {
        return response.data['status'] == 'ok';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Get real-time personalized travel recommendations for the Home Screen Discovery section.
  static Future<List<Map<String, dynamic>>> getDiscoverPlaces(
    String category,
    Map<String, dynamic> profile,
  ) async {
    try {
      final response = await _dio.post('/api/discover', data: {
        'category': category,
        'userId': profile['email'],
        'profile': profile,
      });

      if (response.statusCode == 200) {
        final List<dynamic> decoded = response.data;
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return _getBackupPlaces(category);
    } catch (e) {
      debugPrint('Error getting discover places from backend: $e');
      return _getBackupPlaces(category);
    }
  }

  /// Send a message to Tria Concierge and receive a real-time smart response.
  static Future<String> chatWithTria(
    List<ChatMessage> history,
    Map<String, dynamic> profile,
  ) async {
    try {
      // Build messages payload
      final List<Map<String, String>> messagesJson = [];
      for (var msg in history) {
        messagesJson.add({
          'sender': msg.sender,
          'text': msg.text,
        });
      }

      final response = await _dio.post('/api/chat', data: {
        'messages': messagesJson,
        'profile': profile,
      });

      if (response.statusCode == 200) {
        return response.data['text'] ?? "I couldn't process that response.";
      }
      return "I'm having trouble connecting to my servers right now. Let's try again in a moment! 🗺️";
    } catch (e) {
      debugPrint('Error in Tria Chat backend call: $e');
      return "I'm having trouble connecting to my servers right now. Let's try again in a moment! 🗺️";
    }
  }

  /// Generate a custom itinerary based on chat history / query.
  static Future<List<ItineraryDay>> generateItinerary(
    String query,
    Map<String, dynamic> profile, {
    int? days,
  }) async {
    try {
      final response = await _dio.post('/api/itinerary', data: {
        'query': query,
        'userId': profile['email'],
        'profile': profile,
        'days': days,
      });

      if (response.statusCode == 200) {
        final List<dynamic> decoded = response.data;
        return decoded.map((dayJson) {
          final List<dynamic> actsJson = dayJson['activities'] ?? [];
          final activities = actsJson.map((act) => ActivityItem(
            time: act['time'] ?? '09:00 AM',
            activity: act['activity'] ?? 'Sightseeing',
            description: act['description'] ?? '',
            cost: act['cost'] ?? 'Free',
            locationName: act['locationName'] ?? '',
            suggestedAttire: act['suggestedAttire'] ?? 'Casual',
            transport: act['transport'] ?? '',
            ticketInfo: act['ticketInfo'] ?? '',
            placeDetails: act['placeDetails'] ?? '',
          )).toList();

          return ItineraryDay(
            day: dayJson['day'] ?? 1,
            theme: dayJson['theme'] ?? 'Exploring',
            activities: activities,
          );
        }).toList();
      }
      throw Exception("Backend return error");
    } catch (e) {
      debugPrint('Error generating itinerary from backend: $e');
      final destination = profile['city'] ?? 'Tokyo';
      final cleanDest = destination.toString().trim();
      final capitalized = cleanDest.isNotEmpty 
          ? cleanDest[0].toUpperCase() + cleanDest.substring(1)
          : 'Destination';
      
      final numDays = days ?? 2;
      final List<ItineraryDay> fallbackList = [];
      
      for (int d = 1; d <= numDays; d++) {
        fallbackList.add(ItineraryDay(
          day: d,
          theme: 'Culture & Local Flavors of $capitalized - Day $d',
          activities: [
            ActivityItem(
              time: '08:30 AM',
              activity: 'Healthy Local Breakfast',
              description: 'Start your morning with freshly brewed artisanal coffee and a selection of freshly baked local pastries or a traditional breakfast set at a highly-rated neighborhood cafe.',
              cost: '\$8',
              locationName: '$capitalized Morning Bistro',
              suggestedAttire: 'Casual day wear',
              transport: 'Short 5-minute walk from hotel',
              ticketInfo: 'No reservation required',
              placeDetails: 'A cozy local spot loved by residents for its warm hospitality and freshly ground coffee beans.',
            ),
            ActivityItem(
              time: '10:00 AM',
              activity: 'Iconic Central Landmark Tour',
              description: 'Stroll around the central historic plazas, view majestic architectural monuments, and capture beautiful morning photos of the city\'s most defining civic landmarks.',
              cost: 'Free',
              locationName: '$capitalized Heritage Plaza',
              suggestedAttire: 'Comfortable walking shoes & light layers',
              transport: 'Board local commuter rail to Central Station, walk 3 mins',
              ticketInfo: 'Open public area access',
              placeDetails: 'Established in the early historical era, this prominent plaza represents the rich cultural heart of the city.',
            ),
            ActivityItem(
              time: '01:00 PM',
              activity: 'Gastronomy & Local Food Tour',
              description: 'Explore a vibrant open-air market filled with diverse food stalls. Sample unique regional street food delicacies, local specialties, and freshly prepared bites.',
              cost: '\$25',
              locationName: '$capitalized City Market Hall',
              suggestedAttire: 'Casual streetwear',
              transport: 'Short taxi ride or walk (10 mins)',
              ticketInfo: 'Cash highly recommended at individual stalls',
              placeDetails: 'A bustling commercial market featuring family-owned food stalls passing down authentic recipes for generations.',
            ),
            ActivityItem(
              time: '03:30 PM',
              activity: 'Art & History Museum Visit',
              description: 'Immerse yourself in history and artistic expression. View collections of historical artifacts, fine art, and contemporary exhibitions depicting local history.',
              cost: '\$15',
              locationName: '$capitalized Museum of Art & History',
              suggestedAttire: 'Smart casual / Modest for indoor exhibits',
              transport: 'Walk 5 minutes north from City Market Hall',
              ticketInfo: 'Purchase entry ticket at the reception desk',
              placeDetails: 'A world-class civic institution housing important national treasures and temporary modern art galleries.',
            ),
            ActivityItem(
              time: '06:30 PM',
              activity: 'Sunset Scenic Viewpoint',
              description: 'Climb to an elevated observation deck or scenic hilltop park just in time to watch the setting sun paint the city skyline. Perfect for panoramic photography.',
              cost: '\$18',
              locationName: '$capitalized Skyline Observation Tower',
              suggestedAttire: 'Light jacket (it gets breezy at high elevations)',
              transport: 'Take local subway Line 4 to Heights Station, follow exit signs',
              ticketInfo: 'Online pre-booked ticket voucher recommended for sunset slots',
              placeDetails: 'Standing tall over the cityscape, this observation deck offers breathtaking 360-degree views of the horizon.',
            ),
            ActivityItem(
              time: '08:00 PM',
              activity: 'Signature Local Dinner',
              description: 'Dine in a highly-rated traditional restaurant situated in an atmospheric neighborhood. Enjoy a multi-course dinner of classic regional recipes and local specialties.',
              cost: '\$35',
              locationName: 'Traditional Dining District',
              suggestedAttire: 'Smart casual',
              transport: 'Short taxi ride or walk',
              ticketInfo: 'Reservation confirmed under travel profile',
              placeDetails: 'A highly praised dining spot famous for its authentic cooking techniques and welcoming, cozy atmosphere.',
            ),
          ],
        ));
      }
      return fallbackList;
    }
  }

  /// Get saved itinerary from backend.
  static Future<List<ItineraryDay>> getSavedItinerary(String userId) async {
    try {
      final response = await _dio.get('/api/itinerary/$userId');
      if (response.statusCode == 200) {
        final List<dynamic> decoded = response.data;
        return decoded.map((dayJson) {
          final List<dynamic> actsJson = dayJson['activities'] ?? [];
          final activities = actsJson.map((act) => ActivityItem(
            time: act['time'] ?? '09:00 AM',
            activity: act['activity'] ?? 'Sightseeing',
            description: act['description'] ?? '',
            cost: act['cost'] ?? 'Free',
            locationName: act['locationName'] ?? '',
            suggestedAttire: act['suggestedAttire'] ?? 'Casual',
            transport: act['transport'] ?? '',
            ticketInfo: act['ticketInfo'] ?? '',
            placeDetails: act['placeDetails'] ?? '',
            checked: act['checked'] ?? false,
          )).toList();

          return ItineraryDay(
            day: dayJson['day'] ?? 1,
            theme: dayJson['theme'] ?? 'Exploring',
            activities: activities,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting saved itinerary from backend: $e');
      return [];
    }
  }

  /// Save client-side compiled itinerary to the backend database.
  static Future<bool> saveItinerary(String userId, List<ItineraryDay> itinerary) async {
    try {
      final List<Map<String, dynamic>> itineraryJson = itinerary.map((day) => {
        'day': day.day,
        'theme': day.theme,
        'activities': day.activities.map((act) => {
          'time': act.time,
          'activity': act.activity,
          'description': act.description,
          'locationName': act.locationName,
          'cost': act.cost,
          'suggestedAttire': act.suggestedAttire,
          'transport': act.transport,
          'ticketInfo': act.ticketInfo,
          'placeDetails': act.placeDetails,
          'checked': act.checked,
        }).toList(),
      }).toList();

      final response = await _dio.post('/api/itinerary/save', data: {
        'userId': userId,
        'itinerary': itineraryJson,
      });
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error saving itinerary to backend: $e');
      return false;
    }
  }

  /// Generate a custom packing checklist.
  static Future<List<String>> generatePackingList(
    Map<String, dynamic> profile,
  ) async {
    try {
      final response = await _dio.post('/api/packing-list', data: {
        'userId': profile['email'],
        'profile': profile,
      });

      if (response.statusCode == 200) {
        final List<dynamic> decoded = response.data;
        return decoded.map((e) => e.toString()).toList();
      }
      throw Exception("Backend return error");
    } catch (e) {
      debugPrint('Error generating packing list from backend: $e');
      return [
        'Passport & travel visas',
        'Local currency cash & credit cards',
        'Mobile phone charger & universal travel plug adapter',
        'Comfortable walking shoes',
        'Weather-appropriate clothing layers'
      ];
    }
  }

  static String _extractDioError(dynamic e) {
    if (e is DioException) {
      if (e.response != null && e.response!.data != null) {
        final data = e.response!.data;
        if (data is Map && data.containsKey('error')) {
          return data['error'].toString();
        }
      }
      return e.message ?? 'Server connection error.';
    }
    return e.toString();
  }

  /// Backend User Login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['user']);
      }
      throw Exception(response.data['error'] ?? 'Invalid login credentials.');
    } catch (e) {
      throw Exception(_extractDioError(e));
    }
  }

  /// Backend User Sign Up
  static Future<Map<String, dynamic>> signup(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post('/api/auth/signup', data: userData);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['user']);
      }
      throw Exception(response.data['error'] ?? 'Sign up failed.');
    } catch (e) {
      throw Exception(_extractDioError(e));
    }
  }

  /// Backend Update Profile
  static Future<Map<String, dynamic>> updateProfile(String userId, Map<String, dynamic> profile) async {
    try {
      final response = await _dio.post('/api/profile/update', data: {
        'userId': userId,
        'profile': profile,
      });
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['user']);
      }
      throw Exception(response.data['error'] ?? 'Failed to update profile.');
    } catch (e) {
      throw Exception(_extractDioError(e));
    }
  }

  static List<Map<String, dynamic>> _getBackupPlaces(String category) {
    if (category.contains('Solo')) {
      return [
        {
          "name": "Tokyo Crossing District",
          "country": "Japan",
          "countryCode": "JPN",
          "rating": 4.9,
          "image": "https://images.unsplash.com/photo-1540959733332-eab4deceeaf7?auto=format&fit=crop&w=800&q=80",
          "desc": "Bustling neon streets, capsule hotels, retro arcades, and solo-friendly sushi counters.",
          "tags": ["Neon", "Tech", "Solo-Friendly"]
        },
        {
          "name": "Reykjavik",
          "country": "Iceland",
          "countryCode": "ISL",
          "rating": 4.8,
          "image": "https://images.unsplash.com/photo-1504829857797-ddff28127792?auto=format&fit=crop&w=800&q=80",
          "desc": "The safest country for solo explorers, featuring hot springs, waterfalls, and northern lights.",
          "tags": ["Nature", "Safety", "Adventure"]
        }
      ];
    } else {
      return [
        {
          "name": "Oia Santorini",
          "country": "Greece",
          "countryCode": "GRC",
          "rating": 4.9,
          "image": "https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?auto=format&fit=crop&w=800&q=80",
          "desc": "Iconic whitewashed houses with blue domes perched high on volcanic cliffs overlooking the sunset.",
          "tags": ["Romantic", "Sunset", "Luxury"]
        }
      ];
    }
  }

  static Future<Map<String, dynamic>> translateText({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    try {
      final response = await _dio.post('/api/translate', data: {
        'text': text,
        'sourceLang': sourceLang,
        'targetLang': targetLang,
      });
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      throw Exception('Failed to connect to translation API.');
    } catch (e) {
      throw Exception(_extractDioError(e));
    }
  }

  // ==========================================
  // TRAVEL SQUADS API Methods
  // ==========================================

  static Future<Map<String, dynamic>> createSquad(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/squads/create', data: data);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['squad']);
      }
      throw Exception(response.data['error'] ?? 'Failed to create squad.');
    } catch (e) {
      throw Exception(_extractDioError(e));
    }
  }

  static Future<List<Map<String, dynamic>>> getUserSquads(String userId) async {
    try {
      final response = await _dio.get('/api/squads/user/$userId');
      if (response.statusCode == 200) {
        return (response.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching squads: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getSquadDetails(String squadId) async {
    try {
      final response = await _dio.get('/api/squads/$squadId');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception(_extractDioError(e));
    }
  }

  static Future<Map<String, dynamic>> joinSquadByCode(String inviteCode, String userId, String fullName) async {
    try {
      final response = await _dio.post('/api/squads/join', data: {
        'inviteCode': inviteCode,
        'userId': userId,
        'fullName': fullName,
      });
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['squad']);
      }
      throw Exception(response.data['error'] ?? 'Failed to join squad.');
    } catch (e) {
      throw Exception(_extractDioError(e));
    }
  }

  static Future<Map<String, dynamic>?> sendSquadMessage(String squadId, Map<String, dynamic> msg) async {
    try {
      final response = await _dio.post('/api/squads/$squadId/message', data: msg);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['message']);
      }
      return null;
    } catch (e) {
      debugPrint('Error sending squad message: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getSquadMessages(String squadId, {String? since}) async {
    try {
      String url = '/api/squads/$squadId/messages';
      if (since != null) url += '?since=$since';
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        return (response.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> addSquadExpense(String squadId, Map<String, dynamic> expense) async {
    try {
      final response = await _dio.post('/api/squads/$squadId/expense', data: expense);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['expense']);
      }
      return null;
    } catch (e) {
      throw Exception(_extractDioError(e));
    }
  }

  static Future<Map<String, dynamic>?> createSquadPoll(String squadId, Map<String, dynamic> poll) async {
    try {
      final response = await _dio.post('/api/squads/$squadId/poll', data: poll);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['poll']);
      }
      return null;
    } catch (e) {
      throw Exception(_extractDioError(e));
    }
  }

  static Future<Map<String, dynamic>?> voteOnPoll(String squadId, String pollId, int optionIndex, String userId) async {
    try {
      final response = await _dio.post('/api/squads/$squadId/poll/$pollId/vote', data: {
        'optionIndex': optionIndex,
        'userId': userId,
      });
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['poll']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getSquadAiSuggestions(String squadId, {String? query}) async {
    try {
      final response = await _dio.post('/api/squads/$squadId/ai-suggest', data: {
        'query': query ?? '',
      });
      if (response.statusCode == 200) {
        return (response.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting squad AI suggestions: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> addSquadBooking(String squadId, Map<String, dynamic> booking) async {
    try {
      final response = await _dio.post('/api/squads/$squadId/booking', data: booking);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['booking']);
      }
      return null;
    } catch (e) {
      throw Exception(_extractDioError(e));
    }
  }
}
