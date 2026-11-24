import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/repository/auth_repository.dart';

/// Where the app should land after the splash screen.
enum LaunchDestination { onboarding, welcome, home }

/// First-run + session gate (decided with the product owner, 2026-11-24):
/// saved session → home; onboarding already seen → welcome; else onboarding.
class LaunchState {
  LaunchState({AuthRepository? repository}) : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;

  static const _onboardingSeenKey = 'onboarding_seen';
  static const _genresKey = 'favorite_genres';

  Future<LaunchDestination> resolve() async {
    if (await _repository.restoreSession()) return LaunchDestination.home;
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getBool(_onboardingSeenKey) ?? false) ? LaunchDestination.welcome : LaunchDestination.onboarding;
  }

  static Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }

  /// Genres picked during onboarding; used to tune Discover.
  static Future<void> saveFavoriteGenres(Set<String> genres) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_genresKey, genres.toList());
  }

  static Future<Set<String>> favoriteGenres() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_genresKey) ?? const []).toSet();
  }
}
