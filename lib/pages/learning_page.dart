import 'package:flutter/material.dart';
import 'package:lingos/models/topic.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/app_localizations.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/term_service.dart';
import 'package:lingos/services/user_prefs_service.dart';
import 'package:lingos/services/tts_service.dart';
import 'package:lingos/widgets/display_action.dart';
import 'package:lingos/widgets/completed_action.dart';

class LearningPage extends StatefulWidget {
  final Topic topic;

  const LearningPage({super.key, required this.topic});

  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> {
  int _currentIndex = 0;
  List<Term> _terms = [];
  String? _nativeLanguage;
  String? _targetLanguage;
  late final VoidCallback _prefsListener;
  bool _showTranslation = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _showTranslation = UserPrefsService.showTranslationNotifier.value;
    _prefsListener = () {
      if (!mounted) return;
      setState(() {
        _showTranslation = UserPrefsService.showTranslationNotifier.value;
      });
    };
    UserPrefsService.showTranslationNotifier.addListener(_prefsListener);
  }

  Future<void> _loadData() async {
    final terms = TermService.getTermsByTopic(widget.topic.id);
    final nativeLang = await LanguageService.getNativeLanguage();
    final targetLang = await LanguageService.getTargetLanguage();

    setState(() {
      _terms = terms;
      _nativeLanguage = nativeLang;
      _targetLanguage = targetLang;
    });
    await _speakCurrentTerm();
  }

  void _nextTerm() {
    if (_currentIndex < _terms.length) {
      setState(() {
        _currentIndex++;
      });
      if (_currentIndex < _terms.length) {
        _speakCurrentTerm();
      }
    }
  }

  @override
  void dispose() {
    UserPrefsService.showTranslationNotifier.removeListener(_prefsListener);
    TtsService.stop();
    super.dispose();
  }

  double get _progress {
    if (_terms.isEmpty) return 0.0;
    return (_currentIndex + 1) / _terms.length;
  }

  Future<void> _speakCurrentTerm() async {
    if (_terms.isEmpty || _targetLanguage == null) return;
    final term = _terms[_currentIndex];
    await TtsService.speakTerm(
      text: term.getText(_targetLanguage!),
      languageCode: _targetLanguage!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.appLanguageNotifier,
      builder: (context, languageCode, child) {
        final localizations = AppLocalizations(languageCode);

        final isLoading = _terms.isEmpty;
        final currentTerm = (!isLoading && _currentIndex < _terms.length)
            ? _terms[_currentIndex]
            : null;

        final appBar = AppBar(
          backgroundColor: widget.topic.lightColor,
          foregroundColor: widget.topic.darkColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.topic.darkColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: LinearProgressIndicator(
                  value: isLoading ? null : _progress,
                  minHeight: 6,
                  color: widget.topic.darkColor,
                  backgroundColor: widget.topic.lightColor,
                ),
              ),
            ),
          ),
        );

        if (isLoading) {
          return Scaffold(
            backgroundColor: widget.topic.lightColor,
            appBar: appBar,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Completed view when terms finished
        if (_currentIndex >= _terms.length) {
          return Scaffold(
            backgroundColor: widget.topic.lightColor,
            appBar: appBar,
            body: CompletedAction(
              topic: widget.topic,
              title: localizations.sessionCompleted,
              homeLabel: localizations.homePageButton,
              onHome: () => Navigator.of(context).pop(),
            ),
          );
        }

        final term = currentTerm!;
        return Scaffold(
          backgroundColor: widget.topic.lightColor,
          appBar: appBar,
          body: DisplayAction(
            topic: widget.topic,
            term: term,
            showTranslation: _showTranslation,
            nativeLanguageCode: _nativeLanguage,
            targetLanguageCode: _targetLanguage,
            onNext: _nextTerm,
            nextLabel: localizations.nextButton,
          ),
        );
      },
    );
  }
}
