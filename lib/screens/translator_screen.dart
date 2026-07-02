import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../core/providers/theme_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/services/ai_service.dart';
import '../core/utils/sound_synthesizer.dart';
import '../core/utils/tts_helper.dart';

class TranslatorScreen extends ConsumerStatefulWidget {
  const TranslatorScreen({super.key});

  @override
  ConsumerState<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends ConsumerState<TranslatorScreen> {
  String _sourceLang = 'English';
  String _targetLang = 'Japanese';
  String _activeCategory = 'Dining';
  final TextEditingController _inputCtrl = TextEditingController();
  
  String _resultText = '';
  String _romajiText = '';
  
  // Real-time audio recording & playback state variables
  late stt.SpeechToText _speech;
  bool _isListening = false;
  late FlutterTts _flutterTts;
  bool _ttsPlaying = false;

  final Map<String, Map<String, List<Map<String, String>>>> _phrasebook = {
    'Dining': {
      'Japanese': [
        {'eng': 'Check, please.', 'tr': 'お会計をお願いします。', 'rom': 'O-kaikei o onegai shimasu.'},
        {'eng': 'Does this contain meat?', 'tr': 'これは肉が入っていますか？', 'rom': 'Kore wa niku ga haitte imasu ka?'},
        {'eng': 'Water, please.', 'tr': 'お水をお願いします。', 'rom': 'O-mizu o onegai shimasu.'}
      ],
      'French': [
        {'eng': 'Check, please.', 'tr': 'L\'addition, s\'il vous plaît.', 'rom': 'L\'ah-dee-syon, seel voo pleh.'},
        {'eng': 'Water, please.', 'tr': 'De l\'eau, s\'il vous plaît.', 'rom': 'Duh l\'oh, seel voo pleh.'}
      ],
      'Spanish': [
        {'eng': 'Check, please.', 'tr': 'La cuenta, por favor.', 'rom': 'La kwen-tah por fah-vor.'},
        {'eng': 'Water, please.', 'tr': 'Agua, por favor.', 'rom': 'Ah-gwah por fah-vor.'}
      ],
      'German': [
        {'eng': 'Check, please.', 'tr': 'Die Rechnung, bitte.', 'rom': 'Dee rekh-noong bih-teh.'},
        {'eng': 'Water, please.', 'tr': 'Wasser, bitte.', 'rom': 'Vah-ser bih-teh.'}
      ],
      'Italian': [
        {'eng': 'Check, please.', 'tr': 'Il conto, per favore.', 'rom': 'Eel kon-toh per fah-voh-reh.'},
        {'eng': 'Water, please.', 'tr': 'Acqua, per favore.', 'rom': 'Ah-kwah per fah-voh-reh.'}
      ],
      'Chinese': [
        {'eng': 'Check, please.', 'tr': '买单。', 'rom': 'Mǎidān.'},
        {'eng': 'Water, please.', 'tr': '请给我水。', 'rom': 'Qǐng gěi wǒ shuǐ.'}
      ],
      'Korean': [
        {'eng': 'Check, please.', 'tr': '계산서 주세요.', 'rom': 'Gyesanseo juseyo.'},
        {'eng': 'Water, please.', 'tr': '물 주세요.', 'rom': 'Mul juseyo.'}
      ]
    },
    'Directions': {
      'Japanese': [
        {'eng': 'Where is the station?', 'tr': '駅はどこですか？', 'rom': 'Eki wa doko desu ka?'},
        {'eng': 'Is this the train to the central station?', 'tr': 'これは中央駅行きの電車ですか？', 'rom': 'Kore wa chūō-eki yiki no densha desu ka?'},
      ],
      'French': [
        {'eng': 'Where is the station?', 'tr': 'Où est la gare?', 'rom': 'Oo eh lah gahr?'},
      ],
      'Spanish': [
        {'eng': 'Where is the station?', 'tr': '¿Dónde está la estación?', 'rom': 'Don-deh es-tah lah es-tah-syon?'},
      ],
      'German': [
        {'eng': 'Where is the station?', 'tr': 'Wo ist der Bahnhof?', 'rom': 'Voh ist dare bahn-hohf?'},
      ],
      'Italian': [
        {'eng': 'Where is the station?', 'tr': 'Dov\'è la stazione?', 'rom': 'Doh-veh lah stah-tsyon-eh?'},
      ],
      'Chinese': [
        {'eng': 'Where is the station?', 'tr': '车站在这里吗？', 'rom': 'Chēzhàn zài zhèlǐ ma?'},
      ],
      'Korean': [
        {'eng': 'Where is the station?', 'tr': '역이 어디에 있나요?', 'rom': 'Yeogi eodie innayo?'}
      ]
    },
    'Shopping': {
      'Japanese': [
        {'eng': 'How much is this?', 'tr': 'これはいくらですか？', 'rom': 'How much is this?'},
        {'eng': 'Do you accept credit cards?', 'tr': 'クレジットカードは使えますか？', 'rom': 'Kurejitto kādo wa tsukaemasu ka?'},
      ],
      'French': [
        {'eng': 'How much is this?', 'tr': 'C\'est combien?', 'rom': 'Say com-byen?'},
      ],
      'Spanish': [
        {'eng': 'How much is this?', 'tr': '¿Cuánto cuesta esto?', 'rom': 'Kwan-toh kwes-tah es-toh?'},
      ],
      'German': [
        {'eng': 'How much is this?', 'tr': 'Wie viel kostet das?', 'rom': 'Wie feel kos-tet das?'},
      ],
      'Italian': [
        {'eng': 'How much is this?', 'tr': 'Quanto costa questo?', 'rom': 'Kwan-toh kos-tah kwes-toh?'},
      ],
      'Chinese': [
        {'eng': 'How much is this?', 'tr': '这个多少钱？', 'rom': 'Zhège duōshǎo qián?'},
      ],
      'Korean': [
        {'eng': 'How much is this?', 'tr': '이것은 얼마인가요?', 'rom': 'Igeoseun eolmaingayo?'}
      ]
    }
  };

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initTts();
  }

  void _initTts() {
    _flutterTts.setStartHandler(() {
      setState(() => _ttsPlaying = true);
    });
    _flutterTts.setCompletionHandler(() {
      setState(() => _ttsPlaying = false);
    });
    _flutterTts.setErrorHandler((msg) {
      setState(() => _ttsPlaying = false);
    });
    _flutterTts.setVolume(1.0);
    _flutterTts.setPitch(1.0);
    _flutterTts.setSpeechRate(0.45);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _translateCustomText(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _resultText = 'Translating via Gemini AI...';
      _romajiText = '';
    });
    try {
      final res = await AiService.translateText(
        text: text,
        sourceLang: _sourceLang,
        targetLang: _targetLang,
      );
      setState(() {
        _resultText = res['translation'] ?? '';
        _romajiText = res['romaji'] ?? '';
      });
      
      // Auto speak translated result in the desired language
      _speakTranslatedText(_resultText);
    } catch (e) {
      setState(() {
        _resultText = 'Translation error: ${e.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  Future<void> _speakTranslatedText(String text) async {
    if (text.isEmpty) return;
    try {
      setState(() => _ttsPlaying = true);
      await TtsHelper.speak(text, _targetLang);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _ttsPlaying = false);
        }
      });
    } catch (e) {
      debugPrint('TTS execution failed: $e');
      if (mounted) {
        setState(() => _ttsPlaying = false);
      }
    }
  }

  void _listen() async {
    if (!_isListening) {
      // Play brief microphone activation feedback chime
      await SoundSynthesizer.playTone(frequency: 520, durationSeconds: 0.12, name: 'mic_start.wav');
      
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'notListening' || val == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) {
          setState(() {
            _isListening = false;
            _resultText = 'Speech recognition error: ${val.errorMsg}';
          });
        },
      );
      if (available) {
        setState(() {
          _isListening = true;
          _resultText = 'Listening...';
          _romajiText = '';
        });
        _speech.listen(
          onResult: (val) {
            setState(() {
              _inputCtrl.text = val.recognizedWords;
            });
            if (val.finalResult) {
              _translateCustomText(val.recognizedWords);
            }
          },
        );
      } else {
        setState(() {
          _isListening = false;
          _resultText = 'Microphone speech recognition not available.';
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      // Play mic closure feedback chime
      await SoundSynthesizer.playTone(frequency: 400, durationSeconds: 0.1, name: 'mic_stop.wav');
    }
  }

  @override
  Widget build(BuildContext context) {
    final phraseList = _phrasebook[_activeCategory]?[_targetLang] ?? [];
    final isDark = ref.watch(isDarkProvider);

    return Scaffold(
      backgroundColor: AiraColors.scaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: AiraColors.cardBg(isDark),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AiraColors.textPrimary(isDark)),
        title: Text(
          'Real-Time AI Translator',
          style: TextStyle(
            color: AiraColors.textPrimary(isDark),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language selector dropdowns
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AiraColors.cardBg(isDark),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AiraColors.border(isDark)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButton<String>(
                    value: _sourceLang,
                    dropdownColor: AiraColors.cardBg(isDark),
                    style: TextStyle(color: AiraColors.textPrimary(isDark), fontWeight: FontWeight.bold),
                    underline: const SizedBox(),
                    onChanged: (v) => setState(() => _sourceLang = v!),
                    items: [
                      DropdownMenuItem(
                        value: 'English',
                        child: Text('English', style: TextStyle(color: AiraColors.textPrimary(isDark))),
                      )
                    ],
                  ),
                  Icon(Icons.arrow_forward_rounded, color: AiraColors.textSecondary(isDark)),
                  DropdownButton<String>(
                    value: _targetLang,
                    dropdownColor: AiraColors.cardBg(isDark),
                    style: TextStyle(color: AiraColors.textPrimary(isDark), fontWeight: FontWeight.bold),
                    underline: const SizedBox(),
                    onChanged: (v) => setState(() {
                      _targetLang = v!;
                      _resultText = '';
                      _romajiText = '';
                    }),
                    items: [
                      DropdownMenuItem(value: 'Japanese', child: Text('Japanese', style: TextStyle(color: AiraColors.textPrimary(isDark)))),
                      DropdownMenuItem(value: 'French', child: Text('French', style: TextStyle(color: AiraColors.textPrimary(isDark)))),
                      DropdownMenuItem(value: 'Spanish', child: Text('Spanish', style: TextStyle(color: AiraColors.textPrimary(isDark)))),
                      DropdownMenuItem(value: 'German', child: Text('German', style: TextStyle(color: AiraColors.textPrimary(isDark)))),
                      DropdownMenuItem(value: 'Italian', child: Text('Italian', style: TextStyle(color: AiraColors.textPrimary(isDark)))),
                      DropdownMenuItem(value: 'Chinese', child: Text('Chinese', style: TextStyle(color: AiraColors.textPrimary(isDark)))),
                      DropdownMenuItem(value: 'Korean', child: Text('Korean', style: TextStyle(color: AiraColors.textPrimary(isDark)))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Translation Input card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AiraColors.cardBg(isDark),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AiraColors.border(isDark)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _inputCtrl,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AiraColors.textPrimary(isDark)),
                    decoration: InputDecoration(
                      hintText: 'Type phrase here (e.g. hello, thank you...)',
                      hintStyle: TextStyle(color: AiraColors.textMuted(isDark), fontSize: 13),
                      filled: true,
                      fillColor: AiraColors.scaffoldBg(isDark),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AiraColors.border(isDark))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AiraColors.border(isDark))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB))),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.translate, color: Color(0xFF2563EB)),
                        onPressed: () => _translateCustomText(_inputCtrl.text),
                      ),
                    ),
                    onSubmitted: (v) => _translateCustomText(v),
                  ),
                  if (_resultText.isNotEmpty) ...[
                    Divider(height: 24, color: AiraColors.border(isDark)),
                    Text(
                      'TRANSLATED OUTPUT',
                      style: TextStyle(
                        fontSize: 9,
                        color: AiraColors.textSecondary(isDark),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_resultText, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF00B4D8))),
                              if (_romajiText.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _romajiText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AiraColors.textSecondary(isDark),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.volume_up, color: _ttsPlaying ? const Color(0xFF00B4D8) : const Color(0xFF2563EB)),
                          onPressed: () => _speakTranslatedText(_resultText),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Voice translation card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF1E1B4B), Color(0xFF111827)]
                      : const [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AiraColors.border(isDark)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VOICE DIALOGUE TRANSLATOR',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFFFF6B35),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isListening ? 'Listening to voice logs...' : 'Hold Mic to scan audio speech',
                          style: TextStyle(
                            color: AiraColors.textPrimary(isDark),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _listen(),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: _isListening ? Colors.redAccent : const Color(0xFF2563EB),
                      child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Phrasebook Category Chips
            Text(
              'PHRASEBOOK DICTIONARY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: ['Dining', 'Directions', 'Shopping'].map((cat) {
                final active = _activeCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: active,
                    selectedColor: const Color(0xFF2563EB),
                    backgroundColor: AiraColors.cardBg(isDark),
                    disabledColor: AiraColors.cardBg(isDark),
                    side: BorderSide(color: active ? const Color(0xFF2563EB) : AiraColors.border(isDark)),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      color: active ? Colors.white : AiraColors.textSecondary(isDark),
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (sel) {
                      if (sel) setState(() => _activeCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            // Phrasebook list
            if (phraseList.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'No offline phrases found for this category.',
                    style: TextStyle(color: AiraColors.textSecondary(isDark), fontSize: 12),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: phraseList.length,
                itemBuilder: (context, idx) {
                  final p = phraseList[idx];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _inputCtrl.text = p['eng']!;
                        _resultText = p['tr']!;
                        _romajiText = p['rom']!;
                      });
                      _speakTranslatedText(p['tr']!);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AiraColors.cardBg(isDark),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AiraColors.border(isDark)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['eng']!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AiraColors.textPrimary(isDark))),
                                const SizedBox(height: 4),
                                Text(p['tr']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00B4D8))),
                                Text(p['rom']!, style: TextStyle(fontSize: 10, color: AiraColors.textSecondary(isDark), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.volume_up, color: Color(0xFF2563EB)),
                            onPressed: () => _speakTranslatedText(p['tr']!),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
