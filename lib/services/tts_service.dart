import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
    _initialized = true;
  }

  static Future<void> speakTerm({
    required String text,
    required String languageCode,
  }) async {
    if (text.isEmpty) return;
    await init();
    final lang = _mapLangToTtsCode(languageCode);
    await _tts.stop();
    await _tts.setLanguage(lang);
    await _tts.speak(text);
  }

  static Future<void> stop() async {
    if (!_initialized) return;
    await _tts.stop();
  }

  static String _mapLangToTtsCode(String code) {
    switch (code) {
      case 'tr':
        return 'tr-TR';
      case 'fi':
        return 'fi-FI';
      case 'en':
      default:
        return 'en-US';
    }
  }
}
