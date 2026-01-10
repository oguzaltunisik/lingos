import 'package:flutter/material.dart';
import 'package:lingos/models/topic.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/services/language_service.dart';

class QuestionCard extends StatefulWidget {
  const QuestionCard({
    super.key,
    required this.topic,
    required this.term,
    this.questionText,
  });

  final Topic topic;
  final Term term;
  final String? questionText;

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  late Future<String> _nativeFuture;

  @override
  void initState() {
    super.initState();
    _nativeFuture = LanguageService.getNativeLanguage().then(
      (value) => value ?? 'en',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _nativeFuture,
      builder: (context, snapshot) {
        final lang = snapshot.data ?? 'en';
        final scheme = Theme.of(context).colorScheme;
        final primary = scheme.primary;
        final question = widget.questionText ?? widget.term.getQuestion(lang);
        return LayoutBuilder(
          builder: (context, constraints) {
            const double minFontSize = 16.0;
            const double maxFontSize = 32.0;
            final availableWidth = constraints.maxWidth - 32.0; // padding
            final availableHeight = constraints.maxHeight - 32.0; // padding

            // Calculate font size based on available space
            double fontSize = maxFontSize;
            if (question.isNotEmpty) {
              final textPainter = TextPainter(
                text: TextSpan(
                  text: question,
                  style: TextStyle(
                    fontSize: maxFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                textDirection: TextDirection.ltr,
                maxLines: null,
              );
              textPainter.layout(maxWidth: availableWidth);

              if (textPainter.height > availableHeight ||
                  textPainter.width > availableWidth) {
                // Scale down to fit, but respect minimum
                final scale = (availableWidth / textPainter.width)
                    .clamp(0.0, 1.0)
                    .clamp(0.0, availableHeight / textPainter.height);
                fontSize = (maxFontSize * scale).clamp(
                  minFontSize,
                  maxFontSize,
                );
              }
            }

            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: null,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.transparent,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            question,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                            softWrap: true,
                            maxLines: null,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
