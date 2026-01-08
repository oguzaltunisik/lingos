import 'package:flutter/material.dart';
import 'package:lingos/models/topic.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/app_localizations.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/widgets/native_term_card.dart';
import 'package:lingos/widgets/target_term_card.dart';
import 'package:lingos/widgets/action_button.dart';

class RememberAction extends StatefulWidget {
  const RememberAction({
    super.key,
    required this.topic,
    required this.term,
    required this.onNext,
  });

  final Topic topic;
  final Term term;
  final VoidCallback onNext;

  @override
  State<RememberAction> createState() => _RememberActionState();
}

class _RememberActionState extends State<RememberAction> {
  bool _canProceed = false;
  int _flowId = 0;
  String? _targetLanguageCode;
  static const Duration _preTtsDelay = Duration(milliseconds: 300);

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
    setState(() {
      _canProceed = false;
    });

    final target = await LanguageService.getTargetLanguage();
    if (!mounted || currentFlow != _flowId) return;
    setState(() {
      _targetLanguageCode = target;
    });

    await Future.delayed(_preTtsDelay);
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
                    child: NativeTermCard(
                      term: term,
                      topic: topic,
                      nativeLanguageText: null, // no translation shown
                    ),
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
