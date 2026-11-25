import 'dart:async';

import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/home/data/home_feed.dart';
import 'package:cluvie_mobile/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/real_fonts.dart';

const _targets = [
  '/notifications',
  '/watch-parties',
  '/discussionThread',
  '/watchParty',
  '/communities/friday-film-club/vote',
  '/suggest',
];

/// What a stub destination prints: its path plus the film/club it was given.
String _describe(Object? extra) {
  if (extra is! Map) return '';
  final focus = extra['focus'];
  if (focus is Map) return ' about ${focus['title']} (${focus['club']}, ${focus['when']})';
  if (extra['club'] != null) return ' for ${extra['club']} (${(extra['options'] as List).length} options)';
  if (extra['minutesLeft'] != null) return ' about ${extra['title']} (${extra['minutesLeft']}m left)';
  return ' about ${extra['title']}';
}

/// [feed] defaults to the demo feed. [shell] mounts Home under the real
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
      GoRoute(path: p, builder: (_, st) => Scaffold(body: Text('at $p${_describe(st.extra)}'))),
  ]);
  return ProviderScope(
    overrides: [homeFeedProvider.overrideWith((ref) async => (feed ?? () => demoHomeFeed)())],
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

bool _isGold(Color? c) => c != null && (c.toARGB32() == AppColors.gold.toARGB32() || c.toARGB32() == AppColors.goldDeep.toARGB32());

bool _decorationIsGold(Decoration? d) {
  if (d is! BoxDecoration) return false;
  final g = d.gradient;
  final border = d.border;
  return _isGold(d.color) ||
      (g != null && g.colors.any(_isGold)) ||
      (border is Border && [border.top, border.bottom, border.left, border.right].any((s) => s.style != BorderStyle.none && _isGold(s.color)));
}

/// Every element painting gold that isn't an allowed owner: the hero CTA,
/// the logo, the active nav tab and the focus ring.
List<String> _goldViolations(WidgetTester t) {
  final heroCta = _inHero(find.ancestor(of: find.text('RSVP'), matching: find.byType(ClButton)));
  final allowed = <Element>{
    ...heroCta.evaluate(),
    ...find.byType(ClLogo).evaluate(),
    ...find.byType(ClBottomNavBar).evaluate(),
  };
  bool underAllowed(Element e) {
    var ok = false;
    e.visitAncestorElements((a) {
      if (allowed.contains(a)) ok = true;
      return !ok;
    });
    return ok || allowed.contains(e);
  }

  final out = <String>[];
  for (final e in find.byWidgetPredicate((_) => true).evaluate()) {
    final w = e.widget;
    final gold = switch (w) {
      Icon(:final color) => _isGold(color),
      Text(:final style) => _isGold(style?.color),
      RichText(:final text) => _isGold(text.style?.color),
      DecoratedBox(:final decoration) => _decorationIsGold(decoration),
      Container(:final decoration, :final color) => _isGold(color) || _decorationIsGold(decoration),
      ColoredBox(:final color) => _isGold(color),
      RefreshIndicator(:final color) => _isGold(color),
      SvgPicture(:final colorFilter) => colorFilter != null && colorFilter.toString().contains('ffffd27d'),
      _ => false,
    };
    if (gold && !underAllowed(e)) out.add(w.toStringShort());
  }
  return out;
}

void main() {
  setUpAll(() async {
    ClPosterImage.debugDisableNetwork = true;
    await loadRealFonts();
  });

  group('Layout', () {
    for (final size in const [Size(320, 568), Size(375, 667), Size(390, 844)]) {
      for (final scale in const [1.0, 1.3, 2.0]) {
        testWidgets('no overflow or truncated control top to bottom at ${size.width.toInt()}x${size.height.toInt()} @${scale}x', (t) async {
          await _pump(t, size: size, scale: scale, padding: const EdgeInsets.only(top: 20, bottom: 34));
          expect(t.takeException(), isNull);
          // Control labels and the poll footer never ellipsize.
          for (final label in ['Cast your vote', 'Join live', 'RSVP', 'Discuss', 'See all']) {
            await _scrollTo(t, find.text(label));
            for (final e in find.text(label).evaluate()) {
              final p = e.findRenderObject()! as RenderParagraph;
              expect(p.didExceedMaxLines, isFalse, reason: '"$label" truncated');
            }
          }
          // The party list scrolls sideways; every card must fit its height.
          await t.drag(find.byType(ListView).first, const Offset(-900, 0));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          await t.drag(find.byType(Scrollable).first, const Offset(0, -4000));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
        });
      }
    }

    testWidgets('in the shell, the last card clears the floating nav', (t) async {
      await _pump(t, shell: true, padding: const EdgeInsets.only(top: 47, bottom: 34));
      await t.drag(find.byType(Scrollable).first, const Offset(0, -4000));
      await t.pumpAndSettle();
      final last = t.getRect(_card(find.text('5 replies')));
      final nav = t.getRect(find.bySemanticsLabel('Home').first);
      expect(last.bottom, lessThan(nav.top), reason: 'last card is under the nav');
    });
  });

  // Round 4 B1–B3: hero text and controls must stay on a ≥ 0.85 cover and
  // the CTA label must never truncate, at any phone size or text scale.
  group('Hero legibility', () {
    final panelColor = AppColors.bg.withValues(alpha: AppColors.scrimSolid);
    for (final size in const [Size(320, 568), Size(375, 667), Size(390, 844)]) {
      for (final scale in const [1.0, 1.3]) {
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
            for (final f in [find.textContaining("WEEK'S PICK"), find.text('DRAMA · 2023'), find.text('Past Lives')]) {
              expect(t.getRect(f.first).top, greaterThanOrEqualTo(panel.top), reason: '$f above the panel');
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
      expect(_isGold(spinner.valueColor?.value ?? spinner.color), isFalse, reason: 'spinner is gold');
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
      expect(ys, orderedEquals([...ys]..sort()), reason: 'poll rows are not ranked by votes');
    });

    testWidgets('footer count matches the votes shown', (t) async {
      await _pump(t);
      await _scrollTo(t, find.text('Cast your vote'));
      expect(find.text('24 of 31 members voted'), findsOneWidget);
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
    testWidgets('hero RSVP → the pick\'s watch party',
        (t) => tapAndExpect(t, _inHero(find.text('RSVP')), 'at /watch-parties about Past Lives (Cinema Sundays, Sun 8:00 PM)'));
    testWidgets('hero Discuss → the pick\'s thread', (t) => tapAndExpect(t, _inHero(find.text('Discuss')), 'at /discussionThread about Past Lives'));
    testWidgets('Cast your vote → the same poll',
        (t) => tapAndExpect(t, find.text('Cast your vote'), 'at /communities/friday-film-club/vote for Friday Film Club (3 options)'));
    testWidgets('Join live → that party\'s room',
        (t) => tapAndExpect(t, find.text('Join live'), 'at /watchParty about Mission: Impossible — Fallout (41m left)'));
    testWidgets('party RSVP → that party',
        (t) => tapAndExpect(t, find.descendant(of: find.byType(ListView), matching: find.text('RSVP')),
            'at /watch-parties about Oppenheimer (Nolan Nerds, Tonight 8:00 PM)'));
    testWidgets('See all → watch parties', (t) => tapAndExpect(t, find.text('See all'), 'at /watch-parties'));
    testWidgets('discussion card → its own film',
        (t) => tapAndExpect(t, find.text('5 replies'), 'at /discussionThread about Mission: Impossible — Fallout'));

    testWidgets('cards with their own button are not also tappable (one stop per action)', (t) async {
      await _pump(t);
      final partyRsvp = find.descendant(of: find.byType(ListView), matching: find.text('RSVP'));
      for (final label in [find.text('Cast your vote'), find.text('Join live'), partyRsvp]) {
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
      c.complete(demoHomeFeed);
      await t.pumpAndSettle();
      expect(find.text('Past Lives'), findsWidgets);
      expect(find.byType(ClSkeleton), findsNothing);
    });

    testWidgets('a failed load shows a retry that reloads', (t) async {
      var calls = 0;
      await _pump(t, feed: () {
        calls++;
        if (calls == 1) throw Exception('offline');
        return demoHomeFeed;
      });
      expect(find.text("Couldn't load your feed"), findsOneWidget);
      await t.tap(_control(find.text('Try again')));
      await t.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('Active poll'), findsOneWidget);
    });

    testWidgets('a failed refresh keeps the feed and says so', (t) async {
      var calls = 0;
      await _pump(t, feed: () {
        calls++;
        if (calls > 1) throw Exception('offline');
        return demoHomeFeed;
      });
      await t.fling(find.byType(Scrollable).first, const Offset(0, 500), 1500);
      await t.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('Active poll'), findsOneWidget);
      expect(find.textContaining("Couldn't refresh"), findsOneWidget);
    });

    testWidgets('empty feed: each section shows its empty state; Live now is hidden', (t) async {
      await _pump(t, feed: () => const HomeFeed());
      expect(find.byType(FlexibleSpaceBar), findsNothing, reason: 'no pick, no hero');
      expect(find.text('No active polls — suggest a film!'), findsOneWidget);
      expect(find.text('Live now'), findsNothing);
      await _scrollTo(t, find.text('No watch parties planned yet.'));
      expect(find.text('See all'), findsNothing);
      await _scrollTo(t, find.textContaining('Be the first to start a thread'));
      expect(find.textContaining('Discuss'), findsNothing, reason: 'no pick to discuss');
      expect(t.takeException(), isNull);
    });

    testWidgets('empty poll → Suggest a film opens the suggest tab', (t) async {
      await _pump(t, feed: () => const HomeFeed());
      await t.tap(_control(find.text('Suggest a film')));
      await t.pumpAndSettle();
      expect(find.text('at /suggest'), findsOneWidget);
    });

    testWidgets('no discussions → the action names and opens the pick', (t) async {
      await _pump(t, feed: () => HomeFeed(pick: demoHomeFeed.pick, poll: demoHomeFeed.poll));
      final action = find.text('Discuss Past Lives');
      await _scrollTo(t, action);
      await t.tap(_control(action));
      await t.pumpAndSettle();
      expect(find.text('at /discussionThread about Past Lives'), findsOneWidget);
    });
  });

  group('Semantics', () {
    testWidgets('section headings are their own header node, not merged into a button', (t) async {
      final handle = t.ensureSemantics();
      await _pump(t);
      for (final heading in ['Active poll', 'Live now']) {
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
      expect(t.getSemantics(_inHero(find.text('Past Lives'))).getSemanticsData().flagsCollection.isHeader, isTrue);
      handle.dispose();
    });

    testWidgets('the live ring reads as a countdown, once', (t) async {
      final handle = t.ensureSemantics();
      await _pump(t);
      await _scrollTo(t, find.text('Join live'));
      final ring = t.getSemantics(find.byType(ClProgressRing)).getSemanticsData();
      // The card reads as one item, starting with the countdown.
      expect(ring.label, startsWith('41 minutes left'));
      expect(ring.label, isNot(contains('41m')), reason: 'the ring text is read again');
      expect(ring.value, isNot(contains('%')), reason: 'the fill is elapsed time, not what is left');
      expect(find.bySemanticsLabel(RegExp(r'^41m$')), findsNothing);
      handle.dispose();
    });

    testWidgets('posters are decorative; the party count is read once', (t) async {
      final handle = t.ensureSemantics();
      await _pump(t);
      expect(find.bySemanticsLabel(RegExp('poster')), findsNothing);
      await _scrollTo(t, find.text('9 going'));
      expect(find.bySemanticsLabel('9 going'), findsNothing);
      expect(find.bySemanticsLabel(RegExp(r'Ada, Tunde \+7 going')), findsOneWidget);
      handle.dispose();
    });
  });
}
