import 'package:flutter/material.dart';
import 'package:lingos/services/app_localizations.dart';
import 'package:lingos/widgets/action_button.dart';

class PauseView extends StatelessWidget {
  const PauseView({super.key, required this.onResume, required this.onEnd});

  final VoidCallback onResume;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.current;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 24,
          children: [
            Icon(Icons.pause_circle_outline, size: 80, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              'Paused',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            ActionButton(label: loc.continueButton, onPressed: onResume),
            ActionButton(
              label: loc.homePageButton,
              onPressed: onEnd,
              outlined: true,
            ),
          ],
        ),
      ),
    );
  }
}
