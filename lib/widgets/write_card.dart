import 'package:flutter/material.dart';
import 'package:lingos/models/topic.dart';

class WriteCard extends StatelessWidget {
  const WriteCard({
    super.key,
    required this.topic,
    required this.onTap,
    this.text,
    this.showBorder = false,
  });

  final Topic topic;
  final VoidCallback onTap;
  final String? text;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final bgColor = Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: bgColor,
            border: showBorder
                ? Border.all(color: primary.withValues(alpha: 0.3), width: 1)
                : Border.all(
                    color: primary.withValues(alpha: 0.2),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: text == null || text!.isEmpty
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_rounded, color: primary, size: 32),
                        const SizedBox(width: 8),
                        Text(
                          'Tap to write',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: primary,
                          ),
                        ),
                      ],
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        text!,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
