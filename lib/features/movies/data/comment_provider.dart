import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/models/movie_comment.dart';
import 'package:cluvie_mobile/features/movies/data/movie_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:cluvie_mobile/core/repository/comment_repository.dart';

final movieCommentsProvider =
    AsyncNotifierProvider.family<MovieCommentNotifier, List<MovieComment>, String>(
  MovieCommentNotifier.new,
);

class MovieCommentNotifier extends FamilyAsyncNotifier<List<MovieComment>, String> {

  late final CommentRepository _repository;
  late final String movieId;


  @override
  Future<List<MovieComment>> build(String arg) async {
    final apiClient = ref.read(apiClientProvider);
 
    movieId = arg;
    _repository = CommentRepository(apiClient: apiClient);
    return await _repository.fetchMovieComments(movieId);
  }

  /// 🔁 Refresh the list of comments
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.fetchMovieComments(movieId));
  }

  /// Create a new comment for the movie
  Future<MovieComment> createComment(String text) async {
    final newComment = await _repository.createMovieComment(movieId, text);
    final current = state.value ?? [];
    state = AsyncData([...current, newComment]);
    return newComment;
  }

  /// Delete a comment by its ID
  Future<void> deleteComment(String commentId) async {
    await _repository.deleteMovieComment(commentId);
    final current = state.value ?? [];
    state = AsyncData(current.where((c) => c.id != commentId).toList());
  }

}