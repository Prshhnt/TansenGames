import 'package:shared_preferences/shared_preferences.dart';

/// Stores and persists API configuration used by the app.
class ApiSettings {
  static const String defaultBaseUrl = 'http://127.0.0.1:8000';
  static const String _baseUrlKey = 'api_base_url';

  static String _baseUrl = defaultBaseUrl;

  /// Current base URL for the backend API.
  static String get baseUrl => _baseUrl;

  /// Load persisted settings. Call during app startup before API usage.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_baseUrlKey)?.trim() ?? defaultBaseUrl;
  }

  /// Persist and update the base URL used by the API client.
  static Future<void> setBaseUrl(String baseUrl) async {
    _baseUrl = baseUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, baseUrl);
  }
}
