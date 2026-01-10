import 'package:flutter/material.dart';
import 'package:lingos/models/topic.dart';
import 'package:lingos/models/term.dart';

class MergeCard extends StatelessWidget {
  const MergeCard({
    super.key,
    required this.topic,
    required this.term,
    required this.targetLanguageCode,
    required this.chunks,
    required this.shuffledIndices,
    required this.selectedIndices,
    required this.onToggle,
  });

  final Topic topic;
  final Term term;
  final String targetLanguageCode;
  final List<String> chunks;
  final List<int> shuffledIndices;
  final List<int> selectedIndices;
  final void Function(int idx) onToggle;

  static List<String> buildChunks(String text) {
    final letters = text.characters.toList();
    if (letters.isEmpty) return [];
    final chunkCount = letters.length >= 6 ? 3 : 2;
    final base = letters.length ~/ chunkCount;
    final remainder = letters.length % chunkCount;
    final result = <String>[];
    int cursor = 0;
    for (int i = 0; i < chunkCount; i++) {
      final take = base + (i < remainder ? 1 : 0);
      result.add(letters.sublist(cursor, cursor + take).join());
      cursor += take;
    }
    return result.where((s) => s.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;

    final chips = shuffledIndices.map((i) {
      final selected = selectedIndices.contains(i);
      return Opacity(
        opacity: selected ? 0 : 1,
        child: IgnorePointer(
          ignoring: selected,
          child: FilterChip(
            label: Text(
              i < chunks.length ? chunks[i] : '',
              style: TextStyle(
                color: selected ? scheme.onPrimary : primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            selected: selected,
            selectedColor: primary,
            showCheckmark: false,
            onSelected: (_) => onToggle(i),
            side: BorderSide(color: primary.withValues(alpha: 0.3)),
          ),
        ),
      );
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 12,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: chips,
          ),
        ],
      ),
    );
  }
}
