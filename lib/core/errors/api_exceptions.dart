

import 'package:dio/dio.dart';

// class ApiException implements Exception {
//   final String message;
//   ApiException(this.message);

//   static ApiException fromDioError(dynamic error) {
//     if (error is DioException) {
//       return ApiException(error.message ?? 'Unknown API error');
//     }
//     return ApiException('Unexpected error occurred');
//   }
// }
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';

  static ApiException fromDioError(dynamic error) {
    if (error is DioException) {
      return ApiException(error.message ?? 'Unknown API error');
    }
    return ApiException('Unexpected error occurred');
  }
}
