
import 'package:dio/dio.dart';

import '../errors/api_exceptions.dart';

class ApiClient {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://api.cluvie.com'));

  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    try {
      return await _dio.get(path, queryParameters: params);
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}