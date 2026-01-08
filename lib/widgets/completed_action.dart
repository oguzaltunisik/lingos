import 'package:flutter/material.dart';
import 'package:lingos/models/topic.dart';

class CompletedAction extends StatelessWidget {
  const CompletedAction({
    super.key,
    required this.topic,
    required this.title,
    required this.homeLabel,
    required this.onHome,
  });

  final Topic topic;
  final String title;
  final String homeLabel;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🎉', style: const TextStyle(fontSize: 80)),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: topic.darkColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onHome,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: topic.darkColor,
                foregroundColor: Colors.white,
              ),
              child: Text(homeLabel, style: const TextStyle(fontSize: 18)),
            ),
          ),
        ),
      ],
    );
  }
}
