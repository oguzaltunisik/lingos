import 'package:flutter/material.dart';
import 'dart:math';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/app_localizations.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/sound_service.dart';
import 'package:lingos/widgets/visual_card.dart';
import 'package:lingos/widgets/target_card.dart';
import 'package:lingos/widgets/audio_card.dart';
import 'package:lingos/constants/durations.dart' as AppDurations;
import 'package:lingos/pages/learning/action_types.dart';
import 'package:lingos/constants/card_colors.dart';

class PairAction extends StatefulWidget {
  const PairAction({
    super.key,
    required this.terms,
    required this.onNext,
    required this.type,
  });

  final List<Term> terms;
  final VoidCallback onNext;
  final PairActionType type;

  @override
  State<PairAction> createState() => _PairActionState();
}

class _PairActionState extends State<PairAction> {
  int? _selectedLeftIndex;
  String? _targetLanguageCode;
  final List<int> _matchedPairs = [];
  final List<int> _rightIndices = [];
  final Map<int, bool> _showFeedback =
      {}; // Track which pairs show green feedback
  final Map<int, bool> _showWrongFeedback =
      {}; // Track which pairs show red feedback
  bool _isFirstAttempt = true; // Track if this is the first attempt

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _shuffleRight();
  }

  Future<void> _loadLanguage() async {
    final target = await LanguageService.getTargetLanguage();
    if (!mounted) return;
    setState(() {
      _targetLanguageCode = target;
    });
  }

  void _shuffleRight() {
    final random = Random();
    final indices = List.generate(3, (i) => i);
    indices.shuffle(random);
    setState(() {
      _rightIndices.clear();
      _rightIndices.addAll(indices);
    });
  }

  void _handleLeftTap(int index) {
    if (_matchedPairs.contains(index)) return; // Already matched

    setState(() {
      // Select the card (don't deselect if already selected)
      _selectedLeftIndex = index;
    });
  }

  void _handleRightTap(int rightIndex) {
    if (_selectedLeftIndex == null) return; // No left card selected
    if (_matchedPairs.contains(_selectedLeftIndex)) return; // Already matched

    final leftIndex = _selectedLeftIndex!;
    final originalRightIndex = _rightIndices[rightIndex];

    // Check if it's a correct match
    final isCorrect = leftIndex == originalRightIndex;

    if (isCorrect) {
      // Correct match - play sound, show green, then hide
      SoundService.playCorrect();
      setState(() {
        _showFeedback[leftIndex] = true;
        _selectedLeftIndex = null;
      });

      // After feedback, hide the matched pair
      Future.delayed(AppDurations.Durations.feedbackDisplay, () {
        if (!mounted) return;
        setState(() {
          _matchedPairs.add(leftIndex);
          _showFeedback.remove(leftIndex);
        });

        // Check if all pairs are matched
        if (_matchedPairs.length == 3) {
          Future.delayed(AppDurations.Durations.fadeOutDelay, () {
            if (!mounted) return;
            // Increase level only on first attempt success (primary term is first)
            if (widget.terms.isNotEmpty && _isFirstAttempt) {
              widget.terms.first.incrementLearningLevel();
            }
            widget.onNext();
          });
        }
      });
    } else {
      // Wrong match - play sound, show red only on the two selected cards (left and right that was tapped)
      SoundService.playIncorrect();
      setState(() {
        _showWrongFeedback[leftIndex] = true;
        // Use rightIndex to track which right card was tapped, not originalRightIndex
        _showWrongFeedback[rightIndex + 10] =
            true; // Add offset to avoid conflict with left indices
        _isFirstAttempt = false; // Mark that first attempt failed
      });

      // Clear red feedback after delay, but keep left card selected
      Future.delayed(AppDurations.Durations.feedbackDisplay, () {
        if (!mounted) return;
        setState(() {
          _showWrongFeedback.remove(leftIndex);
          _showWrongFeedback.remove(rightIndex + 10);
        });
      });
    }
  }

  Widget _buildLeftCard(int index) {
    final isSelected = _selectedLeftIndex == index;
    final isMatched = _matchedPairs.contains(index);
    final showGreen = _showFeedback[index] == true;
    final showRed = _showWrongFeedback[index] == true;

    if (isMatched) {
      return Opacity(
        opacity: 0,
        child: IgnorePointer(
          child: _buildLeftCardContent(
            index,
            colorStatus: CardColorStatus.deselected,
          ),
        ),
      );
    }

    CardColorStatus colorStatus;
    if (showRed) {
      colorStatus = CardColorStatus.incorrect;
    } else if (showGreen) {
      colorStatus = CardColorStatus.correct;
    } else if (isSelected) {
      colorStatus = CardColorStatus.selected;
    } else {
      colorStatus = CardColorStatus.deselected;
    }

    // For audio types, AudioCard handles its own tap, so don't wrap in GestureDetector
    final isAudioType =
        widget.type == PairActionType.audioToTarget ||
        widget.type == PairActionType.audioToVisual;

    if (isAudioType) {
      return _buildLeftCardContent(index, colorStatus: colorStatus);
    }

    return GestureDetector(
      onTap: () => _handleLeftTap(index),
      child: _buildLeftCardContent(index, colorStatus: colorStatus),
    );
  }

  Widget _buildLeftCardContent(
    int index, {
    required CardColorStatus colorStatus,
  }) {
    final term = widget.terms[index];

    switch (widget.type) {
      case PairActionType.visualToTarget:
        return VisualCard(
          term: term,
          colorStatus: colorStatus,
          showIcon: false,
          showBorder: true,
        );
      case PairActionType.audioToTarget:
      case PairActionType.audioToVisual:
        return AudioCard(
          term: term,
          targetLanguageCode: _targetLanguageCode ?? 'en',
          colorStatus: colorStatus,
          showBorder: true,
          onSelected: () {
            // Handle selection and play TTS
            _handleLeftTap(index);
            return true; // Play TTS
          },
        );
    }
  }

  Widget _buildRightCard(int rightIndex) {
    final originalIndex = _rightIndices[rightIndex];
    final isMatched = _matchedPairs.contains(originalIndex);
    final showGreen = _showFeedback[originalIndex] == true;
    final showRed =
        _showWrongFeedback[rightIndex + 10] ==
        true; // Use rightIndex with offset

    if (isMatched) {
      return Opacity(
        opacity: 0,
        child: IgnorePointer(
          child: _buildRightCardContent(
            originalIndex,
            colorStatus: CardColorStatus.deselected,
          ),
        ),
      );
    }

    CardColorStatus colorStatus;
    if (showRed) {
      colorStatus = CardColorStatus.incorrect;
    } else if (showGreen) {
      colorStatus = CardColorStatus.correct;
    } else {
      colorStatus = CardColorStatus.deselected;
    }

    return GestureDetector(
      onTap: () => _handleRightTap(rightIndex),
      child: _buildRightCardContent(originalIndex, colorStatus: colorStatus),
    );
  }

  Widget _buildRightCardContent(
    int index, {
    required CardColorStatus colorStatus,
  }) {
    final term = widget.terms[index];
    final targetLang = _targetLanguageCode ?? 'en';

    switch (widget.type) {
      case PairActionType.visualToTarget:
      case PairActionType.audioToTarget:
        return TargetCard(
          languageCode: targetLang,
          term: term,
          colorStatus: colorStatus,
          showIcon: false,
          showBorder: true,
        );
      case PairActionType.audioToVisual:
        return VisualCard(
          term: term,
          colorStatus: colorStatus,
          showIcon: false,
          showBorder: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.current;
    final scheme = Theme.of(context).colorScheme;

    if (widget.terms.length < 3) {
      return const SizedBox.shrink();
    }

    final title = loc.actionPair;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        spacing: 16,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            ),
          ),
          Expanded(
            child: Row(
              spacing: 16,
              children: [
                // Left column
                Expanded(
                  child: Column(
                    spacing: 12,
                    children: List.generate(3, (i) {
                      return Expanded(child: _buildLeftCard(i));
                    }),
                  ),
                ),
                // Right column
                Expanded(
                  child: Column(
                    spacing: 12,
                    children: List.generate(3, (i) {
                      return Expanded(child: _buildRightCard(i));
                    }),
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
