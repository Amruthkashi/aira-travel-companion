import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/travel_models.dart';
import '../services/ai_service.dart';


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
          return ItineraryDay(
            day: day.day,
            theme: day.theme,
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
          return ItineraryDay(
            day: day.day,
            theme: day.theme,
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
          return ItineraryDay(
            day: day.day,
            theme: day.theme,
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
    
    // Simulate AI swap for now with a slight variation
    final newAct = oldAct.copyWith(
      activity: "AI SUGGESTED: ${oldAct.activity} (Optimized)",
      description: "${oldAct.description}\n\n[AI Optimization]: Recommended alternative route via local express to save 15 mins.",
      ticketInfo: "Digital Voucher Issued",
    );

    final updatedActivities = List<ActivityItem>.from(day.activities);
    updatedActivities[activityIndex] = newAct;

    state = state.map((d) {
      if (d.day == dayIndex + 1) {
        return ItineraryDay(day: d.day, theme: d.theme, activities: updatedActivities);
      }
      return d;
    }).toList();
  }

  void applyAiReroute(int dayIndex, List<ActivityItem> newActivities, String newTheme) {
    if (dayIndex >= 0 && dayIndex < state.length) {
      state = state.map((day) {
        if (day.day == dayIndex + 1) {
          return ItineraryDay(
            day: day.day,
            theme: newTheme,
            activities: newActivities,
          );
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
