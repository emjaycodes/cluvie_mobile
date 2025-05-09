import 'package:cluvie_mobile/core/models/movie.dart';
import 'package:cluvie_mobile/core/router/routes_name.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_bottom_nav_bar.dart';
import 'package:cluvie_mobile/features/authentication/presentation/login_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/onboarding_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/sigup_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/splash_screen.dart';
import 'package:cluvie_mobile/features/communities/presentation/community_chat_screen.dart';
import 'package:cluvie_mobile/features/communities/presentation/community_info_screen.dart';
import 'package:cluvie_mobile/features/communities/presentation/community_list_screen.dart';
import 'package:cluvie_mobile/features/communities/presentation/create_community_screen.dart';
import 'package:cluvie_mobile/features/communities/presentation/joined_community_screen.dart';
import 'package:cluvie_mobile/features/movies/presentation/discussion_list_screen.dart';
import 'package:cluvie_mobile/features/movies/presentation/movie_details_screen.dart';
import 'package:cluvie_mobile/features/movies/presentation/movie_list_screen.dart';
import 'package:cluvie_mobile/features/movies/presentation/movie_search_screen.dart';
import 'package:cluvie_mobile/features/user_profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();



final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/movies',
  routes: [
    GoRoute(
      path: '/',
      name: 'onboarding',
      builder: (context, state) => OnboardingScreen(),
    ),
    GoRoute(
      name: RouteNames.splash,
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
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
      name: RouteNames.movieDetails,
      path: '/MovieDetails',
      builder: (context, state) {
        final movie = state.extra as Movie;
        return MovieDetailScreen(movie: movie);
      },
    ),

    GoRoute(
      name: RouteNames.movieSearch,
      path: '/MovieSearch',
      builder: (context, state) => MovieSearchScreen(),
    ),

    GoRoute(
      name: RouteNames.createCommunity,
      path: '/createCommunity',
      builder: (context, state) => CreateCommunityScreen(),
    ),

    GoRoute(
      name: RouteNames.allCommunities,
      path: '/allCommunities',
      builder: (context, state) => CommunityListScreen(),
    ),

    GoRoute(
      name: RouteNames.communityChat,
      path: '/communityChat',
      builder: (context, state) => CommunityChatScreen(),
    ),

GoRoute(
  name: RouteNames.communityInfo,
  path: '/communityInfo',
  builder: (context, state) { 
    final Community community = Community(
      name: "Sci-Fi",
      description: "A community for lovers of sci-fi classics and futuristic cinema. Share, discuss, and vote on what to watch next!",
      imageUrl: 'assets/images/dis.png',
      membersCount: 2560,
      postsCount: 732,
      createdAt: DateTime(2023, 6, 12),
      isUserMember: true,
      category: "Movies • Sci-Fi",
    );

    // Optional: Only use `state.extra` if needed
    // final movie = state.extra as Movie;

    return CommunityInfoScreen(community: community);
  },
),


    // ShellRoute for Bottom Navigation Tabs
    ShellRoute(
      parentNavigatorKey: _rootNavigatorKey,
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ClBottomNavBar(child: child),
      routes: [
        GoRoute(
          name: RouteNames.movies,
          path: '/movies',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => MovieListScreen(),
        ),
        GoRoute(
          name: RouteNames.joinedCommunities,
          path: '/communities',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const JoinedCommunitiesScreen(),
        ),
        GoRoute(
          name: RouteNames.discussions,
          path: '/discussions',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const DiscussionListScreen(),
        ),
        GoRoute(
          name: RouteNames.profile,
          path: '/profile',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
