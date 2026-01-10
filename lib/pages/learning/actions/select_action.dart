import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lingos/models/topic.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/models/selection_option.dart';
import 'package:lingos/services/app_localizations.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/tts_service.dart';
import 'package:lingos/pages/learning/actions/remember_action.dart';
import 'package:lingos/widgets/action_button.dart';
import 'package:lingos/widgets/visual_card.dart';
import 'package:lingos/widgets/target_card.dart';
import 'package:lingos/widgets/options_card.dart';
import 'package:lingos/widgets/audio_card.dart';
import 'package:lingos/widgets/question_card.dart';

enum SelectActionType {
  audioToTarget,
  audioToVisual,
  visualToTarget,
  targetToVisual,
  targetToAudio,
  visualToAudio,
  questionToTarget,
  questionToAudio,
}

class SelectAction extends StatefulWidget {
  const SelectAction({
    super.key,
    required this.topic,
    required this.term,
    required this.distractorTerm,
    required this.onNext,
    required this.type,
  });

  final Topic topic;
  final Term term;
  final Term distractorTerm;
  final VoidCallback onNext;
  final SelectActionType type;

  @override
  State<SelectAction> createState() => _SelectActionState();
}

class _SelectActionState extends State<SelectAction> {
  static const Duration _ttsDelay = Duration(milliseconds: 350);
  bool _hasAnswered = false;
  bool _showFeedback = false;
  bool _isResultCorrect = false;
  bool _showTopCard = false;
  bool _showBottomCard = false;
  int? _selectedIndex;
  int _flowId = 0;
  String? _targetLanguageCode;
  String? _nativeLanguageCode;
  List<SelectionOption> _options = const [];
  String? _cachedQuestion;

  @override
  void initState() {
    super.initState();
    _loadLanguageAndStartFlow();
  }

  @override
  void didUpdateWidget(covariant SelectAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.term.id != widget.term.id ||
        oldWidget.distractorTerm.id != widget.distractorTerm.id ||
        oldWidget.type != widget.type) {
      _loadLanguageAndStartFlow();
    }
  }

  Future<void> _loadLanguageAndStartFlow() async {
    _flowId++;
    final currentFlow = _flowId;

    final target = await LanguageService.getTargetLanguage();
    final native = await LanguageService.getNativeLanguage();
    if (!mounted || currentFlow != _flowId) return;

    setState(() {
      _targetLanguageCode = target;
      _nativeLanguageCode = native;
    });

    await _startFlow();
  }

  Future<void> _startFlow() async {
    _flowId++;
    final currentFlow = _flowId;
    final opts = [
      SelectionOption(
        term: widget.term,
        text: _textForTerm(widget.term),
        emoji: widget.term.emoji,
        languageCode: _targetLanguageCode,
        isCorrect: true,
      ),
      SelectionOption(
        term: widget.distractorTerm,
        text: _textForTerm(widget.distractorTerm),
        emoji: widget.distractorTerm.emoji,
        languageCode: _targetLanguageCode,
        isCorrect: false,
      ),
    ]..shuffle();

    // Cache question once if needed
    String? cachedQuestion;
    if (widget.type == SelectActionType.questionToTarget ||
        widget.type == SelectActionType.questionToAudio) {
      final lang = _nativeLanguageCode ?? 'en';
      cachedQuestion = widget.term.getQuestion(lang);
    }

    setState(() {
      _hasAnswered = false;
      _showFeedback = false;
      _isResultCorrect = false;
      _selectedIndex = null;
      _options = opts;
      _cachedQuestion = cachedQuestion;
      _showTopCard = false;
      _showBottomCard = false;
    });

    // Wait after screen opens
    await Future.delayed(_ttsDelay);
    if (!mounted || currentFlow != _flowId) return;

    // Show top card with fade
    setState(() {
      _showTopCard = true;
    });

    // Wait after top card appears - adjust based on question length if it's a question type, or 1s for visual card, or target length for targetTo types
    Duration waitDuration = _ttsDelay;
    if (widget.type == SelectActionType.questionToTarget ||
        widget.type == SelectActionType.questionToAudio) {
      final questionLength = cachedQuestion?.length ?? 0;
      // Base delay + additional time based on question length (roughly 50ms per character, min 350ms)
      waitDuration = Duration(
        milliseconds: (350 + (questionLength * 50)).clamp(350, 2000),
      );
    } else if (widget.type == SelectActionType.visualToTarget ||
        widget.type == SelectActionType.visualToAudio ||
        widget.type == SelectActionType.audioToVisual) {
      // Wait 1 second for visual card to be perceived
      waitDuration = const Duration(seconds: 1);
    } else if (widget.type == SelectActionType.targetToVisual ||
        widget.type == SelectActionType.targetToAudio) {
      // Wait based on target text length for reading (roughly 50ms per character, min 350ms)
      final targetText = _targetLanguageCode != null
          ? widget.term.getText(_targetLanguageCode!)
          : widget.term.textEn;
      final targetLength = targetText.length;
      waitDuration = Duration(
        milliseconds: (350 + (targetLength * 50)).clamp(350, 2000),
      );
    }
    await Future.delayed(waitDuration);
    if (!mounted || currentFlow != _flowId) return;

    // Play TTS automatically for audioTo types
    if (widget.type == SelectActionType.audioToTarget ||
        widget.type == SelectActionType.audioToVisual) {
      if (_targetLanguageCode != null) {
        final text = widget.term.getText(_targetLanguageCode!);
        if (text.isNotEmpty) {
          await TtsService.speakTerm(
            text: text,
            languageCode: _targetLanguageCode!,
          );
        }
      }
    }

    // Wait after TTS
    await Future.delayed(_ttsDelay);
    if (!mounted || currentFlow != _flowId) return;

    // Show bottom card with fade
    setState(() {
      _showBottomCard = true;
    });
  }

  String _textForTerm(Term term) {
    if (_targetLanguageCode != null) {
      return term.getText(_targetLanguageCode!);
    }
    return term.textEn;
  }

  String _title(AppLocalizations loc) {
    switch (widget.type) {
      case SelectActionType.audioToTarget:
        return loc.actionAudioToTarget;
      case SelectActionType.audioToVisual:
        return loc.actionAudioToVisual;
      case SelectActionType.visualToTarget:
        return loc.actionVisualToTarget;
      case SelectActionType.targetToVisual:
        return loc.actionTargetToVisual;
      case SelectActionType.targetToAudio:
        return loc.actionTargetToAudio;
      case SelectActionType.visualToAudio:
        return loc.actionVisualToAudio;
      case SelectActionType.questionToTarget:
        return loc.actionQuestionToTarget;
      case SelectActionType.questionToAudio:
        return loc.actionQuestionToAudio;
    }
  }

  Widget _buildTopCard() {
    final topic = widget.topic;
    final targetLang = _targetLanguageCode ?? 'en';
    switch (widget.type) {
      case SelectActionType.audioToTarget:
      case SelectActionType.audioToVisual:
        return AudioCard(topic: topic, term: widget.term, isSelected: false);
      case SelectActionType.visualToTarget:
      case SelectActionType.visualToAudio:
        return VisualCard(term: widget.term, topic: topic);
      case SelectActionType.targetToVisual:
      case SelectActionType.targetToAudio:
      case SelectActionType.questionToTarget:
      case SelectActionType.questionToAudio:
        if (widget.type == SelectActionType.questionToTarget ||
            widget.type == SelectActionType.questionToAudio) {
          return QuestionCard(
            topic: topic,
            term: widget.term,
            questionText: _cachedQuestion,
          );
        }
        return TargetCard(
          topic: topic,
          targetText: widget.term.getText(targetLang),
          languageCode: targetLang,
        );
    }
  }

  Widget _buildOptions(AppLocalizations loc, Color? feedbackColor) {
    final topic = widget.topic;
    switch (widget.type) {
      case SelectActionType.audioToTarget:
      case SelectActionType.questionToTarget:
        return OptionsCard(
          topic: topic,
          isVisual: false,
          options: _options,
          selectedIndex: _selectedIndex,
          highlightedIndex: _selectedIndex,
          highlightColor: feedbackColor,
          showFeedback: _showFeedback,
          onSelect: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        );
      case SelectActionType.visualToTarget:
        return OptionsCard(
          topic: topic,
          isVisual: false,
          options: _options,
          selectedIndex: _selectedIndex,
          highlightedIndex: _selectedIndex,
          highlightColor: feedbackColor,
          showFeedback: _showFeedback,
          onSelect: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        );
      case SelectActionType.targetToVisual:
      case SelectActionType.audioToVisual:
        return OptionsCard(
          topic: topic,
          isVisual: true,
          options: _options,
          selectedIndex: _selectedIndex,
          highlightedIndex: _selectedIndex,
          highlightColor: feedbackColor,
          showFeedback: _showFeedback,
          onSelect: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        );
      case SelectActionType.visualToAudio:
      case SelectActionType.targetToAudio:
      case SelectActionType.questionToAudio:
        return Column(
          spacing: 12,
          children: [
            Expanded(
              child: AudioCard(
                topic: topic,
                term: _options[0].term ?? widget.term,
                isSelected: _selectedIndex == 0,
                overrideColor: _showFeedback && _selectedIndex == 0
                    ? feedbackColor
                    : null,
                onSelected: () {
                  final wasSelected = _selectedIndex == 0;
                  setState(() {
                    _selectedIndex = wasSelected ? -1 : 0;
                  });
                  return !wasSelected; // Return true if selected, false if deselected
                },
              ),
            ),
            Expanded(
              child: AudioCard(
                topic: topic,
                term: _options[1].term ?? widget.term,
                isSelected: _selectedIndex == 1,
                overrideColor: _showFeedback && _selectedIndex == 1
                    ? feedbackColor
                    : null,
                onSelected: () {
                  final wasSelected = _selectedIndex == 1;
                  setState(() {
                    _selectedIndex = wasSelected ? -1 : 1;
                  });
                  return !wasSelected; // Return true if selected, false if deselected
                },
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topic = widget.topic;
    final loc = AppLocalizations.current;
    final actionTitle = _hasAnswered ? loc.actionRemember : _title(loc);
    final Color? feedbackColor = _showFeedback && _selectedIndex != null
        ? (_isResultCorrect ? Colors.green : Colors.red)
        : null;

    if (_options.length < 2) {
      return const SizedBox.shrink();
    }

    if (_hasAnswered) {
      return RememberAction(
        topic: topic,
        term: widget.term,
        onNext: widget.onNext,
        titleOverride: actionTitle,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        spacing: 16,
        children: [
          Text(
            actionTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Expanded(
            child: Column(
              spacing: 16,
              children: [
                Expanded(
                  child: AnimatedOpacity(
                    opacity: _showTopCard ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: _buildTopCard(),
                  ),
                ),
                Expanded(
                  child: AnimatedOpacity(
                    opacity: _showBottomCard ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: _buildOptions(loc, feedbackColor),
                  ),
                ),
              ],
            ),
          ),
          ActionButton(
            label: loc.checkButton,
            onPressed: (_selectedIndex == null || _showFeedback)
                ? null
                : () {
                    final currentFlow = ++_flowId;
                    final isCorrect = _options[_selectedIndex!].isCorrect;
                    setState(() {
                      _isResultCorrect = isCorrect;
                      _showFeedback = true;
                    });
                    Future.delayed(const Duration(seconds: 1), () {
                      if (!mounted || currentFlow != _flowId) return;
                      setState(() {
                        _showFeedback = false;
                        _hasAnswered = true;
                      });
                    });
                  },
          ),
        ],
      ),
    );
  }
}
