import 'package:flutter/material.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/tts_service.dart';

class AudioCard extends StatelessWidget {
  const AudioCard({
    super.key,
    required this.term,
    this.onSelected,
    this.overrideColor,
    this.showBorder = false,
  });

  final Term term;
  final bool Function()? onSelected; // Returns true if should play TTS
  final Color? overrideColor;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = overrideColor ?? scheme.primary;
    final onPrimary = scheme.onPrimary;
    final bgColor = overrideColor ?? Colors.transparent;
    final iconColor = overrideColor != null ? onPrimary : primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          // Update selection state and check if should play TTS
          final shouldPlayTts = onSelected?.call() ?? false;
          // Play TTS only if selection was made (not deselected)
          if (shouldPlayTts) {
            final targetLang = await LanguageService.getTargetLanguage();
            if (targetLang != null) {
              final text = term.getText(targetLang);
              if (text.isNotEmpty) {
                await TtsService.speakTerm(
                  text: text,
                  languageCode: targetLang,
                );
              }
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: bgColor,
            border: showBorder
                ? Border.all(color: primary.withValues(alpha: 0.3), width: 1)
                : null,
          ),
          child: Center(
            child: Icon(Icons.volume_up_rounded, size: 40, color: iconColor),
          ),
        ),
      ),
    );
  }
}
