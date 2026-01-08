import 'package:flutter/material.dart';
import 'package:lingos/models/topic.dart';

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.topic,
    required this.label,
    this.onPressed,
  });

  final Topic topic;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: topic.darkColor,
            foregroundColor: Colors.white,
          ),
          child: Text(label, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
