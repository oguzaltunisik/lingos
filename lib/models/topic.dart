import 'package:flutter/material.dart';

class Topic {
  const Topic({
    required this.id,
    required this.emoji,
    required this.lightColor,
    required this.darkColor,
    required this.textEn,
    required this.textTr,
    required this.textFi,
  });

  final String id;
  final String emoji;
  final Color lightColor;
  final Color darkColor;
  final String textEn;
  final String textTr;
  final String textFi;

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '',
      lightColor: _parseColor(json['lightColor'] as String?),
      darkColor: _parseColor(json['darkColor'] as String?),
      textEn: (json['textEn'] as String? ?? '').toLowerCase(),
      textTr: (json['textTr'] as String? ?? '').toLowerCase(),
      textFi: (json['textFi'] as String? ?? '').toLowerCase(),
    );
  }

  String getName(String languageCode) {
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

  static Color _parseColor(String? hexString) {
    final value = (hexString ?? '').replaceAll('#', '');
    if (value.length == 6) {
      return Color(int.parse('FF$value', radix: 16));
    }
    if (value.length == 8) {
      return Color(int.parse(value, radix: 16));
    }
    return const Color(0xFFCCCCCC);
  }
}
