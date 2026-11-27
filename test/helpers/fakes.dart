import 'dart:async';

import 'package:cluvie_mobile/core/api/api_client.dart';
import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/features/clubs/data/comunity_provider.dart';
import 'package:dio/dio.dart';

/// One recorded request.
typedef ApiCall = ({String method, String path, Map<String, dynamic>? params, Map<String, dynamic>? data});

/// Stands in for [ApiClient] (a singleton with a private constructor) so
/// screen tests never touch the network and can assert what was sent.
///
/// [onGet] / [onPost] return the response body, or throw to simulate a
/// failure. They may return a Future to hold a request open.
class FakeApiClient implements ApiClient {
  FakeApiClient({this.onGet, this.onPost, this.onPatch, this.onDelete});

  FutureOr<Object?> Function(String path, Map<String, dynamic>? params)? onGet;
  FutureOr<Object?> Function(String path, Map<String, dynamic>? data)? onPost;
  FutureOr<Object?> Function(String path, Map<String, dynamic>? data)? onPatch;
  FutureOr<Object?> Function(String path)? onDelete;
  final calls = <ApiCall>[];

  Response<dynamic> _ok(String path, Object? data) =>
      Response<dynamic>(requestOptions: RequestOptions(path: path), data: data, statusCode: 200);

  @override
  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    calls.add((method: 'GET', path: path, params: params, data: null));
    return _ok(path, await (onGet?.call(path, params)));
  }

  @override
  Future<Response> post(String path, {Map<String, dynamic>? data}) async {
    calls.add((method: 'POST', path: path, params: null, data: data));
    return _ok(path, await (onPost?.call(path, data)));
  }

  @override
  Future<Response> patch(String path, {Map<String, dynamic>? data}) async {
    calls.add((method: 'PATCH', path: path, params: null, data: data));
    return _ok(path, await (onPatch?.call(path, data)));
  }

  @override
  Future<Response> delete(String path) async {
    calls.add((method: 'DELETE', path: path, params: null, data: null));
    if (onDelete == null) throw UnimplementedError('FakeApiClient: DELETE $path');
    return _ok(path, await onDelete!(path));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('FakeApiClient: ${invocation.memberName}');
}

Community fakeClub(String id, String name, {int members = 3, String? description}) => Community(
  id: id,
  name: name,
  description: description,
  members: [for (var i = 0; i < members; i++) 'u$i'],
  admins: const [],
  votes: const [],
  movieSuggestions: const [],
  createdAt: DateTime(2026),
);

class FakeJoinedCommunities extends JoinedCommunityNotifier {
  FakeJoinedCommunities(this.load);
  final FutureOr<List<Community>> Function() load;

  @override
  Future<List<Community>> build() async => load();
}

class FakeAllCommunities extends AllCommunitiesNotifier {
  FakeAllCommunities(this.load);
  final FutureOr<List<Community>> Function() load;

  @override
  Future<List<Community>> build() async => load();
}
