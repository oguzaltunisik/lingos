import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lingos/models/topic.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/app_localizations.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/widgets/action_button.dart';
import 'package:lingos/widgets/visual_card.dart';
import 'package:lingos/widgets/target_card.dart';
import 'package:lingos/widgets/audio_card.dart';

enum PairActionType { visualToTarget, audioToTarget, audioToVisual }

class PairAction extends StatefulWidget {
  const PairAction({
    super.key,
    required this.topic,
    required this.terms,
    required this.onNext,
  });

  final Topic topic;
  final List<Term> terms;
  final VoidCallback onNext;

  @override
  State<PairAction> createState() => _PairActionState();
}

class _PairActionState extends State<PairAction> {
  int? _selectedLeftIndex;
  int? _selectedRightIndex;
  Map<int, int> _pairs = {}; // left index -> right display index
  Map<int, int> _rightDisplayToOriginal =
      {}; // right display index -> original index
  bool _showFeedback = false;
  String? _targetLanguageCode;
  List<int> _rightIndices = [];
  late PairActionType _type;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Randomly select pair action type
    _type =
        PairActionType.values[_random.nextInt(PairActionType.values.length)];
    // Create shuffled right side indices once
    if (widget.terms.isNotEmpty) {
      _rightIndices = List.generate(widget.terms.length, (i) => i)
        ..shuffle(_random);
      _rightDisplayToOriginal = {
        for (int i = 0; i < _rightIndices.length; i++) i: _rightIndices[i],
      };
    }
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final target = await LanguageService.getTargetLanguage();
    if (!mounted) return;
    setState(() {
      _targetLanguageCode = target;
    });
  }

  bool _onLeftCardTap(int index) {
    if (_showFeedback) return false;
    if (_pairs.containsKey(index)) return false; // Already paired

    bool wasSelected = _selectedLeftIndex == index;
    setState(() {
      if (wasSelected) {
        _selectedLeftIndex = null;
      } else {
        _selectedLeftIndex = index;
        if (_selectedRightIndex != null) {
          // Create pair: left index -> right display index
          _pairs[index] = _selectedRightIndex!;
          _selectedLeftIndex = null;
          _selectedRightIndex = null;
        }
      }
    });
    return !wasSelected; // Return true if selected, false if deselected
  }

  void _onRightCardTap(int displayIndex) {
    if (_showFeedback) return;
    if (_pairs.values.contains(displayIndex)) return; // Already paired

    // Can only select right if left is already selected
    if (_selectedLeftIndex == null) return;

    setState(() {
      if (_selectedRightIndex == displayIndex) {
        _selectedRightIndex = null;
      } else {
        _selectedRightIndex = displayIndex;
        // Create pair: left index -> right display index
        _pairs[_selectedLeftIndex!] = displayIndex;
        _selectedLeftIndex = null;
        _selectedRightIndex = null;
      }
    });
  }

  bool get _allPaired {
    return _pairs.length == widget.terms.length;
  }

  void _checkPairs() {
    setState(() {
      _showFeedback = true;
    });
  }

  void _handleNext() {
    widget.onNext();
  }

  Color? _getLeftCardColor(int leftIndex) {
    if (!_showFeedback) {
      return _selectedLeftIndex == leftIndex
          ? Theme.of(context).colorScheme.primary
          : null;
    }
    // Show feedback: green if correct pair, red if wrong
    final rightDisplayIndex = _pairs[leftIndex];
    if (rightDisplayIndex == null) return null;
    final originalIndex = _rightDisplayToOriginal[rightDisplayIndex];
    if (originalIndex == null) return null;
    return leftIndex == originalIndex ? Colors.green : Colors.red;
  }

  Color? _getRightCardColor(int displayIndex) {
    if (!_showFeedback) {
      return _selectedRightIndex == displayIndex
          ? Theme.of(context).colorScheme.primary
          : null;
    }
    // Show feedback: green if correct pair, red if wrong
    final leftIndex = _pairs.entries
        .firstWhere(
          (e) => e.value == displayIndex,
          orElse: () => const MapEntry(-1, -1),
        )
        .key;
    if (leftIndex == -1) return null;
    final originalIndex = _rightDisplayToOriginal[displayIndex];
    if (originalIndex == null) return null;
    return leftIndex == originalIndex ? Colors.green : Colors.red;
  }

  Widget _buildLeftCard(Term term, int index) {
    final isSelected = _selectedLeftIndex == index || _pairs.containsKey(index);
    final overrideColor = _getLeftCardColor(index);

    switch (_type) {
      case PairActionType.visualToTarget:
        return VisualCard(
          term: term,
          topic: widget.topic,
          isSelected: isSelected,
          onTap: () => _onLeftCardTap(index),
          overrideColor: overrideColor,
          showIcon: false,
        );
      case PairActionType.audioToTarget:
      case PairActionType.audioToVisual:
        return AudioCard(
          topic: widget.topic,
          term: term,
          isSelected: isSelected,
          onSelected: () => _onLeftCardTap(index),
          overrideColor: overrideColor,
        );
    }
  }

  Widget _buildRightCard(
    Term term,
    int displayIndex,
    bool isPaired,
    String targetLanguageCode,
  ) {
    final isSelected = _selectedRightIndex == displayIndex || isPaired;
    final overrideColor = _getRightCardColor(displayIndex);

    switch (_type) {
      case PairActionType.visualToTarget:
      case PairActionType.audioToTarget:
        return TargetCard(
          topic: widget.topic,
          targetText: term.getText(targetLanguageCode),
          languageCode: targetLanguageCode,
          isSelected: isSelected,
          onTap: () => _onRightCardTap(displayIndex),
          overrideColor: overrideColor,
          showIcon: false,
        );
      case PairActionType.audioToVisual:
        return VisualCard(
          term: term,
          topic: widget.topic,
          isSelected: isSelected,
          onTap: () => _onRightCardTap(displayIndex),
          overrideColor: overrideColor,
          showIcon: false,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.current;
    final scheme = Theme.of(context).colorScheme;
    final targetLanguageCode = _targetLanguageCode;

    if (targetLanguageCode == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.terms.isEmpty || _rightIndices.isEmpty) {
      return const Center(child: Text('No terms available'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        spacing: 16,
        children: [
          Text(
            loc.actionPair,
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
                // Left side cards
                Expanded(
                  child: Column(
                    spacing: 12,
                    children: widget.terms.asMap().entries.map((entry) {
                      final index = entry.key;
                      final term = entry.value;
                      return Expanded(child: _buildLeftCard(term, index));
                    }).toList(),
                  ),
                ),
                // Right side cards (shuffled)
                Expanded(
                  child: Column(
                    spacing: 12,
                    children: _rightIndices.asMap().entries.map((entry) {
                      final displayIndex = entry.key;
                      final originalIndex = entry.value;
                      if (originalIndex < 0 ||
                          originalIndex >= widget.terms.length) {
                        return const SizedBox.shrink();
                      }
                      final term = widget.terms[originalIndex];
                      final isPaired = _pairs.values.contains(displayIndex);
                      return Expanded(
                        child: _buildRightCard(
                          term,
                          displayIndex,
                          isPaired,
                          targetLanguageCode,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          ActionButton(
            label: _showFeedback ? loc.nextButton : loc.checkButton,
            onPressed: _showFeedback
                ? _handleNext
                : (_allPaired ? _checkPairs : null),
          ),
        ],
      ),
    );
  }
}
