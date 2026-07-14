import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

final FlutterTts _flutterTts = FlutterTts();

Future<void> speakText(String text, String targetLang, {double rate = 1.0}) async {
  String localeCode = 'en-US';
  if (targetLang == 'Japanese') {
    localeCode = 'ja-JP';
  } else if (targetLang == 'French') {
    localeCode = 'fr-FR';
  } else if (targetLang == 'Spanish') {
    localeCode = 'es-ES';
  } else if (targetLang == 'German') {
    localeCode = 'de-DE';
  } else if (targetLang == 'Italian') {
    localeCode = 'it-IT';
  } else if (targetLang == 'Chinese') {
    localeCode = 'zh-CN';
  } else if (targetLang == 'Korean') {
    localeCode = 'ko-KR';
  }

  try {
    await _flutterTts.setLanguage(localeCode);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate((0.45 * rate).clamp(0.1, 1.0));
    await _flutterTts.speak(text);
  } catch (e) {
    debugPrint('Native TTS execution failed: $e');
  }
}

Future<void> stopTts() async {
  try {
    await _flutterTts.stop();
  } catch (e) {
    debugPrint('Native TTS stop failed: $e');
  }
}
