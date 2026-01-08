class Term {
  final String id;
  final List<String> topicIds;
  final String textEn;
  final String textTr;
  final String textFi;
  final String emoji;

  const Term({
    required this.id,
    required this.topicIds,
    required this.textEn,
    required this.textTr,
    required this.textFi,
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

    return Term(
      id: json['id'] as String,
      topicIds: topicIds,
      textEn: json['textEn'] as String,
      textTr: json['textTr'] as String,
      textFi: json['textFi'] as String,
      emoji: json['emoji'] as String? ?? '👋',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topicIds': topicIds,
      'textEn': textEn,
      'textTr': textTr,
      'textFi': textFi,
      'emoji': emoji,
    };
  }
}
