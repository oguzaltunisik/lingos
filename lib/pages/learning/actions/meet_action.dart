import 'package:flutter/material.dart';
import 'package:lingos/models/topic.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/app_localizations.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/tts_service.dart';
import 'package:lingos/widgets/action_button.dart';
import 'package:lingos/widgets/visual_card.dart';
import 'package:lingos/widgets/target_card.dart';

class MeetAction extends StatelessWidget {
  const MeetAction({
    super.key,
    required this.topic,
    required this.term,
    required this.onNext,
  });

  final Topic topic;
  final Term term;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _MeetActionCore(
      topic: topic,
      term: term,
      onNext: onNext,
      animateFlow: true,
      showTranslation: true,
      playTts: true,
    );
  }
}

class _MeetActionCore extends StatefulWidget {
  const _MeetActionCore({
    required this.topic,
    required this.term,
    required this.onNext,
    required this.animateFlow,
    required this.showTranslation,
    required this.playTts,
  });

  final Topic topic;
  final Term term;
  final VoidCallback onNext;
  final bool animateFlow;
  final bool showTranslation;
  final bool playTts;

  @override
  State<_MeetActionCore> createState() => _MeetActionCoreState();
}

class _MeetActionCoreState extends State<_MeetActionCore> {
  static const Duration _ttsDelay = Duration(milliseconds: 350);
  bool _showNative = false;
  bool _showTarget = false;
  int _flowId = 0;
  bool _canProceed = false;
  String? _targetLanguageCode;

  @override
  void initState() {
    super.initState();
    _loadLanguagesAndRunFlow();
  }

  @override
  void didUpdateWidget(covariant _MeetActionCore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.term.id != widget.term.id) {
      _loadLanguagesAndRunFlow();
    }
  }

  Future<void> _loadLanguagesAndRunFlow() async {
    _flowId++;
    final currentFlow = _flowId;

    await LanguageService.getNativeLanguage(); // retained for future use
    final target = await LanguageService.getTargetLanguage();

    if (!mounted || currentFlow != _flowId) return;

    setState(() {
      _targetLanguageCode = target;
    });

    await _runFlow();
  }

  Future<void> _runFlow() async {
    _flowId++;
    final currentFlow = _flowId;
    setState(() {
      _showNative = widget.animateFlow ? false : true;
      _showTarget = widget.animateFlow ? false : true;
      _canProceed = widget.animateFlow ? false : true;
    });

    if (!widget.animateFlow) {
      if (widget.playTts && _targetLanguageCode != null) {
        await TtsService.speakTerm(
          text: widget.term.getText(_targetLanguageCode!),
          languageCode: _targetLanguageCode!,
        );
      }
      return;
    }

    // Wait after screen opens
    await Future.delayed(_ttsDelay);
    if (!mounted || currentFlow != _flowId) return;

    // Show top card with fade
    setState(() {
      _showNative = true;
    });

    // Wait after top card appears
    await Future.delayed(_ttsDelay);
    if (!mounted || currentFlow != _flowId) return;

    // Speak top card text
    if (widget.playTts && _targetLanguageCode != null) {
      await TtsService.speakTerm(
        text: widget.term.getText(_targetLanguageCode!),
        languageCode: _targetLanguageCode!,
      );
    }

    // Wait after speaking
    await Future.delayed(_ttsDelay);
    if (!mounted || currentFlow != _flowId) return;

    // Show bottom card with fade
    setState(() {
      _showTarget = true;
    });

    // Wait after bottom card appears
    await Future.delayed(_ttsDelay);
    if (!mounted || currentFlow != _flowId) return;

    // Speak bottom card text
    if (widget.playTts && _targetLanguageCode != null) {
      await TtsService.speakTerm(
        text: widget.term.getText(_targetLanguageCode!),
        languageCode: _targetLanguageCode!,
      );
    }

    // Wait after speaking
    await Future.delayed(_ttsDelay);
    if (!mounted || currentFlow != _flowId) return;

    // Enable button
    setState(() {
      _canProceed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topic = widget.topic;
    final term = widget.term;
    final onNext = widget.onNext;
    final actionTitle = AppLocalizations.current.actionMeet;
    final targetLanguageCode = _targetLanguageCode;

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
                    opacity: _showNative ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: _showNative
                        ? VisualCard(term: term, topic: topic)
                        : (widget.showTranslation
                              ? Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.6),
                                  ),
                                )
                              : const SizedBox.shrink()),
                  ),
                ),
                if (targetLanguageCode != null)
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: _showTarget ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: TargetCard(
                        topic: topic,
                        targetText: term.getText(targetLanguageCode),
                        languageCode: targetLanguageCode,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            spacing: 12,
            children: [
              ActionButton(
                label: AppLocalizations.current.alreadyKnowButton,
                onPressed: _canProceed ? onNext : null,
                outlined: true,
              ),
              ActionButton(
                label: AppLocalizations.current.wantToLearnButton,
                onPressed: _canProceed ? onNext : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
