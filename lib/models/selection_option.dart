import 'package:lingos/models/term.dart';

class SelectionOption {
  const SelectionOption({
    required this.text,
    required this.isCorrect,
    this.term,
    this.emoji,
    this.languageCode,
  });

  final String text;
  final bool isCorrect;
  final Term? term;
  final String? emoji;
  final String? languageCode;
}
