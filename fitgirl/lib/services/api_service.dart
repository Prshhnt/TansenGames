import 'package:dio/dio.dart';
import '../models/article_link.dart';
import '../models/download_link.dart';
import '../models/game_metadata.dart';
import '../models/home_data.dart';
import 'api_settings_service.dart';

/// Service class for communicating with the Python FastAPI backend
/// All scraping logic is handled by Python - Flutter only consumes the API
class ApiService {
  static Dio? _sharedDio;
  static String _currentBaseUrl = ApiSettings.baseUrl;

  final String? _overrideBaseUrl;

  ApiService({String? baseUrl}) : _overrideBaseUrl = baseUrl;

  String get resolvedBaseUrl => _overrideBaseUrl ?? ApiSettings.baseUrl;

  Dio get _dio => _ensureClient();

  Dio _ensureClient() {
    final resolvedBaseUrl = _overrideBaseUrl ?? ApiSettings.baseUrl;
    final needsNewClient = _sharedDio == null || resolvedBaseUrl != _currentBaseUrl;

    if (needsNewClient) {
      _currentBaseUrl = resolvedBaseUrl;
      _sharedDio = Dio(
        BaseOptions(
          baseUrl: resolvedBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      _sharedDio!.interceptors.clear();
      _sharedDio!.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => print('[API] $obj'),
        ),
      );
    }

    return _sharedDio!;
  }

  /// Probe a specific base URL without mutating shared client state.
  static Future<bool> testEndpoint(String baseUrl) async {
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      );
      final response = await dio.get('/');
      return response.statusCode == 200;
    } catch (e) {
      print('Health check ($baseUrl) failed: $e');
      return false;
    }
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

  /// Fetch popular repacks from FitGirl Repacks
  ///
  /// Returns list of ArticleLink or throws exception on error
  Future<List<ArticleLink>> fetchPopularRepacks({
    String imageSize = 'medium',
    bool forceRefresh = false,
  }) async {
    try {
      final response = await _dio.get(
        '/api/popular-repacks',
        queryParameters: {
          'image_size': imageSize,
          if (forceRefresh) 'force_refresh': true,
        },
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
          'Cannot connect to backend. Please ensure the Python API is running at $resolvedBaseUrl',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to fetch popular repacks: $e');
    }
  }

  /// Search FitGirl Repacks for games
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
          'Cannot connect to backend. Please ensure the Python API is running at $resolvedBaseUrl',
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
          'Cannot connect to backend. Please ensure the Python API is running at $resolvedBaseUrl',
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
          'Cannot connect to backend. Please ensure the Python API is running at $resolvedBaseUrl',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to decrypt paste: $e');
    }
  }

  /// Extract actual download buttons from FuckingFast page
  ///
  /// [fuckingfastUrl] - FuckingFast URL to extract download links from
  ///
  /// Returns list of DownloadLink with actual download URLs
  Future<List<DownloadLink>> extractFuckingFastButtons(
      String fuckingfastUrl) async {
    try {
      final response = await _dio.get(
        '/api/extract-fuckingfast',
        queryParameters: {'fuckingfast_url': fuckingfastUrl},
      );

      // Parse response
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final buttonsJson = data['data'] as List<dynamic>;
        return buttonsJson
            .map((json) => DownloadLink.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(data['error'] ?? 'Unknown error occurred');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout. FuckingFast page is slow.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Cannot connect to backend. Please ensure the Python API is running at $resolvedBaseUrl',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to extract FuckingFast buttons: $e');
    }
  }

  /// Fetch detailed game metadata for a given repack page
  Future<GameMetadata> fetchGameMetadata(
    String pageUrl, {
    String imageSize = 'medium',
    bool forceRefresh = false,
  }) async {
    try {
      final response = await _dio.get(
        '/api/game-metadata',
        queryParameters: {
          'page_url': pageUrl,
          'image_size': imageSize,
          if (forceRefresh) 'force_refresh': true,
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true && data['data'] != null) {
        return GameMetadata.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw Exception(data['error'] ?? 'Failed to fetch game metadata');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout while fetching game metadata.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Cannot connect to backend. Please ensure the Python API is running at $resolvedBaseUrl',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to fetch game metadata: $e');
    }
  }

  /// Fetch aggregate home data (featured, latest, upcoming, popular)
  Future<HomeData> fetchHome({
    int maxItems = 12,
    String imageSize = 'medium',
    bool forceRefresh = false,
  }) async {
    try {
      final response = await _dio.get(
        '/api/home',
        queryParameters: {
          'max_items': maxItems,
          'image_size': imageSize,
          if (forceRefresh) 'force_refresh': true,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return HomeData.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception(data['error'] ?? 'Failed to fetch home data');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout while fetching home data.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Cannot connect to backend. Please ensure the Python API is running at $resolvedBaseUrl',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to fetch home data: $e');
    }
  }

  /// Fetch home latest list
  Future<List<HomeItem>> fetchHomeLatest({
    int maxItems = 12,
    String imageSize = 'medium',
    bool forceRefresh = false,
  }) async {
    try {
      final response = await _dio.get(
        '/api/home-latest',
        queryParameters: {
          'max_items': maxItems,
          'image_size': imageSize,
          if (forceRefresh) 'force_refresh': true,
        },
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final items = (data['data'] as List<dynamic>? ?? [])
            .map((e) => HomeItem.fromJson(e as Map<String, dynamic>))
            .toList();
        return items;
      }
      throw Exception(data['error'] ?? 'Failed to fetch home latest');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout while fetching home latest.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Cannot connect to backend. Please ensure the Python API is running at $resolvedBaseUrl',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to fetch home latest: $e');
    }
  }

  /// Fetch upcoming list
  Future<List<String>> fetchUpcoming() async {
    try {
      final response = await _dio.get('/api/upcoming');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final items = (data['data'] as List<dynamic>? ?? [])
            .map((e) => (e as Map<String, dynamic>)['title']?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
        return items;
      }
      throw Exception(data['error'] ?? 'Failed to fetch upcoming');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout while fetching upcoming.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Cannot connect to backend. Please ensure the Python API is running at $resolvedBaseUrl',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to fetch upcoming: $e');
    }
  }
}
