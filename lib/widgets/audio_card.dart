import 'package:flutter/material.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/tts_service.dart';
import 'package:lingos/constants/card_colors.dart';

class AudioCard extends StatelessWidget {
  const AudioCard({
    super.key,
    required this.term,
    required this.targetLanguageCode,
    this.onSelected,
    this.colorStatus = CardColorStatus.deselected,
    this.showBorder = false,
  });

  final Term term;
  final String targetLanguageCode;
  final bool Function()? onSelected; // Returns true if should play TTS
  final CardColorStatus colorStatus;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final primary = colorStatus.getColor(context);
    final bgColor = colorStatus.getBackgroundColor(context);
    final iconColor = colorStatus.getTextColor(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          // Update selection state and check if should play TTS
          final shouldPlayTts = onSelected?.call() ?? false;
          // Play TTS only if selection was made (not deselected)
          if (shouldPlayTts) {
            final text = term.getText(targetLanguageCode);
            if (text.isNotEmpty) {
              await TtsService.speakTerm(
                text: text,
                languageCode: targetLanguageCode,
              );
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
