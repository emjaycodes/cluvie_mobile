

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

  MovieState.loading()
      : movies = const [],
       selectedMovie = null,
        isLoading = true,
        error = null;

  MovieState.error(this.error)
      : movies = const [],
       selectedMovie = null,
        isLoading = false;

  MovieState.success(this.movies)
      : isLoading = false,
       selectedMovie = null,
        error = null;

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

  MovieState.detail(Movie movie)
      : movies = const [],
        selectedMovie = movie,
        isLoading = false,
        error = null;
}
