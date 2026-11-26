import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/features/clubs/data/comunity_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

const _id = '64c000000000000000000001';
const _owner = '64b0000000000000000000aa';

Map<String, dynamic> clubJson({String id = _id, String name = 'Cinema Sundays', Object? members, Object? admins}) => {
      '_id': id,
      'name': name,
      'description': 'Weekly picks',
      'owner': _owner,
      'members': members ??
          [
            {'user': _owner, 'role': 'admin', '_id': 'sub1'},
            {'user': 'u2', 'role': 'member', '_id': 'sub2'},
          ],
      'admins': admins ?? const [],
      'movie_suggestions': const ['m1', 'm2'],
      'createdAt': '2026-03-01T10:00:00.000Z',
    };

ApiException apiError(int status, [Object? body]) =>
    ApiException(message: 'HTTP $status', statusCode: status, responseBody: body);

void main() {
  group('Community.fromJson', () {
    test('reads {user, role} members, the owner and admins', () {
      final c = Community.fromJson(clubJson(admins: ['u3']));
      expect(c.id, _id);
      expect(c.members, [_owner, 'u2']);
      expect(c.admins, containsAll([_owner, 'u3']));
      expect(c.isOwner(_owner), isTrue);
      expect(c.isAdmin('u2'), isFalse);
      expect(c.isAdmin('u3'), isTrue);
      expect(c.isMember('u2'), isTrue);
      expect(c.isMember('stranger'), isFalse);
      expect(c.movieSuggestions, hasLength(2));
      expect(c.createdAt, isNotNull);
    });

    test('older documents with raw-id members, no owner entry, no createdAt', () {
      final json = clubJson(members: ['u1', 'u2', 'u2'])..remove('createdAt');
      final c = Community.fromJson(json);
      // The owner counts as a member even when not listed.
      expect(c.members, [_owner, 'u1', 'u2']);
      expect(c.isMember(_owner), isTrue);
      expect(c.createdAt, isNull);
    });

    test('blank name and description read as null; displayName never empty', () {
      final c = Community.fromJson({'_id': _id, 'name': '  ', 'description': ''});
      expect(c.name, isNull);
      expect(c.description, isNull);
      expect(c.displayName, 'Untitled club');
      expect(c.members, isEmpty);
    });
  });

  group('providers', () {
    late FakeApiClient api;
    late ProviderContainer container;

    setUp(() {
      api = FakeApiClient(onGet: (path, _) {
        if (path == '/communities/$_id') return {'success': true, 'data': clubJson()};
        if (path == '/communities/joined' || path == '/communities/all') {
          return {'success': true, 'communities': [clubJson()]};
        }
        throw apiError(404);
      });
      container = ProviderContainer(overrides: [apiClientProvider.overrideWithValue(api)]);
      addTearDown(container.dispose);
    });

    test('communityProvider unwraps the {success, data} envelope', () async {
      final c = await container.read(communityProvider(_id).future);
      expect(c.displayName, 'Cinema Sundays');
    });

    test('a non-Mongo id is "not found" without a request', () async {
      await expectLater(container.read(communityProvider('demo-community').future), throwsA(isA<ClubNotFound>()));
      expect(api.calls, isEmpty);
    });

    test('a 404 is "not found"', () async {
      await expectLater(
        container.read(communityProvider('64c0000000000000000000ff').future),
        throwsA(isA<ClubNotFound>()),
      );
    });

    test('the real notifiers survive invalidation (no late-final rebuild error)', () async {
      expect(await container.read(joinedCommunitiesProvider.future), hasLength(1));
      expect(await container.read(allCommunitiesProvider.future), hasLength(1));
      container.invalidate(joinedCommunitiesProvider);
      container.invalidate(allCommunitiesProvider);
      expect(await container.read(joinedCommunitiesProvider.future), hasLength(1));
      expect(await container.read(allCommunitiesProvider.future), hasLength(1));
    });

    test('createCommunity puts the new club first and refetches all clubs', () async {
      api.onPost = (path, data) => {
            'success': true,
            'community': clubJson(id: '64c000000000000000000002', name: data!['name'] as String),
          };
      await container.read(joinedCommunitiesProvider.future);
      await container.read(allCommunitiesProvider.future);
      final before = api.calls.where((c) => c.path == '/communities/all').length;
      final created = await container.read(joinedCommunitiesProvider.notifier).createCommunity('Noir Nights', 'Old films');
      expect(created.displayName, 'Noir Nights');
      expect(container.read(joinedCommunitiesProvider).value!.first.displayName, 'Noir Nights');
      await container.read(allCommunitiesProvider.future);
      expect(api.calls.where((c) => c.path == '/communities/all').length, before + 1);
      expect(api.calls.last.method, 'GET');
      expect(api.calls.firstWhere((c) => c.method == 'POST').data, {'name': 'Noir Nights', 'description': 'Old films'});
    });

    test('membership is unknown until the joined list loads, and on failure', () async {
      expect(container.read(clubMembershipProvider(_id)), ClubMembership.unknown);
      await container.read(joinedCommunitiesProvider.future);
      expect(container.read(clubMembershipProvider(_id)), ClubMembership.member);
      expect(container.read(clubMembershipProvider('64c0000000000000000000ff')), ClubMembership.notMember);

      final failing = ProviderContainer(overrides: [
        apiClientProvider.overrideWithValue(FakeApiClient(onGet: (_, __) => throw apiError(500))),
      ]);
      addTearDown(failing.dispose);
      await expectLater(failing.read(joinedCommunitiesProvider.future), throwsA(anything));
      expect(failing.read(clubMembershipProvider(_id)), ClubMembership.unknown);
    });
  });

  group('join and leave', () {
    Future<ClubActionRefusal?> run(
      WidgetTester tester,
      FakeApiClient api,
      Future<ClubActionRefusal?> Function(WidgetRef ref) action,
    ) async {
      late WidgetRef captured;
      await tester.pumpWidget(ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(api)],
        child: Consumer(builder: (context, ref, _) {
          captured = ref;
          return const SizedBox();
        }),
      ));
      ClubActionRefusal? result;
      await tester.runAsync(() async => result = await action(captured));
      return result;
    }

    testWidgets('join posts and succeeds; "already a member" counts as joined', (tester) async {
      final api = FakeApiClient(onPost: (_, __) => {'success': true});
      expect(await run(tester, api, (ref) => joinClub(ref, _id)), isNull);
      expect(api.calls.single.path, '/communities/$_id/join');

      api.onPost = (_, __) => throw apiError(400, {'message': 'User already a member'});
      expect(await run(tester, api, (ref) => joinClub(ref, _id)), isNull);

      api.onPost = (_, __) => throw apiError(404);
      expect(await run(tester, api, (ref) => joinClub(ref, _id)), ClubActionRefusal.notFound);

      api.onPost = (_, __) => throw apiError(500);
      expect(await run(tester, api, (ref) => joinClub(ref, _id)), ClubActionRefusal.failed);
    });

    testWidgets('leave: the owner is refused; "not a member" counts as left', (tester) async {
      final api = FakeApiClient(onPost: (_, __) => throw apiError(400, {'message': 'Owner cannot leave the community'}));
      expect(await run(tester, api, (ref) => leaveClub(ref, _id)), ClubActionRefusal.ownerCannotLeave);
      expect(api.calls.single.path, '/communities/$_id/leave');

      api.onPost = (_, __) => throw apiError(400, {'message': 'You are not a member of this community'});
      expect(await run(tester, api, (ref) => leaveClub(ref, _id)), isNull);

      api.onPost = (_, __) => {'success': true};
      expect(await run(tester, api, (ref) => leaveClub(ref, _id)), isNull);
    });
  });
}
