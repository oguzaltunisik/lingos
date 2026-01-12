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
  String get correct => _getString('correct');
  String get incorrect => _getString('incorrect');
  String get checkButton => _getString('checkButton');
  String get skipButton => _getString('skipButton');
  String get alreadyKnowButton => _getString('alreadyKnowButton');
  String get wantToLearnButton => _getString('wantToLearnButton');
  String get actionMeet => _getString('actionMeet');
  String get actionAudioToTarget => _getString('actionAudioToTarget');
  String get actionRemember => _getString('actionRemember');
  String get actionVisualToTarget => _getString('actionVisualToTarget');
  String get actionTargetToVisual => _getString('actionTargetToVisual');
  String get actionTargetToAudio => _getString('actionTargetToAudio');
  String get actionAudioToVisual => _getString('actionAudioToVisual');
  String get actionVisualToAudio => _getString('actionVisualToAudio');
  String get actionAudioToTargetMerge => _getString('actionAudioToTargetMerge');
  String get actionVisualToTargetMerge =>
      _getString('actionVisualToTargetMerge');
  String get actionQuestionToTargetMerge =>
      _getString('actionQuestionToTargetMerge');
  String get actionQuestionToTarget => _getString('actionQuestionToTarget');
  String get actionQuestionToAudio => _getString('actionQuestionToAudio');
  String get actionPair => _getString('actionPair');
  String get actionMemory => _getString('actionMemory');
  String get actionSelectCorrectOption =>
      _getString('actionSelectCorrectOption');
  String get actionBuildTerm => _getString('actionBuildTerm');

  // Topics
  String getTopicName(String topicId) {
    final topic = TermService.getTopicById(topicId);
    if (topic != null) {
      return topic.getName(languageCode);
    }
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
    'correct': 'Correct',
    'incorrect': 'Incorrect',
    'checkButton': 'Check',
    'skipButton': 'Skip',
    'alreadyKnowButton': 'I Already Know',
    'wantToLearnButton': 'I Want to Learn',
    'actionMeet': 'Meet',
    'actionAudioToTarget': 'Hear it, pick the word',
    'actionAudioToVisual': 'Hear it, pick the visual',
    'actionVisualToAudio': 'See it, pick the audio',
    'actionAudioToTargetMerge': 'Hear it, build the word',
    'actionVisualToTargetMerge': 'See it, build the word',
    'actionQuestionToTargetMerge': 'Read the question, build the word',
    'actionQuestionToTarget': 'Read the question, pick the word',
    'actionQuestionToAudio': 'Read the question, pick the audio',
    'actionRemember': 'Remember',
    'actionVisualToTarget': 'See it, pick the word',
    'actionTargetToVisual': 'Read it, pick the visual',
    'actionTargetToAudio': 'Read it, pick the audio',
    'actionPair': 'Match',
    'actionMemory': 'Memory',
    'actionSelectCorrectOption': 'Make a selection',
    'actionBuildTerm': 'Build the term',
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
    'correct': 'Doğru',
    'incorrect': 'Yanlış',
    'checkButton': 'Kontrol Et',
    'skipButton': 'Atla',
    'alreadyKnowButton': 'Zaten Biliyorum',
    'wantToLearnButton': 'Öğrenmek İstiyorum',
    'actionMeet': 'Tanış',
    'actionAudioToTarget': 'Dinle, doğru kelimeyi seç',
    'actionAudioToVisual': 'Dinle, doğru görseli seç',
    'actionVisualToAudio': 'Bak, doğru sesi seç',
    'actionAudioToTargetMerge': 'Dinle, harfleri birleştir',
    'actionVisualToTargetMerge': 'Bak, harfleri birleştir',
    'actionQuestionToTargetMerge': 'Soruyu oku, harfleri birleştir',
    'actionQuestionToTarget': 'Soruyu oku, doğru kelimeyi seç',
    'actionQuestionToAudio': 'Soruyu oku, doğru sesi seç',
    'actionRemember': 'Hatırla',
    'actionVisualToTarget': 'Bak, doğru kelimeyi seç',
    'actionTargetToVisual': 'Oku, doğru görseli seç',
    'actionTargetToAudio': 'Oku, doğru sesi seç',
    'actionPair': 'Eşleştir',
    'actionMemory': 'Hafıza',
    'actionSelectCorrectOption': 'Seçim Yap',
    'actionBuildTerm': 'Terimi Oluştur',
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
    'correct': 'Oikein',
    'incorrect': 'Väärin',
    'checkButton': 'Tarkista',
    'skipButton': 'Ohita',
    'alreadyKnowButton': 'Tiedän jo',
    'wantToLearnButton': 'Haluan oppia',
    'actionMeet': 'Tutustu',
    'actionAudioToTarget': 'Kuuntele ja valitse sana',
    'actionAudioToVisual': 'Kuuntele ja valitse kuva',
    'actionVisualToAudio': 'Katso ja valitse ääni',
    'actionAudioToTargetMerge': 'Kuuntele ja rakenna sana',
    'actionVisualToTargetMerge': 'Katso ja rakenna sana',
    'actionQuestionToTargetMerge': 'Lue kysymys, rakenna sana',
    'actionQuestionToTarget': 'Lue kysymys, valitse sana',
    'actionQuestionToAudio': 'Lue kysymys, valitse ääni',
    'actionRemember': 'Muista',
    'actionVisualToTarget': 'Katso ja valitse sana',
    'actionTargetToVisual': 'Lue ja valitse kuva',
    'actionTargetToAudio': 'Lue ja valitse ääni',
    'actionPair': 'Yhdistä',
    'actionMemory': 'Muisti',
    'actionSelectCorrectOption': 'Tee valinta',
    'actionBuildTerm': 'Rakenna termi',
    // Language names
    'language_tr': 'Türkçe',
    'language_en': 'English',
    'language_fi': 'Suomi',
  };
}
