

import 'package:cluvie_mobile/core/models/movie.dart';

class MovieState {
  final List<Movie> movies;
  final bool isLoading;
  final String? error;

  MovieState({
    this.movies = const [],
    this.isLoading = false,
    this.error,
  });

  // Loading state
  MovieState.loading()
      : movies = const [],
        isLoading = true,
        error = null;

  // Error state
  MovieState.error(this.error)
      : movies = const [],
        isLoading = false;

  // Success state
  MovieState.success(this.movies)
      : isLoading = false,
        error = null;

  // Update state with new values
  MovieState copyWith({
    List<Movie>? movies,
    bool? isLoading,
    String? error,
  }) {
    return MovieState(
      movies: movies ?? this.movies,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
