import 'package:flutter/material.dart';
import 'package:lingos/models/topic.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/app_localizations.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/term_service.dart';
import 'package:lingos/widgets/action_button.dart';

class TopicTermsBottomSheet extends StatefulWidget {
  final Topic topic;
  final VoidCallback onStartLesson;

  const TopicTermsBottomSheet({
    super.key,
    required this.topic,
    required this.onStartLesson,
  });

  @override
  State<TopicTermsBottomSheet> createState() => _TopicTermsBottomSheetState();
}

class _TopicTermsBottomSheetState extends State<TopicTermsBottomSheet> {
  List<(Term, int)> _termsWithLevels = [];
  bool _isLoading = true;
  String? _targetLanguageCode;

  @override
  void initState() {
    super.initState();
    _loadTermsWithLevels();
  }

  Future<void> _loadTermsWithLevels() async {
    final targetLang = await LanguageService.getTargetLanguage();
    final terms = TermService.getTermsByTopic(widget.topic.id);
    final termsWithLevels = <(Term, int)>[];

    // Keep JSON order (no sorting)
    for (final term in terms) {
      final level = await term.getLearningLevel();
      termsWithLevels.add((term, level));
    }

    setState(() {
      _targetLanguageCode = targetLang ?? 'en';
      _termsWithLevels = termsWithLevels;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.current;
    final scheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Text(
            loc.getTopicName(widget.topic.id),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: scheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.topic.emoji,
            style: const TextStyle(fontSize: 48),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Terms list
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                itemCount: _termsWithLevels.length,
                itemBuilder: (context, index) {
                  final (term, level) = _termsWithLevels[index];
                  final termText = term.getText(_targetLanguageCode ?? 'en');

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: scheme.primaryContainer,
                        child: Text(
                          term.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      title: Text(
                        termText,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${loc.levelLabel} $level',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
          // Start lesson button
          ActionButton(
            label: loc.startLessonButton,
            onPressed: () {
              Navigator.of(context).pop();
              widget.onStartLesson();
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
