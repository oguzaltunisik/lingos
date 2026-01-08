import 'package:flutter/material.dart';

enum Topic {
  greetings(
    id: 'greetings',
    emoji: '👋',
    lightColor: Color(0xFFE8EEF9),
    darkColor: Color(0xFF2F5DA8),
  ),
  travel(
    id: 'travel',
    emoji: '✈️',
    lightColor: Color(0xFFE7F5F3),
    darkColor: Color(0xFF1E6C63),
  ),
  food(
    id: 'food',
    emoji: '🍽️',
    lightColor: Color(0xFFFFF4E6),
    darkColor: Color(0xFFB25B12),
  ),
  shopping(
    id: 'shopping',
    emoji: '🛍️',
    lightColor: Color(0xFFF9EAF4),
    darkColor: Color(0xFF9B2169),
  ),
  dailyLife(
    id: 'daily_life',
    emoji: '🏠',
    lightColor: Color(0xFFEAF5EA),
    darkColor: Color(0xFF2E7D32),
  );

  const Topic({
    required this.id,
    required this.emoji,
    required this.lightColor,
    required this.darkColor,
  });

  final String id;
  final String emoji;
  final Color lightColor;
  final Color darkColor;
}
