import 'package:flutter/material.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/app_localizations.dart';
import 'package:lingos/pages/learning/learning_page.dart';
import 'package:lingos/pages/settings_page.dart';
import 'package:lingos/pages/topic_terms_bottom_sheet.dart';
import 'package:lingos/services/term_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.appLanguageNotifier,
      builder: (context, languageCode, child) {
        final localizations = AppLocalizations(languageCode);

        final topics = TermService.getTopics();

        if (topics.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(localizations.appTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(localizations.appTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: topics.map((topic) {
                final scheme = Theme.of(context).colorScheme;
                return Card(
                  color: scheme.surfaceContainerHighest,
                  surfaceTintColor: scheme.surfaceContainerHighest,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => TopicTermsBottomSheet(
                          topic: topic,
                          onStartLesson: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    LearningPage(topic: topic),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                topic.emoji,
                                style: const TextStyle(fontSize: 36),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                localizations.getTopicName(topic.id),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
