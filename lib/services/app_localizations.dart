import 'package:flutter/material.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/term_service.dart';

class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  static AppLocalizations of(BuildContext context) {
    // Get current language from notifier
    final languageCode = LanguageService.appLanguageNotifier.value;
    return AppLocalizations(languageCode);
  }

  // Get current instance without context
  static AppLocalizations get current {
    final languageCode = LanguageService.appLanguageNotifier.value;
    return AppLocalizations(languageCode);
  }

  // Home Page
  String get appTitle => _getString('appTitle');
  String get welcomeMessage => _getString('welcomeMessage');
  String get nativeLanguage => _getString('nativeLanguage');
  String get targetLanguage => _getString('targetLanguage');
  String get startLearning => _getString('startLearning');

  // Language Selection Page
  String get selectLanguages => _getString('selectLanguages');
  String get nativeLanguageTitle => _getString('nativeLanguageTitle');
  String get targetLanguageTitle => _getString('targetLanguageTitle');
  String get continueButton => _getString('continueButton');
  String get selectBothLanguages => _getString('selectBothLanguages');
  String get languagesMustBeDifferent => _getString('languagesMustBeDifferent');
  String get errorSavingLanguages => _getString('errorSavingLanguages');

  // Learning Page
  String get nextButton => _getString('nextButton');
  String get homePageButton => _getString('homePageButton');
  String get showTranslation => _getString('showTranslation');
  String get settingsTitle => _getString('settingsTitle');
  String get languageSettings => _getString('languageSettings');
  String get sessionCompleted => _getString('sessionCompleted');

  // Topics
  String getTopicName(String topicId) {
    return _getString('topic_$topicId');
  }

  // Language names (displayed in their own language)
  String getLanguageDisplayName(String languageCode) {
    return _getString('language_$languageCode');
  }

  // Terms - Get term text in current language
  String? getTermText(String termId) {
    return TermService.getTermText(termId, languageCode);
  }

  String _getString(String key) {
    switch (languageCode) {
      case 'tr':
        return _trStrings[key] ?? key;
      case 'fi':
        return _fiStrings[key] ?? key;
      case 'en':
      default:
        return _enStrings[key] ?? key;
    }
  }

  static const Map<String, String> _enStrings = {
    'appTitle': 'Lingos',
    'welcomeMessage': 'Welcome to Lingos!',
    'nativeLanguage': 'Native Language:',
    'targetLanguage': 'Target Language:',
    'startLearning': 'Start learning!',
    'selectLanguages': 'Select Languages',
    'nativeLanguageTitle': 'Native Language',
    'targetLanguageTitle': 'Target Language',
    'continueButton': 'Continue',
    'selectBothLanguages': 'Please select both native and target languages',
    'languagesMustBeDifferent': 'Native and target languages must be different',
    'errorSavingLanguages': 'Error saving languages: ',
    // Learning Page
    'nextButton': 'Next',
    'homePageButton': 'Home',
    'showTranslation': 'Show Translation',
    'settingsTitle': 'Settings',
    'languageSettings': 'Language',
    'sessionCompleted': 'Session completed',
    // Topics
    'topic_greetings': 'Greetings',
    'topic_travel': 'Travel',
    'topic_food': 'Food',
    'topic_shopping': 'Shopping',
    'topic_daily_life': 'Daily Life',
    // Language names
    'language_tr': 'Türkçe',
    'language_en': 'English',
    'language_fi': 'Suomi',
  };

  static const Map<String, String> _trStrings = {
    'appTitle': 'Lingos',
    'welcomeMessage': 'Lingos\'a Hoş Geldiniz!',
    'nativeLanguage': 'Ana Dil:',
    'targetLanguage': 'Hedef Dil:',
    'startLearning': 'Öğrenmeye başla!',
    'selectLanguages': 'Dil Seçimi',
    'nativeLanguageTitle': 'Ana Dil',
    'targetLanguageTitle': 'Hedef Dil',
    'continueButton': 'Devam Et',
    'selectBothLanguages': 'Lütfen hem ana dili hem de hedef dili seçin',
    'languagesMustBeDifferent': 'Ana dil ve hedef dil farklı olmalıdır',
    'errorSavingLanguages': 'Diller kaydedilirken hata oluştu: ',
    // Learning Page
    'nextButton': 'Sonraki',
    'homePageButton': 'Ana Sayfa',
    'showTranslation': 'Tercümeyi Göster',
    'settingsTitle': 'Ayarlar',
    'languageSettings': 'Dil Ayarları',
    'sessionCompleted': 'Oturum tamamlandı',
    // Topics
    'topic_greetings': 'Tanışma',
    'topic_travel': 'Seyahat',
    'topic_food': 'Yemek',
    'topic_shopping': 'Alışveriş',
    'topic_daily_life': 'Günlük Hayat',
    // Language names
    'language_tr': 'Türkçe',
    'language_en': 'English',
    'language_fi': 'Suomi',
  };

  static const Map<String, String> _fiStrings = {
    'appTitle': 'Lingos',
    'welcomeMessage': 'Tervetuloa Lingosiin!',
    'nativeLanguage': 'Äidinkieli:',
    'targetLanguage': 'Kohdekieli:',
    'startLearning': 'Aloita oppiminen!',
    'selectLanguages': 'Valitse kielet',
    'nativeLanguageTitle': 'Äidinkieli',
    'targetLanguageTitle': 'Kohdekieli',
    'continueButton': 'Jatka',
    'selectBothLanguages': 'Valitse sekä äidinkieli että kohdekieli',
    'languagesMustBeDifferent':
        'Äidinkielen ja kohdekielen on oltava erilaiset',
    'errorSavingLanguages': 'Virhe tallennettaessa kieliä: ',
    // Learning Page
    'nextButton': 'Seuraava',
    'homePageButton': 'Etusivu',
    'showTranslation': 'Näytä käännös',
    'settingsTitle': 'Asetukset',
    'languageSettings': 'Kieliasetukset',
    'sessionCompleted': 'Istunto valmis',
    // Topics
    'topic_greetings': 'Tervehdykset',
    'topic_travel': 'Matkustaminen',
    'topic_food': 'Ruoka',
    'topic_shopping': 'Ostokset',
    'topic_daily_life': 'Päivittäinen elämä',
    // Language names
    'language_tr': 'Türkçe',
    'language_en': 'English',
    'language_fi': 'Suomi',
  };
}
