// ignore_for_file: deprecated_member_use
import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/core/router/routes_name.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/authentication/presentation/forgot_password_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/login_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/reset_password_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/onboarding_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/sigup_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/splash_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/welcome_screen.dart';
import 'package:cluvie_mobile/features/clubs/presentation/club_settings.dart';
import 'package:cluvie_mobile/features/clubs/presentation/club_chat_screen.dart';
import 'package:cluvie_mobile/features/clubs/presentation/community_detail_screen.dart';
import 'package:cluvie_mobile/features/clubs/presentation/community_info_screen.dart';
import 'package:cluvie_mobile/features/clubs/presentation/community_list_screen.dart';
import 'package:cluvie_mobile/features/clubs/presentation/create_community_screen.dart';
import 'package:cluvie_mobile/features/discover/presentation/discover_screen.dart';
import 'package:cluvie_mobile/features/home/presentation/home_screen.dart';
import 'package:cluvie_mobile/features/movies/presentation/club_discussions_screen.dart';
import 'package:cluvie_mobile/features/movies/presentation/discussion_thread_screen.dart';
import 'package:cluvie_mobile/features/movies/presentation/movie_details_screen.dart';
import 'package:cluvie_mobile/features/movies/presentation/vote_summary_screen.dart';
import 'package:cluvie_mobile/features/notifications/presentation/notification_settings_screen.dart';
import 'package:cluvie_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:cluvie_mobile/features/suggest/presentation/suggestion_screen.dart';
import 'package:cluvie_mobile/features/user_profile/presentation/edit_profile_screen.dart';
import 'package:cluvie_mobile/features/user_profile/presentation/profile_screen.dart';
import 'package:cluvie_mobile/features/watch_party/presentation/watch_party_screen.dart';
import 'package:cluvie_mobile/features/watch_party/presentation/watch_party_list_screen.dart';
import 'package:cluvie_mobile/features/watch_party/presentation/watch_party_detail_screen.dart';
import 'package:cluvie_mobile/features/watch_party/presentation/watch_party_room_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The emailed reset link is `cluvie://reset-password?token=…`. In a custom
/// scheme `reset-password` is the URI's host, not its path, and platforms
/// pass it on differently (whole URI, or only `?token=…`). Every form lands
/// on `/reset-password?token=…`. Returns null for anything else.
String? resetPasswordRedirect(Uri uri) {
  final token = uri.queryParameters['token'];
  final isReset = uri.host == 'reset-password' ||
      (uri.path.isEmpty || uri.path == '/') && token != null && token.isNotEmpty;
  if (!isReset) return null;
  return Uri(path: '/reset-password', queryParameters: token == null ? null : {'token': token}).toString();
}

final _shellNavigatorKey = GlobalKey<NavigatorState>();
/// The root navigator, for app-level messages (e.g. "your session ended").
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// M1+M2: 5-tab ShellRoute that satisfies ROADMAP M1 exit criteria.
/// Tab mapping (ROUTE spec):
///  Home      -> /               (Home Feed CF-03/CF-07)
///  Discover  -> /discover       (CF-03)
///  Suggest   -> /suggest        (CF-05)
///  Communities -> /communities  (CF-04)
///  Profile   -> /profile        (CF-02)
/// Auth chain: splash (/splash) -> onboarding (/) -> welcome (/welcome) -> login/signup
final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  // ignore: unused_local_variable is intentional — guard wired for M3 hardening
  redirect: (context, state) {
    final reset = resetPasswordRedirect(state.uri);
    if (reset != null) return reset;
    // Auth guard: splash -> onboarding -> welcome -> login/signup -> Shell
    // For M1/M2 keep navigable; M3 will enforce: if (!loggedIn && !isAuthRoute) return '/welcome';
    // ignore: unused_local_variable
    final loggedIn = false; // TODO(M3): replace with token check
    // ignore: unused_local_variable
    final isAuthRoute = [
      '/splash',
      '/',
      '/welcome',
      '/login',
      '/signup',
      '/forgotPassword',
      '/reset-password',
    ].contains(state.matchedLocation);
    return null;
  },
  routes: [
    GoRoute(name: RouteNames.splash, path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      name: RouteNames.onboarding,
      path: '/onboarding-legacy',
      builder: (context, state) => const OnboardingScreen(),
    ),
    // Root is onboarding for first-install flow (splash -> onboarding -> welcome)
    GoRoute(name: 'onboardingRoot', path: '/', builder: (context, state) => const OnboardingScreen()),
    GoRoute(name: RouteNames.welcome, path: '/welcome', builder: (context, state) => const WelcomeScreen()),
    GoRoute(name: RouteNames.login, path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(name: RouteNames.signup, path: '/signup', builder: (context, state) => const SignupScreen()),
    GoRoute(
      name: RouteNames.forgotPassword,
      path: '/forgotPassword',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      name: RouteNames.resetPassword,
      path: '/reset-password',
      builder: (context, state) => ResetPasswordScreen(token: state.uri.queryParameters['token']),
    ),

    // Deep-link targets that live outside Shell (notifications -> direct)
    GoRoute(
      name: RouteNames.notifications,
      path: '/notifications',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/notifications/settings',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: '/watchParty',
      name: RouteNames.watchParty,
      parentNavigatorKey: rootNavigatorKey,
      redirect: (context, state) {
        final extra = state.extra is Map ? state.extra as Map : const {};
        final id = extra['id'];
        // The party page applies `canEnterRoom`; going straight to the live
        // room let cancelled, ended or too-early parties connect (R11-N5).
        return id is String && id.isNotEmpty ? '/watch-parties/$id' : null;
      },
      builder: (context, state) => const WatchPartyScreen(),
    ),
    GoRoute(
      path: '/watch-parties',
      name: RouteNames.watchPartyList,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const WatchPartyListScreen(),
    ),
    GoRoute(
      path: '/watch-parties/:id',
      name: RouteNames.watchPartyDetail,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => WatchPartyDetailScreen(partyId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/watch-parties/:id/live',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => WatchPartyRoomScreen(partyId: state.pathParameters['id']!),
    ),
    // Backend notification links (`/watchparty/:id`).
    GoRoute(path: '/watchparty/:id', redirect: (context, state) => '/watch-parties/${state.pathParameters['id']}'),
    GoRoute(
      name: RouteNames.movieDetails,
      path: '/movie/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return MovieDetailScreen(movieId: id);
      },
    ),
    // Legacy camelCase aliases (keep for backward compat)
    GoRoute(
      name: 'movieDetailsLegacy',
      path: '/MovieDetails',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const MovieDetailScreen(),
    ),
    GoRoute(
      name: RouteNames.movieSearch,
      path: '/search',
      // Film search lives in Discover (debounced, via the backend's TMDB
      // proxy). The old standalone screen is gone.
      redirect: (context, state) => '/discover',
    ),
    GoRoute(
      name: 'movieSearchLegacy',
      path: '/MovieSearch',
      redirect: (context, state) => '/discover',
    ),
    GoRoute(
      name: RouteNames.createCommunity,
      path: '/createCommunity',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const CreateCommunityScreen(),
    ),
    GoRoute(
      name: RouteNames.discussionThread,
      path: '/discussionThread',
      parentNavigatorKey: rootNavigatorKey,
      // Film context in `extra`: DiscussionThreadScreen.extraFor(...).
      builder: (context, state) => DiscussionThreadScreen.fromExtra(state.extra),
    ),
    GoRoute(
      name: RouteNames.communityChat,
      path: '/communityChat',
      parentNavigatorKey: rootNavigatorKey,
      // Legacy: takes `extra: Community`. Prefer /communities/:id/chat.
      redirect: (context, state) {
        final id = state.extra is Community ? (state.extra as Community).id : null;
        return id == null ? null : '/communities/$id/chat';
      },
      builder: (context, state) => const _MissingExtraScreen(title: 'Club chat'),
    ),
    GoRoute(
      name: RouteNames.communityInfo,
      path: '/communityInfo',
      parentNavigatorKey: rootNavigatorKey,
      // Legacy: takes `extra: Community`. Prefer /communities/:id/about.
      builder: (context, state) {
        final id = state.extra is Community ? (state.extra as Community).id : null;
        if (id == null) return const _MissingExtraScreen(title: 'About');
        return CommunityInfoScreen(communityId: id);
      },
    ),
    GoRoute(
      name: RouteNames.communitySettings,
      path: '/communitySettings',
      parentNavigatorKey: rootNavigatorKey,
      // Legacy: takes `extra: Community`. Prefer /communities/:id/settings.
      builder: (context, state) {
        final id = state.extra is Community ? (state.extra as Community).id : null;
        if (id == null) return const _MissingExtraScreen(title: 'Membership');
        return ClubSettingsScreen(communityId: id);
      },
    ),

    // ── 5-tab ShellRoute ────────────────────────────────────────────
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      parentNavigatorKey: rootNavigatorKey,
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
          // Was a second copy inside the shell that lit up the Home tab
          // (audit P1-1); there is one Notifications screen.
          redirect: (context, state) => '/notifications',
        ),
      ],
    ),

    // Community-scoped subroutes (all deep-linkable, outside shell for full-screen)
    GoRoute(
      name: RouteNames.communityDetail,
      path: '/communities/:id',
      parentNavigatorKey: rootNavigatorKey,
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
            return SuggestMovieScreen(communityId: id);
          },
        ),
        GoRoute(
          name: RouteNames.voting,
          path: 'vote',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            // Optional: {'club': String}, the club name for the title.
            final extra = state.extra is Map ? state.extra as Map : const {};
            return VoteSummaryScreen(
              communityId: id,
              clubName: extra['club'] is String ? extra['club'] as String : null,
            );
          },
        ),
        GoRoute(
          name: RouteNames.communityAbout,
          path: 'about',
          builder: (context, state) => CommunityInfoScreen(communityId: state.pathParameters['id']!),
        ),
        GoRoute(
          name: RouteNames.communityMembership,
          path: 'settings',
          builder: (context, state) => ClubSettingsScreen(communityId: state.pathParameters['id']!),
        ),
        GoRoute(
          name: RouteNames.clubChat,
          path: 'chat',
          builder: (context, state) => ClubChatScreen(communityId: state.pathParameters['id']!),
        ),
        GoRoute(
          name: RouteNames.discussion,
          path: 'discussion',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ClubDiscussionsScreen(communityId: id);
          },
        ),
      ],
    ),
    // User profile deep link
    GoRoute(
      name: RouteNames.userProfile,
      path: '/users/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return UserProfileScreen(userId: id);
      },
    ),
    // Edit your own profile: full-screen, above the tab shell, so the
    // keyboard never fights the floating nav.
    GoRoute(
      name: RouteNames.editProfile,
      path: '/profile/edit',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const EditProfileScreen(),
    ),
  ],
);

class _MissingExtraScreen extends StatelessWidget {
  final String title;
  const _MissingExtraScreen({required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ClAppBar(title: title, fallbackRoute: '/communities'),
      body: const ClEmptyState(
        title: "Couldn't open this page",
        message: 'Go back and try again.',
      ),
    );
  }
}
