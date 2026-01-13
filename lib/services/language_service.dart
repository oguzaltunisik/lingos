import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

class LanguageService {
  static const String _keyNativeLanguage = 'native_language';
  static const String _keyTargetLanguage = 'target_language';
  static const String _keyAppLanguage = 'app_language';

  // Supported languages
  static const List<String> supportedLanguages = ['tr', 'en', 'fi', 'fr'];

  // Notifier for app language changes
  static final ValueNotifier<String> appLanguageNotifier =
      ValueNotifier<String>('en');

  // Get device language
  static String getDeviceLanguage() {
    final locale = ui.PlatformDispatcher.instance.locale;
    final languageCode = locale.languageCode;

    // If device language is supported, return it
    if (supportedLanguages.contains(languageCode)) {
      return languageCode;
    }

    // Default to English if device language is not supported
    return 'en';
  }

  // Get native language from preferences
  static Future<String?> getNativeLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyNativeLanguage);
  }

  // Set native language
  static Future<void> setNativeLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNativeLanguage, language);
  }

  // Get target language from preferences
  static Future<String?> getTargetLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTargetLanguage);
  }

  // Set target language
  static Future<void> setTargetLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTargetLanguage, language);
  }

  // Initialize app language notifier
  static Future<void> initializeAppLanguage() async {
    final languageCode = await getAppLanguage();
    appLanguageNotifier.value = languageCode;
  }

  // Get app UI language
  static Future<String> getAppLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_keyAppLanguage);

    // If app language is set, use it
    if (savedLanguage != null && supportedLanguages.contains(savedLanguage)) {
      return savedLanguage;
    }

    // Otherwise, use device language
    return getDeviceLanguage();
  }

  // Set app UI language
  static Future<void> setAppLanguage(String language) async {
    if (!supportedLanguages.contains(language)) {
      throw ArgumentError('Unsupported language: $language');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppLanguage, language);
    appLanguageNotifier.value = language;
  }

  // Check if language selection is completed
  static Future<bool> isLanguageSelectionCompleted() async {
    final nativeLang = await getNativeLanguage();
    final targetLang = await getTargetLanguage();
    return nativeLang != null && targetLang != null;
  }

  // Get Locale from language code
  static Locale getLocaleFromLanguage(String languageCode) {
    return Locale(languageCode);
  }

  // Get language display name
  static String getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'tr':
        return 'Türkçe';
      case 'en':
        return 'English';
      case 'fi':
        return 'Suomi';
      case 'fr':
        return 'Français';
      default:
        return languageCode;
    }
  }

  // Get language emoji
  static String getLanguageEmoji(String languageCode) {
    switch (languageCode) {
      case 'tr':
        return '🇹🇷';
      case 'en':
        return '🇬🇧';
      case 'fi':
        return '🇫🇮';
      case 'fr':
        return '🇫🇷';
      default:
        return '';
    }
  }
}
