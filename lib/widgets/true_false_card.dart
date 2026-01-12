import 'package:flutter/material.dart';

class TrueFalseCard extends StatelessWidget {
  const TrueFalseCard({
    super.key,
    required this.onSelect,
    this.selectedValue,
    this.showFeedback = false,
    this.isCorrect = false,
    this.correctValue,
  });

  final ValueChanged<bool> onSelect;
  final bool? selectedValue;
  final bool showFeedback;
  final bool isCorrect;
  final bool? correctValue; // The correct answer value

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final onPrimary = scheme.onPrimary;
    final error = scheme.error;
    final onError = scheme.onError;

    return Row(
      spacing: 16,
      children: [
        Expanded(
          child: _buildButton(
            context,
            value: false,
            scheme: scheme,
            primary: primary,
            onPrimary: onPrimary,
            error: error,
            onError: onError,
          ),
        ),
        Expanded(
          child: _buildButton(
            context,
            value: true,
            scheme: scheme,
            primary: primary,
            onPrimary: onPrimary,
            error: error,
            onError: onError,
          ),
        ),
      ],
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required bool value,
    required ColorScheme scheme,
    required Color primary,
    required Color onPrimary,
    required Color error,
    required Color onError,
  }) {
    final isSelected = selectedValue == value;
    final isCorrectAnswer = isCorrect && isSelected;
    final shouldShowFeedback = showFeedback && isSelected;

    Color backgroundColor;
    Color iconColor;
    VoidCallback? onTap;
    IconData icon;

    if (shouldShowFeedback) {
      // Show feedback color only for selected button
      if (isCorrectAnswer) {
        // Selected and correct - green
        backgroundColor = Colors.green;
        iconColor = Colors.white;
      } else {
        // Selected but incorrect - red
        backgroundColor = error;
        iconColor = onError;
      }
      onTap = null; // Disable after feedback
    } else if (isSelected) {
      // Selected but no feedback yet
      backgroundColor = primary.withValues(alpha: 0.2);
      iconColor = primary;
      onTap = () => onSelect(value);
    } else {
      // Not selected
      backgroundColor = Colors.transparent;
      iconColor = primary;
      onTap = () => onSelect(value);
    }

    // Set icon based on value
    icon = value ? Icons.check_rounded : Icons.close_rounded;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: backgroundColor,
          border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1),
        ),
        child: Center(child: Icon(icon, size: 40, color: iconColor)),
      ),
    );
  }
}
