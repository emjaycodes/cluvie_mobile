
import 'package:cluvie_mobile/core/utils/build_config.dart';
import 'package:dio/dio.dart';

import '../errors/api_exceptions.dart';


class ApiClient {
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  late final Dio _dio;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'http://192.168.1.55:5000/api',
      connectTimeout: const Duration(days: 1),
      // receiveTimeout: const Duration(seconds: 10),
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


