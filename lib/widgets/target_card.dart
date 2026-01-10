import 'package:flutter/material.dart';
import 'package:lingos/models/topic.dart';
import 'package:lingos/services/tts_service.dart';
import 'package:lingos/widgets/mini_icon_button.dart';

class TargetCard extends StatelessWidget {
  const TargetCard({
    super.key,
    required this.topic,
    required this.targetText,
    required this.languageCode,
    this.isSelected = false,
    this.onTap,
    this.overrideColor,
    this.showIcon = true,
  });

  final Topic topic;
  final String targetText;
  final String languageCode;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? overrideColor;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scheme = Theme.of(context).colorScheme;
        final primary = overrideColor ?? scheme.primary;
        final onPrimary = scheme.onPrimary;
        final bgColor =
            overrideColor ?? (isSelected ? primary : Colors.transparent);
        final fgColor = overrideColor != null
            ? onPrimary
            : isSelected
            ? onPrimary
            : primary;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: bgColor,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          targetText,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: fgColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
                if (showIcon)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: MiniIconButton(
                      icon: Icons.volume_up_rounded,
                      color: overrideColor != null
                          ? onPrimary
                          : (isSelected ? onPrimary : primary),
                      onPressed: () async {
                        if (targetText.isEmpty) return;
                        await TtsService.speakTerm(
                          text: targetText,
                          languageCode: languageCode,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
