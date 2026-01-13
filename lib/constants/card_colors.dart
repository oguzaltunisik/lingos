import 'package:flutter/material.dart';

// Card color status for visual feedback
enum CardColorStatus {
  deselected, // Default state
  selected, // Selected/highlighted state
  correct, // Correct answer feedback
  incorrect, // Incorrect answer feedback
}

// Extension to get color from CardColorStatus
extension CardColorStatusExtension on CardColorStatus {
  Color getColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (this) {
      case CardColorStatus.deselected:
        return scheme.primary;
      case CardColorStatus.selected:
        return scheme.primary;
      case CardColorStatus.correct:
        return Colors.green;
      case CardColorStatus.incorrect:
        return Colors.red;
    }
  }

  Color getBackgroundColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (this) {
      case CardColorStatus.deselected:
        return Colors.transparent;
      case CardColorStatus.selected:
        return scheme.primary;
      case CardColorStatus.correct:
        return Colors.green;
      case CardColorStatus.incorrect:
        return Colors.red;
    }
  }

  Color getTextColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (this) {
      case CardColorStatus.deselected:
        return scheme.primary;
      case CardColorStatus.selected:
        return scheme.onPrimary;
      case CardColorStatus.correct:
        return Colors.white;
      case CardColorStatus.incorrect:
        return Colors.white;
    }
  }
}

