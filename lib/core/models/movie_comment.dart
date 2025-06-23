class MovieComment {
  final String id;
  final String movieId;
  final String userId;
  final String comment;
  final DateTime createdAt;

  MovieComment({
    required this.id,
    required this.movieId,
    required this.userId,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movieId': movieId,
      'userId': userId,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MovieComment.fromJson(Map<String, dynamic> json) {
    return MovieComment(
      id: json['id'],
      movieId: json['movieId'],
      userId: json['userId'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

  // @override
  // String toString() {
  //   return 'MovieComment{id: $id, movieId: $movieId, userId: $userId, comment: $comment, createdAt: $createdAt}';
  // }
// }  