import 'dart:js' as js;

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
    js.context.callMethod('eval', ['''
      if ('speechSynthesis' in window) {
        window.speechSynthesis.cancel();
        var utterance = new SpeechSynthesisUtterance("${text.replaceAll('"', '\\"').replaceAll('\n', ' ')}");
        utterance.lang = "$localeCode";
        window.speechSynthesis.speak(utterance);
      }
    ''']);
  } catch (e) {
    print('Web TTS execution failed: $e');
  }
}

Future<void> stopTts() async {
  try {
    js.context.callMethod('eval', ['''
      if ('speechSynthesis' in window) {
        window.speechSynthesis.cancel();
      }
    ''']);
  } catch (e) {
    print('Web TTS stop failed: $e');
  }
}
