import 'package:flutter/material.dart';
import 'package:lingos/models/topic.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/language_service.dart';
import 'package:lingos/services/tts_service.dart';
import 'package:lingos/widgets/mini_icon_button.dart';

class VisualCard extends StatefulWidget {
  const VisualCard({
    super.key,
    required this.term,
    required this.topic,
    this.translationInitiallyVisible = false,
    this.isSelected = false,
    this.onTap,
    this.overrideColor,
    this.showIcon = true,
  });

  final Term term;
  final Topic topic;
  final bool translationInitiallyVisible;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? overrideColor;
  final bool showIcon;

  @override
  State<VisualCard> createState() => _VisualCardState();
}

class _VisualCardState extends State<VisualCard> {
  late bool _showTranslation;
  String? _nativeLanguageCode;
  int _flowId = 0;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _showTranslation = widget.translationInitiallyVisible;
    _loadNativeLanguage();
  }

  Future<void> _loadNativeLanguage() async {
    final native = await LanguageService.getNativeLanguage();
    if (!mounted) return;
    setState(() {
      _nativeLanguageCode = native;
    });
  }

  Future<void> _speakAndShowTranslation() async {
    if (_nativeLanguageCode == null) return;
    final currentFlow = ++_flowId;
    final text = widget.term.getText(_nativeLanguageCode!);
    if (text.isEmpty) return;
    setState(() {
      _isSpeaking = true;
      _showTranslation = true;
    });
    await TtsService.speakTerm(text: text, languageCode: _nativeLanguageCode!);
    if (!mounted || currentFlow != _flowId) return;
    setState(() {
      _isSpeaking = false;
      _showTranslation = widget.translationInitiallyVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final translationText = (_nativeLanguageCode != null)
        ? widget.term.getText(_nativeLanguageCode!)
        : null;

    final showTranslation =
        translationText != null &&
        (_showTranslation || widget.translationInitiallyVisible);

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final scheme = Theme.of(context).colorScheme;
        final primary = widget.overrideColor ?? scheme.primary;
        final onPrimary = scheme.onPrimary;
        final bgColor =
            widget.overrideColor ??
            (widget.isSelected ? primary : Colors.transparent);
        final fgColor = widget.overrideColor != null
            ? onPrimary
            : widget.isSelected
            ? onPrimary
            : primary;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: bgColor,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.term.emoji,
                      style: const TextStyle(fontSize: 200),
                    ),
                    if (showTranslation) ...[
                      const SizedBox(height: 16),
                      Text(
                        translationText,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: fgColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (translationText == null && widget.onTap == null) {
      return content;
    }

    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap,
        child: content,
      ),
    );

    if (translationText == null) return card;

    if (!widget.showIcon) return card;

    return Stack(
      children: [
        card,
        Positioned(
          right: 12,
          bottom: 12,
          child: MiniIconButton(
            icon: Icons.translate_rounded,
            color: widget.isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.primary,
            onPressed: _isSpeaking ? null : _speakAndShowTranslation,
          ),
        ),
      ],
    );
  }
}
