import 'package:flutter/material.dart';
import 'package:lingos/models/topic.dart';
import 'package:lingos/models/term.dart';

class SpeakCard extends StatelessWidget {
  const SpeakCard({
    super.key,
    required this.topic,
    required this.term,
    required this.targetLanguageCode,
    required this.isRecording,
    required this.onRecordStart,
    required this.onRecordStop,
  });

  final Topic topic;
  final Term term;
  final String targetLanguageCode;
  final bool isRecording;
  final VoidCallback onRecordStart;
  final VoidCallback onRecordStop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;

    return GestureDetector(
      onLongPressStart: (_) => onRecordStart(),
      onLongPressEnd: (_) => onRecordStop(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isRecording
              ? Colors.red.withValues(alpha: 0.2)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.3),
          border: Border.all(
            color: isRecording ? Colors.red : primary.withValues(alpha: 0.3),
            width: isRecording ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            Icon(
              isRecording ? Icons.mic : Icons.mic_none,
              size: 48,
              color: isRecording ? Colors.red : primary,
            ),
            Text(
              isRecording ? 'Konuş...' : 'Basılı tut ve konuş',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isRecording ? Colors.red : primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
