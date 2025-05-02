import 'package:cluvie_mobile/core/models/movie.dart';
import 'package:cluvie_mobile/core/repository/movie_repository.dart';
import 'package:cluvie_mobile/features/movies/states/movie_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final movieNotifierProvider =
    StateNotifierProvider<MovieNotifier, MovieState>((ref) {
  final MovieRepository movieRepository = MovieRepository();
  return MovieNotifier(movieRepository);
});

class MovieNotifier extends StateNotifier<MovieState> {
  final MovieRepository movieRepository;

  MovieNotifier(this.movieRepository) : super(MovieState.loading()) {
    fetchPopularMovies();
  }

  Future<void> fetchPopularMovies() async {
    try {
      state = MovieState.loading();
      final movies = await movieRepository.fetchPopularMovies();
  
      final genresMap = await movieRepository.getGenres();

      // Add genre names to each movie
      for (var movie in movies) {
        movie.genreNames =
            movie.genreIds.map((id) => genresMap[id] ?? 'Unknown').toList();
      }
      state = MovieState.success(movies);
      print('Movies fetched successfully: ${movies.length} movies');
      print('Genres fetched successfully: ${genresMap.length} genres');
    } catch (e) {
      print('Error fetching movies: $e');
      state = MovieState.error(e.toString());
      

    }
  }

  void addMovie(Movie movie) {
    state = state.copyWith(movies: [...state.movies, movie]);
  }

  void removeMovie(int movieId) {
    final updated = state.movies.where((m) => m.id != movieId).toList();
    state = state.copyWith(movies: updated);
  }
}
