import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/repository/movie_repository.dart';
import 'package:cluvie_mobile/core/utils/build_config.dart';
import 'package:cluvie_mobile/features/movies/states/movie_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final movieNotifierProvider =
    StateNotifierProvider<MovieNotifier, MovieState>((ref) {
       final api = ref.read(apiClientProvider);
  final MovieRepository movieRepository = MovieRepository(apiClient: api);
  return MovieNotifier(movieRepository);
});

class MovieNotifier extends StateNotifier<MovieState> {
  final MovieRepository movieRepository;

  MovieNotifier(this.movieRepository) : super(MovieState.loading()) {
    fetchMovies();
  }

  Future<void> fetchMovies() async {
    try {
      final movies = await movieRepository.fetchAllMovies();
      state = MovieState.success(movies);
      log('Fetched movies: ${movies.length}');
    } catch (e) {
      state = MovieState.error(e.toString());
    }
  }

Future<void> fetchMovieDetails(String movieId) async {
  try {
    state = state.copyWith(isLoading: true, error: null);
    final movie = await movieRepository.fetchMovieDetails(movieId);
    state = state.copyWith(selectedMovie: movie, isLoading: false);
  } catch (e) {
    state = state.copyWith(error: e.toString(), isLoading: false);
  }
}

}
