import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
  }

  static Future<void> playCorrect() async {
    try {
      await _player.setAsset('assets/sound_effects/correct.wav');
      await _player.play();
    } catch (e) {
      // Ignore errors if sound file is not found
      if (kDebugMode) {
        print('Error playing correct sound: $e');
      }
    }
  }

  static Future<void> playIncorrect() async {
    try {
      await _player.setAsset('assets/sound_effects/incorrect.mp3');
      await _player.play();
    } catch (e) {
      // Ignore errors if sound file is not found
      if (kDebugMode) {
        print('Error playing incorrect sound: $e');
      }
    }
  }

  static Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      // Ignore errors
    }
  }
}
