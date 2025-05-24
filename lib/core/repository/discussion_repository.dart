import 'package:cluvie_mobile/core/models/discussion.dart';
import 'package:cluvie_mobile/core/models/discussion_comments.dart';
import 'package:dio/dio.dart';

class DiscussionRepository {
  final Dio dio;
  final String baseUrl;

  DiscussionRepository({required this.dio, required this.baseUrl});


  // Future<Discussion> createDiscussion(Discussion discussion) async {
  //   final response = await dio.post(
  //     '$baseUrl/discussions',
  //     data: discussion.toJson(),
  //   );

  //   return Discussion.fromJson(response.data);
  // }

  Future<void> upvoteDiscussion(String discussionId, String userId) async {
    await dio.post('$baseUrl/discussions/$discussionId/upvote', data: {
      'userId': userId,
    });
  }

  Future<void> reactToDiscussion(
      String discussionId, String userId, String type) async {
    await dio.post('$baseUrl/discussions/$discussionId/react', data: {
      'userId': userId,
      'type': type,
    });
  }
  
  // Get discussions for a movie
  Future<List<Discussion>> fetchDiscussions(String movieId) async {
    final response = await dio.get('$baseUrl/discussions/$movieId');
    return (response.data as List)
        .map((json) => Discussion.fromJson(json))
        .toList();
  }

  // Delete discussion by ID (auth token must be set in Dio headers)
  Future<void> deleteDiscussion(String discussionId) async {
    await dio.delete('$baseUrl/discussions/$discussionId');
  }

  // Get comments for a discussion
  Future<List<DiscussionComment>> fetchComments(String discussionId) async {
    final response = await dio.get('$baseUrl/discussions/$discussionId/comments');
    return (response.data['comments'] as List)
        .map((json) => DiscussionComment.fromJson(json))
        .toList();
  }

  // Add comment to discussion
  Future<DiscussionComment> addComment(String discussionId, String text) async {
    final response = await dio.post('$baseUrl/discussions/$discussionId/comment', data: {
      'text': text,
    });
    return DiscussionComment.fromJson(response.data['comment']);
  }

  // Update comment (must be authenticated user)
  Future<DiscussionComment> updateComment(
      String discussionId, String commentId, String text) async {
    final response = await dio.put(
      '$baseUrl/discussions/$discussionId/comments/$commentId',
      data: {'text': text},
    );
    return DiscussionComment.fromJson(response.data['comment']);
  }

  // Create discussion
  Future<Discussion> createDiscussion({
    required String tmdbId,
    required String title,
    required String posterPath,
    required String text,
  }) async {
    final response = await dio.post(
      '$baseUrl/discussions',
      data: {
        'tmdbId': tmdbId,
        'title': title,
        'posterPath': posterPath,
        'text': text,
      },
    );
    return Discussion.fromJson(response.data['discussion']);
  }
}
