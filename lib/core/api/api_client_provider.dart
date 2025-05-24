import 'package:cluvie_mobile/core/api/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(); // Singleton instance of ApiClient
});
