
import 'package:cluvie_mobile/core/utils/build_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user.dart';
import '../../../core/repository/auth_repository.dart';

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final UserModel? user;
  final String? error;
  final bool isLoading;

  AuthState({this.user, this.error, this.isLoading = false});

  AuthState.loading() : user = null, error = null, isLoading = true;

  AuthState.error(String this.error) : user = null, isLoading = false;

  AuthState.success(UserModel this.user) : error = null, isLoading = false;

  AuthState copyWith({UserModel? user, String? error, bool? isLoading}) {
    return AuthState(
      user: user ?? this.user,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}



class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository = AuthRepository();

  AuthNotifier() : super(AuthState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true); 
    try {
      final user = await _repository.login(email, password);
      log("usreeeeeeeee $user");
      state = AuthState.success(user);
      return true;
    } catch (e) {
      state = AuthState.error("Login failed: ${e.toString()}");
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    state = state.copyWith(isLoading: true); 
    try {
      final user = await _repository.register(username, email, password);
      state = AuthState.success(user); 
      return true;
    } catch (e) {
      state = AuthState.error("Registration failed: ${e.toString()}"); 
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState();
  }
}