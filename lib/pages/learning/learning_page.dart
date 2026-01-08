import 'package:flutter/material.dart';
import 'dart:math';

import 'package:lingos/models/topic.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/app_localizations.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/term_service.dart';
import 'package:lingos/pages/learning/actions/meet_action.dart';
import 'package:lingos/widgets/completed_action.dart';
import 'package:lingos/pages/learning/actions/listen_and_select_action.dart';

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

  int get _totalSteps => _terms.length * 2;

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
        final localizations = AppLocalizations(languageCode);

        final isLoading = _terms.isEmpty;
        final currentTerm = (!isLoading && _currentStep < _totalSteps)
            ? _terms[_currentStep ~/ 2]
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
        if (_currentStep >= _totalSteps) {
          return Scaffold(
            backgroundColor: widget.topic.lightColor,
            appBar: appBar,
            body: CompletedAction(
              topic: widget.topic,
              onHome: () => Navigator.of(context).pop(),
            ),
          );
        }

        final term = currentTerm!;
        final isDisplayStep = _currentStep % 2 == 0;
        final body = isDisplayStep
            ? MeetAction(topic: widget.topic, term: term, onNext: _nextStep)
            : ListenAndSelectAction(
                topic: widget.topic,
                term: term,
                distractorTerm: _getDistractorTerm(_currentStep ~/ 2),
                onNext: _nextStep,
                nextLabel: localizations.nextButton,
              );

        return Scaffold(
          backgroundColor: widget.topic.lightColor,
          appBar: appBar,
          body: body,
        );
      },
    );
  }
}
