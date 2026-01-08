import 'package:flutter/material.dart';
import 'package:lingos/models/topic.dart';
import 'package:lingos/services/app_localizations.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/widgets/action_button.dart';

class CompletedAction extends StatelessWidget {
  const CompletedAction({super.key, required this.topic, required this.onHome});

  final Topic topic;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(LanguageService.appLanguageNotifier.value);

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
                    loc.sessionCompleted,
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
        ActionButton(
          topic: topic,
          label: loc.homePageButton,
          onPressed: onHome,
        ),
      ],
    );
  }
}
