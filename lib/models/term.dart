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
      default:
        return textEn;
    }
  }

  String getQuestion(String languageCode) {
    if (questions == null || questions!.isEmpty) return '';
    final randomQuestion = questions![_random.nextInt(questions!.length)];
    switch (languageCode) {
      case 'tr':
        return randomQuestion['tr'] ?? randomQuestion['en'] ?? '';
      case 'fi':
        return randomQuestion['fi'] ?? randomQuestion['en'] ?? '';
      case 'en':
      default:
        return randomQuestion['en'] ?? '';
    }
  }

  factory Term.fromJson(Map<String, dynamic> json) {
    // Support both old format (single topicId) and new format (topicIds array)
    List<String> topicIds;
    if (json['topicIds'] != null) {
      topicIds = List<String>.from(json['topicIds'] as List);
    } else if (json['topicId'] != null) {
      // Backward compatibility: single topicId becomes array
      topicIds = [json['topicId'] as String];
    } else {
      topicIds = [];
    }

    // Support both old format (questionEn/Tr/Fi) and new format (questions array)
    List<Map<String, String>>? questions;
    if (json['questions'] != null) {
      // New format: questions array
      final questionsList = json['questions'] as List;
      if (questionsList.isNotEmpty) {
        questions = questionsList
            .map((q) => Map<String, String>.from(q as Map))
            .toList();
      }
    } else if (json['questionEn'] != null ||
        json['questionTr'] != null ||
        json['questionFi'] != null) {
      // Old format: convert single question to array format
      questions = [
        {
          'en': json['questionEn'] as String? ?? '',
          'tr': json['questionTr'] as String? ?? '',
          'fi': json['questionFi'] as String? ?? '',
        },
      ];
    }

    return Term(
      id: json['id'] as String,
      topicIds: topicIds,
      textEn: json['textEn'] as String,
      textTr: json['textTr'] as String,
      textFi: json['textFi'] as String,
      questions: questions,
      emoji: json['emoji'] as String? ?? '👋',
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
