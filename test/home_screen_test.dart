import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/real_fonts.dart';

const _targets = ['/notifications', '/watch-parties', '/discussionThread', '/watchParty', '/communities/demo/vote', '/suggest'];

Widget _app({Size size = const Size(390, 844), double scale = 1}) {
  final router = GoRouter(initialLocation: '/home', routes: [
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    for (final p in _targets) GoRoute(path: p, builder: (_, __) => Scaffold(body: Text('at $p'))),
  ]);
  return MediaQuery(
    data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
    child: MaterialApp.router(theme: AppTheme.theme, routerConfig: router),
  );
}

Future<void> _pump(WidgetTester t, {Size size = const Size(390, 844), double scale = 1}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(_app(size: size, scale: scale));
  await t.pumpAndSettle();
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
  for (var i = 0; i < 30; i++) {
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

void main() {
  setUpAll(() async {
    ClPosterImage.debugDisableNetwork = true;
    await loadRealFonts();
  });

  group('Layout', () {
    for (final (size, scale) in [(const Size(320, 568), 1.3), (const Size(375, 667), 1.3), (const Size(390, 844), 1.0)]) {
      testWidgets('no overflow top to bottom at ${size.width.toInt()}x${size.height.toInt()} @${scale}x', (t) async {
        await _pump(t, size: size, scale: scale);
        expect(t.takeException(), isNull);
        await _scrollTo(t, find.text('Recent discussions'));
        await t.drag(find.byType(Scrollable).first, const Offset(0, -2000));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      });
    }
  });

  group('Gold budget', () {
    testWidgets('exactly one gold-gradient element (the hero CTA)', (t) async {
      await _pump(t);
      final gold = find.byWidgetPredicate(
        (w) => w is DecoratedBox && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).gradient == AppColors.goldGradient,
      );
      expect(gold, findsOneWidget);
      await _scrollTo(t, find.text('Recent discussions'));
      expect(gold.evaluate().length, lessThanOrEqualTo(1));
    });
  });

  group('Poll', () {
    testWidgets('ranked by votes with the leader marked; no premature WINNER', (t) async {
      await _pump(t);
      await _scrollTo(t, find.text('Cast your vote'));
      expect(find.text('LEADING'), findsOneWidget); // ClBadge uppercases
      expect(find.textContaining('WINNER'), findsNothing);
      final top = t.getTopLeft(find.text('Everything Everywhere All at Once').first).dy;
      final second = t.getTopLeft(find.text('Oppenheimer').last).dy;
      expect(top, lessThan(second));
    });
  });

  group('Every control goes somewhere real', () {
    Future<void> tapAndExpect(WidgetTester t, Finder f, String route) async {
      await _pump(t);
      await _scrollTo(t, f);
      final target = find.ancestor(of: f.first, matching: find.byType(ClPressable)).evaluate().isEmpty ? f.first : _control(f.first);
      await t.tap(target);
      await t.pumpAndSettle();
      expect(find.text('at $route'), findsOneWidget, reason: '$f → $route');
    }

    testWidgets('bell → notifications', (t) => tapAndExpect(t, find.byTooltip('Notifications, 3 unread'), '/notifications'));
    testWidgets('hero CTA → watch parties', (t) => tapAndExpect(t, find.text('Watch party'), '/watch-parties'));
    testWidgets('hero Discuss → thread', (t) => tapAndExpect(t, find.text('Discuss'), '/discussionThread'));
    testWidgets('Cast your vote → vote screen', (t) => tapAndExpect(t, find.text('Cast your vote'), '/communities/demo/vote'));
    testWidgets('Join live → live room', (t) => tapAndExpect(t, find.text('Join live'), '/watchParty'));
    testWidgets('RSVP → watch parties', (t) => tapAndExpect(t, find.text('RSVP'), '/watch-parties'));
    testWidgets('discussion card → thread', (t) => tapAndExpect(t, find.text('12 replies'), '/discussionThread'));
  });
}
