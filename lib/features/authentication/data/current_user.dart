import 'package:cluvie_mobile/core/repository/auth_repository.dart';
import 'package:cluvie_mobile/features/authentication/data/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in user's id, or null when signed out.
///
/// After a login it comes from the user the API returned; after a cold start
/// (session restored from the saved token) it's read from the token. Screens
/// use it to show "your vote" and "you liked this".
final currentUserIdProvider = FutureProvider<String?>((ref) async {
  final fromLogin = ref.watch(authNotifierProvider.select((s) => s.user?.id));
  if (fromLogin != null && fromLogin.isNotEmpty) return fromLogin;
  return AuthRepository().savedUserId();
});
