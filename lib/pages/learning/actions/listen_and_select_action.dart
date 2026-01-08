import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingos/models/topic.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/tts_service.dart';
import 'package:lingos/pages/learning/actions/remember_action.dart';

class ListenAndSelectAction extends StatefulWidget {
  const ListenAndSelectAction({
    super.key,
    required this.topic,
    required this.term,
    required this.distractorTerm,
    required this.onNext,
    required this.nextLabel,
  });

  final Topic topic;
  final Term term;
  final Term distractorTerm;
  final VoidCallback onNext;
  final String nextLabel;

  @override
  State<ListenAndSelectAction> createState() => _ListenAndSelectActionState();
}

class _ListenAndSelectActionState extends State<ListenAndSelectAction> {
  static const Duration _ttsDelay = Duration(milliseconds: 350);
  bool _hasAnswered = false;
  int _flowId = 0;
  String? _targetLanguageCode;

  @override
  void initState() {
    super.initState();
    _loadLanguageAndStartFlow();
  }

  @override
  void didUpdateWidget(covariant ListenAndSelectAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.term.id != widget.term.id ||
        oldWidget.distractorTerm.id != widget.distractorTerm.id) {
      _loadLanguageAndStartFlow();
    }
  }

  Future<void> _loadLanguageAndStartFlow() async {
    _flowId++;
    final currentFlow = _flowId;

    final target = await LanguageService.getTargetLanguage();
    if (!mounted || currentFlow != _flowId) return;

    setState(() {
      _targetLanguageCode = target;
    });

    await _startFlow();
  }

  Future<void> _startFlow() async {
    _flowId++;
    final currentFlow = _flowId;
    setState(() {
      _hasAnswered = false;
    });

    await Future.delayed(_ttsDelay);
    if (!mounted || currentFlow != _flowId) return;
    await _playAudio();
  }

  Future<void> _playAudio() async {
    if (_targetLanguageCode == null) return;
    final text = widget.term.getText(_targetLanguageCode!);
    if (text.isEmpty) return;
    await TtsService.speakTerm(text: text, languageCode: _targetLanguageCode!);
  }

  Future<void> _onSelect(bool isCorrect) async {
    if (_hasAnswered) return;
    setState(() {
      _hasAnswered = true;
    });
    if (isCorrect) {
      await SystemSound.play(SystemSoundType.click);
    }
    await _playAudio();
  }

  @override
  Widget build(BuildContext context) {
    final topic = widget.topic;

    String _textForTerm(Term term) {
      if (_targetLanguageCode != null) {
        return term.getText(_targetLanguageCode!);
      }
      return term.textEn;
    }

    final options = [
      _Option(text: _textForTerm(widget.term), isCorrect: true),
      _Option(text: _textForTerm(widget.distractorTerm), isCorrect: false),
    ]..shuffle();

    if (_hasAnswered) {
      return RememberAction(
        topic: topic,
        term: widget.term,
        onNext: widget.onNext,
      );
    }

    return Column(
      children: [
        Expanded(
          child: Center(
            child: IconButton(
              iconSize: 40,
              color: topic.darkColor,
              onPressed: _playAudio,
              icon: const Icon(Icons.volume_up_rounded),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _OptionCard(
                      text: options[0].text,
                      topic: topic,
                      onTap: () => _onSelect(options[0].isCorrect),
                    ),
                  ),
                ),
                Expanded(
                  child: _OptionCard(
                    text: options[1].text,
                    topic: topic,
                    onTap: () => _onSelect(options[1].isCorrect),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Option {
  _Option({required this.text, required this.isCorrect});

  final String text;
  final bool isCorrect;
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.text,
    required this.topic,
    required this.onTap,
  });

  final String text;
  final Topic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: topic.darkColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
