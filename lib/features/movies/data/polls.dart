import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/features/discover/data/tmdb.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mongo ids are 24 hex characters. The polls API answers 400 for anything
/// else, so such ids (demo links) are treated as "no polls" without a request.
final _mongoId = RegExp(r'^[a-f\d]{24}$', caseSensitive: false);
bool isMongoId(String? id) => id != null && _mongoId.hasMatch(id);

class PollOption {
  const PollOption({
    required this.id,
    required this.index,
    required this.title,
    required this.voteCount,
    required this.voterIds,
    this.movieId,
    this.tmdbId,
    this.posterUrl,
  });

  /// The option's own id, which `POST /polls/:id/vote` takes.
  final String id;

  /// Position in the poll as created (suggestion order). Ties go to the
  /// lower index, as on the server.
  final int index;
  final String title;
  final int voteCount;
  final Set<String> voterIds;

  /// Catalog id (discussions are keyed by it) and TMDB id (Movie Detail).
  final String? movieId;
  final int? tmdbId;
  final String? posterUrl;

  PollOption withVote(String userId) => PollOption(
        id: id,
        index: index,
        title: title,
        voteCount: voteCount + 1,
        voterIds: {...voterIds, userId},
        movieId: movieId,
        tmdbId: tmdbId,
        posterUrl: posterUrl,
      );
}

class Poll {
  const Poll({
    required this.id,
    required this.question,
    required this.expiresAt,
    required this.options,
    this.open = true,
    this.allowMultiple = false,
  });

  final String id;
  final String question;
  final DateTime expiresAt;
  final bool open;
  final bool allowMultiple;

  /// In the order received (suggestion order); see [ranked].
  final List<PollOption> options;

  int get totalVotes => options.fold(0, (n, o) => n + o.voteCount);

  bool isOpenAt(DateTime now) => open && expiresAt.isAfter(now);

  /// Most votes first; ties go to the earlier suggestion (the server's rule).
  List<PollOption> get ranked => [...options]..sort(compareOptions);

  static int compareOptions(PollOption a, PollOption b) {
    final byVotes = b.voteCount.compareTo(a.voteCount);
    return byVotes != 0 ? byVotes : a.index.compareTo(b.index);
  }

  /// The leading option, or null before anyone has voted.
  PollOption? get leader => totalVotes == 0 ? null : ranked.first;

  bool hasVoted(String? userId) => userId != null && options.any((o) => o.voterIds.contains(userId));

  Poll replaceOption(PollOption option) => Poll(
        id: id,
        question: question,
        expiresAt: expiresAt,
        open: open,
        allowMultiple: allowMultiple,
        options: [for (final o in options) o.id == option.id ? option : o],
      );

  static Poll? fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['pollId'];
    final expires = DateTime.tryParse('${json['expiresAt']}');
    if (id is! String || expires == null) return null;
    final raw = json['options'] is List ? json['options'] as List : const [];
    final options = <PollOption>[];
    for (final o in raw) {
      if (o is! Map) continue;
      final optionId = o['_id'] ?? o['optionId'];
      if (optionId is! String) continue;
      final movie = o['movie'];
      final m = movie is Map ? Map<String, dynamic>.from(movie) : const <String, dynamic>{};
      final film = m.isEmpty ? null : TmdbMovie.fromJson(m);
      final votes = o['votes'];
      final count = o['voteCount'];
      final voterIds = {for (final v in (votes is List ? votes : const [])) '$v'};
      options.add(PollOption(
        id: optionId,
        index: options.length,
        title: film?.title ?? 'Untitled',
        voteCount: count is int ? count : voterIds.length,
        voterIds: voterIds,
        movieId: m['_id'] is String ? m['_id'] as String : (movie is String ? movie : null),
        tmdbId: film?.id,
        posterUrl: film?.posterUrl('w185'),
      ));
    }
    final question = json['question'];
    return Poll(
      id: id,
      question: question is String && question.trim().isNotEmpty ? question.trim() : 'What should we watch?',
      expiresAt: expires.toLocal(),
      open: json['status'] == null || json['status'] == 'open',
      allowMultiple: json['allowMultiple'] == true,
      options: options,
    );
  }
}

/// A club's open polls (`GET /polls/active?communityId=`), soonest to close
/// first.
final activePollsProvider = FutureProvider.autoDispose.family<List<Poll>, String>((ref, communityId) async {
  if (!isMongoId(communityId)) return const [];
  final res = await ref.read(apiClientProvider).get('/polls/active', params: {'communityId': communityId});
  final body = res.data;
  final list = body is List ? body : (body is Map && body['data'] is List ? body['data'] as List : const []);
  return [
    for (final p in list)
      if (p is Map) Poll.fromJson(Map<String, dynamic>.from(p)),
  ].whereType<Poll>().toList();
});

/// Why a vote was refused.
enum VoteRefusal {
  /// The user already voted in this single-choice poll (`ALREADY_VOTED`).
  alreadyVoted,

  /// The poll closed or expired (`POLL_CLOSED`).
  closed,

  /// The user isn't in the club (403). Retrying can't help.
  notMember,

  /// Anything else: network, server.
  failed,
}

/// Casts a vote. Returns null on success.
Future<VoteRefusal?> castVote(WidgetRef ref, {required String pollId, required String optionId}) async {
  try {
    await ref.read(apiClientProvider).post('/polls/$pollId/vote', data: {'optionId': optionId});
    return null;
  } on ApiException catch (e) {
    final body = e.responseBody;
    final code = body is Map ? body['code'] : null;
    if (code == 'ALREADY_VOTED') return VoteRefusal.alreadyVoted;
    if (code == 'POLL_CLOSED') return VoteRefusal.closed;
    if (e.statusCode == 403) return VoteRefusal.notMember;
    return VoteRefusal.failed;
  } catch (_) {
    return VoteRefusal.failed;
  }
}
