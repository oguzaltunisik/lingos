import 'package:flutter/material.dart' hide SelectAction;
import 'dart:math';

import 'package:lingos/models/topic.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/app_localizations.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/term_service.dart';
import 'package:lingos/pages/learning/actions/meet_action.dart';
import 'package:lingos/pages/learning/actions/completed_action.dart';
import 'package:lingos/pages/learning/actions/select_action.dart';
import 'package:lingos/pages/learning/actions/merge_action.dart';
import 'package:lingos/pages/learning/actions/pair_action.dart';

class LearningPage extends StatefulWidget {
  final Topic topic;

  const LearningPage({super.key, required this.topic});

  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> {
  final Random _random = Random();
  int _currentStep = 0;
  List<Term> _terms = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final terms = TermService.getTermsByTopic(widget.topic.id);

    setState(() {
      _terms = terms;
    });
  }

  void _nextStep() {
    final totalSteps = _totalSteps;
    if (_currentStep < totalSteps) {
      setState(() {
        _currentStep++;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  double get _progress {
    if (_terms.isEmpty) return 0.0;
    return (_currentStep + 1) / _totalSteps;
  }

  int get _totalSteps => _terms.length * 3 + 1;

  Term _getDistractorTerm(int correctIndex) {
    if (_terms.length < 2) return _terms[correctIndex];
    int candidate = correctIndex;
    while (candidate == correctIndex) {
      candidate = _random.nextInt(_terms.length);
    }
    return _terms[candidate];
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.appLanguageNotifier,
      builder: (context, languageCode, child) {
        final isLoading = _terms.isEmpty;
        final isPairAction = !isLoading && _currentStep == _totalSteps - 1;
        final currentTerm =
            (!isLoading && !isPairAction && _currentStep < _totalSteps)
            ? _terms[_currentStep ~/ 3]
            : null;
        final scheme = Theme.of(context).colorScheme;

        final appBar = AppBar(
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
                    color: scheme.primary.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: LinearProgressIndicator(
                  value: isLoading ? null : _progress,
                  minHeight: 6,
                  color: scheme.primary,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _currentStep + 1 >= _totalSteps ? null : _nextStep,
              child: Text(
                AppLocalizations.current.skipButton,
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );

        if (isLoading) {
          return Scaffold(
            appBar: appBar,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Pair action at the end (before completion)
        if (isPairAction) {
          // Show pair action with a subset of terms (4-6 terms)
          final pairTerms = _terms.length > 6
              ? (_terms.toList()..shuffle(_random)).take(6).toList()
              : _terms;
          return Scaffold(
            appBar: appBar,
            body: PairAction(
              topic: widget.topic,
              terms: pairTerms,
              onNext: _nextStep,
            ),
          );
        }

        // Completed view when terms finished
        if (_currentStep >= _totalSteps) {
          return Scaffold(
            appBar: appBar,
            body: CompletedAction(
              topic: widget.topic,
              onHome: () => Navigator.of(context).pop(),
            ),
          );
        }

        final term = currentTerm!;
        final stepMod = _currentStep % 3;
        final hasQuestions =
            term.questions != null && term.questions!.isNotEmpty;
        Widget body;
        if (stepMod == 0) {
          body = MeetAction(topic: widget.topic, term: term, onNext: _nextStep);
        } else if (stepMod == 1) {
          final allSelectTypes = SelectActionType.values;
          final selectTypes = hasQuestions
              ? allSelectTypes
              : allSelectTypes
                    .where(
                      (t) =>
                          t != SelectActionType.questionToTarget &&
                          t != SelectActionType.questionToAudio,
                    )
                    .toList();
          final randomIndex = _random.nextInt(selectTypes.length);
          body = SelectAction(
            topic: widget.topic,
            term: term,
            distractorTerm: _getDistractorTerm(_currentStep ~/ 3),
            onNext: _nextStep,
            type: selectTypes[randomIndex],
          );
        } else {
          final allMergeTypes = MergeActionType.values;
          final mergeTypes = hasQuestions
              ? allMergeTypes
              : allMergeTypes
                    .where((t) => t != MergeActionType.questionToTarget)
                    .toList();
          final randomIndex = _random.nextInt(mergeTypes.length);
          body = MergeAction(
            topic: widget.topic,
            term: term,
            onNext: _nextStep,
            type: mergeTypes[randomIndex],
          );
        }

        return Scaffold(appBar: appBar, body: body);
      },
    );
  }
}
