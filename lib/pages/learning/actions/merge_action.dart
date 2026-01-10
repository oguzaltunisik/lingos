import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingos/models/topic.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/app_localizations.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/tts_service.dart';
import 'package:lingos/pages/learning/actions/remember_action.dart';
import 'package:lingos/widgets/action_button.dart';
import 'package:lingos/widgets/visual_card.dart';
import 'package:lingos/widgets/audio_card.dart';
import 'package:lingos/widgets/merge_card.dart';
import 'package:lingos/widgets/target_card.dart';
import 'package:lingos/widgets/question_card.dart';

enum MergeActionType { audioToTarget, visualToTarget, questionToTarget }

class MergeAction extends StatefulWidget {
  const MergeAction({
    super.key,
    required this.topic,
    required this.term,
    required this.onNext,
    required this.type,
  });

  final Topic topic;
  final Term term;
  final VoidCallback onNext;
  final MergeActionType type;

  @override
  State<MergeAction> createState() => _MergeActionState();
}

class _MergeActionState extends State<MergeAction> {
  static const Duration _ttsDelay = Duration(milliseconds: 350);
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
      _cachedQuestion = cachedQuestion;
      _showTopCard = false;
      _showBottomCard = false;
    });

    if (_targetLanguageCode == null && _nativeLanguageCode == null) return;

    // Wait after screen opens
    await Future.delayed(_ttsDelay);
    if (!mounted || currentFlow != _flowId) return;

    // Show top card with fade
    setState(() {
      _showTopCard = true;
    });

    // Wait after top card appears - adjust based on question length if it's a question type, or 1s for visual card
    Duration waitDuration = _ttsDelay;
    if (widget.type == MergeActionType.questionToTarget) {
      final questionLength = cachedQuestion?.length ?? 0;
      // Base delay + additional time based on question length (roughly 50ms per character, min 350ms)
      waitDuration = Duration(
        milliseconds: (350 + (questionLength * 50)).clamp(350, 2000),
      );
    } else if (widget.type == MergeActionType.visualToTarget) {
      // Wait 1 second for visual card to be perceived
      waitDuration = const Duration(seconds: 1);
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
    await Future.delayed(_ttsDelay);
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
    final rng = Random();
    // Ensure not returning the original order to keep it visibly shuffled.
    for (int attempt = 0; attempt < 5; attempt++) {
      indices.shuffle(rng);
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

  void _toggleLetter(int idx) {
    setState(() {
      if (_selectedOrder.contains(idx)) {
        _selectedOrder.remove(idx);
      } else {
        _selectedOrder.add(idx);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final topic = widget.topic;
    final loc = AppLocalizations.current;
    final title = _hasAnswered
        ? loc.actionRemember
        : (widget.type == MergeActionType.audioToTarget
              ? loc.actionAudioToTargetMerge
              : widget.type == MergeActionType.questionToTarget
              ? loc.actionQuestionToTargetMerge
              : loc.actionVisualToTargetMerge);

    if (_targetText.isEmpty) return const SizedBox.shrink();

    if (_hasAnswered) {
      return RememberAction(
        topic: topic,
        term: widget.term,
        onNext: widget.onNext,
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
                    duration: const Duration(milliseconds: 300),
                    child: widget.type == MergeActionType.audioToTarget
                        ? AudioCard(
                            topic: topic,
                            term: widget.term,
                            isSelected: false,
                          )
                        : widget.type == MergeActionType.questionToTarget
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
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      spacing: 12,
                      children: [
                        Expanded(
                          child: TargetCard(
                            topic: topic,
                            targetText: _builtText,
                            languageCode: _targetLanguageCode ?? 'en',
                            isSelected: false,
                            overrideColor: _showFeedback
                                ? (_isResultCorrect ? Colors.green : Colors.red)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedOrder.clear();
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: MergeCard(
                            topic: topic,
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
          ActionButton(
            label: loc.checkButton,
            onPressed: (_selectedOrder.length >= 2 && !_showFeedback)
                ? () async {
                    final currentFlow = ++_flowId;
                    final isCorrect = _builtText == _targetText;
                    if (isCorrect &&
                        widget.type == MergeActionType.audioToTarget &&
                        _targetLanguageCode != null) {
                      await SystemSound.play(SystemSoundType.click);
                    }
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
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
