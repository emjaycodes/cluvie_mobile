// ignore_for_file: deprecated_member_use
import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/core/router/routes_name.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_bottom_nav_bar.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_empty_state.dart';
import 'package:cluvie_mobile/features/authentication/presentation/forgot_password_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/login_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/onboarding_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/sigup_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/splash_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/welcome_screen.dart';
import 'package:cluvie_mobile/features/clubs/presentation/club_settings.dart';
import 'package:cluvie_mobile/features/clubs/presentation/community_chat_screen.dart';
import 'package:cluvie_mobile/features/clubs/presentation/community_detail_screen.dart';
import 'package:cluvie_mobile/features/clubs/presentation/community_info_screen.dart';
import 'package:cluvie_mobile/features/clubs/presentation/community_list_screen.dart';
import 'package:cluvie_mobile/features/clubs/presentation/create_community_screen.dart';
import 'package:cluvie_mobile/features/discover/presentation/discover_screen.dart';
import 'package:cluvie_mobile/features/home/presentation/home_screen.dart';
import 'package:cluvie_mobile/features/movies/presentation/disscusion_thread.dart';
import 'package:cluvie_mobile/features/movies/presentation/movie_details_screen.dart';
import 'package:cluvie_mobile/features/movies/presentation/movie_search_screen.dart';
import 'package:cluvie_mobile/features/movies/presentation/vote_summary_screen.dart';
import 'package:cluvie_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:cluvie_mobile/features/suggest/presentation/suggestion_screen.dart';
import 'package:cluvie_mobile/features/user_profile/presentation/profile_screen.dart';
import 'package:cluvie_mobile/features/watch_party/presentation/watch_party_screen.dart';
import 'package:cluvie_mobile/features/watch_party/presentation/watch_party_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// M1+M2: 5-tab ShellRoute that satisfies ROADMAP M1 exit criteria.
/// Tab mapping (ROUTE spec):
///  Home      -> /               (Home Feed CF-03/CF-07)
///  Discover  -> /discover       (CF-03)
///  Suggest   -> /suggest        (CF-05)
///  Communities -> /communities  (CF-04)
///  Profile   -> /profile        (CF-02)
/// Auth chain: splash (/splash) -> onboarding (/) -> welcome (/welcome) -> login/signup
final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  // ignore: unused_local_variable is intentional — guard wired for M3 hardening
  redirect: (context, state) {
    // Auth guard: splash -> onboarding -> welcome -> login/signup -> Shell
    // For M1/M2 keep navigable; M3 will enforce: if (!loggedIn && !isAuthRoute) return '/welcome';
    // ignore: unused_local_variable
    final loggedIn = false; // TODO(M3): replace with token check
    // ignore: unused_local_variable
    final isAuthRoute = ['/splash', '/', '/welcome', '/login', '/signup', '/forgotPassword'].contains(state.matchedLocation);
    return null;
  },
  routes: [
    GoRoute(
      name: RouteNames.splash,
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      name: RouteNames.onboarding,
      path: '/onboarding-legacy',
      builder: (context, state) => const OnboardingScreen(),
    ),
    // Root is onboarding for first-install flow (splash -> onboarding -> welcome)
    GoRoute(
      name: 'onboardingRoot',
      path: '/',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      name: RouteNames.welcome,
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      name: RouteNames.login,
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      name: RouteNames.signup,
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      name: RouteNames.forgotPassword,
      path: '/forgotPassword',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),

    // Deep-link targets that live outside Shell (notifications -> direct)
    GoRoute(
      name: RouteNames.notifications,
      path: '/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/watchParty',
      name: RouteNames.watchParty,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const WatchPartyScreen(),
    ),
    GoRoute(
      path: '/watch-parties',
      name: RouteNames.watchPartyList,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const WatchPartyListScreen(),
    ),
    GoRoute(
      name: RouteNames.movieDetails,
      path: '/movie/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return MovieDetailScreen(movieId: id);
      },
    ),
    // Legacy camelCase aliases (keep for backward compat)
    GoRoute(
      name: 'movieDetailsLegacy',
      path: '/MovieDetails',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MovieDetailScreen(),
    ),
    GoRoute(
      name: RouteNames.movieSearch,
      path: '/search',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MovieSearchScreen(),
    ),
    GoRoute(
      name: 'movieSearchLegacy',
      path: '/MovieSearch',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MovieSearchScreen(),
    ),
    GoRoute(
      name: RouteNames.createCommunity,
      path: '/createCommunity',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreateCommunityScreen(),
    ),
    GoRoute(
      name: RouteNames.discussionThread,
      path: '/discussionThread',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DiscussionThreadScreen(),
    ),
    GoRoute(
      name: RouteNames.communityChat,
      path: '/communityChat',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final community = state.extra as Community?;
        if (community == null) {
          return const _MissingExtraScreen(hint: 'CommunityChat');
        }
        return CommunityChatScreen(community: community);
      },
    ),
    GoRoute(
      name: RouteNames.communityInfo,
      path: '/communityInfo',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final community = state.extra as Community?;
        if (community == null) return const _MissingExtraScreen(hint: 'CommunityInfo');
        return CommunityInfoScreen(community: community);
      },
    ),
    GoRoute(
      name: RouteNames.communitySettings,
      path: '/communitySettings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ClubSettingsScreen(),
    ),

    // ── 5-tab ShellRoute ────────────────────────────────────────────
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state, child) => ClBottomNavBar(child: child),
      routes: [
        // Home Feed — CF-03/CF-07 — route "/"  (also accessible via /home alias)
        GoRoute(
          name: RouteNames.home,
          path: '/home',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const HomeScreen(),
        ),
        // Discover — CF-03
        GoRoute(
          name: RouteNames.discover,
          path: '/discover',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const DiscoverScreen(),
        ),
        // Legacy Discover caps alias
        GoRoute(
          name: 'discoverLegacy',
          path: '/Discover',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const DiscoverScreen(),
        ),
        // Suggest — CF-05
        GoRoute(
          name: RouteNames.suggest,
          path: '/suggest',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const SuggestMovieScreen(),
        ),
        GoRoute(
          name: 'suggestLegacy',
          path: '/Suggest',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const SuggestMovieScreen(),
        ),
        // Communities List — CF-04
        GoRoute(
          name: RouteNames.communities,
          path: '/communities',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const CommunityListScreen(),
        ),
        GoRoute(
          name: RouteNames.allCommunities,
          path: '/allCommunities',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const CommunityListScreen(),
        ),
        // Profile — CF-02
        GoRoute(
          name: RouteNames.profile,
          path: '/profile',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const UserProfileScreen(),
        ),
        // Notifications inside shell as fallback (also top-level /notifications)
        GoRoute(
          name: 'notificationsShell',
          path: '/notifications-shell',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const NotificationsScreen(),
        ),
      ],
    ),

    // Community-scoped subroutes (all deep-linkable, outside shell for full-screen)
    GoRoute(
      name: RouteNames.communityDetail,
      path: '/communities/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return CommunityDetailScreen(communityId: id);
      },
      routes: [
        GoRoute(
          name: RouteNames.suggestMovie,
          path: 'suggest',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return SuggestMovieDeepScreen(communityId: id);
          },
        ),
        GoRoute(
          name: RouteNames.voting,
          path: 'vote',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return VoteSummaryScreen(communityId: id);
          },
        ),
        GoRoute(
          name: RouteNames.discussion,
          path: 'discussion',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return DiscussionThreadScreen(communityId: id);
          },
        ),
      ],
    ),
    // User profile deep link
    GoRoute(
      name: RouteNames.userProfile,
      path: '/users/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return UserProfileScreen(userId: id);
      },
    ),
  ],
);

class _MissingExtraScreen extends StatelessWidget {
  final String hint;
  const _MissingExtraScreen({required this.hint});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(hint)),
      body: const ClEmptyState(message: 'CL* — Missing navigation data. Go back and try again.'),
    );
  }
}

/// Stub for deep-linked suggest when opened via /communities/:id/suggest
class SuggestMovieDeepScreen extends StatelessWidget {
  final String communityId;
  const SuggestMovieDeepScreen({super.key, required this.communityId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suggest Movie')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClEmptyState(message: 'Suggest to community $communityId — search TMDB above.'),
            const SizedBox(height: 16),
            const SuggestMovieScreen(),
          ],
        ),
      ),
    );
  }
}
