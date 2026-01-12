class Topic {
  const Topic({
    required this.id,
    required this.emoji,
    required this.textEn,
    required this.textTr,
    required this.textFi,
  });

  final String id;
  final String emoji;
  final String textEn;
  final String textTr;
  final String textFi;

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] as String,
      emoji: json['emoji'] as String,
      textEn: json['textEn'] as String,
      textTr: json['textTr'] as String,
      textFi: json['textFi'] as String,
    );
  }

  String getName(String languageCode) {
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
}
