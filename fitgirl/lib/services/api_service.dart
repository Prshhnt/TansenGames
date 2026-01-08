import 'package:dio/dio.dart';
import '../models/article_link.dart';
import '../models/download_link.dart';

/// Service class for communicating with the Python FastAPI backend
/// All scraping logic is handled by Python - Flutter only consumes the API
class ApiService {
  late final Dio _dio;
  final String baseUrl;

  ApiService({this.baseUrl = 'http://127.0.0.1:8000'}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add interceptor for logging (helpful for debugging)
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('[API] $obj'),
      ),
    );
  }

  /// Check if backend is online
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/');
      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  /// Search Fitgirl Repacks for games
  ///
  /// [query] - Search term (e.g., "resident evil")
  ///
  /// Returns list of ArticleLink or throws exception on error
  Future<List<ArticleLink>> searchGames(String query) async {
    try {
      final response = await _dio.get(
        '/api/search',
        queryParameters: {'query': query},
      );

      // Parse response
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final articlesJson = data['data'] as List<dynamic>;
        return articlesJson
            .map((json) => ArticleLink.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(data['error'] ?? 'Unknown error occurred');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Connection timeout. Please check if backend is running.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Cannot connect to backend. Please ensure the Python API is running at $baseUrl',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to search: $e');
    }
  }

  /// Fetch download mirrors from a specific article page
  ///
  /// [pageUrl] - Full URL of the article page
  ///
  /// Returns list of DownloadLink or throws exception on error
  Future<List<DownloadLink>> fetchDownloadMirrors(String pageUrl) async {
    try {
      final response = await _dio.get(
        '/api/download-links',
        queryParameters: {'page_url': pageUrl},
      );

      // Parse response
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final linksJson = data['data'] as List<dynamic>;
        return linksJson
            .map((json) => DownloadLink.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(data['error'] ?? 'Unknown error occurred');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout. The page might be slow to load.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Cannot connect to backend. Please ensure the Python API is running at $baseUrl',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to fetch download mirrors: $e');
    }
  }

  /// Decrypt PrivateBin paste and extract download URLs
  ///
  /// [pasteUrl] - Full URL of the PrivateBin paste (must include #key)
  ///
  /// Returns list of extracted URLs or throws exception on error
  Future<List<String>> decryptPaste(String pasteUrl) async {
    try {
      final response = await _dio.get(
        '/api/decrypt-paste',
        queryParameters: {'paste_url': pasteUrl},
      );

      // Parse response
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final urlsJson = data['data'] as List<dynamic>;
        return urlsJson.map((url) => url.toString()).toList();
      } else {
        throw Exception(data['error'] ?? 'Unknown error occurred');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout. Decryption is taking too long.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Cannot connect to backend. Please ensure the Python API is running at $baseUrl',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to decrypt paste: $e');
    }
  }
}
