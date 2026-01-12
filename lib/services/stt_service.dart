import 'package:speech_to_text/speech_to_text.dart' as stt;

class SttService {
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static bool _initialized = false;

  static Future<bool> initialize() async {
    if (_initialized) return true;
    final available = await _speech.initialize(
      onError: (error) {
        // Error handler for initialization
      },
      onStatus: (status) {
        // Status handler
      },
    );
    _initialized = available;
    return available;
  }

  static Future<bool> hasPermission() async {
    if (!_initialized) {
      await initialize();
    }
    final permission = await _speech.hasPermission;
    return permission;
  }

  static Future<void> requestPermission() async {
    if (!_initialized) {
      await initialize();
    }
    await _speech.initialize(onError: (error) {}, onStatus: (status) {});
  }

  static Future<void> startListening({
    required Function(String text) onResult,
    required Function(String text)? onFinalResult,
    required String localeId,
  }) async {
    if (!_initialized) {
      final initialized = await initialize();
      if (!initialized) {
        throw Exception(
          'Speech to text initialization failed. Please check microphone permissions.',
        );
      }
    }

    // Check permission
    final hasPerm = await hasPermission();
    if (!hasPerm) {
      throw Exception(
        'Microphone permission is required. Please grant microphone permission in settings.',
      );
    }

    if (!_speech.isAvailable) {
      throw Exception('Speech to text is not available on this device.');
    }

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          // Final result - call onFinalResult if provided
          if (onFinalResult != null) {
            onFinalResult(result.recognizedWords);
          }
        } else {
          // Partial result - call onResult
          onResult(result.recognizedWords);
        }
      },
      localeId: localeId,
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
      ),
    );
  }

  static Future<void> stopListening() async {
    await _speech.stop();
  }

  static bool get isListening => _speech.isListening;

  static Future<void> cancel() async {
    await _speech.cancel();
  }
}
