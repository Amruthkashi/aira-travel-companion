import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/theme_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/travel_providers.dart';

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
          debugPrint('Error parsing dates for chat compilation: $e');
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
    final isDark = ref.watch(isDarkProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent to show parent's gradient background
      appBar: AppBar(
        backgroundColor: TriaColors.cardBg(isDark).withValues(alpha: 0.85),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: TriaColors.textPrimary(isDark)),
          onPressed: () {
            ref.read(currentTabProvider.notifier).state = 0; // Go back to Home tab
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFFFF6B35), Color(0xFFFF477E)]
                      : const [Color(0xFF2563EB), Color(0xFF00B4D8)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'TRIA AI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Tria Concierge',
              style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.auto_awesome, color: isDark ? const Color(0xFFFF6B35) : const Color(0xFF2563EB)),
            onPressed: () => _startCompilation(),
          )
        ],
      ),
      body: Stack(
        children: [
          // Chat Feed Column & Translucent bubbles
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: chatMessages.length + (_chatTyping ? 1 : 0),
                  itemBuilder: (context, idx) {
                    if (idx == chatMessages.length) {
                      // Tria is typing container with avatar
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
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? const [Color(0xFFFF6B35), Color(0xFFFF477E)]
                                      : const [Color(0xFF2563EB), Color(0xFF00B4D8)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark ? const Color(0xFFFF6B35) : const Color(0xFF2563EB)).withValues(alpha: 0.3),
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
                                    color: TriaColors.cardBg(isDark).withValues(alpha: 0.85),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                    border: Border.all(color: TriaColors.border(isDark).withValues(alpha: 0.4)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          color: isDark ? Color(0xFFFF6B35) : Color(0xFF2563EB),
                                          strokeWidth: 1.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Tria is typing...",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: TriaColors.textSecondary(isDark),
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
                    final showSaveButton = false;

                    final bubbleContent = Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isUser
                            ? LinearGradient(
                                colors: isDark
                                    ? const [Color(0xFFFF6B35), Color(0xFFFF477E)]
                                    : const [Color(0xFF2563EB), Color(0xFF00B4D8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isUser ? null : TriaColors.cardBg(isDark).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                          bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                        ),
                        border: isUser
                            ? null
                            : Border.all(color: TriaColors.border(isDark).withValues(alpha: 0.4), width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
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
                              color: isUser ? Colors.white : TriaColors.textPrimary(isDark),
                            ),
                          ),
                          if (showSaveButton) ...[
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFFFF6B35) : const Color(0xFF2563EB),
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
                                      data: isDark
                                          ? ThemeData.dark().copyWith(
                                              colorScheme: ColorScheme.dark(
                                                primary: isDark ? const Color(0xFFFF6B35) : const Color(0xFF2563EB),
                                                onPrimary: Colors.white,
                                                surface: Color(0xFF0A1628),
                                                onSurface: Colors.white,
                                              ),
                                              datePickerTheme: const DatePickerThemeData(
                                                backgroundColor: Color(0xFF0A1628),
                                                headerBackgroundColor: Color(0xFF1E293B),
                                                headerForegroundColor: Colors.white,
                                                rangePickerHeaderBackgroundColor: Color(0xFF1E293B),
                                                rangePickerHeaderForegroundColor: Colors.white,
                                              ),
                                            )
                                          : ThemeData.light().copyWith(
                                              colorScheme: ColorScheme.light(
                                                primary: isDark ? const Color(0xFFFF6B35) : const Color(0xFF2563EB),
                                                onPrimary: Colors.white,
                                                surface: Colors.white,
                                                onSurface: Colors.black87,
                                              ),
                                              datePickerTheme: const DatePickerThemeData(
                                                backgroundColor: Colors.white,
                                                headerBackgroundColor: Color(0xFFF1F5F9),
                                                headerForegroundColor: Colors.black87,
                                                rangePickerHeaderBackgroundColor: Color(0xFFF1F5F9),
                                                rangePickerHeaderForegroundColor: Colors.black87,
                                              ),
                                            ),
                                      child: child!,
                                    );
                                  },
                                );

                                if (picked != null) {
                                  final textLower = msg.text.toLowerCase();
                                  final cities = {
                                    'kyoto': 'Kyoto',
                                    'tokyo': 'Tokyo',
                                    'shibuya': 'Crossing District',
                                    'paris': 'Paris',
                                    'rome': 'Rome',
                                    'bali': 'Bali',
                                    'london': 'London',
                                    'barcelona': 'Barcelona',
                                    'santorini': 'Santorini',
                                    'amalfi': 'Amalfi Coast',
                                    'venice': 'Venice',
                                    'orlando': 'Orlando',
                                    'bangkok': 'Bangkok',
                                    'hanoi': 'Hanoi',
                                    'milan': 'Milan',
                                    'new york': 'New York',
                                    'dubai': 'Dubai',
                                    'costa rica': 'Costa Rica',
                                    'serengeti': 'Serengeti',
                                  };
                                  String city = 'Kyoto';
                                  for (final entry in cities.entries) {
                                    if (textLower.contains(entry.key)) {
                                      city = entry.value;
                                      break;
                                    }
                                  }

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
                                color: isUser ? Colors.white70 : TriaColors.textMuted(isDark),
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
                                    gradient: LinearGradient(
                                      colors: isDark
                                          ? const [Color(0xFFFF6B35), Color(0xFFFF477E)]
                                          : const [Color(0xFF2563EB), Color(0xFF00B4D8)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isDark ? const Color(0xFFFF6B35) : const Color(0xFF2563EB)).withValues(alpha: 0.3),
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

              // Suggestion presets bar
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _presetChip('🍴 Recommend local food spots', isDark),
                    const SizedBox(width: 8),
                    _presetChip('⛰️ Scenic hiking trails', isDark),
                    const SizedBox(width: 8),
                    _presetChip('🏛️ Historical museum options', isDark),
                  ],
                ),
              ),

              // Premium message input bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: TriaColors.cardBg(isDark).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: TriaColors.border(isDark).withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
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
                          style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 13),
                          decoration: InputDecoration(
                            hintText: _chatTyping ? 'Tria is thinking...' : 'Ask about flights, hotels, or trips...',
                            hintStyle: TextStyle(color: TriaColors.textMuted(isDark), fontSize: 12, fontStyle: FontStyle.italic),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (v) => _sendMessage(v),
                        ),
                      ),
                      Icon(Icons.mic, color: TriaColors.iconDefault(isDark), size: 20),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _sendMessage(_chatInput.text),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: isDark
                                  ? const [Color(0xFFFF6B35), Color(0xFFFF477E)]
                                  : const [Color(0xFF2563EB), Color(0xFF00B4D8)],
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
          if (_isGenerating) _buildCompilationOverlay(isDark),
        ],
      ),
    );
  }

  Widget _presetChip(String txt, bool isDark) {
    return ActionChip(
      backgroundColor: TriaColors.cardBg(isDark).withValues(alpha: 0.85),
      side: BorderSide(color: TriaColors.border(isDark).withValues(alpha: 0.5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      label: Text(txt, style: TextStyle(color: isDark ? const Color(0xFFFF6B35) : const Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.bold)),
      onPressed: () => _sendMessage(txt),
    );
  }

  Widget _buildCompilationOverlay(bool isDark) {
    return Positioned.fill(
      child: Container(
        color: TriaColors.scaffoldBg(isDark).withValues(alpha: 0.95),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: isDark ? const Color(0xFFFF6B35) : const Color(0xFF2563EB), size: 50),
            const SizedBox(height: 24),
            Text(
              'COMPILING TRAVEL SCENARIO',
              style: TextStyle(color: TriaColors.textSecondary(isDark), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              '$_genProgress%',
              style: TextStyle(color: TriaColors.textPrimary(isDark), fontSize: 36, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _genProgress / 100.0,
                backgroundColor: isDark ? Colors.white12 : Colors.black12,
                color: isDark ? const Color(0xFFFF6B35) : const Color(0xFF2563EB),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _genStage,
              style: TextStyle(color: isDark ? const Color(0xFFFF6B35) : const Color(0xFF2563EB), fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}