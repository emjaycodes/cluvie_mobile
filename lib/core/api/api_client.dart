
import 'package:cluvie_mobile/core/utils/build_config.dart';
import 'package:dio/dio.dart';

import '../errors/api_exceptions.dart';

/// API base URL is resolved at compile time via --dart-define.
///
/// Usage:
///   flutter run --dart-define=API_BASE_URL=http://localhost:5000/api           # iOS simulator / local
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api             # Android emulator (host loopback)
///   flutter run --dart-define=API_BASE_URL=http://`lan-ip`:5000/api            # Physical device on same LAN
///   flutter build apk --dart-define=API_BASE_URL=https://api.cluvie.com/api    # QA / prod flavor
///
/// See OPERATIONS.md §2.3 and README.md "Environment Configuration".
/// Default is http://localhost:5000/api for local development.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  late final Dio _dio;

  // Compile-time env — prefer --dart-define; fallback to localhost default.
  // If flutter_dotenv is later adopted, this can be extended with dotenv fallback.
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000/api',
  );

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  void setupDioLogging() {
  _dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      log(' REQUEST[${options.method}] => PATH: ${options.uri}');
      log('Headers: ${options.headers}');
      log('Data: ${options.data}');
      return handler.next(options);
    },
    onResponse: (response, handler) {
      log(' RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.uri}');
      log('Data: ${response.data}');
      return handler.next(response);
    },
    onError: (DioException e, handler) {
      log(' ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.uri}');
      log('Message: ${e.message}');
      log('Error Data: ${e.response?.data}');
      return handler.next(e);
    },
  ));
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    try {
      return await _dio.get(path, queryParameters: params);
    } catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Response> post(String path, {Map<String, dynamic>? data}) async {
    try {
      return await _dio.post(path, data: data);
    } catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Response> put(String path, {Map<String, dynamic>? data}) async {
    try {
      return await _dio.put(path, data: data);
    } catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}


