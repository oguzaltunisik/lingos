import 'package:flutter/material.dart' hide SelectAction;
import 'dart:async';
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
import 'package:lingos/pages/learning/pause_view.dart';

class LearningPage extends StatefulWidget {
  final Topic topic;

  const LearningPage({super.key, required this.topic});

  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> {
  static const int _sessionDurationSeconds = 60;
  static const int _termsPerCycle = 5;

  // Timer state
  int _remainingSeconds = _sessionDurationSeconds;
  bool _isPaused = false;
  Timer? _sessionTimer;

  // Terms state
  List<Term> _allTerms = [];
  List<Term> _selectedTerms = []; // 5 lowest level terms
  int _currentTermIndex = 0;

  // Action state
  bool _showRemember = false;
  Term? _rememberTerm;
  bool _isInSpecialAction = false;
  LearningActionType? _specialActionType;
  List<Term>? _specialActionTerms;
  LearningActionType?
  _currentActionType; // Track current action for remember check

  // Seed for deterministic random
  int _randomSeed = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final terms = TermService.getTermsByTopic(widget.topic.id);

    setState(() {
      _allTerms = terms;
    });

    await _selectLowestLevelTerms();
    _startSession();
  }

  // Select 5 lowest level terms and sort by level
  Future<void> _selectLowestLevelTerms() async {
    if (_allTerms.isEmpty) return;

    // Load levels for all terms
    final termsWithLevels = <(Term, int)>[];
    for (final term in _allTerms) {
      final level = await term.getLearningLevel();
      termsWithLevels.add((term, level));
    }

    // Sort by level (lowest first)
    termsWithLevels.sort((a, b) => a.$2.compareTo(b.$2));

    // Take first 5
    final selected = termsWithLevels
        .take(_termsPerCycle)
        .map((e) => e.$1)
        .toList();

    setState(() {
      _selectedTerms = selected;
      _currentTermIndex = 0;
    });
  }

  // Start session timer
  void _startSession() {
    _sessionTimer?.cancel();
    _remainingSeconds = _sessionDurationSeconds;
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;

      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        _endSession();
      }
    });
  }

  // Pause session
  void _pauseSession() {
    setState(() {
      _isPaused = true;
    });
  }

  // Resume session
  void _resumeSession() {
    setState(() {
      _isPaused = false;
    });
  }

  // End session
  void _endSession() {
    _sessionTimer?.cancel();
    setState(() {
      _isPaused = false;
      _remainingSeconds = 0;
    });
  }

  // Format time as "60s"
  String _formatTime(int seconds) {
    return '${seconds}s';
  }

  // Get action type for a given level and term
  LearningActionType _getActionForLevel(int level, Term term) {
    switch (level) {
      case 0:
        return LearningActionType.display;
      case 1:
        return LearningActionType.select;
      case 2:
        return LearningActionType.trueFalse;
      case 3:
        return LearningActionType.merge;
      case 4:
        return LearningActionType.speak;
      default: // Level 5+
        // Random from select, trueFalse, merge, speak (excluding display)
        final actions = [
          LearningActionType.select,
          LearningActionType.trueFalse,
          LearningActionType.merge,
          LearningActionType.speak,
        ];
        final seed = _getTermSeed(term) + level;
        final random = Random(seed);
        return actions[random.nextInt(actions.length)];
    }
  }

  // Check for special actions (Memory or Pair) after cycle
  Future<(LearningActionType?, List<Term>?)?> _checkForSpecialAction() async {
    // Load levels for all terms
    final termsWithLevels = <(Term, int)>[];
    for (final term in _allTerms) {
      final level = await term.getLearningLevel();
      termsWithLevels.add((term, level));
    }

    // Check Memory first (priority): 3 terms with level >= 6
    final memoryCandidates = termsWithLevels
        .where((e) => e.$2 >= 6)
        .map((e) => e.$1)
        .toList();

    if (memoryCandidates.length >= 3) {
      // Take 3 random candidates using seed
      final random = Random(_randomSeed);
      final selected = <Term>[];
      final available = List<Term>.from(memoryCandidates);
      for (int i = 0; i < 3 && available.isNotEmpty; i++) {
        final index = random.nextInt(available.length);
        selected.add(available.removeAt(index));
      }
      return (LearningActionType.memory, selected);
    }

    // Check Pair: 3 terms with level >= 5
    final pairCandidates = termsWithLevels
        .where((e) => e.$2 >= 5)
        .map((e) => e.$1)
        .toList();

    if (pairCandidates.length >= 3) {
      // Take 3 random candidates using seed
      final random = Random(_randomSeed + 1);
      final selected = <Term>[];
      final available = List<Term>.from(pairCandidates);
      for (int i = 0; i < 3 && available.isNotEmpty; i++) {
        final index = random.nextInt(available.length);
        selected.add(available.removeAt(index));
      }
      return (LearningActionType.pair, selected);
    }

    return null;
  }

  // Move to next action
  Future<void> _nextAction() async {
    if (_remainingSeconds <= 0) return;

    // If showing remember, hide it and move to next term
    if (_showRemember) {
      setState(() {
        _showRemember = false;
        _rememberTerm = null;
        _currentTermIndex++;
        _randomSeed++;
      });

      // Check if cycle completed (5 terms processed)
      if (_currentTermIndex >= _selectedTerms.length) {
        await _handleCycleComplete();
      }
      return;
    }

    // If in special action, exit it and continue with same 5 terms
    if (_isInSpecialAction) {
      setState(() {
        _isInSpecialAction = false;
        _specialActionType = null;
        _specialActionTerms = null;
        _currentTermIndex = 0;
        _randomSeed++;
      });
      // Continue with same 5 terms (no new selection)
      return;
    }

    // Normal action: skip current term and move to next
    setState(() {
      _currentTermIndex++;
      _randomSeed++;
      _currentActionType = null; // Reset action type
    });

    // Check if cycle completed (5 terms processed)
    if (_currentTermIndex >= _selectedTerms.length) {
      await _handleCycleComplete();
    }
  }

  // Handle cycle completion
  Future<void> _handleCycleComplete() async {
    // Check for special actions
    final specialAction = await _checkForSpecialAction();

    if (specialAction != null) {
      setState(() {
        _isInSpecialAction = true;
        _specialActionType = specialAction.$1;
        _specialActionTerms = specialAction.$2;
        _currentTermIndex = 0;
      });
    } else {
      // No special action, reset cycle with same 5 terms
      setState(() {
        _currentTermIndex = 0;
        _randomSeed++;
      });
    }
  }

  // Get current term
  Term? _getCurrentTerm() {
    if (_selectedTerms.isEmpty || _currentTermIndex >= _selectedTerms.length) {
      return null;
    }
    return _selectedTerms[_currentTermIndex];
  }

  // Get deterministic seed for a term
  int _getTermSeed(Term term) {
    // Combine term index, random seed, and term id hash for unique seed
    final termIndex = _selectedTerms.indexOf(term);
    final termIdHash = term.id.hashCode;
    return _randomSeed * 1000 + termIndex * 100 + (termIdHash % 100);
  }

  // Get distractor term
  Term _getDistractorTerm(Term correctTerm) {
    final availableTerms = _allTerms
        .where((t) => t.id != correctTerm.id)
        .toList();
    if (availableTerms.isEmpty) return correctTerm;

    final seed =
        _getTermSeed(correctTerm) +
        1; // +1 to differentiate from action type seed
    final random = Random(seed);
    return availableTerms[random.nextInt(availableTerms.length)];
  }

  // Handle action completion (called by actions)
  void _onActionCompleted(Term term) {
    // Check if this is a single-term action that needs remember
    final singleTermActions = [
      LearningActionType.display,
      LearningActionType.select,
      LearningActionType.trueFalse,
      LearningActionType.merge,
      LearningActionType.speak,
    ];

    if (_currentActionType != null &&
        singleTermActions.contains(_currentActionType)) {
      // Show remember step
      setState(() {
        _showRemember = true;
        _rememberTerm = term;
        _currentActionType = null; // Reset
      });
    } else {
      // Multi-term action, proceed directly
      setState(() {
        _currentActionType = null; // Reset
      });
      _nextAction();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.appLanguageNotifier,
      builder: (context, languageCode, child) {
        final scheme = Theme.of(context).colorScheme;

        // Build AppBar
        final appBar = AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: () {
              if (_isPaused) {
                _resumeSession();
              } else {
                _pauseSession();
              }
            },
          ),
          title: Text(
            _formatTime(_remainingSeconds),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: _remainingSeconds > 0 && !_isPaused
                  ? _nextAction
                  : null,
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

        // Show pause view if paused
        if (_isPaused) {
          return Scaffold(
            appBar: appBar,
            body: PauseView(
              onResume: _resumeSession,
              onEnd: () {
                _endSession();
                Navigator.of(context).pop();
              },
            ),
          );
        }

        // Show completed view if time is up
        if (_remainingSeconds <= 0) {
          return Scaffold(
            appBar: appBar,
            body: CompletedAction(onHome: () => Navigator.of(context).pop()),
          );
        }

        // Loading state
        if (_selectedTerms.isEmpty) {
          return Scaffold(
            appBar: appBar,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Show remember step if needed
        if (_showRemember && _rememberTerm != null) {
          return Scaffold(
            appBar: appBar,
            body: DisplayAction(
              term: _rememberTerm!,
              onNext: _nextAction,
              mode: DisplayMode.remember,
            ),
          );
        }

        // Show special action if in one
        if (_isInSpecialAction &&
            _specialActionType != null &&
            _specialActionTerms != null) {
          switch (_specialActionType!) {
            case LearningActionType.memory:
              final allMemoryTypes = MemoryActionType.values;
              // Use seed based on first term and special action state
              final seed = _randomSeed * 1000 + 500; // +500 for memory action
              final random = Random(seed);
              final randomIndex = random.nextInt(allMemoryTypes.length);
              return Scaffold(
                appBar: appBar,
                body: MemoryAction(
                  terms: _specialActionTerms!,
                  onNext: _nextAction,
                  type: allMemoryTypes[randomIndex],
                ),
              );
            case LearningActionType.pair:
              final allPairTypes = PairActionType.values;
              // Use seed based on first term and special action state
              final seed = _randomSeed * 1000 + 600; // +600 for pair action
              final random = Random(seed);
              final randomIndex = random.nextInt(allPairTypes.length);
              return Scaffold(
                appBar: appBar,
                body: PairAction(
                  terms: _specialActionTerms!,
                  onNext: _nextAction,
                  type: allPairTypes[randomIndex],
                ),
              );
            default:
              break;
          }
        }

        // Get current term
        final currentTerm = _getCurrentTerm();
        if (currentTerm == null) {
          return Scaffold(appBar: appBar, body: const SizedBox.shrink());
        }

        // Get action type based on level
        final levelFuture = currentTerm.getLearningLevel();

        return FutureBuilder<int>(
          future: levelFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Scaffold(
                appBar: appBar,
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            final level = snapshot.data!;
            final actionType = _getActionForLevel(level, currentTerm);
            final hasQuestions =
                currentTerm.questions != null &&
                currentTerm.questions!.isNotEmpty;

            // Store current action type for remember check
            _currentActionType = actionType;

            // Get deterministic seed for this term
            final termSeed = _getTermSeed(currentTerm);

            Widget body;
            switch (actionType) {
              case LearningActionType.display:
                body = DisplayAction(
                  term: currentTerm,
                  onNext: () {
                    // Display action handles level increment internally
                    _onActionCompleted(currentTerm);
                  },
                  mode: DisplayMode.meet,
                );
                break;
              case LearningActionType.select:
                final allSelectTypes = SelectActionType.values;
                final selectTypes = hasQuestions
                    ? allSelectTypes
                    : allSelectTypes
                          .where((t) => t != SelectActionType.questionToTarget)
                          .toList();
                final actionTypeSeed =
                    termSeed + 10; // +10 to differentiate from distractor seed
                final random = Random(actionTypeSeed);
                final randomIndex = random.nextInt(selectTypes.length);
                body = SelectAction(
                  term: currentTerm,
                  distractorTerm: _getDistractorTerm(currentTerm),
                  onNext: () {
                    _onActionCompleted(currentTerm);
                  },
                  type: selectTypes[randomIndex],
                );
                break;
              case LearningActionType.trueFalse:
                final allTrueFalseTypes = TrueFalseActionType.values;
                final actionTypeSeed = termSeed + 20; // +20 to differentiate
                final random = Random(actionTypeSeed);
                final randomIndex = random.nextInt(allTrueFalseTypes.length);
                body = TrueFalseAction(
                  term: currentTerm,
                  distractorTerm: _getDistractorTerm(currentTerm),
                  onNext: () {
                    _onActionCompleted(currentTerm);
                  },
                  type: allTrueFalseTypes[randomIndex],
                );
                break;
              case LearningActionType.merge:
                final allMergeTypes = MergeActionType.values;
                final mergeTypes = hasQuestions
                    ? allMergeTypes
                    : allMergeTypes
                          .where((t) => t != MergeActionType.questionToTarget)
                          .toList();
                final actionTypeSeed = termSeed + 30; // +30 to differentiate
                final random = Random(actionTypeSeed);
                final randomIndex = random.nextInt(mergeTypes.length);
                body = MergeAction(
                  term: currentTerm,
                  onNext: () {
                    _onActionCompleted(currentTerm);
                  },
                  type: mergeTypes[randomIndex],
                );
                break;
              case LearningActionType.speak:
                final allSpeakTypes = SpeakActionType.values;
                final speakTypes = hasQuestions
                    ? allSpeakTypes
                    : allSpeakTypes
                          .where((t) => t != SpeakActionType.questionToTarget)
                          .toList();
                final actionTypeSeed = termSeed + 40; // +40 to differentiate
                final random = Random(actionTypeSeed);
                final randomIndex = random.nextInt(speakTypes.length);
                body = SpeakAction(
                  term: currentTerm,
                  onNext: () {
                    _onActionCompleted(currentTerm);
                  },
                  type: speakTypes[randomIndex],
                );
                break;
              default:
                body = const SizedBox.shrink();
            }

            return Scaffold(appBar: appBar, body: body);
          },
        );
      },
    );
  }
}
