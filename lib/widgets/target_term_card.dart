import 'package:flutter/material.dart';
import 'package:lingos/models/topic.dart';

class TargetTermCard extends StatelessWidget {
  const TargetTermCard({
    super.key,
    required this.topic,
    required this.targetText,
  });

  final Topic topic;
  final String targetText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Text(
          targetText,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: topic.darkColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
