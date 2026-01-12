import 'dart:math';

class Term {
  final String id;
  final List<String> topicIds;
  final String textEn;
  final String textTr;
  final String textFi;
  final List<Map<String, String>>? questions;
  final String emoji;
  static final Random _random = Random();

  const Term({
    required this.id,
    required this.topicIds,
    required this.textEn,
    required this.textTr,
    required this.textFi,
    this.questions,
    required this.emoji,
  });

  String getText(String languageCode) {
    switch (languageCode) {
      case 'tr':
        return textTr;
      case 'fi':
        return textFi;
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
      case 'en':
        return randomQuestion['en'] ?? '';
      default:
        throw ArgumentError('Unsupported language code: $languageCode');
    }
  }

  factory Term.fromJson(Map<String, dynamic> json) {
    final questionsList = json['questions'] as List?;
    List<Map<String, String>>? questions;
    if (questionsList != null && questionsList.isNotEmpty) {
      questions = questionsList
          .map((q) => Map<String, String>.from(q as Map))
          .toList();
    }

    return Term(
      id: json['id'] as String,
      topicIds: List<String>.from(json['topicIds'] as List),
      textEn: json['textEn'] as String,
      textTr: json['textTr'] as String,
      textFi: json['textFi'] as String,
      questions: questions,
      emoji: json['emoji'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{
      'id': id,
      'topicIds': topicIds,
      'textEn': textEn,
      'textTr': textTr,
      'textFi': textFi,
      'emoji': emoji,
    };
    if (questions != null && questions!.isNotEmpty) {
      result['questions'] = questions;
    }
    return result;
  }
}
