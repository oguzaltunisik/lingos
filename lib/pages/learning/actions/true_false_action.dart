import 'package:flutter/material.dart';
import 'dart:math';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/app_localizations.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/sound_service.dart';
import 'package:lingos/services/tts_service.dart';
import 'package:lingos/widgets/visual_card.dart';
import 'package:lingos/widgets/target_card.dart';
import 'package:lingos/widgets/audio_card.dart';
import 'package:lingos/widgets/true_false_card.dart';
import 'package:lingos/constants/durations.dart' as AppDurations;
import 'package:lingos/pages/learning/action_types.dart';

class TrueFalseAction extends StatefulWidget {
  const TrueFalseAction({
    super.key,
    required this.term,
    required this.distractorTerm,
    required this.onNext,
    required this.type,
  });

  final Term term;
  final Term distractorTerm;
  final VoidCallback onNext;
  final TrueFalseActionType type;

  @override
  State<TrueFalseAction> createState() => _TrueFalseActionState();
}

class _TrueFalseActionState extends State<TrueFalseAction> {
  bool _hasAnswered = false;
  bool _showFeedback = false;
  bool _isResultCorrect = false;
  bool _showTopCard = false;
  bool _showBottomCard = false;
  bool? _selectedValue;
  bool _isCompatible = false; // Whether top and bottom cards match
  String? _targetLanguageCode;
  int _flowId = 0;

  @override
  void initState() {
    super.initState();
    _loadLanguageAndStartFlow();
  }

  @override
  void didUpdateWidget(covariant TrueFalseAction oldWidget) {
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
    if (!mounted || currentFlow != _flowId) return;

    setState(() {
      _targetLanguageCode = target;
    });

    await _startFlow();
  }

  Future<void> _startFlow() async {
    _flowId++;
    final currentFlow = _flowId;

    // Randomly decide if cards are compatible
    final random = Random();
    _isCompatible = random.nextBool();

    setState(() {
      _hasAnswered = false;
      _showFeedback = false;
      _isResultCorrect = false;
      _showTopCard = false;
      _showBottomCard = false;
      _selectedValue = null;
    });

    // Show top card
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted || currentFlow != _flowId) return;
    setState(() {
      _showTopCard = true;
    });

    // Play audio automatically if top card is audio
    final isTopCardAudio =
        widget.type == TrueFalseActionType.audioToTarget ||
        widget.type == TrueFalseActionType.audioToVisual;
    if (isTopCardAudio) {
      final text = widget.term.getText(_targetLanguageCode!);
      if (text.isNotEmpty) {
        await TtsService.speakTerm(
          text: text,
          languageCode: _targetLanguageCode!,
        );
      }
    }

    // Show bottom card after a delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || currentFlow != _flowId) return;
    setState(() {
      _showBottomCard = true;
    });

    // Play audio automatically if bottom card is audio
    final isBottomCardAudio = widget.type == TrueFalseActionType.visualToAudio;
    if (isBottomCardAudio) {
      final bottomTerm = _isCompatible ? widget.term : widget.distractorTerm;
      final text = bottomTerm.getText(_targetLanguageCode!);
      if (text.isNotEmpty) {
        await TtsService.speakTerm(
          text: text,
          languageCode: _targetLanguageCode!,
        );
      }
    }
  }

  void _handleTrueFalseSelect(bool value) {
    if (_hasAnswered || _showFeedback) return;

    // Determine if the answer is correct
    // If compatible: true is correct
    // If not compatible: false is correct
    final isCorrect = _isCompatible ? value == true : value == false;

    setState(() {
      _selectedValue = value;
      _isResultCorrect = isCorrect;
      _showFeedback = true;
    });

    // Play sound
    if (isCorrect) {
      SoundService.playCorrect();
      // Correct: show green, then proceed to next step
      Future.delayed(AppDurations.Durations.feedbackDisplay, () {
        if (!mounted) return;
        setState(() {
          _hasAnswered = true;
        });
        widget.onNext();
      });
    } else {
      // Incorrect: play sound, show red, then reset for retry
      SoundService.playIncorrect();
      Future.delayed(AppDurations.Durations.feedbackDisplay, () {
        if (!mounted) return;
        setState(() {
          _showFeedback = false;
          _selectedValue = null;
        });
      });
    }
  }

  Widget _buildTopCard() {
    if (!_showTopCard) {
      return const SizedBox.shrink();
    }

    switch (widget.type) {
      case TrueFalseActionType.audioToTarget:
      case TrueFalseActionType.audioToVisual:
        return AudioCard(
          term: widget.term,
          showBorder: true,
          onSelected: () => true, // Play TTS when tapped
        );
      case TrueFalseActionType.visualToTarget:
      case TrueFalseActionType.visualToAudio:
        return VisualCard(term: widget.term, showBorder: true);
    }
  }

  Widget _buildBottomCard() {
    if (!_showBottomCard) {
      return const SizedBox.shrink();
    }

    final bottomTerm = _isCompatible ? widget.term : widget.distractorTerm;

    switch (widget.type) {
      case TrueFalseActionType.audioToTarget:
      case TrueFalseActionType.visualToTarget:
        return TargetCard(
          languageCode: _targetLanguageCode!,
          term: bottomTerm,
          showBorder: true,
          showIcon: false,
        );
      case TrueFalseActionType.audioToVisual:
        return VisualCard(term: bottomTerm, showBorder: true);
      case TrueFalseActionType.visualToAudio:
        return AudioCard(
          term: bottomTerm,
          showBorder: true,
          onSelected: () => true, // Play TTS when tapped
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_targetLanguageCode == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        spacing: 16,
        children: [
          Text(
            AppLocalizations.current.actionTrueFalse,
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
                  flex: 2,
                  child: AnimatedOpacity(
                    opacity: _showTopCard ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: _buildTopCard(),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: AnimatedOpacity(
                    opacity: _showBottomCard ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: _buildBottomCard(),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: TrueFalseCard(
                    onSelect: _handleTrueFalseSelect,
                    selectedValue: _selectedValue,
                    showFeedback: _showFeedback,
                    isCorrect: _isResultCorrect,
                    correctValue: _isCompatible ? true : false,
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
