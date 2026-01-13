import 'package:flutter/material.dart';
import 'dart:math';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/app_localizations.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/sound_service.dart';
import 'package:lingos/widgets/visual_card.dart';
import 'package:lingos/widgets/target_card.dart';
import 'package:lingos/widgets/audio_card.dart';
import 'package:lingos/services/tts_service.dart';
import 'package:lingos/constants/durations.dart' as AppDurations;
import 'package:lingos/pages/learning/action_types.dart';
import 'package:lingos/constants/card_colors.dart';

class MemoryAction extends StatefulWidget {
  const MemoryAction({
    super.key,
    required this.terms,
    required this.onNext,
    required this.type,
  });

  final List<Term> terms;
  final VoidCallback onNext;
  final MemoryActionType type;

  @override
  State<MemoryAction> createState() => _MemoryActionState();
}

class _MemoryActionState extends State<MemoryAction> {
  String? _targetLanguageCode;
  final List<int> _cardIndices = []; // 0-5 indices for 6 cards (3 terms * 2)
  final List<bool> _isLeftCard =
      []; // true for left type (visual/audio), false for right type (target/visual)
  final Set<int> _flippedCards = {}; // Currently flipped cards
  final Set<int> _matchedPairs = {}; // Matched card indices
  int? _firstFlippedIndex;
  int? _secondFlippedIndex;
  bool _isChecking = false;
  bool _isFirstAttempt = true; // Track if this is the first attempt

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _initializeCards();
  }

  Future<void> _loadLanguage() async {
    final target = await LanguageService.getTargetLanguage();
    if (!mounted) return;
    setState(() {
      _targetLanguageCode = target;
    });
  }

  void _initializeCards() {
    // Create pairs: each term has 2 cards, one left type and one right type
    // Then shuffle the positions
    final pairs = <int>[];
    final leftTypes = <bool>[];
    final random = Random();

    // For each term, create one left card and one right card
    for (int i = 0; i < 3; i++) {
      pairs.add(i); // Left card
      pairs.add(i); // Right card
      leftTypes.add(true); // First card is left type
      leftTypes.add(false); // Second card is right type
    }

    // Shuffle pairs and leftTypes together while keeping the pair relationship
    final combined = List.generate(
      6,
      (i) => {'pair': pairs[i], 'left': leftTypes[i]},
    );
    combined.shuffle(random);

    setState(() {
      _cardIndices.clear();
      _isLeftCard.clear();
      for (var item in combined) {
        _cardIndices.add(item['pair'] as int);
        _isLeftCard.add(item['left'] as bool);
      }
    });
  }

  Future<void> _handleCardTap(int cardIndex) async {
    if (_isChecking) return; // Don't allow during check
    if (_matchedPairs.contains(cardIndex)) return; // Already matched
    if (_flippedCards.contains(cardIndex)) return; // Already flipped

    final isLeft = _isLeftCard[cardIndex];
    final isAudioCard =
        (widget.type == MemoryActionType.audioToTarget ||
            widget.type == MemoryActionType.audioToVisual) &&
        isLeft;

    final isFirstCard = _firstFlippedIndex == null;
    final isSecondCard =
        _firstFlippedIndex != null && _secondFlippedIndex == null;

    setState(() {
      _flippedCards.add(cardIndex);
      if (isFirstCard) {
        _firstFlippedIndex = cardIndex;
      } else if (isSecondCard) {
        _secondFlippedIndex = cardIndex;
        _isChecking = true;
      }
    });

    // Play TTS for audio cards when flipped and wait for it to finish
    if (isAudioCard && _targetLanguageCode != null) {
      final termIndex = _cardIndices[cardIndex];
      final term = widget.terms[termIndex];
      final text = term.getText(_targetLanguageCode!);
      if (text.isNotEmpty) {
        await TtsService.speakTerm(
          text: text,
          languageCode: _targetLanguageCode!,
        );
      }
    }

    // If this is the second card, check for match after TTS (if audio) finishes
    if (isSecondCard) {
      _checkMatch();
    }
  }

  void _checkMatch() {
    if (_firstFlippedIndex == null || _secondFlippedIndex == null) return;

    final firstTermIndex = _cardIndices[_firstFlippedIndex!];
    final secondTermIndex = _cardIndices[_secondFlippedIndex!];
    final firstIsLeft = _isLeftCard[_firstFlippedIndex!];
    final secondIsLeft = _isLeftCard[_secondFlippedIndex!];

    // Match if same term AND one is left type and other is right type
    final isMatch =
        firstTermIndex == secondTermIndex && firstIsLeft != secondIsLeft;

    if (isMatch) {
      // Correct match - play sound, show green, then hide
      SoundService.playCorrect();
      Future.delayed(AppDurations.Durations.feedbackDisplay, () {
        if (!mounted) return;
        setState(() {
          _matchedPairs.add(_firstFlippedIndex!);
          _matchedPairs.add(_secondFlippedIndex!);
          _flippedCards.remove(_firstFlippedIndex);
          _flippedCards.remove(_secondFlippedIndex);
          _firstFlippedIndex = null;
          _secondFlippedIndex = null;
          _isChecking = false;
        });

        // Check if all pairs are matched
        if (_matchedPairs.length == 6) {
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
      // Wrong match - play sound, show red, then flip back
      SoundService.playIncorrect();
      setState(() {
        _isFirstAttempt = false; // Mark that first attempt failed
      });
      Future.delayed(AppDurations.Durations.feedbackDisplay, () {
        if (!mounted) return;
        setState(() {
          _flippedCards.remove(_firstFlippedIndex);
          _flippedCards.remove(_secondFlippedIndex);
          _firstFlippedIndex = null;
          _secondFlippedIndex = null;
          _isChecking = false;
        });
      });
    }
  }

  Widget _buildCard(int cardIndex) {
    final isFlipped = _flippedCards.contains(cardIndex);
    final isMatched = _matchedPairs.contains(cardIndex);
    final isFirstFlipped = _firstFlippedIndex == cardIndex;
    final isSecondFlipped = _secondFlippedIndex == cardIndex;
    final isChecking = _isChecking && (isFirstFlipped || isSecondFlipped);

    // Determine if this is a correct or wrong match during checking
    CardColorStatus colorStatus;
    if (isChecking) {
      final firstTermIndex = _firstFlippedIndex != null
          ? _cardIndices[_firstFlippedIndex!]
          : null;
      final secondTermIndex = _secondFlippedIndex != null
          ? _cardIndices[_secondFlippedIndex!]
          : null;
      final firstIsLeft = _firstFlippedIndex != null
          ? _isLeftCard[_firstFlippedIndex!]
          : null;
      final secondIsLeft = _secondFlippedIndex != null
          ? _isLeftCard[_secondFlippedIndex!]
          : null;
      if (firstTermIndex != null &&
          secondTermIndex != null &&
          firstIsLeft != null &&
          secondIsLeft != null) {
        final isMatch =
            firstTermIndex == secondTermIndex && firstIsLeft != secondIsLeft;
        colorStatus = isMatch
            ? CardColorStatus.correct
            : CardColorStatus.incorrect;
      } else {
        colorStatus = CardColorStatus.deselected;
      }
    } else if (isFlipped) {
      // Show primary color for flipped cards
      colorStatus = CardColorStatus.selected;
    } else {
      colorStatus = CardColorStatus.deselected;
    }

    if (isMatched) {
      return Opacity(
        opacity: 0,
        child: IgnorePointer(
          child: _buildCardContent(
            cardIndex,
            colorStatus: CardColorStatus.deselected,
          ),
        ),
      );
    }

    if (!isFlipped) {
      // Card is face down
      return GestureDetector(
        onTap: () => _handleCardTap(cardIndex),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.help_outline,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    // Card is face up
    return GestureDetector(
      onTap: () => _handleCardTap(cardIndex),
      child: _buildCardContent(cardIndex, colorStatus: colorStatus),
    );
  }

  Widget _buildCardContent(
    int cardIndex, {
    required CardColorStatus colorStatus,
  }) {
    final termIndex = _cardIndices[cardIndex];
    final isLeft = _isLeftCard[cardIndex];
    final term = widget.terms[termIndex];
    final targetLang = _targetLanguageCode ?? 'en';

    switch (widget.type) {
      case MemoryActionType.visualToTarget:
        if (isLeft) {
          return VisualCard(
            term: term,
            colorStatus: colorStatus,
            showIcon: false,
            showBorder: true,
          );
        } else {
          return TargetCard(
            languageCode: targetLang,
            term: term,
            colorStatus: colorStatus,
            showIcon: false,
            showBorder: true,
          );
        }
      case MemoryActionType.audioToTarget:
        if (isLeft) {
          return AudioCard(
            term: term,
            targetLanguageCode: targetLang,
            colorStatus: colorStatus,
            showBorder: true,
            onSelected: () => true, // Play TTS when tapped
          );
        } else {
          return TargetCard(
            languageCode: targetLang,
            term: term,
            colorStatus: colorStatus,
            showIcon: false,
            showBorder: true,
          );
        }
      case MemoryActionType.audioToVisual:
        if (isLeft) {
          return AudioCard(
            term: term,
            targetLanguageCode: targetLang,
            colorStatus: colorStatus,
            showBorder: true,
            onSelected: () => true, // Play TTS when tapped
          );
        } else {
          return VisualCard(
            term: term,
            colorStatus: colorStatus,
            showIcon: false,
            showBorder: true,
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.current;
    final scheme = Theme.of(context).colorScheme;

    if (widget.terms.length < 3) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        spacing: 16,
        children: [
          Text(
            loc.actionMemory,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate card size to fit exactly in the available space
                final cardWidth = (constraints.maxWidth - 12) / 2;
                final cardHeight = (constraints.maxHeight - 24) / 3; // 3 rows

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: cardWidth / cardHeight,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: _buildCard(index),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
