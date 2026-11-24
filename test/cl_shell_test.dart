import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'dart:ui' show Tristate;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Regression tests for review round 2 (design/review/round-2.md C1–C9).

Widget _shell({double bottomInset = 34, double keyboard = 0, Widget? tab}) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (c, s, child) => ClBottomNavBar(child: child),
        routes: [
          for (final p in ClBottomNavBar.routes)
            GoRoute(path: p, builder: (c, s) => tab ?? Scaffold(appBar: AppBar(title: Text(p)), body: Text('body $p'))),
        ],
      ),
    ],
  );
  return MediaQuery(
    data: MediaQueryData(
      size: const Size(390, 844),
      padding: EdgeInsets.only(top: 47, bottom: bottomInset),
      viewPadding: EdgeInsets.only(top: 47, bottom: bottomInset),
      viewInsets: EdgeInsets.only(bottom: keyboard),
    ),
    child: MaterialApp.router(
      theme: AppTheme.theme,
      routerConfig: router,
      builder: (context, child) => BackdropGroup(child: child!),
    ),
  );
}

void _phone(WidgetTester t) {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

double _barTop(WidgetTester t) => t.getTopLeft(find.byType(BackdropFilter).first).dy;

void main() {
  group('Floating nav (C1–C4)', () {
    testWidgets('every tab and the "+" expose a tap action and selected state', (t) async {
      _phone(t);
      final handle = t.ensureSemantics();
      await t.pumpWidget(_shell());
      await t.pumpAndSettle();
      for (final label in ['Home', 'Discover', 'Clubs', 'Profile', 'Suggest a film']) {
        final data = t.getSemantics(find.bySemanticsLabel(label).first).getSemanticsData();
        expect(data.hasAction(SemanticsAction.tap), isTrue, reason: '$label must be activatable by TalkBack/VoiceOver');
      }
      final home = t.getSemantics(find.bySemanticsLabel('Home').first).getSemanticsData();
      expect(home.flagsCollection.isSelected, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('semantics tap on a tab navigates', (t) async {
      _phone(t);
      final handle = t.ensureSemantics();
      await t.pumpWidget(_shell());
      await t.pumpAndSettle();
      t.semantics.tap(find.semantics.byLabel('Discover'));
      await t.pumpAndSettle();
      expect(find.text('body /discover'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the "+" is a focus target and paints the focus ring when focused', (t) async {
      _phone(t);
      await t.pumpWidget(_shell());
      await t.pumpAndSettle();
      final plus = find.byWidgetPredicate((w) => w is ClPressable && w.semanticLabel == 'Suggest a film');
      final ring = find.descendant(
        of: plus,
        matching: find.byWidgetPredicate((w) =>
            w is DecoratedBox &&
            w.position == DecorationPosition.foreground &&
            (w.decoration as BoxDecoration).border != null),
      );
      expect(ring, findsNothing);

      // C2: the "+" must own a focus node in the app's traversal tree.
      final inner = t.element(find.descendant(of: plus, matching: find.byType(Container)).first);
      final node = Focus.of(inner);
      expect(node.canRequestFocus, isTrue);
      expect(FocusManager.instance.rootScope.traversalDescendants, contains(node));

      // C5: focusing it paints the 2px gold ring above the purple fill.
      node.requestFocus();
      await t.pump(); // focus change is applied
      await t.pump(); // ClPressable rebuilds with the ring
      expect(node.hasPrimaryFocus, isTrue);
      expect(ring, findsOneWidget);
      final border = (t.widget<DecoratedBox>(ring).decoration as BoxDecoration).border as Border;
      expect(border.top.color, AppColors.focusRing);
      expect(border.top.width, 2);
    });

    for (final inset in [34.0, 0.0]) {
      testWidgets('inner FAB and SnackBar sit above the bar (home indicator $inset)', (t) async {
        _phone(t);
        final fabKey = GlobalKey();
        late BuildContext ctx;
        await t.pumpWidget(
          _shell(
            bottomInset: inset,
            tab: Scaffold(
              appBar: AppBar(title: const Text('x')),
              floatingActionButton: FloatingActionButton.extended(
                key: fabKey,
                onPressed: () {},
                label: const Text('Create'),
              ),
              body: Builder(
                builder: (c) {
                  ctx = c;
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        final barTop = _barTop(t);
        final plusTop = t.getTopLeft(find.bySemanticsLabel('Suggest a film')).dy;
        expect(t.getRect(find.byKey(fabKey)).bottom, lessThanOrEqualTo(plusTop), reason: 'C3: FAB hidden by the bar');

        ClSnackbar.show(ctx, message: 'hello');
        await t.pumpAndSettle();
        final pill = t.getRect(find.descendant(of: find.byType(SnackBar), matching: find.byType(Material)).first);
        final gap = barTop - pill.bottom;
        expect(gap, greaterThan(0), reason: 'snackbar must not overlap the bar');
        expect(gap, lessThan(40), reason: 'C4: snackbar floating far above the bar (gap $gap)');
      });
    }

    testWidgets('bar hides while the keyboard is up', (t) async {
      _phone(t);
      await t.pumpWidget(_shell(keyboard: 300));
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel('Suggest a film'), findsNothing);
      await t.pumpWidget(_shell());
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel('Suggest a film'), findsOneWidget);
    });
  });

  group('Hit areas (C6)', () {
    testWidgets('taps in the padded edge of ClButton.sm and ClChip register', (t) async {
      var b = 0, c = 0;
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClButton(
                    key: const Key('b'),
                    label: 'Small',
                    size: ClButtonSize.sm,
                    expand: false,
                    onPressed: () => b++,
                  ),
                  ClChip(key: const Key('c'), label: 'Chip', onTap: () => c++),
                ],
              ),
            ),
          ),
        ),
      );
      final br = t.getRect(find.byKey(const Key('b')));
      final cr = t.getRect(find.byKey(const Key('c')));
      expect(br.height, greaterThanOrEqualTo(AppSpacing.minTouch));
      expect(cr.height, greaterThanOrEqualTo(AppSpacing.minTouch));
      await t.tapAt(Offset(br.center.dx, br.top + 2));
      await t.tapAt(Offset(cr.center.dx, cr.top + 2));
      await t.pumpAndSettle();
      expect(b, 1, reason: 'ClButton.sm padded edge must be tappable');
      expect(c, 1, reason: 'ClChip padded edge must be tappable');
    });

    testWidgets('disabled ClButton ignores real taps', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: const Scaffold(body: Center(child: ClButton(label: 'No', onPressed: null))),
        ),
      );
      await t.tap(find.text('No'), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  });

  group('Dialog (C7)', () {
    testWidgets('showClDialog with a confirm button renders without layout errors', (t) async {
      late BuildContext ctx;
      var confirmed = 0;
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Builder(
            builder: (c) {
              ctx = c;
              return const Scaffold();
            },
          ),
        ),
      );
      showClDialog(
        context: ctx,
        title: 'Leave club?',
        message: 'You can rejoin later.',
        onConfirm: () => confirmed++,
        showConfirm: true,
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.tap(find.text('Confirm'));
      await t.pumpAndSettle();
      expect(confirmed, 1);
    });
  });

  group('Tokens match tokens.md (C8, C9)', () {
    test('scrimBottom stops', () {
      expect(AppColors.scrimBottom.stops, [0.0, 0.35, 0.55, 1.0]);
      expect(AppColors.scrimBottom.colors[2].a, closeTo(0.85, 0.01));
      expect(AppColors.scrimBottom.colors[3].a, closeTo(0.96, 0.01));
    });

    test('glowPurple is 30% / blur 40 / no offset', () {
      final s = AppShadows.glowPurple.single;
      expect(s.color.a, closeTo(0.30, 0.01));
      expect(s.blurRadius, 40);
      expect(s.offset, Offset.zero);
    });

    test('surfaceGlass is 88% surface', () {
      expect(AppColors.surfaceGlass.a, closeTo(0.88, 0.01));
    });
  });
}
