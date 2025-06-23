import 'package:cluvie_mobile/core/models/discussion_comments.dart';
import 'package:dio/dio.dart';

class CommentRepository {
  final Dio _dio;

  CommentRepository({Dio? dio}) : _dio = dio ?? Dio();

  /// Fetch all comments for a discussion
  Future<List<DiscussionComment>> fetchComments(String discussionId) async {
    try {
      final response = await _dio.get(
        'https://api.example.com/comments/discussion/$discussionId',
      );

      return (response.data as List)
          .map((json) => DiscussionComment.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new comment for a discussion
  Future<DiscussionComment> createComment(DiscussionComment comment) async {
    try {
      final response = await _dio.post(
        'https://api.example.com/comments',
        data: comment.toJson(),
      );

      return DiscussionComment.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a comment by ID (admin or owner)
  Future<void> deleteComment(String commentId) async {
    try {
      await _dio.delete('https://api.example.com/comments/$commentId');
    } catch (e) {
      rethrow;
    }
  }
}
