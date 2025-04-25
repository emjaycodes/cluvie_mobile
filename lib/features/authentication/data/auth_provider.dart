
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/User.dart';
import '../../../core/repository/auth_repository.dart';

final authProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<UserModel?> {
  final AuthRepository _repository = AuthRepository();

  AuthNotifier() : super(null);

  Future<void> login(String email, String password) async {
    state = await _repository.login(email, password);
  }
}