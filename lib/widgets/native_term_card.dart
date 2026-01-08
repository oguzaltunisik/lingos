import 'package:flutter/material.dart';
import 'package:lingos/models/topic.dart';
import 'package:lingos/models/term.dart';

class NativeTermCard extends StatelessWidget {
  const NativeTermCard({
    super.key,
    required this.term,
    required this.topic,
    required this.showTranslation,
    required this.nativeLanguageText,
  });

  final Term term;
  final Topic topic;
  final bool showTranslation;
  final String? nativeLanguageText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(term.emoji, style: const TextStyle(fontSize: 120)),
          const SizedBox(height: 16),
          if (showTranslation && nativeLanguageText != null)
            Text(
              nativeLanguageText!,
              style: TextStyle(fontSize: 18, color: topic.darkColor),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
