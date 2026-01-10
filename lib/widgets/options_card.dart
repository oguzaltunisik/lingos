import 'package:flutter/material.dart';
import 'package:lingos/models/topic.dart';
import 'package:lingos/models/selection_option.dart';
import 'package:lingos/widgets/visual_card.dart';
import 'package:lingos/widgets/target_card.dart';

class OptionsCard extends StatelessWidget {
  const OptionsCard({
    super.key,
    required this.topic,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
    this.isVisual = false,
    this.highlightedIndex,
    this.highlightColor,
    this.showFeedback = false,
  });

  final Topic topic;
  final List<SelectionOption> options;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final bool isVisual;
  final int? highlightedIndex;
  final Color? highlightColor;
  final bool showFeedback;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12,
      children: [
        Expanded(child: _buildOption(context, options[0], 0)),
        Expanded(child: _buildOption(context, options[1], 1)),
      ],
    );
  }

  Widget _buildOption(BuildContext context, SelectionOption item, int index) {
    final isSelected = selectedIndex == index && !showFeedback;
    void onTap() => onSelect(index);
    final applyHighlight = showFeedback && highlightedIndex == index;
    final Color? overrideColor = applyHighlight ? highlightColor : null;

    if (isVisual && item.term != null) {
      return VisualCard(
        term: item.term!,
        topic: topic,
        isSelected: isSelected,
        onTap: onTap,
        overrideColor: overrideColor,
      );
    }

    // Fallback visual mode without term: use emoji+text inside a decorated container
    if (isVisual) {
      final scheme = Theme.of(context).colorScheme;
      final primary = scheme.primary;
      final onPrimary = scheme.onPrimary;
      final bgColor =
          overrideColor ??
          (isSelected ? primary.withValues(alpha: 0.08) : Colors.transparent);
      final textColor = overrideColor != null
          ? onPrimary
          : isSelected
          ? onPrimary
          : primary;
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: bgColor,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.emoji != null)
                    Text(
                      item.emoji!,
                      style: TextStyle(fontSize: 72, color: textColor),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    item.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Non-visual: show target term card with selection styling
    return TargetCard(
      topic: topic,
      targetText: item.text,
      languageCode: item.languageCode ?? 'en',
      isSelected: isSelected,
      onTap: onTap,
      overrideColor: overrideColor,
    );
  }
}
