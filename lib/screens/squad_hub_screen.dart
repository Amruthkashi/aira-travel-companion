import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/travel_models.dart';
import '../core/providers/travel_providers.dart';
import '../core/services/ai_service.dart';

class SquadHubScreen extends ConsumerStatefulWidget {
  final String squadId;
  const SquadHubScreen({super.key, required this.squadId});

  @override
  ConsumerState<SquadHubScreen> createState() => _SquadHubScreenState();
}

class _SquadHubScreenState extends ConsumerState<SquadHubScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _squad;
  bool _loading = true;
  String? _error;

  // Chat
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  Timer? _pollTimer;
  String? _lastMessageTimestamp;

  // Expense form
  final TextEditingController _expDescController = TextEditingController();
  final TextEditingController _expAmountController = TextEditingController();

  // Poll form
  final TextEditingController _pollQuestionController = TextEditingController();
  final List<TextEditingController> _pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  // AI Suggestions
  List<Map<String, dynamic>> _aiSuggestions = [];
  bool _loadingAi = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadSquad();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    _expDescController.dispose();
    _expAmountController.dispose();
    _pollQuestionController.dispose();
    for (var c in _pollOptionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSquad() async {
    try {
      final data = await AiService.getSquadDetails(widget.squadId);
      if (mounted) {
        setState(() {
          _squad = data;
          _messages.clear();
          final msgs = data['messages'] as List? ?? [];
          for (var m in msgs) {
            _messages.add(Map<String, dynamic>.from(m));
          }
          if (_messages.isNotEmpty) {
            _lastMessageTimestamp = _messages.last['timestamp'];
          }
          _loading = false;
        });
        _startPolling();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      try {
        final newMsgs = await AiService.getSquadMessages(widget.squadId, since: _lastMessageTimestamp);
        if (newMsgs.isNotEmpty && mounted) {
          setState(() {
            for (var m in newMsgs) {
              if (!_messages.any((e) => e['id'] == m['id'])) {
                _messages.add(m);
              }
            }
            _lastMessageTimestamp = _messages.last['timestamp'];
          });
          _scrollToBottom();
        }
        // Also refresh squad data for expenses/polls
        final data = await AiService.getSquadDetails(widget.squadId);
        if (mounted) {
          setState(() => _squad = data);
        }
      } catch (_) {}
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    final profile = ref.read(userProfileProvider).profile;
    final userIdVal = profile['id'] ?? profile['email'] ?? '';
    final userId = userIdVal.toString().trim().isEmpty ? 'shreyas' : userIdVal;
    final userNameVal = profile['fullName'] ?? '';
    final userName = userNameVal.toString().trim().isEmpty ? 'Shreyas Aswini' : userNameVal;

    _chatController.clear();

    // Instant local echo to update UI instantly!
    final temporaryId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final timestamp = DateTime.now().toIso8601String();
    final tempMsg = {
      'id': temporaryId,
      'senderId': userId,
      'senderName': userName,
      'text': text,
      'type': 'text',
      'timestamp': timestamp,
    };
    
    setState(() {
      _messages.add(tempMsg);
      _lastMessageTimestamp = timestamp;
    });
    _scrollToBottom();

    try {
      final actualMsg = await AiService.sendSquadMessage(widget.squadId, {
        'senderId': userId,
        'senderName': userName,
        'text': text,
        'type': 'text',
      });
      if (actualMsg != null && mounted) {
        setState(() {
          // Replace temp message with server message to get final id/timestamp
          final idx = _messages.indexWhere((m) => m['id'] == temporaryId);
          if (idx != -1) {
            _messages[idx] = actualMsg;
          } else {
            _messages.add(actualMsg);
          }
          _lastMessageTimestamp = actualMsg['timestamp'];
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<void> _addExpense() async {
    final desc = _expDescController.text.trim();
    final amountStr = _expAmountController.text.trim();
    if (desc.isEmpty || amountStr.isEmpty) return;
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return;

    final profile = ref.read(userProfileProvider).profile;
    final userIdVal = profile['id'] ?? profile['email'] ?? '';
    final userId = userIdVal.toString().trim().isEmpty ? 'shreyas' : userIdVal;
    final userNameVal = profile['fullName'] ?? '';
    final userName = userNameVal.toString().trim().isEmpty ? 'Shreyas Aswini' : userNameVal;
    final members = (_squad?['members'] as List?)?.map((m) => m['userId'].toString()).toList() ?? [];

    try {
      final res = await AiService.addSquadExpense(widget.squadId, {
        'description': desc,
        'amount': amount,
        'currency': 'USD',
        'paidBy': userId,
        'paidByName': userName,
        'splitAmong': members,
      });

      _expDescController.clear();
      _expAmountController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Expense "$desc" added!'), backgroundColor: const Color(0xFF06D6A0)),
        );
      }

      if (res != null) {
        await _loadSquad(); // Refresh details instantly!
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding expense: ${e.toString().replaceFirst('Exception: ', '')}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _createPoll() async {
    final question = _pollQuestionController.text.trim();
    final options = _pollOptionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    if (question.isEmpty || options.length < 2) return;

    final profile = ref.read(userProfileProvider).profile;
    final userIdVal = profile['id'] ?? profile['email'] ?? '';
    final userId = userIdVal.toString().trim().isEmpty ? 'shreyas' : userIdVal;
    final userNameVal = profile['fullName'] ?? '';
    final userName = userNameVal.toString().trim().isEmpty ? 'Shreyas Aswini' : userNameVal;

    try {
      final res = await AiService.createSquadPoll(widget.squadId, {
        'question': question,
        'options': options,
        'createdBy': userId,
        'createdByName': userName,
      });

      _pollQuestionController.clear();
      for (var c in _pollOptionControllers) {
        c.clear();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Poll created!'), backgroundColor: Color(0xFF2563EB)),
        );
      }

      if (res != null) {
        await _loadSquad(); // Refresh details instantly!
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating poll: ${e.toString().replaceFirst('Exception: ', '')}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _voteOnPoll(String pollId, int optionIndex) async {
    final profile = ref.read(userProfileProvider).profile;
    final userIdVal = profile['id'] ?? profile['email'] ?? '';
    final userId = userIdVal.toString().trim().isEmpty ? 'shreyas' : userIdVal;
    try {
      final res = await AiService.voteOnPoll(widget.squadId, pollId, optionIndex, userId);
      if (res != null && mounted) {
        await _loadSquad(); // Refresh details instantly!
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error voting: ${e.toString().replaceFirst('Exception: ', '')}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _loadAiSuggestions() async {
    setState(() => _loadingAi = true);
    final suggestions = await AiService.getSquadAiSuggestions(widget.squadId);
    if (mounted) {
      setState(() {
        _aiSuggestions = suggestions;
        _loadingAi = false;
      });
    }
  }

  void _addSuggestionToPersonalItinerary(Map<String, dynamic> s) {
    final itinerary = ref.read(itineraryProvider);
    if (itinerary.isEmpty) {
      ref.read(itineraryProvider.notifier).setItinerary([
        ItineraryDay(day: 1, theme: 'Custom Trip Plan', activities: [])
      ]);
      _executeAddActivity(0, s);
      return;
    }
    
    if (itinerary.length == 1) {
      _executeAddActivity(0, s);
      return;
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2744),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Itinerary Day', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: itinerary.length,
                  itemBuilder: (context, index) {
                    final day = itinerary[index];
                    return ListTile(
                      title: Text('Day ${day.day} - ${day.theme}', style: const TextStyle(color: Colors.white70)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white30),
                      onTap: () {
                        Navigator.pop(ctx);
                        _executeAddActivity(index, s);
                      },
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

  void _executeAddActivity(int dayIndex, Map<String, dynamic> s) {
    final activityItem = ActivityItem(
      time: s['bestTimeOfDay'] ?? '10:00 AM',
      activity: s['activity'] ?? 'AI Selected Place',
      description: s['description'] ?? '',
      cost: s['estimatedCost'] ?? 'Free',
      locationName: _squad?['destination'] ?? 'Tokyo',
      suggestedAttire: 'Casual, comfortable shoes',
      placeDetails: s['groupTip'] ?? '',
    );
    ref.read(itineraryProvider.notifier).addActivity(dayIndex, activityItem);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${s['activity']}" to Day ${dayIndex + 1} of your Personal Itinerary! 📅'),
        backgroundColor: const Color(0xFF06D6A0),
      ),
    );
  }

  Future<void> _addSuggestionToSquadBookings(Map<String, dynamic> s) async {
    final profile = ref.read(userProfileProvider).profile;
    final userIdVal = profile['id'] ?? profile['email'] ?? '';
    final userId = userIdVal.toString().trim().isEmpty ? 'shreyas' : userIdVal;
    final userNameVal = profile['fullName'] ?? '';
    final userName = userNameVal.toString().trim().isEmpty ? 'Shreyas Aswini' : userNameVal;

    try {
      await AiService.addSquadBooking(widget.squadId, {
        'type': 'activity',
        'title': s['activity'] ?? 'AI Selected Place',
        'confirmationCode': 'AI-SUGG-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        'dateTime': s['bestTimeOfDay'] ?? 'flexible',
        'details': s['description'] ?? '',
        'notes': s['groupTip'] ?? '',
        'createdBy': userId,
        'createdByName': userName,
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${s['activity']}" to Squad Bookings & Activities! 🚢'),
          backgroundColor: const Color(0xFF00B4D8),
        ),
      );
      
      await _loadSquad();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to squad bookings: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  String _getMemberColor(String? userId) {
    final members = (_squad?['members'] as List?) ?? [];
    for (var m in members) {
      if (m['userId'] == userId) return m['avatarColor'] ?? '#6366F1';
    }
    return '#6366F1';
  }

  int _daysUntilTrip() {
    final start = _squad?['startDate'] ?? '';
    if (start.isEmpty) return 0;
    try {
      final date = DateTime.parse(start);
      return date.difference(DateTime.now()).inDays;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF020617),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7B2FF7)]),
                  boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.4), blurRadius: 20)],
                ),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Loading Squad...', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    if (_error != null || _squad == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF020617),
        appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white),
        body: Center(child: Text(_error ?? 'Squad not found', style: const TextStyle(color: Colors.red))),
      );
    }

    final squad = _squad!;
    final members = (squad['members'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFF0A1628),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Aurora gradient background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0A1628), Color(0xFF0A1628), Color(0xFF0D1B2A)],
                      ),
                    ),
                  ),
                  // Mesh overlay circles
                  Positioned(top: -40, right: -30, child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF2563EB).withValues(alpha: 0.15)))),
                  Positioned(bottom: 20, left: -20, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF00B4D8).withValues(alpha: 0.12)))),
                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 80, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7B2FF7)]),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('${members.length} Members', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            if (_daysUntilTrip() > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF00B4D8), Color(0xFF06D6A0)]),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('${_daysUntilTrip()} days away', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(squad['name'] ?? 'My Squad', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFFFFD166), size: 16),
                            const SizedBox(width: 4),
                            Text(squad['destination'] ?? '', style: const TextStyle(color: Color(0xFFFFD166), fontSize: 14, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            if (squad['startDate'] != null && squad['startDate'].toString().isNotEmpty)
                              Text('${squad['startDate']} → ${squad['endDate'] ?? ''}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Member avatars row
                        Row(
                          children: [
                            ...members.take(8).map((m) {
                              final color = Color(int.parse((m['avatarColor'] ?? '#6366F1').replaceFirst('#', '0xFF')));
                              return Container(
                                width: 32, height: 32,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color,
                                  border: Border.all(color: const Color(0xFF020617), width: 2),
                                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)],
                                ),
                                child: Center(child: Text((m['fullName'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                              );
                            }),
                            if (members.length > 8)
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)),
                                child: Center(child: Text('+${members.length - 8}', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold))),
                              ),
                            const Spacer(),
                            // Invite code button
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: squad['inviteCode'] ?? ''));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Invite code "${squad['inviteCode']}" copied!'), backgroundColor: const Color(0xFF2563EB)),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.copy, color: Colors.white70, size: 14),
                                    const SizedBox(width: 4),
                                    Text(squad['inviteCode'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF2563EB),
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              tabs: const [
                Tab(icon: Icon(Icons.chat_bubble, size: 16), text: 'Chat'),
                Tab(icon: Icon(Icons.receipt_long, size: 16), text: 'Expenses'),
                Tab(icon: Icon(Icons.airplane_ticket, size: 16), text: 'Bookings'),
                Tab(icon: Icon(Icons.poll, size: 16), text: 'Polls'),
                Tab(icon: Icon(Icons.auto_awesome, size: 16), text: 'AI Ideas'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildChatTab(),
            _buildExpensesTab(),
            _buildBookingsTab(),
            _buildPollsTab(),
            _buildAiTab(),
          ],
        ),
      ),
    );
  }

  // ======== CHAT TAB ========
  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isSystem = msg['type'] == 'system' || msg['type'] == 'expense' || msg['type'] == 'poll';
              final profile = ref.read(userProfileProvider).profile;
              final myIdVal = profile['id'] ?? profile['email'] ?? '';
              final myId = myIdVal.toString().trim().isEmpty ? 'shreyas' : myIdVal;
              final isMe = msg['senderId'] == myId;

              if (isSystem) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2744).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white60, fontSize: 12), textAlign: TextAlign.center),
                    ),
                  ),
                );
              }

              final avatarColor = Color(int.parse(_getMemberColor(msg['senderId']).replaceFirst('#', '0xFF')));
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (!isMe) ...[
                      Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: avatarColor),
                        child: Center(child: Text((msg['senderName'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF2563EB) : const Color(0xFF1A2744),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(msg['senderName'] ?? '', style: TextStyle(color: avatarColor, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Message input
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: const BoxDecoration(
            color: Color(0xFF0A1628),
            border: Border(top: BorderSide(color: Color(0xFF1A2744))),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2744),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Message your squad...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7B2FF7)]),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.4), blurRadius: 8)],
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ======== EXPENSES TAB ========
  Widget _buildExpensesTab() {
    final expenses = (_squad?['expenses'] as List?) ?? [];
    final members = (_squad?['members'] as List?) ?? [];

    // Calculate balances
    Map<String, double> balances = {};
    for (var m in members) {
      balances[m['userId']] = 0;
    }
    for (var exp in expenses) {
      final amount = (exp['amount'] as num?)?.toDouble() ?? 0;
      final paidBy = exp['paidBy'] ?? '';
      final splitAmong = (exp['splitAmong'] as List?) ?? [];
      if (splitAmong.isEmpty) continue;
      final perPerson = amount / splitAmong.length;
      balances[paidBy] = (balances[paidBy] ?? 0) + amount - perPerson;
      for (var uid in splitAmong) {
        if (uid != paidBy) {
          balances[uid.toString()] = (balances[uid.toString()] ?? 0) - perPerson;
        }
      }
    }

    double totalSpent = 0;
    for (var exp in expenses) {
      totalSpent += (exp['amount'] as num?)?.toDouble() ?? 0;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Total card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A1628), Color(0xFF312E81)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              const Text('TOTAL GROUP SPEND', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 6),
              Text('\$${totalSpent.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('${expenses.length} expenses · ${members.length} members', style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Balances
        if (balances.isNotEmpty) ...[
          const Text('WHO OWES WHOM', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          ...balances.entries.map((e) {
            final member = members.firstWhere((m) => m['userId'] == e.key, orElse: () => {'fullName': 'Unknown', 'avatarColor': '#6366F1'});
            final name = member['fullName'] ?? 'Unknown';
            final color = Color(int.parse((member['avatarColor'] ?? '#6366F1').replaceFirst('#', '0xFF')));
            final bal = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2744).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                    child: Center(child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
                  Text(
                    bal >= 0 ? '+\$${bal.toStringAsFixed(2)}' : '-\$${bal.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      color: bal >= 0 ? const Color(0xFF06D6A0) : const Color(0xFFEF4444),
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Add expense form
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2744).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('LOG NEW EXPENSE', style: TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              TextField(
                controller: _expDescController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'What was it for?',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF0A1628),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _expAmountController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Amount (USD)',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF0A1628),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  prefixText: '\$ ',
                  prefixStyle: const TextStyle(color: Color(0xFF06D6A0), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addExpense,
                  icon: const Icon(Icons.add_circle, size: 18),
                  label: const Text('Split Among All', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06D6A0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Expense history
        if (expenses.isNotEmpty) ...[
          const Text('EXPENSE HISTORY', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          ...expenses.reversed.take(20).map((exp) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1628),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt, color: Color(0xFFFFD166), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exp['description'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('Paid by ${exp['paidByName'] ?? ''}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text('\$${((exp['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFFFD166), fontWeight: FontWeight.w900, fontSize: 15)),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  // ======== POLLS TAB ========
  Widget _buildPollsTab() {
    final polls = (_squad?['polls'] as List?) ?? [];
    final profile = ref.read(userProfileProvider).profile;
    final myIdVal = profile['id'] ?? profile['email'] ?? '';
    final myId = myIdVal.toString().trim().isEmpty ? 'shreyas' : myIdVal;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Create poll form
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2744).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF7B2FF7).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CREATE A POLL', style: TextStyle(color: Color(0xFF7B2FF7), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              TextField(
                controller: _pollQuestionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'What should we decide?',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF0A1628),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(_pollOptionControllers.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: TextField(
                    controller: _pollOptionControllers[i],
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Option ${i + 1}',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: const Color(0xFF0A1628),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                );
              }),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      if (_pollOptionControllers.length < 6) {
                        setState(() => _pollOptionControllers.add(TextEditingController()));
                      }
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Option', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF7B2FF7)),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _createPoll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B2FF7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Create Poll', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Active polls
        if (polls.isNotEmpty)
          const Text('ACTIVE POLLS', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        ...polls.reversed.map((poll) {
          final totalVotes = (poll['options'] as List).fold<int>(0, (sum, o) => sum + ((o['votes'] as List?)?.length ?? 0));
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2744).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.poll, color: Color(0xFF7B2FF7), size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(poll['question'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
                  ],
                ),
                const SizedBox(height: 4),
                Text('by ${poll['createdByName'] ?? ''} · $totalVotes votes', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 12),
                ...List.generate((poll['options'] as List).length, (i) {
                  final opt = poll['options'][i];
                  final votes = (opt['votes'] as List?)?.length ?? 0;
                  final pct = totalVotes > 0 ? votes / totalVotes : 0.0;
                  final voted = (opt['votes'] as List?)?.contains(myId) ?? false;
                  return GestureDetector(
                    onTap: () => _voteOnPoll(poll['id'], i),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A1628),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: voted ? const Color(0xFF2563EB) : Colors.white.withValues(alpha: 0.06), width: voted ? 2 : 1),
                            ),
                            child: Row(
                              children: [
                                if (voted) const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 16),
                                if (voted) const SizedBox(width: 6),
                                Expanded(child: Text(opt['text'] ?? '', style: TextStyle(color: voted ? const Color(0xFF2563EB) : Colors.white, fontWeight: voted ? FontWeight.bold : FontWeight.normal, fontSize: 13))),
                                Text('$votes', style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 0, top: 0, bottom: 0,
                            child: Container(
                              width: (MediaQuery.of(context).size.width - 64) * pct,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
        const SizedBox(height: 40),
      ],
    );
  }

  // ======== AI IDEAS TAB ========
  Widget _buildAiTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A1628), Color(0xFF312E81), Color(0xFF0A1628)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7B2FF7), Color(0xFFFF477E)]),
                  boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.5), blurRadius: 16)],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 12),
              const Text('AI Group Concierge', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                'Get personalized activity suggestions for your squad of ${(_squad?['members'] as List?)?.length ?? 0} traveling to ${_squad?['destination'] ?? 'unknown'}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loadingAi ? null : _loadAiSuggestions,
                  icon: _loadingAi ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(_loadingAi ? 'Thinking...' : 'Generate Group Ideas', style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // AI Suggestions
        ..._aiSuggestions.map((s) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2744).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_activity, color: Color(0xFF00B4D8), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(s['activity'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(s['description'] ?? '', style: const TextStyle(color: Colors.white60, fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    if (s['estimatedCost'] != null)
                      _aiChip(Icons.attach_money, s['estimatedCost'], const Color(0xFF06D6A0)),
                    if (s['bestTimeOfDay'] != null)
                      _aiChip(Icons.schedule, s['bestTimeOfDay'], const Color(0xFFFFD166)),
                  ],
                ),
                if (s['groupTip'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B4D8).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00B4D8).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tips_and_updates, color: Color(0xFF00B4D8), size: 16),
                        const SizedBox(width: 6),
                        Expanded(child: Text(s['groupTip'], style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 12))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _addSuggestionToPersonalItinerary(s),
                      icon: const Icon(Icons.calendar_today, size: 12, color: Colors.white),
                      label: const Text('Add to Itinerary', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _addSuggestionToSquadBookings(s),
                      icon: const Icon(Icons.group_add, size: 12, color: Color(0xFF00B4D8)),
                      label: const Text('Add to Squad', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00B4D8))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF00B4D8)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _aiChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ======== BOOKINGS & TICKETS TAB ========
  Widget _buildBookingsTab() {
    final bookings = (_squad?['bookings'] as List?) ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SQUAD TICKETS & BOOKINGS',
              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            ElevatedButton.icon(
              onPressed: _showAddBookingModal,
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: const Text('Add Ticket', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (bookings.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2744).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                const Icon(Icons.airplane_ticket, color: Color(0xFF00B4D8), size: 48),
                const SizedBox(height: 12),
                const Text('No bookings logged yet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                const Text(
                  'Share flights, hotel stays, or event vouchers so everyone is on the same page.',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _showAddBookingModal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.2),
                    foregroundColor: const Color(0xFF00B4D8),
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Log First Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )
        else
          ...bookings.map((book) {
            final type = book['type'] ?? 'flight';
            final title = book['title'] ?? '';
            final code = book['confirmationCode'] ?? '';
            final dateStr = book['dateTime'] ?? '';
            final details = book['details'] ?? '';
            final notes = book['notes'] ?? '';
            final addedBy = book['createdByName'] ?? 'Member';

            IconData icon = Icons.airplane_ticket;
            Color accentColor = const Color(0xFF2563EB);
            if (type == 'hotel') {
              icon = Icons.hotel;
              accentColor = const Color(0xFF06D6A0);
            } else if (type == 'transport') {
              icon = Icons.directions_train;
              accentColor = const Color(0xFFFFD166);
            } else if (type == 'attraction') {
              icon = Icons.local_activity;
              accentColor = const Color(0xFFFF477E);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1628),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: accentColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text('Added by $addedBy', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            code,
                            style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(width: 6, height: 12, decoration: const BoxDecoration(color: Color(0xFF020617), borderRadius: BorderRadius.horizontal(right: Radius.circular(6)))),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Flex(
                              direction: Axis.horizontal,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                (constraints.constrainWidth() / 8).floor(),
                                (index) => SizedBox(width: 4, height: 1, child: DecoratedBox(decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15)))),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(width: 6, height: 12, decoration: const BoxDecoration(color: Color(0xFF020617), borderRadius: BorderRadius.horizontal(left: Radius.circular(6)))),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.schedule, color: Colors.white54, size: 14),
                                const SizedBox(width: 6),
                                Text(dateStr, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Text(details, style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (notes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: Text(
                              notes,
                              style: const TextStyle(color: Colors.white60, fontSize: 11.5, height: 1.3),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          height: 24,
                          width: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              28,
                              (idx) {
                                final w = (idx % 3 == 0) ? 3.0 : ((idx % 4 == 0) ? 1.0 : 2.0);
                                final s = (idx % 5 == 0) ? 2.5 : 1.5;
                                return Container(
                                  width: w,
                                  height: double.infinity,
                                  margin: EdgeInsets.only(right: s),
                                  color: Colors.white.withValues(alpha: idx % 6 == 0 ? 0.05 : 0.25),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _showAddBookingModal() {
    final titleCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: '2026-07-15 10:00 AM');
    final detailsCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String selectedType = 'flight';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A1628),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 16),
                    const Text('LOG GROUP BOOKING', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    const Text('Add flight, hotel, or attraction tickets for the group', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 16),
                    
                    const Text('Booking Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2744),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedType,
                          dropdownColor: const Color(0xFF0A1628),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          items: const [
                            DropdownMenuItem(value: 'flight', child: Row(children: [Icon(Icons.flight, color: Color(0xFF00B4D8), size: 16), SizedBox(width: 8), Text('Flight Ticket ✈️')])),
                            DropdownMenuItem(value: 'hotel', child: Row(children: [Icon(Icons.hotel, color: Color(0xFF06D6A0), size: 16), SizedBox(width: 8), Text('Hotel Stay 🏨')])),
                            DropdownMenuItem(value: 'transport', child: Row(children: [Icon(Icons.directions_train, color: Color(0xFFFFD166), size: 16), SizedBox(width: 8), Text('Train/Commute 🚄')])),
                            DropdownMenuItem(value: 'attraction', child: Row(children: [Icon(Icons.local_activity, color: Color(0xFFFF477E), size: 16), SizedBox(width: 8), Text('Attraction Ticket 🎟️')])),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                selectedType = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _bookingField('Booking Title (e.g. Flight to Tokyo)', titleCtrl),
                    _bookingField('Confirmation / PNR Code (e.g. NH-782Y9W)', codeCtrl),
                    _bookingDateTimeField(modalCtx, 'Date & Time (YYYY-MM-DD HH:MM)', dateCtrl),
                    _bookingField('Seat, Room, or Ticket details (e.g. Seat 14A, 3 passes)', detailsCtrl),
                    _bookingField('Notes / Info (Optional)', notesCtrl, maxLines: 2),
                    
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF334155)),
                              foregroundColor: Colors.white70,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              final title = titleCtrl.text.trim();
                              final code = codeCtrl.text.trim();
                              final date = dateCtrl.text.trim();
                              final details = detailsCtrl.text.trim();
                              if (title.isEmpty || code.isEmpty || date.isEmpty || details.isEmpty) return;

                              final profile = ref.read(userProfileProvider).profile;
                              final userIdVal = profile['id'] ?? profile['email'] ?? '';
                              final userId = userIdVal.toString().trim().isEmpty ? 'shreyas' : userIdVal;
                              final userNameVal = profile['fullName'] ?? '';
                              final userName = userNameVal.toString().trim().isEmpty ? 'Shreyas Aswini' : userNameVal;

                              await AiService.addSquadBooking(widget.squadId, {
                                'type': selectedType,
                                'title': title,
                                'confirmationCode': code,
                                'dateTime': date,
                                'details': details,
                                'notes': notesCtrl.text.trim(),
                                'createdBy': userId,
                                'createdByName': userName,
                              });

                              Navigator.pop(ctx);
                              _loadSquad();
                            },
                            child: const Text('Add to Squad', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _bookingField(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFF1A2744),
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookingDateTimeField(BuildContext context, String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            readOnly: true,
            onTap: () async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Color(0xFF2563EB), // Royal Blue
                        onPrimary: Colors.white,
                        surface: Color(0xFF1A2744),
                        onSurface: Colors.white,
                      ),
                      dialogBackgroundColor: const Color(0xFF0A1628),
                      datePickerTheme: DatePickerThemeData(
                        backgroundColor: const Color(0xFF0A1628),
                        headerBackgroundColor: const Color(0xFF1E293B),
                        headerForegroundColor: Colors.white,
                        rangePickerHeaderBackgroundColor: const Color(0xFF1E293B),
                        rangePickerHeaderForegroundColor: Colors.white,
                        confirmButtonStyle: ButtonStyle(
                          foregroundColor: WidgetStateProperty.all(const Color(0xFF60A5FA)),
                          textStyle: WidgetStateProperty.all(const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        cancelButtonStyle: ButtonStyle(
                          foregroundColor: WidgetStateProperty.all(const Color(0xFF94A3B8)),
                          textStyle: WidgetStateProperty.all(const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (pickedDate != null && context.mounted) {
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: Color(0xFF2563EB),
                          onPrimary: Colors.white,
                          surface: Color(0xFF1A2744),
                          onSurface: Colors.white,
                        ),
                        dialogBackgroundColor: const Color(0xFF0A1628),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedTime != null) {
                  final y = pickedDate.year;
                  final m = pickedDate.month.toString().padLeft(2, '0');
                  final d = pickedDate.day.toString().padLeft(2, '0');
                  final hr = pickedTime.hour.toString().padLeft(2, '0');
                  final min = pickedTime.minute.toString().padLeft(2, '0');
                  ctrl.text = '$y-$m-$d $hr:$min';
                }
              }
            },
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFF1A2744),
              hintText: 'Tap to select date & time',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
              suffixIcon: const Icon(Icons.calendar_month, color: Color(0xFF2563EB), size: 16),
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB))),
            ),
          ),
        ],
      ),
    );
  }
}
