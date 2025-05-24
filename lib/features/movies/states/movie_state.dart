

import 'package:cluvie_mobile/core/models/movie.dart';

class MovieState {
  final List<Movie> movies;
  final Movie? selectedMovie;
  final bool isLoading;
  final String? error;

  MovieState({
    this.movies = const [],
    this.selectedMovie,
    this.isLoading = false,
    this.error,
  });

  // Loading state
  MovieState.loading()
      : movies = const [],
       selectedMovie = null,
        isLoading = true,
        error = null;

  // Error state
  MovieState.error(this.error)
      : movies = const [],
       selectedMovie = null,
        isLoading = false;

  // Success state
  MovieState.success(this.movies)
      : isLoading = false,
       selectedMovie = null,
        error = null;

  // Update state with new values
  MovieState copyWith({
    List<Movie>? movies,
    Movie? selectedMovie,
    bool? isLoading,
    String? error,
  }) {
    return MovieState(
      movies: movies ?? this.movies,
      selectedMovie: selectedMovie ?? this.selectedMovie,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

    // Success state (movie detail only)
  MovieState.detail(Movie movie)
      : movies = const [],
        selectedMovie = movie,
        isLoading = false,
        error = null;
}
