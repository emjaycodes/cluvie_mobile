/// A film club (`Community` on the backend).
///
/// Membership mirrors the backend's `utils/membership.js`: the owner always
/// counts as a member and an admin; an admin is the owner, anyone in
/// `admins`, or a member whose role is `admin`. Older documents store
/// `members` as raw ids rather than `{user, role}` entries.
class Community {
  final String? id;
  final String? name;
  final String? description;

  /// Member user ids, owner included.
  final List<String?> members;

  /// Admin user ids, owner included.
  final List<String?> admins;
  final List<String?> votes;
  final List<String?> movieSuggestions;
  final DateTime? createdAt;
  final String? ownerId;

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.admins,
    required this.votes,
    required this.movieSuggestions,
    required this.createdAt,
    this.ownerId,
  });

  /// Reads an id that may be a plain string or a populated `{_id}` object.
  static String? _idOf(Object? value) {
    if (value is String && value.isNotEmpty) return value;
    if (value is Map && value['_id'] is String) return value['_id'] as String;
    return null;
  }

  factory Community.fromJson(Map<String, dynamic> json) {
    final ownerId = _idOf(json['owner']);
    final memberIds = <String>[];
    final adminIds = <String>[];
    void addAdmin(String? id) {
      if (id != null && !adminIds.contains(id)) adminIds.add(id);
    }

    for (final m in json['members'] is List ? json['members'] as List : const []) {
      if (m is Map && m.containsKey('user')) {
        final uid = _idOf(m['user']);
        if (uid == null) continue;
        if (!memberIds.contains(uid)) memberIds.add(uid);
        if (m['role'] == 'admin') addAdmin(uid);
      } else {
        final uid = _idOf(m);
        if (uid != null && !memberIds.contains(uid)) memberIds.add(uid);
      }
    }
    for (final a in json['admins'] is List ? json['admins'] as List : const []) {
      addAdmin(_idOf(a));
    }
    if (ownerId != null) {
      if (!memberIds.contains(ownerId)) memberIds.insert(0, ownerId);
      addAdmin(ownerId);
    }

    List<String?> ids(Object? raw) => [for (final v in raw is List ? raw : const []) _idOf(v)];

    final name = json['name'];
    final description = json['description'];
    return Community(
      id: _idOf(json['_id']) ?? _idOf(json['id']),
      name: name is String && name.trim().isNotEmpty ? name.trim() : null,
      description: description is String && description.trim().isNotEmpty ? description.trim() : null,
      members: memberIds,
      admins: adminIds,
      votes: ids(json['votes']),
      movieSuggestions: ids(json['movie_suggestions']),
      createdAt: DateTime.tryParse('${json['createdAt']}')?.toLocal(),
      ownerId: ownerId,
    );
  }

  bool isMember(String? userId) => userId != null && (ownerId == userId || members.contains(userId));
  bool isAdmin(String? userId) => userId != null && (ownerId == userId || admins.contains(userId));
  bool isOwner(String? userId) => userId != null && ownerId == userId;

  /// The display name; never empty.
  String get displayName => name ?? 'Untitled club';

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'members': members,
      'admins': admins,
      'votes': votes,
      'movie_suggestions': movieSuggestions,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}
