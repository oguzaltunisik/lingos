import 'package:flutter/material.dart';
import 'package:lingos/models/term.dart';

class MergeCard extends StatelessWidget {
  const MergeCard({
    super.key,
    required this.term,
    required this.targetLanguageCode,
    required this.chunks,
    required this.shuffledIndices,
    required this.selectedIndices,
    required this.onToggle,
  });

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

    if (chunks.isEmpty || shuffledIndices.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: const Center(child: Text('No chunks available')),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: shuffledIndices.map((i) {
              final selected = selectedIndices.contains(i);
              final chunkText = i < chunks.length ? chunks[i] : '';
              return Opacity(
                opacity: selected ? 0 : 1,
                child: IgnorePointer(
                  ignoring: selected,
                  child: FilterChip(
                    label: Text(
                      chunkText,
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    selected: false,
                    onSelected: selected ? null : (_) => onToggle(i),
                    backgroundColor: primary,
                    selectedColor: primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
