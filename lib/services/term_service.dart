import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:lingos/models/term.dart';
import 'package:lingos/models/topic.dart';

class TermService {
  static List<Term>? _terms;
  static List<Topic>? _topics;
  static bool _isLoading = false;
  static Map<String, Map<String, dynamic>>? _languageData;

  // Load topics and terms from JSON files
  static Future<void> loadTerms() async {
    if (_isLoading || (_terms != null && _topics != null)) return;

    _isLoading = true;
    try {
      // Load main content.json (id and emoji only)
      final String contentResponse = await rootBundle.loadString(
        'assets/data/content.json',
      );
      final Map<String, dynamic> contentData = json.decode(contentResponse);
      final topicsJson = (contentData['topics'] as List?) ?? [];
      final termsJson = (contentData['terms'] as List?) ?? [];

      // Load language files
      _languageData = {};
      for (String lang in ['en', 'tr', 'fi', 'fr']) {
        try {
          final String langResponse = await rootBundle.loadString(
            'assets/data/content_$lang.json',
          );
          _languageData![lang] = json.decode(langResponse);
        } catch (e) {
          // If language file doesn't exist, continue
        }
      }

      // Create topics and terms with language data
      _topics = topicsJson.map((json) {
        return Topic.fromJson(json, _languageData);
      }).toList();

      _terms = termsJson.map((json) {
        return Term.fromJson(json, _languageData);
      }).toList();
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
      case 'fr':
        return term.textFr;
      case 'en':
      default:
        return term.textEn;
    }
  }
}
