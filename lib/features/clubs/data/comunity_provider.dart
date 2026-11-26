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
    if (current != null) {
      state = AsyncData([created, ...current.where((c) => c.id != created.id)]);
    } else {
      // The list was loading or failed: fetch it again, now with the club.
      ref.invalidateSelf();
    }
    final id = created.id;
    if (id != null) {
      final overrides = ref.read(clubMembershipOverridesProvider.notifier);
      overrides.state = {...overrides.state, id: true};
    }
    ref.invalidate(allCommunitiesProvider);
    return created;
  }
}

/// Whether the signed-in user is in a club. [unknown] while the answer is
/// loading or failed to load: don't treat that as "not a member".
enum ClubMembership { member, notMember, unknown }

/// Joins and leaves made in this session, by club id (true = joined). They
/// win over fetched data, so a join shows at once and survives a failed
/// refetch.
final clubMembershipOverridesProvider = StateProvider<Map<String, bool>>((ref) => const {});

/// Membership of club [id], by the backend's own rule
/// (`utils/membership.js`: owner, `{user}` entries or raw-id members), read
/// from the club itself. `GET /communities/joined` only matches `{user}`
/// entries, so it is a fallback, not the authority.
final clubMembershipProvider = Provider.autoDispose.family<ClubMembership, String>((ref, id) {
  final override = ref.watch(clubMembershipOverridesProvider)[id];
  if (override != null) return override ? ClubMembership.member : ClubMembership.notMember;

  // Demo links: no such club, so nothing to join or be a member of.
  if (!isMongoId(id)) return ClubMembership.unknown;

  final me = ref.watch(currentUserIdProvider).valueOrNull;
  final hasMe = me != null && me.isNotEmpty;
  final club = ref.watch(communityProvider(id));
  if (hasMe && club.hasValue) {
    return club.requireValue.isMember(me) ? ClubMembership.member : ClubMembership.notMember;
  }

  final joined = ref.watch(joinedCommunitiesProvider).valueOrNull;
  if (joined != null && joined.any((c) => c.id == id)) return ClubMembership.member;
  // Only when the all-clubs list is already loaded elsewhere (the Clubs
  // tab); never fetch it just for this.
  if (hasMe && ref.exists(allCommunitiesProvider)) {
    final fromAll = ref.watch(allCommunitiesProvider).valueOrNull?.where((c) => c.id == id).firstOrNull;
    if (fromAll != null && fromAll.isMember(me)) return ClubMembership.member;
  }
  // Still finding out from the club itself.
  if (hasMe && club.isLoading && !club.hasError) return ClubMembership.unknown;
  return joined != null ? ClubMembership.notMember : ClubMembership.unknown;
});

/// Membership for a loaded [club].
ClubMembership membershipIn(WidgetRef ref, Community club) => ref.watch(clubMembershipProvider(club.id ?? ''));

/// Whether [club] in a list is the user's: from this session's joins and
/// leaves, the club's own members, or `/joined`.
bool isMyClub(Community club, {required String? me, required Set<String?> joinedIds, required Map<String, bool> overrides}) {
  final override = overrides[club.id];
  if (override != null) return override;
  return joinedIds.contains(club.id) || (me != null && me.isNotEmpty && club.isMember(me));
}

/// Why joining or leaving didn't happen.
enum ClubActionRefusal {
  /// The owner can't leave their own club.
  ownerCannotLeave,

  /// The club no longer exists.
  notFound,

  /// The session expired or was refused (401/403).
  unauthorised,

  /// Network or server failure; retrying may help.
  failed,
}

/// Refetches what a join or leave changed, and waits for it. Returns false
/// when the refetch failed (the change itself went through).
Future<bool> _refreshClub(WidgetRef ref, String id) async {
  ref.invalidate(joinedCommunitiesProvider);
  ref.invalidate(allCommunitiesProvider);
  ref.invalidate(communityProvider(id));
  // The club provider auto-disposes: keep it alive while waiting on it.
  final keep = ref.listenManual(communityProvider(id), (_, __) {});
  try {
    await Future.wait([
      ref.read(joinedCommunitiesProvider.future),
      ref.read(communityProvider(id).future),
    ]);
    return true;
  } catch (_) {
    return false;
  } finally {
    keep.close();
  }
}

ClubActionRefusal? _refusalFor(ApiException e) {
  if (e.statusCode == 404) return ClubActionRefusal.notFound;
  if (e.statusCode == 401 || e.statusCode == 403) return ClubActionRefusal.unauthorised;
  if (e.statusCode != 400) return ClubActionRefusal.failed;
  return null;
}

/// The outcome of a join or leave that went through.
class ClubActionDone {
  const ClubActionDone({required this.refreshed});

  /// False when the club couldn't be refetched afterwards. Membership is
  /// still updated locally.
  final bool refreshed;
}

/// Joins a club. "Already a member" counts as joined. Waits for the club
/// to be refetched, so callers can keep their button busy until then.
Future<(ClubActionDone?, ClubActionRefusal?)> joinClub(WidgetRef ref, String id) async {
  try {
    await CommunityRepository(apiClient: ref.read(apiClientProvider)).join(id);
  } on ApiException catch (e) {
    final refusal = _refusalFor(e);
    if (refusal != null) return (null, refusal);
    // 400 means "already a member": the goal is met.
  } catch (_) {
    return (null, ClubActionRefusal.failed);
  }
  final overrides = ref.read(clubMembershipOverridesProvider.notifier);
  overrides.state = {...overrides.state, id: true};
  return (ClubActionDone(refreshed: await _refreshClub(ref, id)), null);
}

/// Leaves a club. "Not a member" counts as left.
Future<(ClubActionDone?, ClubActionRefusal?)> leaveClub(WidgetRef ref, String id) async {
  try {
    await CommunityRepository(apiClient: ref.read(apiClientProvider)).leave(id);
  } on ApiException catch (e) {
    final body = e.responseBody;
    if (e.statusCode == 400 && body is Map) {
      // Prefer a code; the message check covers today's backend.
      if (body['code'] == 'OWNER_CANNOT_LEAVE' ||
          (body['code'] == null && '${body['message']}'.toLowerCase().contains('owner'))) {
        return (null, ClubActionRefusal.ownerCannotLeave);
      }
    }
    final refusal = _refusalFor(e);
    if (refusal != null) return (null, refusal);
    // Otherwise "not a member": the goal is met.
  } catch (_) {
    return (null, ClubActionRefusal.failed);
  }
  final overrides = ref.read(clubMembershipOverridesProvider.notifier);
  overrides.state = {...overrides.state, id: false};
  return (ClubActionDone(refreshed: await _refreshClub(ref, id)), null);
}

/// What happened when making someone an admin.
enum PromoteResult { done, noLongerMember, notAllowed, notFound, failed }

/// Makes [userId] an admin of club [clubId], then refetches the club.
/// "Already an admin" counts as done; "not a member" (they left since the
/// list loaded) is reported as such.
Future<PromoteResult> makeClubAdmin(WidgetRef ref, String clubId, String userId) async {
  var result = PromoteResult.done;
  try {
    await CommunityRepository(apiClient: ref.read(apiClientProvider)).makeAdmin(clubId, userId);
  } on ApiException catch (e) {
    final body = e.responseBody;
    final message = body is Map ? '${body['message'] ?? ''}'.toLowerCase() : '';
    final code = body is Map ? body['code'] : null;
    result = switch (e.statusCode) {
      401 || 403 => PromoteResult.notAllowed,
      404 => PromoteResult.notFound,
      400 when code == 'ALREADY_ADMIN' || message.contains('already an admin') => PromoteResult.done,
      400 when code == 'NOT_A_MEMBER' || message.contains('not a member') => PromoteResult.noLongerMember,
      _ => PromoteResult.failed,
    };
  } catch (_) {
    result = PromoteResult.failed;
  }
  if (result != PromoteResult.failed && result != PromoteResult.notAllowed) ref.invalidate(communityProvider(clubId));
  return result;
}
