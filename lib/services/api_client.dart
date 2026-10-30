import 'dart:developer' as dev;
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../core/constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio _dio;
  late Dio _refreshDio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  VoidCallback? _onUnauthorized;

  ApiClient._internal() {
    _initDio();
  }

  void _initDio() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));

    _refreshDio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final path = options.path;
        final isAuthEndpoint = path.contains('/auth/login') ||
            path.contains('/auth/register') ||
            path.contains('/auth/refresh') ||
            path.contains('/health');

        if (!isAuthEndpoint) {
          final token = await _storage.read(key: AppConstants.accessTokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final path = error.requestOptions.path;
        final isAuthEndpoint = path.contains('/auth/login') ||
            path.contains('/auth/register') ||
            path.contains('/auth/refresh') ||
            path.contains('/health');

        // Handle server cold-start / wake-up resilience (Render free tier sleeps)
        final statusCode = error.response?.statusCode;
        final isGatewayOrTimeout = error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.connectionError ||
            statusCode == 502 ||
            statusCode == 503 ||
            statusCode == 504;

        final retryCount = error.requestOptions.extra['coldStartRetry'] as int? ?? 0;
        if (isGatewayOrTimeout && retryCount < 2) {
          try {
            error.requestOptions.extra['coldStartRetry'] = retryCount + 1;
            await Future.delayed(Duration(milliseconds: 1200 * (retryCount + 1)));
            final retryResponse = await _dio.fetch(error.requestOptions);
            return handler.resolve(retryResponse);
          } catch (_) {
            // Proceed to standard error flow if retry fails
          }
        }

        if (statusCode == 401 && !isAuthEndpoint) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            final retryResponse = await _retry(error.requestOptions);
            return handler.resolve(retryResponse);
          }
          _onUnauthorized?.call();
        }
        handler.next(error);
      },
    ));
  }

  void setOnUnauthorized(VoidCallback callback) => _onUnauthorized = callback;

  Future<bool> tryRefreshToken() => _tryRefreshToken();

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) return false;
      final response = await _refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data['data'];
      await _storage.write(key: AppConstants.accessTokenKey, value: data['accessToken']);
      await _storage.write(key: AppConstants.refreshTokenKey, value: data['refreshToken']);
      return true;
    } catch (e) {
      dev.log('Token refresh failed: $e', name: 'ApiClient');
      return false;
    }
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    final options = Options(
      method: requestOptions.method,
      headers: {'Authorization': 'Bearer $token'},
    );
    return _dio.request(requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> delete(String path) =>
      _dio.delete(path);

  Future<void> clearTokens() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }

  static String humanizeError(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Server is not responding. Please try again.';
        case DioExceptionType.connectionError:
          return 'Cannot reach the server. Please check your connection.';
        case DioExceptionType.badCertificate:
          return 'Security certificate error. Please contact support.';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        case DioExceptionType.badResponse:
          return _humanizeBadResponse(error.response);
        default:
          return 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  static String _humanizeBadResponse(Response? response) {
    if (response == null) return 'Something went wrong. Please try again.';
    final body = response.data;
    if (body is Map && body['message'] != null) {
      return body['message'] as String;
    }
    switch (response.statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'You do not have permission for this action.';
      case 404:
        return 'Requested resource not found.';
      case 409:
        return 'This item already exists.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  static bool isNetworkError(Object error) {
    return error is DioException &&
        (error.type == DioExceptionType.connectionTimeout ||
         error.type == DioExceptionType.sendTimeout ||
         error.type == DioExceptionType.receiveTimeout ||
         error.type == DioExceptionType.connectionError);
  }

  static bool isAuthError(Object error) {
    return error is DioException && error.response?.statusCode == 401;
  }
}
