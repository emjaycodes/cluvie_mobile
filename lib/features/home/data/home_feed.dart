import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/discover/data/tmdb.dart';
import 'package:cluvie_mobile/features/notifications/data/notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Home feed from `GET /api/feed`: everything in the signed-in user's
/// clubs (owner, `{user}` or legacy raw-id member). Each section holds at
/// most `limit` items.
class HomeFeed {
  const HomeFeed({
    this.clubCount = 0,
    this.pick,
    this.poll,
    this.happening = const [],
    this.parties = const [],
    this.discussions = const [],
    this.suggestions = const [],
  });

  /// How many clubs the user is in. 0: the first-run state, not five
  /// empty sections.
  final int clubCount;

  /// The hero: the next watch party that hasn't started. Null hides it.
  final FeaturedPick? pick;

  /// The open poll that closes soonest. Null shows the "suggest" state.
  final HomePoll? poll;

  /// Parties under way: live, or past their start time (only the host's
  /// button makes a party live, so a party can be due but not "live").
  /// Empty hides "Happening now".
  final List<HomeParty> happening;

  /// Upcoming parties after the hero's, soonest first.
  final List<HomeParty> parties;
  final List<HomeDiscussion> discussions;

  /// Films suggested in your clubs, newest first, round-robin across clubs.
  final List<HomeSuggestion> suggestions;

  bool get hasClubs => clubCount > 0;

  /// The next moment this feed goes stale: a poll closing or a party
  /// starting. Home refreshes then.
  DateTime? nextChange() {
    final times = [
      if (poll != null) poll!.closesAt,
      if (pick != null) pick!.party.scheduledAt,
      for (final p in parties) p.scheduledAt,
    ];
    if (times.isEmpty) return null;
    return times.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// Parses `{success, data}` or the bare `data`. [me] decides "hosting".
  factory HomeFeed.fromJson(Object? json, {String? me, DateTime? now}) {
    final body = json is Map && json['data'] is Map ? json['data'] as Map : json;
    if (body is! Map) return const HomeFeed();
    List<Map> list(String key) => [for (final v in body[key] is List ? body[key] as List : const []) if (v is Map) v];

    final polls = [for (final p in list('polls')) if (HomePoll.fromJson(p, now: now) case final v?) v];
    final all = [for (final p in list('watchParties')) if (HomeParty.fromJson(p, me: me) case final v?) v]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final at = now ?? DateTime.now();
    bool started(HomeParty p) => p.isLive || !p.scheduledAt.isAfter(at);
    final happening = [for (final p in all) if (started(p)) p];
    final upcoming = [for (final p in all) if (!started(p)) p];
    final pickParty = upcoming.firstOrNull;
    return HomeFeed(
      clubCount: list('communities').length,
      // A poll past its close time is over, whatever the cached feed says.
      poll: polls.where((p) => p.closesAt.isAfter(at)).firstOrNull,
      happening: happening,
      pick: pickParty == null ? null : FeaturedPick(pickParty),
      parties: upcoming.skip(1).toList(),
      discussions: [for (final d in list('discussions')) if (HomeDiscussion.fromJson(d) case final v?) v],
      suggestions: [for (final s in list('suggestions')) if (HomeSuggestion.fromJson(s) case final v?) v],
    );
  }
}

String? _str(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;

String? _id(Object? v) {
  if (v is String && v.isNotEmpty) return v;
  if (v is Map && v['_id'] is String) return v['_id'] as String;
  return null;
}

int _int(Object? v) => v is num ? v.toInt() : 0;

TmdbMovie? _film(Object? v) => v is Map ? TmdbMovie.fromJson(Map<String, dynamic>.from(v)) : null;

/// The hero: the next watch party, shown with its film's poster.
class FeaturedPick {
  const FeaturedPick(this.party);
  final HomeParty party;

  /// The party's own title (R11-N12).
  String get title => party.title;

  /// The film, when it differs from the party's title.
  String? get filmTitle => party.film?.title == party.title ? null : party.film?.title;

  /// Release year, or null.
  String? get year => party.film?.year;

  String? get posterUrl => party.film?.posterUrl('w500');
}

class HomePollOption {
  const HomePollOption({required this.optionId, required this.film, required this.votes, required this.order});
  final String optionId;
  final TmdbMovie film;
  final int votes;

  /// Position in the poll; ties go to the earliest option.
  final int order;

  String get title => film.title;
  String? get posterUrl => film.posterUrl('w185');
}

/// An open poll in one of your clubs.
class HomePoll {
  const HomePoll({
    required this.pollId,
    required this.communityId,
    required this.club,
    required this.question,
    required this.closesAt,
    required this.options,
    this.hasVoted = false,
    this.serverTotal,
    this.now,
  });

  final String pollId;
  final String communityId;
  final String? club;
  final String? question;
  final DateTime closesAt;
  final List<HomePollOption> options;
  final bool hasVoted;

  /// The server's total, which counts votes for options whose film is
  /// gone (R11-N9).
  final int? serverTotal;

  /// For tests; null means the real clock.
  final DateTime? now;

  Duration get closesIn {
    final d = closesAt.difference(now ?? DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  int get totalVotes => serverTotal ?? options.fold(0, (a, o) => a + o.votes);

  /// Most votes first; ties go to the earliest option.
  List<HomePollOption> get ranked =>
      [...options]..sort((a, b) => b.votes != a.votes ? b.votes.compareTo(a.votes) : a.order.compareTo(b.order));

  /// "2 days", "5 hours", "40 minutes".
  String get closesInLabel {
    String unit(int n, String u) => '$n $u${n == 1 ? '' : 's'}';
    final c = closesIn;
    if (c.inDays >= 1) return unit(c.inDays, 'day');
    if (c.inHours >= 1) return unit(c.inHours, 'hour');
    return unit(c.inMinutes < 1 ? 1 : c.inMinutes, 'minute');
  }

  static HomePoll? fromJson(Map json, {DateTime? now}) {
    final id = _id(json['pollId']);
    final club = _id(json['communityId']);
    final closes = DateTime.tryParse('${json['expiresAt']}')?.toLocal();
    if (id == null || club == null || closes == null) return null;
    final options = <HomePollOption>[];
    for (final (i, o) in (json['options'] is List ? json['options'] as List : const []).indexed) {
      if (o is! Map) continue;
      final oid = _id(o['optionId']);
      final film = _film(o['movie']);
      if (oid == null || film == null) continue;
      options.add(HomePollOption(optionId: oid, film: film, votes: _int(o['voteCount']), order: i));
    }
    if (options.isEmpty) return null;
    return HomePoll(
      pollId: id,
      communityId: club,
      club: _str(json['communityName']),
      question: _str(json['question']),
      closesAt: closes,
      options: options,
      hasVoted: json['hasVoted'] == true,
      serverTotal: json['totalVotes'] is num ? (json['totalVotes'] as num).toInt() : null,
      now: now,
    );
  }
}

/// A watch party in one of your clubs.
class HomeParty {
  const HomeParty({
    required this.id,
    required this.title,
    required this.scheduledAt,
    required this.isLive,
    this.film,
    this.movieId,
    this.clubId,
    this.club,
    this.hostName,
    this.attending = 0,
    this.joined = false,
    this.hosting = false,
  });

  final String id;
  final String title;
  final DateTime scheduledAt;
  final bool isLive;
  final TmdbMovie? film;

  /// Catalog film id, for the film's discussion.
  final String? movieId;
  final String? clubId;
  final String? club;
  final String? hostName;
  final int attending;

  /// You RSVP'd.
  final bool joined;

  /// You're the host (who is always going).
  final bool hosting;

  bool get going => joined || hosting;

  String? get posterUrl => film?.posterUrl('w342');

  static HomeParty? fromJson(Map json, {String? me}) {
    final id = _id(json['watchPartyId']);
    final when = DateTime.tryParse('${json['scheduledAt']}')?.toLocal();
    if (id == null || when == null) return null;
    final host = json['host'];
    final hostId = _id(host);
    return HomeParty(
      id: id,
      title: _str(json['title']) ?? 'Watch party',
      scheduledAt: when,
      isLive: json['status'] == 'live',
      film: _film(json['movie']),
      movieId: _id(json['movieId']),
      clubId: _id(json['communityId']),
      club: _str(json['communityName']),
      hostName: host is Map ? _str(host['username']) : null,
      attending: _int(json['participantCount']),
      joined: json['joined'] == true,
      hosting: me != null && hostId == me,
    );
  }
}

/// A recent post about a film suggested in one of your clubs.
class HomeDiscussion {
  const HomeDiscussion({
    required this.id,
    required this.movieId,
    required this.film,
    required this.text,
    this.createdAt,
    this.author,
    this.club,
    this.replies = 0,
    this.likes = 0,
  });

  final String id;

  /// Catalog film id: discussions are keyed by it.
  final String movieId;
  final TmdbMovie film;
  final String text;

  /// Null when the server sent none.
  final DateTime? createdAt;
  final String? author;
  final String? club;

  /// The film's comment count (all comments on the film, not replies).
  final int replies;
  final int likes;

  String? get posterUrl => film.posterUrl('w185');

  static HomeDiscussion? fromJson(Map json) {
    final id = _id(json['discussionId']);
    final movieId = _id(json['movieId']);
    final film = _film(json['movie']);
    final text = _str(json['text']);
    if (id == null || movieId == null || film == null || text == null) return null;
    final movie = json['movie'];
    return HomeDiscussion(
      id: id,
      movieId: movieId,
      film: film,
      text: text,
      createdAt: DateTime.tryParse('${json['createdAt']}')?.toLocal(),
      author: json['author'] is Map ? _str((json['author'] as Map)['username']) : null,
      club: _str(json['communityName']),
      replies: movie is Map ? _int(movie['commentCount']) : 0,
      likes: _int(json['upvotes']),
    );
  }
}

/// A film suggested in one of your clubs.
class HomeSuggestion {
  const HomeSuggestion({required this.movieId, required this.film, this.club});
  final String movieId;
  final TmdbMovie film;
  final String? club;

  static HomeSuggestion? fromJson(Map json) {
    final movieId = _id(json['movieId']);
    final film = _film(json['movie']);
    if (movieId == null || film == null) return null;
    return HomeSuggestion(movieId: movieId, film: film, club: _str(json['communityName']));
  }
}

/// Loads the Home feed (`GET /feed`). Refresh by invalidating it and
/// awaiting `.future`. Invalidate it (when it exists, so nothing fetches it
/// just for that) after anything that changes what Home shows: RSVPs,
/// votes, suggestions, posts, joining or leaving a club, signing out.
final homeFeedProvider = FutureProvider<HomeFeed>((ref) async {
  final me = await ref.watch(currentUserIdProvider.future);
  final res = await ref.read(apiClientProvider).get('/feed', params: {'limit': 10});
  return HomeFeed.fromJson(res.data, me: me);
});

/// Unread notification count for every bell in the app, so the tabs agree.
///
/// From `GET /notifications?isRead=false`. 0 while loading or when it
/// failed, so a bell never shows a made-up count.
final unreadCountProvider = Provider.autoDispose<int>((ref) => ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0);
