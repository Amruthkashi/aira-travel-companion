// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

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
    debugPrint('Web TTS execution failed: $e');
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
    debugPrint('Web TTS stop failed: $e');
  }
}
