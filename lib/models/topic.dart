class Topic {
  const Topic({
    required this.id,
    required this.emoji,
    required this.textEn,
    required this.textTr,
    required this.textFi,
    required this.textFr,
  });

  final String id;
  final String emoji;
  final String textEn;
  final String textTr;
  final String textFi;
  final String textFr;

  factory Topic.fromJson(
    Map<String, dynamic> json,
    Map<String, Map<String, dynamic>>? languageData,
  ) {
    final id = json['id'] as String;
    final emoji = json['emoji'] as String;

    // Get text from language files
    String textEn = '';
    String textTr = '';
    String textFi = '';
    String textFr = '';

    if (languageData != null) {
      textEn = languageData['en']?['topics']?[id] ?? '';
      textTr = languageData['tr']?['topics']?[id] ?? '';
      textFi = languageData['fi']?['topics']?[id] ?? '';
      textFr = languageData['fr']?['topics']?[id] ?? '';
    }

    return Topic(
      id: id,
      emoji: emoji,
      textEn: textEn,
      textTr: textTr,
      textFi: textFi,
      textFr: textFr,
    );
  }

  String getName(String languageCode) {
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
}
