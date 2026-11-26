import 'dart:async';

import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/home/data/home_feed.dart';
import 'package:cluvie_mobile/features/discover/presentation/movie_poster_tile.dart';
import 'package:cluvie_mobile/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/design_checks.dart';
import 'helpers/real_fonts.dart';

const _me = '64b000000000000000000001';
const _club1 = '64c000000000000000000001';
const _club2 = '64c000000000000000000002';
const _nextParty = '6a0000000000000000000001';
const _laterParty = '6a0000000000000000000002';
const _liveParty = '6a0000000000000000000003';
const _poll = '650000000000000000000001';

Map<String, Object?> _movie(String id, int tmdb, String title, {String year = '2023', int comments = 0}) =>
    {'_id': id, 'tmdbId': tmdb, 'title': title, 'posterPath': '/p.jpg', 'releaseDate': '$year-06-02', 'commentCount': comments};

final _pastLives = _movie('680000000000000000000001', 666277, 'Past Lives', comments: 12);
final _oppenheimer = _movie('680000000000000000000002', 872585, 'Oppenheimer', comments: 4);
final _eeaao = _movie('680000000000000000000003', 545611, 'Everything Everywhere All at Once', year: '2022');
final _fallout = _movie('680000000000000000000004', 353081, 'Mission: Impossible — Fallout', year: '2018', comments: 5);

/// A `GET /feed` body shaped exactly like `routes/feedRoutes.js` builds it.
Map<String, Object?> _feedJson({
  bool clubs = true,
  bool poll = true,
  bool parties = true,
  bool live = true,
  bool discussions = true,
  bool hasVoted = false,
  bool joinedNext = false,
  bool joinedLive = false,
}) {
  final now = DateTime.now();
  String at(Duration d) => now.add(d).toUtc().toIso8601String();
  return {
    'success': true,
    'data': {
      'communities': clubs ? [{'communityId': _club1, 'name': 'Cinema Sundays'}, {'communityId': _club2, 'name': 'Nolan Nerds'}] : [],
      'polls': poll && clubs
          ? [
              {
                'pollId': _poll,
                'communityId': _club1,
                'communityName': 'Cinema Sundays',
                'question': 'What do we watch on Friday?',
                'expiresAt': at(const Duration(days: 2, minutes: 1)),
                'allowMultiple': false,
                'totalVotes': 24,
                'hasVoted': hasVoted,
                'myVotes': hasVoted ? ['o1'] : [],
                'options': [
                  {'optionId': '660000000000000000000001', 'movieId': _oppenheimer['_id'], 'movie': _oppenheimer, 'voteCount': 7},
                  {'optionId': '660000000000000000000002', 'movieId': _eeaao['_id'], 'movie': _eeaao, 'voteCount': 12},
                  {'optionId': '660000000000000000000003', 'movieId': _fallout['_id'], 'movie': _fallout, 'voteCount': 5},
                ],
              },
            ]
          : [],
      'suggestions': clubs
          ? [
              {'communityId': _club1, 'communityName': 'Cinema Sundays', 'movieId': _pastLives['_id'], 'movie': _pastLives},
              {'communityId': _club2, 'communityName': 'Nolan Nerds', 'movieId': _oppenheimer['_id'], 'movie': _oppenheimer},
            ]
          : [],
      'discussions': discussions && clubs
          ? [
              {
                'discussionId': '6d0000000000000000000001',
                'movieId': _fallout['_id'],
                'movie': _fallout,
                'communityId': _club2,
                'communityName': 'Nolan Nerds',
                'text': 'That bathroom fight is the best action scene of the decade. Fight me.',
                'author': {'_id': 'u9', 'username': 'tunde'},
                'upvotes': 3,
                'createdAt': at(const Duration(hours: -3)),
              },
            ]
          : [],
      'watchParties': parties && clubs
          ? [
              if (live)
                {
                  'watchPartyId': _liveParty, 'communityId': _club2, 'communityName': 'Action Heads', 'movieId': _fallout['_id'],
                  'movie': _fallout, 'title': 'Fallout marathon', 'scheduledAt': at(const Duration(minutes: -40)), 'status': 'live',
                  'isPrivate': false, 'host': {'_id': 'h2', 'username': 'carmen'}, 'participantCount': 6, 'joined': joinedLive,
                },
              {
                'watchPartyId': _nextParty, 'communityId': _club1, 'communityName': 'Cinema Sundays', 'movieId': _pastLives['_id'],
                'movie': _pastLives, 'title': 'Sunday screening', 'scheduledAt': at(const Duration(days: 1)), 'status': 'scheduled',
                'isPrivate': false, 'host': {'_id': 'h1', 'username': 'ada'}, 'participantCount': 9, 'joined': joinedNext,
              },
              {
                'watchPartyId': _laterParty, 'communityId': _club2, 'communityName': 'Nolan Nerds', 'movieId': _oppenheimer['_id'],
                'movie': _oppenheimer, 'title': 'Oppenheimer', 'scheduledAt': at(const Duration(days: 3)), 'status': 'scheduled',
                'isPrivate': false, 'host': {'_id': _me, 'username': 'me_myself'}, 'participantCount': 14, 'joined': true,
              },
            ]
          : [],
    },
  };
}

HomeFeed _feed([Map<String, Object?>? json]) => HomeFeed.fromJson(json ?? _feedJson(), me: _me);

const _targets = [
  '/notifications',
  '/watch-parties',
  '/watch-parties/:id',
  '/watch-parties/:id/live',
  '/discussionThread',
  '/communities/:id/vote',
  '/communities',
  '/movie/:id',
  '/suggest',
];

/// What a stub destination prints: its path plus what it was given.
String _describe(GoRouterState st) {
  final extra = st.extra;
  final where = st.uri.path;
  if (extra is! Map) return 'at $where';
  if (extra['movieId'] != null) return 'at $where about ${extra['title']} (${extra['movieId']}, tmdb ${extra['tmdbId']})';
  if (extra['club'] != null) return 'at $where for ${extra['club']}';
  return 'at $where';
}

/// [feed] defaults to [_feedJson]. [shell] mounts Home under the real
/// floating nav, as in the app.
Widget _app({
  Size size = const Size(390, 844),
  double scale = 1,
  EdgeInsets padding = EdgeInsets.zero,
  FutureOr<HomeFeed> Function()? feed,
  bool shell = false,
  bool reduceMotion = false,
}) {
  final home = GoRoute(path: '/home', builder: (_, __) => const HomeScreen());
  final router = GoRouter(initialLocation: '/home', routes: [
    if (shell) ShellRoute(builder: (_, __, child) => ClBottomNavBar(child: child), routes: [home]) else home,
    for (final p in _targets)
      GoRoute(path: p, builder: (_, st) => Scaffold(body: Text(_describe(st)))),
  ]);
  return ProviderScope(
    overrides: [
      homeFeedProvider.overrideWith((ref) async => (feed ?? () => _feed())()),
      unreadCountProvider.overrideWithValue(3),
    ],
    child: MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(scale),
        padding: padding,
        viewPadding: padding,
        disableAnimations: reduceMotion,
      ),
      child: MaterialApp.router(theme: AppTheme.theme, routerConfig: router),
    ),
  );
}

Future<void> _pump(
  WidgetTester t, {
  Size size = const Size(390, 844),
  double scale = 1,
  EdgeInsets padding = EdgeInsets.zero,
  FutureOr<HomeFeed> Function()? feed,
  bool shell = false,
  bool settle = true,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(_app(size: size, scale: scale, padding: padding, feed: feed, shell: shell));
  if (settle) await t.pumpAndSettle();
}

/// Brings [f] on screen *below* the pinned app bar, without scrolling when
/// it's already visible (scrolling would collapse the hero header).
Future<void> _scrollTo(WidgetTester t, Finder f) async {
  final scrollable = find.byType(Scrollable).first;
  final screenH = t.view.physicalSize.height / t.view.devicePixelRatio;
  const clearance = 160.0; // status bar + pinned toolbar + margin
  // Controls in the pinned toolbar are always reachable where they are.
  if (f.evaluate().isNotEmpty && find.ancestor(of: f.first, matching: find.byType(NavigationToolbar)).evaluate().isNotEmpty) {
    return;
  }
  for (var i = 0; i < 40; i++) {
    if (f.evaluate().isNotEmpty) {
      final r = t.getRect(f.first);
      if (r.top >= clearance && r.bottom <= screenH - 24) return;
      final dy = r.top < clearance ? (clearance - r.top + 40) : -(r.bottom - screenH + 120);
      await t.drag(scrollable, Offset(0, dy));
    } else {
      await t.drag(scrollable, const Offset(0, -300)); // lazily built sections
    }
    await t.pumpAndSettle();
  }
  fail('could not bring $f on screen');
}

/// The tappable control that owns [label] (button, card or icon button).
Finder _control(Finder label) => find.ancestor(of: label, matching: find.byType(ClPressable)).first;

Finder _inHero(Finder f) => find.descendant(of: find.byType(FlexibleSpaceBar), matching: f);

/// The card wrapping [label].
Finder _card(Finder label) => find.ancestor(of: label, matching: find.byType(ClCard)).first;

List<String> _goldViolations(WidgetTester t) =>
    goldViolations(t, allowed: [_inHero(find.ancestor(of: find.text('RSVP'), matching: find.byType(ClButton)))]);

void main() {
  setUpAll(() async {
    ClPosterImage.debugDisableNetwork = true;
    await loadRealFonts();
  });

  group('Layout', () {
    // Names that must never be cut: clubs, the short film titles, counts.
    const names = ['Action Heads', 'Nolan Nerds', 'Cinema Sundays', 'Oppenheimer', 'Past Lives', '14 going'];
    const controls = ['Cast your vote', 'See party', 'RSVP', 'Discuss', 'See all'];

    void expectNotCut(WidgetTester t, String label) {
      for (final e in find.text(label).evaluate()) {
        final p = e.findRenderObject()! as RenderParagraph;
        expect(p.didExceedMaxLines, isFalse, reason: '"$label" truncated');
      }
    }

    for (final size in const [Size(320, 568), Size(375, 667), Size(390, 844)]) {
      for (final scale in const [1.0, 1.3, 2.0]) {
        testWidgets('no overflow or cut text top to bottom at ${size.width.toInt()}x${size.height.toInt()} @${scale}x', (t) async {
          final top = size.height > 800 ? 47.0 : 20.0;
          await _pump(t, size: size, scale: scale, shell: true, padding: EdgeInsets.only(top: top, bottom: 34));
          expect(t.takeException(), isNull);
          for (final label in controls) {
            await _scrollTo(t, find.text(label));
            expectNotCut(t, label);
            expectNoBrokenWords(t);
          }
          for (final n in names) {
            expectNotCut(t, n);
          }
          // The party list scrolls sideways; every card must fit its height.
          await t.drag(find.byType(ListView).first, const Offset(-900, 0));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          for (final n in names) {
            expectNotCut(t, n);
          }
          await t.drag(find.byType(Scrollable).first, const Offset(0, -4000));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          for (final n in names) {
            expectNotCut(t, n);
          }
        });
      }
    }

    testWidgets('in the shell, the last card clears the floating nav', (t) async {
      await _pump(t, shell: true, padding: const EdgeInsets.only(top: 47, bottom: 34));
      await t.drag(find.byType(Scrollable).first, const Offset(0, -4000));
      await t.pumpAndSettle();
      final last = t.getRect(_card(find.text('5 comments on the film')));
      final nav = t.getRect(find.bySemanticsLabel('Home').first);
      expect(last.bottom, lessThan(nav.top), reason: 'last card is under the nav');
    });
  });

  // Round 4 B1–B3: hero text and controls must stay on a ≥ 0.85 cover and
  // the CTA label must never truncate, at any phone size or text scale.
  group('Hero legibility', () {
    final panelColor = AppColors.bg.withValues(alpha: AppColors.scrimSolid);
    for (final size in const [Size(320, 568), Size(375, 667), Size(390, 844)]) {
      for (final scale in const [1.0, 1.3, 2.0]) {
        for (final inset in const [20.0, 47.0]) {
          testWidgets('${size.width.toInt()}x${size.height.toInt()} @${scale}x, top inset $inset', (t) async {
            await _pump(t, size: size, scale: scale, padding: EdgeInsets.only(top: inset, bottom: 34));

            // B3: neither hero label is ellipsized.
            for (final label in ['RSVP', 'Discuss']) {
              final p = t.renderObject<RenderParagraph>(_inHero(find.text(label)));
              expect(p.didExceedMaxLines, isFalse, reason: '"$label" truncated');
            }

            // B1: every hero line sits on the solid panel.
            final panel = t.getRect(find.byWidgetPredicate((w) => w is ColoredBox && w.color == panelColor));
            // Round 5 B1: and every line is below the toolbar, so nothing
            // runs under the logo or off the screen.
            for (final f in [find.text('NEXT WATCH PARTY'), _inHero(find.text('2023')), _inHero(find.text('Sunday screening'))]) {
              final r = t.getRect(f.first);
              expect(r.top, greaterThanOrEqualTo(panel.top), reason: '$f above the panel');
              expect(r.top, greaterThanOrEqualTo(inset + kToolbarHeight), reason: '$f under the toolbar');
            }

            // B2: the solid part of the top scrim covers the logo and the bell.
            final topScrim = find.byWidgetPredicate((w) {
              if (w is! DecoratedBox) return false;
              final g = (w.decoration as BoxDecoration?)?.gradient;
              return g is LinearGradient && g.colors.first == panelColor && g.stops?.length == 3;
            });
            final r = t.getRect(topScrim);
            final solidBottom = r.top + r.height * (t.widget<DecoratedBox>(topScrim).decoration as BoxDecoration).gradient!.stops![1];
            for (final f in [find.byType(ClLogo), find.byTooltip('Notifications, 3 unread')]) {
              expect(t.getRect(f.first).bottom, lessThanOrEqualTo(solidBottom), reason: '$f below the solid top scrim');
            }
            expect(t.takeException(), isNull);
          });
        }
      }
    }
  });

  group('Gold budget', () {
    testWidgets('the scan flags gold outside the allowed owners (negative control)', (t) async {
      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(children: [
                const Icon(Icons.star, color: AppColors.gold),
                const Text('x', style: TextStyle(color: AppColors.gold)),
                Container(decoration: BoxDecoration(border: Border.all(color: AppColors.goldDeep)), width: 10, height: 10),
              ]),
            ),
          ),
        ),
      );
      expect(_goldViolations(t), containsAll(['Icon', 'Text', 'Container']));
    });


    testWidgets('nothing is gold except the hero CTA, logo, active tab and pull-to-refresh is purple', (t) async {
      await _pump(t, shell: true, padding: const EdgeInsets.only(top: 47, bottom: 34));
      expect(_inHero(find.ancestor(of: find.text('RSVP'), matching: find.byType(ClButton))), findsOneWidget);
      expect(_goldViolations(t), isEmpty);
      await t.drag(find.byType(Scrollable).first, const Offset(0, -4000));
      await t.pumpAndSettle();
      expect(_goldViolations(t), isEmpty);
      // Mid-pull: the refresh spinner is on screen.
      await t.drag(find.byType(Scrollable).first, const Offset(0, 6000));
      await t.pumpAndSettle();
      final gesture = await t.startGesture(t.getCenter(find.byType(Scrollable).first));
      await gesture.moveBy(const Offset(0, 200));
      await t.pump();
      expect(find.byType(RefreshProgressIndicator), findsOneWidget);
      final spinner = t.widget<RefreshProgressIndicator>(find.byType(RefreshProgressIndicator));
      expect(isGold(spinner.valueColor?.value ?? spinner.color), isFalse, reason: 'spinner is gold');
      expect(_goldViolations(t), isEmpty);
      await gesture.up();
      await t.pumpAndSettle();
    });
  });

  group('Poll', () {
    testWidgets('ranked by votes with the leader marked; no premature WINNER', (t) async {
      await _pump(t);
      await _scrollTo(t, find.text('Cast your vote'));
      final poll = _card(find.text('Cast your vote'));
      Finder inPoll(String s) => find.descendant(of: poll, matching: find.text(s));
      expect(find.descendant(of: poll, matching: find.textContaining('Leading', findRichText: true)), findsOneWidget);
      expect(find.textContaining('WINNER'), findsNothing);
      final ys = [for (final s in ['Everything Everywhere All at Once', 'Oppenheimer', 'Mission: Impossible — Fallout']) t.getTopLeft(inPoll(s)).dy];
      expect(find.descendant(of: poll, matching: find.text('What do we watch on Friday?')), findsOneWidget);
      expect(ys, orderedEquals([...ys]..sort()), reason: 'poll rows are not ranked by votes');
    });

    testWidgets('footer count matches the votes shown', (t) async {
      await _pump(t);
      await _scrollTo(t, find.text('Cast your vote'));
      expect(find.text('24 votes'), findsOneWidget);
    });

    testWidgets('after voting, the button says See the vote and the footer says so', (t) async {
      await _pump(t, feed: () => _feed(_feedJson(hasVoted: true)));
      await _scrollTo(t, find.text('See the vote'));
      expect(find.text('24 votes · you voted'), findsOneWidget);
      expect(find.text('Cast your vote'), findsNothing);
    });
  });

  group('Every control opens what it names', () {
    Future<void> tapAndExpect(WidgetTester t, Finder f, String expected) async {
      await _pump(t);
      await _scrollTo(t, f);
      // Icon and text buttons aren't ClPressables; tap them directly.
      final hasPressable = find.ancestor(of: f.first, matching: find.byType(ClPressable)).evaluate().isNotEmpty;
      await t.tap(hasPressable ? _control(f.first) : f.first);
      await t.pumpAndSettle();
      expect(find.text(expected), findsOneWidget, reason: '$f → $expected');
    }

    testWidgets('bell → notifications', (t) => tapAndExpect(t, find.byTooltip('Notifications, 3 unread'), 'at /notifications'));
    testWidgets('hero RSVP → the next party', (t) => tapAndExpect(t, _inHero(find.text('RSVP')), 'at /watch-parties/$_nextParty'));
    testWidgets('hero Discuss → the film\'s thread, by catalog id',
        (t) => tapAndExpect(t, _inHero(find.text('Discuss')), 'at /discussionThread about Past Lives (680000000000000000000001, tmdb 666277)'));
    testWidgets('Cast your vote → the club\'s vote',
        (t) => tapAndExpect(t, find.text('Cast your vote'), 'at /communities/$_club1/vote for Cinema Sundays'));
    testWidgets('live, not going: See party → the party page',
        (t) => tapAndExpect(t, find.text('See party'), 'at /watch-parties/$_liveParty'));
    testWidgets('live, going: Join live → the room', (t) async {
      await _pump(t, feed: () => _feed(_feedJson(joinedLive: true)));
      await _scrollTo(t, find.text('Join live'));
      await t.tap(_control(find.text('Join live')));
      await t.pumpAndSettle();
      expect(find.text('at /watch-parties/$_liveParty/live'), findsOneWidget);
    });
    testWidgets('a party you host → View opens it',
        (t) => tapAndExpect(t, find.descendant(of: find.byType(ListView), matching: find.text('View')), 'at /watch-parties/$_laterParty'));
    testWidgets('See all → watch parties', (t) => tapAndExpect(t, find.text('See all'), 'at /watch-parties'));
    testWidgets('discussion card → its own film',
        (t) => tapAndExpect(t, find.text('5 comments on the film'), 'at /discussionThread about Mission: Impossible — Fallout (680000000000000000000004, tmdb 353081)'));
    testWidgets('a new film → its page', (t) async {
      await _pump(t);
      final tile = find.byType(MoviePosterTile);
      await _scrollTo(t, tile);
      await t.tap(tile.first);
      await t.pumpAndSettle();
      expect(find.text('at /movie/666277'), findsOneWidget);
    });

    testWidgets('going to the next party: the hero says View party', (t) async {
      await _pump(t, feed: () => _feed(_feedJson(joinedNext: true)));
      expect(_inHero(find.text('View party')), findsOneWidget);
      expect(_inHero(find.text('RSVP')), findsNothing);
    });

    testWidgets('cards with their own button are not also tappable (one stop per action)', (t) async {
      await _pump(t);
      final partyView = find.descendant(of: find.byType(ListView), matching: find.text('View'));
      for (final label in [find.text('Cast your vote'), find.text('See party'), partyView]) {
        await _scrollTo(t, label);
        expect(t.widget<ClCard>(_card(label)).onTap, isNull, reason: '$label card');
      }
      await t.pump(const Duration(seconds: 2)); // let late section entrances finish
    });
  });

  group('States', () {
    testWidgets('loading shows a skeleton, then the feed', (t) async {
      final c = Completer<HomeFeed>();
      await _pump(t, feed: () => c.future, settle: false);
      await t.pump();
      expect(find.bySemanticsLabel('Loading your feed'), findsOneWidget);
      expect(find.byType(ClSkeleton), findsWidgets);
      expect(find.byType(ClLogo), findsOneWidget, reason: 'the app bar stays while loading');
      c.complete(_feed());
      await t.pumpAndSettle();
      expect(find.text('Sunday screening'), findsWidgets);
      expect(find.byType(ClSkeleton), findsNothing);
    });

    testWidgets('a failed load shows a retry that reloads', (t) async {
      var calls = 0;
      await _pump(t, feed: () {
        calls++;
        if (calls == 1) throw Exception('offline');
        return _feed();
      });
      expect(find.text("Couldn't load your feed"), findsOneWidget);
      await t.tap(_control(find.text('Try again')));
      await t.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('Active poll'), findsOneWidget);
    });

    testWidgets('while a retry is in flight the skeleton replaces the error', (t) async {
      var calls = 0;
      final retry = Completer<HomeFeed>();
      await _pump(t, feed: () {
        calls++;
        if (calls == 1) throw Exception('offline');
        return retry.future;
      });
      await t.tap(_control(find.text('Try again')));
      await t.pump();
      await t.pump();
      expect(find.text("Couldn't load your feed"), findsNothing);
      expect(find.bySemanticsLabel('Loading your feed'), findsOneWidget);
      retry.complete(_feed());
      await t.pumpAndSettle();
      expect(find.text('Active poll'), findsOneWidget);
    });

    testWidgets('a failed refresh keeps the feed and says so', (t) async {
      var calls = 0;
      await _pump(t, feed: () {
        calls++;
        if (calls > 1) throw Exception('offline');
        return _feed();
      });
      await t.fling(find.byType(Scrollable).first, const Offset(0, 500), 1500);
      await t.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('Active poll'), findsOneWidget);
      expect(find.textContaining("Couldn't refresh"), findsOneWidget);
    });

    testWidgets('in clubs but nothing going on: each section shows its empty state; Live now is hidden', (t) async {
      await _pump(t, feed: () => _feed(_feedJson(poll: false, parties: false, discussions: false)));
      expect(find.byType(FlexibleSpaceBar), findsNothing, reason: 'no party, no hero');
      expect(find.text('No open votes in your clubs. Suggest a film to get one going.'), findsOneWidget);
      expect(find.text('Happening now'), findsNothing);
      await _scrollTo(t, find.text('No watch parties planned yet.'));
      await _scrollTo(t, find.textContaining('Be the first to start a thread'));
      expect(find.textContaining('Discuss'), findsNothing, reason: 'no party film to discuss');
      expect(goldViolations(t, allowed: const []), isEmpty, reason: 'empty states add no gold');
      expect(t.takeException(), isNull);
    });

    testWidgets('empty poll → Suggest a film opens the suggest tab', (t) async {
      await _pump(t, feed: () => _feed(_feedJson(poll: false)));
      await _scrollTo(t, find.text('Suggest a film'));
      await t.tap(_control(find.text('Suggest a film')));
      await t.pumpAndSettle();
      expect(find.text('at /suggest'), findsOneWidget);
    });

    testWidgets('no discussions → the action names and opens the party film', (t) async {
      await _pump(t, feed: () => _feed(_feedJson(discussions: false)));
      final action = find.text('Discuss Past Lives');
      await _scrollTo(t, action);
      await t.tap(_control(action));
      await t.pumpAndSettle();
      expect(find.text('at /discussionThread about Past Lives (680000000000000000000001, tmdb 666277)'), findsOneWidget);
    });

    testWidgets('no clubs: one first-run state that opens Clubs, not five empty sections', (t) async {
      await _pump(t, feed: () => _feed(_feedJson(clubs: false)));
      expect(find.text('Your feed fills up with your clubs'), findsOneWidget);
      expect(find.text('Active poll'), findsNothing);
      expect(goldViolations(t, allowed: [find.ancestor(of: find.text('Find a club'), matching: find.byType(ClButton))]), isEmpty);
      await t.tap(_control(find.text('Find a club')));
      await t.pumpAndSettle();
      expect(find.text('at /communities'), findsOneWidget);
    });
  });

  group('Parsing GET /feed', () {
    test('hero is the next scheduled party; live is separate; the rest follow', () {
      final f = _feed();
      expect(f.clubCount, 2);
      expect(f.pick!.party.id, _nextParty);
      expect(f.pick!.title, 'Sunday screening');
      expect(f.pick!.filmTitle, 'Past Lives');
      expect(f.happening.single.id, _liveParty);
      expect(f.parties.map((p) => p.id), [_laterParty]);
      expect(f.parties.single.hosting, isTrue);
      expect(f.poll!.ranked.first.title, 'Everything Everywhere All at Once');
      expect(f.poll!.totalVotes, 24);
      expect(f.discussions.single.replies, 5);
      expect(f.suggestions.map((s) => s.film.id), [666277, 872585]);
    });

    test('R11-S3: a party past its start but not live is happening, not "next"', () {
      final json = _feedJson(live: false);
      final parties = (json['data'] as Map)['watchParties'] as List;
      (parties.first as Map)['scheduledAt'] = DateTime.now().subtract(const Duration(minutes: 10)).toUtc().toIso8601String();
      final f = HomeFeed.fromJson(json, me: _me);
      expect(f.happening.single.id, _nextParty);
      expect(f.pick!.party.id, _laterParty);
      expect(f.parties, isEmpty);
    });

    test('R11-S2: a poll past its close time is gone; nextChange is the soonest deadline', () {
      final json = _feedJson();
      final poll = ((json['data'] as Map)['polls'] as List).first as Map;
      poll['expiresAt'] = DateTime.now().subtract(const Duration(minutes: 1)).toUtc().toIso8601String();
      final f = HomeFeed.fromJson(json, me: _me);
      expect(f.poll, isNull);
      expect(f.nextChange(), f.pick!.party.scheduledAt);
    });

    test('R11-N9: the poll total is the server\'s', () {
      final json = _feedJson();
      (((json['data'] as Map)['polls'] as List).first as Map)['totalVotes'] = 30;
      expect(HomeFeed.fromJson(json).poll!.totalVotes, 30);
    });

    test('malformed items are skipped, not fatal', () {
      final json = _feedJson();
      final data = json['data'] as Map;
      (data['watchParties'] as List).add({'title': 'no id'});
      (data['discussions'] as List).add({'discussionId': 'x'});
      (data['polls'] as List).add({'pollId': 'p', 'communityId': 'c', 'expiresAt': 'nope'});
      final f = HomeFeed.fromJson(json, me: _me);
      expect(f.parties, hasLength(1));
      expect(f.discussions, hasLength(1));
      expect(f.poll!.pollId, _poll);
      expect(HomeFeed.fromJson(null).hasClubs, isFalse);
    });
  });

  group('Semantics', () {
    testWidgets('section headings are their own header node, not merged into a button', (t) async {
      final handle = t.ensureSemantics();
      await _pump(t);
      for (final heading in ['Active poll', 'Happening now']) {
        await _scrollTo(t, find.text(heading));
        final data = t.getSemantics(find.text(heading)).getSemanticsData();
        expect(data.flagsCollection.isHeader, isTrue, reason: heading);
        expect(data.flagsCollection.isButton, isFalse, reason: '$heading is announced as a button');
        expect(data.label, isNot(contains('Everything Everywhere')), reason: '$heading absorbs the poll rows');
      }
      handle.dispose();
    });

    testWidgets('the hero title is a header', (t) async {
      final handle = t.ensureSemantics();
      await _pump(t);
      expect(t.getSemantics(_inHero(find.text('Sunday screening'))).getSemanticsData().flagsCollection.isHeader, isTrue);
      handle.dispose();
    });

    testWidgets('the live card says who is going, with a purple Live badge, and its button names the party', (t) async {
      final handle = t.ensureSemantics();
      await _pump(t);
      await _scrollTo(t, find.text('See party'));
      expect(find.text('6 going'), findsOneWidget);
      final badge = t.widget<ClBadge>(find.ancestor(of: find.text('LIVE'), matching: find.byType(ClBadge)));
      expect(badge.tone, ClBadgeTone.purpleSolid);
      expect(find.bySemanticsLabel('See the Fallout marathon watch party'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('posters are decorative; the party count is read once', (t) async {
      final handle = t.ensureSemantics();
      await _pump(t);
      expect(find.bySemanticsLabel(RegExp('poster')), findsNothing);
      await _scrollTo(t, find.text('14 going'));
      expect(find.bySemanticsLabel('View Oppenheimer'), findsOneWidget, reason: 'the party button names its party');
      handle.dispose();
    });
  });
}
