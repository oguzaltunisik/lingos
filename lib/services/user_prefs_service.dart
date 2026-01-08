import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPrefsService {
  static const String _keyShowTranslation = 'show_translation';

  // Notifier to reflect show translation preference across app
  static final ValueNotifier<bool> showTranslationNotifier =
      ValueNotifier<bool>(false);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_keyShowTranslation);
    showTranslationNotifier.value = saved ?? false;
  }

  static Future<void> setShowTranslation(bool value) async {
    showTranslationNotifier.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowTranslation, value);
  }
}
