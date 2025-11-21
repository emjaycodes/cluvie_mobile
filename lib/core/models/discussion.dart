class Reaction {
  final String? type;
  final String? userId;

  Reaction({required this.type, required this.userId});

  factory Reaction.fromJson(Map<String, dynamic> json) => Reaction(
        type: json['type'],
        userId: json['userId'],
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'userId': userId,
      };
}

class Discussion {
  final String? id;
  final String? movieId;
  final String? userId;
  final String? text;
  final DateTime createdAt;
  final List<String?> upvotes;
  final List<Reaction> reactions;
  final bool pinned;

  Discussion({
    required this.id,
    required this.movieId,
    required this.userId,
    required this.text,
    required this.createdAt,
    required this.upvotes,
    required this.reactions,
    required this.pinned,
  });

  factory Discussion.fromJson(Map<String?, dynamic> json) => Discussion(
        id: json['_id'],
        movieId: json['movieId'],
        userId: json['userId'],
        text: json['text'],
        createdAt: DateTime.parse(json['createdAt']),
        upvotes: List<String?>.from(json['upvotes'] ?? []),
        reactions: (json['reactions'] as List<dynamic>?)
                ?.map((e) => Reaction.fromJson(e))
                .toList() ??
            [],
        pinned: json['pinned'] ?? false,
      );

  Map<String?, dynamic> toJson() => {
        'movieId': movieId,
        'userId': userId,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'upvotes': upvotes,
        'reactions': reactions.map((r) => r.toJson()).toList(),
        'pinned': pinned,
      };
}
