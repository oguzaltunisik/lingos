import 'package:flutter/material.dart' hide SelectAction;
import 'dart:math';

import 'package:lingos/models/topic.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/app_localizations.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/term_service.dart';
import 'package:lingos/pages/learning/actions/display_action.dart';
import 'package:lingos/pages/learning/actions/completed_action.dart';
import 'package:lingos/pages/learning/actions/memory_action.dart';
import 'package:lingos/pages/learning/actions/pair_action.dart';
import 'package:lingos/pages/learning/actions/select_action.dart';
import 'package:lingos/pages/learning/actions/true_false_action.dart';
import 'package:lingos/pages/learning/actions/merge_action.dart';
import 'package:lingos/pages/learning/actions/speak_action.dart';
import 'package:lingos/pages/learning/action_types.dart';

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

  double get _progress {
    if (_terms.isEmpty) return 0.0;
    return (_currentStep + 1) / _totalSteps;
  }

  // Single-term actions that should show remember after completion
  static const List<LearningActionType> _singleTermActions = [
    LearningActionType.display,
    LearningActionType.select,
    LearningActionType.trueFalse,
    LearningActionType.merge,
    LearningActionType.speak,
  ];

  // Multi-term actions that don't show remember
  static const List<LearningActionType> _multiTermActions = [
    LearningActionType.pair,
    LearningActionType.memory,
  ];

  // Calculate total steps: each term has single-term actions + remember steps + multi-term actions
  int get _totalSteps {
    // Each term: 5 single-term actions + 5 remember steps + 2 multi-term actions = 12 steps
    return _terms.length *
        (_singleTermActions.length * 2 + _multiTermActions.length);
  }

  // Get the current action type and whether we should show remember
  (LearningActionType?, bool) _getActionTypeAndRemember(int step) {
    final stepsPerTerm =
        _singleTermActions.length * 2 + _multiTermActions.length;
    final termIndex = step ~/ stepsPerTerm;
    final stepInTerm = step % stepsPerTerm;

    if (termIndex >= _terms.length) {
      return (null, false);
    }

    int currentStep = 0;

    // Process single-term actions with remember
    for (final action in _singleTermActions) {
      if (currentStep == stepInTerm) {
        return (action, false); // Action step
      }
      currentStep++;
      if (currentStep == stepInTerm) {
        return (action, true); // Remember step after action
      }
      currentStep++;
    }

    // Process multi-term actions (no remember)
    final multiTermStep = stepInTerm - (_singleTermActions.length * 2);
    if (multiTermStep >= 0 && multiTermStep < _multiTermActions.length) {
      return (_multiTermActions[multiTermStep], false);
    }

    return (null, false);
  }

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
        final stepsPerTerm =
            _singleTermActions.length * 2 + _multiTermActions.length;
        final currentTerm = (!isLoading && _currentStep < _totalSteps)
            ? _terms[_currentStep ~/ stepsPerTerm]
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

        // Completed view when terms finished
        if (_currentStep >= _totalSteps) {
          return Scaffold(
            appBar: appBar,
            body: CompletedAction(onHome: () => Navigator.of(context).pop()),
          );
        }

        final term = currentTerm!;
        final (actionType, showRemember) = _getActionTypeAndRemember(
          _currentStep,
        );

        if (actionType == null) {
          return Scaffold(appBar: appBar, body: const SizedBox.shrink());
        }

        // If this is a remember step, show DisplayAction in remember mode
        if (showRemember) {
          Widget body = DisplayAction(
            term: term,
            onNext: _nextStep,
            mode: DisplayMode.remember,
          );
          return Scaffold(appBar: appBar, body: body);
        }

        final hasQuestions =
            term.questions != null && term.questions!.isNotEmpty;
        Widget body;
        switch (actionType) {
          case LearningActionType.display:
            body = DisplayAction(
              term: term,
              onNext: _nextStep,
              mode: DisplayMode.meet,
            );
            break;
          case LearningActionType.memory:
            // Memory action - use current term and 2 distractors
            final memoryTerms = <Term>[term];
            while (memoryTerms.length < 3) {
              final distractor = _getDistractorTerm(
                _currentStep ~/ stepsPerTerm,
              );
              if (!memoryTerms.contains(distractor)) {
                memoryTerms.add(distractor);
              } else {
                // If distractor is same, get another one
                int candidate = _random.nextInt(_terms.length);
                while (memoryTerms.contains(_terms[candidate])) {
                  candidate = _random.nextInt(_terms.length);
                }
                memoryTerms.add(_terms[candidate]);
              }
            }
            final allMemoryTypes = MemoryActionType.values;
            final randomIndex = _random.nextInt(allMemoryTypes.length);
            body = MemoryAction(
              terms: memoryTerms,
              onNext: _nextStep,
              type: allMemoryTypes[randomIndex],
            );
            break;
          case LearningActionType.pair:
            // Pair action - use current term and 2 distractors
            final pairTerms = <Term>[term];
            while (pairTerms.length < 3) {
              final distractor = _getDistractorTerm(
                _currentStep ~/ stepsPerTerm,
              );
              if (!pairTerms.contains(distractor)) {
                pairTerms.add(distractor);
              } else {
                // If distractor is same, get another one
                int candidate = _random.nextInt(_terms.length);
                while (pairTerms.contains(_terms[candidate])) {
                  candidate = _random.nextInt(_terms.length);
                }
                pairTerms.add(_terms[candidate]);
              }
            }
            final allPairTypes = PairActionType.values;
            final randomIndex = _random.nextInt(allPairTypes.length);
            body = PairAction(
              terms: pairTerms,
              onNext: _nextStep,
              type: allPairTypes[randomIndex],
            );
            break;
          case LearningActionType.select:
            // Select action
            final allSelectTypes = SelectActionType.values;
            final selectTypes = hasQuestions
                ? allSelectTypes
                : allSelectTypes
                      .where((t) => t != SelectActionType.questionToTarget)
                      .toList();
            final randomIndex = _random.nextInt(selectTypes.length);
            body = SelectAction(
              term: term,
              distractorTerm: _getDistractorTerm(_currentStep ~/ stepsPerTerm),
              onNext: _nextStep,
              type: selectTypes[randomIndex],
            );
            break;
          case LearningActionType.trueFalse:
            // True/False action
            final allTrueFalseTypes = TrueFalseActionType.values;
            final randomIndex = _random.nextInt(allTrueFalseTypes.length);
            body = TrueFalseAction(
              term: term,
              distractorTerm: _getDistractorTerm(_currentStep ~/ stepsPerTerm),
              onNext: _nextStep,
              type: allTrueFalseTypes[randomIndex],
            );
            break;
          case LearningActionType.merge:
            // Merge action
            final allMergeTypes = MergeActionType.values;
            final mergeTypes = hasQuestions
                ? allMergeTypes
                : allMergeTypes
                      .where((t) => t != MergeActionType.questionToTarget)
                      .toList();
            final randomIndex = _random.nextInt(mergeTypes.length);
            body = MergeAction(
              term: term,
              onNext: _nextStep,
              type: mergeTypes[randomIndex],
            );
            break;
          case LearningActionType.speak:
            // Speak action
            final allSpeakTypes = SpeakActionType.values;
            final speakTypes = hasQuestions
                ? allSpeakTypes
                : allSpeakTypes
                      .where((t) => t != SpeakActionType.questionToTarget)
                      .toList();
            final randomIndex = _random.nextInt(speakTypes.length);
            body = SpeakAction(
              term: term,
              onNext: _nextStep,
              type: speakTypes[randomIndex],
            );
            break;
        }

        return Scaffold(appBar: appBar, body: body);
      },
    );
  }
}
