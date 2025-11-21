class Community {
  final String? id;
  final String? name;
  final String? description;
  final List<String?> members;
  final List<String?> admins;
  final List<String?> votes;
  final List<String?> movieSuggestions;
  final DateTime createdAt;

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.admins,
    required this.votes,
    required this.movieSuggestions,
    required this.createdAt,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
      final membersJson = json['members'] as List<dynamic>? ?? [];

  final memberIds = <String?>[];
  final adminIds  = <String?>[];

  for (final m in membersJson) {
    final uid  = m['user'] as String?;
    final role = m['role'] as String? ?? 'member';
    memberIds.add(uid);
    if (role == 'admin') adminIds.add(uid);
  }

    return Community(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
         members: memberIds,
    admins: adminIds,
      votes: List<String?>.from(json['votes'] ?? []),
      movieSuggestions: List<String?>.from(json['movie_suggestions'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'members': members,
      'admins': admins,
      'votes': votes,
      'movie_suggestions': movieSuggestions,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
