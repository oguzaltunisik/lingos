import 'package:flutter/material.dart';
import 'package:lingos/models/topic.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/app_localizations.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/tts_service.dart';
import 'package:lingos/services/sound_service.dart';
import 'package:lingos/services/stt_service.dart';
import 'package:lingos/pages/learning/actions/display_action.dart';
import 'package:lingos/widgets/visual_card.dart';
import 'package:lingos/widgets/audio_card.dart';
import 'package:lingos/widgets/target_card.dart';
import 'package:lingos/widgets/question_card.dart';
import 'package:lingos/widgets/speak_card.dart';
import 'package:lingos/constants/durations.dart' as AppDurations;
import 'package:lingos/utils/action_helpers.dart';

enum SpeakActionType { audioToTarget, visualToTarget, questionToTarget }

class SpeakAction extends StatefulWidget {
  const SpeakAction({
    super.key,
    required this.topic,
    required this.term,
    required this.onNext,
    required this.type,
  });

  final Topic topic;
  final Term term;
  final VoidCallback onNext;
  final SpeakActionType type;

  @override
  State<SpeakAction> createState() => _SpeakActionState();
}

class _SpeakActionState extends State<SpeakAction> {
  bool _hasAnswered = false;
  bool _showFeedback = false;
  bool _isResultCorrect = false;
  bool _showTopCard = false;
  bool _showBottomCard = false;
  int _flowId = 0;
  String? _targetLanguageCode;
  String? _nativeLanguageCode;
  String _spokenText = '';
  String? _cachedQuestion;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeAndCheckPermission();
    _loadAndStart();
  }

  Future<void> _initializeAndCheckPermission() async {
    await SttService.initialize();
    final hasPermission = await SttService.hasPermission();
    if (!hasPermission && mounted) {
      await SttService.requestPermission();
      final hasPermAfterRequest = await SttService.hasPermission();
      if (!hasPermAfterRequest && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Microphone permission is required. Please grant permission in app settings.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    SttService.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SpeakAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.term.id != widget.term.id || oldWidget.type != widget.type) {
      _loadAndStart();
    }
  }

  Future<void> _loadAndStart() async {
    _flowId++;
    final currentFlow = _flowId;
    final target = await LanguageService.getTargetLanguage();
    final native = await LanguageService.getNativeLanguage();
    if (!mounted || currentFlow != _flowId) return;

    // Cache question once if needed
    String? cachedQuestion;
    if (widget.type == SpeakActionType.questionToTarget) {
      cachedQuestion = widget.term.getQuestion(native ?? 'en');
    }

    setState(() {
      _targetLanguageCode = target;
      _nativeLanguageCode = native;
      _spokenText = '';
      _hasAnswered = false;
      _showFeedback = false;
      _isResultCorrect = false;
      _cachedQuestion = cachedQuestion;
      _showTopCard = false;
      _showBottomCard = false;
      _isRecording = false;
    });

    if (_targetLanguageCode == null && _nativeLanguageCode == null) return;

    // Wait after screen opens
    await Future.delayed(AppDurations.Durations.ttsDelay);
    if (!mounted || currentFlow != _flowId) return;

    // Show top card with fade
    setState(() {
      _showTopCard = true;
    });

    // Wait after top card appears - adjust based on question length if it's a question type, or 1s for visual card
    Duration waitDuration = AppDurations.Durations.ttsDelay;
    if (widget.type == SpeakActionType.questionToTarget) {
      waitDuration = ActionHelpers.calculateTextWaitDuration(cachedQuestion);
    } else if (widget.type == SpeakActionType.visualToTarget) {
      waitDuration = AppDurations.Durations.visualComprehensionDelay;
    }
    await Future.delayed(waitDuration);
    if (!mounted || currentFlow != _flowId) return;

    // Play TTS if needed (for audioToTarget)
    if (widget.type == SpeakActionType.audioToTarget) {
      final text = widget.term.getText(_targetLanguageCode ?? 'en');
      if (text.isNotEmpty) {
        await TtsService.speakTerm(
          text: text,
          languageCode: _targetLanguageCode ?? 'en',
        );
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

  String get _targetText {
    if (_targetLanguageCode == null) return widget.term.textEn;
    return widget.term.getText(_targetLanguageCode!);
  }

  String _getLocaleId(String languageCode) {
    switch (languageCode) {
      case 'tr':
        return 'tr_TR';
      case 'fi':
        return 'fi_FI';
      case 'en':
      default:
        return 'en_US';
    }
  }

  Future<void> _startRecording() async {
    if (_isRecording || _targetLanguageCode == null) return;

    // Stop any existing listening first
    if (SttService.isListening) {
      await SttService.cancel();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Check permission one more time before starting
    final hasPermission = await SttService.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Microphone permission is required. Please grant permission in app settings.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isRecording = true;
      });

      final localeId = _getLocaleId(_targetLanguageCode!);
      await SttService.startListening(
        onResult: (text) {
          if (!mounted) return;
          setState(() {
            _spokenText = text.trim();
          });
        },
        onFinalResult: (text) {
          if (!mounted) return;
          setState(() {
            _spokenText = text.trim();
          });
          // Automatically check when final result is received
        },
        localeId: localeId,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRecording = false;
      });
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    await SttService.stopListening();

    // Wait a bit for final result to be processed
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _isRecording = false;
    });

    // Check the spoken text
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _checkSpokenText();
  }

  void _checkSpokenText() {
    if (_spokenText.isEmpty) return;

    // Check if the spoken text matches the target text (case-insensitive, ignore punctuation)
    final targetNormalized = _targetText
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();
    final spokenNormalized = _spokenText
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();

    final isCorrect = targetNormalized == spokenNormalized;

    if (isCorrect) {
      // Correct: play sound, show green and proceed to remember
      SoundService.playCorrect();
      setState(() {
        _isResultCorrect = true;
        _showFeedback = true;
      });
      Future.delayed(AppDurations.Durations.feedbackDisplay, () {
        if (!mounted) return;
        setState(() {
          _hasAnswered = true;
        });
      });
    } else {
      // Wrong: play sound, show red, then reset
      SoundService.playIncorrect();
      setState(() {
        _isResultCorrect = false;
        _showFeedback = true;
      });
      Future.delayed(AppDurations.Durations.wrongChunkFeedback, () {
        if (!mounted) return;
        // Cancel any ongoing listening
        if (SttService.isListening) {
          SttService.cancel();
        }
        setState(() {
          _showFeedback = false;
          _spokenText = '';
          _isRecording = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topic = widget.topic;
    final loc = AppLocalizations.current;
    final title = _hasAnswered
        ? loc.actionRemember
        : (widget.type == SpeakActionType.audioToTarget
              ? 'Dinle ve Söyle'
              : widget.type == SpeakActionType.questionToTarget
              ? 'Soruya Cevap Ver'
              : 'Görseli Söyle');

    if (_targetText.isEmpty) return const SizedBox.shrink();

    if (_hasAnswered) {
      return DisplayAction(
        topic: topic,
        term: widget.term,
        onNext: widget.onNext,
        mode: DisplayMode.remember,
        titleOverride: title,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
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
                    child: widget.type == SpeakActionType.audioToTarget
                        ? AudioCard(
                            topic: topic,
                            term: widget.term,
                            onSelected: () {
                              // Always play TTS when audio card is tapped
                              return true;
                            },
                          )
                        : widget.type == SpeakActionType.questionToTarget
                        ? QuestionCard(
                            topic: topic,
                            term: widget.term,
                            questionText: _cachedQuestion,
                          )
                        : VisualCard(term: widget.term, topic: topic),
                  ),
                ),
                Expanded(
                  child: AnimatedOpacity(
                    opacity: _showBottomCard ? 1.0 : 0.0,
                    duration: AppDurations.Durations.fadeAnimation,
                    child: Column(
                      spacing: 12,
                      children: [
                        Expanded(
                          child: TargetCard(
                            topic: topic,
                            targetText: _spokenText,
                            languageCode: _targetLanguageCode ?? 'en',
                            overrideColor: _showFeedback
                                ? (_isResultCorrect ? Colors.green : Colors.red)
                                : null,
                            onTap: () {
                              setState(() {
                                _spokenText = '';
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: SpeakCard(
                            topic: topic,
                            term: widget.term,
                            targetLanguageCode: _targetLanguageCode ?? 'en',
                            isRecording: _isRecording,
                            onRecordStart: _startRecording,
                            onRecordStop: _stopRecording,
                          ),
                        ),
                      ],
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
