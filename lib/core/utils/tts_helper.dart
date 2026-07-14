import 'tts_helper_stub.dart'
    if (dart.library.js) 'tts_helper_web.dart'
    if (dart.library.io) 'tts_helper_native.dart';

class TtsHelper {
  static Future<void> speak(String text, String targetLang, {double rate = 1.0}) async {
    await speakText(text, targetLang, rate: rate);
  }

  static Future<void> stop() async {
    await stopTts();
  }
}
