import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes_name.dart';
import '../../clubs/data/comunity_provider.dart';
import '../../movies/data/comment_provider.dart';
import '../../movies/data/movie_provider.dart';
import 'auth_provider.dart';

/// Ends the session everywhere: clears the stored token and auth header,
/// resets the auth state and drops every user-scoped cache so the next
/// person to log in on this device never sees the previous user's data.
Future<void> signOut(BuildContext context, WidgetRef ref) async {
  await ref.read(authNotifierProvider.notifier).logout();
  ref
    ..invalidate(joinedCommunitiesProvider)
    ..invalidate(allCommunitiesProvider)
    ..invalidate(movieNotifierProvider)
    ..invalidate(movieCommentsProvider);
  if (context.mounted) context.goNamed(RouteNames.welcome);
}
