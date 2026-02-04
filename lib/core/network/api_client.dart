import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';

/// API Client - Xử lý HTTP requests với retry logic
class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;

  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add retry interceptor
    _dio.interceptors.add(
      _RetryInterceptor(
        dio: _dio,
        maxRetries: ApiConfig.maxRetries,
        retryDelay: ApiConfig.retryDelay,
      ),
    );

    // Logging disabled for performance - enable only for debugging specific issues
    // if (kDebugMode) {
    //   _dio.interceptors.add(LogInterceptor(
    //     request: false,
    //     requestHeader: false,
    //     requestBody: false,
    //     responseHeader: false,
    //     responseBody: false,
    //     error: true,
    //   ));
    // }
  }

  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }

  /// Reset instance (useful when changing server config)
  static void resetInstance() {
    _instance = null;
  }

  Dio get dio => _dio;

  /// Set auth token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Clear auth token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // ============================================
  // CACHING LAYER
  // ============================================

  final Map<String, _CacheEntry> _cache = {};

  /// GET request with caching - useful for static data like categories, equipments
  Future<Response<T>> getCached<T>(
    String path, {
    Duration cacheDuration = const Duration(hours: 1),
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _buildCacheKey(path, queryParameters);

    // Return cached response if valid and not forcing refresh
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final entry = _cache[cacheKey]!;
      if (!entry.isExpired) {
        debugPrint('📦 Cache hit for: $path');
        return entry.response as Response<T>;
      }
    }

    // Fetch fresh data
    debugPrint('🌐 Fetching fresh data for: $path');
    final response = await get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );

    // Cache the response
    _cache[cacheKey] = _CacheEntry(response, cacheDuration);

    return response;
  }

  /// Build cache key from path and query parameters
  String _buildCacheKey(String path, Map<String, dynamic>? queryParameters) {
    if (queryParameters == null || queryParameters.isEmpty) {
      return path;
    }
    final sortedParams =
        queryParameters.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    final paramString = sortedParams
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    return '$path?$paramString';
  }

  /// Clear specific cache entry
  void clearCacheEntry(String path, {Map<String, dynamic>? queryParameters}) {
    final cacheKey = _buildCacheKey(path, queryParameters);
    _cache.remove(cacheKey);
  }

  /// Clear all cache entries
  void clearCache() {
    _cache.clear();
    debugPrint('🗑️ Cache cleared');
  }

  /// Clear expired cache entries
  void cleanExpiredCache() {
    _cache.removeWhere((key, entry) => entry.isExpired);
  }
}

/// Cache entry with expiration
class _CacheEntry {
  final Response response;
  final DateTime expiry;

  _CacheEntry(this.response, Duration duration)
    : expiry = DateTime.now().add(duration);

  bool get isExpired => DateTime.now().isAfter(expiry);
}

/// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.success(T data) {
    return ApiResponse(success: true, data: data);
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
}

/// Paginated Response for list endpoints
class PaginatedResponse<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool hasMore;

  PaginatedResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final data = json['data'] as List? ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

    return PaginatedResponse<T>(
      items: data.map((e) => fromJsonT(e as Map<String, dynamic>)).toList(),
      totalCount: pagination['total'] as int? ?? data.length,
      page: pagination['page'] as int? ?? 1,
      pageSize: pagination['limit'] as int? ?? 20,
      hasMore:
          (pagination['page'] as int? ?? 1) <
          (pagination['totalPages'] as int? ?? 1),
    );
  }
}

/// Retry Interceptor - Tự động retry khi gặp lỗi timeout/connection
class _RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryDelay;

  _RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Chỉ retry với các lỗi có thể retry được
    if (_shouldRetry(err)) {
      final retryCount = err.requestOptions.extra['retryCount'] ?? 0;

      if (retryCount < maxRetries) {
        debugPrint(
          '🔄 Retrying request (${retryCount + 1}/$maxRetries): ${err.requestOptions.path}',
        );

        // Đợi trước khi retry
        await Future.delayed(retryDelay * (retryCount + 1));

        // Tăng retry count
        err.requestOptions.extra['retryCount'] = retryCount + 1;

        try {
          // Thực hiện retry
          final response = await dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } on DioException catch (e) {
          // Nếu vẫn lỗi, tiếp tục retry hoặc trả lỗi
          return onError(e, handler);
        }
      }
    }

    // Không retry được, trả lỗi
    return handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
  }
}
