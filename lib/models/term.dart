import 'dart:math';

class Term {
  final String id;
  final List<String> topicIds;
  final String textEn;
  final String textTr;
  final String textFi;
  final String textFr;
  final List<Map<String, String>>? questions;
  final String emoji;
  static final Random _random = Random();

  const Term({
    required this.id,
    required this.topicIds,
    required this.textEn,
    required this.textTr,
    required this.textFi,
    required this.textFr,
    this.questions,
    required this.emoji,
  });

  String getText(String languageCode) {
    switch (languageCode) {
      case 'tr':
        return textTr;
      case 'fi':
        return textFi;
      case 'fr':
        return textFr;
      case 'en':
        return textEn;
      default:
        throw ArgumentError('Unsupported language code: $languageCode');
    }
  }

  String getQuestion(String languageCode) {
    if (questions == null || questions!.isEmpty) return '';
    final randomQuestion = questions![_random.nextInt(questions!.length)];
    switch (languageCode) {
      case 'tr':
        return randomQuestion['tr'] ?? '';
      case 'fi':
        return randomQuestion['fi'] ?? '';
      case 'fr':
        return randomQuestion['fr'] ?? '';
      case 'en':
        return randomQuestion['en'] ?? '';
      default:
        throw ArgumentError('Unsupported language code: $languageCode');
    }
  }

  factory Term.fromJson(
    Map<String, dynamic> json,
    Map<String, Map<String, dynamic>>? languageData,
  ) {
    final id = json['id'] as String;
    final emoji = json['emoji'] as String;
    final topicIds = List<String>.from(json['topicIds'] as List);

    // Get text from language files
    String textEn = '';
    String textTr = '';
    String textFi = '';
    String textFr = '';

    if (languageData != null) {
      textEn = languageData['en']?['terms']?[id] ?? '';
      textTr = languageData['tr']?['terms']?[id] ?? '';
      textFi = languageData['fi']?['terms']?[id] ?? '';
      textFr = languageData['fr']?['terms']?[id] ?? '';
    }

    // Get questions from language files
    List<Map<String, String>>? questions;
    if (languageData != null) {
      final questionsList = languageData['en']?['questions']?[id] as List?;
      if (questionsList != null && questionsList.isNotEmpty) {
        questions = [];
        for (int i = 0; i < questionsList.length; i++) {
          final enQ = questionsList[i] as String? ?? '';
          final trQ =
              languageData['tr']?['questions']?[id]?[i] as String? ?? '';
          final fiQ =
              languageData['fi']?['questions']?[id]?[i] as String? ?? '';
          final frQ =
              languageData['fr']?['questions']?[id]?[i] as String? ?? '';
          questions.add({'en': enQ, 'tr': trQ, 'fi': fiQ, 'fr': frQ});
        }
      }
    }

    return Term(
      id: id,
      topicIds: topicIds,
      textEn: textEn,
      textTr: textTr,
      textFi: textFi,
      textFr: textFr,
      questions: questions,
      emoji: emoji,
    );
  }

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{
      'id': id,
      'topicIds': topicIds,
      'textEn': textEn,
      'textTr': textTr,
      'textFi': textFi,
      'textFr': textFr,
      'emoji': emoji,
    };
    if (questions != null && questions!.isNotEmpty) {
      result['questions'] = questions;
    }
    return result;
  }
}
