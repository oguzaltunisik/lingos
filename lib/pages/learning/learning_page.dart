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
import 'package:lingos/pages/learning/actions/write_action.dart';
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

  int get _totalSteps => _terms.length * LearningActionType.values.length;

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
        final currentTerm = (!isLoading && _currentStep < _totalSteps)
            ? _terms[_currentStep ~/ LearningActionType.values.length]
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
        final actionType = LearningActionType
            .values[_currentStep % LearningActionType.values.length];
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
                _currentStep ~/ LearningActionType.values.length,
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
                _currentStep ~/ LearningActionType.values.length,
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
              distractorTerm: _getDistractorTerm(
                _currentStep ~/ LearningActionType.values.length,
              ),
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
              distractorTerm: _getDistractorTerm(
                _currentStep ~/ LearningActionType.values.length,
              ),
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
          case LearningActionType.write:
            // Write action
            final allWriteTypes = WriteActionType.values;
            final randomIndex = _random.nextInt(allWriteTypes.length);
            body = WriteAction(
              term: term,
              onNext: _nextStep,
              type: allWriteTypes[randomIndex],
            );
            break;
        }

        return Scaffold(appBar: appBar, body: body);
      },
    );
  }
}
