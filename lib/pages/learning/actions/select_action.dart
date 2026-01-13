import 'package:flutter/material.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/models/selection_option.dart';
import 'package:lingos/services/app_localizations.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/tts_service.dart';
import 'package:lingos/services/sound_service.dart';
import 'package:lingos/widgets/visual_card.dart';
import 'package:lingos/widgets/target_card.dart';
import 'package:lingos/widgets/options_card.dart';
import 'package:lingos/widgets/audio_card.dart';
import 'package:lingos/widgets/question_card.dart';
import 'package:lingos/constants/durations.dart' as AppDurations;
import 'package:lingos/utils/action_helpers.dart';
import 'package:lingos/pages/learning/action_types.dart';

class SelectAction extends StatefulWidget {
  const SelectAction({
    super.key,
    required this.term,
    required this.distractorTerm,
    required this.onNext,
    required this.type,
  });

  final Term term;
  final Term distractorTerm;
  final VoidCallback onNext;
  final SelectActionType type;

  @override
  State<SelectAction> createState() => _SelectActionState();
}

class _SelectActionState extends State<SelectAction> {
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
  bool _isFirstAttempt = true; // Track if this is the first attempt

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
    if (widget.type == SelectActionType.questionToTarget) {
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
      _isFirstAttempt = true; // Reset first attempt flag
    });

    // Wait after screen opens
    await Future.delayed(AppDurations.Durations.ttsDelay);
    if (!mounted || currentFlow != _flowId) return;

    // Show top card with fade
    setState(() {
      _showTopCard = true;
    });

    // Wait after top card appears - adjust based on question length if it's a question type, or 1s for visual card, or target length for targetTo types
    Duration waitDuration = AppDurations.Durations.ttsDelay;
    if (widget.type == SelectActionType.questionToTarget) {
      waitDuration = ActionHelpers.calculateTextWaitDuration(cachedQuestion);
    } else if (widget.type == SelectActionType.visualToTarget ||
        widget.type == SelectActionType.audioToVisual) {
      // Wait 1 second for visual card to be perceived
      waitDuration = AppDurations.Durations.visualComprehensionDelay;
    } else if (widget.type == SelectActionType.targetToVisual) {
      final targetText = _targetLanguageCode != null
          ? widget.term.getText(_targetLanguageCode!)
          : widget.term.textEn;
      waitDuration = ActionHelpers.calculateTextWaitDuration(targetText);
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
    await Future.delayed(AppDurations.Durations.ttsDelay);
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

  void _checkAnswer(int selectedIndex) {
    if (_showFeedback) return; // Already checking, ignore

    final currentFlow = ++_flowId;
    final isCorrect = _options[selectedIndex].isCorrect;

    // Show feedback immediately
    setState(() {
      _selectedIndex = selectedIndex;
      _isResultCorrect = isCorrect;
      _showFeedback = true;
    });

    if (isCorrect) {
      // Play correct sound
      SoundService.playCorrect();
      // Correct: show green, then proceed to remember action
      Future.delayed(AppDurations.Durations.feedbackDisplay, () {
        if (!mounted || currentFlow != _flowId) return;
        setState(() {
          _hasAnswered = true;
        });
      });
    } else {
      // Incorrect: play sound, show red, then reset for retry
      SoundService.playIncorrect();
      Future.delayed(AppDurations.Durations.feedbackDisplay, () {
        if (!mounted || currentFlow != _flowId) return;
        setState(() {
          _showFeedback = false;
          _selectedIndex = null;
          _isFirstAttempt = false; // Mark that first attempt failed
        });
      });
    }
  }

  String _title(AppLocalizations loc) {
    return loc.actionSelectCorrectOption;
  }

  Widget _buildTopCard() {
    final targetLang = _targetLanguageCode ?? 'en';
    switch (widget.type) {
      case SelectActionType.audioToTarget:
      case SelectActionType.audioToVisual:
        return AudioCard(
          term: widget.term,
          targetLanguageCode: targetLang,
          onSelected: () {
            // Always play TTS when top card is tapped
            return true;
          },
        );
      case SelectActionType.visualToTarget:
        return VisualCard(term: widget.term);
      case SelectActionType.targetToVisual:
        return TargetCard(languageCode: targetLang, term: widget.term);
      case SelectActionType.questionToTarget:
        return QuestionCard(term: widget.term, questionText: _cachedQuestion);
    }
  }

  Widget _buildOptions(AppLocalizations loc, Color? feedbackColor) {
    final isVisual =
        widget.type == SelectActionType.targetToVisual ||
        widget.type == SelectActionType.audioToVisual;

    return OptionsCard(
      isVisual: isVisual,
      options: _options,
      selectedIndex: _selectedIndex,
      highlightedIndex: _selectedIndex,
      highlightColor: feedbackColor,
      showFeedback: _showFeedback,
      onSelect: _handleOptionSelect,
    );
  }

  void _handleOptionSelect(int index) {
    if (_showFeedback) return; // Don't allow selection during feedback
    setState(() {
      _selectedIndex = index;
    });
    _checkAnswer(index);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.current;
    final actionTitle = _title(loc);
    final Color? feedbackColor = _showFeedback && _selectedIndex != null
        ? (_isResultCorrect ? Colors.green : Colors.red)
        : null;

    if (_options.length < 2) {
      return const SizedBox.shrink();
    }

    if (_hasAnswered) {
      // Proceed to next step (remember will be shown by LearningPage).
      // Call onNext after the current frame to avoid setState during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Increase level only on first attempt success
          if (_isFirstAttempt) {
            widget.term.incrementLearningLevel();
          }
          widget.onNext();
        }
      });
      return const SizedBox.shrink();
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
                    duration: AppDurations.Durations.fadeAnimation,
                    child: _buildTopCard(),
                  ),
                ),
                Expanded(
                  child: AnimatedOpacity(
                    opacity: _showBottomCard ? 1.0 : 0.0,
                    duration: AppDurations.Durations.fadeAnimation,
                    child: _buildOptions(loc, feedbackColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
