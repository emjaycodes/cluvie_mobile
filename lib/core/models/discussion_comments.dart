class DiscussionComment {
  final String id;
  final String discussionId;
  final String userId;
  final String text;
  final DateTime createdAt;

  DiscussionComment({
    required this.id,
    required this.discussionId,
    required this.userId,
    required this.text,
    required this.createdAt,
  });

  factory DiscussionComment.fromJson(Map<String, dynamic> json) => DiscussionComment(
        id: json['_id'],
        discussionId: json['discussionId'],
        userId: json['userId'],
        text: json['text'],
        createdAt: DateTime.parse(json['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'discussionId': discussionId,
        'userId': userId,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };
}
