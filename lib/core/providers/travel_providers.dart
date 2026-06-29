import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';
import '../models/travel_models.dart';
import '../services/ai_service.dart';
import '../utils/timeline_validator.dart';


// 1. User Profile State Notifier
class UserProfileState {
  final Map<String, dynamic> profile;
  final double dnaFoodie;
  final double dnaHeritage;
  final double dnaTech;
  final double dnaAdventure;
  final int xpPoints;
  final bool nfcKeyScanning;
  final bool nfcKeyUnlocked;
  final bool isWalletAdded;

  UserProfileState({
    required this.profile,
    this.dnaFoodie = 92.0,
    this.dnaHeritage = 85.0,
    this.dnaTech = 78.0,
    this.dnaAdventure = 40.0,
    this.xpPoints = 2450,
    this.nfcKeyScanning = false,
    this.nfcKeyUnlocked = false,
    this.isWalletAdded = false,
  });

  String get travelArchetype {
    if (dnaFoodie > 80 && dnaTech > 70) return "Gourmet Netrunner";
    if (dnaHeritage > 80 && dnaFoodie > 70) return "Cultural Shogun";
    if (dnaAdventure > 70 && dnaTech > 60) return "Digital Nomad Explorer";
    if (dnaHeritage > 70 && dnaAdventure > 50) return "Zen Backpacker";
    return "Balanced Voyager";
  }

  UserProfileState copyWith({
    Map<String, dynamic>? profile,
    double? dnaFoodie,
    double? dnaHeritage,
    double? dnaTech,
    double? dnaAdventure,
    int? xpPoints,
    bool? nfcKeyScanning,
    bool? nfcKeyUnlocked,
    bool? isWalletAdded,
  }) {
    return UserProfileState(
      profile: profile ?? this.profile,
      dnaFoodie: dnaFoodie ?? this.dnaFoodie,
      dnaHeritage: dnaHeritage ?? this.dnaHeritage,
      dnaTech: dnaTech ?? this.dnaTech,
      dnaAdventure: dnaAdventure ?? this.dnaAdventure,
      xpPoints: xpPoints ?? this.xpPoints,
      nfcKeyScanning: nfcKeyScanning ?? this.nfcKeyScanning,
      nfcKeyUnlocked: nfcKeyUnlocked ?? this.nfcKeyUnlocked,
      isWalletAdded: isWalletAdded ?? this.isWalletAdded,
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final Ref ref;
  UserProfileNotifier(this.ref) : super(UserProfileState(
    profile: const {}
  ));

  void updateUserProfile(Map<String, dynamic> updated) {
    final newProfile = Map<String, dynamic>.from(state.profile)..addAll(updated);
    state = state.copyWith(profile: newProfile);
    
    final email = state.profile['email'];
    if (email != null && email.toString().isNotEmpty) {
      AiService.updateProfile(email, updated).then((serverProfile) {
        state = state.copyWith(profile: serverProfile);
      }).catchError((e) {
        print('Error syncing profile update to server: $e');
      });
    }
  }

  void setUserVibes(List<String> vibes) {
    final newProfile = Map<String, dynamic>.from(state.profile)..['selectedPreferences'] = vibes;
    state = state.copyWith(profile: newProfile);

    final email = state.profile['email'];
    if (email != null && email.toString().isNotEmpty) {
      AiService.updateProfile(email, {'selectedPreferences': vibes}).then((serverProfile) {
        state = state.copyWith(profile: serverProfile);
      }).catchError((e) {
        print('Error syncing vibes update to server: $e');
      });
    }
  }

  void restoreSession(Map<String, dynamic> profile) {
    state = state.copyWith(
      profile: profile,
      dnaFoodie: profile['dnaFoodie'] != null ? (profile['dnaFoodie'] as num).toDouble() : state.dnaFoodie,
      dnaHeritage: profile['dnaHeritage'] != null ? (profile['dnaHeritage'] as num).toDouble() : state.dnaHeritage,
      dnaTech: profile['dnaTech'] != null ? (profile['dnaTech'] as num).toDouble() : state.dnaTech,
      dnaAdventure: profile['dnaAdventure'] != null ? (profile['dnaAdventure'] as num).toDouble() : state.dnaAdventure,
    );
  }

  Future<void> fetchItineraryAndChecklist(String email) async {
    try {
      final savedItinerary = await AiService.getSavedItinerary(email);
      ref.read(itineraryProvider.notifier).state = savedItinerary;

      final user = state.profile;
      if (user['checklist'] != null) {
        final List<dynamic> chkList = user['checklist'];
        ref.read(checklistProvider.notifier).state = chkList.map((item) => ChecklistItem(
          id: item['id'] ?? 'chk-${DateTime.now().millisecondsSinceEpoch}',
          text: item['text'] ?? '',
          checked: item['checked'] ?? false,
        )).toList();
      }
    } catch (e) {
      print('Background session sync failed: $e');
    }
  }

  Future<void> logout() async {
    state = UserProfileState(profile: const {});
    final authBox = Hive.box('auth_box');
    await authBox.clear();
    ref.read(checklistProvider.notifier).state = [];
    ref.read(itineraryProvider.notifier).state = [];
  }

  Future<void> login(String email, String password) async {
    final user = await AiService.login(email, password);
    state = state.copyWith(
      profile: user,
      dnaFoodie: user['dnaFoodie'] != null ? (user['dnaFoodie'] as num).toDouble() : state.dnaFoodie,
      dnaHeritage: user['dnaHeritage'] != null ? (user['dnaHeritage'] as num).toDouble() : state.dnaHeritage,
      dnaTech: user['dnaTech'] != null ? (user['dnaTech'] as num).toDouble() : state.dnaTech,
      dnaAdventure: user['dnaAdventure'] != null ? (user['dnaAdventure'] as num).toDouble() : state.dnaAdventure,
    );

    // Persist login details to Hive Box
    final authBox = Hive.box('auth_box');
    await authBox.put('email', email);
    await authBox.put('password', password);
    await authBox.put('profile', state.profile);

    // Load checklist
    if (user['checklist'] != null) {
      final List<dynamic> chkList = user['checklist'];
      ref.read(checklistProvider.notifier).state = chkList.map((item) => ChecklistItem(
        id: item['id'] ?? 'chk-${DateTime.now().millisecondsSinceEpoch}',
        text: item['text'] ?? '',
        checked: item['checked'] ?? false,
      )).toList();
    } else {
      ref.read(checklistProvider.notifier).state = [];
    }

    // Load itinerary
    final savedItinerary = await AiService.getSavedItinerary(user['email'] ?? email);
    ref.read(itineraryProvider.notifier).state = savedItinerary;
  }

  Future<void> signup(Map<String, dynamic> userData) async {
    final user = await AiService.signup(userData);
    state = state.copyWith(
      profile: user,
      dnaFoodie: user['dnaFoodie'] != null ? (user['dnaFoodie'] as num).toDouble() : state.dnaFoodie,
      dnaHeritage: user['dnaHeritage'] != null ? (user['dnaHeritage'] as num).toDouble() : state.dnaHeritage,
      dnaTech: user['dnaTech'] != null ? (user['dnaTech'] as num).toDouble() : state.dnaTech,
      dnaAdventure: user['dnaAdventure'] != null ? (user['dnaAdventure'] as num).toDouble() : state.dnaAdventure,
    );

    // Persist signup credentials to Hive Box
    final authBox = Hive.box('auth_box');
    await authBox.put('email', user['email']);
    await authBox.put('password', userData['password']);
    await authBox.put('profile', state.profile);

    ref.read(checklistProvider.notifier).state = [];
    ref.read(itineraryProvider.notifier).state = [];
  }

  void addXP(int points) {
    state = state.copyWith(xpPoints: state.xpPoints + points);
  }

  void updateDNA(String key, double val) {
    state = state.copyWith(
      dnaFoodie: key == 'foodie' ? val : state.dnaFoodie,
      dnaHeritage: key == 'heritage' ? val : state.dnaHeritage,
      dnaTech: key == 'tech' ? val : state.dnaTech,
      dnaAdventure: key == 'adventure' ? val : state.dnaAdventure,
    );

    // Save to Hive Profile
    final authBox = Hive.box('auth_box');
    final Map<String, dynamic> updatedProfile = Map<String, dynamic>.from(state.profile)
      ..['dnaFoodie'] = state.dnaFoodie
      ..['dnaHeritage'] = state.dnaHeritage
      ..['dnaTech'] = state.dnaTech
      ..['dnaAdventure'] = state.dnaAdventure
      ..['travelArchetype'] = state.travelArchetype;
    
    state = state.copyWith(profile: updatedProfile);
    authBox.put('profile', updatedProfile);

    // Sync to backend!
    final email = state.profile['email'];
    if (email != null && email.toString().isNotEmpty) {
      AiService.updateProfile(email.toString(), {
        'dnaFoodie': state.dnaFoodie,
        'dnaHeritage': state.dnaHeritage,
        'dnaTech': state.dnaTech,
        'dnaAdventure': state.dnaAdventure,
        'travelArchetype': state.travelArchetype,
      }).then((serverProfile) {
        // Updated successfully
      }).catchError((e) {
        print('Error syncing DNA update to server: $e');
      });
    }
  }

  void triggerKeyUnlock() {
    state = state.copyWith(nfcKeyScanning: true, nfcKeyUnlocked: false);
  }

  void setKeyUnlocked(bool val) {
    state = state.copyWith(nfcKeyScanning: false, nfcKeyUnlocked: val);
  }

  void toggleWalletAdded() {
    state = state.copyWith(isWalletAdded: !state.isWalletAdded);
  }
}

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
  return UserProfileNotifier(ref);
});

// 2. Suica State Notifier
class SuicaNotifier extends StateNotifier<SuicaState> {
  final Ref ref;
  SuicaNotifier(this.ref) : super(SuicaState(balance: 2500.0, status: 'idle'));

  void topUpSuica(double amt) {
    state = state.copyWith(balance: state.balance + amt);
    
    // Log as a commute expense (converted to USD using 155 rate)
    ref.read(expensesProvider.notifier).addExpense(TravelExpense(
      id: 'suica-topup-${DateTime.now().millisecondsSinceEpoch}',
      category: 'Commute',
      amount: amt / 155.0,
      label: 'Prepaid Card Top-Up (¥${amt.toInt()})',
      date: '2026-06-04',
    ));
  }

  void scanSuicaGate() {
    if (state.balance >= 200) {
      state = state.copyWith(balance: state.balance - 200);
      ref.read(expensesProvider.notifier).addExpense(TravelExpense(
        id: 'suica-scan-${DateTime.now().millisecondsSinceEpoch}',
        category: 'Commute',
        amount: 200 / 155.0,
        label: 'Metro Gate Scan - Crossing District Station (¥200)',
        date: '2026-06-04',
      ));
    }
  }
}

final suicaProvider = StateNotifierProvider<SuicaNotifier, SuicaState>((ref) {
  return SuicaNotifier(ref);
});

// 3. Expenses State Notifier
class ExpensesNotifier extends StateNotifier<List<TravelExpense>> {
  ExpensesNotifier() : super([
    TravelExpense(
      id: '1',
      category: 'Local Dine-Out',
      amount: 190.00,
      label: 'Seafood Market Street Food & Crossing District traditional tavern Crawl',
      date: '2026-06-02',
    ),
    TravelExpense(
      id: '2',
      category: 'Metros & Taxis',
      amount: 50.00,
      label: 'Prepaid Smart Transit Card Top-Up',
      date: '2026-06-02',
    ),
    TravelExpense(
      id: '3',
      category: 'Sightseeing & Shows',
      amount: 1725.00,
      label: 'VIP Helicopter Skyline Tour & Anime Event Tickets',
      date: '2026-06-03',
    ),
    TravelExpense(
      id: '4',
      category: 'Souvenirs & Anime',
      amount: 50.00,
      label: 'Retro Collectors Mall Retro Figurines & Manga',
      date: '2026-06-03',
    ),
  ]);

  void addExpense(TravelExpense exp) {
    state = [...state, exp];
  }

  void removeExpense(String id) {
    state = state.where((e) => e.id != id).toList();
  }
}

final expensesProvider = StateNotifierProvider<ExpensesNotifier, List<TravelExpense>>((ref) {
  return ExpensesNotifier();
});

// 4. Itinerary State Notifier
class ItineraryNotifier extends StateNotifier<List<ItineraryDay>> {
  ItineraryNotifier() : super([]);

  void setItinerary(List<ItineraryDay> itinerary) {
    state = itinerary;
  }

  void addActivity(int dayIndex, ActivityItem item) {
    if (dayIndex >= 0 && dayIndex < state.length) {
      final updatedDays = state.map((day) {
        if (day.day == dayIndex + 1) {
          return day.copyWith(
            activities: [...day.activities, item],
          );
        }
        return day;
      }).toList();
      state = updatedDays;
    }
  }

  void updateActivity(int dayIndex, int activityIndex, {
    required String activity,
    required String time,
    required String description,
    required String cost,
    required String locationName,
    required String suggestedAttire,
    String transport = "",
    String ticketInfo = "",
    String placeDetails = "",
  }) {
    if (dayIndex >= 0 && dayIndex < state.length) {
      final updatedDays = state.map((day) {
        if (day.day == dayIndex + 1) {
          final updatedActivities = List<ActivityItem>.from(day.activities);
          if (activityIndex >= 0 && activityIndex < updatedActivities.length) {
            updatedActivities[activityIndex] = updatedActivities[activityIndex].copyWith(
              time: time,
              activity: activity,
              description: description,
              cost: cost,
              locationName: locationName,
              suggestedAttire: suggestedAttire,
              transport: transport,
              ticketInfo: ticketInfo,
              placeDetails: placeDetails,
            );
          }
          return day.copyWith(
            activities: updatedActivities,
          );
        }
        return day;
      }).toList();
      state = updatedDays;
    }
  }

  void toggleActivityCheck(int dayIndex, int activityIndex) {
    if (dayIndex >= 0 && dayIndex < state.length) {
      final updatedDays = state.map((day) {
        if (day.day == dayIndex + 1) {
          final updatedActivities = List<ActivityItem>.from(day.activities);
          if (activityIndex >= 0 && activityIndex < updatedActivities.length) {
            updatedActivities[activityIndex] = updatedActivities[activityIndex].copyWith(
              checked: !updatedActivities[activityIndex].checked,
            );
          }
          return day.copyWith(
            activities: updatedActivities,
          );
        }
        return day;
      }).toList();
      state = updatedDays;
    }
  }

  void deleteActivity(int dayIndex, int activityIndex) {
    if (dayIndex >= 0 && dayIndex < state.length) {
      final updatedDays = state.map((day) {
        if (day.day == dayIndex + 1) {
          final updatedActivities = List<ActivityItem>.from(day.activities);
          if (activityIndex >= 0 && activityIndex < updatedActivities.length) {
            updatedActivities.removeAt(activityIndex);
          }
          return day.copyWith(
            activities: updatedActivities,
          );
        }
        return day;
      }).toList();
      state = updatedDays;
    }
  }

  void reorderActivity(int dayIndex, int oldIndex, int newIndex) {
    if (dayIndex >= 0 && dayIndex < state.length) {
      final updatedDays = state.map((day) {
        if (day.day == dayIndex + 1) {
          final updatedActivities = List<ActivityItem>.from(day.activities);
          if (oldIndex >= 0 && oldIndex < updatedActivities.length &&
              newIndex >= 0 && newIndex < updatedActivities.length) {
            final item = updatedActivities.removeAt(oldIndex);
            updatedActivities.insert(newIndex, item);
          }
          return day.copyWith(
            activities: updatedActivities,
          );
        }
        return day;
      }).toList();
      state = updatedDays;
    }
  }

  Future<void> swapActivityWithAi(int dayIndex, int activityIndex) async {
    if (dayIndex < 0 || dayIndex >= state.length) return;
    final day = state[dayIndex];
    if (activityIndex < 0 || activityIndex >= day.activities.length) return;

    final oldAct = day.activities[activityIndex];
    
    final newAct = oldAct.copyWith(
      activity: "AI SUGGESTED: ${oldAct.activity} (Optimized)",
      description: "${oldAct.description}\n\n[AI Optimization]: Recommended alternative route via local express to save 15 mins.",
      ticketInfo: "Digital Voucher Issued",
    );

    final updatedActivities = List<ActivityItem>.from(day.activities);
    updatedActivities[activityIndex] = newAct;

    state = state.map((d) {
      if (d.day == dayIndex + 1) {
        return d.copyWith(activities: updatedActivities);
      }
      return d;
    }).toList();
  }

  void applyAiReroute(int dayIndex, List<ActivityItem> newActivities, String newTheme) {
    if (dayIndex >= 0 && dayIndex < state.length) {
      state = state.map((day) {
        if (day.day == dayIndex + 1) {
          return day.copyWith(
            theme: newTheme,
            activities: newActivities,
          );
        }
        return day;
      }).toList();
    }
  }

  void updateNotes(int dayIndex, String newNotes) {
    if (dayIndex >= 0 && dayIndex < state.length) {
      state = state.map((day) {
        if (day.day == dayIndex + 1) {
          return day.copyWith(notes: newNotes);
        }
        return day;
      }).toList();
    }
  }

  Future<void> generateAiItinerary(String query, Map<String, dynamic> profile) async {
    int? days;
    final upcoming = profile['upcomingTrip'];
    if (upcoming != null && upcoming is Map) {
      final startStr = upcoming['startDate'];
      final endStr = upcoming['endDate'];
      if (startStr != null && endStr != null) {
        try {
          final start = DateTime.parse(startStr.toString());
          final end = DateTime.parse(endStr.toString());
          days = end.difference(start).inDays + 1;
          if (days <= 0) days = 1;
        } catch (e) {
          print('Error parsing upcoming trip dates: $e');
        }
      }
    }

    final itinerary = await AiService.generateItinerary(query, profile, days: days);
    
    // Save to the database for persistence
    final email = profile['email'];
    if (email != null && email.toString().isNotEmpty) {
      await AiService.saveItinerary(email.toString(), itinerary);
    }
    
    state = itinerary;
  }
}

final itineraryProvider = StateNotifierProvider<ItineraryNotifier, List<ItineraryDay>>((ref) {
  return ItineraryNotifier();
});

// 5. Checklist State Notifier
class ChecklistNotifier extends StateNotifier<List<ChecklistItem>> {
  final Ref ref;
  ChecklistNotifier(this.ref) : super([]);

  void toggleChecklistItem(String id) {
    state = state.map((item) {
      if (item.id == id) {
        return ChecklistItem(id: item.id, text: item.text, checked: !item.checked);
      }
      return item;
    }).toList();
    _syncChecklist();
  }

  void addChecklistItem(String text) {
    state = [...state, ChecklistItem(id: 'chk-${DateTime.now().millisecondsSinceEpoch}', text: text)];
    _syncChecklist();
  }

  void generateAIChecklist(List<String> items) {
    final List<ChecklistItem> newItems = items.map((str) => ChecklistItem(
      id: 'chk-${DateTime.now().millisecondsSinceEpoch}-${str.hashCode}',
      text: str,
    )).toList();
    state = [...state, ...newItems];
    _syncChecklist();
  }

  Future<void> generateRealAiChecklist(Map<String, dynamic> profile) async {
    final items = await AiService.generatePackingList(profile);
    generateAIChecklist(items);
  }

  void _syncChecklist() {
    final userProfile = ref.read(userProfileProvider);
    final email = userProfile.profile['email'];
    if (email != null && email.toString().isNotEmpty) {
      final checklistData = state.map((item) => {
        'id': item.id,
        'text': item.text,
        'checked': item.checked,
      }).toList();
      AiService.updateProfile(email, {'checklist': checklistData}).then((serverProfile) {
        ref.read(userProfileProvider.notifier).state = ref.read(userProfileProvider).copyWith(profile: serverProfile);
      }).catchError((e) {
        print('Error syncing checklist to server: $e');
      });
    }
  }
}

final checklistProvider = StateNotifierProvider<ChecklistNotifier, List<ChecklistItem>>((ref) {
  return ChecklistNotifier(ref);
});

// 6. Chat Messages State Notifier
class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  ChatMessagesNotifier() : super([
    ChatMessage(
      id: 'init',
      sender: 'assistant',
      text: 'Hello! 🗺️ I am Aira, your private AI Concierge. Tell me your travel goals so we can construct your budget specs.',
      timestamp: '12:00 PM',
    ),
  ]);

  void sendChatMessage(String text, String sender) {
    final tStr = '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';
    state = [...state, ChatMessage(
      id: 'chat-${DateTime.now().millisecondsSinceEpoch}',
      sender: sender,
      text: text,
      timestamp: tStr,
    )];
  }

  Future<void> sendChatMessageWithAiReply(String text, Map<String, dynamic> profile) async {
    // Call Gemini AI
    final reply = await AiService.chatWithAira(state, profile);
    
    sendChatMessage(reply, 'assistant');
  }
}

final chatMessagesProvider = StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>((ref) {
  return ChatMessagesNotifier();
});

// 7. Audio Guide State Notifier
class AudioGuideState {
  final String? activeTrackId;
  final bool isPlaying;
  final double progress; // 0.0 to 1.0

  AudioGuideState({
    this.activeTrackId,
    this.isPlaying = false,
    this.progress = 0.0,
  });

  AudioGuideState copyWith({
    String? activeTrackId,
    bool? isPlaying,
    double? progress,
  }) {
    return AudioGuideState(
      activeTrackId: activeTrackId ?? this.activeTrackId,
      isPlaying: isPlaying ?? this.isPlaying,
      progress: progress ?? this.progress,
    );
  }
}

class AudioGuideNotifier extends StateNotifier<AudioGuideState> {
  AudioGuideNotifier() : super(AudioGuideState());

  void playAudioTrack(String trackId) {
    if (state.activeTrackId == trackId) {
      state = state.copyWith(isPlaying: !state.isPlaying);
    } else {
      state = AudioGuideState(activeTrackId: trackId, isPlaying: true, progress: 0.0);
    }
  }

  void updateAudioProgress(double progress) {
    state = state.copyWith(progress: progress);
  }
}

final audioGuideProvider = StateNotifierProvider<AudioGuideNotifier, AudioGuideState>((ref) {
  return AudioGuideNotifier();
});

// 8. Navigation Screen State Provider
final currentScreenProvider = StateProvider<String>((ref) => '/splash');
final currentTabProvider = StateProvider<int>((ref) => 0);

// 9. Budget and Spending Selectors
final budgetCeilingProvider = Provider<double>((ref) => 1500.00);
final totalSpentProvider = Provider<double>((ref) {
  final expenses = ref.watch(expensesProvider);
  final itinerary = ref.watch(itineraryProvider);
  final base = expenses.fold(0.0, (double sum, item) => sum + item.amount);
  double activitiesCost = 0.0;
  for (var day in itinerary) {
    for (var act in day.activities) {
      activitiesCost += act.usdCost;
    }
  }
  return base + activitiesCost;
});

// 10. Real-time AI Discover Places Provider
final discoverPlacesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, category) async {
  final userState = ref.watch(userProfileProvider);
  final profileMap = Map<String, dynamic>.from(userState.profile);
  // Inject DNA metrics into the profile payload for hyper-personalization
  profileMap['dnaFoodie'] = userState.dnaFoodie;
  profileMap['dnaHeritage'] = userState.dnaHeritage;
  profileMap['dnaTech'] = userState.dnaTech;
  profileMap['dnaAdventure'] = userState.dnaAdventure;
  profileMap['travelArchetype'] = userState.travelArchetype;
  
  return AiService.getDiscoverPlaces(category, profileMap);
});

// 11. Real-time AI Picks / Personalized Recommendations Provider
final personalizedRecommendationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userState = ref.watch(userProfileProvider);
  final profileMap = Map<String, dynamic>.from(userState.profile);
  // Inject DNA metrics into the profile payload for hyper-personalization
  profileMap['dnaFoodie'] = userState.dnaFoodie;
  profileMap['dnaHeritage'] = userState.dnaHeritage;
  profileMap['dnaTech'] = userState.dnaTech;
  profileMap['dnaAdventure'] = userState.dnaAdventure;
  profileMap['travelArchetype'] = userState.travelArchetype;

  return AiService.getDiscoverPlaces('Personalized', profileMap);
});

// 12. Connection status
enum ServerConnectionStatus { connected, disconnected, checking }

class ServerConnectionNotifier extends StateNotifier<ServerConnectionStatus> {
  Timer? _pingTimer;

  ServerConnectionNotifier() : super(ServerConnectionStatus.checking) {
    checkHealth();
    // Poll every 15 seconds to keep status updated
    _pingTimer = Timer.periodic(const Duration(seconds: 15), (_) => checkHealth());
  }

  Future<void> checkHealth() async {
    final isAlive = await AiService.checkConnection();
    state = isAlive ? ServerConnectionStatus.connected : ServerConnectionStatus.disconnected;
  }

  void forceRefresh() {
    state = ServerConnectionStatus.checking;
    checkHealth();
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    super.dispose();
  }
}

final serverConnectionProvider = StateNotifierProvider<ServerConnectionNotifier, ServerConnectionStatus>((ref) {
  return ServerConnectionNotifier();
});

final serverUrlProvider = StateProvider<String>((ref) {
  return AiService.baseUrl;
});

// ==========================================
// ITINERARY WIZARD PROVIDERS
// ==========================================

// 13. Trip Bookings State
class TripBookingsNotifier extends StateNotifier<TripBookings> {
  TripBookingsNotifier() : super(TripBookings());

  void setTripDates(String start, String end) {
    state = state.copyWith(startDate: start, endDate: end, isManualDates: true);
  }

  void setStartDate(String start) {
    state = state.copyWith(startDate: start, isManualDates: true);
  }

  void setEndDate(String end) {
    state = state.copyWith(endDate: end, isManualDates: true);
  }

  void addFlight(FlightBooking flight) {
    final updatedFlights = [...state.flights, flight];
    String? newStart = state.startDate;
    String? newEnd = state.endDate;
    String newDestination = state.destination;

    if (updatedFlights.isNotEmpty) {
      final sorted = List<FlightBooking>.from(updatedFlights)
        ..sort((a, b) {
          final dtA = DateTime.tryParse(a.departureDate) ?? DateTime(1970);
          final dtB = DateTime.tryParse(b.departureDate) ?? DateTime(1970);
          return dtA.compareTo(dtB);
        });
      final flightStart = sorted.first.departureDate;
      final flightEnd = sorted.last.arrivalDate.isNotEmpty ? sorted.last.arrivalDate : sorted.last.departureDate;

      if (!state.isManualDates) {
        newStart = flightStart;
        newEnd = flightEnd;
      } else {
        final parsedItineraryStart = DateTime.tryParse(state.startDate ?? '');
        final parsedItineraryEnd = DateTime.tryParse(state.endDate ?? '');
        final parsedFlightStart = DateTime.tryParse(flightStart);
        final parsedFlightEnd = DateTime.tryParse(flightEnd);

        if (parsedItineraryStart != null && parsedFlightStart != null) {
          if (parsedFlightStart.isBefore(parsedItineraryStart)) {
            newStart = flightStart;
          }
        }
        if (parsedItineraryEnd != null && parsedFlightEnd != null) {
          if (parsedFlightEnd.isAfter(parsedItineraryEnd)) {
            newEnd = flightEnd;
          }
        }
      }

      // Auto-calculate destination city from flights
      FlightBooking? targetFlight;
      for (final f in updatedFlights) {
        if (f.flightType == 'going') {
          targetFlight = f;
          break;
        }
      }
      if (targetFlight == null) {
        for (final f in updatedFlights) {
          if (f.flightType == 'other') {
            targetFlight = f;
            break;
          }
        }
      }
      if (targetFlight == null) {
        for (final f in updatedFlights) {
          if (f.flightType != 'return') {
            targetFlight = f;
            break;
          }
        }
      }
      if (targetFlight == null) {
        targetFlight = updatedFlights.first;
      }

      if (targetFlight.flightType == 'return') {
        newDestination = targetFlight.departureCity;
      } else {
        newDestination = targetFlight.arrivalCity;
      }
    }

    state = state.copyWith(
      flights: updatedFlights,
      startDate: newStart,
      endDate: newEnd,
      destination: newDestination,
    );
  }

  void removeFlight(String id) {
    final updatedFlights = state.flights.where((f) => f.id != id).toList();
    String? newStart = state.startDate;
    String? newEnd = state.endDate;
    String newDestination = state.destination;

    if (!state.isManualDates) {
      if (updatedFlights.isNotEmpty) {
        final sorted = List<FlightBooking>.from(updatedFlights)
          ..sort((a, b) {
            final dtA = DateTime.tryParse(a.departureDate) ?? DateTime(1970);
            final dtB = DateTime.tryParse(b.departureDate) ?? DateTime(1970);
            return dtA.compareTo(dtB);
          });
        newStart = sorted.first.departureDate;
        newEnd = sorted.last.arrivalDate.isNotEmpty ? sorted.last.arrivalDate : sorted.last.departureDate;
      } else {
        newStart = '';
        newEnd = '';
      }
    }

    if (updatedFlights.isNotEmpty) {
      // Auto-calculate destination city from flights
      FlightBooking? targetFlight;
      for (final f in updatedFlights) {
        if (f.flightType == 'going') {
          targetFlight = f;
          break;
        }
      }
      if (targetFlight == null) {
        for (final f in updatedFlights) {
          if (f.flightType == 'other') {
            targetFlight = f;
            break;
          }
        }
      }
      if (targetFlight == null) {
        for (final f in updatedFlights) {
          if (f.flightType != 'return') {
            targetFlight = f;
            break;
          }
        }
      }
      if (targetFlight == null) {
        targetFlight = updatedFlights.first;
      }

      if (targetFlight.flightType == 'return') {
        newDestination = targetFlight.departureCity;
      } else {
        newDestination = targetFlight.arrivalCity;
      }
    }

    state = state.copyWith(
      flights: updatedFlights,
      startDate: newStart,
      endDate: newEnd,
      destination: newDestination,
    );
  }

  void addHotel(HotelBooking hotel) {
    state = state.copyWith(hotels: [...state.hotels, hotel]);
  }

  void removeHotel(String id) {
    state = state.copyWith(hotels: state.hotels.where((h) => h.id != id).toList());
  }

  void addOther(OtherBooking other) {
    state = state.copyWith(others: [...state.others, other]);
  }

  void removeOther(String id) {
    state = state.copyWith(others: state.others.where((o) => o.id != id).toList());
  }

  void setDestination(String dest) {
    state = state.copyWith(destination: dest);
  }

  void reset() {
    state = TripBookings();
  }
}

final tripBookingsProvider = StateNotifierProvider<TripBookingsNotifier, TripBookings>((ref) {
  return TripBookingsNotifier();
});

// 14. Selected Places from Explore Screen
final selectedPlacesProvider = StateProvider<List<ExplorePlaceItem>>((ref) => []);

// 15. Day Schedule State — with time-blocking engine
class DayScheduleNotifier extends StateNotifier<List<List<DayScheduleItem>>> {
  DayScheduleNotifier() : super([]);

  void initDays(int numDays) {
    if (state.isEmpty) {
      state = List.generate(numDays, (_) => []);
    } else if (state.length < numDays) {
      state = [...state, ...List.generate(numDays - state.length, (_) => [])];
    } else if (state.length > numDays) {
      state = state.sublist(0, numDays);
    }
  }

  /// Check if a time slot is free on a given day
  /// Returns true if no existing activity overlaps [startMin, startMin + duration)
  bool isTimeSlotFree(int dayIndex, int startMin, int durationMin, {String? excludePlaceId}) {
    if (dayIndex < 0 || dayIndex >= state.length) return true;
    final endMin = startMin + durationMin;
    for (final item in state[dayIndex]) {
      if (excludePlaceId != null && item.place.id == excludePlaceId) continue;
      final itemStart = item.startMinutes;
      final itemEnd = item.endMinutes;
      // Overlap check: two intervals overlap if one starts before the other ends
      if (startMin < itemEnd && endMin > itemStart) {
        return false;
      }
    }
    return true;
  }

  /// Find the first free slot of a day for a place.
  /// Checks open hours first, falls back to closed hours if none are available.
  int findFreeSlotForPlace(int dayIndex, ExplorePlaceItem place, TripBookings bookings, {String? excludePlaceId}) {
    if (dayIndex < 0 || dayIndex >= state.length) return 540; // 9:00 AM default

    final duration = place.durationMinutes;
    final openMin = place.openMinutes;
    final closeMin = place.closeMinutes;

    // Build occupancy grid (1500 minutes to support nightlife crossing midnight)
    final grid = List<int>.filled(1500, 0);

    // Block time before earliest start
    final earliestStart = getDayEarliestStart(dayIndex, bookings);
    for (int i = 0; i < earliestStart; i++) {
      grid[i] = 1;
    }

    // Block time after latest departure (if return day)
    final baseStart = getBaseStartDate(bookings);
    final dayDate = baseStart.add(Duration(days: dayIndex));
    final dateStr = '${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}';

    final returnFlight = getReturnFlight(bookings);
    final returnDeparture = returnFlight != null
        ? parseFlightDateTime(returnFlight.departureDate, returnFlight.departureTime.isNotEmpty ? returnFlight.departureTime : '06:00 PM')
        : null;

    final isReturnDepartureDay = returnDeparture != null &&
        dayDate.year == returnDeparture.year &&
        dayDate.month == returnDeparture.month &&
        dayDate.day == returnDeparture.day;

    if (isReturnDepartureDay && returnFlight != null) {
      final depMin = parseTimeToMinutes(returnFlight.departureTime.isNotEmpty ? returnFlight.departureTime : '06:00 PM');
      final latestDepartureStartMin = depMin - 165;
      for (int i = latestDepartureStartMin; i < 1500; i++) {
        grid[i] = 1;
      }
    }

    // Block hotel checkout periods
    final checkingInHotels = bookings.hotels.where((h) => h.checkInDate == dateStr).toList();
    final checkingOutHotels = bookings.hotels.where((h) => h.checkOutDate == dateStr).toList();
    for (final hotel in checkingOutHotels) {
      final coMin = parseTimeToMinutes(hotel.checkOutTime.isNotEmpty ? hotel.checkOutTime : '11:00 AM');
      final isHotelChange = checkingInHotels.isNotEmpty;
      final endBlock = isHotelChange ? coMin + 120 : coMin + 30;
      for (int i = coMin; i < endBlock; i++) {
        if (i < 1500) grid[i] = 1;
      }
    }

    // Block existing scheduled items (excluding the current one)
    for (final item in state[dayIndex]) {
      if (excludePlaceId != null && item.place.id == excludePlaceId) continue;
      final s = item.startMinutes - 30; // 30 min travel buffer before
      final e = item.endMinutes;
      for (int i = max(0, s); i < e; i++) {
        if (i < 1500) grid[i] = 1;
      }
    }

    // Helper to check if a candidate interval is free
    bool isIntervalFree(int start, int end) {
      for (int i = start; i < end; i++) {
        if (i >= 1500 || grid[i] != 0) return false;
      }
      return true;
    }

    // Pass 1: Try to find first free slot respecting open/close hours
    int searchStart = openMin;
    if (searchStart < earliestStart) {
      searchStart = earliestStart;
    }
    
    for (int candidate = searchStart; candidate + duration <= closeMin; candidate += 15) {
      if (isIntervalFree(candidate - 30, candidate + duration)) {
        return candidate;
      }
    }

    // Pass 2: Fallback (any slot, even if closed)
    int absoluteLimit = (place.genre == 'Nightlife') ? 1500 : 1380;
    for (int candidate = earliestStart; candidate + duration <= absoluteLimit; candidate += 15) {
      if (isIntervalFree(candidate - 30, candidate + duration)) {
        return candidate;
      }
    }

    return earliestStart; // absolute fallback
  }

  /// Find the next free slot on a day that can fit [durationMin] minutes
  /// Searches from [afterMinutes] onwards (default 9:00 AM = 540)
  /// Returns start time in minutes, or -1 if no slot found before 10 PM
  int findNextFreeSlot(int dayIndex, int durationMin, {int afterMinutes = 540}) {
    if (dayIndex < 0 || dayIndex >= state.length) return afterMinutes;
    
    // Get all occupied intervals on this day, sorted by start
    final occupied = state[dayIndex]
        .map((item) => [item.startMinutes, item.endMinutes])
        .toList()
      ..sort((a, b) => a[0].compareTo(b[0]));

    int candidate = afterMinutes;
    const int dayEnd = 22 * 60; // 10:00 PM limit

    for (final interval in occupied) {
      if (candidate + durationMin <= interval[0]) {
        // Found a gap before this occupied interval
        return candidate;
      }
      // Move candidate past this occupied interval (+ 30 min travel buffer)
      if (interval[1] + 30 > candidate) {
        candidate = interval[1] + 30;
      }
    }

    // Check if there's room after all occupied slots
    if (candidate + durationMin <= dayEnd) {
      return candidate;
    }
    return -1; // No slot available
  }

  void addToDay(int dayIndex, DayScheduleItem item, TripBookings bookings) {
    if (dayIndex >= 0 && dayIndex < state.length) {
      final updated = List<List<DayScheduleItem>>.from(state.map((d) => List<DayScheduleItem>.from(d)));
      
      // Auto-assign the first free slot
      final freeSlot = findFreeSlotForPlace(dayIndex, item.place, bookings);
      final timeStr = minutesToTimeString(freeSlot);
      
      final newItem = item.copyWith(
        dayNumber: dayIndex + 1,
        sortOrder: updated[dayIndex].length,
        scheduledTime: timeStr,
      );
      updated[dayIndex] = [...updated[dayIndex], newItem];
      // Sort by scheduled time
      updated[dayIndex].sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
      // Re-index sort orders
      for (int i = 0; i < updated[dayIndex].length; i++) {
        updated[dayIndex][i] = updated[dayIndex][i].copyWith(sortOrder: i);
      }
      state = updated;
    }
  }

  void removeFromDay(int dayIndex, String placeId) {
    if (dayIndex >= 0 && dayIndex < state.length) {
      final updated = List<List<DayScheduleItem>>.from(state.map((d) => List<DayScheduleItem>.from(d)));
      updated[dayIndex] = updated[dayIndex].where((item) => item.place.id != placeId).toList();
      // Re-index sort orders
      for (int i = 0; i < updated[dayIndex].length; i++) {
        updated[dayIndex][i] = updated[dayIndex][i].copyWith(sortOrder: i);
      }
      state = updated;
    }
  }

  /// Move activity between days; checks for time availability on target day
  /// Returns true if successful, false if no free slot
  bool moveToDay(int fromDay, int toDay, String placeId, TripBookings bookings) {
    if (fromDay >= 0 && fromDay < state.length && toDay >= 0 && toDay < state.length) {
      final updated = List<List<DayScheduleItem>>.from(state.map((d) => List<DayScheduleItem>.from(d)));
      final itemIndex = updated[fromDay].indexWhere((item) => item.place.id == placeId);
      if (itemIndex >= 0) {
        final item = updated[fromDay][itemIndex];
        
        // Check if the same time is free on the target day
        final originalStart = item.startMinutes;
        bool canKeepTime = true;
        // Check against target day's existing items
        final targetOccupied = updated[toDay];
        for (final existing in targetOccupied) {
          final eStart = existing.startMinutes;
          final eEnd = existing.endMinutes;
          if (originalStart < eEnd && (originalStart + item.place.durationMinutes) > eStart) {
            canKeepTime = false;
            break;
          }
        }

        String newTime = item.scheduledTime;
        if (!canKeepTime) {
          // Find a free slot on the target day
          final freeSlot = findFreeSlotForPlace(toDay, item.place, bookings, excludePlaceId: placeId);
          if (freeSlot < 0) return false; // No free slot available
          newTime = minutesToTimeString(freeSlot);
        }

        updated[fromDay].removeAt(itemIndex);
        final movedItem = item.copyWith(
          dayNumber: toDay + 1,
          sortOrder: updated[toDay].length,
          scheduledTime: newTime,
        );
        updated[toDay] = [...updated[toDay], movedItem];
        // Sort target day by time
        updated[toDay].sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
        for (int i = 0; i < updated[toDay].length; i++) {
          updated[toDay][i] = updated[toDay][i].copyWith(sortOrder: i);
        }
        state = updated;
        return true;
      }
    }
    return false;
  }

  void reorderInDay(int dayIndex, int oldIndex, int newIndex) {
    if (dayIndex >= 0 && dayIndex < state.length) {
      final updated = List<List<DayScheduleItem>>.from(state.map((d) => List<DayScheduleItem>.from(d)));
      final dayItems = List<DayScheduleItem>.from(updated[dayIndex]);
      if (newIndex > oldIndex) newIndex -= 1;
      final item = dayItems.removeAt(oldIndex);
      dayItems.insert(newIndex, item);
      
      // Auto-suggest timings to re-stack them sequentially in the new order!
      int currentTime = 540; // 9:00 AM
      for (int i = 0; i < dayItems.length; i++) {
        dayItems[i] = dayItems[i].copyWith(
          scheduledTime: minutesToTimeString(currentTime),
          sortOrder: i,
        );
        currentTime += dayItems[i].place.durationMinutes + 30; // 30 min buffer
      }
      
      updated[dayIndex] = dayItems;
      state = updated;
    }
  }

  /// Swap two activities between days/times.
  /// Checks if both slots are free (excluding the swapping items themselves).
  /// Returns true if successful, false if there is a conflict.
  bool swapActivities(int dayIndex1, String placeId1, int dayIndex2, String placeId2) {
    if (dayIndex1 < 0 || dayIndex1 >= state.length || dayIndex2 < 0 || dayIndex2 >= state.length) return false;
    
    final updated = List<List<DayScheduleItem>>.from(state.map((d) => List<DayScheduleItem>.from(d)));
    final idx1 = updated[dayIndex1].indexWhere((item) => item.place.id == placeId1);
    final idx2 = updated[dayIndex2].indexWhere((item) => item.place.id == placeId2);
    
    if (idx1 < 0 || idx2 < 0) return false;
    
    final item1 = updated[dayIndex1][idx1];
    final item2 = updated[dayIndex2][idx2];
    
    final time1 = item1.scheduledTime;
    final time2 = item2.scheduledTime;
    
    final startMin1 = item1.startMinutes;
    final startMin2 = item2.startMinutes;
    
    // Check if item1 fits on dayIndex2 at startMin2 (excluding item2)
    final fits1 = isTimeSlotFree(dayIndex2, startMin2, item1.place.durationMinutes, excludePlaceId: placeId2);
    // Check if item2 fits on dayIndex1 at startMin1 (excluding item1)
    final fits2 = isTimeSlotFree(dayIndex1, startMin1, item2.place.durationMinutes, excludePlaceId: placeId1);
    
    if (fits1 && fits2) {
      if (dayIndex1 == dayIndex2) {
        // Same day: just swap times
        final list = List<DayScheduleItem>.from(state[dayIndex1]);
        final i1 = list.indexWhere((item) => item.place.id == placeId1);
        final i2 = list.indexWhere((item) => item.place.id == placeId2);
        
        final temp = list[i1].copyWith(scheduledTime: time2);
        list[i2] = list[i2].copyWith(scheduledTime: time1);
        list[i1] = temp;
        
        list.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
        for (int i = 0; i < list.length; i++) {
          list[i] = list[i].copyWith(sortOrder: i);
        }
        updated[dayIndex1] = list;
      } else {
        // Different days: swap days and times
        updated[dayIndex1].removeAt(idx1);
        final newItem2 = item2.copyWith(
          dayNumber: dayIndex1 + 1,
          scheduledTime: time1,
        );
        updated[dayIndex1].add(newItem2);
        updated[dayIndex1].sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
        for (int i = 0; i < updated[dayIndex1].length; i++) {
          updated[dayIndex1][i] = updated[dayIndex1][i].copyWith(sortOrder: i);
        }
        
        final idx2New = updated[dayIndex2].indexWhere((item) => item.place.id == placeId2);
        updated[dayIndex2].removeAt(idx2New);
        final newItem1 = item1.copyWith(
          dayNumber: dayIndex2 + 1,
          scheduledTime: time2,
        );
        updated[dayIndex2].add(newItem1);
        updated[dayIndex2].sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
        for (int i = 0; i < updated[dayIndex2].length; i++) {
          updated[dayIndex2][i] = updated[dayIndex2][i].copyWith(sortOrder: i);
        }
      }
      
      state = updated;
      return true;
    }
    
    return false;
  }

  /// Update time for an activity. Returns false if the new time conflicts.
  bool updateTime(int dayIndex, String placeId, String newTime) {
    if (dayIndex >= 0 && dayIndex < state.length) {
      final item = state[dayIndex].firstWhere(
        (i) => i.place.id == placeId,
        orElse: () => state[dayIndex].first,
      );
      final newStartMin = parseTimeToMinutes(newTime);
      
      // Check collision (exclude self)
      if (!isTimeSlotFree(dayIndex, newStartMin, item.place.durationMinutes, excludePlaceId: placeId)) {
        return false; // Conflict!
      }
      
      final updated = List<List<DayScheduleItem>>.from(state.map((d) => List<DayScheduleItem>.from(d)));
      updated[dayIndex] = updated[dayIndex].map((i) {
        if (i.place.id == placeId) {
          return i.copyWith(scheduledTime: newTime);
        }
        return i;
      }).toList();
      // Re-sort by time
      updated[dayIndex].sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
      for (int i = 0; i < updated[dayIndex].length; i++) {
        updated[dayIndex][i] = updated[dayIndex][i].copyWith(sortOrder: i);
      }
      state = updated;
      return true;
    }
    return false;
  }

  void addToDayAtTime(int dayIndex, ExplorePlaceItem place, String timeStr) {
    if (dayIndex >= 0 && dayIndex < state.length) {
      final updated = List<List<DayScheduleItem>>.from(state.map((d) => List<DayScheduleItem>.from(d)));
      final newItem = DayScheduleItem(
        place: place,
        dayNumber: dayIndex + 1,
        sortOrder: updated[dayIndex].length,
        scheduledTime: timeStr,
      );
      updated[dayIndex] = [...updated[dayIndex], newItem];
      updated[dayIndex].sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
      for (int i = 0; i < updated[dayIndex].length; i++) {
        updated[dayIndex][i] = updated[dayIndex][i].copyWith(sortOrder: i);
      }
      state = updated;
    }
  }

  Map<String, String> autoSuggestTimings(int dayIndex, TripBookings bookings) {
    return resolveConflictsForDay(dayIndex, bookings);
  }

  void reorderAttractionsInDay(int dayIdx, int oldIndex, int newIndex, TripBookings bookings) {
    if (dayIdx < 0 || dayIdx >= state.length) return;
    final dayItems = List<DayScheduleItem>.from(state[dayIdx]);
    if (dayItems.isEmpty) return;

    if (newIndex > oldIndex) newIndex -= 1;
    newIndex = newIndex.clamp(0, dayItems.length - 1);
    final item = dayItems.removeAt(oldIndex);
    dayItems.insert(newIndex, item);

    final baseStart = getBaseStartDate(bookings);
    final dayDate = baseStart.add(Duration(days: dayIdx));
    final dateStr = '${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}';

    final checkingInHotels = bookings.hotels.where((h) => h.checkInDate == dateStr).toList();
    final checkingOutHotels = bookings.hotels.where((h) => h.checkOutDate == dateStr).toList();

    int currentPointerMin = getDayEarliestStart(dayIdx, bookings);

    final returnFlight = getReturnFlight(bookings);
    final returnDeparture = returnFlight != null
        ? parseFlightDateTime(returnFlight.departureDate, returnFlight.departureTime.isNotEmpty ? returnFlight.departureTime : '06:00 PM')
        : null;

    final isReturnDepartureDay = returnDeparture != null &&
        dayDate.year == returnDeparture.year &&
        dayDate.month == returnDeparture.month &&
        dayDate.day == returnDeparture.day;

    final isAfterReturnFlight = returnDeparture != null &&
        DateTime(dayDate.year, dayDate.month, dayDate.day).isAfter(DateTime(returnDeparture.year, returnDeparture.month, returnDeparture.day));

    int latestDepartureStartMin = 1500;
    if (isReturnDepartureDay && returnFlight != null) {
      final depMin = parseTimeToMinutes(returnFlight.departureTime.isNotEmpty ? returnFlight.departureTime : '06:00 PM');
      latestDepartureStartMin = depMin - 165;
    } else if (isAfterReturnFlight) {
      latestDepartureStartMin = 0;
    }

    final List<List<int>> avoidPeriods = [];
    for (final hotel in checkingOutHotels) {
      final coMin = parseTimeToMinutes(hotel.checkOutTime.isNotEmpty ? hotel.checkOutTime : '11:00 AM');
      final isHotelChange = checkingInHotels.isNotEmpty;
      avoidPeriods.add([coMin, isHotelChange ? coMin + 120 : coMin + 30]);
    }

    final List<DayScheduleItem> resolvedItems = [];
    for (int i = 0; i < dayItems.length; i++) {
      final currentItem = dayItems[i];
      final duration = currentItem.place.durationMinutes;
      final openMin = currentItem.place.openMinutes;
      final closeMin = currentItem.place.closeMinutes;

      int startMin = resolvedItems.isEmpty ? currentPointerMin : currentPointerMin + 30;
      startMin = max(startMin, openMin);

      bool slotFound = false;
      final int dayLimit = (currentItem.place.genre == 'Nightlife') ? 1500 : 1380;
      while (startMin + duration <= latestDepartureStartMin && startMin + duration <= dayLimit) {
        bool overlapsAvoid = false;
        for (final period in avoidPeriods) {
          if (startMin < period[1] && (startMin + duration) > period[0]) {
            overlapsAvoid = true;
            break;
          }
        }

        if (!overlapsAvoid && startMin >= openMin && (startMin + duration) <= closeMin) {
          slotFound = true;
          break;
        }
        startMin += 15;
      }

      if (slotFound) {
        resolvedItems.add(currentItem.copyWith(
          scheduledTime: minutesToTimeString(startMin),
          sortOrder: i,
        ));
        currentPointerMin = startMin + duration;
      } else {
        resolvedItems.add(currentItem.copyWith(sortOrder: i));
      }
    }

    resolvedItems.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    for (int i = 0; i < resolvedItems.length; i++) {
      resolvedItems[i] = resolvedItems[i].copyWith(sortOrder: i);
    }

    final updated = List<List<DayScheduleItem>>.from(state.map((d) => List<DayScheduleItem>.from(d)));
    updated[dayIdx] = resolvedItems;
    state = updated;
  }

  Map<String, String> resolveConflictsForDay(int dayIdx, TripBookings bookings) {
    final Map<String, String> changes = {};
    if (dayIdx < 0 || dayIdx >= state.length) return changes;
    final dayItems = state[dayIdx];
    if (dayItems.isEmpty) return changes;

    final sortedItems = List<DayScheduleItem>.from(dayItems)
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    final baseStart = getBaseStartDate(bookings);
    final dayDate = baseStart.add(Duration(days: dayIdx));
    final dateStr = '${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}';
    final checkingInHotels = bookings.hotels.where((h) => h.checkInDate == dateStr).toList();
    final checkingOutHotels = bookings.hotels.where((h) => h.checkOutDate == dateStr).toList();

    int currentPointerMin = getDayEarliestStart(dayIdx, bookings);

    final returnFlight = getReturnFlight(bookings);
    final returnDeparture = returnFlight != null
        ? parseFlightDateTime(returnFlight.departureDate, returnFlight.departureTime.isNotEmpty ? returnFlight.departureTime : '06:00 PM')
        : null;

    final isReturnDepartureDay = returnDeparture != null &&
        dayDate.year == returnDeparture.year &&
        dayDate.month == returnDeparture.month &&
        dayDate.day == returnDeparture.day;

    final isAfterReturnFlight = returnDeparture != null &&
        DateTime(dayDate.year, dayDate.month, dayDate.day).isAfter(DateTime(returnDeparture.year, returnDeparture.month, returnDeparture.day));

    int latestDepartureStartMin = 1500;
    if (isReturnDepartureDay && returnFlight != null) {
      final depMin = parseTimeToMinutes(returnFlight.departureTime.isNotEmpty ? returnFlight.departureTime : '06:00 PM');
      latestDepartureStartMin = depMin - 165;
    } else if (isAfterReturnFlight) {
      latestDepartureStartMin = 0;
    }

    final List<List<int>> avoidPeriods = [];
    for (final hotel in checkingOutHotels) {
      final coMin = parseTimeToMinutes(hotel.checkOutTime.isNotEmpty ? hotel.checkOutTime : '11:00 AM');
      final isHotelChange = checkingInHotels.isNotEmpty;
      avoidPeriods.add([coMin, isHotelChange ? coMin + 120 : coMin + 30]);
    }

    final List<DayScheduleItem> resolvedItems = [];
    for (final item in sortedItems) {
      final duration = item.place.durationMinutes;
      final openMin = item.place.openMinutes;
      final closeMin = item.place.closeMinutes;

      int startMin = resolvedItems.isEmpty ? currentPointerMin : currentPointerMin + 30;
      startMin = max(startMin, openMin);

      bool slotFound = false;
      final int dayLimit = (item.place.genre == 'Nightlife') ? 1500 : 1380;
      while (startMin + duration <= latestDepartureStartMin && startMin + duration <= dayLimit) {
        bool overlapsAvoid = false;
        for (final period in avoidPeriods) {
          if (startMin < period[1] && (startMin + duration) > period[0]) {
            overlapsAvoid = true;
            break;
          }
        }

        if (!overlapsAvoid && startMin >= openMin && (startMin + duration) <= closeMin) {
          slotFound = true;
          break;
        }
        startMin += 15;
      }

      if (slotFound) {
        final oldTime = item.scheduledTime;
        final newTime = minutesToTimeString(startMin);
        if (oldTime != newTime) {
          changes[item.place.name] = "$oldTime → $newTime";
        }
        resolvedItems.add(item.copyWith(scheduledTime: newTime));
        currentPointerMin = startMin + duration;
      } else {
        resolvedItems.add(item);
      }
    }

    resolvedItems.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    for (int i = 0; i < resolvedItems.length; i++) {
      resolvedItems[i] = resolvedItems[i].copyWith(sortOrder: i);
    }

    final updated = List<List<DayScheduleItem>>.from(state.map((d) => List<DayScheduleItem>.from(d)));
    updated[dayIdx] = resolvedItems;
    state = updated;

    return changes;
  }


  /// Get all occupied time ranges for a day (for UI display)
  List<Map<String, int>> getOccupiedSlots(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= state.length) return [];
    return state[dayIndex].map((item) => {
      'start': item.startMinutes,
      'end': item.endMinutes,
    }).toList();
  }

  void reset() {
    state = [];
  }
}

final dayScheduleProvider = StateNotifierProvider<DayScheduleNotifier, List<List<DayScheduleItem>>>((ref) {
  return DayScheduleNotifier();
});

final draftItineraryProvider = StateProvider<DraftItinerary?>((ref) => null);

// 18. Past Trips Provider
class PastTrip {
  final String id;
  final String destination;
  final String dates;
  final String theme;
  final int activitiesCount;
  final String image;
  final String highlight;

  PastTrip({
    required this.id,
    required this.destination,
    required this.dates,
    required this.theme,
    required this.activitiesCount,
    required this.image,
    required this.highlight,
  });
}

class PastTripsNotifier extends StateNotifier<List<PastTrip>> {
  PastTripsNotifier() : super([
    PastTrip(
      id: 'pt-1',
      destination: 'Tokyo, Japan',
      dates: 'May 12 - May 17, 2025',
      theme: 'Cyberpunk Neon & Ancient Shrines',
      activitiesCount: 15,
      image: 'https://images.unsplash.com/photo-1540959733332-eab4deceeaf7?auto=format&fit=crop&w=800&q=80',
      highlight: 'Watched Godzilla roar at dusk in Shinjuku and walked Asakusa at dawn.',
    ),
    PastTrip(
      id: 'pt-2',
      destination: 'Paris, France',
      dates: 'Sept 04 - Sept 08, 2024',
      theme: 'Gourmet Pastries & Impressionist Art',
      activitiesCount: 9,
      image: 'https://images.unsplash.com/photo-1499856871958-5b9647a6409a?auto=format&fit=crop&w=800&q=80',
      highlight: 'Ate fresh croissants by the Seine and visited the Musee d’Orsay.',
    ),
  ]);

  void removeTrip(String id) {
    state = state.where((trip) => trip.id != id).toList();
  }

  void clearTrips() {
    state = [];
  }
}

final pastTripsProvider = StateNotifierProvider<PastTripsNotifier, List<PastTrip>>((ref) {
  return PastTripsNotifier();
});
