import 'package:cluvie_mobile/core/utils/build_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exceptions.dart';
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
    return AuthState(user: user ?? this.user, error: error ?? this.error, isLoading: isLoading ?? this.isLoading);
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
      log('login failed: $e');
      state = AuthState.error(friendlyAuthError(e, isLogin: true));
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
      log('register failed: $e');
      state = AuthState.error(friendlyAuthError(e, isLogin: false));
      return false;
    }
  }

  /// Drop a previous error (e.g. when opening another auth screen).
  void clearError() {
    if (state.error != null) state = AuthState(user: state.user);
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState();
  }
}

/// Plain-language auth errors (tokens.md → States → Error: say what went wrong
/// and how to fix it). Raw exception details go to the log, not the screen.
String friendlyAuthError(Object error, {required bool isLogin}) {
  final status = error is ApiException ? error.statusCode : null;
  final isNetwork = error is ApiException && status == null && !error.message.startsWith('Unexpected');
  if (isNetwork) {
    return "Can't reach Cluvie right now. Check your connection and try again.";
  }
  if (isLogin && (status == 400 || status == 401 || status == 404)) {
    return 'That email and password don\'t match. Try again or reset your password.';
  }
  if (!isLogin && status == 409) {
    return 'An account with that email already exists. Log in instead.';
  }
  if (!isLogin && status == 400) {
    return 'Some details look off. Check your name, email and password.';
  }
  if (status != null && status >= 500) {
    return 'Cluvie is having trouble on our side. Try again in a moment.';
  }
  return 'Something went wrong. Try again.';
}
