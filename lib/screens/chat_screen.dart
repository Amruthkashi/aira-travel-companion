import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/travel_providers.dart';

// Model definition for map destination hotspots (Myra-style)
class MapDestination {
  final String name;
  final String description;
  final List<String> images;
  final String prompt;
  final double x; // Percent from left (0 to 100)
  final double y; // Percent from top (0 to 100)
  final Color color;

  const MapDestination({
    required this.name,
    required this.description,
    required this.images,
    required this.prompt,
    required this.x,
    required this.y,
    required this.color,
  });
}

// Places exactly matching the user's Myra AI screenshot
const List<MapDestination> MAP_DESTINATIONS = [
  MapDestination(
    name: "Kashmir",
    description: "Heaven on Earth - snow-capped peaks, Dal Lake houseboats, and tulip gardens.",
    images: [
      "https://images.unsplash.com/photo-1566228015668-4c45dbc4e2f5?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1595878715977-2e8fe63b658a?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1588681664899-f142ff225f63?w=200&auto=format&fit=crop&q=80"
    ],
    prompt: "Show me details and packages for a trip to Kashmir.",
    x: 43.0,
    y: 33.0,
    color: Color(0xFF2ECC71), // Vibrant Green
  ),
  MapDestination(
    name: "Manali",
    description: "Charming valley town - adventure sports, Rohtang pass snow, and wooden temples.",
    images: [
      "https://images.unsplash.com/photo-1605649487212-47bdab064df7?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1544644181-1484b3fdfc62?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=200&auto=format&fit=crop&q=80"
    ],
    prompt: "Plan a trip to Manali for adventure sports.",
    x: 46.0,
    y: 35.0,
    color: Color(0xFF2ECC71),
  ),
  MapDestination(
    name: "Delhi",
    description: "Vibrant capital - Red Fort history, Qutub Minar, and street food crawling.",
    images: [
      "https://images.unsplash.com/photo-1587474260584-136574528ed5?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1574169208507-84376144848b?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=200&auto=format&fit=crop&q=80"
    ],
    prompt: "Tell me about historical spots and foods in Delhi.",
    x: 44.0,
    y: 39.0,
    color: Color(0xFF2ECC71),
  ),
  MapDestination(
    name: "Dubai",
    description: "Luxury high-rises, shopping malls, desert safaris, and Burj Khalifa vistas.",
    images: [
      "https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1582672060674-bc2bd808a8b5?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1546412414-e1885261b951?w=200&auto=format&fit=crop&q=80"
    ],
    prompt: "Plan a luxury trip to Dubai.",
    x: 20.0,
    y: 43.0,
    color: Color(0xFF2ECC71),
  ),
  MapDestination(
    name: "Assam",
    description: "World-famous tea estates, Kaziranga rhinos, and Brahmaputra river.",
    images: [
      "https://images.unsplash.com/photo-1574360309993-a020b7d5f4e8?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1597848212624-a19eb35e2651?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1582515073490-39981397c445?w=200&auto=format&fit=crop&q=80"
    ],
    prompt: "Suggest attractions in Assam and Kaziranga.",
    x: 61.0,
    y: 38.0,
    color: Color(0xFF2ECC71),
  ),
  MapDestination(
    name: "Mumbai",
    description: "Gateway of India, Bollywood, beaches, and local street food.",
    images: [
      "https://images.unsplash.com/photo-1570168007204-dfb528c6958f?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1562158074-a58145abf64a?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1598305367664-9df2c219662b?w=200&auto=format&fit=crop&q=80"
    ],
    prompt: "What should I do in Mumbai?",
    x: 39.0,
    y: 46.0,
    color: Color(0xFF2ECC71),
  ),
  MapDestination(
    name: "Goa",
    description: "Golden sand beaches, historic churches, and local seafood shacks.",
    images: [
      "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1506461883276-594a12b11db3?w=200&auto=format&fit=crop&q=80"
    ],
    prompt: "Plan a beach trip to Goa.",
    x: 40.0,
    y: 50.0,
    color: Color(0xFF2ECC71),
  ),
  MapDestination(
    name: "Mysore",
    description: "Palatial history, incense markets, and traditional silk weaving hubs.",
    images: [
      "https://images.unsplash.com/photo-1590050752117-238cb0612b1b?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1600011689032-8b628b8a8744?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1588681664899-f142ff225f63?w=200&auto=format&fit=crop&q=80"
    ],
    prompt: "Plan a heritage tour of Mysore.",
    x: 44.0,
    y: 54.0,
    color: Color(0xFF2ECC71),
  ),
  MapDestination(
    name: "Sri Lanka",
    description: "Scenic train tea plantations, ancient Sigiriya rock, and blue oceans.",
    images: [
      "https://images.unsplash.com/photo-1588598126786-81c1c1f516a2?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1544735716-392fe2489ffa?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1546708973-b339540b5162?w=200&auto=format&fit=crop&q=80"
    ],
    prompt: "Give me details on planning a Sri Lanka holiday.",
    x: 50.0,
    y: 60.0,
    color: Color(0xFF2ECC71),
  ),
  MapDestination(
    name: "Andaman",
    description: "Pristine white sand beaches, marine coral reefs, and scuba diving sanctuaries.",
    images: [
      "https://images.unsplash.com/photo-1589308078059-be1415eab4c3?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1555400038-63f5ba517a47?w=200&auto=format&fit=crop&q=80"
    ],
    prompt: "Plan a honeymoon/scuba trip to Andaman.",
    x: 63.0,
    y: 55.0,
    color: Color(0xFF2ECC71),
  ),
  MapDestination(
    name: "Thailand",
    description: "Ornate gold temples, beautiful tropical beaches, and vibrant floating street markets.",
    images: [
      "https://images.unsplash.com/photo-1508009603885-50cf7c579365?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=200&auto=format&fit=crop&q=80"
    ],
    prompt: "What are the must-do activities in Thailand?",
    x: 71.0,
    y: 50.0,
    color: Color(0xFF2ECC71),
  ),
  MapDestination(
    name: "Vietnam",
    description: "Spectacular Ha Long Bay cruises, historical old towns, and delicious local pho.",
    images: [
      "https://images.unsplash.com/photo-1528127269322-539801943592?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=200&auto=format&fit=crop&q=80"
    ],
    prompt: "Suggest a 7-day travel plan for Vietnam.",
    x: 79.0,
    y: 52.0,
    color: Color(0xFF2ECC71),
  ),
  MapDestination(
    name: "Hong Kong",
    description: "Breathtaking harbor skylines, dynamic shopping districts, and Disneyland.",
    images: [
      "https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1538481199705-c710c4e965fc?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=200&auto=format&fit=crop&q=80"
    ],
    prompt: "What is there to do in Hong Kong with family?",
    x: 82.0,
    y: 46.0,
    color: Color(0xFF2ECC71),
  ),
  MapDestination(
    name: "Egypt",
    description: "Ancient Pyramids of Giza, Sphinx mysteries, and beautiful Nile river cruises.",
    images: [
      "https://images.unsplash.com/photo-1539650116574-8efeb43e2750?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1503177119275-0aa32b31d468?w=200&auto=format&fit=crop&q=80",
      "https://images.unsplash.com/photo-1572120360610-d971b9d7767c?w=200&auto=format&fit=crop&q=80"
    ],
    prompt: "Show me details and itineraries for Egypt.",
    x: 4.0,
    y: 52.0,
    color: Color(0xFF2ECC71),
  )
];

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _chatInput = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isGenerating = false;
  bool _chatTyping = false;
  int _genProgress = 0;
  String _genStage = 'Initializing Concierge Optimizer...';
  Timer? _genTimer;
  MapDestination? _activeMapPopup;

  @override
  void dispose() {
    _chatInput.dispose();
    _scrollController.dispose();
    _genTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty || _chatTyping) return;
    
    setState(() {
      _chatTyping = true;
    });
    ref.read(chatMessagesProvider.notifier).sendChatMessage(text, 'user');
    _chatInput.clear();
    _scrollToBottom();

    try {
      final profile = ref.read(userProfileProvider).profile;
      await ref.read(chatMessagesProvider.notifier).sendChatMessageWithAiReply(text, profile);
    } catch (e) {
      ref.read(chatMessagesProvider.notifier).sendChatMessage("Sorry, I encountered an error connecting to my AI service.", 'assistant');
    } finally {
      if (mounted) {
        setState(() {
          _chatTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _startCompilation({String? customDestination}) {
    setState(() {
      _isGenerating = true;
      _genProgress = 0;
      _genStage = 'Analyzing traveler vibe profiling logs...';
    });

    final profile = ref.read(userProfileProvider).profile;
    final city = customDestination ?? profile['city'] ?? 'Tokyo';
    
    int days = 2;
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
          print('Error parsing dates for chat compilation: $e');
        }
      }
    }

    final query = "Plan a $days-day itinerary for $city";
    final userProfileState = ref.read(userProfileProvider);
    final updatedProfile = Map<String, dynamic>.from(profile)
      ..['city'] = city
      ..['dnaFoodie'] = userProfileState.dnaFoodie
      ..['dnaHeritage'] = userProfileState.dnaHeritage
      ..['dnaTech'] = userProfileState.dnaTech
      ..['dnaAdventure'] = userProfileState.dnaAdventure
      ..['travelArchetype'] = userProfileState.travelArchetype;

    bool apiFinished = false;

    ref.read(itineraryProvider.notifier).generateAiItinerary(query, updatedProfile).then((_) {
      ref.read(checklistProvider.notifier).generateRealAiChecklist(updatedProfile).then((_) {
        apiFinished = true;
      }).catchError((e) {
        apiFinished = true;
      });
    }).catchError((e) {
      apiFinished = true;
    });

    _genTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      setState(() {
        if (_genProgress < 30) {
          _genProgress += 5;
          _genStage = 'Analyzing traveler vibe profiling logs...';
        } else if (_genProgress < 70) {
          _genProgress += 4;
          _genStage = 'Querying local spots & experiences...';
        } else if (_genProgress < 95) {
          if (apiFinished) {
            _genProgress += 10;
          } else {
            _genStage = 'Formulating day maps & suggestion attire with Gemini AI...';
          }
        } else {
          _genProgress = 100;
          _genStage = 'Itinerary Compiled successfully!';
          timer.cancel();
          Future.delayed(const Duration(milliseconds: 800), () {
            if (!mounted) return;
            setState(() {
              _isGenerating = false;
            });
            ref.read(currentTabProvider.notifier).state = 2; // Switch to Trips tab
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatMessages = ref.watch(chatMessagesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2744),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFFFF477E)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'AIRA AI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Aira Concierge',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF2563EB)),
            onPressed: () => _startCompilation(),
          )
        ],
      ),
      body: Stack(
        children: [
          // Main Chat Feed Column
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: chatMessages.length + (_chatTyping ? 1 : 0),
                  itemBuilder: (context, idx) {
                    if (idx == chatMessages.length) {
                      // Aira is typing container with avatar
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8, top: 4),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2563EB), Color(0xFFFF477E)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A2744),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                    border: Border.all(color: const Color(0xFF334155)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF2563EB),
                                          strokeWidth: 1.5,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Aira is typing...",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final msg = chatMessages[idx];
                    final isUser = msg.sender == 'user';
                    final showSaveButton = !isUser && (
                      msg.text.toLowerCase().contains('itinerary') ||
                      msg.text.toLowerCase().contains('day 1') ||
                      msg.text.toLowerCase().contains('places') ||
                      msg.text.toLowerCase().contains('kyoto') ||
                      msg.text.toLowerCase().contains('tokyo') ||
                      msg.text.toLowerCase().contains('suggest') ||
                      msg.text.toLowerCase().contains('plan')
                    );

                    final bubbleContent = Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isUser
                            ? const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFFFF477E)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isUser ? null : const Color(0xFF1A2744),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                          bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                        ),
                        border: isUser
                            ? null
                            : Border.all(color: const Color(0xFF334155), width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.text,
                            style: TextStyle(
                              fontSize: 14, 
                              height: 1.4, 
                              color: isUser ? Colors.white : const Color(0xFFF1F5F9),
                            ),
                          ),
                          if (showSaveButton) ...[
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: () async {
                                final DateTimeRange? picked = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                  builder: (context, child) {
                                    return Theme(
                                      data: ThemeData.dark().copyWith(
                                        colorScheme: const ColorScheme.dark(
                                          primary: Color(0xFF2563EB),
                                          onPrimary: Colors.white,
                                          surface: Color(0xFF0A1628),
                                          onSurface: Colors.white,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );

                                if (picked != null) {
                                  final textLower = msg.text.toLowerCase();
                                  String city = 'Kyoto';
                                  if (textLower.contains('kyoto')) city = 'Kyoto';
                                  else if (textLower.contains('tokyo')) city = 'Tokyo';
                                  else if (textLower.contains('shibuya')) city = 'Crossing District';
                                  else if (textLower.contains('paris')) city = 'Paris';
                                  else if (textLower.contains('rome')) city = 'Rome';
                                  else if (textLower.contains('bali')) city = 'Bali';
                                  else if (textLower.contains('london')) city = 'London';
                                  else if (textLower.contains('barcelona')) city = 'Barcelona';
                                  else if (textLower.contains('santorini')) city = 'Santorini';
                                  else if (textLower.contains('amalfi')) city = 'Amalfi Coast';
                                  else if (textLower.contains('venice')) city = 'Venice';
                                  else if (textLower.contains('orlando')) city = 'Orlando';
                                  else if (textLower.contains('bangkok')) city = 'Bangkok';
                                  else if (textLower.contains('hanoi')) city = 'Hanoi';
                                  else if (textLower.contains('milan')) city = 'Milan';
                                  else if (textLower.contains('new york')) city = 'New York';
                                  else if (textLower.contains('dubai')) city = 'Dubai';
                                  else if (textLower.contains('costa rica')) city = 'Costa Rica';
                                  else if (textLower.contains('serengeti')) city = 'Serengeti';

                                  ref.read(userProfileProvider.notifier).updateUserProfile({
                                    'city': city,
                                    'upcomingTrip': {
                                      'city': city,
                                      'startDate': picked.start.toIso8601String().substring(0, 10),
                                      'endDate': picked.end.toIso8601String().substring(0, 10),
                                    }
                                  });

                                  _startCompilation(customDestination: city);
                                }
                              },
                              icon: const Icon(Icons.calendar_month, size: 14),
                              label: const Text(
                                'Save to Trips',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              msg.timestamp,
                              style: TextStyle(
                                fontSize: 9, 
                                color: isUser ? Colors.white70 : Colors.white54,
                              ),
                            ),
                          )
                        ],
                      ),
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: isUser
                          ? Align(
                              alignment: Alignment.centerRight,
                              child: bubbleContent,
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8, top: 4),
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF2563EB), Color(0xFFFF477E)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: bubbleContent,
                                  ),
                                ),
                              ],
                            ),
                    );
                  },
                ),
              ),

              // Suggestion presets bar (custom styled action chips)
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _presetChip('🍴 Delhi Food?'),
                    const SizedBox(width: 8),
                    _presetChip('⛰️ Manali Snow?'),
                    const SizedBox(width: 8),
                    _presetChip('🍵 Assam Tea?'),
                  ],
                ),
              ),

              // Premium message input bar (Solid Dark Blue container matching themes)
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2744),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFF334155)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _chatInput,
                          enabled: !_chatTyping,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: _chatTyping ? 'Aira is thinking...' : 'Ask about flights, hotels, or trips...',
                            hintStyle: TextStyle(color: Colors.white30, fontSize: 12, fontStyle: FontStyle.italic),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (v) => _sendMessage(v),
                        ),
                      ),
                      const Icon(Icons.mic, color: Colors.white70, size: 20),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _sendMessage(_chatInput.text),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFFFF477E)],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Generating / Compiler Overlay
          if (_isGenerating) _buildCompilationOverlay(),
        ],
      ),
    );
  }

  Widget _presetChip(String txt) {
    return ActionChip(
      backgroundColor: const Color(0xFF1A2744),
      side: const BorderSide(color: Color(0xFF334155)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      label: Text(txt, style: const TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.bold)),
      onPressed: () => _sendMessage(txt),
    );
  }

  Widget _buildCompilationOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0A1628).withValues(alpha: 0.95),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF2563EB), size: 50),
            const SizedBox(height: 24),
            const Text(
              'COMPILING TRAVEL SCENARIO',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              '$_genProgress%',
              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _genProgress / 100.0,
                backgroundColor: Colors.white12,
                color: const Color(0xFF2563EB),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _genStage,
              style: const TextStyle(color: Color(0xFF2563EB), fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
