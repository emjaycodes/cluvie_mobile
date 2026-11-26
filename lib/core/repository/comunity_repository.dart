import 'package:cluvie_mobile/core/api/api_client.dart';
import 'package:cluvie_mobile/core/models/community.dart';

/// The backend's `/communities` routes. The backend has no update, delete,
/// invite-code, ownership-transfer or chat routes, so none are offered here.
class CommunityRepository {
  CommunityRepository({required ApiClient apiClient}) : _apiClient = apiClient;
  final ApiClient _apiClient;

  static List<Community> _list(Object? body, String key) {
    final raw = body is Map ? (body[key] ?? body['data']) : body;
    return [
      for (final json in raw is List ? raw : const [])
        if (json is Map) Community.fromJson(Map<String, dynamic>.from(json)),
    ];
  }

  /// Clubs the signed-in user belongs to (`GET /communities/joined`).
  Future<List<Community>> fetchJoinedCommunities() async =>
      _list((await _apiClient.get('/communities/joined')).data, 'communities');

  /// Every club, newest first (`GET /communities/all`).
  Future<List<Community>> fetchAllCommunities() async =>
      _list((await _apiClient.get('/communities/all')).data, 'communities');

  /// One club (`GET /communities/:id`, `{success, data}`).
  Future<Community> fetchCommunityById(String id) async {
    final body = (await _apiClient.get('/communities/$id')).data;
    final json = body is Map && body['data'] is Map ? body['data'] : body;
    if (json is! Map) throw StateError('Unexpected club response');
    return Community.fromJson(Map<String, dynamic>.from(json));
  }

  /// Creates a club; the caller becomes its owner (`POST /communities`).
  Future<Community> createCommunity(String name, String description) async {
    final body = (await _apiClient.post('/communities', data: {'name': name, 'description': description})).data;
    final json = body is Map ? (body['community'] ?? body['data']) : null;
    if (json is! Map) throw StateError('Unexpected create response');
    return Community.fromJson(Map<String, dynamic>.from(json));
  }

  /// `POST /communities/:id/join`
  Future<void> join(String id) => _apiClient.post('/communities/$id/join');

  /// `POST /communities/:id/leave`
  Future<void> leave(String id) => _apiClient.post('/communities/$id/leave');

  /// Makes a member an admin; owner and admins only
  /// (`POST /communities/:id/make-admin`).
  Future<void> makeAdmin(String id, String userId) =>
      _apiClient.post('/communities/$id/make-admin', data: {'targetUserId': userId});
}
