import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/core/repository/comunity_repository.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/movies/data/polls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Club chat has no backend yet (the socket only carries watch-party events).
/// While false, nothing links to `/communityChat`.
const kClubChatAvailable = false;

/// The clubs the signed-in user belongs to.
final joinedCommunitiesProvider =
    AsyncNotifierProvider<JoinedCommunityNotifier, List<Community>>(JoinedCommunityNotifier.new);

/// Every club, newest first.
final allCommunitiesProvider =
    AsyncNotifierProvider<AllCommunitiesNotifier, List<Community>>(AllCommunitiesNotifier.new);

/// One club. Ids that aren't Mongo ids (demo links) fail as "not found"
/// without a request: the backend would answer 500 for them.
final communityProvider = FutureProvider.autoDispose.family<Community, String>((ref, id) async {
  if (!isMongoId(id)) throw const ClubNotFound();
  try {
    return await CommunityRepository(apiClient: ref.read(apiClientProvider)).fetchCommunityById(id);
  } on ApiException catch (e) {
    if (e.statusCode == 404) throw const ClubNotFound();
    rethrow;
  }
});

class ClubNotFound implements Exception {
  const ClubNotFound();
}

class AllCommunitiesNotifier extends AsyncNotifier<List<Community>> {
  // A getter, not `late final`: Riverpod reuses the notifier on rebuild.
  CommunityRepository get _repository => CommunityRepository(apiClient: ref.read(apiClientProvider));

  @override
  Future<List<Community>> build() => _repository.fetchAllCommunities();
}

class JoinedCommunityNotifier extends AsyncNotifier<List<Community>> {
  CommunityRepository get _repo => CommunityRepository(apiClient: ref.read(apiClientProvider));

  @override
  Future<List<Community>> build() => _repo.fetchJoinedCommunities();

  /// Creates a club (the caller becomes its owner) and returns it. The
  /// all-clubs list is refetched so the new club shows there too.
  Future<Community> createCommunity(String name, String description) async {
    final created = await _repo.createCommunity(name, description);
    final current = state.valueOrNull;
    if (current != null) state = AsyncData([created, ...current.where((c) => c.id != created.id)]);
    ref.invalidate(allCommunitiesProvider);
    return created;
  }
}

/// Whether the signed-in user is in a club. [unknown] while the answer is
/// loading or failed to load: don't treat that as "not a member".
enum ClubMembership { member, notMember, unknown }

/// Membership from the joined-clubs list.
final clubMembershipProvider = Provider.autoDispose.family<ClubMembership, String>((ref, id) {
  final joined = ref.watch(joinedCommunitiesProvider);
  if (joined.hasError && !joined.hasValue) return ClubMembership.unknown;
  final list = joined.valueOrNull;
  if (list == null) return ClubMembership.unknown;
  return list.any((c) => c.id == id) ? ClubMembership.member : ClubMembership.notMember;
});

/// Membership for a loaded [club]: from its member list when the user's id
/// is known, else from the joined-clubs list.
ClubMembership membershipIn(WidgetRef ref, Community club) {
  final me = ref.watch(currentUserIdProvider).valueOrNull;
  if (me != null && me.isNotEmpty) {
    return club.isMember(me) ? ClubMembership.member : ClubMembership.notMember;
  }
  return ref.watch(clubMembershipProvider(club.id ?? ''));
}

/// Why joining or leaving didn't happen.
enum ClubActionRefusal {
  /// The owner can't leave their own club.
  ownerCannotLeave,

  /// The club no longer exists.
  notFound,

  /// Network or server failure; retrying may help.
  failed,
}

void _refreshClub(WidgetRef ref, String id) {
  ref.invalidate(joinedCommunitiesProvider);
  ref.invalidate(allCommunitiesProvider);
  ref.invalidate(communityProvider(id));
}

/// Joins a club. Returns null on success, including "already a member".
Future<ClubActionRefusal?> joinClub(WidgetRef ref, String id) async {
  try {
    await CommunityRepository(apiClient: ref.read(apiClientProvider)).join(id);
  } on ApiException catch (e) {
    if (e.statusCode == 404) return ClubActionRefusal.notFound;
    if (e.statusCode != 400) return ClubActionRefusal.failed;
    // 400 means "already a member": the goal is met.
  } catch (_) {
    return ClubActionRefusal.failed;
  }
  _refreshClub(ref, id);
  return null;
}

/// Leaves a club. Returns null on success, including "not a member".
Future<ClubActionRefusal?> leaveClub(WidgetRef ref, String id) async {
  try {
    await CommunityRepository(apiClient: ref.read(apiClientProvider)).leave(id);
  } on ApiException catch (e) {
    if (e.statusCode == 404) return ClubActionRefusal.notFound;
    if (e.statusCode != 400) return ClubActionRefusal.failed;
    final body = e.responseBody;
    final message = body is Map ? '${body['message']}' : '';
    if (message.toLowerCase().contains('owner')) return ClubActionRefusal.ownerCannotLeave;
    // Otherwise "not a member": the goal is met.
  } catch (_) {
    return ClubActionRefusal.failed;
  }
  _refreshClub(ref, id);
  return null;
}
