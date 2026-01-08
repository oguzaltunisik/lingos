import 'package:flutter/material.dart';
import 'package:lingos/pages/language_selection_page.dart';
import 'package:lingos/services/app_localizations.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/user_prefs_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.appLanguageNotifier,
      builder: (context, languageCode, child) {
        final localizations = AppLocalizations(languageCode);

        return Scaffold(
          appBar: AppBar(title: Text(localizations.settingsTitle)),
          body: ListView(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.translate),
                title: Text(localizations.showTranslation),
                value: UserPrefsService.showTranslationNotifier.value,
                onChanged: (value) {
                  UserPrefsService.setShowTranslation(value);
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(localizations.languageSettings),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LanguageSelectionPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
