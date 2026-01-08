import 'package:flutter/material.dart';
import 'package:lingos/models/topic.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/widgets/native_term_card.dart';
import 'package:lingos/widgets/target_term_card.dart';

class DisplayAction extends StatelessWidget {
  const DisplayAction({
    super.key,
    required this.topic,
    required this.term,
    required this.showTranslation,
    required this.nativeLanguageCode,
    required this.targetLanguageCode,
    required this.onNext,
    required this.nextLabel,
  });

  final Topic topic;
  final Term term;
  final bool showTranslation;
  final String? nativeLanguageCode;
  final String? targetLanguageCode;
  final VoidCallback onNext;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Term display
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (nativeLanguageCode != null)
                    Expanded(
                      child: NativeTermCard(
                        term: term,
                        topic: topic,
                        showTranslation: showTranslation,
                        nativeLanguageText: term.getText(nativeLanguageCode!),
                      ),
                    ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: topic.darkColor.withValues(alpha: 0.25),
                  ),
                  if (targetLanguageCode != null)
                    Expanded(
                      child: TargetTermCard(
                        topic: topic,
                        targetText: term.getText(targetLanguageCode!),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Action button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: topic.darkColor,
                foregroundColor: Colors.white,
              ),
              child: Text(nextLabel, style: const TextStyle(fontSize: 18)),
            ),
          ),
        ),
      ],
    );
  }
}
