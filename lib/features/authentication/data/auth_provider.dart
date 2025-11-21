
import 'package:cluvie_mobile/core/utils/build_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user.dart';
import '../../../core/repository/auth_repository.dart';

// Define a provider for AuthNotifier
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// a State class that tracks the different states of Auth
class AuthState {
  final UserModel? user;
  final String? error;
  final bool isLoading;

  AuthState({this.user, this.error, this.isLoading = false});

  // Loading state
  AuthState.loading() : user = null, error = null, isLoading = true;

  // Error state
  AuthState.error(String this.error) : user = null, isLoading = false;

  // Success state
  AuthState.success(UserModel this.user) : error = null, isLoading = false;

  // Helper method for cloning the object with different values
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

  AuthNotifier() : super(AuthState()); // initial state is an empty AuthState

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true); // Update state to loading
    try {
      final user = await _repository.login(email, password);
      log("usreeeeeeeee $user");
      state = AuthState.success(user); // Update state to success
      return true;
    } catch (e) {
      state = AuthState.error("Login failed: ${e.toString()}"); // Update state to error
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    state = state.copyWith(isLoading: true); // Update state to loading
    try {
      final user = await _repository.register(username, email, password);
      state = AuthState.success(user); // Update state to success
      return true;
    } catch (e) {
      state = AuthState.error("Registration failed: ${e.toString()}"); // Update state to error
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState(); // Reset the state after logout
  }
}