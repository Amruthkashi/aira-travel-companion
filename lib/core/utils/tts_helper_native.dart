import 'package:flutter_tts/flutter_tts.dart';

final FlutterTts _flutterTts = FlutterTts();

Future<void> speakText(String text, String targetLang) async {
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
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.speak(text);
  } catch (e) {
    print('Native TTS execution failed: $e');
  }
}

Future<void> stopTts() async {
  try {
    await _flutterTts.stop();
  } catch (e) {
    print('Native TTS stop failed: $e');
  }
}
