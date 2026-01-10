import 'package:flutter/material.dart';
import 'package:lingos/models/topic.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/app_localizations.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/tts_service.dart';
import 'package:lingos/widgets/visual_card.dart';
import 'package:lingos/widgets/target_card.dart';

class RememberAction extends StatefulWidget {
  const RememberAction({
    super.key,
    required this.topic,
    required this.term,
    required this.onNext,
    this.titleOverride,
  });

  final Topic topic;
  final Term term;
  final VoidCallback onNext;
  final String? titleOverride;

  @override
  State<RememberAction> createState() => _RememberActionState();
}

class _RememberActionState extends State<RememberAction> {
  int _flowId = 0;
  String? _targetLanguageCode;
  bool _showNative = false;
  bool _showTarget = false;
  static const Duration _initialDelay = Duration(milliseconds: 350);
  static const Duration _cardDelay = Duration(seconds: 1);
  static const Duration _preTtsDelay = Duration(seconds: 1);
  static const Duration _postTtsDelay = Duration(milliseconds: 350);
  static const Duration _fadeOutDelay = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    _runFlow();
  }

  @override
  void didUpdateWidget(covariant RememberAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.term.id != widget.term.id) {
      _runFlow();
    }
  }

  Future<void> _runFlow() async {
    _flowId++;
    final currentFlow = _flowId;

    final target = await LanguageService.getTargetLanguage();
    if (!mounted || currentFlow != _flowId) return;
    setState(() {
      _targetLanguageCode = target;
      _showNative = false;
      _showTarget = false;
    });

    // Wait after screen opens
    await Future.delayed(_initialDelay);
    if (!mounted || currentFlow != _flowId) return;

    // Show top card (VisualCard) with fade
    setState(() {
      _showNative = true;
    });

    // Wait after top card appears
    await Future.delayed(_cardDelay);
    if (!mounted || currentFlow != _flowId) return;

    // Show bottom card (TargetCard) with fade
    setState(() {
      _showTarget = true;
    });

    // Wait after bottom card appears (visual comprehension time)
    await Future.delayed(_preTtsDelay);
    if (!mounted || currentFlow != _flowId) return;

    // Play TTS for target card only
    if (_targetLanguageCode != null) {
      await TtsService.speakTerm(
        text: widget.term.getText(_targetLanguageCode!),
        languageCode: _targetLanguageCode!,
      );
      if (!mounted || currentFlow != _flowId) return;
    }

    // Wait after TTS completes
    await Future.delayed(_postTtsDelay);
    if (!mounted || currentFlow != _flowId) return;

    // Hide cards with fade
    setState(() {
      _showNative = false;
      _showTarget = false;
    });

    // Wait for fade out
    await Future.delayed(_fadeOutDelay);
    if (!mounted || currentFlow != _flowId) return;

    // Automatically proceed
    if (mounted && currentFlow == _flowId) {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topic = widget.topic;
    final term = widget.term;
    final actionTitle =
        widget.titleOverride ?? AppLocalizations.current.actionRemember;
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
                    child: VisualCard(
                      term: term,
                      topic: topic,
                      showIcon: false,
                    ),
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
                        showIcon: false,
                      ),
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
