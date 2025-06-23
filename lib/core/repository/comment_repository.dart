import 'package:cluvie_mobile/core/api/api_client.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/core/models/movie_comment.dart';

class CommentRepository {
  final ApiClient _apiClient;
  CommentRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // Fetch all comments for a movie
  Future<List<MovieComment>> fetchMovieComments(String movieId) async {
    try {
      final response = await _apiClient.get('/movies/$movieId/comments');
      if (response.statusCode == 201) {
        final data = response.data as List;
        return data.map((json) => MovieComment.fromJson(json)).toList();
      } else {
        throw ApiException(
          message: response.statusMessage!,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Error fetching comments: $e');
      rethrow;
    }
  }

  // Create a new comment for a movie
  Future<MovieComment> createMovieComment(String movieId, String text) async {
    try {
      final response = await _apiClient.post(
        '/movies/$movieId/comments',
        data: {'text': text},
      );
      if (response.statusCode == 201) {
        return MovieComment.fromJson(response.data);
      } else {
        throw ApiException(
          message: response.statusMessage!,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Error creating comment: $e');
      rethrow;
    }
  }


  // Delete a comment by ID (admin or owner)
  Future<void> deleteMovieComment(String commentId) async {
    try {
      final response = await _apiClient.delete('/comments/$commentId');
      if (response.statusCode != 204) {
        throw ApiException(
          message: response.statusMessage!,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Error deleting comment: $e');
      rethrow;
    }
  }
}
