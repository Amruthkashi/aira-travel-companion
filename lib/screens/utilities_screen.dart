import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/travel_providers.dart';
import '../core/utils/sound_synthesizer.dart';

class UtilitiesScreen extends ConsumerStatefulWidget {
  const UtilitiesScreen({super.key});

  @override
  ConsumerState<UtilitiesScreen> createState() => _UtilitiesScreenState();
}

class _UtilitiesScreenState extends ConsumerState<UtilitiesScreen> {
  // Vocabulary trainer state
  final List<String> _englishWords = ['Excuse me', 'Water', 'Check please', 'Thank you'];
  final List<String> _synonymWords = ['Pardon me', 'H2O', 'Bill please', 'Thanks'];
  
  final Map<String, String> _pairs = {
    'Excuse me': 'Pardon me',
    'Water': 'H2O',
    'Check please': 'Bill please',
    'Thank you': 'Thanks',
  };

  String? _selectedEnglish;
  String? _selectedSynonym;
  final Set<String> _matchedWords = {};

  void _handleWordSelect(String word, bool isEnglish) async {
    setState(() {
      if (isEnglish) {
        _selectedEnglish = word;
      } else {
        _selectedSynonym = word;
      }
    });

    if (_selectedEnglish != null && _selectedSynonym != null) {
      if (_pairs[_selectedEnglish] == _selectedSynonym) {
        // Match success
        await SoundSynthesizer.playTone(frequency: 880, durationSeconds: 0.15, name: 'match_success.wav');
        if (!mounted) return;
        ref.read(userProfileProvider.notifier).addXP(100); // Award XP
        
        setState(() {
          _matchedWords.add(_selectedEnglish!);
          _matchedWords.add(_selectedSynonym!);
          _selectedEnglish = null;
          _selectedSynonym = null;
        });
      } else {
        // Match fail
        await SoundSynthesizer.playTone(frequency: 220, durationSeconds: 0.25, name: 'match_fail.wav');
        setState(() {
          _selectedEnglish = null;
          _selectedSynonym = null;
        });
      }
    }
  }

  void _resetGame() {
    setState(() {
      _selectedEnglish = null;
      _selectedSynonym = null;
      _matchedWords.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProfileState = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2744),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Smart Utilities', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customs guide section
            const Text('CUSTOMS & DUTY-FREE LAWS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Colors.white70)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2744),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _customsRow(Icons.payments_outlined, 'Cash Caps', 'Declare if carrying > Â¥1,000,000 equivalent cash value.'),
                  _customsRow(Icons.liquor_outlined, 'Alcohol Limit', 'Tax-free allowance limits to 3 bottles (760ml each).'),
                  _customsRow(Icons.filter_vintage_outlined, 'Prohibited Items', 'Strictly forbidden: fresh fruits, meats, narcotics, and firearms.'),
                  _customsRow(Icons.shopping_bag_outlined, 'Tax-Free Purchases', 'Keep receipts attached to passport details for customs review at airport.'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Vocabulary Game section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('VOCABULARY TRAINER GAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Colors.white70)),
                Text('Score Rewards: ${userProfileState.xpPoints} XP', style: const TextStyle(fontSize: 11, color: Color(0xFF00B4D8), fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2744),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Match word pairs below to claim 100 XP points rewards.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Game columns layout
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // English List
                      Expanded(
                        child: Column(
                          children: _englishWords.map((word) {
                            final matched = _matchedWords.contains(word);
                            final selected = _selectedEnglish == word;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: InkWell(
                                onTap: matched ? null : () => _handleWordSelect(word, true),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: matched
                                        ? Colors.green.withValues(alpha: 0.15)
                                        : (selected ? const Color(0xFF2563EB) : const Color(0xFF0A1628)),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: matched ? Colors.green : (selected ? const Color(0xFF2563EB) : const Color(0xFF334155)),
                                    ),
                                  ),
                                  child: Text(
                                    word,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: matched
                                          ? Colors.greenAccent
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Synonym List
                      Expanded(
                        child: Column(
                          children: _synonymWords.map((word) {
                            final matched = _matchedWords.contains(word);
                            final selected = _selectedSynonym == word;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: InkWell(
                                onTap: matched ? null : () => _handleWordSelect(word, false),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: matched
                                        ? Colors.green.withValues(alpha: 0.15)
                                        : (selected ? const Color(0xFF2563EB) : const Color(0xFF0A1628)),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: matched ? Colors.green : (selected ? const Color(0xFF2563EB) : const Color(0xFF334155)),
                                    ),
                                  ),
                                  child: Text(
                                    word,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: matched
                                          ? Colors.greenAccent
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  
                  const Divider(height: 24, color: Color(0xFF334155)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Matched: ${_matchedWords.length ~/ 2} / ${_englishWords.length}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      TextButton.icon(
                        onPressed: () => _resetGame(),
                        icon: const Icon(Icons.refresh, size: 14, color: Color(0xFF2563EB)),
                        label: const Text('Reset Board', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customsRow(IconData icon, String title, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00B4D8))),
                const SizedBox(height: 2),
                Text(val, style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.3)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
