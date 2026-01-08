import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:lingos/models/term.dart';

class TermService {
  static List<Term>? _terms;
  static bool _isLoading = false;

  // Load terms from JSON file
  static Future<void> loadTerms() async {
    if (_isLoading || _terms != null) return;

    _isLoading = true;
    try {
      final String response = await rootBundle.loadString(
        'assets/data/terms.json',
      );
      final List<dynamic> data = json.decode(response);
      _terms = data.map((json) => Term.fromJson(json)).toList();
    } catch (e) {
      _terms = [];
    } finally {
      _isLoading = false;
    }
  }

  // Get all terms
  static List<Term> getAllTerms() {
    return _terms ?? [];
  }

  // Get terms by topic ID
  static List<Term> getTermsByTopic(String topicId) {
    return getAllTerms()
        .where((term) => term.topicIds.contains(topicId))
        .toList();
  }

  // Get term by ID
  static Term? getTermById(String termId) {
    try {
      return getAllTerms().firstWhere((term) => term.id == termId);
    } catch (e) {
      return null;
    }
  }

  // Get term text in specific language
  static String? getTermText(String termId, String languageCode) {
    final term = getTermById(termId);
    if (term == null) return null;

    switch (languageCode) {
      case 'tr':
        return term.textTr;
      case 'fi':
        return term.textFi;
      case 'en':
      default:
        return term.textEn;
    }
  }
}
