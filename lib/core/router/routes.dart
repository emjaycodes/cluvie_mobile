import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/core/models/movie.dart';
import 'package:cluvie_mobile/core/router/routes_name.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_bottom_nav_bar.dart';
import 'package:cluvie_mobile/features/authentication/presentation/login_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/onboarding_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/sigup_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/splash_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/welcome_screen.dart';
import 'package:cluvie_mobile/features/communities/presentation/club_settings.dart';
import 'package:cluvie_mobile/features/communities/presentation/community_chat_screen.dart';
import 'package:cluvie_mobile/features/communities/presentation/community_info_screen.dart';
import 'package:cluvie_mobile/features/communities/presentation/community_list_screen.dart';
import 'package:cluvie_mobile/features/communities/presentation/create_community_screen.dart';
import 'package:cluvie_mobile/features/communities/presentation/joined_community_screen.dart';
import 'package:cluvie_mobile/features/discover/presentation/discover_screen.dart';
import 'package:cluvie_mobile/features/home/presentation/home_screen.dart';
import 'package:cluvie_mobile/features/movies/presentation/discussion_list_screen.dart';
import 'package:cluvie_mobile/features/movies/presentation/disscusion_thread.dart';
import 'package:cluvie_mobile/features/movies/presentation/movie_details_screen.dart';
import 'package:cluvie_mobile/features/movies/presentation/movie_list_screen.dart';
import 'package:cluvie_mobile/features/movies/presentation/movie_search_screen.dart';
import 'package:cluvie_mobile/features/suggest/presentation/suggestion_screen.dart';
import 'package:cluvie_mobile/features/user_profile/presentation/profile_screen.dart';
import 'package:cluvie_mobile/features/watch_party/presentation/watch_party_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/communitySettings',
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
    path: '/home', 
    builder: (context, state) => const HomeScreen()),

    GoRoute(
      path: '/discover',
      builder: (context, state) => const DiscoverScreen(),
    ),

    GoRoute(
      path: '/suggest',
      name: RouteNames.suggest,
      builder: (context, state) => const SuggestMovieScreen(),
    ),

    // GoRoute(
    //   path: '/Profile',
    //   name: RouteNames.profile,
    //   builder: (context, state) => const ProfileScreen(username: "Justice", email: "jay@gmail.com", joinedCommunities: 5, totalPosts: 15,),
    // ),
    
     GoRoute(
      path: '/watchParty',
      name: RouteNames.watchParty,
      builder: (context, state) => const WatchPartyScreen(),
    ),
      
    GoRoute(
      name: RouteNames.movieDetails,
      path: '/MovieDetails',
      builder: (context, state) {
        // final movie = state.extra as Movie;
        return MovieDetailScreen();
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
      name: RouteNames.discussionThread,
      path: '/discussionThread',
      builder: (context, state) => DiscussionThreadScreen(),
    ),

    GoRoute(
      name: RouteNames.communityChat,
      path: '/communityChat',
      builder: (context, state) {
        final community = state.extra as Community;
        return CommunityChatScreen(community: community);
      },
    ),

    GoRoute(
      name: RouteNames.communityInfo,
      path: '/communityInfo',
      builder: (context, state) {
        final community = state.extra as Community;
        return CommunityInfoScreen(community: community);
      }

    
    ),

      GoRoute(
      name: RouteNames.communitySettings, 
      path: '/communitySettings',
      builder: (context, state) { 
        return ClubSettingsScreen();
      }
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
          builder:
              (context, state) => const UserProfileScreen(
                
              ),
        ),
      ],
    ),
  ],
);
