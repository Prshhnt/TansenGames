import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service to manage article click history
/// Stores clicked article titles and URLs locally
class SearchHistoryService {
  static const String _historyKey = 'article_history';
  static const int _maxHistoryItems = 50;

  /// Add a clicked article to history
  Future<void> addArticle(String title, String url) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_historyKey) ?? [];
    
    // Create JSON string for article
    final articleJson = jsonEncode({'title': title, 'url': url, 'timestamp': DateTime.now().toIso8601String()});
    
    // Remove if already exists (to move to top)
    history.removeWhere((item) {
      try {
        final decoded = jsonDecode(item);
        return decoded['url'] == url;
      } catch (e) {
        return false;
      }
    });
    
    // Add to beginning
    history.insert(0, articleJson);
    
    // Limit history size
    if (history.length > _maxHistoryItems) {
      history = history.sublist(0, _maxHistoryItems);
    }
    
    await prefs.setStringList(_historyKey, history);
  }

  /// Get all article history
  Future<List<Map<String, String>>> getArticleHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_historyKey) ?? [];
    
    return history.map((item) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        return {
          'title': decoded['title'] as String,
          'url': decoded['url'] as String,
          'timestamp': decoded['timestamp'] as String,
        };
      } catch (e) {
        return <String, String>{};
      }
    }).where((item) => item.isNotEmpty).toList();
  }

  /// Clear all history
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  /// Remove a specific item from history by URL
  Future<void> removeFromHistory(String url) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_historyKey) ?? [];
    history.removeWhere((item) {
      try {
        final decoded = jsonDecode(item);
        return decoded['url'] == url;
      } catch (e) {
        return false;
      }
    });
    await prefs.setStringList(_historyKey, history);
  }
}
