import 'package:flutter/material.dart';
import 'package:lingos/models/topic.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/app_localizations.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/tts_service.dart';
import 'package:lingos/widgets/action_button.dart';
import 'package:lingos/widgets/native_term_card.dart';
import 'package:lingos/widgets/target_term_card.dart';

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
  static const Duration _revealDelay = Duration(milliseconds: 200);
  bool _showNative = false;
  int _flowId = 0;
  bool _canProceed = false;
  String? _nativeLanguageCode;
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

    final native = await LanguageService.getNativeLanguage();
    final target = await LanguageService.getTargetLanguage();

    if (!mounted || currentFlow != _flowId) return;

    setState(() {
      _nativeLanguageCode = native;
      _targetLanguageCode = target;
    });

    await _runFlow();
  }

  Future<void> _runFlow() async {
    _flowId++;
    final currentFlow = _flowId;
    setState(() {
      _showNative = widget.animateFlow ? false : true;
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

    await Future.delayed(_ttsDelay);
    if (!mounted || currentFlow != _flowId) return;

    if (widget.playTts && _targetLanguageCode != null) {
      await TtsService.speakTerm(
        text: widget.term.getText(_targetLanguageCode!),
        languageCode: _targetLanguageCode!,
      );
    }

    await Future.delayed(_revealDelay);
    if (!mounted || currentFlow != _flowId) return;
    setState(() {
      _showNative = true;
    });

    await Future.delayed(_ttsDelay);
    if (!mounted || currentFlow != _flowId) return;
    if (widget.playTts && _targetLanguageCode != null) {
      await TtsService.speakTerm(
        text: widget.term.getText(_targetLanguageCode!),
        languageCode: _targetLanguageCode!,
      );
    }
    if (!mounted || currentFlow != _flowId) return;
    setState(() {
      _canProceed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topic = widget.topic;
    final term = widget.term;
    final onNext = widget.onNext;
    final nextLabel = AppLocalizations.current.nextButton;
    final nativeLanguageCode = _nativeLanguageCode;
    final targetLanguageCode = _targetLanguageCode;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: _showNative
                        ? NativeTermCard(
                            term: term,
                            topic: topic,
                            nativeLanguageText:
                                widget.showTranslation &&
                                    nativeLanguageCode != null
                                ? term.getText(nativeLanguageCode)
                                : null,
                          )
                        : (widget.showTranslation
                              ? Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: topic.lightColor,
                                  ),
                                )
                              : const SizedBox.shrink()),
                  ),
                  if (widget.showTranslation)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: topic.darkColor.withValues(alpha: 0.25),
                    ),
                  if (targetLanguageCode != null)
                    Expanded(
                      child: TargetTermCard(
                        topic: topic,
                        targetText: term.getText(targetLanguageCode),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        ActionButton(
          topic: topic,
          label: nextLabel,
          onPressed: _canProceed ? onNext : null,
        ),
      ],
    );
  }
}
