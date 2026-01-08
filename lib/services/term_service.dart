import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/models/topic.dart';

class TermService {
  static List<Term>? _terms;
  static List<Topic>? _topics;
  static bool _isLoading = false;

  // Load topics and terms from JSON file
  static Future<void> loadTerms() async {
    if (_isLoading || (_terms != null && _topics != null)) return;

    _isLoading = true;
    try {
      final String response = await rootBundle.loadString(
        'assets/data/content.json',
      );
      final Map<String, dynamic> data = json.decode(response);
      final topicsJson = (data['topics'] as List?) ?? [];
      final termsJson = (data['terms'] as List?) ?? [];

      _topics = topicsJson.map((json) => Topic.fromJson(json)).toList();
      _terms = termsJson.map((json) => Term.fromJson(json)).toList();
    } catch (e) {
      _terms = [];
      _topics = [];
    } finally {
      _isLoading = false;
    }
  }

  // Get all terms
  static List<Term> getAllTerms() {
    return _terms ?? [];
  }

  // Get all topics
  static List<Topic> getTopics() {
    return _topics ?? [];
  }

  static Topic? getTopicById(String topicId) {
    try {
      return getTopics().firstWhere((t) => t.id == topicId);
    } catch (e) {
      return null;
    }
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
