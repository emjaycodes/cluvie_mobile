import '../../../core/api/api_client.dart';
import '../models/User.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<UserModel> login(String email, String password) async {
    final response = await _apiClient.get('/auth/login', params: {
      'email': email,
      'password': password,
    });
    return UserModel.fromJson(response.data);
  }
}