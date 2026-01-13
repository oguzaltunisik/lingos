import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/app_localizations.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/tts_service.dart';
import 'package:lingos/services/sound_service.dart';
import 'package:lingos/widgets/visual_card.dart';
import 'package:lingos/widgets/audio_card.dart';
import 'package:lingos/widgets/merge_card.dart';
import 'package:lingos/widgets/target_card.dart';
import 'package:lingos/widgets/question_card.dart';
import 'package:lingos/constants/durations.dart' as AppDurations;
import 'package:lingos/utils/action_helpers.dart';
import 'package:lingos/pages/learning/action_types.dart';
import 'package:lingos/constants/card_colors.dart';

class MergeAction extends StatefulWidget {
  const MergeAction({
    super.key,
    required this.term,
    required this.onNext,
    required this.type,
  });

  final Term term;
  final VoidCallback onNext;
  final MergeActionType type;

  @override
  State<MergeAction> createState() => _MergeActionState();
}

class _MergeActionState extends State<MergeAction> {
  bool _hasAnswered = false;
  bool _showFeedback = false;
  bool _isResultCorrect = false;
  bool _showTopCard = false;
  bool _showBottomCard = false;
  final Random _rng = Random();
  int _flowId = 0;
  String? _targetLanguageCode;
  String? _nativeLanguageCode;
  List<String> _chunks = const [];
  List<int> _shuffledIndices = const [];
  final List<int> _selectedOrder = [];
  String? _cachedQuestion;
  bool _isFirstAttempt = true; // Track if this is the first attempt

  @override
  void initState() {
    super.initState();
    _loadAndStart();
  }

  @override
  void didUpdateWidget(covariant MergeAction oldWidget) {
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
    if (widget.type == MergeActionType.questionToTarget) {
      cachedQuestion = widget.term.getQuestion(native ?? 'en');
    }

    setState(() {
      _targetLanguageCode = target;
      _nativeLanguageCode = native;
      _chunks = _buildChunksWithDistractors();
      _shuffledIndices = _buildShuffledIndices(_chunks.length);
      _selectedOrder.clear();
      _hasAnswered = false;
      _showFeedback = false;
      _isResultCorrect = false;
      _isFirstAttempt = true; // Reset first attempt flag
      _cachedQuestion = cachedQuestion;
      _showTopCard = false;
      _showBottomCard = false;
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
    if (widget.type == MergeActionType.questionToTarget) {
      waitDuration = ActionHelpers.calculateTextWaitDuration(cachedQuestion);
    } else if (widget.type == MergeActionType.visualToTarget) {
      // Wait 1 second for visual card to be perceived
      waitDuration = AppDurations.Durations.visualComprehensionDelay;
    }
    await Future.delayed(waitDuration);
    if (!mounted || currentFlow != _flowId) return;

    // Play TTS if needed (for audioToTarget)
    if (widget.type == MergeActionType.audioToTarget) {
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

  List<String> _buildChunksWithDistractors() {
    final baseChunks = MergeCard.buildChunks(
      widget.term.getText(_targetLanguageCode ?? 'en'),
    );
    if (baseChunks.isEmpty) return baseChunks;

    final wrongChunks = <String>[];
    final int needed = baseChunks.length >= 3
        ? 2
        : baseChunks.length == 2
        ? 1
        : 0;

    String generateWrong(int length) {
      const letters = 'abcdefghijklmnopqrstuvwxyz';
      return List.generate(
        length,
        (_) => letters[_rng.nextInt(letters.length)],
      ).join();
    }

    while (wrongChunks.length < needed) {
      final ref = baseChunks[wrongChunks.length % baseChunks.length];
      final candidate = generateWrong(ref.length.clamp(1, 6));
      if (!baseChunks.contains(candidate) && !wrongChunks.contains(candidate)) {
        wrongChunks.add(candidate);
      }
    }

    return [...baseChunks, ...wrongChunks];
  }

  List<int> _buildShuffledIndices(int count) {
    final indices = List<int>.generate(count, (i) => i);
    if (indices.length <= 1) return indices;
    // Ensure not returning the original order to keep it visibly shuffled.
    for (int attempt = 0; attempt < 5; attempt++) {
      indices.shuffle(_rng);
      final isSameOrder = List.generate(
        indices.length,
        (i) => i,
      ).every((i) => indices[i] == i);
      if (!isSameOrder) break;
    }
    return indices;
  }

  String get _targetText {
    if (_targetLanguageCode == null) return widget.term.textEn;
    return widget.term.getText(_targetLanguageCode!);
  }

  String get _builtText {
    return _selectedOrder.map((i) => _chunks[i]).join();
  }

  List<int> get _correctChunkIndices {
    // The first baseChunks.length indices in _chunks are the correct chunks in order
    final baseChunks = MergeCard.buildChunks(_targetText);
    return List<int>.generate(baseChunks.length, (i) => i);
  }

  void _toggleLetter(int idx) {
    if (_showFeedback) return; // Don't allow during feedback

    final currentFlow = ++_flowId;
    final wasSelected = _selectedOrder.contains(idx);

    if (wasSelected) {
      // Deselect - just remove it
      setState(() {
        _selectedOrder.remove(idx);
      });
      return;
    }

    // Select - first add the chunk, then check if it's correct
    setState(() {
      _selectedOrder.add(idx);
    });

    // Check if it's correct
    final correctChunkIndices = _correctChunkIndices;
    final expectedIndex =
        (_selectedOrder.length - 1) < correctChunkIndices.length
        ? correctChunkIndices[_selectedOrder.length - 1]
        : null;
    final isCorrect = expectedIndex != null && idx == expectedIndex;

    if (isCorrect) {
      // Check if all chunks are complete
      if (_selectedOrder.length == correctChunkIndices.length) {
        // All correct - play sound, show green and proceed to remember
        SoundService.playCorrect();
        setState(() {
          _isResultCorrect = true;
          _showFeedback = true;
        });
        Future.delayed(AppDurations.Durations.feedbackDisplay, () {
          if (!mounted || currentFlow != _flowId) return;
          setState(() {
            _hasAnswered = true;
          });
        });
      }
    } else {
      // Wrong chunk - play sound, show red, then revert
      SoundService.playIncorrect();
      setState(() {
        _isResultCorrect = false;
        _showFeedback = true;
        _isFirstAttempt = false; // Mark that first attempt failed
      });
      Future.delayed(AppDurations.Durations.wrongChunkFeedback, () {
        if (!mounted || currentFlow != _flowId) return;
        setState(() {
          _showFeedback = false;
          _selectedOrder.remove(idx); // Remove the wrong chunk
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.current;
    final title = loc.actionBuildTerm;

    if (_targetText.isEmpty) return const SizedBox.shrink();

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
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
                    child: widget.type == MergeActionType.audioToTarget
                        ? AudioCard(
                            term: widget.term,
                            targetLanguageCode: _targetLanguageCode ?? 'en',
                          )
                        : widget.type == MergeActionType.questionToTarget
                        ? QuestionCard(
                            term: widget.term,
                            questionText: _cachedQuestion,
                          )
                        : VisualCard(term: widget.term),
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
                            term: widget.term,
                            languageCode: _targetLanguageCode ?? 'en',
                            displayText: _builtText,
                            colorStatus: _showFeedback
                                ? (_isResultCorrect
                                      ? CardColorStatus.correct
                                      : CardColorStatus.incorrect)
                                : CardColorStatus.deselected,
                            showIcon: false,
                            onTap: () {
                              setState(() {
                                _selectedOrder.clear();
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: MergeCard(
                            term: widget.term,
                            targetLanguageCode: _targetLanguageCode ?? 'en',
                            chunks: _chunks,
                            shuffledIndices: _shuffledIndices,
                            selectedIndices: _selectedOrder,
                            onToggle: _toggleLetter,
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
