import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/core/router/routes_name.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_bottom_nav_bar.dart';
import 'package:cluvie_mobile/features/authentication/presentation/forgot_password_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/login_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/onboarding_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/sigup_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/splash_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/welcome_screen.dart';
import 'package:cluvie_mobile/features/clubs/presentation/club_settings.dart';
import 'package:cluvie_mobile/features/clubs/presentation/community_chat_screen.dart';
import 'package:cluvie_mobile/features/clubs/presentation/community_info_screen.dart';
import 'package:cluvie_mobile/features/clubs/presentation/community_list_screen.dart';
import 'package:cluvie_mobile/features/clubs/presentation/create_community_screen.dart';
import 'package:cluvie_mobile/features/discover/presentation/discover_screen.dart';
import 'package:cluvie_mobile/features/home/presentation/home_screen.dart';
import 'package:cluvie_mobile/features/movies/presentation/disscusion_thread.dart';
import 'package:cluvie_mobile/features/movies/presentation/movie_details_screen.dart';
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
  initialLocation: '/welcome',
  routes: [
    GoRoute(
      name: 'onboarding',
      path: '/',
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
      name: RouteNames.forgotPassword,
      path: '/forgotPassword',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    // GoRoute(
    // path: '/home', 
    // builder: (context, state) => const HomeScreen()),

    // GoRoute(
    //   path: '/discover',
    //   builder: (context, state) => const DiscoverScreen(),
    // ),

    // GoRoute(
    //   path: '/suggest',
    //   name: RouteNames.suggest,
    //   builder: (context, state) => const SuggestMovieScreen(),
    // ),

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

    // GoRoute(
    //   name: RouteNames.allCommunities,
    //   path: '/allCommunities',
    //   builder: (context, state) => CommunityListScreen(),
    // ),

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

      //  GoRoute(
      //     name: RouteNames.profile,
      //     path: '/profile',
      //     // parentNavigatorKey: _shellNavigatorKey,
      //     builder:
      //         (context, state) => const UserProfileScreen(
                
      //         ),
      //  ),
       
      

    // ShellRoute for Bottom Navigation Tabs
    ShellRoute(
      parentNavigatorKey: _rootNavigatorKey,
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ClBottomNavBar(child: child),
      routes: [
        GoRoute(
          name: RouteNames.home,
          path: '/home',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => HomeScreen(),
        ),
        GoRoute(
          name: RouteNames.discover,
          path: '/Discover',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const DiscoverScreen(),
        ),
        GoRoute(
          name: RouteNames.suggest,
          path: '/Suggest',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const SuggestMovieScreen(),
        ),
        GoRoute(
          name: RouteNames.allCommunities,
          path: '/allCommunities',
          parentNavigatorKey: _shellNavigatorKey,
          builder: (context, state) => const CommunityListScreen(),
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
