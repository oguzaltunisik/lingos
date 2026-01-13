import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingos/models/topic.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/tts_service.dart';
import 'package:lingos/services/sound_service.dart';
import 'package:lingos/widgets/visual_card.dart';
import 'package:lingos/widgets/audio_card.dart';
import 'package:lingos/widgets/write_card.dart';
import 'package:lingos/widgets/target_card.dart';
import 'package:lingos/constants/durations.dart' as AppDurations;

enum WriteActionType { audioToTarget, visualToTarget }

class WriteAction extends StatefulWidget {
  const WriteAction({
    super.key,
    required this.topic,
    required this.term,
    required this.onNext,
    required this.type,
  });

  final Topic topic;
  final Term term;
  final VoidCallback onNext;
  final WriteActionType type;

  @override
  State<WriteAction> createState() => _WriteActionState();
}

class _WriteActionState extends State<WriteAction> {
  bool _showTopCard = false;
  bool _showBottomCard = false;
  String? _writtenText;
  bool _showFeedback = false;
  bool _isCorrect = false;
  int _flowId = 0;
  String? _targetLanguageCode;

  @override
  void initState() {
    super.initState();
    _loadLanguagesAndStartFlow();
  }

  @override
  void didUpdateWidget(covariant WriteAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.term.id != widget.term.id || oldWidget.type != widget.type) {
      _loadLanguagesAndStartFlow();
    }
  }

  Future<void> _loadLanguagesAndStartFlow() async {
    _flowId++;
    final currentFlow = _flowId;

    final target = await LanguageService.getTargetLanguage();

    if (!mounted || currentFlow != _flowId) return;

    setState(() {
      _targetLanguageCode = target;
      _writtenText = null;
      _showFeedback = false;
      _isCorrect = false;
    });

    await _startFlow();
  }

  Future<void> _startFlow() async {
    _flowId++;
    final currentFlow = _flowId;

    setState(() {
      _showTopCard = false;
      _showBottomCard = false;
    });

    // Wait after screen opens
    await Future.delayed(AppDurations.Durations.initialDelay);
    if (!_shouldContinue(currentFlow)) return;

    // Show top card
    setState(() {
      _showTopCard = true;
    });

    // Play TTS if audio card
    if (widget.type == WriteActionType.audioToTarget) {
      await Future.delayed(AppDurations.Durations.cardDelay);
      if (!_shouldContinue(currentFlow)) return;

      final targetLang = _targetLanguageCode;
      if (targetLang != null) {
        final text = widget.term.getText(targetLang);
        if (text.isNotEmpty) {
          await TtsService.speakTerm(text: text, languageCode: targetLang);
        }
      }
    }

    // Show bottom card after a delay
    await Future.delayed(AppDurations.Durations.cardDelay);
    if (!_shouldContinue(currentFlow)) return;

    setState(() {
      _showBottomCard = true;
    });
  }

  bool _shouldContinue(int flowId) {
    return mounted && _flowId == flowId;
  }

  Future<void> _openWriteBottomSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WriteBottomSheet(
        initialText: _writtenText ?? '',
        targetLanguageCode: _targetLanguageCode ?? 'en',
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _writtenText = result;
      });

      // Wait a bit then check
      await Future.delayed(AppDurations.Durations.cardDelay);
      if (!mounted) return;

      _checkAnswer();
    }
  }

  void _checkAnswer() {
    final targetLang = _targetLanguageCode;
    if (targetLang == null || _writtenText == null) return;

    final correctText = widget.term.getText(targetLang).toLowerCase().trim();
    final writtenText = _writtenText!.toLowerCase().trim();

    final isCorrect = correctText == writtenText;

    setState(() {
      _isCorrect = isCorrect;
      _showFeedback = true;
    });

    if (isCorrect) {
      SoundService.playCorrect();
      // Wait then proceed
      Future.delayed(AppDurations.Durations.feedbackDisplay, () {
        if (mounted) {
          widget.onNext();
        }
      });
    } else {
      SoundService.playIncorrect();
      // Wait then allow retry
      Future.delayed(AppDurations.Durations.feedbackDisplay, () {
        if (mounted) {
          setState(() {
            _showFeedback = false;
            _writtenText = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedOpacity(
              opacity: _showTopCard ? 1.0 : 0.0,
              duration: AppDurations.Durations.fadeAnimation,
              child: widget.type == WriteActionType.audioToTarget
                  ? AudioCard(
                      topic: widget.topic,
                      term: widget.term,
                      showBorder: true,
                    )
                  : VisualCard(
                      term: widget.term,
                      topic: widget.topic,
                      showBorder: true,
                    ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedOpacity(
              opacity: _showBottomCard ? 1.0 : 0.0,
              duration: AppDurations.Durations.fadeAnimation,
              child: _showFeedback && _isCorrect
                  ? TargetCard(
                      topic: widget.topic,
                      targetText: widget.term.getText(
                        _targetLanguageCode ?? 'en',
                      ),
                      languageCode: _targetLanguageCode ?? 'en',
                      overrideColor: Colors.green,
                      showBorder: true,
                    )
                  : _showFeedback && !_isCorrect
                  ? WriteCard(
                      topic: widget.topic,
                      text: _writtenText,
                      onTap: _openWriteBottomSheet,
                      showBorder: true,
                    )
                  : WriteCard(
                      topic: widget.topic,
                      text: _writtenText,
                      onTap: _openWriteBottomSheet,
                      showBorder: true,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WriteBottomSheet extends StatefulWidget {
  const _WriteBottomSheet({
    required this.initialText,
    required this.targetLanguageCode,
  });

  final String initialText;
  final String targetLanguageCode;

  @override
  State<_WriteBottomSheet> createState() => _WriteBottomSheetState();
}

class _WriteBottomSheetState extends State<_WriteBottomSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
    // Focus after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_controller.text.trim().isNotEmpty) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: keyboardHeight + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Text field
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSubmit(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Type here...',
              hintStyle: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: scheme.primary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: scheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
