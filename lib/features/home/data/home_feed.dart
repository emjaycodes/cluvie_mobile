import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Home feed: everything the Home tab shows, loaded as one unit.
///
/// There is no feed endpoint yet, so [homeFeedProvider] serves [demoHomeFeed].
/// Swap its body for the API call when one exists; the screen already
/// handles loading, error, refresh and empty sections.
class HomeFeed {
  const HomeFeed({
    this.pick,
    this.poll,
    this.live,
    this.parties = const [],
    this.discussions = const [],
    this.unread = 0,
  });

  /// This week's pick (the hero). Null hides the hero.
  final FeaturedPick? pick;

  /// The active poll. Null shows the "suggest a film" empty state.
  final Poll? poll;

  /// A party that is live right now. Null hides "Live now".
  final Party? live;
  final List<Party> parties;
  final List<Discussion> discussions;
  final int unread;
}

class FeaturedPick {
  const FeaturedPick({required this.title, required this.meta, required this.posterUrl, required this.party});
  final String title;

  /// Genre · year.
  final String meta;
  final String posterUrl;

  /// The watch party the pick is scheduled for.
  final Party party;

  /// "Cinema Sundays · Watch party Sun 8:00 PM".
  String get when => '${party.club} · Watch party ${party.when}';

  /// Route extra for the discussion thread.
  Map<String, Object> get threadExtra => {'title': title, 'posterUrl': posterUrl};
}

class PollOption {
  const PollOption(this.title, this.votes, this.posterUrl, this.order);
  final String title;
  final int votes;
  final String posterUrl;

  /// Suggestion order; ties go to the earliest suggestion.
  final int order;
}

class Poll {
  const Poll({
    required this.communityId,
    required this.club,
    required this.closesIn,
    required this.options,
    required this.members,
  });
  final String communityId;
  final String club;
  final String closesIn;
  final List<PollOption> options;
  final int members;

  /// Single-pick poll, so this is also the number of members who voted.
  int get totalVotes => options.fold(0, (a, o) => a + o.votes);

  /// Most votes first; ties go to the earliest suggestion.
  List<PollOption> get ranked =>
      [...options]..sort((a, b) => b.votes != a.votes ? b.votes.compareTo(a.votes) : a.order.compareTo(b.order));

  /// Route extra for the vote screen, so it shows this same poll.
  Map<String, Object> get voteExtra => {
        'club': club,
        'options': [
          for (final o in options) {'title': o.title, 'posterUrl': o.posterUrl, 'votes': o.votes, 'order': o.order},
        ],
      };
}

typedef Person = ({String name, String? imageUrl});

class Party {
  const Party({
    required this.title,
    required this.club,
    required this.when,
    required this.posterUrl,
    required this.attending,
    required this.people,
    this.badge,
    this.progress = 0,
    this.minutesLeft = 0,
  });
  final String title;
  final String club;
  final String when;
  final String posterUrl;
  final int attending;
  final List<Person> people;
  final String? badge;

  /// Live parties: share of the film already watched (0..1).
  final double progress;

  /// Live parties: minutes until the film ends.
  final int minutesLeft;

  /// Route extra for the watch-party list, which lists this party first.
  Map<String, Object> get focusExtra => {
        'focus': {'title': title, 'when': when, 'club': club, 'posterUrl': posterUrl, 'attending': attending},
      };

  /// Route extra for the live room.
  Map<String, Object> get roomExtra => {'title': title, 'minutesLeft': minutesLeft};
}

class Discussion {
  const Discussion(this.title, this.prompt, this.posterUrl, this.replies, this.ago, {this.pinned = false});
  final String title;
  final String prompt;
  final String posterUrl;
  final int replies;
  final String ago;
  final bool pinned;

  Map<String, Object> get threadExtra => {'title': title, 'posterUrl': posterUrl};
}

/// Loads the Home feed. Refresh by invalidating it and awaiting `.future`.
final homeFeedProvider = FutureProvider<HomeFeed>((ref) async {
  // TODO(api): replace with the home feed request once it exists.
  return demoHomeFeed;
});

// ── Demo data ────────────────────────────────────────────────────────────────

const _tmdb = 'https://image.tmdb.org/t/p/w342';
const _pastLivesPoster = '$_tmdb/kAellTx1ukNtc42BP1kcnHPCG5e.jpg';
const _oppenheimerPoster = '$_tmdb/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg';
const _eeaaoPoster = '$_tmdb/w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg';
const _falloutPoster = '$_tmdb/74xTEgt7R36Fpooo50r9T25onhq.jpg';

const Person _ada = (name: 'Ada Obi', imageUrl: null);
const Person _tunde = (name: 'Tunde Bello', imageUrl: null);
const Person _mira = (name: 'Mira Chen', imageUrl: null);
const Person _sam = (name: 'Sam Reyes', imageUrl: null);

const _pastLivesParty = Party(
  title: 'Past Lives',
  club: 'Cinema Sundays',
  when: 'Sun 8:00 PM',
  posterUrl: _pastLivesPoster,
  attending: 14,
  people: [_mira, _sam, _tunde],
);

const demoHomeFeed = HomeFeed(
  unread: 3,
  pick: FeaturedPick(
    title: 'Past Lives',
    meta: 'Drama · 2023',
    posterUrl: 'https://image.tmdb.org/t/p/w780/kAellTx1ukNtc42BP1kcnHPCG5e.jpg',
    party: _pastLivesParty,
  ),
  poll: Poll(
    communityId: 'friday-film-club',
    club: 'Friday Film Club',
    closesIn: '2 days',
    members: 31,
    options: [
      PollOption('Oppenheimer', 8, _oppenheimerPoster, 1),
      PollOption('Everything Everywhere All at Once', 11, _eeaaoPoster, 0),
      PollOption('Mission: Impossible — Fallout', 5, _falloutPoster, 2),
    ],
  ),
  live: Party(
    title: 'Mission: Impossible — Fallout',
    club: 'Action Heads',
    when: 'Now',
    posterUrl: _falloutPoster,
    attending: 12,
    people: [_sam, _ada],
    progress: 0.72,
    minutesLeft: 41,
  ),
  parties: [
    Party(
      title: 'Oppenheimer',
      club: 'Nolan Nerds',
      when: 'Tonight 8:00 PM',
      posterUrl: _oppenheimerPoster,
      attending: 9,
      people: [_ada, _tunde, _mira],
      badge: 'Tonight',
    ),
    _pastLivesParty,
    Party(
      title: 'Everything Everywhere All at Once',
      club: 'A24 Lovers',
      when: 'Fri 7:30 PM',
      posterUrl: _eeaaoPoster,
      attending: 6,
      people: [_tunde, _ada],
    ),
  ],
  discussions: [
    Discussion(
      'Oppenheimer',
      "Christopher Nolan's magnum opus. Did the three timelines work for you?",
      _oppenheimerPoster,
      12,
      '2h',
      pinned: true,
    ),
    Discussion(
      'Mission: Impossible — Fallout',
      'Most thrilling practical stunt ever filmed? Make your case.',
      _falloutPoster,
      5,
      '5h',
    ),
  ],
);
