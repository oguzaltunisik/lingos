import 'package:flutter/material.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/app_localizations.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/tts_service.dart';
import 'package:lingos/widgets/action_button.dart';
import 'package:lingos/widgets/visual_card.dart';
import 'package:lingos/widgets/target_card.dart';
import 'package:lingos/constants/durations.dart' as AppDurations;
import 'package:lingos/pages/learning/action_types.dart';

class DisplayAction extends StatefulWidget {
  const DisplayAction({
    super.key,
    required this.term,
    required this.onNext,
    required this.mode,
    this.titleOverride,
  });

  final Term term;
  final VoidCallback onNext;
  final DisplayMode mode;
  final String? titleOverride;

  @override
  State<DisplayAction> createState() => _DisplayActionState();
}

class _DisplayActionState extends State<DisplayAction> {
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
  void didUpdateWidget(covariant DisplayAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.term.id != widget.term.id || oldWidget.mode != widget.mode) {
      _loadLanguagesAndRunFlow();
    }
  }

  Future<void> _loadLanguagesAndRunFlow() async {
    _flowId++;
    final currentFlow = _flowId;

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
      _showNative = false;
      _showTarget = false;
      _canProceed = false;
    });

    if (widget.mode == DisplayMode.remember) {
      await _runRememberFlow(currentFlow);
    } else {
      await _runMeetFlow(currentFlow);
    }
  }

  Future<void> _runRememberFlow(int currentFlow) async {
    // Wait after screen opens
    await Future.delayed(AppDurations.Durations.initialDelay);
    if (!_shouldContinue(currentFlow)) return;

    // Show both cards at the same time with fade
    setState(() {
      _showNative = true;
      _showTarget = true;
    });

    // Wait after cards appear
    await Future.delayed(AppDurations.Durations.cardDelay);
    if (!_shouldContinue(currentFlow)) return;

    // Single TTS for target card
    await _speakTargetText();

    // Wait after speaking
    await Future.delayed(AppDurations.Durations.postTtsDelay);
    if (!_shouldContinue(currentFlow)) return;

    // Auto proceed for remember mode
    if (mounted && currentFlow == _flowId) {
      widget.onNext();
    }
  }

  Future<void> _runMeetFlow(int currentFlow) async {
    // Wait after screen opens
    await Future.delayed(AppDurations.Durations.ttsDelay);
    if (!_shouldContinue(currentFlow)) return;

    // Show top card with fade
    setState(() {
      _showNative = true;
    });

    // Wait after top card appears
    await Future.delayed(AppDurations.Durations.ttsDelay);
    if (!_shouldContinue(currentFlow)) return;

    // Speak top card text
    await _speakTargetText();

    // Wait after speaking
    await Future.delayed(AppDurations.Durations.ttsDelay);
    if (!_shouldContinue(currentFlow)) return;

    // Show bottom card with fade
    setState(() {
      _showTarget = true;
    });

    // Wait after bottom card appears
    await Future.delayed(AppDurations.Durations.ttsDelay);
    if (!_shouldContinue(currentFlow)) return;

    // Speak bottom card text
    await _speakTargetText();

    // Wait after speaking
    await Future.delayed(AppDurations.Durations.ttsDelay);
    if (!_shouldContinue(currentFlow)) return;

    // Enable button for meet mode
    setState(() {
      _canProceed = true;
    });
  }

  bool _shouldContinue(int currentFlow) {
    return mounted && currentFlow == _flowId;
  }

  Future<void> _speakTargetText() async {
    if (_targetLanguageCode != null) {
      await TtsService.speakTerm(
        text: widget.term.getText(_targetLanguageCode!),
        languageCode: _targetLanguageCode!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final term = widget.term;
    final onNext = widget.onNext;
    final actionTitle =
        widget.titleOverride ??
        (widget.mode == DisplayMode.meet
            ? AppLocalizations.current.actionMeet
            : AppLocalizations.current.actionRemember);
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
                    duration: AppDurations.Durations.fadeAnimation,
                    child: _showNative
                        ? VisualCard(
                            term: term,
                            showIcon: widget.mode != DisplayMode.remember,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                if (targetLanguageCode != null)
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: _showTarget ? 1.0 : 0.0,
                      duration: AppDurations.Durations.fadeAnimation,
                      child: TargetCard(
                        languageCode: targetLanguageCode,
                        term: term,
                        showIcon: widget.mode != DisplayMode.remember,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (widget.mode == DisplayMode.meet)
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
