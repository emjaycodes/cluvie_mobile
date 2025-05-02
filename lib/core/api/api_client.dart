
import 'package:dio/dio.dart';

import '../errors/api_exceptions.dart';

class ApiClient {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://api.cluvie.com'));

  Future<Response> post(String path, {Map<String, dynamic>? data}) async {
    try {
      return await _dio.post(path, data: data);
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    try {
      return await _dio.get(path, queryParameters: params);
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}
