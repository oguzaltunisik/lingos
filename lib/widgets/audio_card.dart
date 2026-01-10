import 'package:flutter/material.dart';
import 'package:lingos/models/topic.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/tts_service.dart';

class AudioCard extends StatelessWidget {
  const AudioCard({
    super.key,
    required this.topic,
    required this.term,
    this.isSelected = false,
    this.onSelected,
    this.overrideColor,
  });

  final Topic topic;
  final Term term;
  final bool isSelected;
  final VoidCallback? onSelected;
  final Color? overrideColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = overrideColor ?? scheme.primary;
    final onPrimary = scheme.onPrimary;
    final bgColor =
        overrideColor ?? (isSelected ? primary : Colors.transparent);
    final iconColor = overrideColor != null
        ? onPrimary
        : isSelected
        ? onPrimary
        : primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          // First update selection state
          onSelected?.call();
          // Then play TTS
          final targetLang = await LanguageService.getTargetLanguage();
          if (targetLang != null) {
            final text = term.getText(targetLang);
            if (text.isNotEmpty) {
              await TtsService.speakTerm(text: text, languageCode: targetLang);
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: bgColor,
          ),
          child: Center(
            child: Icon(Icons.volume_up_rounded, size: 40, color: iconColor),
          ),
        ),
      ),
    );
  }
}
