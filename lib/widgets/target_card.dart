import 'package:flutter/material.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/tts_service.dart';
import 'package:lingos/widgets/mini_icon_button.dart';
import 'package:lingos/constants/card_colors.dart';

class TargetCard extends StatefulWidget {
  const TargetCard({
    super.key,
    required this.term,
    required this.languageCode,
    this.displayText,
    this.onTap,
    this.colorStatus = CardColorStatus.deselected,
    this.showIcon = true,
    this.showBorder = false,
  });

  final Term term;
  final String languageCode;
  final String?
  displayText; // Override text if needed (e.g., for merge/speak actions)
  final VoidCallback? onTap;
  final CardColorStatus colorStatus;
  final bool showIcon;
  final bool showBorder;

  String get _displayText {
    return displayText ?? term.getText(languageCode);
  }

  @override
  State<TargetCard> createState() => _TargetCardState();
}

class _TargetCardState extends State<TargetCard> {
  int _level = 0;

  @override
  void initState() {
    super.initState();
    _loadLevel();
  }

  Future<void> _loadLevel() async {
    final level = await Term.getLevel(widget.term.id);
    if (mounted) {
      setState(() {
        _level = level;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final primary = widget.colorStatus.getColor(context);
        final bgColor = widget.colorStatus.getBackgroundColor(context);
        final fgColor = widget.colorStatus.getTextColor(context);
        final scheme = Theme.of(context).colorScheme;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: bgColor,
                    border: widget.showBorder
                        ? Border.all(
                            color: primary.withValues(alpha: 0.3),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          widget._displayText,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: fgColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Text(
                    '$_level',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.colorStatus == CardColorStatus.deselected
                          ? primary
                          : Colors.white,
                    ),
                  ),
                ),
                if (widget.showIcon)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: MiniIconButton(
                      icon: Icons.volume_up_rounded,
                      color: widget.colorStatus == CardColorStatus.deselected
                          ? primary
                          : scheme.onPrimary,
                      onPressed: () async {
                        final text = widget._displayText;
                        if (text.isEmpty) return;
                        await TtsService.speakTerm(
                          text: text,
                          languageCode: widget.languageCode,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
