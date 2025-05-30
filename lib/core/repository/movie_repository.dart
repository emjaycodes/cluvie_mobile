import 'package:cluvie_mobile/core/api/api_client.dart';
import 'package:cluvie_mobile/core/models/movie.dart';
import 'package:dio/dio.dart';

// class MovieRepository {
//  final _dio = Dio(
//   BaseOptions(
//     baseUrl: 'https://api.themoviedb.org/3',
//     headers: {
//       'accept': 'application/json',
//       'Authorization': 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIxZWQ0MTkzZWFlYzNmMWE5YjdjNzRjZTk4NGUyMGI2NiIsIm5iZiI6MS43NDEzMTA5MzY3MTI5OTk4ZSs5LCJzdWIiOiI2N2NhNGJkODc0NzlkOGM4NDkyYjNiYjIiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0.9nldDyT56nlJrj6oKCkz7leRsgQP7bd_pOqTXXeJrV4',
//     },
//   ),
// );

//   Future<List<Movie>> fetchPopularMovies() async {
//     final response = await _dio.get(
//       'https://api.themoviedb.org/3/discover/movie',
//       queryParameters: {
//         // 'api_key': apiKey,
//         'sort_by': 'popularity.desc',
//         'language': 'en-US',
//         'include_adult': false,
//         'include_video': false,
//         'page': 1,
//       },
//     );

//     final results = response.data['results'] as List;
//     return results.map((e) => Movie.fromJson(e)).toList();
//   }

//   Future<List<Movie>> fetchTrendingMovies({String timeWindow = 'day'}) async {
//   final response = await _dio.get(
//     'https://api.themoviedb.org/3/trending/movie/$timeWindow',
//     queryParameters: {
//       // 'api_key': apiKey, // if not already added via an interceptor
//       'language': 'en-US',
//     },
//   );

//   final results = response.data['results'] as List;
//   return results.map((e) => Movie.fromJson(e)).toList();
// }

// // final trendingToday = await fetchTrendingMovies(); // defaults to 'day'
// // final trendingThisWeek = await fetchTrendingMovies(timeWindow: 'week');


//    Future<Map<int, String>> getGenres() async {
//     final response = await _dio.get(
//       'https://api.themoviedb.org/3/genre/movie/list',
//       queryParameters: {
//         'api_key': '1ed4193eaec3f1a9b7c74ce984e20b66',
//         'language': 'en-US', 
//       },
//     );

//    final genresMap = <int, String>{};
//     for (var genre in response.data['genres']) {
//       genresMap[genre['id']] = genre['name'];
//     }
//     return genresMap;
//   }
// }


// import 'package:dio/dio.dart';
// import 'movie_model.dart';

class MovieRepository {
  final ApiClient apiClient;
  MovieRepository({required this.apiClient});

  // Refresh movies from TMDB trending endpoint
  Future<int> refreshMovies() async {
    try{
    final response = await apiClient.get('/movies/refresh');
        return response.data['count'] as int;
    } catch (e){
        print('Error fetching communities: $e');
        rethrow;
    }
   
  }

  // Get all movies, sorted by votes desc
  Future<List<Movie>> fetchAllMovies() async {
    try{
        final response = await apiClient.get('/movies/list');
    return (response.data as List).map((json) => Movie.fromJson(json)).toList();
    }catch (e) {
      print('Error fetching all movies: ${e.toString()}');
      rethrow;
    }
  }

  // Get trending movies by engagement score for last week, limit 10
  Future<List<Movie>> fetchTrendingByEngagement() async {
    try{
      final response = await apiClient.get('/movies/trending-engagement');
    return (response.data as List).map((json) => Movie.fromJson(json)).toList();
    }catch (e) {
      print('Error fetching trending movies by engagement: $e');
      rethrow;
    }
    
  }

  // Get movie details by id
  Future<Movie> fetchMovieDetails(String id) async {
    try{
      final response = await apiClient.get('/movies/$id');
    return Movie.fromJson(response.data);
    }catch (e) {
      print('Error fetching movie details: $e');
      rethrow;
    }
    
  }

  // Delete movie by id (admin only)
  Future<void> deleteMovie(String id) async {
    try{
      await apiClient.delete('/movies/$id');
    }catch (e) {
      print('Error deleting movie: $e');
      rethrow;
    }
    
  }

  // Vote for a movie (authenticated user)
  Future<int> voteMovie(String id) async {
    try{
      final response = await apiClient.post('/movies/$id/vote');
    return response.data['votes'] as int;}catch (e) {
      print('Error voting for movie: $e');
      rethrow;
    }
    
  }

  // Remove vote from a movie (authenticated user)
  Future<int> downvoteMovie(String id) async {
    try{
      final response = await apiClient.post('/movies/$id/downvote');
    return response.data['votes'] as int;}catch (e) {
      print('Error downvoting movie: $e');
      rethrow;
    }
    
  }
}
