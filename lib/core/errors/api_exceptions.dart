

import 'package:dio/dio.dart';


class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? path;
  final dynamic responseBody;

  ApiException({
    required this.message,
    this.statusCode,
    this.path,
    this.responseBody,
  });

  @override
  String toString() =>
      'ApiException($statusCode) $message\n↳ $path\n↳ $responseBody';

  factory ApiException.fromDio(Object error) {
    if (error is DioException) {
      return ApiException(
        message: error.message ?? 'Unknown Dio error',
        statusCode: error.response?.statusCode,
        path: error.requestOptions.path,
        responseBody: error.response?.data,
      );
    }
    return ApiException(message: 'Unexpected non-Dio error');
  }
}

